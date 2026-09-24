# Task 3 Batch 2 VM Packages Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align Virtual Machine and Packages pages to `dsm_helper` structure and signal-based state management, preserving UI-only `setState` with comments and matching error handling.

**Architecture:** Mirror `dsm_helper` file structure and widgets for VM and Packages flows. Convert non-UI state to signals, using copied collections for mutations. Keep UI-only `setState` for transient UI behavior with explicit comments. Validate remaining `setState` with `rg` and commit changes.

**Tech Stack:** Flutter (Dart), signals, existing app widgets/utilities.

---

### Task 1: Baseline Diff + File Mapping

**Files:**
- Read: `/Users/humphrey/Project/Flutter/dsm_helper/lib/pages/virtual_machine/**`
- Read: `/Users/humphrey/Project/Flutter/dsm_helper/lib/pages/packages/**`
- Read: `lib/pages/virtual_machine/virtual_machine.dart`
- Read: `lib/pages/packages/packages.dart`
- Read: `lib/pages/packages/detail.dart`
- Read: `lib/pages/packages/uninstall.dart`

- [ ] **Step 1: Identify baseline file structure**

List the `dsm_helper` VM and Packages-related files and any shared widgets they reference. Note required moves/renames/splits and widget path differences (no `lib/widgets/common/`).

- [ ] **Step 2: Map deltas**

Create a concise mapping from current files to baseline structure, including required import path changes.

### Task 2: Align Structure and Naming

**Files:**
- Modify: `lib/pages/virtual_machine/virtual_machine.dart`
- Modify: `lib/pages/packages/packages.dart`
- Modify: `lib/pages/packages/detail.dart`
- Modify: `lib/pages/packages/uninstall.dart`
- Modify/Create: related widgets under `lib/widgets/**`

- [ ] **Step 1: Move/rename/split as required**

Implement the structural changes to match `dsm_helper` for VM and Packages. Update imports and references accordingly.

- [ ] **Step 2: Verify no `lib/widgets/common/` imports remain for these flows**

Update widget paths to match baseline.

### Task 3: Convert State to Signals

**Files:**
- Modify: `lib/pages/virtual_machine/virtual_machine.dart`
- Modify: `lib/pages/packages/packages.dart`
- Modify: `lib/pages/packages/detail.dart`
- Modify: `lib/pages/packages/uninstall.dart`

- [ ] **Step 1: Replace non-UI `setState` with signals**

Migrate stateful data (API responses, loading, selections, lists/maps used for logic) to signals. Use copied lists/maps when mutating collections.

- [ ] **Step 2: Preserve UI-only `setState` with comments**

Keep only transient UI feedback/animation/gesture `setState`. Add comments explaining UI-only rationale.

### Task 4: Align Error Handling to `dsm_helper`

**Files:**
- Modify: `lib/pages/virtual_machine/virtual_machine.dart`
- Modify: `lib/pages/packages/packages.dart`
- Modify: `lib/pages/packages/detail.dart`
- Modify: `lib/pages/packages/uninstall.dart`

- [ ] **Step 1: Match error toasts/messages and failure branches**

Compare to `dsm_helper` and adjust error handling and messaging behavior to match baseline.

### Task 5: Verification

**Files:**
- Read: `lib/pages/virtual_machine/virtual_machine.dart`
- Read: `lib/pages/packages/packages.dart`
- Read: `lib/pages/packages/detail.dart`
- Read: `lib/pages/packages/uninstall.dart`

- [ ] **Step 1: Run ripgrep verification**

Run:
```
rg -n "setState\\(" lib/pages/virtual_machine lib/pages/packages
```
Expected: only UI-only `setState` remains.

### Task 6: Commit

- [ ] **Step 1: Stage changes**

Run:
```
git add lib/pages/virtual_machine lib/pages/packages lib/widgets
```

- [ ] **Step 2: Commit**

Run:
```
git commit -m "feat: align virtual machine and packages to signals"
```
