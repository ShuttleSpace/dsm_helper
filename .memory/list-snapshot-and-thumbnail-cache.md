---
name: list-snapshot-and-thumbnail-cache
description: Photos/文件 tab 的列表快照缓存（stale-while-revalidate）与缩略图磁盘缓存怎么做、为什么这么切 key
type: project
---

列表先显示快照再后台刷新：`lib/util/list_cache.dart` 的 `ListCache` 是内存 Map + 磁盘 JSON（`getApplicationSupportDirectory()/list_cache/<hash>.json`，文件内带 `k`/`t`/`v`，哈希撞车或超过 `maxAge=7天` 都当未命中）。调用方模式固定为：`await ListCache.read(key)` 命中就先填 signal、`loading=false`，随后照旧请求网络，成功后 `unawaited(ListCache.write(key, json))` 并覆盖，失败则保留快照（不要清空已显示的列表）。已接入：`lib/pages/photos/timeline.dart`（key `photos|timeline|$isTeam|$type|$geocodingId|$generalTagId|$recentlyAdd`）、`lib/pages/photos/album_tab.dart`（`photos|albums|$isTeam`）、`lib/pages/file/file.dart`（`files|$path|$sortBy|$sortDirection` 与 `files|@shares`）。

**Why:** 打开 Photos 的白屏几乎全在一次 `SYNO.Foto.Browse.Timeline.get` 上——无分页、一次拉整库、且 `timeline_model.dart` 原来把整个响应 `Log.log` 一遍（logger 会同时写轮转文件 + `debugPrint`，等于两次整库 JSON 串化 + 落盘），那行已删。缩略图慢的原因不是没有磁盘缓存，而是 `ExtendedImage.network` 的默认 key 是整条 URL 的 md5，URL 里 `_sid` 每次登录都变 → 磁盘缓存永远未命中；`cacheRawData` 在 io 路径下其实不起作用，真正要的是自定义 `cacheKey`。key 隔离用 `baseUri + account` 前缀，所以换 NAS/换账号不会读到别人的快照，登出无需清理（内存 Map 条目很少）。

**How to apply:** 新增列表缓存时直接复用 `ListCache`，`key` 必须带上区分维度和账号前缀（前缀由 `ListCache` 自己加）；模型必须能 `toJson`/`fromJson` 往返（`TimelineModel`、`AlbumModel` 都已验证）。缩略图缓存 key 用 `lib/widgets/cupertino_image.dart` 的 `thumbnailCacheKey(url)`，它剔掉 `_sid` 再 md5；`cacheMaxAge: 30天` 与 `lib/main.dart` 启动时的 `clearDiskCachedImages(duration: 30天)` 对齐。测试：`test/util/list_cache_test.dart`（用 `ListCache.rootForTest` 指到临时目录）、`test/widgets/thumbnail_cache_key_test.dart`。注意 `connectionStore.baseUri/account` 是 `ReadonlySignal`，测试里要调用 `setBaseUri`/`setAccount`。

**Related:** `lib/util/list_cache.dart`, `lib/widgets/cupertino_image.dart`, `lib/models/photos/timeline_model.dart`, [[tmdb-scraping-cache-attribution]]
