# 自动备份（冷启动自动续传）实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 增加可持久化的“自动备份”开关，登录进首页后自动按“继续备份”语义创建一条备份父任务。

**Architecture:** 复用现有 `collectBackupAssets()` / `backupPendingAssets()` / `startBackup()`。新增纯决策函数 `startAutoBackup()`（可测，不含平台调用）与被 `Home` 首次构建触发的 `runAutoBackup()`（读存储、取相册、去重、静默失败）。

**Tech Stack:** Flutter, flutter_hooks, signals, shared_preferences（经 `StorageUtil`）, photo_manager, background_downloader。

**Spec:** `docs/superpowers/specs/2026-11-21-auto-backup-design.md`

## Global Constraints

- 不引入新依赖。
- 存储键固定为 `auto_backup`（bool，默认 false）；相册/目的地/时间沿用 `backup_album`、`backup_folder`、`last_backup_time`。
- 自动备份固定“继续备份”语义（`continueBackup = true`）。
- 跳过时静默，不弹 toast。
- 无新增 `dart analyze` 错误。

## Review Focus

- 开关关闭时绝不能创建任务。
- 同一次启动不能创建多条备份父任务（进程内标记 + 未完成任务检查）。
- 相册权限被拒、无相册、无目的地时静默返回，不崩溃。
- `backup_album` 存储为空字符串时不能抛 `FormatException`。
- 已存在未完成备份任务时不得重复入队。

---

### Task 1: `startAutoBackup` 决策函数

**Files:**
- Modify: `lib/pages/backup/backup.dart`（`startBackup` 之后、`remoteDir` 附近）
- Test: `test/pages/backup_start_test.dart`

**Interfaces:**
- Consumes: `backupPendingAssets(List<AssetEntity>, DateTime?, bool)`, `startBackup({backupFolder, assets, enqueue, cacheRoot, cancelEnqueued})`, `hasPendingBackupTask(Iterable<TransferTask>)`
- Produces:
  - `bool hasPendingBackupTask(Iterable<TransferTask> tasks)`
  - `Future<TransferTask?> startAutoBackup({required bool enabled, required String backupFolder, required List<AssetEntity> uploads, required DateTime? lastBackupTime, required bool hasPendingBackup, required Future<String> Function(String cachePath, String remoteDir) enqueue, required Directory cacheRoot})`

- [ ] **Step 1: 写失败测试**（追加到 `test/pages/backup_start_test.dart`）

```dart
test('hasPendingBackupTask true only for stepped queued/active tasks', () {
  final queued = TransferTask(id: 'b1', type: TransferType.upload, localPath: '', remotePath: '/p', state: TransferState.queued, steps: const []);
  final plain = TransferTask(id: 'u1', type: TransferType.upload, localPath: '/a.jpg', remotePath: '/p/a.jpg', state: TransferState.active);
  final done = queued.copyWith(state: TransferState.done);
  expect(hasPendingBackupTask([queued]), isTrue);
  expect(hasPendingBackupTask([plain]), isFalse);
  expect(hasPendingBackupTask([done]), isFalse);
});

test('startAutoBackup skips when disabled, no folder, pending task or nothing new', () async {
  final cacheRoot = await Directory.systemTemp.createTemp('auto_backup_test_');
  addTearDown(() => cacheRoot.deleteSync(recursive: true));
  final source = File('${cacheRoot.path}/new.jpg')..writeAsStringSync('photo');
  final asset = FakeAsset('new', DateTime(2026, 2, 1), sourceFile: source);
  final enqueue = (String cachePath, String remoteDir) async => 'auto1';

  expect(await startAutoBackup(enabled: false, backupFolder: '/photos', uploads: [asset], lastBackupTime: null, hasPendingBackup: false, enqueue: enqueue, cacheRoot: cacheRoot), isNull);
  expect(await startAutoBackup(enabled: true, backupFolder: '', uploads: [asset], lastBackupTime: null, hasPendingBackup: false, enqueue: enqueue, cacheRoot: cacheRoot), isNull);
  expect(await startAutoBackup(enabled: true, backupFolder: '/photos', uploads: [asset], lastBackupTime: null, hasPendingBackup: true, enqueue: enqueue, cacheRoot: cacheRoot), isNull);
  expect(await startAutoBackup(enabled: true, backupFolder: '/photos', uploads: [asset], lastBackupTime: DateTime(2026, 3, 1), hasPendingBackup: false, enqueue: enqueue, cacheRoot: cacheRoot), isNull);
  expect(transferStore.tasks.value.any((t) => t.id.startsWith('backup_')), isFalse);
});

test('startAutoBackup creates parent task when eligible', () async {
  final cacheRoot = await Directory.systemTemp.createTemp('auto_backup_test_');
  addTearDown(() => cacheRoot.deleteSync(recursive: true));
  final source = File('${cacheRoot.path}/new.jpg')..writeAsStringSync('photo');
  final asset = FakeAsset('new', DateTime(2026, 2, 1), sourceFile: source);
  final parent = await startAutoBackup(
    enabled: true,
    backupFolder: '/photos',
    uploads: [asset],
    lastBackupTime: DateTime(2026, 1, 1),
    hasPendingBackup: false,
    enqueue: (cachePath, remoteDir) async => 'auto1',
    cacheRoot: cacheRoot,
  );
  expect(parent!.steps!.single.id, 'auto1');
  expect(parent.remotePath, '/photos');
  transferStore.remove(parent.id);
});
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/pages/backup_start_test.dart`
Expected: 编译错误 `hasPendingBackupTask isn't defined`

- [ ] **Step 3: 实现**

```dart
/// 已有未完成的备份父任务时不再入队，避免重复上传。
bool hasPendingBackupTask(Iterable<TransferTask> tasks) => tasks.any((t) =>
    t.steps != null &&
    (t.state == TransferState.queued || t.state == TransferState.active));

/// 自动备份的决策层：不可用时返回 null，不抛异常、不提示。
Future<TransferTask?> startAutoBackup({...}) async {
  if (!enabled || backupFolder.isBlank || hasPendingBackup) return null;
  final assets = backupPendingAssets(uploads, lastBackupTime, true);
  if (assets.isEmpty) return null;
  return startBackup(backupFolder: backupFolder, assets: assets, enqueue: enqueue, cacheRoot: cacheRoot);
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/pages/backup_start_test.dart`
Expected: All tests passed

- [ ] **Step 5: 提交**

```bash
git add lib/pages/backup/backup.dart test/pages/backup_start_test.dart
git commit -m "feat(backup): add auto backup decision helper"
```

---

### Task 2: 运行入口、首页触发与开关卡片

**Files:**
- Modify: `lib/pages/backup/backup.dart`（`runAutoBackup()` + 卡片 + `getData()` 读开关）
- Modify: `lib/pages/home.dart`（首次构建触发）
- Test: `test/pages/backup_ui_cleanup_test.dart`

**Interfaces:**
- Consumes: Task 1 的 `startAutoBackup` / `hasPendingBackupTask`
- Produces: `Future<TransferTask?> runAutoBackup()`

- [ ] **Step 1: 写失败测试**（追加到 `test/pages/backup_ui_cleanup_test.dart`）

源码级断言：
- `backup.dart` 含 `'auto_backup'`、含 `runAutoBackup(`、不含 `暂不支持自动备份`
- `home.dart` 含 `runAutoBackup()`

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/pages/backup_ui_cleanup_test.dart`
Expected: FAIL（找不到 `auto_backup`）

- [ ] **Step 3: 实现**

`backup.dart`：
```dart
bool _autoBackupRan = false;

/// 冷启动一次：读配置、解析相册、调用 startAutoBackup。不可用时静默返回 null。
Future<TransferTask?> runAutoBackup() async {
  if (_autoBackupRan) return null;
  _autoBackupRan = true;
  if (!(await StorageUtil.getBool('auto_backup') ?? false)) return null;
  final backupFolder = await StorageUtil.getString('backup_folder') ?? '';
  if (backupFolder.isBlank) return null;
  final albumStr = await StorageUtil.getString('backup_album') ?? '';
  if (albumStr.isBlank) return null;
  final ids = (json.decode(albumStr) as List).cast<String>().toSet();
  if (await PhotoManager.requestPermissionExtend() != PermissionState.authorized) return null;
  final albums = (await PhotoManager.getAssetPathList())
      .where((a) => ids.contains(a.id)).toList();
  if (albums.isEmpty) return null;
  final uploads = await collectBackupAssets(albums);
  final last = await StorageUtil.getString('last_backup_time') ?? '';
  final docs = await getApplicationDocumentsDirectory();
  try {
    return await startAutoBackup(
      enabled: true,
      backupFolder: backupFolder,
      uploads: uploads,
      lastBackupTime: last.isNotBlank ? DateTime.fromMillisecondsSinceEpoch(int.parse(last)) : null,
      hasPendingBackup: hasPendingBackupTask(transferStore.tasks.value),
      enqueue: (cachePath, remoteDir) => enqueueFileUpload(localPath: cachePath, remoteDir: remoteDir),
      cacheRoot: Directory('${docs.path}/backup_cache'),
    );
  } on BackupEnqueueIncomplete catch (e) {
    Log.info('auto backup skipped: $e');
    return null;
  }
}
```

`backup.dart` 卡片：`final autoBackup = useSignal(false);`，`getData()` 里 `autoBackup.value = await StorageUtil.getBool('auto_backup') ?? false;`，卡片 `onTap` 切换并 `StorageUtil.setBool('auto_backup', autoBackup.value)`，`autoBackup.value` 为真时显示 `CupertinoIcons.checkmark_alt`。

`home.dart`：`useEffect(() { runAutoBackup(); return null; }, const []);`

- [ ] **Step 4: 跑测试**

Run: `flutter test test/pages/backup_ui_cleanup_test.dart && flutter test`
Expected: All tests passed

- [ ] **Step 5: 提交**

```bash
git add lib/pages/backup/backup.dart lib/pages/home.dart test/pages/backup_ui_cleanup_test.dart
git commit -m "feat(backup): run auto backup on app launch and add toggle"
```
