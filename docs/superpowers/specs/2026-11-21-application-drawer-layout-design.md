# Application drawer: smaller items + list/grid toggle

## Intent

The left application panel is a real `Scaffold.drawer` (`lib/pages/dashborad/dashboard.dart:327`), so edge-swipe already works; no drawer gesture change is needed. Make its app items smaller and let the user switch between grid and list presentation.

## Why

The current tile (`lib/widgets/application_tile.dart`) uses a 45×45 icon inside a `Wrap` with 20px gaps (`lib/pages/dashborad/applications.dart:36-45`); on a phone only a handful of the 13 apps fit. A denser grid plus a list alternative shows more apps without changing navigation.

## Goals

- Grid mode keeps the current look but with a smaller icon (36×36) and tighter spacing (~12px).
- List mode renders one app per row: icon left, label right, badge preserved.
- A toggle in the drawer switches the two modes with one tap.
- Existing `Navigator.pop()` + `CupertinoPageRoute` behavior and badges stay identical.

## Non-goals

- No change to drawer gesture, width, or `dashboardDrawerOpen` synchronization.
- No persistence of the chosen mode across app restarts.
- No change to `Dashboard` shortcuts/widgets, or to the packages-center toggle.

## Constraints / calls made

- Reuse the layout-toggle pattern from `lib/pages/packages/packages.dart:441-451` (`Tooltip` + `IconButton` with `Icons.grid_view_outlined` / `Icons.view_list_outlined`) so the interaction matches the rest of the app.
- Toggle state is a local signal, not `SettingsStore`/`StorageUtil`; this matches the packages center. The user approved the proposal without asking for persistence, so this is the builder's call.
- Exact icon/spacing values are the builder's call; the user agreed to “小一点” without naming a target size or answering the screen-size question, so use 36px / 12px as proposed.

## Approaches

1. **Local signal + adaptive tile (chosen).** `ApplicationList` becomes a `HookWidget`, holds a `useSignal` for the mode, wraps tiles in a fixed-width `Wrap` for grid or a full-width `Column` for list, and extends `ApplicationTile` so it renders a compact column in narrow constraints and a row in wide ones. Keeps all 13 app switch cases untouched; touches only `applications.dart` and `application_tile.dart`.
2. **Persist mode in `SettingsStore`.** Adds a field, `StorageUtil` read/write and `initialize()` wiring. Rejected: more surface area for a preference nobody asked to keep.
3. **Turn the drawer into a full-screen page.** Would give room for a proper AppBar and search, but changes the Drawer gesture/navigation contract the user explicitly asked about. Rejected as out of scope.

## What's left to the builder

- Replace the 45px icon with 36px in the tile; keep badge positioning working in both layouts.
- Add the toggle above the app list inside the drawer's `ListView` and verify both modes with `flutter analyze` / a simulator screenshot.
