# 上传/下载断点续传 —— API 能力前置验证结论

日期：2026-11-16
关联：Task 8（`docs/superpowers/plans/2026-11-16-api-migration-and-core-features.md`）、
`2026-11-13-transfer-contract.md`、`2026-11-13-transfer-engine-design.md`

> 这是 Task 8 Step 1 的硬性前置验证记录。目的是在写任何续传代码前确定
> 「下载是否支持 Range」「上传是否有 offset/append/分片语义」，并按结论分支，
> **禁止无提示假续传**。

## 1. 探测手段与实际结果

### 1.1 真机最小实验（本次可做部分）

从当前环境对 DSM `http://192.168.8.40:5000` 直接发请求：

| 探测 | 命令/请求 | 结果 |
|---|---|---|
| API 版本 | `GET /webapi/query.cgi?api=SYNO.API.Info&method=query&query=SYNO.FileStation.Download,SYNO.FileStation.Upload` | `Download: min1/max2`; `Upload: min2/max3`（`success:true`）|
| 下载端点 Range | `GET /webapi/entry.cgi?api=SYNO.FileStation.Download&method=download&version=2&path=...&mode=download` + `Range: bytes=0-0` | `HTTP 200`，body `{"error":{"code":119},"success":false}`，响应头 `x-request-error: unauth` |
| 认证会话 | browse 扩展状态 | `paired-offline`、`no browsers/activeTargets`，无已登录 DSM 会话 |

**结论边界**：NAS 在线，但下载端点需要有效 FileStation 会话 SID（登录需 2FA），
browse 无已登录会话 → **无法在本次对真实文件完成 206/Accept-Ranges 实测，
也无法发起 v3 分片上传实测**。不得据此编造「已实测支持」的结论。

### 1.2 抓包痕迹与代码证据（可离线核实，已核实）

来自 `docs/superpowers/specs/2026-11-13-transfer-{contract,engine-design}.md`
记录的两次 Whistle 抓包（`upload`、`upload-wepe`）：

- 上传：DSM 官方网页端即使 **238MB** 文件也是**单个** `SYNO.FileStation.Upload
  version=2` multipart POST（一个 boundary，`Content-Length: 238591638`）；
  两次抓包中 `part_number` / `upload_id` / `version=3` 出现次数**均为 0**。
- 下载：`/fbdownload/<文件名>?dlink=<base64(path)>&mode=download&SynoToken=<token>`
  是普通文件流；设计上应认 `Range`，但**未实测 206**。
- 代码现状（本次逐文件确认）：
  - `lib/api/dsm_api.filestation.transfer_contract.dart`：
    `kUploadV3Supported = false`（注释明确「未实测确认 → 回退 v2 单请求上传」），
    `UploadV3Fields` 字段名标注「**未实测**，待 Task 8 真机确认后生效」。
  - `lib/services/transfer_upload.dart`：`enqueueFileUpload` 默认走 v2，
    v3 分支（`enqueueV3Upload`）的 `upload_id` 握手留空、拼合靠假设。
  - `lib/services/transfer_download.dart`：`downloadConcurrency = 1`
    （注释「是否认 Range 多线程待真机确认；确认前保持 1」），
    `allowPause: true`、`updates: Updates.statusAndProgress`、`retries: 3`。
  - `all_api.json5`：仅声明 `SYNO.FileStation.Upload maxVersion=3/minVersion=2`、
    `path=entry.cgi`、`requestFormat=JSON` —— **没有任何 offset/size/分片参数定义**。
  - `lib/api/dsm_api_compat.dart` 的 `DsmApi.upload`（Task 7 锁定契约）：
    `create_parents:true`、`size`、`mtime`、`overwrite:false`、单个 multipart `file`，
    无 offset/append 参数。

## 2. 结论（按证据，不猜测）

### 2.1 下载

- **能力**：`background_downloader` 的 `DownloadTask`（`allowPause: true`）本身用
  `Range` + 临时文件实现字节级暂停/续传，并由其自身持久化数据库记录字节偏移；
  这是库已提供、无需服务端额外契约的机制。上传/下载引擎已配置
  `updates: Updates.statusAndProgress` 以便 UI 拿到进度。
- **未确认**：`/fbdownload` 是否对真实文件返回 `206 Accept-Ranges`（本次无 SID，
  无法实测）→ **多连接并行 Range 下载（`ParallelDownloadTask`）保持关闭**
  （`downloadConcurrency = 1`）。不在未确认时调高，避免重复落盘/损坏文件。
- **选定分支**：**字节级续传由 `background_downloader` 的 pause/resume 提供**
  （单连接、库管理 Range 与临时文件）；自管下载 API（`dsmFileStationDownload`）
  提供可选的 `Range` 头构造 + 续写偏移助手，供需要按字节续写的调用方使用。
- **能力边界**：并行多线程下载待有效 FileStation SID 实测 206 后再开启；
  当前单连接续传不依赖该实测即可成立。

### 2.2 上传

- **能力**：**没有可验证的 offset/append/分片合并语义**。证据：官方客户端 238MB
  仍单请求 v2；抓包零 `part_number`/`upload_id`/`version=3`；`all_api.json5` 无分片参数；
  `UploadV3Fields`/`enqueueV3Upload` 的字段与握手均为未实测假设。
- **风险**：在未验证契约下写 v3 分片上传会导致静默文件损坏 —— 这正是 spec 明确
  的「反目标」，不得凭猜测启用。
- **选定分支**：**任务级重试降级**。保持 v2 单请求 multipart 上传（同时完整保留
  Task 7 备份上传契约），失败/被杀后按任务重新入队重试；**明确标注「上传不支持
  字节级续传」**，禁止 UI/文档出现误导性的「断点续传」承诺。
- **能力边界（须在 UI/文档明示）**：DSM Upload API 未提供已验证的偏移/追加语义，
  上传中断需重新上传（任务可一键重试），非字节级续传。

## 3. 分支落地对照

| 项 | 结论 | 代码分支 |
|---|---|---|
| 下载续传 | 库管理 Range/临时文件，206 未实测 | `DownloadTask allowPause:true` + `updates`；并行保持 off；自管路径提供 Range/续写助手 |
| 上传续传 | 无 offset/append 语义，v3 未实测 | v2 单请求上传 + 任务级重试 + UI/文档明示限制；**不启用** `kUploadV3Supported` |
| 多文件/暂停/继续/重试/持久化 | 已有 transferStore + background_downloader | 复用并补测，不重写架构 |

## 4. 仍需真机补验（不阻塞本次保守分支）

1. 有效 FileStation SID 下对已知文件发 `Range: bytes=0-1023` → 确认 206；
   确认后可把 `downloadConcurrency` 调至 4 开启并行下载，并比对校验和。
2. 有效 SID 下发 2 分片 `version=3` 上传，读回确切字段名/`upload_id` 握手/拼合时机；
   仅在实测通过后才置 `kUploadV3Supported = true`，届时才可宣称上传字节级续传。
