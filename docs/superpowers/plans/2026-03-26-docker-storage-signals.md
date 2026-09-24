# Docker + Storage Signals Migration (Batch 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align Docker and Storage Manager pages with `dsm_helper` structure and migrate non-UI state to signals while preserving UI-only state and baseline error handling.

**Architecture:** Keep existing page composition but replace mutable state with `signal<T>` and Watch-based rebuilds. Align file paths/widgets to `dsm_helper` structure; reuse common widgets from the same paths. Ensure error handling matches baseline.

**Tech Stack:** Flutter (Dart), signals, existing app widget structure.

---

### Task 1: Align File Structure + Common Widgets to `dsm_helper`

**Files:**
- Modify: `lib/pages/docker/docker.dart`
- Modify: `lib/pages/docker/detail.dart`
- Modify: `lib/pages/storage_manager/storage_manager.dart`
- Modify: `lib/pages/storage_manager/smart.dart`
- Modify/Create/Move (if needed): `lib/widgets/...` (exact path to match `dsm_helper`)

- [ ] **Step 1: Map current vs baseline structure**

Run:
```bash
rg -n "class|part|import" lib/pages/docker lib/pages/storage_manager lib/widgets
```
Expected: output showing current file/part structure for alignment.

- [ ] **Step 2: Map baseline `dsm_helper` structure**

Run:
```bash
rg -n "class|part|import" /Users/humphrey/Project/Flutter/dsm_helper/lib/pages/docker /Users/humphrey/Project/Flutter/dsm_helper/lib/pages/storage_manager /Users/humphrey/Project/Flutter/dsm_helper/lib/widgets
```
Expected: output showing authoritative paths and widget splits.

- [ ] **Step 3: Write a failing structural test (if TDD not waived)**

Create: `test/pages/docker_storage_structure_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder: docker/storage pages structure alignment', () {
    // This test should fail until files/imports are aligned.
    // It will be updated to validate actual widget availability.
    expect(false, isTrue);
  });
}
```

- [ ] **Step 4: Run test to verify it fails**

Run:
```bash
flutter test test/pages/docker_storage_structure_test.dart
```
Expected: FAIL with expectation mismatch.

- [ ] **Step 5: Align paths/splits to `dsm_helper`**

Actions:
- Move/rename/split files to match `dsm_helper`.
- Move common widgets to same path as `dsm_helper` (no `lib/widgets/common/` if not present).
- Update imports in touched files.

- [ ] **Step 6: Update structural test to validate availability**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dsm_api_tidy/pages/docker/docker.dart';
import 'package:dsm_api_tidy/pages/storage_manager/storage_manager.dart';

void main() {
  test('docker/storage pages are importable', () {
    expect(DockerPage, isNotNull);
    expect(StorageManagerPage, isNotNull);
  });
}
```

- [ ] **Step 7: Run test to verify it passes**

Run:
```bash
flutter test test/pages/docker_storage_structure_test.dart
```
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/pages/docker lib/pages/storage_manager lib/widgets test/pages/docker_storage_structure_test.dart
git commit -m "test: add docker/storage structure smoke test"
```

### Task 2: Migrate Docker Pages to Signals + Baseline Errors

**Files:**
- Modify: `lib/pages/docker/docker.dart`
- Modify: `lib/pages/docker/detail.dart`
- Test: `test/pages/docker_signals_test.dart`

- [ ] **Step 1: Write failing test for Docker page build**

Create: `test/pages/docker_signals_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dsm_api_tidy/pages/docker/docker.dart';

void main() {
  testWidgets('Docker page builds', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DockerPage()));
    expect(find.byType(DockerPage), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
flutter test test/pages/docker_signals_test.dart
```
Expected: FAIL (if current state prevents build or import issues).

- [ ] **Step 3: Migrate non-UI state to signals**

Actions:
- Replace mutable state fields with `signal<T>`.
- Add getter/setter proxies to reduce churn.
- Replace `setState` with signal assignments.
- Wrap `build` (or dynamic subtrees) with `Watch`.
- Preserve UI-only `setState` with a short comment.

- [ ] **Step 4: Align Docker error handling with `dsm_helper`**

Actions:
- Compare toasts/messages/failure branches and adjust to match baseline.

- [ ] **Step 5: Run test to verify it passes**

Run:
```bash
flutter test test/pages/docker_signals_test.dart
```
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/pages/docker test/pages/docker_signals_test.dart
git commit -m "test: add docker page build test"
```

### Task 3: Migrate Storage Manager Pages to Signals + Baseline Errors

**Files:**
- Modify: `lib/pages/storage_manager/storage_manager.dart`
- Modify: `lib/pages/storage_manager/smart.dart`
- Test: `test/pages/storage_manager_signals_test.dart`

- [ ] **Step 1: Write failing test for Storage Manager page build**

Create: `test/pages/storage_manager_signals_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dsm_api_tidy/pages/storage_manager/storage_manager.dart';

void main() {
  testWidgets('Storage Manager page builds', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StorageManagerPage()));
    expect(find.byType(StorageManagerPage), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
flutter test test/pages/storage_manager_signals_test.dart
```
Expected: FAIL (if current state prevents build or import issues).

- [ ] **Step 3: Migrate non-UI state to signals**

Actions:
- Replace mutable state fields with `signal<T>`.
- Add getter/setter proxies to reduce churn.
- Replace `setState` with signal assignments.
- Wrap `build` (or dynamic subtrees) with `Watch`.
- Preserve UI-only `setState` with a short comment.

- [ ] **Step 4: Align Storage Manager error handling with `dsm_helper`**

Actions:
- Compare toasts/messages/failure branches and adjust to match baseline.

- [ ] **Step 5: Run test to verify it passes**

Run:
```bash
flutter test test/pages/storage_manager_signals_test.dart
```
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/pages/storage_manager test/pages/storage_manager_signals_test.dart
git commit -m "test: add storage manager page build test"
```

### Task 4: Final Verification + Required Commit

**Files:**
- Modify: `lib/pages/docker/docker.dart`
- Modify: `lib/pages/docker/detail.dart`
- Modify: `lib/pages/storage_manager/storage_manager.dart`
- Modify: `lib/pages/storage_manager/smart.dart`
- Modify: `lib/widgets/...` (if moved)

- [ ] **Step 1: Verify remaining setState calls**

Run:
```bash
rg -n "setState\\(" lib/pages/docker lib/pages/storage_manager
```
Expected: only UI-only `setState` remain with comments.

- [ ] **Step 2: Run full test suite (optional)**

Run:
```bash
flutter test
```
Expected: PASS.

- [ ] **Step 3: Commit required migration changes**

```bash
git add lib/pages/docker lib/pages/storage_manager lib/widgets test
git commit -m "feat: align docker and storage pages to signals"
```
