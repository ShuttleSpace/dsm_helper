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

> **工具签名变更（重要）**：新版 browse 的顶层 `network stop` 不再写 HAR 文件
> （忽略 `--output`），只返回 `exchanges` 数组。要落盘得在 `execute` 的 Playwright
> realm 里用内部 helper：`await network.start()` → 操作 → `const s = await network.stop()`，
> 把 `s.exchanges` 转成最小 HAR 结构 `{log:{entries:[{request:{method,url,postData}}]}}`，
> 再 `await files.write(<绝对路径>, JSON.stringify(har))`（`files.write` 返回 Promise，
> 必须 await）。`document`/`page` 只在嵌套 `tools.browse.execute` 的 code 里可用，且
> 内层 code 不能用反引号（会破坏外层 JSON）。

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
- **函数名冲突**：不同 api 字符串可能 collapse 成同一个 `dsm*` 函数名，例如
  `SYNO.Core.SecurityAutoBlock`（`dsm_api.vpn.dart` 里手写的）与
  `SYNO.Core.Security.AutoBlock`（抓包/all_api.json5 里的正确串）都会生成
  `dsmCoreSecurityAutoBlockGet`。`gen_api.py` 已按「已有函数名」再过滤一层，避免重复定义。

## 已将抓到的规格生成代码的命名空间

（`dsm_api.captured.g.dart`，共 217 个函数）

- SYNO.Cal：Cal.list / Event.list / Todo.{list,count_todo} / Setting.{get,set} /
  Contact.{list,get_user_info} / Proxy.{get_config,task_list} / SyncUser.sync /
  Timezone.list / UserAction.set
- SYNO.Contacts：Addressbook.list / Contact.{list,list_group} / ExternalSource.list /
  Info.{get,get_timezone} / Label.list
- SYNO.Finder：Bookmark.get / FileIndexing.Folder.list / Preference.get / Settings.get
- SYNO.SecureSignIn：AMFA.Policy.get
- SYNO.Docker：Container.{list,stats} / Image.list / Migrate.status / Network.list /
  Project.list / Registry.get
- SYNO.Backup / SYNO.DSM / SYNO.Network / SYNO.S2S / SYNO.SecurityAdvisor /
  SYNO.USBCopy / SYNO.WebDAV：控制面板模块各自若干
- SYNO.Core.Security.*：AutoBlock / DSM / DoS / Firewall 等一批；Core.ISCSI.LUN / FCTarget
- 控制面板图标的真实文本在 DOM 里但 `snapshot()` 不渲染，用
  `page.evaluate` 按 `innerText` 精确匹配点击，比按 role/name 可靠。
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

## 抓包的关键坑（修正过一次）

- **新标签 + 必须 reload**：Download Station / Photos / Drive / VMM / Calendar / Contacts
  都会开**新浏览器标签**，按 tab 抓包只跟当前标签，会漏。对策：
  `browse session_adopt --target-url <launchApp=...>` 接管该标签，**再 `page.reload()`**
  （否则应用已加载完，bootstrap 的 API 调用早就发完了，抓到 0 条）。Calendar/Contacts
  就是这样补上的。
- **WebSocket 不是应用 API**：桌面 shell 有一条 `socket.io` 长连接走
  `/synoscgi.sock/`（Playwright `page.on('websocket')` 能抓帧），但里面几乎只有
  `SYNO.Core.System.Utilization` 心跳和 `AppNotify`。Calendar/Contacts 的业务 API
  （`SYNO.Cal.*` / `SYNO.Contacts.*`）**全部走 HTTP `entry.cgi`**，HAR 就能抓到。
  → 之前误判为「WebSocket 应用、HAR 覆盖不到」，实际只是漏了 adopt + reload。
  Whistle 虽然也支持 WS 帧，但本流程不需要它，也不必让 Chrome 走代理。

## 尚未抓到的应用（后续按同一循环补）

| 套件 | 命名空间 | 卡点 |
|---|---|---|
| Synology Photos | `SYNO.Foto.*` | 部分已抓（Setting/UserInfo），需进入相册/共享空间交互 |
| Synology Drive | `SYNO.SynologyDrive.*` | 部分已抓（get_status），需进入管理/共享/版本 |
| Virtual Machine Manager | `SYNO.Virtualization.*` | 部分已抓，需更多交互 |
| 各应用 | 写操作（create/set/delete） | 只读页面抓不到，需在界面里实际增删改后再抓 |
| SAN Manager | `SYNO.SAS.*` | `SYNO.Core.ISCSI.*` 已抓若干，SAS 命名空间未触发 |

## 写操作捕获（A1：页内应用在 fresh session 抓写）

结论：**写操作走普通 HTTP `entry.cgi`，页内应用（File Station 窗口）的 HAR 能抓到**，
链路已验证通。做法：在界面新建临时对象 → 立即删除（可逆、零风险、不碰已有数据）。

- 实测用例：File Station **新建文件夹 → 删除** 闭环。抓到 `SYNO.FileStation.CreateFolder.create v2`
  （params: `folder_path, force_parent, name`）和 `SYNO.FileStation.Delete.start/status`
  （`accurate_progress, path` / `taskid`）。这两个 API **已在 `lib/api` 手写实现**，
  所以 `gen_api.py` 整条跳过，不重复生成。
- 注意：`network stop` 现在只返回 exchanges，要在 `execute` 里用内部 `network` helper +
  `files.write` 落盘（见上面「工具签名变更」）。
- 残留清理：删除用例后务必 `remaining===false` 验证无残留临时文件，否则重新点确认框的「删除」。

### 已验证的写用例（新增函数）

| 套件 | 用例 | 抓到的写 method | 结果 |
|---|---|---|---|
| DNSServer | 新建主域区→删除 | `Zone.MasterZoneConf.create v1`、`Zone.delete v1 [items]` | 真机成功，无残留 |
| WebStation | 新建备用门户→删除 | `WebService.Portal.create v1 [portal]`、`remove v1 [ids]` | 真机成功，无残留；**删除 method 叫 `remove` 不是 `delete`** |
| LogCenter | 新建接收规则 | `RecvRule.create v1 [format,name,origin_name,port,protocol,ssl]` | DSM UI 自带请求把值编码成 `%22...%22`（带引号）导致 `success:false`，仅抓到 method，未真建成功 |

### 写用例的 UI 坑

- **工具栏删除要先选中行**：ExtJS 网格（DNS/LogCenter）行未选中时点「删除」静默无效；
  先点 `.x-grid3-row` 行元素使其 `x-grid3-row-selected`，再点删除才弹确认框。
- **菜单项类名不统一**：Web Station「操作」菜单是 `.v-menu-item`（不是 `.x-menu-item`），
  用错选择器会点到隐藏元素、删除不生效。
- **DOM 更新延迟**：创建后列表可能不立即刷新，`created:false` 不代表没建成——
  关对话框、重切 tab 再读列表确认真相（Web Station 就是这样：`success:true` 但列表延迟）。
- **browse 导出的 HAR 里有脱敏坏 URL**：部分请求的 url 被替换成 `http://192.168.8.4[redacted]...`，
  `har_dump.py` 的 `urlparse` 会报 `Invalid IPv6 URL`。数据（postData）没坏——解析前把这些 url
  替换成合法占位符（如 `http://127.0.0.1/webapi/entry.cgi`）即可，不要丢 entry。

Universal Search / Secure SignIn / Resource Monitor / Container Manager / 安全性 / 网络 /
WebDAV / USB Copy / SecurityAdvisor 等控制面板模块已在本轮覆盖。

第三方套件（Jellyfin / Emby / alist / aliyun / aria2 / DDNS-GO / 迅雷）不是 `SYNO.*` API，
走各自反向代理端口，如需接入要单独按各自 HTTP API 实现。
