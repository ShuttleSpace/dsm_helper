# Application Drawer Layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Shrink the application drawer tiles and add a one-tap list/grid switch while keeping the existing Drawer edge swipe and navigation intact.

**Architecture:** `ApplicationList` stays the drawer body and owns a local `useGridLayout` signal plus the toggle button; `ApplicationTile` gains a `listLayout` mode and a 36px icon. The 13 existing per-app switch cases remain unchanged — grid wraps the tiles in 88px boxes, list copies each tile with `listLayout: true` into a full-width column.

**Tech Stack:** Flutter / Dart, `flutter_hooks`, `signals_hooks`, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-11-21-application-drawer-layout-design.md`

## Global Constraints

- Icon is exactly **36×36** in both layouts; grid `Wrap` spacing and runSpacing are exactly **12**.
- Grid tile width is exactly **88**; list tiles are full width (`double.infinity`).
- Toggle uses `Tooltip(message: '点击切换布局')` with `Icons.grid_view_outlined` when grid is active and `Icons.view_list_outlined` otherwise, matching `lib/pages/packages/packages.dart:441-451`.
- Default mode is grid; state is a local `useSignal(true)` and is **not** persisted.
- Do not touch `lib/pages/dashborad/dashboard.dart`, `drawerEdgeDragWidth`, or the `Scaffold.drawer` wiring. No new dependencies.

## Review Focus

- **Drawer edge swipe must survive** — Task 2 verification step asserts `Scaffold.drawer` wiring is unchanged and no `drawerEdgeDragWidth` override exists.
- **Badge must show in both layouts** — Task 1 list test asserts the badge widget is present with `listLayout: true`; grid test keeps the existing badge position.
- **Long labels such as "Virtual Machine Manager" must not overflow** — Task 1 list test uses a long label in a bounded 320px width and asserts a clean `pumpAndSettle`.
- **Toggle must round-trip** — Task 2 test taps the toggle twice and asserts `Wrap` → no `Wrap` → `Wrap`.
- **All apps must appear in both modes** — Task 2 test feeds two app ids through `ApplicationList` and asserts two tiles exist after each toggle.

---

### Task 1: Compact and list-aware ApplicationTile

**Files:**
- Modify: `lib/widgets/application_tile.dart`
- Test: `test/widgets/application_tile_test.dart`

**Interfaces:**
- Consumes: existing `iconAsset`, `label`, `onTap`, `badge`, `centerContent` fields.
- Produces: `ApplicationTile({..., bool listLayout = false})`, icon size 36, and `ApplicationTile copyWith({bool? listLayout})` that preserves all other fields.

- [ ] **Step 1: Write the failing tests**

Add to `test/widgets/application_tile_test.dart`:
- `grid mode uses a 36px icon`: pump `ApplicationTile(iconAsset: 'assets/applications/docker.png', label: 'Docker', onTap: () {})`, assert one `Image` with `width == 36 && height == 36`, and assert `find.byType(Row)` finds nothing.
- `listLayout puts icon before label and keeps badge`: pump `ApplicationTile(..., label: 'Virtual Machine Manager', listLayout: true, badge: const Text('!'))` inside `SizedBox(width: 320, child: ...)`, assert a `Row`, the 36px `Image`, `find.text('Virtual Machine Manager')`, `find.text('!')`, and that `tester.pumpAndSettle()` completes without overflow.
Keep the existing tap test unchanged.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/widgets/application_tile_test.dart`
Expected: FAIL because `listLayout` is not defined and the icon is 45px.

- [ ] **Step 3: Implement the tile**

In `lib/widgets/application_tile.dart`: add `final bool listLayout` with default `false`; change `Image.asset` to `height: 36, width: 36`; when `listLayout` is true replace the centered `Column` with `Row(children: [Image.asset(...), SizedBox(width: 12), Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis))])`; keep the `Stack` + `Positioned` badge, moving it to `right: 12` in list mode. Add `copyWith({bool? listLayout})` per the Interfaces block.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/widgets/application_tile_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/application_tile.dart test/widgets/application_tile_test.dart
git commit -m "feat(drawer): add compact list layout to application tile"
```

---

### Task 2: Toggle list/grid in ApplicationList

**Files:**
- Modify: `lib/pages/dashborad/applications.dart` (header/imports at lines 1-52)
- Create: `test/pages/application_list_layout_test.dart`

**Interfaces:**
- Consumes: `ApplicationTile.copyWith({bool? listLayout})` and the 36px icon from Task 1.
- Produces: `ApplicationList` remains constructible with the same five positional `ReadonlySignal` arguments and renders a toggle with tooltip `'点击切换布局'`.

- [ ] **Step 1: Write the failing test**

Create `test/pages/application_list_layout_test.dart`: pump `MaterialApp(home: Scaffold(body: ApplicationList(signal<List>(['SYNO.SDS.Docker.Application']), signal<Map>({}), signal<List>([]), signal<List>([]), signal<Map>({}))))` (imports from `package:signals_flutter/signals_flutter.dart`). Assert `find.byType(Wrap)` finds one widget and two `ApplicationTile`s are not yet expected. Tap `find.byTooltip('点击切换布局')`, pump, assert no `Wrap` and at least one `Row` from the tile. Tap again, pump, assert `Wrap` returns. Assert exactly one tile in each mode.

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/pages/application_list_layout_test.dart`
Expected: FAIL because no tooltip exists.

- [ ] **Step 3: Implement the toggle and layouts**

In `lib/pages/dashborad/applications.dart`: import `package:flutter_hooks/flutter_hooks.dart` and `package:signals_hooks/signals_hooks.dart`; change `ApplicationList extends StatelessWidget` to `extends HookWidget`; add `final useGridLayout = useSignal(true)`. Inside the existing `ListView` children, insert a `Row(mainAxisAlignment: MainAxisAlignment.end, children: [Tooltip(message: '点击切换布局', child: IconButton(onPressed: () => useGridLayout.value = !useGridLayout.value, icon: useGridLayout.value ? const Icon(Icons.grid_view_outlined) : const Icon(Icons.view_list_outlined)))])` above the app list. Change `_buildApplicationList` to return `List<ApplicationTile>` and, in `build`, map it to `SizedBox(width: 88, child: tile)` when grid is active, otherwise `SizedBox(width: double.infinity, child: tile.copyWith(listLayout: true))`; use `Wrap(spacing: 12, runSpacing: 12, ...)` for grid and `Column(...)` for list.

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/pages/application_list_layout_test.dart`
Expected: PASS.

- [ ] **Step 5: Verify scope and full check**

Run: `grep -n 'drawer: desktopAppViewOrder' lib/pages/dashborad/dashboard.dart && ! grep -rq 'drawerEdgeDragWidth' lib && flutter analyze && flutter test test/widgets/application_tile_test.dart test/pages/application_list_layout_test.dart`
Expected: drawer line still present, no drag-width override, analyzer clean, all four widget tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/pages/dashborad/applications.dart test/pages/application_list_layout_test.dart
git commit -m "feat(drawer): switch application list between grid and list"
```
