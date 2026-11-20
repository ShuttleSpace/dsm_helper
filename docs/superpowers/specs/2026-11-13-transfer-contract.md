# DSM 传输契约（实测记录 + fallback）

日期：2026-11-13
关联：transfer-engine-design.md、transfer-engine.md (Task 1)

## 已确认（来自 Whistle 抓包 `upload`、`upload-wepe`）

1. **下载端点**：普通 HTTP GET
   `http://<nas>:5000/fbdownload/<文件名>?dlink=<base64(路径)>&mode=download&SynoToken=<token>`
   - `dlink` 实测为路径的 base64（抓包中 `22f44...22` 解码即 `/Download/Software/Allbackup/Black/samsa.zip`，首尾 `22` 是 URL 编码的引号）。
   - `SynoToken` 来自登录（`connection_store` 持久化的 `syno_token`）。
   - 普通文件流，**设计上应认 `Range`**，但**未实测**（需要有效会话）。

2. **上传（官方网页端）**：即使是 238MB 文件也是单个
   `SYNO.FileStation.Upload version=2` multipart POST（一个 boundary，
   `Content-Length: 238591638`）。两次抓包中 `part_number`/`upload_id`/`version=3` 出现次数均为 0。
   → **官方客户端不分片**。

3. NAS 声明 `SYNO.FileStation.Upload` 的 `maxVersion=3`（分片/续传版本存在），但官方网页端不用。

## 未实测（待补验）

- `/fbdownload` 是否真的返回 206（Range 生效）—— 决定 `ParallelDownloadTask` 能否多线程。
- v3 分片上传的确切字段名、首片如何返回 `upload_id`、末片如何触发拼合。

## 当前决策（写进 transfer_contract.dart）

| 项 | 值 | 理由 |
|----|----|------|
| 下载 dlink | 直接 `base64(path)` 构造 | 抓包中 dlink 解码即路径；走 /fbdownload（支持 Range/多线程）。**待 Task 8 真机确认 /fbdownload 接受自构造 dlink** |
| `kUploadV3Supported` | `false` | 未实测；先走 v2 单请求上传（background_downloader 仍提供后台连续性） |
| `kDefaultChunkSizeBytes` | `8 * 1024 * 1024` | 分片大小（v3 开启后使用） |
| `kDefaultConcurrency` | `4` | 上传分片并发度 |
| `UploadV3Fields` | 字段名映射 | 预留，待实测后微调 |

> 早期方案曾考虑"下载回退 SYNO.FileStation.Download 取 dlink"，但抓包证明 dlink 即路径的
> base64，自构造即可，且只有 /fbdownload 支持 Range 多线程。故采用自构造单路径。

## 待办（Task 8 真机 / 有效 FileStation SID）

> 已完成：`flutter build apk --debug` 通过 —— AndroidManifest（FOREGROUND_SERVICE_DATA_SYNC + dataSync service）与 Gradle/AGP 编译无误（2026-11-13）。
> 仍有待真机/有效 SID 手动验证（沙箱无设备与在线 NAS）：

1. 用新鲜 `_SSID` 发 2 分片 v3 上传，确认字段名与拼合时机，置 `kUploadV3Supported=true`（并开启分片并发）。
2. 带 `Range` 请求 `/fbdownload`，确认 206；确认后把 `downloadConcurrency` 调高（如 4）开启多线程下载。
3. 下载/上传完成后在 NAS 侧比对校验和，确认文件未损坏。
4. MIUI 真机 + 模拟器各跑一次：退后台/杀进程后传输是否经 work-manager 续传；前台通知进度/暂停/取消是否可用。
