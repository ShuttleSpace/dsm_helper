---
name: video-player-portrait-controls-and-foto-thumbnail
description: Why the player's 22px RenderFlex overflow only happens on portrait videos opened from Synology Photos, and how the thumbnail id=null crash was fixed
type: project
---

`lib/pages/common/video_player.dart` puts `MaterialPlayOrPauseButton(iconSize: 56)` plus up to three 34px `_overlayButton`s in `MaterialVideoControlsThemeData.primaryButtonBar`. The video area is `ConstrainedBox(maxHeight: screen.height * 0.3)` around `AspectRatio`, so a 9:16 video at 360×800 is only 135px wide while the standard bar needs 158px — exactly the reported "overflowed by 22 pixels". `lib/widgets/video_player_controls_layout.dart` holds `playerSurfaceWidth` / `controlBarMinWidth` / `needsCompactControls`; when compact, skip prev/next/playlist move to `bottomButtonBar` and fullscreen is kept there.

**Why:** the overflow is intermittent because it only appears for portrait videos; landscape and file/media-library videos at full width never hit the 135px constraint. The Photos path also produced `…api="SYNO.Foto.Thumbnail"&id=null&cache_key="null"`: `lib/models/photos/photo_model.dart:thumbUrl()` assumed `additional.thumbnail.unit_id` always exists, but video items can lack it. `thumbUrl()` now falls back to the item `id` and omits `cache_key` when absent; `additional!` no longer throws. The player's poster image uses the same `_sid`-free `keyToMd5` cache key as `lib/widgets/cupertino_image.dart`, and `TMDB 未查到` logs `currentName` instead of the constructor `name` (null from Photos).

**How to apply:** when touching the control bar, keep the width helpers in one file and the compact branch in both `normal` and `fullscreen` themes; do not re-add all buttons to a portrait-width surface. `MediaKit.ensureInitialized()` fails under flutter_test on macOS (`Cannot find Mpv.framework/Mpv`), so full-page widget tests are not possible — test the pure layout helpers instead (`test/widgets/video_player_layout_test.dart`, `test/models/photo_model_thumbnail_test.dart`).

**Related:** `lib/pages/common/video_player.dart`, `lib/models/photos/photo_model.dart`, `lib/widgets/cupertino_image.dart`, [[list-snapshot-and-thumbnail-cache]], [[tmdb-scraping-cache-attribution]]
