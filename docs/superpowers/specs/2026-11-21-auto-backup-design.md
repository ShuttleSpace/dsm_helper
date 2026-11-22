# 自动备份（冷启动自动续传）设计

日期：2026-11-21
状态：待批准

## 背景

相册备份页已有三种模式卡片（`lib/pages/backup/backup.dart:393` 继续备份、`:461` 全新备份、`:484` 自动备份）。
继续备份与全新备份已经接入新任务模型：`backupPendingAssets()` 决定是否按 `last_backup_time` 过滤，
`startBackup()` 生成一条父任务 + 每张照片一个子步骤，进度显示在传输页。
只有自动备份是占位：`UiUtil.toast("暂不支持自动备份")`。

## 意图（为什么）

用户希望打开 app 后照片自动接着备份到 NAS，不必每次都进备份页点“开始备份”。

## 目标

- 自动备份有持久化开关，默认关闭，点卡片切换。
- 开启后，每次登录成功进入首页自动跑一次“继续备份”语义（按 `last_backup_time` 过滤）。
- 复用现有任务模型：一条父任务 + 每张照片一个子步骤，进度在传输页可见。
- 不引入新依赖。

## 非目标

- 不做系统级后台调度（workmanager / BGTaskScheduler）。app 未运行时不备份。
- app 常驻期间新增照片不自动触发（本次只在进入首页时尝试一次）。
- 不做自动备份专属日志页、通知或重试策略配置。
- 不改继续备份 / 全新备份的现有行为。

## 反目标（即使能跑也算失败）

- 用户没开开关却后台偷偷上传。
- 同一次启动里重复创建多条备份父任务。
- 相册权限、目的地或相册未配置时弹出打扰性提示。

## 方法对比

| 方案 | 说明 | 代价 |
| --- | --- | --- |
| A 冷启动自动续传 | 登录进首页后尝试一次，复用现有任务模型 | 只在 app 打开时跑；零新依赖 |
| B 前台定时扫描 | 在 A 上加 Timer/生命周期轮询 | 需间隔设置与耗电权衡 |
| C 系统级后台调度 | workmanager / BGTaskScheduler | 新依赖 + 两端系统限制，范围大 |

**用户先选了 C，随后改为 A。** 采纳 A。

## 设计

### 开关

- 存储键 `auto_backup`，`StorageUtil.getBool/setBool`，默认 `false`。
- 备份页“自动备份”卡片改为可点击切换：
  - 开启时右侧显示勾选图标（与另外两张卡片一致），副标题保持“打开${appName}后自动从上次备份位置继续备份”。
  - 关闭时无图标。
  - 点击即写入存储并切换，不再弹 toast。

### 触发点

`lib/pages/home.dart` 的 `Home.build` 里新增一个 `useEffect(..., const [])`，首次构建后调用 `runAutoBackup()`。
首页只有在登录成功后才可达（`lib/pages/login/login.dart:184`、`:338`、`lib/pages/login/accounts.dart:99` 都是
`pushNamedAndRemoveUntil("/home")`），此时 NAS 会话已建立，避免在登录/生物解锁页面对未就绪的连接发请求。

### 纯决策函数（可测）

`lib/pages/backup/backup.dart` 新增：

```dart
/// 自动备份是否应当创建任务；返回 null 表示本次跳过。
Future<TransferTask?> startAutoBackup({
  required bool enabled,
  required String backupFolder,
  required List<AssetEntity> uploads,
  required DateTime? lastBackupTime,
  required bool hasPendingBackup,
  required Future<String> Function(String cachePath, String remoteDir) enqueue,
  required Directory cacheRoot,
}) async
```

跳过条件（依次）：`enabled == false`、`backupFolder` 空白、`hasPendingBackup == true`、
`backupPendingAssets(uploads, lastBackupTime, true)` 为空。否则调用 `startBackup(...)` 并返回父任务。
自动备份固定使用“继续备份”语义（`continueBackup = true`）。

### 运行入口

同文件新增：

```dart
/// 冷启动一次：读取配置、解析相册、调用 startAutoBackup。不可用时静默返回 null。
Future<TransferTask?> runAutoBackup()
```

职责：读 `auto_backup` / `backup_folder` / `backup_album`；权限非 `authorized` 时静默返回；
`PhotoManager.getAssetPathList()` 后按保存的相册 id 取回相册（复用 `isSameAlbum` 的 id 口径）；
`collectBackupAssets()` 取资产；查 `transferStore.tasks` 是否已有未完成的备份父任务
（`steps != null` 且状态为 queued/active）；调用 `startAutoBackup`。

进程内去重：文件级 `bool _autoBackupRan = false`，`runAutoBackup()` 首次进入置 true，后续直接返回 null。
杀进程重启后会再尝试一次，靠 `last_backup_time` 过滤与“无待备份文件即跳过”保证不重复上传。

## 留给实现者

- 失败处理：`startBackup` 抛 `BackupEnqueueIncomplete` 时静默吞掉（父任务已被标记 error，传输页可见）。
- 是否给 `runAutoBackup` 加日志：可加 `Log.info` 一行记录跳过原因，便于排查。
- 测试覆盖：`startAutoBackup` 的四个跳过条件 + 正常创建父任务与步骤；`runAutoBackup` 不做覆盖（依赖 PhotoManager 平台通道）。
