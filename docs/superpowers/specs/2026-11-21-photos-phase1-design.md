# Synology Photos 缺口一期：相册管理与受控的照片删除

## Intent

审计发现 Photos 入口和浏览可用，但相对官方应用是只读的：`lib/pages/photos/album_tab.dart` 只能看相册，`lib/pages/common/image_preview.dart:81` 的删除走 FileStation 且 Photos 调用点没传 `paths`，分享链接管理仍是 TODO。用户选择分阶段推进（方案 1），一期只做能独立验证的闭环：相册新建/删除、契约明确后的照片删除、清掉空壳文件、补测试。分享管理和收藏/标签/移动/上传到照片库留给二期。

## Goals

- 个人空间相册页能新建相册、长按相册后确认删除；成功刷新列表，失败给出明确 toast。
- 照片删除只在抓到 `SYNO.Foto*.Browse.Item` 删除契约后接入；抓不到就不显示这个按钮，绝不猜接口。
- 删除 0 字节文件 `lib/pages/photos/widgets/folder_item_widget.dart`。
- 新增测试覆盖命名校验、确认流程接线和接口请求形状；`flutter test` 与 `dart analyze lib test` 不回退。

## Non-goals / Anti-goals

- 不做分享链接/权限/有效期、收藏、标签、移动、上传到 Photos 库，也不做人物/搜索（二期）。
- 不改 FileStation 文件预览的删除逻辑，不改备份/传输流程。
- 不在共享空间（`isTeam == true`）提供相册写操作：现有 `dsmFotoBrowseAlbumCreate/Delete` 只按 DSM 版本选 `Foto`/`Photo`（`lib/api/dsm_api.photos.dart:3-6`），没有 `FotoTeam` 分支，贸然调用会打到个人空间。
- 不把“保存图片”改成删除的附带动作；现有下载 URL 逻辑保持原样。

## Constraints

- 不引入新依赖；复用 `dsmFotoBrowseAlbumCreate`（`lib/api/dsm_api.photos.dart:95`）、`dsmFotoBrowseAlbumDelete`（`:113`）、`BottomConfirmSheet`、`BottomActionSheet`、`UiUtil.toast`。
- `docs/API_CAPTURE.md:242,259` 明确记录 Foto 写方法未抓包。抓包只操作自己新建的测试相册/照片，不碰真实数据；写帧抓不到是已知概率事件。
- 没有可联调的 NAS；照片删除这一步需要用户提供抓包或可访问环境，否则按目标 2 的兜底处理。
- API 层沿用 `_dsmApiRequestData` + `_httpPost` + `DSMException.fromMap` 的既有写法（见 `lib/api/dsm_api.photos.dart:95-125`）。

## Approaches

1. **分阶段核心闭环（已选）**：先做相册增删 + 有契约才做照片删除 + 清理 + 测试。代价：不是一次做全；收益：每步可验证、可回退，且不猜未知接口。
2. **分享优先**：先做共享链接/权限。代价：`lib/api/dsm_api.photos.sharing.dart:140` 只有 TODO，契约完全缺失，风险最高。
3. **一次对齐官方 Photos**：写操作 + 分享 + 搜索/人物/标签全做。代价：范围大且无法真机验证，不推荐。

## 实现要点（builder 照此实现）

### 相册新建/删除 — `lib/pages/photos/album_tab.dart`

- 在相册列表卡片上加 `onLongPress`，仅 `!isTeam` 时显示 `BottomActionSheet`（"删除相册"）；确认用 `BottomConfirmSheet`，确认后 `await dsmFotoBrowseAlbumDelete(e.id.toString())`，成功后 `getAlbum()` 刷新，失败 toast "删除相册失败"。
- 在相册列表顶部加一个"新建相册"入口（`TextButton`/卡片，随页面现有风格），点击弹 `TextField` 输入框；确认后 `await dsmFotoBrowseAlbumCreate(name.trim())`，成功后 `getAlbum()`，失败 toast "新建相册失败"。
- 抽出纯函数 `String? validateAlbumName(String? name)`（trim 后非空、最长 60 字）供输入校验和单测；空名或超长时不发请求。
- 相册卡片当前是 `GestureDetector(onTap: ...)`（`lib/pages/photos/album_tab.dart:220-240`），加长按不要吃掉原有跳转。

### 照片删除 — 条件步骤

- 只有拿到抓包/API 文档确认 `SYNO.Foto*.Browse.Item` 的删除 method 与参数后才实现；否则跳过整步，保持 Photos 预览现在"没有删除按钮"的安全行为，并在交付说明里写明未做。
- 实现时：在 `lib/api/dsm_api.photos.items.dart` 增加 `dsmFotoBrowseItemDelete(List<String> ids)` 及纯请求数据函数（供测试断言 api/method/version/参数）；在 `lib/pages/common/image_preview.dart` 增加可选 `onDeletePhoto(String id)` 回调，与现有 `paths` + `dsmFileStationDeleteStartForPage` 分支完全分开；Photos 各预览调用点（`lib/pages/photos/timeline.dart:69`、`lib/pages/photos/widgets/photo_item_widget.dart` 等）传该回调，文件页调用点不受影响。删除前必须 `BottomConfirmSheet` 二次确认，成功后从本地预览列表移除对应项。

### 清理与验证

- 删除 `lib/pages/photos/widgets/folder_item_widget.dart`（0 字节，无引用）。
- 新增 `test/pages/photos_album_actions_test.dart`：`validateAlbumName` 的空/空白/超长/正常用例；源码级断言 `album_tab.dart` 接线了 create/delete、删除前有确认、共享空间不显示写入口。
- 若照片删除实现，新增 `test/api/dsm_api_photos_write_test.dart`：断言请求数据函数的 api/method/version/参数形状。
- 收尾跑 `flutter test --reporter compact` 和 `dart analyze lib test`；基线是 131 项测试全过、0 error（7 warning / 425 info 为既有）。

## 留给 builder 的判断

- 新建入口的图标/文案跟随相册页现有风格即可；`isTeam` 下隐藏写入口。
- 抓包未到手时，不要为照片删除写占位 API、也不要在 UI 里放不可用的按钮；这是明确的交付边界，不是遗漏。
- 二期的分享管理不写半成品代码；本设计只为它划定边界。
