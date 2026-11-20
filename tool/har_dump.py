#!/usr/bin/env python3
"""把 Whistle/browse 抓的 HAR 解析成 DSM API 规格。

用法:
    python3 tool/har_dump.py <file.har> [more.har ...] [--json out.json]

输出每个 SYNO.* API 被调用过的 method、version、参数名（不打印参数值），
按命名空间分组。这是"抓包 -> 补全 dsm_api"循环的核心工具。

DSM 把批量调用塞进 SYNO.Entry.Request?compound=[...]，本脚本会递归展开，
所以能拿到应用真正用到的 api/method/params。

注意: HAR 里 secret 已被 browse 替换成 ${BC_SECRET_n}，参数名/方法名不受影响。
"""
import json, sys, urllib.parse, collections

NOISE = {"api", "method", "version", "_sid", "SynoToken", "_", "mode", "dlink"}


def _clean(v):
    """strip surrounding quotes/space that some HARs wrap the api value in."""
    if v is None or not isinstance(v, str):
        return v
    v = v.strip()
    if len(v) >= 2 and v[0] == '"' and v[-1] == '"':
        v = v[1:-1].strip()
    return v


def _walk(requests, out):
    """requests: compound 里的 dict 列表。递归展开嵌套 compound。"""
    for r in requests:
        if not isinstance(r, dict):
            continue
        api = _clean(r.get("api"))
        if not api:
            continue
        method = _clean(r.get("method"))
        ver = str(_clean(r.get("version"))) if r.get("version") is not None else None
        params = {k for k in r.keys() if k not in NOISE}
        out[api][(method, ver)] |= params
        if "compound" in r:
            _walk(r["compound"], out)


def parse(hars):
    """-> {api: {(method, version): set(param names)}}"""
    spec = collections.defaultdict(lambda: collections.defaultdict(set))
    for h in hars:
        try:
            data = json.load(open(h))
        except Exception as e:
            print("skip %s: %s" % (h, e), file=sys.stderr)
            continue
        for e in data.get("log", {}).get("entries", []):
            req = e.get("request", {})
            pu = urllib.parse.urlparse(req.get("url", ""))
            q = urllib.parse.parse_qs(pu.query)
            pd = req.get("postData", {}).get("text", "")
            bq = urllib.parse.parse_qs(pd) if pd else {}

            # 顶层请求（GET query + POST body）
            api = _clean((q.get("api") or bq.get("api") or [None])[0])
            if api:
                method = _clean((q.get("method") or bq.get("method") or [None])[0])
                ver = _clean((q.get("version") or bq.get("version") or [None])[0])
                params = (set(q.keys()) | set(bq.keys())) - NOISE
                spec[api][(method, ver)] |= params

            # 展开 compound（可能在 query 或 body）
            for src in (q, bq):
                raw = (src.get("compound") or [None])[0]
                if not raw:
                    continue
                try:
                    comp = json.loads(raw)
                except Exception:
                    continue
                if isinstance(comp, list):
                    _walk(comp, spec)
    return spec


def report(spec, out_json=None):
    ns = collections.defaultdict(list)
    for api in spec:
        p = api.split(".")
        ns[".".join(p[:2]) if len(p) > 1 else api].append(api)
    total = 0
    for g in sorted(ns):
        print("\n## %s" % g)
        for api in sorted(ns[g]):
            for (method, ver), params in sorted(spec[api].items(), key=lambda x: str(x[0])):
                total += 1
                ps = ", ".join(sorted(params)) if params else "-"
                print("  %-36s %-22s v%-3s [%s]" % (api, method or "?", ver or "?", ps))
    print("\n== %d distinct api/method calls, %d APIs ==" % (total, len(spec)))
    if out_json:
        out = {}
        for api in spec:
            out[api] = [{"method": m, "version": v, "params": sorted(p)}
                        for (m, v), p in spec[api].items()]
        json.dump(out, open(out_json, "w"), ensure_ascii=False, indent=2)
        print("写出 %s" % out_json)


if __name__ == "__main__":
    args = [a for a in sys.argv[1:]]
    out_json = None
    if "--json" in args:
        i = args.index("--json")
        out_json = args[i + 1]
        del args[i:i + 2]
    if not args:
        print(__doc__)
        sys.exit(1)
    report(parse(args), out_json)
