# Signals UI Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align signals-integrated pages to `dsm_helper` UI structure while preserving signals logic and `baseUri` differences.

**Architecture:** UI structure and layout are aligned to `dsm_helper` as source of truth. Signals state management stays intact; only widget tree, styles, and component split are adjusted. URLs keep `baseUri` where required.

**Tech Stack:** Flutter, Dart, signals_flutter, existing app widgets

---

## File Structure Map

Files to modify (signals-integrated pages with UI differences):
- `lib/pages/dashborad/dashboard.dart`
- `lib/pages/dashborad/widget_setting.dart`
- `lib/pages/dashborad/shortcut_list.dart`
- `lib/pages/packages/detail.dart`
- `lib/pages/packages/packages.dart`
- `lib/pages/setting/helper_setting.dart`
- `lib/pages/setting/setting.dart`
- `lib/pages/resource_monitor/performance.dart`
- `lib/pages/resource_monitor/task_manager.dart`
- `lib/pages/security_scan/security_scan.dart`
- `lib/pages/notify/notify.dart`
- `lib/pages/moments/album.dart`
- `lib/pages/moments/moments.dart`
- `lib/pages/moments/photos.dart`
- `lib/pages/moments/timeline.dart`
- `lib/pages/file/file.dart`
- `lib/pages/home.dart`
- `lib/pages/login/accounts.dart`
- `lib/pages/login/login.dart`

Helper source of truth for UI structure:
- `/Users/humphrey/Project/Flutter/dsm_helper/lib/pages/...`

## Task 1: Align Dashboard Pages UI Structure

**Files:**
- Modify: `lib/pages/dashborad/dashboard.dart`
- Modify: `lib/pages/dashborad/widget_setting.dart`
- Modify: `lib/pages/dashborad/shortcut_list.dart`

- [ ] **Step 1: Diff dashboard pages vs helper**

Run:
```bash
for f in dashboard.dart widget_setting.dart shortcut_list.dart; do diff -u /Users/humphrey/Project/Flutter/dsm_helper/lib/pages/dashborad/$f lib/pages/dashborad/$f | head -n 200; done
```

Expected: visible UI/structure differences only.

- [ ] **Step 2: Update widget hierarchy and layout**

Apply UI structure changes to match helper (containers, padding, card shapes, spacing, icon placement). Keep signals state and reactive usage unchanged.

- [ ] **Step 3: Preserve baseUri**

If helper uses `baseUrl`, ensure this project keeps `baseUri` where URLs are built.

- [ ] **Step 4: Quick sanity scan**

Run:
```bash
rg -n "baseUrl" lib/pages/dashborad
```

Expected: no `baseUrl` introduced; only `baseUri` where relevant.

- [ ] **Step 5: Commit**

```bash
git add lib/pages/dashborad/dashboard.dart lib/pages/dashborad/widget_setting.dart lib/pages/dashborad/shortcut_list.dart
git commit -m "feat: align dashboard UI to helper while keeping signals"
```

## Task 2: Align Packages Pages UI Structure

**Files:**
- Modify: `lib/pages/packages/detail.dart`
- Modify: `lib/pages/packages/packages.dart`

- [ ] **Step 1: Diff packages pages vs helper**

Run:
```bash
for f in detail.dart packages.dart; do diff -u /Users/humphrey/Project/Flutter/dsm_helper/lib/pages/packages/$f lib/pages/packages/$f | head -n 200; done
```

- [ ] **Step 2: Update widget hierarchy and layout**

Match helper layout and component arrangement, keep signals state and computed lists intact.

- [ ] **Step 3: Preserve baseUri**

If URLs are adjusted, keep `baseUri`.

- [ ] **Step 4: Commit**

```bash
git add lib/pages/packages/detail.dart lib/pages/packages/packages.dart
git commit -m "feat: align packages UI to helper while keeping signals"
```

## Task 3: Align Settings Pages UI Structure

**Files:**
- Modify: `lib/pages/setting/helper_setting.dart`
- Modify: `lib/pages/setting/setting.dart`

- [ ] **Step 1: Diff settings pages vs helper**

Run:
```bash
for f in helper_setting.dart setting.dart; do diff -u /Users/humphrey/Project/Flutter/dsm_helper/lib/pages/setting/$f lib/pages/setting/$f | head -n 200; done
```

- [ ] **Step 2: Update widget hierarchy and layout**

Align layout, spacing, and component ordering to helper. Retain signals data flow.

- [ ] **Step 3: Commit**

```bash
git add lib/pages/setting/helper_setting.dart lib/pages/setting/setting.dart
git commit -m "feat: align settings UI to helper while keeping signals"
```

## Task 4: Align Resource Monitor Pages UI Structure

**Files:**
- Modify: `lib/pages/resource_monitor/performance.dart`
- Modify: `lib/pages/resource_monitor/task_manager.dart`

- [ ] **Step 1: Diff resource monitor pages vs helper**

Run:
```bash
for f in performance.dart task_manager.dart; do diff -u /Users/humphrey/Project/Flutter/dsm_helper/lib/pages/resource_monitor/$f lib/pages/resource_monitor/$f | head -n 200; done
```

- [ ] **Step 2: Update widget hierarchy and layout**

Align structure and spacing; do not alter data fetch or signals state.

- [ ] **Step 3: Commit**

```bash
git add lib/pages/resource_monitor/performance.dart lib/pages/resource_monitor/task_manager.dart
git commit -m "feat: align resource monitor UI to helper"
```

## Task 5: Align Misc Signals Pages UI Structure

**Files:**
- Modify: `lib/pages/security_scan/security_scan.dart`
- Modify: `lib/pages/notify/notify.dart`
- Modify: `lib/pages/moments/album.dart`
- Modify: `lib/pages/moments/moments.dart`
- Modify: `lib/pages/moments/photos.dart`
- Modify: `lib/pages/moments/timeline.dart`
- Modify: `lib/pages/file/file.dart`
- Modify: `lib/pages/home.dart`
- Modify: `lib/pages/login/accounts.dart`
- Modify: `lib/pages/login/login.dart`

- [ ] **Step 1: Diff misc pages vs helper**

Run:
```bash
for f in security_scan/ security_scan.dart notify/ notify.dart moments/album.dart moments/moments.dart moments/photos.dart moments/timeline.dart file/file.dart home.dart login/accounts.dart login/login.dart; do
  if [ -f /Users/humphrey/Project/Flutter/dsm_helper/lib/pages/$f ]; then
    diff -u /Users/humphrey/Project/Flutter/dsm_helper/lib/pages/$f lib/pages/$f | head -n 120;
  fi;
done
```

- [ ] **Step 2: Update widget hierarchy and layout**

Match helper structure; keep signals logic. Preserve `baseUri` where URLs are built.

- [ ] **Step 3: Commit**

```bash
git add lib/pages/security_scan/security_scan.dart lib/pages/notify/notify.dart lib/pages/moments/album.dart lib/pages/moments/moments.dart lib/pages/moments/photos.dart lib/pages/moments/timeline.dart lib/pages/file/file.dart lib/pages/home.dart lib/pages/login/accounts.dart lib/pages/login/login.dart
git commit -m "feat: align misc signals pages UI to helper"
```

## Task 6: Final Alignment Scan

**Files:**
- Modify: any remaining differences in signals-integrated pages

- [ ] **Step 1: Identify remaining diffs**

Run:
```bash
python3 - <<'PY'
from pathlib import Path
repo_root=Path('lib')
helper_root=Path('/Users/humphrey/Project/Flutter/dsm_helper/lib')

diffs=[]
for p in repo_root.rglob('pages/**/*.dart'):
    rel=p.relative_to(repo_root)
    if str(rel).startswith('pages/common'):
        continue
    hp=helper_root/rel
    if not hp.exists():
        continue
    if p.read_bytes()!=hp.read_bytes():
        diffs.append(rel)

print('\n'.join(str(p) for p in sorted(diffs)))
PY
```

- [ ] **Step 2: Fix remaining UI-only diffs**

Only adjust UI structure/spacing; keep signals logic and `baseUri`.

- [ ] **Step 3: Commit**

```bash
git add lib/pages
git commit -m "feat: finish signals UI alignment to helper"
```
