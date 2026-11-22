# 视频同目录播放列表与文件夹菜单设计

## Intent

多媒体视频页开播时，播放列表应是**当前视频同目录**的片子，而不是整库。
在「视频」页的文件夹行长按（移动端）/右键（桌面端）可直接 `播放全部` 或 `加入播放列表`，
让按目录追剧/连播不用先点进某一部。

## Goals

- 点视频开播：列表默认只含与它同父目录的视频，当前片在列表里。
- 文件夹菜单两项：`播放全部`（清空旧队列，按当前展示顺序播该文件夹及其子文件夹）、`加入播放列表`（追加到队尾）。
- 追加按路径去重；提示具体数量，如 `已加入 12 部`。
- 菜单在「文件树」和「按文件夹分段」两种展示方式里都能用。

## Non-goals / Anti-goals

- 不改 FileStation 文件页：它已经按当前目录构造列表。
- 不改播放历史页：它的列表仍按历史记录顺序。
- 不改 Synology Photos 视频：它目前没有播放列表。
- 不持久化队列，不做跨账号保存；退出 App 即清空。
- 不改 `lib/pages/media/music_player_page.dart`（另一会话正在改）。
- 不做播放列表编辑界面（删除单条、拖拽排序）。

## Constraints

- `MediaKit.ensureInitialized()` 在 macOS flutter_test 下失败（`Cannot find Mpv.framework/Mpv`），不能整页 pump `VideoPlayerPage`；只测纯函数和菜单。
- 菜单文案遵守 GUI 微文案规则：菜单项 ≤6 字，Toast ≤20 字，中文全角引号。
- 不新增依赖；沿用 `showMenu`、`FileListItem` 和 `UiUtil.toast`。

## Approaches

| 方案 | 做法 | 取舍 |
| --- | --- | --- |
| A（选） | 新增内存视频队列 store；播放器列表来自 store，媒体库入口把同目录片子写进队列；菜单替换/追加队列 | 「加入播放列表」有真实去处；多一个 store 和监听 |
| B | 只靠页面传参，加入 = 重新打开播放器 | 正在播放会被打断/从头播，不是追加 |
| C | 持久化到 StorageUtil | 多一份要清理的状态，容易和续播位置冲突 |

用户已选 A。

## Decisions

1. **纯函数**（放 `lib/util/media_library.dart`）：
   - `List<MediaItem> videosInFolder(List<MediaItem> items, String folderPath, {bool recursive = false})`
     —— 按路径前缀匹配，`recursive=false` 只匹配直接子文件（防止 `/a/b` 匹配到 `/a/bb`）。
   - `String parentFolder(String path)` —— 取最后一段之前的部分。
2. **队列 store**（`lib/stores/video_playlist_store.dart`）：
   - `final videoPlaylistStore = VideoPlaylistStore();`
   - `void openWith(Iterable<MediaItem> items)`：覆盖基础列表、保留已显式加入的片子，按路径去重。
   - `void addAll(Iterable<MediaItem> items)`：只追加到队尾，按路径去重；返回实际新增数量供 Toast 用。
   - `void reset(Iterable<MediaItem> items)`：清空基础列表和显式加入项，用于 `播放全部`。
   - `ReadonlySignal<List<MediaItem>> get items`：合并后的列表。
3. **播放器**：`VideoPlayerPage` 仍接收 `playlist` 构造参数（文件页/历史页用法不变），但在 build 时用 local signal 订阅 `videoPlaylistStore.items`，列表以 store 为准；无 store 内容时回落到传入的 `playlist`。`playingIndex` 按新增后的列表重新定位当前 `mediaPath`，避免追加后索引错乱。
4. **入口**：媒体库 `openPlayer(item)` 先 `videoPlaylistStore.openWith(videosInFolder(shown, parentFolder(item.path)))`，再开播放器。
5. **菜单**：提取 `showVideoFolderMenu(BuildContext, Offset)`，返回 `播放全部` / `加入播放列表` 二选一；`FileListItem` 增加可选 `onLongPress`/`onSecondaryTapDown`，默认仍走 `onAction`，其它调用方行为不变。`_TreeFolder` 和「按文件夹分段」标题行用它；`播放全部` 调 `reset(folderVideos)` 再打开第一集，`加入播放列表` 调 `addAll` 并 Toast。
6. **排序**：菜单取队列按页面当前展示顺序（`shown` 已排序/过滤），不额外排序；播放器内的排序按钮仍可用。

## Left to the builder

- 补 `test/util/media_library_test.dart` 的路径匹配/去重用例。
- 补 `test/stores/video_playlist_store_test.dart`：`openWith` 保留追加项、`addAll` 去重、返回数量、`reset` 清空。
- 补菜单 widget 测试（只 pump 菜单，不 pump 播放器）：两项文案与回调。
- 收尾跑 `flutter test --reporter compact` 与 `dart analyze lib test`；对照当前基线（209 tests pass，0 error）。
