# Photo Backup Task Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the silent backup button failure and make photo backup one expandable upload task in the Transfer tab, with one sub-step per photo/video.

**Architecture:** Extend `TransferTask` with nullable `steps`; route background-downloader callbacks by step id and aggregate progress/state to the parent. The backup page copies each asset to a persistent cache, enqueues it via `enqueueFileUpload`, and no longer uses the old Dio direct upload. Transfer list gets a parent row with expandable step rows.

**Tech Stack:** Dart 3.5 / Flutter, `background_downloader: ^9.5.2`, `signals_flutter`/`signals_hooks`, `wechat_assets_picker: 10.1.0`, `path_provider`, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-11-20-photo-backup-task-design.md` plus its review findings 1–10 (accepted by the user).

## Global Constraints

- No new dependencies.
- Old `transfer_tasks` JSON must still load: missing `steps` key reads as null.
- Upload engine is v2 single-request today (`kUploadV3Supported = false`); do not enable v3.
- Existing single-file task behavior must not change.
- Photo permission behavior stays as-is (`PermissionState.authorized` only).
- `last_backup_time` must be maintained so 继续备份 does not re-upload everything.
- A partially enqueued backup must be visibly failed/paused, never silently complete.

## Review Focus

- Empty asset list: pressing 开始备份 shows a toast, never a dead button (test in Task 4).
- `last_backup_time`: completing a backup writes it; continuing备份 filters by it (test in Task 4).
- Old persisted tasks without `steps`: load as normal tasks, no crash (test in Task 1).
- iOS asset ids with `/` as cache folder names: sanitized, no nested path (test in Task 4).
- Callback from engine arriving as step id through `updateProgress`/`applyTaskStatus`/`setError`: routed to the step, not dropped (test in Task 2).
- Deleting a parent task: every step's engine DB record is deleted (test in Task 5).

---

### Task 1: Extend transfer model with steps and fix callback routing

**Files:**
- Modify: `lib/stores/transfer_store.dart`
- Test: `test/stores/transfer_store_test.dart`

**Interfaces:**
- Consumes: existing `TransferTask`, `TransferStore` API, `TaskStatusUpdate`/`TaskProgressUpdate` from `background_downloader`.
- Produces: `class TransferStep { final String id; final String localPath; final String remotePath; final int totalBytes; final int transferredBytes; final TransferState state; final DateTime? modifyTime; final String? errorMessage; ... }`; `TransferTask.steps` (nullable); `TransferStep copyWith({...})`; `TransferStore.updateStep(String groupId, String stepId, {int? transferred, int? total, TransferState? state, String? errorMessage, bool forceActive = false})`; `TransferStore.findStepOwner(String stepId) → ({String groupId, TransferStep step})?`; `TransferStore.addStep(String groupId, TransferStep step)`; `TransferStore.removeStep(String groupId, String stepId)`; `TransferStore.deleteTransferCache(String groupId)`; existing `updateProgress`/`setState`/`setError`/`applyTaskStatus` now route step ids automatically.

- [ ] **Step 1: Write failing tests for step model + JSON roundtrip + legacy JSON**

In `test/stores/transfer_store_test.dart` add:

```dart
test('parent with steps roundtrips JSON and legacy task has null steps', () {
  final parent = TransferTask(
    id: 'backup_1', type: TransferType.upload,
    localPath: '', remotePath: '/photos', state: TransferState.active,
    steps: [
      TransferStep(
        id: 'step1', localPath: '/cache/a.jpg', remotePath: '/photos/a.jpg',
        totalBytes: 100, transferredBytes: 40, state: TransferState.active,
        modifyTime: DateTime(2026, 1, 2, 3, 4, 5),
      ),
    ],
  );
  expect(TransferTask.fromJson(parent.toJson()).toJson(), parent.toJson());
  final legacy = TransferTask.fromJson({
    'id': 'old', 'type': 1, 'localPath': '/l', 'remotePath': '/r',
    'state': 0,
  });
  expect(legacy.steps, isNull);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/stores/transfer_store_test.dart`
Expected: compile error — `TransferStep` / `steps` undefined.

- [ ] **Step 3: Implement `TransferStep` and `TransferTask.steps`**

In `lib/stores/transfer_store.dart`: define `TransferStep` with `toJson/fromJson/copyWith` next to `ChunkState`; add nullable `steps` to `TransferTask` constructor, `copyWith`, `toJson`, `fromJson`. Use key `'steps'`; omit when null.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/stores/transfer_store_test.dart`
Expected: PASS.

- [ ] **Step 5: Write failing tests for step routing + aggregation**

```dart
test('engine callbacks routed by step id aggregate to parent', () {
  final store = TransferStore();
  store.add(const TransferTask(
    id: 'backup_1', type: TransferType.upload,
    localPath: '', remotePath: '/photos', state: TransferState.queued,
    steps: [
      TransferStep(id: 's1', localPath: '/c/a', remotePath: '/photos/a',
          totalBytes: 100, transferredBytes: 0, state: TransferState.queued),
      TransferStep(id: 's2', localPath: '/c/b', remotePath: '/photos/b',
          totalBytes: 200, transferredBytes: 0, state: TransferState.queued),
    ],
  ));
  store.updateProgress('s1', 50, 100,
      speedBytesPerSecond: 1.5, etaSeconds: 7);
  var parent = store.tasks.value.first;
  expect(_step(parent, 's1').transferredBytes, 50);
  expect(parent.transferredBytes, 50);
  expect(parent.totalBytes, 300);
  expect(parent.state, TransferState.active);
  expect(parent.speedBytesPerSecond, 1.5);

  store.applyTaskStatus('s2', TaskStatus.complete);
  parent = store.tasks.value.first;
  expect(_step(parent, 's2').state, TransferState.done);

  store.updateProgress('s2', 200, 200);
  store.applyTaskStatus('s1', TaskStatus.complete);
  parent = store.tasks.value.first;
  expect(parent.state, TransferState.done);
  expect(parent.transferredBytes, 300);
});

test('setError on step id marks step and parent error', () { ... });
```

Add a local helper `TransferStep _step(TransferTask t, String id) => t.steps!.firstWhere((s) => s.id == id);` in the test file.

- [ ] **Step 6: Run test to verify it fails**

Run: `flutter test test/stores/transfer_store_test.dart`
Expected: FAIL — step unchanged / parent not aggregated.

- [ ] **Step 7: Implement routing and aggregation**

In `lib/stores/transfer_store.dart`:
- `findStepOwner(String stepId)` scans `tasks.value` for a task whose `steps` contains `stepId`.
- `updateProgress`, `setState`, `setError` first call `findStepOwner(id)`; if found, call `updateStep(groupId, id, ...)` and return.
- `updateStep` replaces the step, recomputes parent `transferredBytes = sum(steps.transferredBytes)`, `totalBytes = sum(steps.totalBytes)`, `speedBytesPerSecond`/`etaSeconds` from the changed step, `updatedAt = DateTime.now()`, and parent state: any `queued`/`active` → active; else any `error` → error; else all `done` → done; else paused/canceled as uniform.
- `addStep`/`removeStep` mutate the parent's `steps` via copyWith + `_replace`, recomputing totals/state.
- `applyTaskStatus` and `applyTaskStatusUpdate` keep their existing mapping but now benefit from `setState`/`setError` routing.

- [ ] **Step 8: Run test to verify it passes**

Run: `flutter test test/stores/transfer_store_test.dart`
Expected: PASS.

- [ ] **Step 9: Commit**

```bash
git add lib/stores/transfer_store.dart test/stores/transfer_store_test.dart
git commit -m "feat(transfer): add backup task steps and callback routing"
```

---

### Task 2: Wire real engine controls for pause/resume/cancel

**Files:**
- Modify: `lib/stores/transfer_store.dart`
- Test: `test/stores/transfer_store_test.dart`

**Interfaces:**
- Consumes: `TransferStep` from Task 1; `FileDownloader().taskForId(String)`, `FileDownloader().pause(Task)`, `FileDownloader().resume(Task)`, `FileDownloader().cancelTaskWithId(String)`.
- Produces: `resumeTask/pauseTask/cancelTask` call the injected hooks if provided, otherwise `FileDownloader()` directly for single tasks and every step of a parent.

- [ ] **Step 1: Write failing test for hookless control**

```dart
test('pause/cancel/resume without injected hooks still reach engine steps', () async {
  final store = TransferStore();
  const parent = TransferTask(
    id: 'backup_1', type: TransferType.upload,
    localPath: '', remotePath: '/photos', state: TransferState.active,
    steps: [
      TransferStep(id: 's1', localPath: '/c/a', remotePath: '/photos/a',
          totalBytes: 1, transferredBytes: 0, state: TransferState.active),
    ],
  );
  store.add(parent);
  // No FileDownloader in unit test: assert the new default hook exists.
  expect(store.hasDefaultControlHooks, isTrue);
  expect(store.defaultControlFor('s1'), isNotNull);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/stores/transfer_store_test.dart`
Expected: FAIL — getters undefined.

- [ ] **Step 3: Implement default control hooks**

In `lib/stores/transfer_store.dart`: add `bool get hasDefaultControlHooks => true;` and `ControlHook? defaultControlFor(String id) => (id) async { final task = await FileDownloader().taskForId(id); if (task == null) return false; return switch (kind) ... };` — implement three private helpers `_defaultResume`, `_defaultPause`, `_defaultCancel` using `taskForId` + `pause`/`resume`/`cancelTaskWithId`. In `resumeTask/pauseTask/cancelTask`, replace the null fallback with these helpers: `(onResume ?? _defaultResume).call(id)` etc. For parent ids, iterate `steps` and call the chosen hook for each step id, returning true if any succeeded; update parent state as today.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/stores/transfer_store_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/stores/transfer_store.dart test/stores/transfer_store_test.dart
git commit -m "fix(transfer): engine controls work without injected hooks"
```

---

### Task 3: Sanitize cache paths and extract asset flattening with regression test

**Files:**
- Modify: `lib/pages/backup/backup.dart`
- Test: `test/pages/backup_asset_list_test.dart`

**Interfaces:**
- Consumes: `AssetEntity`/`AssetPathEntity` from `wechat_assets_picker`.
- Produces: `List<AssetEntity> collectBackupAssets(Iterable<AssetPathEntity> albums)` (typed flatten + dedupe by id); `String backupCacheDirName(String assetId)` (sanitize to `[A-Za-z0-9]`).

- [ ] **Step 1: Write failing regression test**

```dart
import 'package:garden/pages/backup/backup.dart';

test('collectBackupAssets flattens typed and dedupes by id', () {
  final a = _FakeAlbum(['a', 'b']);
  final b = _FakeAlbum(['b', 'c']);
  final result = collectBackupAssets([a, b]);
  expect(result.map((e) => e.id), ['a', 'b', 'c']);
});

test('backupCacheDirName strips slashes and punctuation', () {
  expect(backupCacheDirName('91D2/L0/001'), '91D2_L0_001');
});
```

`_FakeAlbum` must implement enough of `AssetPathEntity` to satisfy `collectBackupAssets`; if constructing is awkward, make `collectBackupAssets` take `Future<List<AssetEntity>> Function(AssetPathEntity)` as a named parameter with a default that calls `album.getAssetListRange(start: 0, end: 100000000)`, and inject that function in the test.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/pages/backup_asset_list_test.dart`
Expected: compile error — functions undefined.

- [ ] **Step 3: Implement helpers in `lib/pages/backup/backup.dart`**

`collectBackupAssets` calls the injected fetch, appends into a typed `List<AssetEntity>`, dedupes by `id` via a `Set<String>`. `backupCacheDirName` uses `assetId.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_')`. Change `getAssetCount()` to `uploads.value = collectBackupAssets(albums.value)` (or clear+addAll through ListSignal); no cast anywhere.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/pages/backup_asset_list_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/pages/backup/backup.dart test/pages/backup_asset_list_test.dart
git commit -m "fix(backup): typed asset collection and safe cache folder names"
```

---

### Task 4: Rewrite backup start flow to enqueue a parent task

**Files:**
- Modify: `lib/pages/backup/backup.dart`
- Test: `test/pages/backup_start_test.dart` (source-level + pure helper test)

**Interfaces:**
- Consumes: `collectBackupAssets`, `backupCacheDirName` from Task 3; `transferStore`, `TransferTask`, `TransferStep` from Task 1; `enqueueFileUpload` from `lib/services/transfer_upload.dart`.
- Produces: `List<AssetEntity> backupPendingAssets(List<AssetEntity> uploads, DateTime? lastBackupTime, bool continueBackup)`; `Future<TransferTask> startBackup({required String backupFolder, required List<AssetEntity> assets, required Future<String> Function(String cachePath, String remoteDir) enqueue, required Directory cacheRoot})` — adds the parent task to `transferStore`, copies each asset, enqueues, adds steps; throws `BackupEnqueueIncomplete` if any step fails.

- [ ] **Step 1: Write failing tests**

```dart
test('backupPendingAssets filters by modifiedDateTime for continue', () {
  final older = _Asset(DateTime(2026, 1, 1));
  final newer = _Asset(DateTime(2026, 2, 1));
  final since = DateTime(2026, 1, 15);
  expect(backupPendingAssets([older, newer], since, true), [newer]);
  expect(backupPendingAssets([older, newer], since, false).length, 2);
});

test('startBackup adds one parent with one step per asset and keeps modifyTime', () async {
  final cacheRoot = await Directory.systemTemp.createTemp('backup_test_');
  final asset = _Asset(DateTime(2026, 2, 1), id: '91D2/L0/001');
  final parent = await startBackup(
    backupFolder: '/photos', assets: [asset], cacheRoot: cacheRoot,
    enqueue: (cachePath, remoteDir) async => 'step1',
  );
  expect(parent.steps!.length, 1);
  expect(parent.steps!.first.id, 'step1');
  expect(parent.steps!.first.modifyTime, asset.modifiedDateTime);
  expect(parent.steps!.first.localPath, contains('91D2_L0_001'));
  expect(transferStore.tasks.value.any((t) => t.id == parent.id), isTrue);
  transferStore.remove(parent.id);
});
```

`_Asset` is a minimal fake implementing the members used (`modifiedDateTime`, `id`, `originFile`). Give it a real temp file for `originFile`.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/pages/backup_start_test.dart`
Expected: compile error — functions undefined.

- [ ] **Step 3: Implement backup helpers and rewrite `onStartBackup`**

In `lib/pages/backup/backup.dart`:
- `backupPendingAssets` filters and sorts by `modifiedDateTime`.
- `startBackup` builds `parent = TransferTask(id: 'backup_${DateTime.now().microsecondsSinceEpoch}', type: upload, localPath: '', remotePath: backupFolder, state: queued, steps: [])`, adds it first. For each asset: `final file = await asset.originFile`; `final cacheDir = Directory('${cacheRoot.path}/${backupCacheDirName(asset.id)}')..createSync(recursive: true)`; copy to `${cacheDir.path}/${file.path.split(Platform.pathSeparator).last}`; `setLastModifiedSync(asset.modifiedDateTime)`; `final taskId = await enqueue(path, backupFolder)`; `addStep(parent.id, TransferStep(id: taskId, localPath: path, remotePath: '$backupFolder/$filename', state: active, modifyTime: asset.modifiedDateTime))`. If any asset fails, mark parent `error` with `errorMessage` and throw `BackupEnqueueIncomplete`.
- `onStartBackup` validates as before; if pending is empty → vibrate + toast "没有需要备份的文件" + return; call `startBackup(...)` with real `enqueueFileUpload` and `getApplicationDocumentsDirectory()/backup_cache`; toast "已创建备份任务，请到传输页查看".
- Add a `transferStore.tasks` listener (or check in `onStartBackup` via `ever`) that, when a parent with steps transitions to done, writes `last_backup_time = max(modifyTime)` and sets `lastBackupTime.value`. Implement as a small function `syncBackupTimeOnCompletion()` called from `initState` via `useEffect`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/pages/backup_start_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/pages/backup/backup.dart test/pages/backup_start_test.dart
git commit -m "feat(backup): enqueue backup as parent transfer task"
```

---

### Task 5: Transfer list parent row, step actions, and cache cleanup

**Files:**
- Modify: `lib/widgets/transfer_list.dart`
- Test: `test/widgets/transfer_list_test.dart`

**Interfaces:**
- Consumes: `TransferTask.steps`, `TransferStep`, `TransferStore.removeStep/deleteTransferCache` from Tasks 1–2.
- Produces: `String transferTaskName(TransferTask t)` (returns whether parent or normal); `_buildRow` parent branch; step-level retry/remove wired into `_showActions`/`_remove`.

- [ ] **Step 1: Write failing widget tests**

```dart
testWidgets('parent backup task expands to show steps', (tester) async {
  final parent = TransferTask(
    id: 'backup_1', type: TransferType.upload,
    localPath: '', remotePath: '/photos', state: TransferState.active,
    steps: [
      TransferStep(id: 's1', localPath: '/c/a.jpg', remotePath: '/photos/a.jpg',
          totalBytes: 100, transferredBytes: 50, state: TransferState.active),
    ],
  );
  transferStore.add(parent);
  addTearDown(() => transferStore.remove(parent.id));
  await tester.pumpWidget(const MaterialApp(
    home: Scaffold(body: TransferList(type: TransferType.upload)),
  ));
  expect(find.textContaining('相册备份'), findsOneWidget);
  await tester.tap(find.textContaining('相册备份'));
  await tester.pump();
  expect(find.textContaining('a.jpg'), findsOneWidget);
});
```

Second test: call `_retry` path with a failed step through the action sheet and assert a new step id replaces the old one (unit test can call a new pure helper if widget path is awkward).

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widgets/transfer_list_test.dart`
Expected: FAIL — no parent name / no step row.

- [ ] **Step 3: Implement parent row + step actions**

In `lib/widgets/transfer_list.dart`:
- Add `transferTaskName`: parent → "相册备份（N 个文件）", normal → existing `_nameOf`.
- In `filterTransferTasks`, match keyword against `transferTaskName(t)` in addition to paths.
- In `_buildRow`, if `t.steps != null`, show expand icon and a `useState<Set<String>>` expanded set on the widget state; expanded rows show each step's name, state, `transferred/total`, error.
- In `_showActions`, for parent: 暂停/继续/取消 delegate to store parent id; 移除 calls `transferStore.deleteTransferCache(t.id)` for every step cache dir then `remove`; 重试 disabled at parent level, offered per expanded step via a small action calling `enqueueFileUpload(step.localPath, dirname(step.remotePath))` then `removeStep/addStep`.
- In `_remove`, for each step call `FileDownloader().database.deleteRecordWithId(step.id)` before `transferStore.remove(id)`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widgets/transfer_list_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/transfer_list.dart test/widgets/transfer_list_test.dart
git commit -m "feat(transfer): expandable backup task rows and step actions"
```

---

### Task 6: Multi-select restore by id and remove dead backup UI

**Files:**
- Modify: `lib/pages/common/select_ablum.dart`
- Modify: `lib/pages/backup/backup.dart`
- Delete: `lib/pages/backup/backup_model.dart`
- Test: `test/pages/backup_ui_cleanup_test.dart` (source-level assertions)

**Interfaces:**
- Consumes: `AssetPathEntity.id` from `wechat_assets_picker`.
- Produces: `bool isSameAlbum(AssetPathEntity a, AssetPathEntity b) => a.id == b.id;` in `select_ablum.dart`.

- [ ] **Step 1: Write failing test**

```dart
test('album selection compares by id', () {
  final source = File('lib/pages/common/select_ablum.dart').readAsStringSync();
  expect(source, contains('a.id == b.id'));
  expect(source, isNot(contains('selectedAlbums.value.contains(album)')));
});

test('backup page no longer holds legacy uploading state', () {
  final source = File('lib/pages/backup/backup.dart').readAsStringSync();
  expect(source, isNot(contains('useSignal<UploadItem?>(null)')));
  expect(source, isNot(contains('dsmFileStationUploadForPage')));
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/pages/backup_ui_cleanup_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement cleanup**

In `lib/pages/common/select_ablum.dart`: add `isSameAlbum`; replace `contains` checks with `any((e) => isSameAlbum(e, album))` for selected state and toggle logic.

In `lib/pages/backup/backup.dart`: delete `uploading`, `cancel`, `UploadItem` usage, progress card, and the old cancel button branch; the start button becomes always `onTap: onStartBackup` with text "开始备份". Delete `lib/pages/backup/backup_model.dart` after `grep -rn UploadItem lib/` confirms no other callers.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/pages/backup_ui_cleanup_test.dart`
Expected: PASS.

- [ ] **Step 5: Full verification and commit**

Run: `dart analyze lib test` and `flutter test`
Expected: no errors; all tests pass.

```bash
git add lib/pages/common/select_ablum.dart lib/pages/backup/backup.dart lib/pages/backup/backup_model.dart test/pages/backup_ui_cleanup_test.dart
git commit -m "refactor(backup): id-based album selection and remove dead upload UI"
```
