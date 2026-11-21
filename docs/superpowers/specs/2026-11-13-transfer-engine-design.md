# 传输引擎设计（多线程 + 断点续传 + 后台）

日期：2026-11-13
状态：待审批

## 意图与为什么

项目要补强"文件管理 / 同步"能力，用户明确要 **传输增强**：上传/下载的
**多线程分片 + 断点续传**，且**即使 app 退到后台或被杀掉也能继续**。

决策已定（来自对话）：

- 方向 A：**纯客户端**实现多线程（不使用 NAS 侧 CloudSync/Drive 托管任务）。
- 引擎：**`background_downloader`** 作为传输引擎，外面包一层 DSM 协议适配。
  它已在依赖中，原生用前台服务跑传输，自带暂停/续传/持久化，并内置
  `ParallelDownloadTask`（多线程下载）——正好满足"后台/退出也能继续"。

## 来自 Whistle 抓包的事实（已实测）

两次抓包（`upload`、`upload-wepe`）得出的硬事实：

1. **下载**走普通 HTTP GET：
   `http://<nas>:5000/fbdownload/<文件名>?dlink=<base64路径>&mode=download&SynoToken=<token>`
   `dlink`/`SynoToken` 由 `SYNO.FileStation.Download` 产生。这是普通文件流，
   **认 `Range` 头** → 多线程 + 断点续传的天然入口。
2. **上传**：DSM 官方网页端**不分片**——连 238MB 文件也是单个
   `SYNO.FileStation.Upload version=2` 的 multipart POST
   （一个 boundary，`Content-Length: 238591638`）。
   两次抓包中 `part_number` / `upload_id` / `version=3` 出现次数均为 0。
3. NAS 端声明 `SYNO.FileStation.Upload` 的 `maxVersion=3` —— 即分片/续传版本存在，
   但官方网页端不用它。所以要做到上传的多线程+续传，**必须直接调用 v3 分片 API**。

结论：下载侧协议已基本清楚；**上传 v3 分片的确切字段契约是本次唯一需实测确认的未知项**。

## 目标 / 非目标 / 反目标

目标：

- 下载：多线程分片（ParallelDownloadTask）+ 断点续传 + 后台 continuation。
- 上传：v3 分片上传，多分片并发 + 断点续传（失败/被杀后只补传缺失分片）+ 后台 continuation。
- 统一的传输队列/状态（signal 驱动，与本仓库已完成的 signals+hooks 迁移一致），
  跨 app 重启存活。

非目标（本次不做）：

- NAS 侧 CloudSync / SynologyDrive 托管双向同步（用户已选纯客户端）。
- 文件内容去重、增量同步（rsync 式）。
- 完整的文件管理 UI 重写（作为后续阶段；本次先把引擎和最小 UI 打通）。

反目标（即使技术上可行也视为失败）：

- 为了"多线程"而自己重写前台服务/续传数据库（background_downloader 已给，重造即倒退）。
- 在不确定 v3 契约时，凭猜测写上传分片代码（会静默损坏文件）。

## 约束

- 引擎必须是 `background_downloader`（已依赖，9.5.9）。
- 认证：请求带 `_SSID` cookie 或 `SynoToken`；NAS 与 app 同网段（192.168.8.40:5000）。
- 平台：Android 为主（前台服务已验证可跑），iOS 需配 background modes。
- 与现有 `lib/api/dsm_api.*` 风格一致，新增文件放在 `lib/api/` 与 `lib/services/`。

## 方案（已选 A）

### 引擎层：`background_downloader`

复用其原生能力，不重造：

- **下载**：`ParallelDownloadTask`（内部按 `Content-Length` 切分并用 `Range` 并发拉取，
  落盘到正确偏移；自带暂停/续传/进度）。
- **上传**：v3 分片。把源文件切成临时分片文件，每个分片一个 `UploadTask`
  （multipart，自定义字段 + 认证头）并发上传，NAS 负责拼合。
- **后台连续性**：background_downloader 在 Android 用前台服务，app 挂起/被杀后
  传输继续，重启后可 `resume` 未完成任务。这正是用户"退出 app 也能继续"的要求。

> 注：若直接改用 `workmanager` 自行编排，会因 Android 后台限制杀掉长任务，
> 且要重造前台服务+续传库，故不选。

### 适配层（新增 `lib/services/transfer.dart` 等）

**下载适配**

1. `SYNO.FileStation.Download`（version 2，`mode=open` 或 `download`）→ 取
   `dlink`（base64 路径）与 `SynoToken`。
2. 拼出 `/fbdownload/<name>?dlink=<...>&mode=download&SynoToken=<...>`。
3. 构造 `ParallelDownloadTask(url, headers: {Cookie: "_SSID=..."})` → `enqueue()`。
4. 进度/完成由 background_downloader 回调驱动 signal store。

**上传适配（v3 分片，契约待实测）**

1. 计算分片：源文件按 `chunkSize`（默认 8MB）切成 N 片，写入临时目录。
2. 第 1 片 `UploadTask` → `entry.cgi?api=SYNO.FileStation.Upload&method=upload&version=3&SynoToken=...`，
   multipart 字段（工作假设，见下）：
   `path`、`filename`、`size`(总大小)、`overwrite`、`mtime`、
   `part_number=1`、`total_parts=N`、`offset=0`、`offset_size=<片大小>`。
   响应返回 `upload_id`。
3. 其余片带 `upload_id`，`part_number=2..N`、`offset=前一偏移`、`offset_size=片大小`，
   并发上传（并发度默认 4）。
4. `part_number == total_parts` 时 NAS 拼合完成。
5. 续传：失败/被杀后，重启只补传缺失分片（按已确认的分片状态）。

### 状态层（新增 `lib/stores/transfer_store.dart`，signal 驱动）

每个任务记录：`id, type(up/down), localPath, remotePath, totalBytes,
transferredBytes, state(queued/active/paused/done/error), chunkStates[]`。
跨重启存活（持久化到本地，复用仓库既有偏好存储）。

### UI（最小可用，后续可扩）

- 文件页（`lib/pages/file/`）增加：选中→上传/下载；传输列表（进度、暂停/继续/取消、
  后台标识）；失败重试。
- 复用现有 `dsmFileStationDownload`/`dsmFileStationUpload` 作为底层调用，但改走新引擎。

## 留给构建者的待确认项（gating，必须先做）

1. **v3 上传分片契约实测**（最高优先级，阻塞上传实现）。
   需一个 **FileStation 会话的 `_SSID`**（登录时 `session=FileStation` 拿到的，
   不是桌面会话 SID；现有抓包里的 SID 对 FileStation API 返回 119）。
   拿到后：发一个 2 分片 v3 上传，确认字段名、是否需要 `upload_id` 首请求返回、
   末片如何触发拼合、失败分片如何续传。
   若用户无法提供 SID，则第一步改为：用户再抓一次"上传中途取消再续传"的包，
   从真实请求读契约。
2. **`/fbdownload` 认 `Range` 验证**：用真实 `dlink` 发带 `Range` 的请求，确认返回 206。
3. **`SYNO.FileStation.Download` 返回结构**：确认 `dlink`/`file_id` 字段名，
   以便拼 `/fbdownload` URL。
4. **background_downloader 原生配置**：Android 前台服务权限/通知渠道；iOS background modes。
5. **chunkSize / 并发度** 默认值（建议 8MB / 4 并发），按真机测速微调。

以上 1–3 可由我拿 SID 后直接实测写成"已验证契约"小节，再开工。

## 不做的事（明确跳过）

- 不引入新依赖（background_downloader 已存在）。
- 不做 NAS 侧托管同步、不做增量同步。
- 不重写文件管理整套 UI（仅接最小可用入口）。
