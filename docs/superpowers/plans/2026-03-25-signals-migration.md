# Signals 全量迁移 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将本 worktree 中所有残留的 `provider/setState` 迁移到 `signals`，对齐 `dsm_helper` 行为，并抽取可复用 UI 到 `lib/widgets/common/`。

**Architecture:** 以 `dsm_helper` 为基线，逐模块迁移。共享/持久状态进入 Store；页面局部状态使用局部 signals；少量纯 UI 瞬时状态保留 `setState`。公共 UI 抽取为无业务依赖组件。

**Tech Stack:** Flutter, Dart, `signals_flutter`, existing app stores.

---

## File Structure (planned changes)

**Create:**
- `docs/superpowers/plans/2026-03-25-signals-migration-inventory.md` (迁移清单与对齐基线)
- `lib/widgets/common/` (目录已存在则复用)
- `lib/widgets/common/<new_common_widgets>.dart` (具体名称按对照结果确定)
- `lib/stores/<new_store>.dart` (按模块对照 dsm_helper 后创建)
- `test/stores/<new_store>_test.dart` (新增 Store 基础测试)

**Modify (含 setState/provider 迁移):**
- `lib/widgets/neu_back_button.dart`
- `lib/widgets/animation_progress_bar.dart`
- `lib/widgets/sort_menu.dart`
- `lib/widgets/virtual_keyboard.dart`
- `lib/pages/security_scan/security_scan.dart`
- `lib/pages/moments/photos.dart`
- `lib/pages/user/setting.dart`
- `lib/pages/virtual_machine/virtual_machine.dart`
- `lib/widgets/dashboard/dashboard_task_item.dart`
- `lib/pages/user/otp_bind.dart`
- `lib/pages/moments/moments.dart`
- `lib/pages/moments/album.dart`
- `lib/pages/terminal/ssh.dart`
- `lib/pages/moments/timeline.dart`
- `lib/pages/docker/detail.dart`
- `lib/pages/notify/notify.dart`
- `lib/pages/control_panel/file_service/file_service.dart`
- `lib/pages/login/confirm_logout.dart`
- `lib/pages/terminal/add_server.dart`
- `lib/pages/docker/docker.dart`
- `lib/pages/control_panel/file_service/log_setting.dart`
- `lib/pages/terminal/select_server.dart`
- `lib/pages/control_panel/network/network.dart`
- `lib/pages/control_panel/update_reset/update_reset.dart`
- `lib/pages/control_panel/task_scheduler/task_scheduler.dart`
- `lib/widgets/expansion_container.dart`
- `lib/pages/control_panel/user_groups/user_group.dart`
- `lib/pages/storage_manager/smart.dart`
- `lib/pages/control_panel/task_scheduler/task_record.dart`
- `lib/pages/control_panel/media_index/media_index.dart`
- `lib/pages/control_panel/power/power.dart`
- `lib/pages/control_panel/public_access/edit_ddns.dart`
- `lib/pages/storage_manager/storage_manager.dart`
- `lib/widgets/moments/timeline_item_widget.dart`
- `lib/pages/control_panel/shared_folders/add_shared_folder.dart`
- `lib/pages/control_panel/power/add_power_task.dart`
- `lib/pages/control_panel/public_access/public_access.dart`
- `lib/pages/control_panel/shared_folders/shared_folders.dart`
- `lib/pages/photos/folder.dart`
- `lib/pages/file/share_manager.dart`
- `lib/pages/control_panel/users/users.dart`
- `lib/pages/photos/general_tag_page.dart`
- `lib/pages/resource_monitor/task_manager.dart`
- `lib/pages/control_panel/users/user_detail.dart`
- `lib/pages/file/search.dart`
- `lib/pages/backup/backup.dart`
- `lib/pages/photos/album_page.dart`
- `lib/pages/resource_monitor/users.dart`
- `lib/pages/file/remote_folder.dart`
- `lib/pages/file/share.dart`
- `lib/pages/file/favorite.dart`
- `lib/pages/setting/reward.dart`
- `lib/pages/dashborad/widget_setting.dart`
- `lib/pages/file/upload.dart`
- `lib/pages/photos/geocoding_page.dart`
- `lib/pages/resource_monitor/performance.dart`
- `lib/pages/file/file.dart`
- `lib/pages/file/select_folder.dart`
- `lib/pages/dashborad/media_converter.dart`
- `lib/pages/download_station/detail.dart`
- `lib/pages/update/update.dart`
- `lib/pages/download/download_setting.dart`
- `lib/pages/setting/setting.dart`
- `lib/pages/log_center/log_center.dart`
- `lib/pages/photos/photos.dart`
- `lib/pages/common/gesture_password.dart`
- `lib/pages/setting/about.dart`
- `lib/pages/packages/detail.dart`
- `lib/pages/download_station/add_task.dart`
- `lib/pages/packages/uninstall.dart`
- `lib/pages/photos/share_tab.dart`
- `lib/pages/common/audio_player.dart`
- `lib/pages/photos/album_tab.dart`
- `lib/pages/common/browser.dart`
- `lib/pages/download_station/select_file.dart`
- `lib/pages/common/select_local_folder.dart`
- `lib/pages/common/device_finder.dart`
- `lib/pages/setting/helper_setting.dart`
- `lib/pages/photos/timeline.dart`
- `lib/pages/download_station/download_station.dart`
- `lib/pages/common/video_player.dart`
- `lib/pages/common/select_ablum.dart`
- `lib/pages/common/image_preview.dart`
- `lib/pages/download/download_state.dart` (含 FIXME: use signals)

**Keep `setState` (允许保留的纯 UI 瞬时状态，最终需确认):**
- `lib/widgets/neu_back_button.dart`
- `lib/widgets/animation_progress_bar.dart`
- `lib/widgets/virtual_keyboard.dart`
- `lib/pages/common/gesture_password.dart`
- `lib/pages/common/video_player.dart`
- `lib/pages/common/audio_player.dart`

**UI-only setState 判定标准（必须满足其一）:**
- 动画帧/进度条刷新
- 手势/拖拽过程中的连续坐标更新
- 输入焦点/软键盘显示状态等纯 UI 交互
- 临时可视效果（不影响业务数据）

---

### Task 1: 固定对齐基线 + 生成迁移清单

**Files:**
- Create: `docs/superpowers/plans/2026-03-25-signals-migration-inventory.md`

- [ ] **Step 1: 记录 dsm_helper 基线 commit**

Run: `git -C /Users/humphrey/Project/Flutter/dsm_helper rev-parse HEAD`
Expected: 输出一个 commit hash

- [ ] **Step 2: 生成 setState/provider 清单（不区分大小写）**

Run: `rg -n -i "setState\(|provider" lib > /tmp/setstate_provider.txt`
Expected: 生成匹配列表

- [ ] **Step 3: 写入 inventory 文档**

Write the file with以下内容（示例结构）：

```markdown
# Signals Migration Inventory

- Baseline (dsm_helper): <commit-hash>
- Scan date: 2026-03-25

## setState/provider occurrences
<paste /tmp/setstate_provider.txt>
```

- [ ] **Step 4: Commit**

```bash
git add -A docs/superpowers/plans/2026-03-25-signals-migration-inventory.md
git commit -m "docs: add signals migration inventory"
```

- [ ] **Step 5: 对齐 inventory 与计划清单**

对比 `docs/superpowers/plans/2026-03-25-signals-migration-inventory.md` 中的实际匹配文件列表与本计划的“Modify”清单，
若发现额外文件：
- 将其加入相应模块任务；或
- 新增一个模块子任务补齐迁移与验证。

---

### Task 2: 建立公共组件与复用边界

**Files:**
- Create: `lib/widgets/common/<new_common_widgets>.dart`
- Modify: `lib/pages/...` (引用新组件)

- [ ] **Step 1: 对比 dsm_helper 的重复 UI**

Run: `diff -u /Users/humphrey/Project/Flutter/dsm_helper/lib/widgets/common/<candidate>.dart lib/widgets/common/<candidate>.dart`
Expected: 找到可复用组件模式
If not found: 在 `dsm_helper` 中搜索相近组件（`rg -n "class .*Tile|Common" lib/widgets`），并基于当前项目需求本地抽取。

- [ ] **Step 2: 提取/新增通用组件**

Example skeleton:

```dart
class CommonListTile extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const CommonListTile({
    super.key,
    required this.leading,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: title,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
```

- [ ] **Step 3: 更新页面使用新组件**

Example replacement:

```dart
return CommonListTile(
  leading: Icon(Icons.info),
  title: Text(title),
  trailing: trailing,
  onTap: onTap,
);
```

- [ ] **Step 4: Commit**

```bash
git add -A lib/widgets/common
git add -A lib/pages
git commit -m "refactor: extract common widgets"
```

---

### Task 3: 迁移全局/共享状态到 Store（对齐 dsm_helper）

**Files:**
- Create: `lib/stores/<new_store>.dart`
- Modify: `lib/stores/connection_store.dart`
- Modify: `lib/stores/settings_store.dart`
- Modify: `lib/pages/...` (使用 Store)
- Test: `test/stores/<new_store>_test.dart`

- [ ] **Step 1: 对比 dsm_helper Store 结构并新增缺失 store**

Run: `diff -u /Users/humphrey/Project/Flutter/dsm_helper/lib/stores/<store>.dart lib/stores/<store>.dart`
Expected: 识别需要补齐的 signal/state

- [ ] **Step 2: 添加 Store 基础测试**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/stores/<new_store>.dart';

void main() {
  test('store updates signal values', () {
    final store = <NewStore>();
    store.setFoo('bar');
    expect(store.foo.value, 'bar');
  });
}
```

- [ ] **Step 3: 迁移页面引用到 Store 信号**

```dart
return Watch((context) {
  return Text(settingsStore.firmwareVersion.value);
});
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/stores/<new_store>_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add -A lib/stores
git add -A lib/pages
git add -A test/stores
git commit -m "feat: migrate shared state to signals store"
```

---

### Task 4: 模块化迁移页面（按功能域）

> 每个子任务遵循：对齐 dsm_helper → 用 signals 替换 setState/provider → 保留必要 UI setState → 更新公共组件 → 局部测试/运行。

- [ ] **Step 0: 锁定已迁移区域（dashboard/http api）并核对对齐**  

对 `lib/pages/dashborad/` 与 `lib/util/api.dart`（及其相关 API 文件）做一次 dsm_helper 对齐核查，确保只做“补齐对齐”而不改行为。

#### Task 4.1: 登录/账号/安全相关

**Files:**
- Modify: `lib/pages/login/confirm_logout.dart`
- Modify: `lib/pages/user/otp_bind.dart`
- Modify: `lib/pages/user/setting.dart`
- Modify: `lib/pages/security_scan/security_scan.dart`
- Modify: `lib/pages/common/gesture_password.dart` (允许保留 UI setState)

- [ ] **Step 1: 对齐 dsm_helper 实现**

Run: `diff -u /Users/humphrey/Project/Flutter/dsm_helper/lib/pages/user/setting.dart lib/pages/user/setting.dart`
Expected: 明确需迁移的状态字段

- [ ] **Step 2: 用 signals 替换 setState**

Example:

```dart
final _loading = signal(false);

Future<void> load() async {
  _loading.value = true;
  // ...
  _loading.value = false;
}

@override
Widget build(BuildContext context) {
  return Watch((context) {
    return _loading.value ? const CircularProgressIndicator() : content;
  });
}
```

- [ ] **Step 3: 保留 UI-only setState 并注释原因**

```dart
// UI-only: gesture drawing frame updates
setState(() { /* ... */ });
```

- [ ] **Step 4: Commit**

```bash
git add -A lib/pages/login/confirm_logout.dart
# ...添加本任务相关文件
git commit -m "feat: migrate auth/user/security pages to signals"
```

#### Task 4.2: 控制面板模块

**Files:**
- Modify: `lib/pages/control_panel/file_service/file_service.dart`
- Modify: `lib/pages/control_panel/file_service/log_setting.dart`
- Modify: `lib/pages/control_panel/network/network.dart`
- Modify: `lib/pages/control_panel/update_reset/update_reset.dart`
- Modify: `lib/pages/control_panel/task_scheduler/task_scheduler.dart`
- Modify: `lib/pages/control_panel/task_scheduler/task_record.dart`
- Modify: `lib/pages/control_panel/media_index/media_index.dart`
- Modify: `lib/pages/control_panel/power/power.dart`
- Modify: `lib/pages/control_panel/power/add_power_task.dart`
- Modify: `lib/pages/control_panel/public_access/public_access.dart`
- Modify: `lib/pages/control_panel/public_access/edit_ddns.dart`
- Modify: `lib/pages/control_panel/shared_folders/shared_folders.dart`
- Modify: `lib/pages/control_panel/shared_folders/add_shared_folder.dart`
- Modify: `lib/pages/control_panel/users/users.dart`
- Modify: `lib/pages/control_panel/users/user_detail.dart`
- Modify: `lib/pages/control_panel/user_groups/user_group.dart`

- [ ] **Step 1: 对齐 dsm_helper**

Run (example): `diff -u /Users/humphrey/Project/Flutter/dsm_helper/lib/pages/control_panel/network/network.dart lib/pages/control_panel/network/network.dart`

- [ ] **Step 2: 替换 setState 为 signals + Watch**

```dart
final _data = signal<List<Map>>([]);

void setItems(List<Map> items) => _data.value = items;

Widget build(BuildContext context) {
  return Watch((context) {
    return ListView(
      children: _data.value.map(buildRow).toList(),
    );
  });
}
```

- [ ] **Step 3: 提取重复 UI 到 `lib/widgets/common/`**

```dart
return CommonSection(title: title, children: children);
```

- [ ] **Step 4: Commit**

```bash
git add -A lib/pages/control_panel
git add -A lib/widgets/common
git commit -m "feat: migrate control panel pages to signals"
```

#### Task 4.3: 文件/下载/备份模块

**Files:**
- Modify: `lib/pages/file/file.dart`
- Modify: `lib/pages/file/select_folder.dart`
- Modify: `lib/pages/file/search.dart`
- Modify: `lib/pages/file/share.dart`
- Modify: `lib/pages/file/share_manager.dart`
- Modify: `lib/pages/file/favorite.dart`
- Modify: `lib/pages/file/remote_folder.dart`
- Modify: `lib/pages/file/upload.dart`
- Modify: `lib/pages/download/download_state.dart`
- Modify: `lib/pages/download/download_setting.dart`
- Modify: `lib/pages/download_station/download_station.dart`
- Modify: `lib/pages/download_station/detail.dart`
- Modify: `lib/pages/download_station/add_task.dart`
- Modify: `lib/pages/download_station/select_file.dart`
- Modify: `lib/pages/backup/backup.dart`

- [ ] **Step 1: 对齐 dsm_helper**

Run (example): `diff -u /Users/humphrey/Project/Flutter/dsm_helper/lib/pages/download/download_state.dart lib/pages/download/download_state.dart`

- [ ] **Step 2: 把下载状态迁移为 signals store 或局部 signals**

```dart
final loading = signal(true);
final tasks = signal<List<DownloadInfo>>([]);
```

- [ ] **Step 3: 替换 setState 更新**

```dart
tasks.value = updatedTasks;
loading.value = false;
```

- [ ] **Step 4: Commit**

```bash
git add -A lib/pages/file
# ...添加本任务相关文件
git commit -m "feat: migrate file/download/backup pages to signals"
```

#### Task 4.4: 资源监控/日志/通知/更新模块

**Files:**
- Modify: `lib/pages/resource_monitor/task_manager.dart`
- Modify: `lib/pages/resource_monitor/performance.dart`
- Modify: `lib/pages/resource_monitor/users.dart`
- Modify: `lib/pages/log_center/log_center.dart`
- Modify: `lib/pages/notify/notify.dart`
- Modify: `lib/pages/update/update.dart`

- [ ] **Step 1: 对齐 dsm_helper**

Run (example): `diff -u /Users/humphrey/Project/Flutter/dsm_helper/lib/pages/resource_monitor/performance.dart lib/pages/resource_monitor/performance.dart`

- [ ] **Step 2: 用 Watch 替换 setState**

```dart
return Watch((context) {
  return Text('${stats.value}');
});
```

- [ ] **Step 3: Commit**

```bash
git add -A lib/pages/resource_monitor
# ...添加本任务相关文件
git commit -m "feat: migrate monitor/log/notify/update pages to signals"
```

#### Task 4.5: 媒体/照片/时刻模块

**Files:**
- Modify: `lib/pages/photos/photos.dart`
- Modify: `lib/pages/photos/folder.dart`
- Modify: `lib/pages/photos/timeline.dart`
- Modify: `lib/pages/photos/album_page.dart`
- Modify: `lib/pages/photos/album_tab.dart`
- Modify: `lib/pages/photos/share_tab.dart`
- Modify: `lib/pages/photos/general_tag_page.dart`
- Modify: `lib/pages/photos/geocoding_page.dart`
- Modify: `lib/pages/moments/moments.dart`
- Modify: `lib/pages/moments/album.dart`
- Modify: `lib/pages/moments/photos.dart`
- Modify: `lib/pages/moments/timeline.dart`
- Modify: `lib/widgets/moments/timeline_item_widget.dart`

- [ ] **Step 1: 对齐 dsm_helper**

Run (example): `diff -u /Users/humphrey/Project/Flutter/dsm_helper/lib/pages/photos/photos.dart lib/pages/photos/photos.dart`

- [ ] **Step 2: 用 signals 管理页面状态**

```dart
final albumList = signal<List<Album>>([]);
```

- [ ] **Step 3: Commit**

```bash
git add -A lib/pages/photos
# ...添加本任务相关文件
git commit -m "feat: migrate photos/moments pages to signals"
```

#### Task 4.6: Docker/虚拟机/存储/杂项模块

**Files:**
- Modify: `lib/pages/docker/docker.dart`
- Modify: `lib/pages/docker/detail.dart`
- Modify: `lib/pages/virtual_machine/virtual_machine.dart`
- Modify: `lib/pages/storage_manager/storage_manager.dart`
- Modify: `lib/pages/storage_manager/smart.dart`
- Modify: `lib/widgets/dashboard/dashboard_task_item.dart`
- Modify: `lib/pages/dashborad/media_converter.dart`
- Modify: `lib/pages/setting/setting.dart`
- Modify: `lib/pages/setting/about.dart`
- Modify: `lib/pages/setting/reward.dart`
- Modify: `lib/pages/setting/helper_setting.dart`
- Modify: `lib/pages/common/browser.dart`
- Modify: `lib/pages/common/select_local_folder.dart`
- Modify: `lib/pages/common/select_ablum.dart`
- Modify: `lib/pages/common/device_finder.dart`
- Modify: `lib/pages/common/image_preview.dart`

- [ ] **Step 1: 对齐 dsm_helper**

Run (example): `diff -u /Users/humphrey/Project/Flutter/dsm_helper/lib/pages/docker/docker.dart lib/pages/docker/docker.dart`

- [ ] **Step 2: signals 迁移与公共组件抽取**

```dart
final isLoading = signal(false);
```

- [ ] **Step 3: Commit**

```bash
git add -A lib/pages/docker
# ...添加本任务相关文件
git commit -m "feat: migrate misc pages to signals"
```

#### Task 4.7: 终端模块

**Files:**
- Modify: `lib/pages/terminal/add_server.dart`
- Modify: `lib/pages/terminal/select_server.dart`
- Modify: `lib/pages/terminal/ssh.dart`

- [ ] **Step 1: 对齐 dsm_helper**

Run: `diff -u /Users/humphrey/Project/Flutter/dsm_helper/lib/pages/terminal/ssh.dart lib/pages/terminal/ssh.dart`

- [ ] **Step 2: 用 signals 替换 setState**

```dart
final _title = signal('');

void setTitle(String value) => _title.value = value;

@override
Widget build(BuildContext context) {
  return Watch((context) {
    return Text(_title.value);
  });
}
```

- [ ] **Step 3: Commit**

```bash
git add -A lib/pages/terminal
git commit -m "feat: migrate terminal pages to signals"
```

---

### Task 5: 清理与验证

**Files:**
- Modify: `lib/pages/...` (清理残留 setState/provider)
- Modify: `lib/widgets/...`

- [ ] **Step 1: 重新扫描残留 setState/provider**

Run: `rg -n "setState\(|provider" lib`
Expected: 仅保留允许的 UI-only setState

- [ ] **Step 2: 手工验证关键流程**

Checklist:
- 登录/退出/账号切换
- 终端连接/选择服务器/SSH 页面状态刷新
- 下载任务列表刷新
- 控制面板设置切换
- 照片/时刻列表刷新
- 资源监控刷新
- 对照 `dsm_helper` 行为一致性（核心流程）

- [ ] **Step 3: 编译/分析验证**

Run: `flutter analyze`
Expected: 无严重错误

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "chore: finalize signals migration"
```
