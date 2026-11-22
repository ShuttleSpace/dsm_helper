---
name: download-tab-badge-layout
description: Why the transfer page TabBar must be scrollable/center-aligned when tabs carry count badges
type: project
---

`lib/pages/download/download.dart` builds 5 tabs; 下载/上传 tabs may add a count badge via `tabLabel(label, count)` (a `Row` with text + gap + padded `Container`). A default non-scrollable `TabBar` gives each tab `width / 5` minus `kTabLabelPadding` (16px per side), so the badge row overflows on narrow screens: at 360px logical width with one badge the overflow was 12px, at ~420px it was 0.655px, at 320px it was 20px (and worse for 2–3 digit counts). The fix is `isScrollable: true, tabAlignment: TabAlignment.center` on the `TabBar`, so tabs size to their content and scroll when needed.

**Why:** a one-line `labelPadding` reduction only moved the threshold; it still overflowed with 10+ tasks at 320–360px. Scrollable tabs remove the tight per-tab constraint for every count, while `TabAlignment.center` keeps the cluster centered on wide screens.

**How to apply:** when changing tab labels, badges, or `TabBar` settings here, re-run `flutter test test/widgets/download_tab_layout_test.dart` (pumps at 360px with 12 download tasks and fails on any RenderFlex overflow). Do not reintroduce a fixed-width/expand tab layout with badges.

**Related:** [[signals-hooks-watch-scope]]
