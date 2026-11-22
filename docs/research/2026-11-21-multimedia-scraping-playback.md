# 多媒体刮削与播放：开源库 / 开源应用调研

日期：2026-11-21  
范围：为 `dsm_helper`（Flutter，目标 Android / iOS / macOS / Linux / Windows / Web）寻找「多媒体刮削」（把本地文件匹配成影片/剧集信息、海报、NFO、字幕）与「多媒体播放」的现成方案。  
结论基于一手来源：pub.dev 包页 / LICENSE、项目官方仓库与文档、官方 API 文档与现场 API 响应；每条判断都带来源链接。

---

## 0. 结论摘要（短名单）

| 优先级 | 方案 | 覆盖范围 | 许可与平台 | 适配成本 / 主要风险 | 建议 |
|---|---|---|---|---|---|
| 1 | **继续用 `media_kit` 做播放底座**，补外部字幕轨（`SubtitleTrack.uri` / `.data`）与可选文件元数据读取（`xue_hua_media_info`） | 播放 + 字幕 + 技术元数据 | `media_kit` MIT，Android/iOS/macOS/Windows/Linux/Web；`xue_hua_media_info` Apache-2.0，全平台（需 Flutter 3.44+） | 仓库已接入，改动最小；Web 播放依赖浏览器 `<video>`，格式支持「extremely limited」；libmpv 原生二进制需按 ABI 拆分 | **直接采用**。这是已有地基，不要重造播放器。 |
| 2 | **自建薄刮削层**：TMDB 搜索/详情 + 本地扫描/文件名解析 + 现有 `xml2json` 读写 NFO；可选 MIT 的 `tmdb_api_client` | 元数据、封面、NFO | TMDB API 免费但**非商用**且需署名；`tmdb_api_client` MIT；本地 NFO 解析已在本仓库存在 | 需自己写文件名解析、缓存、错误处理和 API key 管理；API key 不能硬编码；商用需向 TMDB 申请许可 | **主推刮削路线**。避开 GPL-3.0 的 `tmdb_api` 和受限数据源。 |
| 3 | **可选外部后端 / 桌面端生态**：Jellyfin HTTP API，或让 tinyMediaManager / MediaElch 生成 NFO 旁车文件 | 完整媒体库 / 批量刮削 | Jellyfin GPL-2.0（服务器端独立运行）；`jellyfin_dart` 客户端 MIT；tinyMediaManager Apache-2.0；MediaElch LGPL-3.0 | 要运行额外服务或桌面工具；只做 HTTP 对接或旁车文件互通，**不要把 GPL 引擎嵌进 Flutter 应用** | **作为进阶选项**，不阻塞 1/2。 |

一句话：**播放层不再选型，`media_kit` 已够用；刮削层自建 TMDB + NFO 薄层最稳；Jellyfin / tinyMediaManager / MediaElch 只做外部集成或参考，不内嵌 GPL 引擎。**

---

## 1. 本仓库现状（避免重复建设）

- `pubspec.yaml` 已声明 `media_kit: ^1.2.6`、`media_kit_video: ^2.0.1`、`media_kit_libs_video: ^1.0.7`；`just_audio`、`video_player` 只是注释。
- `lib/main.dart:26` 已 `import 'package:media_kit/media_kit.dart';`，`lib/main.dart:35` 已调用 `MediaKit.ensureInitialized();`。
- `lib/stores/settings_store.dart:8` 导入 `package:media_kit/media_kit.dart`，`:24` 持有 `final _player = signal<Player?>(null);`，`:32` 提供 `setPlayer(Player)`，`:296` 负责 `dispose()`。
- `lib/pages/common/video_player.dart:18` 已导入 `media_kit_video`，`:62` 调用 `await player.open(Media(url), play: true);`，`:166` 使用 `Video(controller: videoController)`；但未见 `setSubtitleTrack` 或字幕 UI。
- `lib/pages/common/video_player.dart:81` 附近已下载 NFO 并用 `xml2json: ^6.2.6` 的 `Xml2Json()` 解析 `json['episodedetails'] ?? json['movie']` 的 `plot/dateadded/actor/year` 字段——刮削的「本地 NFO 读取」已经有雏形。
- `lib/pages/common/audio_player.dart:32` 也用同一个 `Player.open(Media(url))` 播放音频。
- `docs/API_CAPTURE.md:9` 明确 Jellyfin / Emby 不是 `SYNO.*` API，第三方包需走它们自己的 HTTP API。

因此下文只讨论「还缺什么」：外部字幕、文件元数据、刮削数据源、平台/许可风险。

---

## 2. 播放方案对比

| 包 / 版本（2026-11-21） | 许可 | 平台 | 原生嵌入成本 | 对本项目的判断 |
|---|---|---|---|---|
| [`media_kit` 1.2.6](https://pub.dev/packages/media_kit) + [`media_kit_video` 2.0.1](https://pub.dev/packages/media_kit_video) + [`media_kit_libs_video` 1.0.7](https://pub.dev/packages/media_kit_libs_video) | MIT | Android 5+、iOS 9+、macOS 10.9+、Windows 7+、GNU/Linux、Web | 依赖预编译 libmpv：[Android v1.1.7 jar 每 ABI 约 5.2–6.2 MiB](https://github.com/media-kit/libmpv-android-video-build/releases/tag/v1.1.7)、[iOS v0.6.0 每 slice 约 6.2–6.4 MiB](https://github.com/media-kit/libmpv-darwin-build/releases/tag/v0.6.0)、[Windows 2023-09-24 dev 包约 8.4 MiB](https://github.com/media-kit/libmpv-win32-video-build/releases/tag/2023-09-24)（均为下载产物大小，非最终安装包）；README 建议 `--split-per-abi` / app bundle | **保留**。支持外置音轨/字幕轨 `SubtitleTrack.uri` / `SubtitleTrack.data`、字幕样式和 HTTP headers；Web 例外：README 原文「On the web, libmpv is not used... The format support depends upon the web browser. It happens to be extremely limited as compared to native platforms.」 |
| [`video_player` 2.14.1](https://pub.dev/packages/video_player) (+ [`chewie` 1.18.1](https://pub.dev/packages/chewie) UI) | BSD-3-Clause / MIT | Android、iOS、macOS、web（**无 Linux/Windows**） | 使用 AVPlayer / ExoPlayer 等系统播放器，不自带 FFmpeg；Web 仍由浏览器决定格式 | 可作局部降级方案，但平台覆盖不满足本项目；`chewie` 1.1.0+ 支持字幕覆盖，仍是 UI 包装而非刮削。 |
| [`flutter_vlc_player` 7.4.4](https://pub.dev/packages/flutter_vlc_player) | Dart 包装 BSD-3-Clause；原生 VLC 见 [GPLv2 COPYING](https://code.videolan.org/videolan/vlc/-/blob/master/COPYING) 与 [LGPLv2.1 COPYING.LIB](https://code.videolan.org/videolan/vlc/-/blob/master/COPYING.LIB) | **仅 Android / iOS** | 打包原生 VLC；需按 GPL/LGPL 合规审查 | 编解码能力强但平台缺口大、发布停留在 2025-09，不推荐作为主播放器。 |
| [`just_audio` 0.10.6](https://pub.dev/packages/just_audio) / [`audioplayers` 6.8.1](https://pub.dev/packages/audioplayers) | MIT | 前者 Android/iOS/macOS/web；后者 Android/iOS/Linux/macOS/web/Windows | 音频专用，无视频/字幕 | 只适合音频模式；本项目已用同一 `Player` 播放音频，无需引入。 |
| [`ffmpeg_kit_flutter_new` 5.0.0](https://pub.dev/packages/ffmpeg_kit_flutter_new) | 插件 LGPL-3.0；README 明示 full 版含 GPL-3.0 组件（x264/x265/xvidcore/vid.stab），「an application that uses it is distributed under GPL 3.0」 | Android/iOS/Linux/macOS/Windows（x86_64），**无 Web** | 构建/首次安装时下载预编译 FFmpeg 8.1.3 框架与库，体积和许可清单随变体变化 | 只在必须转码/Probe 时考虑；有 `min`/`https`/`converter`/`full` 等变体，但 full 版会把应用带入 GPL-3.0，且与现有 `media_kit` 播放职责重叠。 |
| [`xue_hua_media_info` 2.2.0](https://pub.dev/packages/xue_hua_media_info)（元数据，不是播放器） | Apache-2.0 | Android/iOS/Linux/macOS/Windows/Web | 原生插件，读取图片 EXIF 与音视频元数据；要求 Flutter 3.44+ | 可补「时长/编码/分辨率」等技术元数据；与 `media_kit` 播放不冲突，按需加。 |

**补字幕的最小动作**：`media_kit` README 已给出 `SubtitleTrack.uri` / `SubtitleTrack.data` 和字幕样式 API，可直接在现有 `Player` 上挂外置 SRT/WebVTT；解析/渲染还可参考 MIT 的 [`subtitle` 0.2.0](https://pub.dev/packages/subtitle)、[`flutter_subtitle` 0.0.6](https://pub.dev/packages/flutter_subtitle)、[`subtitle_toolkit` 0.0.2](https://pub.dev/packages/subtitle_toolkit)。

**许可补充**：mpv 默认 GPLv2-or-later，`-Dgpl=false` 时为 LGPLv2.1-or-later（[mpv README#license](https://github.com/mpv-player/mpv/blob/master/README.md#license)）；[media-kit/libmpv-darwin-build README](https://github.com/media-kit/libmpv-darwin-build/blob/main/README.md) 声称其二进制「compatible with commercial use for playback, and GPL use for encoding」。上架/商用前仍应让法务按实际链接与分发方式复核。

---

## 3. 刮削 / 元数据 Dart 包对比

| 类别 | 包 / 一手来源 | 维护与许可 | 适合度 |
|---|---|---|---|
| TMDB | [`tmdb_api_client` 1.0.0](https://pub.dev/packages/tmdb_api_client) | 2026-08-23，MIT，纯 Dart，覆盖 v3+v4 | **推荐候选**：无原生依赖、许可干净；1.0.0 较新、生态小，需 API key 自带。 |
| TMDB | [`remote_tmdb_kit` 3.0.0](https://pub.dev/packages/remote_tmdb_kit) | 2026-07-02，MIT，纯 Dart，typed `Result`、分页、可注入 HTTP 客户端 | 可替换候选；文档为西班牙语，团队阅读成本略高。 |
| TMDB | [`tmdb_api` 2.2.3](https://pub.dev/packages/tmdb_api) / [license](https://pub.dev/packages/tmdb_api/license) | 2025-03-26，**GPL-3.0** | 功能全但许可对闭源应用不友好，**不推荐**。 |
| TMDB | [`tmdb_dart` 0.2.2](https://pub.dev/packages/tmdb_dart) | 2022-01-13，MIT | 太旧，仅作 API 形态参考。 |
| OMDb | [`t_omdb`](https://pub.dev/packages/t_omdb) / [`omdb_dart`](https://pub.dev/packages/omdb_dart) | Dart 客户端可用；[OMDb 官网](https://www.omdbapi.com/)注明 API key、Poster API 限赞助者，页脚「All content licensed under CC BY-NC 4.0.」 | **数据非商用**；不建议作为商业数据源。 |
| TVDB | [官方 v4 Swagger](https://thetvdb.github.io/v4-api/swagger.yml) | `/login` 用 apikey（订阅者还需 PIN），bearer token 约 1 个月有效 | 剧集信息补充可选；需要申请 key，未发现活跃 Dart 客户端，直接走 HTTP。 |
| OpenSubtitles | [`opensubtitles_dart` 0.0.1](https://pub.dev/packages/opensubtitles_dart) + [`opensubtitles_hasher` 1.2.1](https://pub.dev/packages/opensubtitles_hasher) | MIT；前者需 apiKey + userAgent，后者读取前 128 KB 计算 `moviehash`/`moviebytesize` | 字幕下载可行；算法依据 [OSHash 官方仓库](https://github.com/opensubtitles/oshash/blob/main/README.md)（含 Dart 实现）。版本早期，需自建限流与缓存。 |
| NFO | 无靠谱专用包：[pub.dev `nfo` 搜索](https://pub.dev/packages?q=nfo) | — | **复用仓库现有 `xml2json` 6.2.6**；NFO 本质是 XML，本地 `lib/pages/common/video_player.dart:81` 已解析 `<movie>` / `<episodedetails>`。 |
| 豆瓣 | [官方 v2 端点现场响应](https://api.douban.com/v2/movie/in_theaters) | HTTP 403：`{"msg":"invalid_apikey, Please contact bd-team@douban.com for authorized access.","code":104}`；[pub.dev 搜索](https://pub.dev/packages?q=douban)无可信客户端 | **不可作为默认数据源**；除非用户自带授权 key，否则不要硬编码或假装可用。 |

**TMDB 合规要点**：[官方 FAQ](https://developer.themoviedb.org/docs/faq) 写明 API 免费用于 non-commercial，需把 TMDB 标为数据和/或图片来源，并给出署名文案「This product uses the TMDB API but is not endorsed or certified by TMDB.」；商用需联系官方取得 license。API key 在[账号设置](https://www.themoviedb.org/settings/api)申请。

---

## 4. 现成开源应用 / 可复用形态

| 项目 | 许可 / 活跃度（一手来源） | 它解决什么 | 本项目怎么复用 | 不该怎么做 |
|---|---|---|---|---|
| **Jellyfin** | [GPL-2.0 / 活跃度 API](https://api.github.com/repos/jellyfin/jellyfin)（pushed 2026-11-21）；[官方电影媒体文档](https://jellyfin.org/docs/general/server/media/movies/)；[API 文档](https://api.jellyfin.org/) | 服务器扫描媒体库，自动从外部 metadata providers 抓取信息；支持 NFO、封面/图片、外置字幕/音轨命名规则 | 走 HTTP API 对接；MIT 的 [`jellyfin_dart` 0.1.2](https://pub.dev/packages/jellyfin_dart) 覆盖 v10.11.0；符合 `docs/API_CAPTURE.md:9` 的「第三方 HTTP API」约束 | 不要把 GPL-2.0 服务端代码嵌入 Flutter 客户端；不要假设 Emby 也能按同样开源方式复用（本地文档只说走其 HTTP API）。 |
| **Kodi** | [GPLv2 / 活跃度 API](https://api.github.com/repos/xbmc/xbmc)（pushed 2026-11-21）；[JSON-RPC 源码](https://github.com/xbmc/xbmc/tree/master/xbmc/interfaces/json-rpc)；刮削插件如 [TMDB Python 插件 GPL-3.0](https://github.com/xbmc/metadata.tvshows.themoviedb.org.python)、[TVDB 插件 GPL-2.0](https://github.com/xbmc/metadata.tvdb.com.python) | 完整媒体库 + 刮削引擎 + NFO + 播放；可通过 JSON-RPC 远程控制 | 作为算法/命名规则参考，或让用户外接 Kodi；生成兼容 Kodi 的 NFO 旁车文件 | 直接移植 scraper addon 到闭源 App 会引入 GPL 义务；嵌入 Kodi 核心成本高、平台不匹配。 |
| **tinyMediaManager** | [GitLab 源码](https://gitlab.com/tinyMediaManager/tinyMediaManager)（2026-11-21 活跃），[Apache-2.0 LICENSE](https://gitlab.com/tinyMediaManager/tinyMediaManager/-/raw/devel/LICENSE)，[README](https://gitlab.com/tinyMediaManager/tinyMediaManager/-/raw/devel/README.md) | Java 跨平台 GUI+CLI；IMDb/TMDB/TVDB 等刮削、封面下载、OpenSubtitles 字幕、技术元数据提取、写出 Kodi 可识别 NFO | **外部桌面工具**：用户先用它整理库，App 读取 NFO/图片/字幕；CLI 可批处理 | 不能作为 Dart 库嵌进移动 App；不要把 Java GUI 搬进 Flutter。 |
| **MediaElch** | [LGPL-3.0 COPYING](https://github.com/Komet/MediaElch/blob/master/COPYING)，[活跃度 API](https://api.github.com/repos/Komet/MediaElch)（pushed 2026-11-15）；README 说明管理电影/剧集/音乐会/音乐并写入 NFO、下载 fanart.tv 图片 | Kodi 风格的桌面 NFO 管理器 | 与 tinyMediaManager 同：外部生成旁车文件，App 只读 | 不内嵌 LGPL/GPL 桌面代码；注意 LGPL 动态链接/修改源码义务。 |
| **Sonarr / Radarr / Bazarr** | [Sonarr](https://github.com/Sonarr/Sonarr)、[Radarr](https://github.com/Radarr/Radarr)、[Bazarr](https://github.com/morpheus65535/bazarr)，均 GPL-3.0 | 下载自动化与字幕补全，不是媒体库刮削 SDK | 高级用户可自行运行，通过各自 API 配合；不属于本 App 核心 | 不作为 Dart 依赖；不要误当成「刮削库」。 |

---

## 5. 风险清单

1. **许可证**：优先 MIT / Apache-2.0 / BSD 组合（`media_kit`、`xue_hua_media_info`、`tmdb_api_client`、`jellyfin_dart`）。避开 `tmdb_api` GPL-3.0、`ffmpeg_kit_flutter_new` full-GPL、VLC/Kodi 原生 GPL 组件；若引入 LGPL 组件需单独评估动态链接与源码披露义务。
2. **数据源条款**：TMDB 免费但非商用 + 署名 + 商用授权（[FAQ](https://developer.themoviedb.org/docs/faq)）；OMDb 数据 CC BY-NC（[官网](https://www.omdbapi.com/)）；TVDB / OpenSubtitles 需 API key（[TVDB Swagger](https://thetvdb.github.io/v4-api/swagger.yml)、[opensubtitles_dart](https://pub.dev/packages/opensubtitles_dart)）；豆瓣 v2 端点无授权 key 返回 `invalid_apikey`（[现场响应](https://api.douban.com/v2/movie/in_theaters)）。
3. **平台缺口**：Web 上 `media_kit` 走浏览器 `<video>`，格式远少于原生；`video_player`/`chewie` 无 Linux/Windows；`flutter_vlc_player` 仅 Android/iOS；`ffmpeg_kit_flutter_new` 无 Web；`xue_hua_media_info` 要求 Flutter 3.44+。
4. **包体与构建**：libmpv 预编译产物按 ABI/平台分发，Android 需 `--split-per-abi`，否则包体显著增大；原生插件还会增加各平台构建配置和签名/沙箱工作量。
5. **维护与稳定性**：小版本包（如 `opensubtitles_dart` 0.0.1、`jellyfin_dart` 0.1.2、新出的 `tmdb_api_client` 1.0.0）API 可能变动，应做适配层与缓存，避免散落调用。
6. **用户数据与密钥**：API key / Jellyfin token 进入安全存储而非源码或日志；写 NFO/字幕到用户媒体目录应显式授权、可回滚，避免覆盖用户已有元数据。

---

## 6. 落地建议（不改动代码的调研结论）

1. **播放**：保持 `MediaKit.ensureInitialized()` 与现有 `Player` / `Video` 结构；新增外置字幕轨时使用 `SubtitleTrack.uri` / `SubtitleTrack.data`，字幕解析/渲染复用 `subtitle` / `flutter_subtitle`；需要技术元数据再评估 `xue_hua_media_info`。
2. **刮削**：以 TMDB 为主数据源，先实现「文件名解析 → 搜索 → 详情/图片 → 本地缓存 → NFO 读写」薄层；NFO 复用现有 `xml2json`，TMDB HTTP 可用 `package:http`/`dio` 自行封装，或选 MIT `tmdb_api_client`；API key 由用户设置页提供并安全存储。
3. **扩展**：有 Jellyfin 用户时再做 HTTP connector（`jellyfin_dart` 或手写 REST）；桌面用户可提示用 tinyMediaManager / MediaElch 生成 NFO/字幕旁车文件，App 只读取。字幕下载可基于 OSHash + OpenSubtitles 单独做成可插拔模块。
4. **不要做**：不替换已工作的 `media_kit`；不引入 GPL 刮削引擎或 full-GPL FFmpeg；不硬编码 TMDB/TVDB/OpenSubtitles 密钥；不把豆瓣当稳定公开数据源。
