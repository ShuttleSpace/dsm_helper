---
name: signals-hooks-watch-scope
description: In dsm_helper, keep signal reads for ApplicationList tiles inside the Watch closure or badges/apps stop updating
type: project
---

`ApplicationList` in `lib/pages/dashborad/applications.dart` is a `HookWidget`: local toggle state comes from `useSignal(true)` while app/badge data is read via `applications.value` and `appNotify[...]['unread']` inside a `Watch` builder. The tile builder must be called INSIDE the `Watch` closure. `HookWidget.build` is not reactive by itself; calling `_buildApplicationList(context)` outside `Watch` drops the subscriptions, so badge changes (e.g. after `onEjectSuccess: fetchWidgetModuleList`) no longer rebuild tiles.

**Why:** a list/grid toggle refactor moved tile construction to `build` and silently broke reactivity; regression test `ApplicationList rebuilds tiles when applications change` in `test/pages/application_list_layout_test.dart` now pins it. Keeping the call inside `Watch` preserves both rebuild paths without persisting toggle state.

**How to apply:** when editing `ApplicationList` or similar `HookWidget` + `Watch` widgets in this repo, keep all `.value` reads for rendered content inside the `Watch` builder; keep only pure layout wrapping in `build`. Verify with `flutter test test/pages/application_list_layout_test.dart`.

**Related:** [[auto-backup-cold-start]]
