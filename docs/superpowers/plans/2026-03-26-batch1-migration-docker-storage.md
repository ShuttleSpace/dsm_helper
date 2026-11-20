# Batch 1 Migration (Docker + Storage Manager + Smart) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align Docker and Storage Manager pages to dsm_helper structure and signals-based state, preserving UI-only setState.

**Architecture:** Mirror dsm_helper file structure and shared widget locations, then replace state with signals while keeping UI-only setState and error handling consistent. Use Watch to bridge signals into build trees.

**Tech Stack:** Flutter, signals, dsm_helper parity

---

### Task 1: Map dsm_helper structure and shared widgets

**Files:**
- Modify: `lib/pages/docker/docker.dart`
- Modify: `lib/pages/docker/detail.dart`
- Modify: `lib/pages/storage_manager/storage_manager.dart`
- Modify: `lib/pages/storage_manager/smart.dart`
- Modify: common widgets/paths to match dsm_helper

- [ ] **Step 1: Inspect dsm_helper equivalents**

Open the matching files in `/Users/humphrey/Project/Flutter/dsm_helper` and note:
- Exact file paths
- Widget splits and names
- Shared/common widget locations
- Error handling patterns

- [ ] **Step 2: Align file paths and widget splits**

Move/rename/split files in this worktree to match dsm_helper. Update imports and references accordingly.

- [ ] **Step 3: Commit structural alignment (optional if clean)**

If changes are significant and cleanly isolated, commit after structural alignment. Otherwise fold into final commit.

---

### Task 2: Replace state with signals in Docker pages

**Files:**
- Modify: `lib/pages/docker/docker.dart`
- Modify: `lib/pages/docker/detail.dart`

- [ ] **Step 1: Identify mutable state**

List all non-UI-only state fields and replace with `signal<T>`.

- [ ] **Step 2: Add getter/setter proxies**

Expose `T get foo => _foo.value; set foo(T v) => _foo.value = v;` to minimize churn.

- [ ] **Step 3: Replace setState**

Replace behavioral setState calls with signal assignments. Preserve UI-only setState with comments like `// UI-only: ...`.

- [ ] **Step 4: Wrap build with Watch**

Wrap `build` or dynamic subtrees in `Watch` so signals trigger rebuilds.

- [ ] **Step 5: Align error handling**

Compare to dsm_helper behavior (toasts/messages/branches) and adjust to match.

---

### Task 3: Replace state with signals in Storage Manager pages

**Files:**
- Modify: `lib/pages/storage_manager/storage_manager.dart`
- Modify: `lib/pages/storage_manager/smart.dart`

- [ ] **Step 1: Identify mutable state**

List all non-UI-only state fields and replace with `signal<T>`.

- [ ] **Step 2: Add getter/setter proxies**

Expose `T get foo => _foo.value; set foo(T v) => _foo.value = v;` to minimize churn.

- [ ] **Step 3: Replace setState**

Replace behavioral setState calls with signal assignments. Preserve UI-only setState with comments like `// UI-only: ...`.

- [ ] **Step 4: Wrap build with Watch**

Wrap `build` or dynamic subtrees in `Watch` so signals trigger rebuilds.

- [ ] **Step 5: Align error handling**

Compare to dsm_helper behavior (toasts/messages/branches) and adjust to match.

---

### Task 4: Verification and commit

**Files:**
- Modify: `lib/pages/docker/docker.dart`
- Modify: `lib/pages/docker/detail.dart`
- Modify: `lib/pages/storage_manager/storage_manager.dart`
- Modify: `lib/pages/storage_manager/smart.dart`
- Modify: `lib/widgets/**` (if shared widgets moved)

- [ ] **Step 1: Run verification search**

Run: `rg -n "setState\\(" lib/pages/docker lib/pages/storage_manager`
Expected: only UI-only `setState` remain (commented as such)

- [ ] **Step 2: Commit**

```bash
git add lib/pages/docker lib/pages/storage_manager lib/widgets

git commit -m "feat: align docker and storage pages to signals"
```

---

## Open Questions
- Confirm the authoritative common widgets path in dsm_helper (and whether any additional shared widgets should move).
