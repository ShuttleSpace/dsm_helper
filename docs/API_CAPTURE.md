# DSM API 抓包补全

目标：把本机已安装套件的 API（`method` + 参数）从真实前端流量抓下来，补全到
`lib/api/dsm_api.*`。清单（`all_api.json5`）只有 api/version/path，**没有 method**，
所以 method 必须靠抓包。

## 工具链

| 文件 | 作用 |
|---|---|
| `tool/har_dump.py` | 解析 HAR → `{api: [{method, version, params}]}`，会递归展开 `SYNO.Entry.Request?compound=[...]` 批量调用 |
| `tool/captured_api.json` | 已抓到的合并规格（提交进仓库，可复现） |
| `tool/gen_api.py` | 读规格，跳过 `lib/api` 已实现的 API，生成 `lib/api/dsm_api.captured.g.dart` |

生成文件已作为 `part` 接入 `lib/api/dsm_api.dart`，不要手改 `.g.dart`。

## 抓包循环（每个应用一次）

前置：Chrome 打开并登录 DSM（`http://192.168.8.40:5000/`），browse 扩展已连接。

```bash
# 1) 开始抓包（会话 id 来自 tools.browse.session_*）
browse network start --session <sid> --url /webapi/ --resource-type xhr --resource-type fetch

# 2) 驱动界面：打开一个应用 / 点进各页面（用 browse.execute 跑 Playwright）
#    应用入口在「套件中心 → 打开 X」，或直接 goto:
#    http://192.168.8.40:5000/webman/index.cgi?launchApp=SYNO.SDS.<App>.Instance

# 3) 停止并导出 HAR
browse network stop --session <sid> --output /tmp/<app>.har

# 4) 解析并合并进规格，然后重新生成
python3 tool/har_dump.py /tmp/<app>.har --json /tmp/<app>.json
python3 tool/gen_api.py tool/captured_api.json /tmp/<app>.json
flutter analyze lib/api
```

> `har_dump.py` 支持一次传多个 HAR 合并；`gen_api.py` 支持 `.har` 和 `.json` 输入。

## 关键事实（踩过的坑）

- **鉴权**：登录态 Cookie 是 `_SSID`（不是 `_SID`），且受保护 API 需要
  `X-SYNO-TOKEN`/`X-SYNO-HASH`。手写 `fetch` 缺这些会返回 `code=119`（invalidSession）。
  → 所以不自己拼请求，直接抓页面自己的流量。
- **批量调用**：应用大量使用 `SYNO.Entry.Request?method=request&compound=[...]`，
  真正的 api/method 在 `compound` 的 URL 编码 JSON 里（可嵌套）。`har_dump.py` 已递归展开。
- **脱敏**：browse 会把 `_sid`/Cookie/URL 等替换成 `${BC_SECRET_n}`；api/method/参数名不受影响。
- **新标签页**：应用若在新标签打开，抓包（按 tab）抓不到。优先用 `launchApp` 在同一 tab 打开，
  或 `session_adopt` 新标签后再抓。
- **首次加载**只覆盖读接口（list/get/info）。增删改需在应用里继续操作后再抓一次。

## 已将抓到的规格生成代码的命名空间

（`dsm_api.captured.g.dart`，共 52 个函数）

- SYNO.ActiveInsight：CompleteCollection.get / License.get / Setting.get / Package.get_status
- SYNO.WebStation：Status.get / PHP.get / Python.get / Docker.tags / ScriptLanguage.Utils.get / WebService.Portal.list / WebService.Service.list
- SYNO.DNSServer：Zone.list
- SYNO.LogCenter：RecvRule.list
- SYNO.MediaServer：Setting.get
- SYNO.OAUTH：Client.list
- SYNO.TextEditor：Preference.get
- SYNO.C2FS：Utils.load_global_config
- 以及此前未覆盖的 Core/FileStation/CloudSync/NoteStation/SynologyDrive/AudioStation 若干 method

## 尚未抓到的应用（后续按同一循环补）

已安装但还缺 app 级 method 的套件：

| 套件 | 命名空间 | 说明 |
|---|---|---|
| Synology Calendar | `SYNO.Cal.*` | `launchApp` 只开了桌面 SPA，应用窗口未触发；需进入应用后操作 |
| Synology Contacts | `SYNO.Contacts.*` | 同上 |
| Universal Search | `SYNO.Finder.*` | 点桌面搜索框触发 |
| Secure SignIn | `SYNO.SecureSignIn.*` | 控制面板模块 |
| SAN Manager | `SYNO.SAS.*` / `SYNO.Core.ISCSI.*` | 已抓到 Core.ISCSI 部分 |
| Virtual Machine Manager | `SYNO.Virtualization.*` | 已有 2 个，需补 |
| Synology Photos | `SYNO.Foto.*` | 已有 FotoTeam，需补 Foto |
| Download Station | `SYNO.DownloadStation2.*` | 已有基础，需补 2.x |
| Synology Drive | `SYNO.SynologyDrive.*` | 需补管理端 |

第三方套件（Jellyfin / Emby / alist / aliyun / aria2 / DDNS-GO / 迅雷）不是 `SYNO.*` API，
走各自反向代理端口，如需接入要单独按各自 HTTP API 实现。
