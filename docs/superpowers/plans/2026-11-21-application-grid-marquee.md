# Application grid three-column marquee Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the application drawer grid fit three tiles per row and marquee only titles that are actually truncated.

**Architecture:** `ApplicationList` stays a `HookWidget`; a `LayoutBuilder` replaces the fixed 88px grid width with a width derived from drawer constraints. `ApplicationTile` keeps its geometry and delegates its label to a private `_MarqueeText` that measures with `TextPainter` and animates only on overflow.

**Tech Stack:** Flutter 3.50, Dart, `flutter_hooks` 0.21.3+1, `signals_hooks` 0.4.0, `flutter_test`. No new dependency.

**Spec:** `docs/superpowers/specs/2026-11-21-application-grid-marquee-design.md`

## Global Constraints

- The marquee starts **only when the title is actually truncated**; short titles stay still. In grid mode `TextAlign.center`, in list mode left-aligned.
- Grid is exactly **3 columns**; `Wrap.spacing` and `Wrap.runSpacing` stay **12**; grid tile width is `(constraints.maxWidth - 2 * 12) / 3`.
- Keep `final tiles = _buildApplicationList(context);` **inside the `Watch` closure** in `lib/pages/dashborad/applications.dart`; it subscribes to `applications.value` and `appNotify`.
- Keep list layout width `double.infinity`; keep 36px icon, 12px icon/label gap, and badge positions unchanged.
- Do not change drawer opening/dragging, the 13 app switch cases, `copyWith`, or add dependencies.
- Use bounded `pump()` / `pump(duration:)` in tests around the repeating animation; never `pumpAndSettle()` on a marquee tile.

## Review Focus

- Long label in a narrow grid tile must marquee rather than stay ellipsized — Task 1 long-label test.
- Short label must render a plain `Text` (no `ClipRect` / `Transform`) and still respond to tap — Task 1 short-label test plus existing tap test.
- Long label in list mode must marquee inside `Expanded` without causing a `RenderFlex` overflow — Task 1 list-layout test with `takeException()`.
- Drawer width change (phone vs tablet) must still give three equal columns with two 12px gaps — Task 2 width test at two view sizes.
- Signal updates while a marquee is active must still rebuild tiles — Task 2 existing `applications.value` reactivity test, kept green.

---

### Task 1: Marquee only truncated titles

**Files:**
- Modify: `lib/widgets/application_tile.dart`
- Test: `test/widgets/application_tile_test.dart`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `ApplicationTile` still has `copyWith({bool? listLayout})` and the same constructor; its label now uses a private `_MarqueeText` whose behavior is covered by the tests below. No public API changes.

- [ ] **Step 1: Write the failing tests**

Add to `test/widgets/application_tile_test.dart`:

```dart
testWidgets('short label does not marquee', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 120,
        child: ApplicationTile(
          iconAsset: 'assets/applications/docker.png',
          label: 'Docker',
          onTap: () {},
        ),
      ),
    ),
  ));

  expect(find.text('Docker'), findsOneWidget);
  expect(find.byType(ClipRect), findsNothing);
  expect(find.byType(Transform), findsNothing);
});

testWidgets('long label marquees in a narrow grid tile', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 88,
        child: ApplicationTile(
          iconAsset: 'assets/applications/docker.png',
          label: 'Virtual Machine Manager with a very long title',
          onTap: () {},
        ),
      ),
    ),
  ));

  expect(find.byType(ClipRect), findsOneWidget);
  final before = tester.widget<Transform>(find.byType(Transform));
  await tester.pump(const Duration(milliseconds: 500));
  final after = tester.widget<Transform>(find.byType(Transform));
  expect(before.transform, isNot(after.transform));
});

testWidgets('long label marquees in list mode without overflow', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 200,
        child: ApplicationTile(
          iconAsset: 'assets/applications/docker.png',
          label: 'Virtual Machine Manager with a very long title',
          onTap: () {},
          listLayout: true,
        ),
      ),
    ),
  ));

  expect(find.byType(ClipRect), findsOneWidget);
  await tester.pump(const Duration(milliseconds: 500));
  expect(tester.takeException(), isNull);
});
```

Also change the existing `listLayout puts icon before label and keeps badge` test's final `await tester.pumpAndSettle();` to `await tester.pump(const Duration(milliseconds: 100));`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/widgets/application_tile_test.dart`
Expected: FAIL — the two new long-label tests find no `ClipRect`, and the short-label test may pass or fail depending on tree internals; the test file as a whole must be red.

- [ ] **Step 3: Implement the marquee label**

In `lib/widgets/application_tile.dart`, add `package:flutter_hooks/flutter_hooks.dart` and a private `class _MarqueeText extends HookWidget` with constructor `_MarqueeText({super.key, required this.label, required this.textAlign})`, fields `final String label; final TextAlign textAlign;`.

Its implementation must:
- create one `AnimationController(vsync: useSingleTickerProvider(), duration: const Duration(seconds: 4))` via `useMemoized`, dispose it via `useEffect`, and call `repeat(reverse: true)`;
- in `build`, return a `LayoutBuilder` that measures `label` once with `TextPainter(text: TextSpan(text: label, style: DefaultTextStyle.of(context).style), textDirection: Directionality.of(context), maxLines: 1)..layout()` and computes `overflow = painter.width - constraints.maxWidth`;
- if `overflow <= 1`, return the existing `Text(label, maxLines: 1, textAlign: textAlign, overflow: TextOverflow.ellipsis)` unchanged;
- otherwise return `ClipRect(child: AnimatedBuilder(animation: controller, builder: (context, child) => Transform.translate(offset: Offset(-controller.value * overflow, 0), child: child), child: Text(label, maxLines: 1, softWrap: false)))`.

Replace the two `Text(label, ...)` label widgets in `ApplicationTile.build` with `_MarqueeText`: grid uses `textAlign: TextAlign.center`; list mode uses the default left alignment. Keep the surrounding `Expanded`, 12px gap, 36px icon, and `Positioned` badge exactly as they are.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/widgets/application_tile_test.dart`
Expected: PASS, 6/6 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/application_tile.dart test/widgets/application_tile_test.dart
git commit -m "feat(drawer): marquee titles that overflow"
```

---

### Task 2: Three columns derived from drawer width

**Files:**
- Modify: `lib/pages/dashborad/applications.dart`
- Test: `test/pages/application_list_layout_test.dart`

**Interfaces:**
- Consumes: `ApplicationTile` from Task 1 (unchanged public constructor and `copyWith`).
- Produces: `ApplicationList` still takes the same five signals; grid children are `SizedBox(width: tileWidth)` with `tileWidth = (constraints.maxWidth - 2 * tileGap) / 3`.

- [ ] **Step 1: Write the failing test**

Add to `test/pages/application_list_layout_test.dart` (import `package:garden/constants/app_constants.dart`):

```dart
testWidgets('grid uses three equal columns at phone and tablet widths', (tester) async {
  Future<void> expectThreeColumns() async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ApplicationList(
          signal<List>([
            'SYNO.SDS.Docker.Application',
            'SYNO.SDS.XLPan.Application',
            'SYNO.Photo.AppInstance',
            'SYNO.Foto.AppInstance',
          ]),
          signal<Map>({}),
          signal<List>([]),
          signal<List>([]),
          signal<Map>({}),
        ),
      ),
    ));
    await tester.pump();

    final expectedWidth =
        (tester.view.size.width * 0.8 - 2 * AppConstants.paddingLarge - 24) / 3;
    expect(
      find.byWidgetPredicate(
          (widget) => widget is SizedBox && widget.width == expectedWidth),
      findsNWidgets(4),
    );
    final tiles = find.byType(ApplicationTile);
    expect(tester.getRect(tiles.at(0)).top, tester.getRect(tiles.at(2)).top);
    expect(tester.getRect(tiles.at(3)).top, isGreaterThan(tester.getRect(tiles.at(0)).top));
  }

  await expectThreeColumns();

  tester.view.physicalSize = const Size(1200, 800);
  addTearDown(() => tester.view.resetPhysicalSize());
  await expectThreeColumns();
});
```

Also replace both occurrences of `widget.width == 88` in the existing toggle test with `widget.width == (tester.view.size.width * 0.8 - 2 * AppConstants.paddingLarge - 24) / 3`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/pages/application_list_layout_test.dart`
Expected: FAIL — new test finds no `SizedBox` with the computed width (current width is 88), and the toggle test's width assertions fail.

- [ ] **Step 3: Implement the width calculation**

In `lib/pages/dashborad/applications.dart`, wrap the `useGridLayout.value ? Wrap(...) : Column(...)` expression in a `LayoutBuilder`. Define `const tileGap = 12.0` inside `build` and use it for `Wrap.spacing`, `Wrap.runSpacing`, and the grid `SizedBox(width: (constraints.maxWidth - 2 * tileGap) / 3)`. Leave the `Column` list branch (`width: double.infinity`) untouched and keep `final tiles = _buildApplicationList(context);` inside `Watch`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/pages/application_list_layout_test.dart test/widgets/application_tile_test.dart`
Expected: PASS, 9/9 tests (3 list-layout + 6 tile tests).

- [ ] **Step 5: Full verification and commit**

Run:

```bash
flutter test
flutter analyze lib/pages/dashborad/applications.dart lib/widgets/application_tile.dart test/pages/application_list_layout_test.dart test/widgets/application_tile_test.dart
```

Expected: full suite green; analyzer shows no new errors in the four touched files (pre-existing `deprecated_member_use` infos are acceptable).

```bash
git add lib/pages/dashborad/applications.dart test/pages/application_list_layout_test.dart
git commit -m "feat(drawer): fit three application columns per row"
```
