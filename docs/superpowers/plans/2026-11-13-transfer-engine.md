# 传输引擎（多线程 + 断点续传 + 后台）实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 给 DSM Helper 加上可后台续传、多线程分片的上传/下载能力，引擎用 `background_downloader`，DSM 协议用一层薄适配封装。

**Architecture:** 下载 = 用 `base64(路径)` 拼出 `/fbdownload/<名>?dlink=<b64>&mode=download&SynoToken=...`，交给 `background_downloader` 的 `ParallelDownloadTask`（内部按 `Range` 并发拉取）。上传 = 源文件切临时分片，每片一个 `UploadTask`（v3 字段，并发），NAS 拼合；拿不到 v3 契约时回退 v2 单请求。状态用 signal store 持久化，跨 app 重启 `resume` 未完成任务。

**Tech Stack:** Flutter/Dart；`background_downloader ^9.5.2`（已依赖）；signals（已迁移）；Dio（现有 `_httpPost`/`_httpDownload`）。

**Spec:** `docs/superpowers/specs/2026-11-13-transfer-engine-design.md`

## Global Constraints

- 引擎必须是 `background_downloader`（已依赖，`pubspec.yaml` 中 `background_downloader: ^9.5.2`）。
- 认证：传输请求带 `_SSID` cookie 或 `SynoToken`；NAS 地址 `192.168.8.40:5000`（同网段）。
- 平台：Android 为主（前台服务已验证可跑）；iOS 需配置 background modes。
- 与现有 `lib/api/dsm_api.*` 风格一致；新增文件放 `lib/api/` 与 `lib/services/`。
- 不引入新依赖；不做 NAS 侧托管同步、不做增量同步、不重写整套文件 UI。

## Review Focus

1. **上传 v3 字段名错误 → NAS 上文件静默损坏。** 契约必须经 Task 1 实测确认；并做上传后校验和比对（真机）。
2. **`/fbdownload` 不认 `Range` → `ParallelDownloadTask` 失败/重复落盘。** Task 1 必须确认返回 206。
3. **app 被杀后任务丢失（无续传）。** Task 6 持久化 + 启动 `resume`；真机杀进程验证。
4. **分片临时文件未清理 → 磁盘泄漏。** 拼合成功后删除临时分片。
5. **长传输中 token 过期 → 中段 401。** 行为预期：刷新 token 重试或明确报错，而非静默失败。

---

### Task 1: 验证 DSM 传输契约（Spike）

**Files:**
- Create: `docs/superpowers/specs/2026-11-13-transfer-contract.md`
- Create: `lib/api/dsm_api.filestation.transfer_contract.dart`

**Interfaces:**
- Produces: `lib/api/dsm_api.filestation.transfer_contract.dart` 暴露后续任务依赖的常量/开关：
  - `const bool kUploadV3Supported` —— v3 分片是否可用
  - `const int kDefaultChunkSizeBytes` = 8 * 1024 * 1024
  - `const int kDefaultConcurrency` = 4
  - `UploadV3Fields` 数据类：v3 分片上传每个 multipart 字段名（`path`/`filename`/`upload_id`/`part_number`/`total_parts`/`offset`/`offset_size`/`overwrite`/`mtime`/`size`），及"末片触发拼合"还是"需单独 complete 调用"
  - `const bool kDownloadDlinkSelfConstruct` —— 是否可用 `base64(path)` 直接构造 dlink（免调 `SYNO.FileStation.Download`）

**Steps:**
- [ ] **Step 1: 取得有效 FileStation 会话 SID**（用户在执行时提供；从 DSM 网页控制台 `document.cookie.match(/_SSID=([^;]+)/)[1]` 取新鲜值，旧抓包 SID 已 119 失效）。
- [ ] **Step 2: 下载侧实测** —— 对一个已知文件发 `GET /fbdownload/<名>?dlink=<base64(path)>&mode=download&SynoToken=<token>`，先无 `Range` 确认 200，再带 `Range: bytes=0-1023` 确认返回 **206** 且 body 为前 1KB。记录 `SynoToken` 取值来源（`connection_store` 中持久化的 `syno_token`）。
- [ ] **Step 3: 上传 v3 实测** —— 构造 2 分片 v3 上传（`api=SYNO.FileStation.Upload&method=upload&version=3`），第 1 片取响应中的 `upload_id`，第 2 片带 `upload_id`，确认末片后 NAS 拼出完整文件。记录确切字段名与拼合时机；若 NAS 不支持 v3（报错），则置 `kUploadV3Supported=false`，后续走 v2 回退。
- [ ] **Step 4: 把以上结论写入 `transfer_contract.dart` 与 `transfer-contract.md`**（字段名、是否 206、是否自构造 dlink、是否 v3）。若执行时仍无有效 SID，则按 fallback 写：`kUploadV3Supported=false`、`kDownloadDlinkSelfConstruct=false`（下载改走 `SYNO.FileStation.Download` 取 dlink），并在文档显式标注"未实测，待真机补验"。
- [ ] **Step 5: Commit** `docs/.../transfer-contract.md` 与 `lib/api/dsm_api.filestation.transfer_contract.dart`

---

### Task 2: DSM 传输 URL / 契约纯函数（单测）

**Files:**
- Create: `lib/api/dsm_api.filestation.transfer_url.dart`
- Test: `test/api/dsm_api.filestation.transfer_url_test.dart`

**Interfaces:**
- Consumes: `lib/api/dsm_api.filestation.transfer_contract.dart`（`kDownloadDlinkSelfConstruct`）
- Produces:
  - `String dsmBase64Path(String path)` —— `base64(path)`，路径原样编码，不做 URL 编码
  - `String fbDownloadUrl({required String hostname, required String path, required String synoToken})` —— 返回 `http://<hostname>:5000/fbdownload/<末段>?dlink=<base64(path)>&mode=download&SynoToken=<token>`；当 `!kDownloadDlinkSelfConstruct` 时改为调用 `SYNO.FileStation.Download` 取 dlink（保留一个 `Future<String> fbDownloadUrlFromApi(...)` 变体）
  - `String uploadEntryUrl({required String hostname, required String synoToken, required int version})` —— `http://<hostname>:5000/webapi/entry.cgi?api=SYNO.FileStation.Upload&method=upload&version=<version>&SynoToken=<token>`

**Steps:**
- [ ] **Step 1: 写失败测试** —— `test_dsmBase64Path` 断言 `dsmBase64Path("/Download/a.zip")` == `base64("/Download/a.zip")`；`test_fbDownloadUrl` 断言对 `hostname=192.168.8.40`、`path=/Download/a.zip`、`synoToken=T` 返回以 `/fbdownload/a.zip?dlink=` 开头且含 `&mode=download&SynoToken=T`；`test_uploadEntryUrl` 断言含 `version=3`。
- [ ] **Step 2: 跑测试确认失败**（函数未定义）。
- [ ] **Step 3: 在 `transfer_url.dart` 实现上述三个函数**（纯字符串/编码，无网络）。
- [ ] **Step 4: 跑测试确认通过** `flutter test test/api/dsm_api.filestation.transfer_url_test.dart`。
- [ ] **Step 5: Commit。**

---

### Task 3: background_downloader 原生接入与引擎初始化

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`（前台服务通知渠道、`INTERNET`/`POST_NOTIFICATIONS` 权限、`FileDownloader` 所需 provider/服务，按 `background_downloader` 官方 Android 配置）
- Modify: `ios/Runner/Info.plist`（background modes：fetch/processing，若用）
- Create: `lib/services/transfer_engine.dart`
- Modify: `pubspec.yaml`（确认 `background_downloader` 版本与平台配置项，无需升级）

**Interfaces:**
- Produces: `lib/services/transfer_engine.dart`：
  - `Future<void> initTransferEngine()` —— 调用 `FileDownloader().configure(...)`（含 `androidNotification` 配置），并注册全局状态回调（`FileDownloader().updates.listen` 转发到 store，见 Task 6）
  - 提供 `Map<String,String> authHeaders()` —— 从 `connection_store` 读取 `cookie`/`syno_token` 组装请求头/查询参数，供 Task 4/5 注入

**Steps:**
- [ ] **Step 1: 按 `background_downloader` 文档补齐 Android/iOS 原生配置**（前台服务通知渠道是"后台/被杀也能继续"的必要项；漏配会导致传输被系统杀掉）。
- [ ] **Step 2: 实现 `initTransferEngine()` 与 `authHeaders()`**，在 app 启动时调用一次（接 `connection_store` 初始化之后）。
- [ ] **Step 3: 编译验证** `flutter build apk --debug` 通过（本机已验证可构建）；无新 lint 告警 `flutter analyze`。
- [ ] **Step 4: Commit。**

---

### Task 4: 下载适配层（多线程 + 续传，ParallelDownloadTask）

**Files:**
- Modify: `lib/services/download.dart`（`enqueDownloadTask` 改走新引擎，保留签名以最小改动 UI）
- Create: `lib/services/transfer_download.dart`

**Interfaces:**
- Consumes: `fbDownloadUrl` / `fbDownloadUrlFromApi`（Task 2）、`initTransferEngine`/`authHeaders`（Task 3）、`connection_store`（`hostname`、`path` 来源）
- Produces:
  - `Future<String> enqueueFileDownload({required String remotePath, required String destDir, String? destName})` —— 拼 `fbDownloadUrl` → 构造 `ParallelDownloadTask(url, filename, directory, headers: authHeaders())` → `FileDownloader().enqueue(task)`，返回 `task.taskId`
  - `existing enqueDownloadTask(url, fileName, {onPermissionDenied})` 内部改调 `enqueueFileDownload`（保持 `lib/pages/file/file.dart:323` 调用点不变）

**Steps:**
- [ ] **Step 1: 写测试** `test/services/transfer_download_test.dart`：`enqueueFileDownload` 在 mock `FileDownloader` 下返回非空 `taskId` 且 `ParallelDownloadTask` 的 `url` 来自 `fbDownloadUrl`、带认证头（用 `background_downloader` 的测试桩或抽象注入点；若桩不支持，退化为断言 URL/headers 构造正确）。
- [ ] **Step 2: 跑测试确认失败。**
- [ ] **Step 3: 实现 `transfer_download.dart` 与改写 `download.dart` 的 `enqueDownloadTask`**（`onPermissionDenied` 行为保留）。
- [ ] **Step 4: 跑测试通过 + `flutter analyze` 零告警。**
- [ ] **Step 5: Commit。**

---

### Task 5: 上传适配层（v3 分片并发 + 续传；v2 回退）

**Files:**
- Create: `lib/services/transfer_upload.dart`
- Test: `test/services/transfer_upload_test.dart`

**Interfaces:**
- Consumes: `uploadEntryUrl`、`kUploadV3Supported`、`UploadV3Fields`（Task 1/2）、`authHeaders`（Task 3）
- Produces:
  - `List<ChunkRange> splitFileIntoTempChunks(File file, {int chunkSize = kDefaultChunkSizeBytes})` —— 把文件切成临时分片，返回每片 `{index, offset, size, tempPath}`（纯函数，可单测）
  - `Future<String> enqueueFileUpload({required String localPath, required String remoteDir, bool overwrite = false})` —— 若 `kUploadV3Supported`：并行（并发度 `kDefaultConcurrency`）N 个 `UploadTask`（multipart，`fileField='file'`，字段按 `UploadV3Fields`，首片取 `upload_id`，末片拼合）；否则单 `UploadTask` v2 multipart（`path`/`file`/`overwrite`/`mtime`）。返回聚合 `taskGroupId`。拼合成功后删除临时分片。

**Steps:**
- [ ] **Step 1: 写测试** `test_splitFileIntoTempChunks`：对 20MB 假文件、`chunkSize=8MB` 断言返回 3 个 chunk，offset 分别为 0/8M/16M、size 8M/8M/4M，且临时文件字节数与 size 一致。
- [ ] **Step 2: 跑测试确认失败。**
- [ ] **Step 3: 实现 `splitFileIntoTempChunks`（纯逻辑：按字节范围写临时文件）。**
- [ ] **Step 4: 跑测试通过。**
- [ ] **Step 5: 实现 `enqueueFileUpload`（v3 分支 + v2 回退分支；临时分片清理）。** 网络交互以 `background_downloader` `UploadTask` 封装，单测仅覆盖分片规划与字段组装（mock 上传）。
- [ ] **Step 6: `flutter analyze` 零告警；Commit。**

---

### Task 6: 传输状态 store（signal + 持久化 + 跨重启续传）

**Files:**
- Create: `lib/stores/transfer_store.dart`
- Test: `test/stores/transfer_store_test.dart`

**Interfaces:**
- Consumes: 各 adapter 的 `taskId`/`taskGroupId` 返回值（Task 4/5）、`FileDownloader().resume`/`pause`/`cancel`（Task 3）
- Produces:
  - `class TransferTask { String id; TransferType type; String localPath; String remotePath; int totalBytes; int transferredBytes; TransferState state; List<ChunkState>? chunks; }`（可 `toJson`/`fromJson`）
  - `final transferStore` 单例（signals）：`List<TransferTask> tasks`、`add`、`updateProgress`、`setState`、`pause`/`resume`/`cancel`（调用引擎）、`persist()`（写 `StorageUtil`，JSON）
  - `Future<void> resumeUnfinishedOnStartup()` —— app 启动时读取持久化任务，对未完成项调用引擎 `resume`

**Steps:**
- [ ] **Step 1: 写测试** `test_serialize_roundtrip`（`TransferTask`→`toJson`→`fromJson` 等价）、`test_state_transitions`（queued→active→done / error→retry）、`test_resume_unfinished` 用假持久化数据断言对未完成项调用 `resume`。
- [ ] **Step 2: 跑测试确认失败。**
- [ ] **Step 3: 实现 `transfer_store.dart`**（信号 + 持久化 + 状态机 + 启动续传）。
- [ ] **Step 4: 跑测试通过 + `flutter analyze`。**
- [ ] **Step 5: Commit。**

---

### Task 7: 文件页 UI 接入最小可用

**Files:**
- Modify: `lib/pages/file/file.dart`（选中→上传/下载；传输列表；暂停/继续/取消/重试；后台标识）
- Modify: `lib/pages/file/upload.dart`（改用 `enqueueFileUpload`）
- Modify: `lib/pages/file/file.dart:323`（已通过 `enqueDownloadTask` 间接走新引擎，确认无误）

**Interfaces:**
- Consumes: `enqueueFileDownload`/`enqueueFileUpload`（Task 4/5）、`transferStore`（Task 6）
- Produces: 文件页可见的传输队列入口与进度/控制 UI（复用现有页面布局与 signals 风格）。

**Steps:**
- [ ] **Step 1: 文件页选中项增加"下载/上传"动作，调用对应 adapter，任务进入 `transferStore`。**
- [ ] **Step 2: 新增/复用传输列表组件，订阅 `transferStore.tasks`，展示进度条、速率、暂停/继续/取消/失败重试按钮与"后台进行中"标识。**
- [ ] **Step 3: `lib/pages/file/upload.dart` 改为调用 `enqueueFileUpload`（保留原有选择/目录逻辑）。**
- [ ] **Step 4: `flutter analyze` 零告警；Commit。**

---

### Task 8: 真机冒烟（MIUI 真机 + 模拟器）

**Files:** 无新增代码（仅验证）

**Steps:**
- [ ] **Step 1: 模拟器验证** 下载一个大文件，观察多线程进度；中途暂停→继续；杀进程→重启 app 确认从断点续传。
- [ ] **Step 2: MIUI 真机（root 安装）验证** 同上，并验证 app 退到后台/被杀后传输继续（前台服务通知可见）。
- [ ] **Step 3: 上传验证** 上传大文件（触发分片或 v2 回退），完成后在 NAS 侧比对文件大小/校验和，确认未损坏（对应 Review Focus #1）。
- [ ] **Step 4: 记录结果到 `transfer-contract.md` 的"真机验证"小节；Commit（仅文档）。**

---

## 自审摘要

- 覆盖：spec 的下载/上传/状态/UI 四块均有对应 Task（2/4、5、6、7）；后台连续性由 Task 3 前台服务 + Task 6 启动续传保证。
- 纯逻辑（URL 构造、分片规划、状态机）均有单测；引擎/原生/真机类以构建+真机冒烟验证（本 harness 无法跑设备，已显式标注）。
- 类型一致：`taskId`/`taskGroupId`、`TransferTask`/`ChunkState`/`TransferState` 在 Task 4–7 间统一引用。
- Review Focus 五条均落到 Task 1（契约实测，含校验和比对）与 Task 8（杀进程/真机）。
