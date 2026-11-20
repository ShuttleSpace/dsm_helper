# Signals UI Alignment Design

Date: 2026-03-26

## Goal
Align remaining **signals-integrated pages** to match `dsm_helper` UI structure, layout, naming, and component splitting, while **preserving existing signals state management** and required `baseUri` differences.

## Scope
Pages that currently differ from `dsm_helper` but already use signals. Examples include:
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
- `lib/pages/moments/*` (if signals-integrated)
- `lib/pages/file/file.dart` (if signals-integrated)

Non-signals pages already matched to `dsm_helper` are out of scope.

## Non-Goals
- Replacing signals with setState or provider.
- Refactoring logic or behavior beyond what is necessary for UI/structure alignment.
- Changing data flow, error handling, or API interactions.

## Approach
1. **Use `dsm_helper` as the UI source of truth** for layout, widget hierarchy, spacing, and component composition.
2. **Preserve signals logic** and keep existing reactive state usage.
3. **Allow `baseUri` deviations** where `dsm_helper` uses `baseUrl` (the current project’s `connectionStore` exposes `baseUri`).
4. **Do not alter behavior** unless a layout/structure mismatch requires it.

## Alignment Rules
- Keep file structure, naming, and component splitting consistent with `dsm_helper`.
- Replace only UI/structure differences: widget order, container/spacing, styling, icons, and card shapes.
- Keep all signals state holders intact; any UI state updates remain in signals or UI-only setState if already justified.
- Ensure any `baseUrl` references are translated to `baseUri` only when required.

## Risk & Mitigations
- **Risk**: UI changes inadvertently affect behavior.
  - **Mitigation**: only touch widget structure/layout; avoid logic edits unless required to align hierarchy.

## Verification
- No test changes. Visual/manual review only.
- Avoid running `flutter analyze` per user request.

## Deliverables
- Pages listed above aligned to `dsm_helper` UI structure.
- Retain signals state management and `baseUri` differences.
