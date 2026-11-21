# 相册备份：多选、开始按钮失效与传输页父任务

## Intent

相册备份页当前有两个用户可见问题：开始按钮点了没反应；备份过程在传输 tab 里完全看不到。用户要的是：备份作为**一条可展开的上传任务**出现在传输 tab，每个子步骤对应一张照片/视频；备份源保持多选。

## Goals

- 修复 `getAssetCount()` 中的运行时 cast 失败，使数量统计与 `onStartBackup` 能拿到真实的资产列表。
- 点“开始备份”后立即在传输 tab 生成一条父任务（“相册备份”），其下每个文件是一条可展开查看的子步骤。
- 上传复用现有 `background_downloader` 引擎，子步骤可暂停/续传/重试；父任务显示聚合进度。
- 备份源多选继续可用，勾选状态正确回显；“所有图片”仍为互斥选项。

## Non-goals / Anti-goals

- 不做文件夹粒度的步骤、不做自动备份、不新增相册筛选方式。
- 不改现有上传/下载任务的模型语义（普通任务仍是一任务一文件）。
- 不引入新依赖；`path_provider` 与 `background_downloader` 已在项目中。

## Constraints

- `TransferTask` 目前是扁平的一任务一文件（`lib/stores/transfer_store.dart`）；父任务/子步骤是新增字段，不能破坏旧 JSON（`transfer_tasks` 键）的读取。
- 备份页现有临时文件来自 `AssetEntity.originFile`，重启后可能失效；入队前必须复制到持久目录。
- `background_downloader` 的状态/进度回调按 taskId 上报；父任务的 id 不是物理上传 id，回调要路由到对应子步骤。
- 工作规模：中等（4-5 个文件 + 测试），按短设计文档处理，不启动完整项目级 builder check。

## 根因（已复现确认）

`lib/pages/backup/backup.dart` 的 `getAssetCount()`：

```dart
var values = value.fold([], (prev, el) { prev.addAll(el); return prev; });
uploads.addAll(values as List<AssetEntity>);
```

`fold([], …)` 推断为 `List<dynamic>`，强转 `List<AssetEntity>` 抛出 `_CastError`。最小复现脚本已验证该行为。`getAssetCount()` 是 fire-and-forget 调用，错误无人捕获；函数开头已 `uploads.clear()`，所以资产列表永久为空。后果链：数量 0 → `onStartBackup` 的 `tasks` 为空 → for 循环不执行 → 点按钮无任何变化。

## Approaches

1. **父任务 + 可展开子步骤，复用后台引擎（已选）**：`TransferTask` 增加 `steps` 字段保存子步骤；备份页把每个文件 copy 到持久缓存后调用 `enqueueFileUpload`，引擎回调按 taskId 更新子步骤并汇总父任务。传输列表用展开行显示子步骤。代价：要改 store 的 JSON、回调路由和列表 UI；换来真正的暂停/续传/重试与“一条任务”的呈现，符合用户要求。
2. **一文件一任务 + 按备份分组折叠**：只给任务加 group id，列表折叠显示。代价最小，但传输 tab 里不是“一条任务”，也没有父任务聚合进度，违背用户明确选择的形态。
3. **继续 Dio 直传，手动同步进度到父任务**：改动最少，但父任务的暂停/重试按钮无法真正控制上传，需要禁用，且重启后无法续传。用户已选择接入后台引擎，排除。

## 设计（builder 照此实现）

### 数据模型 `lib/stores/transfer_store.dart`

- 新增 `TransferStep`：`id`（引擎 taskId）、`localPath`、`remotePath`、`totalBytes`、`transferredBytes`、`state`、`errorMessage?`，含 `toJson/fromJson`。
- `TransferTask` 增加 `final List<TransferStep>? steps`（nullable；null = 普通任务）并更新 `copyWith/toJson/fromJson`；旧 JSON 无该键时读出 null，向后兼容。
- `TransferStore` 增加：
  - `updateStep(String groupId, String stepId, int transferred, int total, ...)`：更新子步骤并按所有步骤重算父任务的 `transferredBytes/totalBytes/state`（任一 active/queued → active；否则任一 error → error；全部 done → done）。
  - `setStepState(String groupId, String stepId, TransferState state, {String? errorMessage})`。
  - `applyTaskStatusUpdate` / `listenUpdates`：先按 taskId 在含 steps 的任务中查找，命中则走 step 更新，否则走原有单任务路径。
  - `pauseTask/resumeTask/cancelTask`：若 id 对应父任务，遍历其 steps 逐个调用控制钩子；`remove(groupId)` 由调用方负责删除持久缓存文件。
- 父任务字段：`type = upload`，`remotePath = backupFolder`，`id = 'backup_<microseconds>'`，`totalBytes/transferredBytes` 由步骤汇总，`createdAt/updatedAt` 正常写入。

### 备份页 `lib/pages/backup/backup.dart`

- 修复 `getAssetCount()`：用带类型的累加（如 `List<AssetEntity> values = []`，逐 album `addAll`），并按 `asset.id` 去重（相册可能有重叠）。
- “全新备份”计数改用 `uploads.value`（当前误用信号对象 `uploads.where`）；“继续备份”计数保持现有过滤条件。
- `onStartBackup`：
  1. 目的地/源校验不变；过滤后若 `tasks.isEmpty`，toast “没有需要备份的文件”并 return。
  2. 先 `transferStore.add(父任务)`，再逐个资产：`originFile` → 复制到 `getApplicationDocumentsDirectory()/backup_cache/<asset.id>/<原文件名>`（`setLastModifiedSync(asset.modifiedDateTime)` 保留时间）→ `enqueueFileUpload(localPath: cache, remoteDir: backupFolder)` → 成功后 `updateStep` 加入子步骤；入队失败则该步骤记为 error。
  3. 全部入队后 toast “已创建备份任务，请到传输页查看”；不再在备份页自行直传。
- 移除/停用旧的单文件进度条与 `dsmFileStationUploadForPage` 调用；保留 `UploadItem`/`backup_model.dart` 不动（其他调用方无需改动）。

### 传输列表 `lib/widgets/transfer_list.dart`

- `_buildRow` 对 `t.steps != null` 的父任务走新分支：显示“相册备份（N 个文件）”、聚合进度、展开箭头；展开后逐步显示文件名、状态、进度/错误。
- 展开状态用 `useState<Set<String>>`（组件本地，不持久化）。
- 父任务的筛选仍按 `remotePath/localPath` 匹配；搜索“相册备份”也能命中（把固定前缀拼进父任务 remotePath 的显示名，或过滤时特殊处理父任务名）。

### 测试

- `test/stores/transfer_store_test.dart` 增补：父任务子步骤的进度聚合、状态汇总、`toJson/fromJson` 往返、引擎状态/进度回调路由到子步骤。
- 保留 `test/pages/backup_upload_contract_test.dart` 不动（旧直传接口仍存在，未被本次改动破坏）。

## 风险 / 留给 builder 的判断

- 持久缓存目录增长：本次不做自动清理；用户删除父任务时删除其缓存目录即可，后续若有存储压力再单独处理。
- 相册权限仅有 `limited`(部分照片) 时当前代码直接拒绝；本次不改这个行为，避免范围扩大。
- `background_downloader` 的 v3 分片仍默认关闭（`kUploadV3Supported = false`），备份走 v2 单请求，与其他上传一致。
