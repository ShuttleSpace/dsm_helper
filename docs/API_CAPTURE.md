# DSM API 抓包补全

## 目标与范围

- **目标**：把本机已安装套件的 API（`method` + 参数）从真实前端流量抓下来，补全到
  `lib/api/dsm_api.*`。`all_api.json5` 只有 api/version/path（且是 **1044 个命名空间的全量
  目录，不是安装列表**），**没有 method**，所以 method 必须靠抓包。
- **范围**：只抓实际已安装的 `SYNO.*` 套件（安装列表见 `SYNO.Core.Package list`）。
  第三方套件（Jellyfin / Emby / alist / aliyun / aria2 / DDNS-GO / 迅雷）不是 `SYNO.*`，
  走各自反向代理端口，不在范围；如需接入要单独按各自 HTTP API 实现。
- **现状**：`lib/api/` 已手写大量 API（core/photos/downloadstation/docker/filestation/…），
  抓包生成的文件是补充**尚未手写实现**的部分。

## 规则（必须遵守）

1. **不手拼请求**：登录态 Cookie 是 `_SSID`（不是 `_SID`），受保护 API 还要
   `X-SYNO-TOKEN`/`X-SYNO-HASH`，手写 `fetch` 缺这些会返回 `code=119`（invalidSession）。
   → 只抓页面自己发出的流量，不构造请求。
2. **生成文件不手改**：`lib/api/dsm_api.captured.g.dart` 是 `part`，由 `gen_api.py` 全量重建，
   要改就改抓包规格 `tool/captured_api.json` 或生成器，然后整份重新生成。
3. **去重**：`gen_api.py` 跳过 (a) `lib/api` 里已实现的 API 字符串、(b) 已存在的 `dsm*` 函数名
   （不同 api 串可能 collapse 成同名，如 `SYNO.Core.SecurityAutoBlock` 与
   `SYNO.Core.Security.AutoBlock` 都生成 `dsmCoreSecurityAutoBlockGet`）。
   → **已手写覆盖的套件抓了也不会生成新函数**，先查再决定要不要抓。
4. **写操作必须可逆、零风险**：一律「新建临时对象 → 立即删除」，**绝不碰已有数据**
   （尤其不能删到用户真实的文件/门户/记录）。测试对象名用纯字母数字（带 `-` 可能被
   表单校验拒，LogCenter 就报「数值不符合字段规定」）。
5. **删除后必须验证**：`remaining===false`（临时对象没了）**且**已有对象仍完好
   （如 WebStation 删除后 `hasGitea===true`）。任一不满足就停下先清理，不做下一步。
6. **每轮收尾幂等**：合并**全部** HAR 重新生成 → `flutter analyze` + `flutter test` 全绿 → 提交。
   `git add` 只显式加 API/doc/tool 文件，**不要把工作区里用户并发的未提交改动带进提交**。
7. **生成函数未经逐个真机联调**：只按抓包规格生成，method/参数来自真实请求，但没在 app 里
   逐个调用验证过。

## 工具链

| 文件 | 作用 |
|---|---|
| `tool/har_dump.py` | 解析 HAR → `{api: [{method, version, params}]}`，递归展开 `SYNO.Entry.Request?compound=[...]`；`_clean()` 剥掉 URL 里带引号的 api 值、容忍 int version |
| `tool/captured_api.json` | 已抓到的合并规格（提交进仓库，可复现） |
| `tool/gen_api.py` | 读规格、按上面规则去重，生成 `lib/api/dsm_api.captured.g.dart`；`existing_fn_names()` 负责函数名去重 |

`har_dump.py` 可一次传多个 HAR 合并；`gen_api.py` 接受 `.har` / `.json` 输入。
HAR 缓存目录：`/private/var/folders/gd/kplv_kf568q2klrxy2kg_rkw0000gn/T/opencode/dsm-capture/*.har`。

## 抓包方案（可复现 SOP）

前置：Chrome 打开并登录 DSM（`http://192.168.8.40:5000/`，本机账户 `humphrey` + 2FA），
browse 扩展已连接。本机 browser id `chrome-humphreydemac-mini`（示例值）。

### 1) 建会话、确认登录态

```javascript
const s = await tools.browse.session_new({ browser, url: "http://192.168.8.40:5000/" });
const sid = s.session.id;   // 后面每次 execute 都要显式带 session
```

### 2) 打开应用

- **页内应用**（File Station、控制面板各模块、DNS Server、Log Center、Web Station）：
  桌面菜单里点开即可，同一个 tab，抓包直接跟得到。
- **新标签应用**（Download Station / Photos / Drive / VMM / Calendar / Contacts）：
  按 tab 抓包会漏。必须 `session_adopt --target-url <launchApp=...>` 接管该标签，
  **再 `page.reload()`**（否则 bootstrap 的 API 早就发完，抓到 0 条）。
  入口：`http://192.168.8.40:5000/webman/index.cgi?launchApp=SYNO.SDS.<App>.Instance`。

### 3) 抓包 + 落盘（新版工具签名）

> **顶层 `network stop` 不再写 HAR 文件**（忽略 `--output`），只返回 `exchanges`。
> 落盘必须在 `execute` 的 Playwright realm 里用**内部** `network` helper + `files.write`。
> 顶层 `tools.browse.network` 与 realm 内 `network` 是两套，别混用。

骨架（`code` 是传给 `tools.browse.execute` 的字符串）：

```javascript
// 在 Playwright realm 内
const st = await network.status();
if (st.active) await network.cancel();   // realm 崩过的话捕获可能仍 active
await network.start();

// ... 这里驱动 UI（见下节 UI 驱动） ...

const stop = await network.stop();
const har = { log: { entries: (stop.exchanges || []).map(e => ({
  request: {
    method: e.request.method,
    url: e.request.url,
    postData: e.request.body && e.request.body.text
      ? { mimeType: e.request.body.mimeType || '', text: e.request.body.text }
      : undefined
  }
})) }};
await files.write('/…/dsm-capture/<app>.har', JSON.stringify(har));  // 返回 Promise，必须 await
```

外层调用：`await tools.browse.execute({ session: sid, code, timeoutMs: 0 })`（长流程用 `0`
禁用超时）。**内层 `code` 不能用反引号**（会破坏外层 JSON）；脚本太长容易括号不匹配，
拆成小步 `execute` 更稳。

### 4) 修脱敏坏 URL（解析前必做）

browse 会把部分请求的 url 脱敏成 `http://192.168.8.4[redacted]...`，`har_dump.py` 的
`urlparse` 会报 `Invalid IPv6 URL`。**postData 是好的，不要丢 entry**，只替换 url：

```python
import json
p = '/…/dsm-capture/<app>.har'
d = json.load(open(p))
for e in d['log']['entries']:
    if '[redacted]' in e.get('request', {}).get('url', ''):
        e['request']['url'] = 'http://127.0.0.1/webapi/entry.cgi'   # 合法占位符
json.dump(d, open(p, 'w'))
```

### 5) 合并 → 生成 → 验证 → 提交

```bash
D=/…/dsm-capture
python3 tool/har_dump.py $D/*.har --json tool/captured_api.json   # 全量合并，幂等
python3 tool/gen_api.py tool/captured_api.json
flutter analyze && flutter test
git add -u lib/api/dsm_api.captured.g.dart tool/captured_api.json docs/API_CAPTURE.md
```

---

## 写操作捕获（A1）

**结论**：写操作走普通 HTTP `entry.cgi`，页内应用的 HAR 能抓到；新标签应用
（Calendar/Contacts）写帧抓不到（疑似独立 socket.io 连接，非 `request_webapi` 信封），
**别在那里耗**。做法：新建临时对象 → 立即删除，全程抓包。

删除标准流程：选中网格行 → 工具栏「删除」→ 确认框里再点「删除」→ 验证无残留。

### 已验证用例

| 套件 | 用例 | 抓到的写 method | 结果 |
|---|---|---|---|
| File Station | 新建文件夹→删除 | `CreateFolder.create v2 [folder_path,force_parent,name]`、`Delete.start v2 / status v1` | 真机成功，无残留；**但这两个 API 已手写，gen_api 整条跳过** |
| DNSServer | 新建主域区→删除 | `Zone.MasterZoneConf.create v1`（10 参数）、`Zone.delete v1 [items]` | 真机成功，无残留 |
| WebStation | 新建备用门户→删除 | `WebService.Portal.create v1 [portal]`、`remove v1 [ids]` | 真机成功，无残留；**删除 method 叫 `remove` 不是 `delete`**；未碰已有 gitea 门户 |
| LogCenter | 新建接收规则 | `RecvRule.create v1 [format,name,origin_name,port,protocol,ssl]` | DSM UI 自带请求把值编码成 `%22…%22`（带引号）致 `success:false`，**仅抓到 method、未真建成功** |

启示：**`success:false` / `created:false` 仍可能已抓到 method**（规格来自请求，不依赖响应成败）。

---

## 踩坑清单

### A. 工具 / 环境

- **`document` / `page` 只在嵌套 `tools.browse.execute` 的 Playwright realm 里存在**，
  顶层 `execute` 的 Code Mode realm 里没有（会报 `Unknown identifier`）。
- **`page.evaluate(fn, arg)` 只接受一个参数**；多参数要包成对象
  `page.evaluate((o)=>{const {t,sel}=o; …}, {t, sel})`。
- **脱敏**：browse 会把 `_sid`/Cookie/URL 等替换成 `${BC_SECRET_n}` 或 `[redacted]`；
  api/method/参数名不受影响，但坏 URL 会崩解析器（见方案第 4 步）。
- **browse 中继会重启**：`session` / `target` 可能全部丢失（`Session not found`）。
  重建会话后**第一件事是检查并清理上一轮残留的临时对象**（数据安全），再继续。
- **realm 崩溃后网络捕获仍 active**：下次 `network.start()` 报 `already active`，
  先 `status()` + `cancel()`。
- **内层 `code` 用普通字符串**、避免反引号；长脚本拆小步。
- 全局 HAR 缓存目录要用已批准的 `…/opencode/dsm-capture/`，别用 `/tmp`。

### B. 抓包链路

- **批量调用**：应用大量用 `SYNO.Entry.Request?compound=[...]`，真正的 api/method 在
  compound 的 URL 编码 JSON 里（可嵌套），`har_dump.py` 已递归展开。
- **首次加载只覆盖读接口**（list/get/info）。增删改必须在界面里实际操作后再抓一次。
- **新标签 + 必须 reload**（见方案第 2 步）；Calendar/Contacts 就是这样补上的。
- **WebSocket 不是应用 API**：桌面 shell 的 `socket.io`（`/synoscgi.sock/`）里几乎只有
  `Core.System.Utilization` 心跳和 `AppNotify`。Calendar/Contacts 读业务 API 全走 HTTP
  `entry.cgi`，HAR 可抓；曾误判为「WS 应用抓不到」，实际只是漏了 adopt+reload。
  Whistle 的 WS 帧能力本流程用不上，不必让 Chrome 走代理。
- **`network.stop()` 只返回 exchanges**、不写文件（见方案第 3 步）；`files.write` 要 await。

### C. UI 驱动

- **控制面板图标 `snapshot()` 不渲染文字**：用 `page.evaluate` 按 `innerText` 精确匹配
  点击，比按 role/name 可靠。
- **窗口类名会变**：点 tab 后窗口可能重渲染（如 `layout-window-page-list` →
  `…-app`）；多窗口时用 `.filter(…).pop()` 取最上层，别写死 index。
- **工具栏删除要先选中行**：ExtJS 网格行未选中时点「删除」静默无效；先点
  `.x-grid3-row` 使其 `x-grid3-row-selected`，再点删除才弹确认框。
- **确认框是自定义窗口**（`.x-window` 里的「取消/删除」「是否确定删除此区域？」
  「您确定要删除所选择的项目？」），不是原生 `confirm()`；`page.on('dialog')` 抓不到。
  按「窗口文本 + 按钮文本」定位。
- **菜单项类名不统一**：Web Station「操作」菜单是 `.v-menu-item`，File Station 是
  `.x-menu-item`，用错选择器会点到隐藏元素、删除不生效。
- **表单校验**：名称别用 `-`（LogCenter 报「数值不符合字段规定」），用纯字母数字。
- **DOM 更新延迟**：创建后列表可能不立即刷新，`created:false` 不代表没建成——
  看响应的 `success:true` 更可靠，或关对话框、重切 tab 再读列表确认真相。
- **选中行**：`.filter({hasText})` 常误匹配到大容器（如 `#sds-desktop`），
  优先用精确文本单元格向上找 `row/grid/item` 父元素再点。

### D. 生成 / 提交

- **函数名冲突**（见规则 3）：按已有函数名再过滤一层，避免重复定义。
- **提交别夹带**：工作区常有会话前就存在的用户改动（`lib/pages/*`、`lib/stores/*`、
  ios Xcode 噪音、`tools/`），`git add -u` 会把它们全 stage 进去；只显式 add 本任务文件。

---

## 已生成代码的命名空间

（`dsm_api.captured.g.dart`，共 **217** 个函数）

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
- SYNO.Core.* 其余：146 个 API / 167 个 method（桌面 shell + 控制面板轮询带出来的）
- SYNO.ActiveInsight：CompleteCollection.get / License.get / Setting.get / Package.get_status
- SYNO.WebStation：Status.get / PHP.get / Python.get / Docker.tags / ScriptLanguage.Utils.get /
  WebService.Portal.{list,create,remove} / WebService.Service.list
- SYNO.DNSServer：Zone.{list,delete} / Zone.MasterZoneConf.create
- SYNO.LogCenter：RecvRule.{list,create}
- SYNO.MediaServer：Setting.get ｜ SYNO.OAUTH：Client.list ｜ SYNO.TextEditor：Preference.get
- SYNO.C2FS：Utils.load_global_config
- SYNO.Virtualization：Cluster.{check_exist,check_status,get_total_progress,get_host,get} /
  Utils.{activate_mem_cache,check_vnc_connected} / Setting.General.get
- SYNO.DownloadStation2：Captcha.list / Task.list / Task.Statistic.get
- SYNO.Foto：BackgroundTask.Info.list_user_task / Setting.{Admin,TeamSpace,User,Wizard}.get /
  UserInfo.me；SYNO.FotoTeam.* 若干
- SYNO.SynologyDrive：get_status / Index.get_native_client_status / ShareSync.Connection.list
- SYNO.Personal：ProfilePhoto.get ｜ SYNO.AudioStation / SYNO.NoteStation / SYNO.CloudSync /
  SYNO.FileStation / SYNO.FotoTeam 若干

Universal Search / Secure SignIn / Resource Monitor / Container Manager / 安全性 / 网络 /
WebDAV / USB Copy / SecurityAdvisor 等控制面板模块已覆盖。

## 后续优先级（再开时别重复分析）

- **🟢 唯一值得继续抓写的**：Synology Photos `SYNO.Foto.*` 写方法（app 页面最多，写全空）。
  可逆用例：新建相册→删除 / 加收藏→取消。**只删自己新建的对象，绝不碰真实照片**。
  风险：新标签应用，写帧有「抓不到」的先验概率（Calendar 前车之鉴）。
- **🟡 小**：LogCenter 归档/通知/日志发送的 `set` 开关。
- **🔴 白抓**（已手写，gen_api 会跳过）：Download Station、Docker、File Station。
- **🔴 抓不到 / 不可逆 / 低收益**：Calendar/Contacts 写；VMM/iSCSI 写；控制面板 Core.*
  （已饱和）；TextEditor/MediaServer/OAUTH/SecureSignIn/ActiveInsight/USBCopy/WebDAV/S2S/
  NoteStation（各仅 1 个 get）。
- **另一条线**（不是抓 method，是补功能）：`virtual_machine` / `universal_search` /
  `notify` / `security_scan` / `storage_manager` / `iscsi` / `control_panel` /
  `resource_monitor` 这些页面 **0 个手写 api 文件**，全靠抓包生成的 `dsmCore*`
  （页面引用 26 次）撑着，是「功能没接全」的缺口。

## 尚未抓到的应用

| 套件 | 命名空间 | 卡点 |
|---|---|---|
| Synology Photos | `SYNO.Foto.*` | 写方法未抓（Setting/UserInfo 已抓），需进相册/共享空间交互 |
| Synology Drive | `SYNO.SynologyDrive.*` | 部分已抓（get_status），需进管理/共享/版本 |
| Virtual Machine Manager | `SYNO.Virtualization.*` | 已抓多为 check/get，写操作不可逆 |
| SAN Manager | `SYNO.SAS.*` | `SYNO.Core.ISCSI.*` 已抓若干，SAS 命名空间未触发 |
| 新标签应用 | Calendar / Contacts | 写帧走独立 socket，HAR 抓不到 |
