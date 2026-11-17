// Whistle 规则（JS 模块格式：导出 { name, rules }）
//
// 用法：
//   whistle start -p 8899 -H 0.0.0.0 -D ~/whistle-dsm/storage
//   whistle add --force tools/whistle/rules.js
//   打开 http://192.168.8.102:8899/ 查看 Network / Rules 面板
//
// 设备侧把 HTTP 代理设为 192.168.8.102:8899。
//
// 注意：whistle 的 host 匹配**不支持 IP 字面量**，必须用域名。
// 这里用 hosts:// 把 dsm.local 指向真实 NAS，浏览器访问 http://dsm.local:5000
// 就能既命中规则又连到 NAS。

module.exports = {
  name: 'dsm-capture',

  rules: `
# ---- 1. 域名 -> NAS ----
dsm.local/ hosts://192.168.8.40
dsm.local:5000/ hosts://192.168.8.40

# ---- 2. 标记：便于在 Network 面板按 x-dsm-capture 过滤 ----
dsm.local:5000/webapi/entry.cgi resHeaders://x-dsm-capture=entry
dsm.local:5000/webapi/auth.cgi resHeaders://x-dsm-capture=auth
dsm.local:5000/api/ resHeaders://x-dsm-capture=api

# ---- 3. 记录请求头/响应头到 log 面板 ----
# 重点观察：Content-Range / Range / Accept-Ranges（断点续传）
#           以及分片上传的自定义头与参数
dsm.local:5000/webapi/entry.cgi log://{reqHeaders}~{resHeaders}
dsm.local:5000/webapi/auth.cgi log://{reqHeaders}~{resHeaders}
dsm.local:5000/api/ log://{reqHeaders}~{resHeaders}
`,
};
