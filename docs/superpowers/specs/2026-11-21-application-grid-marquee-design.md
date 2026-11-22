# Application grid: three columns + marquee title

Date: 2026-11-21

## Intent

User asked: "grid布局可以一行3列。title跑马灯". The application drawer's grid should fit three tiles per row, and an application name that is too long for its tile should scroll horizontally so the full name is readable. User chose: marquee starts **only when the title is actually truncated**, in both grid and list layouts.

## Goals

- Grid is exactly 3 columns, with tile width derived from the drawer width so it works on phone and tablet.
- Long labels (e.g. `Virtual Machine Manager`, `存储空间管理员`) marquee; short labels (`Docker`, `迅雷`) stay still.
- Keep the existing `Watch` signal subscriptions, the 13 app switch cases, and the drawer gesture unchanged.

## Non-goals / anti-goals

- No change to drawer opening/dragging, app routing, badges, or layout persistence.
- No new dependency; no `GridView` rewrite of the app list.
- All titles scrolling permanently is explicitly rejected (noisy).

## Constraints

- `ApplicationList` is a `HookWidget`; `_buildApplicationList(context)` must stay inside the `Watch` closure or `applications.value` / `appNotify[...]['unread']` stop rebuilding tiles.
- `Wrap` spacing and run spacing stay `12`; list tiles stay `double.infinity`.
- 36px icon, 12px icon/label gap, and badge positions stay as they are.
- The working tree contains unrelated uncommitted changes (`lib/pages/common/video_player.dart`, subtitle picker, etc.); commit only files from this task.

## Approaches considered

1. **`LayoutBuilder` + keep `Wrap` (chosen).** Compute `tileWidth = (constraints.maxWidth - 2 * 12) / 3` and put each tile in a `SizedBox(width: tileWidth)`. Smallest diff; preserves the reactive `Watch` builder and the list-mode branch.
2. **`GridView.count`**. Would replace the `Wrap`, complicate the existing list/grid toggle inside `ListView`, and risk moving signal reads out of `Watch`. More churn for the same result.
3. **Fixed pixel width for 3 columns**. Simple but wrong whenever the drawer width changes (phone vs tablet); rejected.

For the title:

1. **Measure with `TextPainter`, animate only overflow (chosen).** A private `_MarqueeText` returns a plain `Text` when the label fits; otherwise a clipping animated translate. Meets "only when truncated" without hard-coded name lengths.
2. **Always animate every label.** Cheaper but rejected by the user's choice.
3. **Ellipsis + tooltip.** No animation; does not satisfy "跑马灯".

## Design

### `lib/pages/dashborad/applications.dart`

- Wrap the `useGridLayout.value ? Wrap : Column` expression in a `LayoutBuilder`.
- Define `const tileGap = 12.0`; use it for both `Wrap` spacings and for `tileWidth`.
- Grid branch: `SizedBox(width: (constraints.maxWidth - 2 * tileGap) / 3, child: tile)`.
- List branch: unchanged `SizedBox(width: double.infinity, child: tile.copyWith(listLayout: true))`.
- Keep `final tiles = _buildApplicationList(context);` inside `Watch`.

### `lib/widgets/application_tile.dart`

- Add a private `_MarqueeText extends HookWidget` used for the label in both grid and list modes.
- Measure the label once with `TextPainter` using inherited `DefaultTextStyle`, `Directionality.of(context)` and `maxLines: 1`; if `painter.width <= constraints.maxWidth`, render the existing `Text` unchanged (`maxLines: 1`, `TextOverflow.ellipsis`, centered in grid).
- If it overflows, render `ClipRect` → `AnimatedBuilder` → `Transform.translate(offset: Offset(-progress * overflow, 0))`, with a `useSingleTickerProvider()` + hook-created `AnimationController` (~4s, `repeat(reverse: true)`, disposed by hooks). The text keeps `maxLines: 1`, `softWrap: false`.
- Do not change the 36px icon, 12px gap, `copyWith`, badge placement, or `onTap`.

### Tests

- `test/pages/application_list_layout_test.dart`: keep the toggle and reactivity tests; assert the grid `SizedBox` widths are equal and computed from available width with two 12px gaps (not a fixed 88px), and that switching back to grid preserves that width.
- `test/widgets/application_tile_test.dart`: short label renders plain `Text` with no translate; long label in a narrow box renders a `Transform` that moves after `pump(duration: ...)`; tap still fires. Replace `pumpAndSettle()` with bounded `pump()` calls where a repeating animation would otherwise never settle.

## Builder discretion

- Exact animation duration/pause curve is the builder's call; ~4s with a brief pause at each end is the expectation.
- If `TextPainter` measurement needs a small epsilon to avoid a one-pixel false positive, use `<= constraints.maxWidth + 1`.
