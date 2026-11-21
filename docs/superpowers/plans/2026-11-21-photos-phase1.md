# Photos Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the read-only gaps of the in-app Synology Photos page: personal-space album create/delete, photo delete from the preview (only with a real captured API contract), and removal of the dead placeholder file. Sharing links/permissions and other phase-2 features stay out of scope.

**Architecture:** Reuse the declared write APIs (`dsmFotoBrowseAlbumCreate`, `dsmFotoBrowseAlbumDelete`) and existing bottom sheets/toasts in `lib/pages/photos/album_tab.dart`. Keep write UI strictly in personal space (`isTeam == false`) because `_fotoApiName()` in `lib/api/dsm_api.photos.dart:3-6` has no FotoTeam branch. For photo delete, add a captured request-data helper beside `dsmFotoBrowseItemList` and an optional callback on the shared `ImagePreview`, leaving the FileStation `paths` delete branch untouched. Tests follow the repo's pure-helper + source-level assertion pattern; no HTTP mocking dependency.

**Tech Stack:** Dart 3.5 / Flutter, `signals_hooks`, `flutter_test`, existing `dio`-backed `lib/api/dsm_api*.dart`, existing `BottomActionSheet`/`BottomConfirmSheet`/`UiUtil`.

**Spec:** `docs/superpowers/specs/2026-11-21-photos-phase1-design.md` (approved by user in m00113).

## Global Constraints

- No new dependencies. No changes to FileStation delete, backup, transfer, or sharing APIs.
- No write UI when `isTeam == true` (write endpoints do not target FotoTeam).
- Never guess a `/webapi/entry.cgi` method/version/field name for photo delete. `docs/API_CAPTURE.md:242,259` records these write calls as never captured. If the user has not supplied a capture in the conversation, Task 3 is skipped by its Step 1 gate and reported as not delivered.
- Every task starts with a failing test and ends with a passing test. Full-suite baseline: `flutter test --reporter compact` = 131 passed; `dart analyze lib test` = 0 errors, 7 warnings, 425 infos.
- Do not touch untracked files `.memory/`, `.pi/`, or another session's `docs/superpowers/plans/2026-11-21-application-drawer-layout.md`.
- Commit messages follow the repo's Conventional Commits style; each task commits only its own files.

## Review Focus

- Blank/overlong album name must be rejected before a write call (Task 1 Step 1 validates `validateAlbumName`).
- Team space must not gain write controls (Task 1 Step 1 source assertion for `!isTeam`).
- Album delete must send `e.id.toString()` because `AlbumModel.id` is `num?` (Task 1 Step 1 source assertion).
- Preview's file-page delete branch and Photo's new delete branch must coexist (Task 3 Step 2 test asserts both source conditions), otherwise FileStation pages lose delete.
- The 0-byte placeholder must actually disappear and stay unreferenced (Task 2 Step 1 test).
- Full suite and analyzer must stay at baseline (Task 4 Steps 1–2).

---

### Task 1: Personal-space album create and confirmed delete

**Files:**
- Modify: `lib/pages/photos/album_tab.dart`
- Create: `test/pages/photos_album_actions_test.dart`

**Interfaces:**
- Consumes: `Future<Map> dsmFotoBrowseAlbumCreate(String name, {String? condition, CancelToken? cancelToken})` and `Future<Map> dsmFotoBrowseAlbumDelete(String id, {CancelToken? cancelToken})` from `lib/api/dsm_api.photos.dart:95,113`; `BottomConfirmSheet` from `lib/widgets/bottom_confirm_sheet.dart`; `BottomActionSheet`/`BottomActionItem` from `lib/widgets/bottom_action_sheet.dart`; `UiUtil.toast` from `lib/util/ui_util.dart`; `AlbumModel.id` (`num?`) from `lib/models/photos/album_model.dart:115`.
- Produces: top-level pure function `String? validateAlbumName(String? raw)` in `lib/pages/photos/album_tab.dart` returning `null` for a valid trimmed name of 1–60 characters and an error message otherwise; a create entry and long-press delete on album cards in `AlbumTab`.

**Steps:**

- [ ] **Step 1: Write failing tests**

Create `test/pages/photos_album_actions_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:garden/pages/photos/album_tab.dart';

void main() {
  test('validateAlbumName rejects blank and overlong names', () {
    expect(validateAlbumName(null), isNotNull);
    expect(validateAlbumName('   '), isNotNull);
    expect(validateAlbumName('x' * 61), isNotNull);
    expect(validateAlbumName('  新相册  '), isNull);
  });

  test('album write UI is wired only for personal space', () {
    final src = File('lib/pages/photos/album_tab.dart').readAsStringSync();
    expect(src, contains('dsmFotoBrowseAlbumCreate('));
    expect(src, contains('dsmFotoBrowseAlbumDelete(e.id.toString())'));
    expect(src, contains('BottomActionSheet('));
    expect(src, contains('BottomConfirmSheet('));
    expect(src, contains('if (!isTeam)'));
    expect(src, contains('validateAlbumName('));
    expect(src, contains('getAlbum();'));
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/pages/photos_album_actions_test.dart`
Expected: compile error — `validateAlbumName` undefined.

- [ ] **Step 3: Implement validation and the two write actions**

In `lib/pages/photos/album_tab.dart`, add imports for `package:garden/api/dsm_api.dart`, `package:garden/util/ui_util.dart`, `package:garden/widgets/bottom_action_sheet.dart`, `package:garden/widgets/bottom_confirm_sheet.dart`, and declare at file top level:

```dart
String? validateAlbumName(String? raw) {
  final name = raw?.trim() ?? '';
  if (name.isEmpty) return '请输入相册名称';
  if (name.length > 60) return '相册名称不能超过 60 个字符';
  return null;
}
```

Inside `AlbumTab.build`, wrap the new create tile and the existing album-card `onLongPress` in `if (!isTeam)`:

- Add a `GestureDetector` tile before `...albums.value.map((e) {` that shows a `CupertinoAlertDialog` containing a `TextField` plus 取消/创建 actions; on 创建, validate via `validateAlbumName(controller.text)`, return on error, otherwise `await dsmFotoBrowseAlbumCreate(controller.text.trim())`, `UiUtil.toast("相册创建成功")`, `await getAlbum()`, and toast `"相册创建失败"` in `catch`.
- Add `onLongPress` to the existing album `GestureDetector` (the one at `lib/pages/photos/album_tab.dart:220-240` that opens `AlbumPage(e, isTeam: isTeam)`) showing `BottomActionSheet(title: "相册操作", actions: [BottomActionItem(label: "删除相册", iconAsset: "assets/icons/delete.png", labelColor: Colors.redAccent, onPressed: …)])`; its tap shows `BottomConfirmSheet(title: "确认删除", content: "确认删除相册「${e.name ?? ''}」？", confirmText: "确认删除")`, then `await dsmFotoBrowseAlbumDelete(e.id.toString())`, `UiUtil.toast("相册删除成功")`, `await getAlbum()`, with a `"相册删除失败"` toast in `catch`.
- Do not add `onLongPress` or a create tile for team space; keep the existing `onTap` navigation unchanged for both spaces.

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/pages/photos_album_actions_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Analyze the touched files**

Run: `dart analyze lib/pages/photos/album_tab.dart test/pages/photos_album_actions_test.dart`
Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/pages/photos/album_tab.dart test/pages/photos_album_actions_test.dart
git commit -m "feat(photos): add personal album create and delete actions"
```

---

### Task 2: Remove the dead placeholder widget

**Files:**
- Delete: `lib/pages/photos/widgets/folder_item_widget.dart` (0 bytes)
- Create: `test/pages/photos_cleanup_test.dart`

**Interfaces:**
- Consumes: `dart:io` `File`, `flutter_test`.
- Produces: one source-level regression test asserting the placeholder is gone and unreferenced.

**Steps:**

- [ ] **Step 1: Write failing test**

Create `test/pages/photos_cleanup_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('obsolete folder_item_widget is gone and unreferenced', () {
    expect(File('lib/pages/photos/widgets/folder_item_widget.dart').existsSync(),
        isFalse);
    for (final path in [
      'lib/pages/photos/folder.dart',
      'lib/pages/photos/album_tab.dart',
      'lib/pages/photos/photo_tab.dart',
    ]) {
      expect(File(path).readAsStringSync(), isNot(contains('folder_item_widget')));
    }
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/pages/photos_cleanup_test.dart`
Expected: FAIL — file still exists.

- [ ] **Step 3: Delete the file**

Run: `git rm lib/pages/photos/widgets/folder_item_widget.dart`
Expected: file removed; no other code changes.

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/pages/photos_cleanup_test.dart`
Expected: PASS (1 test).

- [ ] **Step 5: Commit**

```bash
git commit -m "chore(photos): remove empty placeholder widget file"
```

---

### Task 3: Photo delete from preview (gated on a real API capture)

**Files:**
- Modify: `lib/api/dsm_api.photos.items.dart`
- Modify: `lib/pages/common/image_preview.dart`
- Modify: `lib/pages/photos/timeline.dart`
- Modify: `lib/pages/photos/widgets/photo_item_widget.dart`
- Modify: `lib/pages/photos/album_page.dart` (only if it is the other `ImagePreview` call site)
- Create: `test/api/dsm_api_photos_write_test.dart`

**Interfaces:**
- Consumes: `_dsmApiRequestData`, `_httpPost`, `_fotoEntryCGI`, `DSMException` from `lib/api/dsm_api.dart` / `lib/api/dsm_api.photos.dart`; `ImagePreview(this.images, this.index, {this.network=true, this.tag, this.thumbs=const [], this.names=const [], this.paths=const [], this.onDelete})` from `lib/pages/common/image_preview.dart:29-36`; `MySwiperPlugin` delete button path at `lib/pages/common/image_preview.dart:395,457-507`.
- Produces: `Map<String, dynamic> dsmFotoBrowseItemDeleteRequestData(List<String> ids)`, `Future<Map> dsmFotoBrowseItemDelete(List<String> ids)`, and optional `Future<void> Function(int index)? onDeletePhoto` on `ImagePreview` (index-based because `ImagePreview` holds URL strings, not photo ids).

**Steps:**

- [ ] **Step 1: Apply the capture gate**

Check whether the user has supplied a concrete capture (api string, method, version, request field names, sample response) for deleting a Photo item in the current conversation. If not, STOP this task: do not change any file, do not invent a contract, and record `照片删除未做：缺抓包` in the final handoff. Continue to Task 4. If a capture exists, copy its exact strings into Step 2's test before writing any implementation.

- [ ] **Step 2: Write failing request-data and wiring tests**

Create `test/api/dsm_api_photos_write_test.dart` with assertions using the captured values (example shape, replace with the captured strings):

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:garden/api/dsm_api.photos.items.dart';

void main() {
  test('dsmFotoBrowseItemDeleteRequestData matches captured payload', () {
    final data = dsmFotoBrowseItemDeleteRequestData(['id-1', 'id-2']);
    expect(data['api'], '<captured api>');
    expect(data['method'], '<captured method>');
    expect(data['version'], <captured version>);
    expect(data['id'], json.encode(['id-1', 'id-2']));
  });

  test('photo delete callback coexists with FileStation delete', () {
    final preview = File('lib/pages/common/image_preview.dart').readAsStringSync();
    expect(preview, contains('onDeletePhoto'));
    expect(preview, contains('paths.length > currentIndex.value'));
    expect(preview, contains('dsmFileStationDeleteStartForPage'));
  });
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `flutter test test/api/dsm_api_photos_write_test.dart`
Expected: compile error — helper undefined.

- [ ] **Step 4: Implement the captured API helper**

In `lib/api/dsm_api.photos.items.dart`, add `dsmFotoBrowseItemDeleteRequestData(List<String> ids)` returning the captured api/method/version plus the captured id field, and `Future<Map> dsmFotoBrowseItemDelete(List<String> ids)` that posts via `_httpPost(_fotoEntryCGI, data: ...)`, throws `DSMException.fromMap(res)` when `res['success'] != true`, and returns `res['data'] ?? {}` — mirroring `dsmFotoBrowseAlbumDelete` in `lib/api/dsm_api.photos.dart:113`.

- [ ] **Step 5: Implement the preview callback without touching FileStation delete**

In `lib/pages/common/image_preview.dart`, add `final Future<void> Function(int index)? onDeletePhoto;` to the constructor as an optional named parameter. Add a second `onDelete` branch on `MySwiperPlugin` that is active when `onDeletePhoto != null`: show `BottomConfirmSheet(title: "确认删除", content: "确认要删除照片？")`, `await onDeletePhoto!(index)`, then remove the deleted item from the local `images`/`thumbs`/`names` lists (mirroring `deleteFile` at `lib/pages/common/image_preview.dart:84-108`), bump `rebuildIndex.value`, and call the existing `onDelete?.call()`. Keep the existing `paths.length > currentIndex.value → deleteFile(index)` branch for FileStation pages exactly as-is; when `paths.isEmpty`, the new callback branch is the only one active.

- [ ] **Step 6: Wire Photos call sites and refresh**

In `lib/pages/photos/timeline.dart:69`, `lib/pages/photos/widgets/photo_item_widget.dart:34-41`, and any other Photos-only `ImagePreview` call site, pass `onDeletePhoto: (index) async { await dsmFotoBrowseItemDelete([photos[index].id.toString()]); }` using that call site's own `List<PhotoModel>` (the variable passed as `images`), then toast success/failure and refresh the current Photos view. Do not add the callback to file-manager or FileStation call sites.

- [ ] **Step 7: Run the test to verify it passes**

Run: `flutter test test/api/dsm_api_photos_write_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 8: Commit**

```bash
git add lib/api/dsm_api.photos.items.dart lib/pages/common/image_preview.dart lib/pages/photos/timeline.dart lib/pages/photos/widgets/photo_item_widget.dart lib/pages/photos/album_page.dart test/api/dsm_api_photos_write_test.dart
git commit -m "feat(photos): add captured photo delete action"
```

---

### Task 4: Full verification and handoff

**Files:** none (verification only).

**Interfaces:**
- Consumes: all files changed in Tasks 1–3.
- Produces: a short handoff message stating delivered items, the gated-out item (if any), and exact verification results.

**Steps:**

- [ ] **Step 1: Run the full test suite**

Run: `flutter test --reporter compact`
Expected: exit 0, at least 131 tests passed, 0 failed.

- [ ] **Step 2: Run static analysis**

Run: `dart analyze lib test`
Expected: 0 errors. Warnings/infos may match the 7/425 baseline; do not fix unrelated ones in this plan.

- [ ] **Step 3: Confirm the working tree contains only intended changes**

Run: `git status --short && git log --oneline -4`
Expected: no unstaged intent-to-add leftovers; commits from Tasks 1–3 (and Task 2's deletion) present; untracked files listed in Global Constraints untouched.

- [ ] **Step 4: Report results**

Report each Task 1–3 with delivered / gated-out status and the exact commands/results of Steps 1–2. If Task 3 was gated out, state: `照片删除未做：缺抓包` and specify the capture fields needed.
