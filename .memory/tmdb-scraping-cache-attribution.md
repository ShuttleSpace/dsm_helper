---
name: tmdb-scraping-cache-attribution
description: How the player fills missing video metadata from TMDB, where the cache lives, and the attribution requirement
type: project
---

`lib/util/tmdb_util.dart` 是播放页的 TMDB 刮削薄层：`guessTitleFromFileName`（去扩展名 + 正则 `(?:^|\D)((?:19|20)\d{2})(?!\d)` 截年份，`1917.mkv` 特判不截断）→ `/3/search/multi` → `pickSearchHit`（只认 movie/tv，年份优先）→ `/3/{movie|tv}/{id}` → `parseTmdbDetail` → `TmdbInfo`（字段刻意与 NFO 对齐，播放页同一套展示）。

**Why:** 本 app 已有 NAS 上的 NFO 解析（`parseNfo`），只缺简介/类型/评分；引入完整刮削引擎（Jellyfin/Kodi）会带 GPL 与整套媒体库模型，不划算。TMDB 免费但**非商用 + 必须署名**，所以播放页显示 TMDB 数据时有一行 "部分数据来自 TMDB"（`video_player.dart` 的 `tmdbUsed` signal），设置页也有完整署名文案。豆瓣 `/v2/movie/in_theaters` 无授权 key 返回 403 `invalid_apikey`，不能当数据源。

**How to apply:** 只填空白字段、不覆盖 NFO；无 key 或无简介时直接跳过。查询结果缓存在 `getApplicationSupportDirectory()/tmdb_cache.json`，键是文件名，30 天过期（`tmdbCacheTtl`），最多 200 条按 ts 淘汰最旧（`tmdbCacheLimit`）；读写都 try/catch，缓存坏掉只当未命中。`lib/util/http_util.dart` 的 `HttpUtil.get` 绑 DSM cookie/origin，查第三方 API 不能复用它，必须直接 `Dio`。

**Related:** `lib/pages/common/video_player.dart`, `lib/pages/setting/player_setting.dart`（TMDB Key + 字幕字号 + 第三方播放器开关）, [[signals-hooks-watch-scope]]