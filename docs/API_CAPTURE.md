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

（`dsm_api.captured.g.dart`，共 70 个函数，来自 100+ 个抓到的 api/method）

- SYNO.ActiveInsight：CompleteCollection.get / License.get / Setting.get / Package.get_status
- SYNO.WebStation：Status.get / PHP.get / Python.get / Docker.tags / ScriptLanguage.Utils.get / WebService.Portal.list / WebService.Service.list
- SYNO.DNSServer：Zone.list
- SYNO.LogCenter：RecvRule.list
- SYNO.MediaServer：Setting.get
- SYNO.OAUTH：Client.list
- SYNO.TextEditor：Preference.get
- SYNO.C2FS：Utils.load_global_config
- SYNO.Virtualization：已抓到若干（创建/列表/状态）
- SYNO.DownloadStation2：Captcha.list / Task.list / Task.Statistic.get
- SYNO.Foto：BackgroundTask.Info.list_user_task / Setting.Admin.get / Setting.TeamSpace.get /
  Setting.User.get / Setting.Wizard.get / UserInfo.me
- SYNO.SynologyDrive：get_status / Index.get_native_client_status / ShareSync.Connection.list
- SYNO.Personal：ProfilePhoto.get
- 以及此前未覆盖的 Core / FileStation / CloudSync / NoteStation / AudioStation 若干 method

## 抓包的两类限制（重要）

1. **WebSocket 应用**：Synology Calendar、Synology Contacts 走 `socket.io`（WebSocket）而非
   `entry.cgi`，HAR 里看不到 `SYNO.Cal.*` / `SYNO.Contacts.*`。这种只能抓 WebSocket 帧，
   本流程（HTTP HAR）覆盖不到。
2. **新标签应用**：Download Station / Synology Photos / Synology Drive / Virtual Machine Manager
   等会开**新浏览器标签**；按 tab 的网络抓包只跟当前标签，会漏掉。对策：点开应用后，
   `browse session_adopt --target-url <launchApp=...>` 接管新标签，再抓。

## 尚未抓到的应用（后续按同一循环补）

| 套件 | 命名空间 | 卡点 |
|---|---|---|
| Synology Calendar | `SYNO.Cal.*` | WebSocket，需抓 WebSocket 帧 |
| Synology Contacts | `SYNO.Contacts.*` | WebSocket |
| Synology Photos | `SYNO.Foto.*` | 部分已抓（Setting/UserInfo），需进入相册/共享空间交互 |
| Synology Drive | `SYNO.SynologyDrive.*` | 部分已抓（get_status），需进入管理/共享/版本 |
| Virtual Machine Manager | `SYNO.Virtualization.*` | 部分已抓，需更多交互 |
| Universal Search | `SYNO.Finder.*` | 点桌面搜索框触发 |
| Secure SignIn | `SYNO.SecureSignIn.*` | 控制面板模块 |
| Resource Monitor | `SYNO.Core.System.*` | 控制面板模块 |
| SAN Manager | `SYNO.SAS.*` / `SYNO.Core.ISCSI.*` | 部分已抓（Core.ISCSI） |

第三方套件（Jellyfin / Emby / alist / aliyun / aria2 / DDNS-GO / 迅雷）不是 `SYNO.*` API，
走各自反向代理端口，如需接入要单独按各自 HTTP API 实现。
