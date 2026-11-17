# 迁移到 `dsm_api.dart` + 三大核心功能 — 设计

日期：2026-11-16  
状态：待批准

## 1. 意图与背景

- 旧层：`lib/util/api.dart`（`class DsmApi`，约 1700 行、137 个 `static Future` 方法，返回 `{success,data,error}` 信封）被 49 个文件 / 136 个调用点依赖，并由 `lib/util/http_util.dart` re-export。
- 新层：`lib/api/dsm_api.dart`（约 90 个 `part`，含 `dsm_api.captured.g.dart` 217 个生成函数），顶层 `dsmXxx()` 成功返回 `res['data']`，失败抛 `DSMException`。**新函数当前 0 处页面引用**。
- 目标（用户确认）：**所有调用 `DsmApi` 的页面改为走 `dsm_api.dart`，删除 `lib/util/api.dart`**。随后把三个最重要的功能做成可用：NAS 文件预览、NAS 文件上传/下载（支持多文件、断点续传，体验对标 DS file）、同步备份。
- 方案：**A — 桥接层**（用户已选）。先无感切换、后分批硬化，核心功能最后单独动、单独验。

## 2. 现状与迁移面（已核实）

| 项 | 数值 / 事实 |
|---|---|
| 旧方法 / 调用点 / 调用文件 | 137 方法，136 调用点，49 文件 |
| 等价映射 | 116 精确等价；17 同 api 不同 method/quirk；**4 完全无等价**（`logHistory`、`reward`、`downloadFileList`、`downloadCreate`） |
| 新层 bug（必须先修） | `dsmCoreShareCreate` 发 `method:'get'`（应 `create`）；`dsmFileStationDeleteStatus` 发 `start`（应 `status`）；`dsmCoreCurrentConnectionGet` 发 `list`（应 `get`） |
| 调用点消费 | 124/136 检查 `res['success']`/`error`，46 读 `error.code`，0 传 model fromJson |
| 不可删 | `lib/util/http_util.dart`：24 处 `HttpUtil.instance` 直用 + 83 个 import 依赖其 re-export（含 extensions） |
| 测试兜底 | `test/` 对 `DsmApi`/`http_util` 零引用 |
| 三大功能现状 | 预览/上传下载链路（`transfer_store`、`lib/pages/download/*`、`lib/pages/file/upload.dart`、`lib/pages/common/{image,office,video}_preview.*`）**不走 `DsmApi`**；**同步备份仅 `lib/pages/backup/backup.dart:217` 调 `DsmApi.upload`** 与旧层交叉 |

## 3. 目标 / 非目标 / 反目标

- **目标**
  - T1：删除 `lib/util/api.dart`，全仓无 `DsmApi` 旧实现与 `api.dart` import；所有页面行为保持。
  - T2：NAS 文件预览可用且覆盖现有预览页（图/文档/Office/视频等已有入口），失败可感知。
  - T3：文件上传/下载支持多文件、可暂停/继续、**断点续传**，交互与状态对标 DS file（任务列表、进度、失败重试）。
  - T4：同步备份（`lib/pages/backup/backup.dart`）在新层上可用，行为不退化。
- **非目标**：为 217 个生成函数逐一做新页面；迁移期间重写 `HttpUtil` 或 transfer 引擎架构；接入第三方（非 `SYNO.*`）套件。
- **反目标**：静默改变请求语义；在未验证核心功能前做大范围页面硬迁移；为求一步到位扩大改动面。

## 4. 选定方案（A：桥接层）

### 4.1 兼容层

- 新增 `lib/api/dsm_api_compat.dart`（或等价命名），`part of 'dsm_api.dart'` 或独立并导出 `class DsmApi`：
  - 保留旧方法签名与方法名，内部调用新 `dsmXxx()`。
  - **适配返回契约**：成功 → `{'success': true, 'data': <新层返回值>}`；捕获 `DSMException` → `{'success': false, 'error': {'code': e.code, ...}, 'data': null}`（兼容 124 处 `res['success']` + 46 处 `error.code` 用法）。
  - 对 **4 个 GAP**：在新层补等价 `dsmXxx`（`SYNO.LogCenter.History|list`、`SYNO.DownloadStation2.Task.List|get`、`SYNO.DownloadStation2.Task.List.Polling|download`）或在 compat 内直调 `_httpGet/_httpPost`；`reward` 走与 `connectionStore.baseUri` 一致的 GET（保留旧行为）。
  - 对 **compound 旧方法**（`systemInfo`、`downloadStationInfo` 等 15 个）：在 compat 内用 `_dsmApiCall`/组合调用复刻旧的 `result[]` 信封结构，保证现有页面解析不变。
- `lib/util/http_util.dart`：将 `export 'package:garden/util/api.dart';` 改为导出 compat；**保留 HttpUtil 类与其它 re-export** 不动。
- 删除 `lib/util/api.dart`（T1 达成时）。

### 4.2 必修前置（无论阶段都要）

- 修正 3 个新函数的 `method` 字符串（`create` / `status` / `get`）并核对调用方预期。
- 审核 17 个“同 api 不同 method/quirk”映射：对 DownloadStation2 vs DownloadStation（api 串不同）、`installPackageStatus/Queue`、`eventRun`、`fileServiceLog*`、`mediaReindex` 等，要么补新函数，要么 compat 特殊处理，**不静默改语义**。

### 4.3 阶段（可独立回滚）

| 阶段 | 内容 | 回滚 | 验证 |
|---|---|---|---|
| S0 前置修复 | 修 3 个 bug + 补 4 个 GAP/17 个 quirk 的兼容实现；补最小测试覆盖 compat 契约 | revert 该提交 | `flutter analyze` + 相关测试 |
| S1 无感切换 | 落 compat、改 http_util export、删 `api.dart`；页面代码不改 | 改回 export 即回退 | 全仓无 `util/api.dart` 引用；`flutter analyze` + `flutter test`；冒烟关键页 |
| S2 核心功能硬化 | **备份**：`backup.dart` 改用新层/compat 语义并验上传；**上传下载**：梳理 `dsmFileStationUpload/Download`、transfer_store、download_state，补多文件与断点续传（Range/偏移/任务恢复，对标 DS file）；**预览**：统一走新层取流/URL，补失败态 | 按功能分 PR/提交回滚 | 手工 + 自动化（见第 6 节） |
| S3 收缩（可选） | 逐模块把页面从 `DsmApi.xxx` 迁到直接 `dsmXxx()` + `try/catch`，最终删 compat | 模块级 revert | 每模块后 analyze+test |

> “删除旧 api”在 S1 完成；“页面调用改为我们的 dsm_api.dart”在 S1 以 compat 形式达成、S3 彻底直连。三大核心功能在 S2 单独验收。

## 5. 三大核心功能设计要点（S2 细化输入）

- **NAS 文件预览**：复用 `lib/pages/common/{image_preview,office_preview,video_player,pdf_viewer,text_editor}.dart` 与 `lib/pages/file/file.dart` 入口；下载/取直链统一走 `dsm_api.filestation.*`（含 `transfer_url`/`uploaddownload`），错误走 `DSMException` → 可读提示；不改预览 UI 风格，只换数据源与错误处理。
- **上传/下载（多文件、断点续传，DS file 体验）**：以 `lib/stores/transfer_store.dart` + `lib/pages/download/*` + `lib/pages/file/upload.dart` 为中心；核对/完善 `dsmFileStationUpload`（分片/overwrite）、`dsmFileStationDownload`（Range 续传、已存在文件续写）、`transfer_engine` 服务；任务持久化与恢复、多选批量入队、进度/暂停/继续/重试。**必须保留现有行为，再扩展断点续传**。
- **同步备份**：`lib/pages/backup/*`（当前 `DsmApi.upload`）迁到新上传路径；保持 `backup_model.dart` 的 `UploadItem/UploadStatus` 语义，复用/对齐 transfer 能力，避免两套上传实现分叉。

（S2 启动前需再做一次针对这三块的代码级摸底，产出实施计划；本设计只定边界与验收。）

## 6. 验证与风险

- **每阶段门禁**：`flutter analyze`、`flutter test` 全绿；S1 后 grep 确认无 `util/api.dart`/旧 `class DsmApi` 定义残留；S2 对三大功能做手工回归（多文件、暂停续传、备份上传）。
- **已知风险**：124 处信封消费靠 compat 形状兼容，compound 结构最易错 → S0/S1 必须对 compound 方法做契约样例测试；17 个 quirk 里 api 串不一致（DownloadStation vs DownloadStation2）可能导致静默错配；无现成 `DsmApi` 测试，回归依赖 analyze + 手测。
- **数据/行为安全**：备份与上传涉及真实文件操作，S2 仅在可控目录/小文件验证断点续传，不破坏用户既有任务。

## 7. 已拍板 / 开放问题

1. **S1 范围**：只做 compat + 删 `api.dart`，页面零直迁；直迁放 S3。（建议已采纳，写入 §4.3）
2. **断点续传验收（已拍板：上传下载都要）**：下载与上传都做字节级断点续传。S2 第一子步必须**前置验证**上传 API 能力（`SYNO.FileStation.Upload` 是否支持分片/偏移/追加、能否持久化半成品并续传）；若不支持，S2 计划需明确采用的替代方案（如客户端分片上传 + 服务端合并，或在能力受限时降级为任务级重试并在 UI/文档标注限制）——不得静默承诺做不到的能力。
3. **预览范围**：沿用现有已支持格式（T2 已定），本轮不扩新格式。

Builder 审查结论：除上面第 2 项（已拍板）外无其余阻塞问题；其余可在实现期从代码确定。

---

本设计批准后，下一步：调用 `superpowers:writing-plans` 输出分阶段实施计划（S0→S1→S2）。