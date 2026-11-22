---
name: application-tile-marquee-constraints
description: Why the drawer's title marquee must measure with MediaQuery.textScaler and only mount a ticker on overflow
type: project
---

`lib/widgets/application_tile.dart` renders drawer titles through a private `_MarqueeText` (measure-only `StatelessWidget`, `TextPainter` + `LayoutBuilder`) that returns a plain ellipsized `Text` when `overflow <= 1` and otherwise mounts `_ScrollingText` (the only owner of `useSingleTickerProvider()` + `AnimationController(4s)` + `ClipRect`/`AnimatedBuilder`/`Transform.translate`).

**Why:** two defects were caught only by whole-branch review. (1) The `TextPainter` defaults to `TextScaler.noScaling` while `Text` renders with `MediaQuery.textScalerOf(context)`, so with large accessibility text a truncated title measured as fitting and never moved — the "marquee only when truncated" contract silently broke. (2) A controller created unconditionally in `_MarqueeText` kept a live `Ticker` per tile (up to 13 in the drawer) even for short static labels, burning frames while the drawer was open.

**How to apply:** when touching marquee/title code, keep `textScaler: MediaQuery.textScalerOf(context)` on the `TextPainter` (letter/word-spacing overrides are still not mirrored — known, deliberate) and keep all hook/animation state inside `_ScrollingText` so short labels never mount a controller. Grid columns are `(constraints.maxWidth - 2 * tileGap) / 3` with `tileGap = 12` in `lib/pages/dashborad/applications.dart`; `final tiles = _buildApplicationList(context);` must stay inside `Watch` (see [[signals-hooks-watch-scope]]).

**Test gotchas (Flutter 3.50):** `TestFlutterView` has no `size` getter — use `tester.view.physicalSize.width / tester.view.devicePixelRatio`; `isGreaterThan` needs `package:checks`; `find.byType(Transform)` also matches Material/Card internals, so scope it with `find.descendant(of: find.byType(ClipRect), ...)`.

**Related:** `lib/widgets/application_tile.dart`, `lib/pages/dashborad/applications.dart`, `test/widgets/application_tile_test.dart`, `test/pages/application_list_layout_test.dart`, [[signals-hooks-watch-scope]]
