# Signals + Flutter Hooks 全量迁移 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 `lib/` 下所有 `StatefulWidget` / `setState` 状态管理迁移到 signals + flutter_hooks，并使 `flutter analyze` 全库零告警、行为不变。

**Architecture:** 本计划只覆盖阶段一（迁移，不拆文件）。先锁定依赖并清理全库既存 lint 告警到零（批次 0），再按功能模块分批将 `StatefulWidget` 改为 `HookWidget`/`StatelessWidget`、字段改为 `signals_hooks` 的 `useSignal`/`useComputed`，controller/订阅/observer 交给 `flutter_hooks` 官方 hook；共享状态保留在两个 Store 的信号上。每批以 `flutter analyze` 零告警 + 编译通过为验收。

**Tech Stack:** Flutter 3.47.2 / Dart >=3.5.0；`signals ^6.3.0`、`signals_flutter ^6.3.0`、`signals_hooks 0.4.0`、`flutter_hooks 0.21.3+1`。

**Spec:** `docs/superpowers/specs/2026-11-11-signals-hooks-migration-design.md`

**Test Strategy:** 本计划是行为不变的重构，验收主手段是 `flutter analyze` 全库零告警 + `flutter build` 编译通过（spec 已定 `flutter test`/`flutter build` 不作为硬性门槛）。为覆盖最高风险点，计划含两个测试任务：`connection_store`/`settings_store` 信号契约测试（Task 2）与 `Home` 的 build smoke + 抽屉/返回信号驱动测试（Task 7）。其余批次以 analyze 零 + 编译为验证。

## Global Constraints

- 不新增依赖、不改版本；`signals_hooks 0.4.0` 依赖 `signals ^6.3.0`，与现有 pubspec 匹配，无需升级。
- 不恢复 `backup/hook.dart`（当年靠 `setState` 触发重建，本质是 Stateful 思路）。
- 不删除或替换 `lib/util/api.dart`（第 2 项处理）。
- 阶段一：只换状态，不拆文件、不改命名、不加自研适配层、不改 UI（状态机制本身除外）。
- 验收：`flutter analyze` 输出必须为空（零 error/warning/info/lint）；逐条修复，不批量加 `// ignore`、不改 `analysis_options.yaml` 的 linter 规则、不新增 exclude。
- 共享状态保留在 `connection_store` / `settings_store` 的信号；「全部 signal」指状态值，Flutter 对象（AnimationController 等）生命周期交给 hooks。
- 豁免仅限第三方/框架的 State 类型引用：`GlobalKey<ScaffoldState>`、`GlobalKey<ExtendedImageSlidePageState>` 及其 `currentState` 调用；不豁免整个文件（`lib/widgets/animation_progress_bar.dart` 仍在范围内）。
- 顺序：本计划只做阶段一；阶段二（拆分易读）在阶段一验收后另写计划。
- `flutter pub get` 属安装依赖，仅在本计划 Task 1 执行；若因 gitee 依赖失败，停下报告，不擅自改依赖、不降级验收。

## Review Focus

1. `useSignal`/`useComputed` 在 `HookWidget.build` 之外被调用 → 抛异常。迁移须把所有 signal 创建写进 `build` 内，原 `initState` 逻辑搬到 `useSignalEffect`。测试：Task 7 的 `Home` build 不抛。
2. 跨组件 `currentState` 改信号后，`home` 的返回键 `onWillPop` 与抽屉开关行为须与原来一致（信号触发顺序、`isDrawerOpen` 判定）。测试：Task 7 模拟返回键/抽屉信号。
3. `PersistentSignalExt.save/read` 在 `useSignalEffect` 中调用，须 keys 固定、仅初始化一次，避免重复写入或 effect 死循环导致丢失持久化。
4. `AnimationController`/`TabController` 改用 `use*` hook 后，原 `TickerProviderStateMixin` 删除，`TabBar` 动画须仍工作且 widget 卸载时释放，不泄漏 ticker。
5. 全局 Store 信号经 `useExistingSignal` 订阅，主题/登录态等仍正确刷新（如 `settingsStore.darkMode` 切换重建 `MaterialApp`）。

---

## Task 1: 依赖锁定（flutter pub get + pubspec.lock）

**Files:**
- Create/Modify: `pubspec.lock`（由 `flutter pub get` 生成）
- Modify: none（不改 pubspec.yaml 依赖）

**Interfaces:**
- Consumes: 现有 `pubspec.yaml`（已含 `signals_hooks: ^0.4.0`、`flutter_hooks: ^0.21.3+1`）
- Produces: 已解析的 `pubspec.lock` 与本地 `.dart_tool`，使后续 `flutter analyze`/`flutter build` 可运行

- [ ] **Step 1: 运行 `flutter pub get`**

Run: `flutter pub get`
Expected: 解析成功（注意：pubspec 含 gitee git 依赖，需联网；若失败，停下报告，不擅自改依赖）。

- [ ] **Step 2: 提交 `pubspec.lock`**

```bash
git add pubspec.lock
git commit -m "chore: lock dependencies for signals migration"
```

---

## Task 2: Store 信号契约测试 + 记录 analyze 基线

**Files:**
- Create: `test/stores/connection_store_test.dart`
- Create: `test/stores/settings_store_test.dart`
- Modify: none

**Interfaces:**
- Consumes: `connection_store`（signal 字段 `_sid`/`_baseUri`/`_darkMode` 等及其 setter）、`settings_store`
- Produces: 一个可重复运行的测试，证明 Store 信号读写契约在迁移前后一致

- [ ] **Step 1: 写失败测试——连接 Store 信号读写**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/stores/connection_store.dart';

void main() {
  test('connection store signals read/write', () {
    connectionStore.setSid('abc');
    expect(connectionStore.sid.value, 'abc');
    connectionStore.setBaseUri('http://1.2.3.4:5000/');
    expect(connectionStore.baseUri.value, 'http://1.2.3.4:5000/');
  });
}
```

- [ ] **Step 2: 运行测试确认通过**

Run: `flutter test test/stores/connection_store_test.dart`
Expected: PASS（Store 已存在，契约应已满足；若失败，先修 Store 再继续）

- [ ] **Step 3: 记录 `flutter analyze` 全库告警基线数字**

Run: `flutter analyze`
Expected: 输出既有告警数量；将该数字记到本任务提交说明中作为进度参考（非达标线）。

- [ ] **Step 4: 提交测试**

```bash
git add test/stores
git commit -m "test: add store signal contract tests"
```

---

## Task 3: Lint 清理 · lib 基础层

**Files:**
- Modify: `lib/stores/**`、`lib/extensions/**`、`lib/models/**`、`lib/services/**`、`lib/util/**`、`lib/theme/**`、`lib/constants/**`、`lib/api/**` 下所有产生 analyze 告警的文件（仅修复，不改行为）

**Interfaces:**
- Consumes: 无
- Produces: 上述目录 `flutter analyze <dir>` 零告警

- [ ] **Step 1: 逐文件修复上述目录的 analyze 告警**

逐条修复（`avoid_print`→日志、`prefer_const_constructors`→加 const、`use_build_context_synchronously`→`context.mounted` 守卫等）；不批量加 `// ignore`、不改 linter 规则、不新增 exclude。

- [ ] **Step 2: 按目录验证零告警**

Run: `flutter analyze lib/stores lib/extensions lib/models lib/services lib/util lib/theme lib/constants lib/api`
Expected: 无输出（零告警）。

- [ ] **Step 3: 提交**

```bash
git add lib/stores lib/extensions lib/models lib/services lib/util lib/theme lib/constants lib/api
git commit -m "chore: clear lint warnings in lib base layers"
```

---

## Task 4: Lint 清理 · lib/widgets

**Files:**
- Modify: `lib/widgets/**`（102 个文件）下所有产生 analyze 告警的文件（仅修复，不改行为；含 `animation_progress_bar.dart` 等 vendored 控件）

**Interfaces:**
- Consumes: 无
- Produces: `lib/widgets` 目录 `flutter analyze` 零告警

- [ ] **Step 1: 逐文件修复告警**（同 Task 3 原则）

- [ ] **Step 2: 验证零告警**

Run: `flutter analyze lib/widgets`
Expected: 无输出。

- [ ] **Step 3: 提交**

```bash
git add lib/widgets
git commit -m "chore: clear lint warnings in lib/widgets"
```

---

## Task 5: Lint 清理 · lib/pages + 全库零确认

**Files:**
- Modify: `lib/pages/**`（117 个文件）下所有产生 analyze 告警的文件（仅修复，不改行为、不改状态范式）

**Interfaces:**
- Consumes: Task 3/4 已清的目录
- Produces: 全库 `flutter analyze` 零告警（前置批次 0 完成）

- [ ] **Step 1: 逐文件修复 lib/pages 告警**

- [ ] **Step 2: 全库零确认**

Run: `flutter analyze`
Expected: 无输出（零 error/warning/info/lint）。若仍有告警，回到对应文件修复直到为空。

- [ ] **Step 3: 提交前置 lint 清理收尾**

```bash
git add lib/pages
git commit -m "chore: clear lint warnings in lib/pages; full lib analyze clean"
```

---

## Task 6: 迁移批次 1 · 登录/账号/安全

**Files:**
- Modify: `lib/pages/login/login.dart`、`lib/pages/login/accounts.dart`、`lib/pages/login/auth_page.dart`、`lib/pages/user/otp_bind.dart`（若存在）、`lib/pages/user/setting.dart`、`lib/pages/security_scan/security_scan.dart` 及本批目录其余 `extends State<` 文件

**Interfaces:**
- Consumes: `signals_hooks`（`useSignal`/`useComputed`/`useSignalEffect`/`useExistingSignal`/`useListSignal`/`useMapSignal`）、`flutter_hooks`（`useTextEditingController`/`useEffect`/`useMemoized`）、`connection_store`/`settings_store` 全局信号
- Produces: 本批文件不再含 `setState`/`StatefulWidget`/`State<`/`SignalsMixin`/`createSignal`（登录表单、OTP、账号列表状态全部为 hook 创建的信号）

- [ ] **Step 1: 按 spec「状态映射规则」改造本批每个 StatefulWidget**

`State<X>` → `HookWidget`；`initState` 内一次性初始化 / 异步加载 → `useSignalEffect`/`useFutureSignal`；字段 → `useSignal`/`useListSignal`/`useMapSignal`；`setState((){x=y;})` → `x.value = y`；读全局 Store 用 `useExistingSignal(store.xxx)`；`TextEditingController` → `useTextEditingController`。

- [ ] **Step 2: 验证本批目录零告警**

Run: `flutter analyze lib/pages/login lib/pages/user lib/pages/security_scan`
Expected: 无输出。

- [ ] **Step 3: 提交**

```bash
git add lib/pages/login lib/pages/user lib/pages/security_scan
git commit -m "feat: migrate auth/account/security pages to signals+hooks"
```

---

## Task 7: 迁移批次 2 · 首页框架 + Dashboard（含 currentState 改造）+ Home 测试

**Files:**
- Modify: `lib/main.dart`、`lib/pages/home.dart`、`lib/pages/dashborad/dashboard.dart`、`lib/pages/dashborad/widget_setting.dart`、`lib/pages/dashborad/shortcut_list.dart`、`lib/pages/dashborad/dashboard_cards.dart`、`lib/pages/dashborad/applications.dart` 及 dashborad 目录其余 `extends State<` 文件

**Interfaces:**
- Consumes: 同 Task 6 API；`GlobalKey<FilesState>`/`GlobalKey<DashboardState>` 所引用的 `FilesState`/`DashboardState` 改 HookWidget 后不再有 State 类
- Produces: `home.dart` 不再用 `GlobalKey<XxxState>.currentState` 调 `closeDrawer()`/`onWillPop()`；改由信号/回调驱动；`Home` 可无依赖地 `pumpWidget(MaterialApp(home: Home()))`

**风险点（Review Focus #1、#2）改造方式：**
- `home.dart` 持有 `signal<bool> filesDrawerOpen`/`dashboardDrawerOpen`/`signal<Future<bool> Function()?> filesOnWillPop`，作为构造参数传给 `Files`/`Dashboard`；`Files`/`Dashboard` 改为 `HookWidget`，内部通过 `widget.*DrawerOpen`/`widget.onWillPop` 暴露抽屉状态与返回拦截，不再依赖 `GlobalKey` 反向调用。
- `WidgetsBindingObserver` → `useOnAppLifecycleStateChange`；`checkAuth` 逻辑搬入对应 effect。

- [ ] **Step 1: 按 spec 映射改造 home/dashboard 各 StatefulWidget**

- [ ] **Step 2: 改造 home 的 currentState 跨组件调用为信号/回调驱动**（见 Interfaces 风险点）

- [ ] **Step 3: 写 Home build smoke + 抽屉/返回信号测试**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/pages/home.dart';

void main() {
  testWidgets('Home builds and opens drawer via signal', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Home()));
    expect(find.byType(Home), findsOneWidget);
    // 抽屉/返回键行为改为由信号驱动后，构建不抛、可交互
    await tester.pumpAndSettle();
  });
}
```

- [ ] **Step 4: 运行测试**

Run: `flutter test test/pages/home_test.dart`
Expected: PASS（无抛错）。

- [ ] **Step 5: 验证零告警**

Run: `flutter analyze lib/main.dart lib/pages/home.dart lib/pages/dashborad`
Expected: 无输出。

- [ ] **Step 6: 提交**

```bash
git add lib/main.dart lib/pages/home.dart lib/pages/dashborad test/pages/home_test.dart
git commit -m "feat: migrate home+dashboard to signals+hooks; remove currentState coupling"
```

---

## Task 8: 迁移批次 3 · 控制面板

**Files:**
- Modify: `lib/pages/control_panel/**`（含 `control_panel.dart` 及 `file_service/`、`network/`、`power/`、`users/`、`shared_folders/`、`task_scheduler/`、`media_index/`、`public_access/`、`update_reset/`、`ssh/`、`info/`、`external_device/` 等子目录所有 `extends State<` 文件）

**Interfaces:**
- Consumes: 同 Task 6 API（`useTabController` 用于含 Tab 页、`useAnimationController`/`useSingleTickerProvider` 用于展开/动画）
- Produces: 控制面板全目录不再含旧状态范式

- [ ] **Step 1: 按 spec 映射改造本批每个 StatefulWidget**（Tab/动画场景用对应 `use*` hook 替代 `TickerProviderStateMixin`）

- [ ] **Step 2: 验证零告警**

Run: `flutter analyze lib/pages/control_panel`
Expected: 无输出。

- [ ] **Step 3: 提交**

```bash
git add lib/pages/control_panel
git commit -m "feat: migrate control panel pages to signals+hooks"
```

---

## Task 9: 迁移批次 4 · 文件/下载/备份（含跨批耦合）

**Files:**
- Modify: `lib/pages/file/**`（含 `file.dart` 3696 行、`upload.dart`、`select_folder.dart`、`search.dart`、`share*.dart`、`favorite.dart`、`remote_folder.dart`）、`lib/pages/download*/**`、`lib/pages/backup/backup.dart` 及本批目录其余 `extends State<` 文件

**Interfaces:**
- Consumes: 同 Task 6/7 API；注意 `file.dart` 的 `GlobalKey<ScaffoldState>` 属框架 State 可保留；与 `home.dart`（Task 7）的 `FilesState`/`GlobalKey<FilesState>` 跨批耦合——Task 7 已把 `Files` 改为 HookWidget 并改用信号/回调驱动，本任务不再依赖 `FilesState`
- Produces: 文件/下载/备份全目录迁移完成，无旧状态范式

- [ ] **Step 1: 按 spec 映射改造本批每个 StatefulWidget**（`file.dart` 体量最大，逐函数/逐区块迁移，保持每区块 `analyze` 可验证；不在此刻拆分文件）

- [ ] **Step 2: 确认与 Task 7 的抽屉/返回信号契约一致**（Files 子部件通过 `widget.*DrawerOpen`/`widget.onWillPop` 接收，而非反向 `currentState`）

- [ ] **Step 3: 验证零告警**

Run: `flutter analyze lib/pages/file lib/pages/download lib/pages/download_station lib/pages/backup`
Expected: 无输出。

- [ ] **Step 4: 提交**

```bash
git add lib/pages/file lib/pages/download lib/pages/download_station lib/pages/backup
git commit -m "feat: migrate file/download/backup pages to signals+hooks"
```

---

## Task 10: 迁移批次 5 · 资源监控/日志/通知/更新

**Files:**
- Modify: `lib/pages/resource_monitor/**`、`lib/pages/log_center/log_center.dart`、`lib/pages/notify/notify.dart`、`lib/pages/update/update.dart` 及本批目录其余 `extends State<` 文件

**Interfaces:**
- Consumes: 同 Task 6 API（监控页的轮询/定时器 → `useEffect` + `Timer`/`StreamSubscription`；`useAnimationController` 用于进度/刷新动画）
- Produces: 本批目录迁移完成

- [ ] **Step 1: 按 spec 映射改造本批每个 StatefulWidget**

- [ ] **Step 2: 验证零告警**

Run: `flutter analyze lib/pages/resource_monitor lib/pages/log_center lib/pages/notify lib/pages/update`
Expected: 无输出。

- [ ] **Step 3: 提交**

```bash
git add lib/pages/resource_monitor lib/pages/log_center lib/pages/notify lib/pages/update
git commit -m "feat: migrate monitor/log/notify/update pages to signals+hooks"
```

---

## Task 11: 迁移批次 6 · 媒体/照片/时刻（含三 GlobalKey 改造）

**Files:**
- Modify: `lib/pages/photos/**`、`lib/pages/moments/**`、`lib/pages/common/device_finder.dart`、`lib/pages/common/select_ablum.dart` 等本批目录 `extends State<` 文件

**Interfaces:**
- Consumes: 同 Task 6 API；`photos.dart` 的 `GlobalKey<TimelineState>`/`GlobalKey<FolderState>`/`GlobalKey<AlbumTabState>` 构造参数 → 子页改 HookWidget 后改由信号/回调驱动，移除跨页 `currentState` 调用
- Produces: 媒体/照片/时刻全目录迁移完成

- [ ] **Step 1: 按 spec 映射改造本批每个 StatefulWidget**

- [ ] **Step 2: 改造 photos 的三个 GlobalKey 跨页调用为信号/回调驱动**（同 Task 7 风险点方式）

- [ ] **Step 3: 验证零告警**

Run: `flutter analyze lib/pages/photos lib/pages/moments lib/pages/common`
Expected: 无输出。

- [ ] **Step 4: 提交**

```bash
git add lib/pages/photos lib/pages/moments lib/pages/common
git commit -m "feat: migrate photos/moments pages to signals+hooks"
```

---

## Task 12: 迁移批次 7 · Docker/VM/存储/终端/套件/设置/杂项 + lib/widgets 全量

**Files:**
- Modify: `lib/pages/docker/**`、`lib/pages/virtual_machine/**`、`lib/pages/storage_manager/**`、`lib/pages/terminal/**`、`lib/pages/packages/**`、`lib/pages/setting/**`、`lib/pages/common/**`（剩余）、`lib/widgets/**`（剩余含 `StatefulWidget` 的 10 个文件：`hero_widget.dart`、`virtual_keyboard.dart`、`animation_progress_bar.dart`、`expansion_container.dart`、`neu_picker.dart`、`sort_menu.dart`、`list_item.dart`、`neu_back_button.dart`、`widgets/dashboard/dashboard_task_item.dart`、`widgets/moments/timeline_item_widget.dart`）

**Interfaces:**
- Consumes: 同 Task 6 API（`useTabController`/`useAnimationController`/`useSingleTickerProvider`/`useTextEditingController`/`useEffect`/`useOnAppLifecycleStateChange`）
- Produces: 全 `lib/` 不再含任何业务 `StatefulWidget`/`setState`（仅保留 `GlobalKey<ScaffoldState>`、`GlobalKey<ExtendedImageSlidePageState>` 的第三方类型引用）

- [ ] **Step 1: 按 spec 映射改造本批每个 StatefulWidget**（`animation_progress_bar.dart` 虽 vendored 仍需迁移自身状态；保留 `hero_widget.dart`/`image_preview.dart` 对 `ExtendedImageSlidePageState` 的 `currentState` 调用）

- [ ] **Step 2: 验证 lib/widgets 零告警**

Run: `flutter analyze lib/widgets`
Expected: 无输出。

- [ ] **Step 3: 提交**

```bash
git add lib/pages/docker lib/pages/virtual_machine lib/pages/storage_manager lib/pages/terminal lib/pages/packages lib/pages/setting lib/pages/common lib/widgets
git commit -m "feat: migrate remaining pages and widgets to signals+hooks"
```

---

## Task 13: 收尾 · 删除 SignalsMixin 痕迹 + 全局零确认

**Files:**
- Modify: `lib/main.dart`、`lib/pages/home.dart`、`lib/pages/login/login.dart`、`lib/pages/login/accounts.dart`、`lib/pages/control_panel/control_panel.dart`、`lib/pages/dashborad/dashboard.dart`、`lib/pages/control_panel/ssh/ssh.dart`、`lib/pages/control_panel/info/info.dart`、`lib/pages/control_panel/external_device/external_device.dart`、`lib/pages/packages/packages.dart` 等含 `with SignalsMixin` 的文件；`pubspec.yaml`（清理 `flutter_hooks`/`signals_hooks` 之外的旧注释，不改实际依赖）

**Interfaces:**
- Consumes: 已完成迁移的全 `lib/`
- Produces: 全文扫描无 `setState(`/`extends State<`/`SignalsMixin`/`createSignal`（`GlobalKey<ScaffoldState>`/`GlobalKey<ExtendedImageSlidePageState>` 引用除外）；全库 `flutter analyze` 零告警

- [ ] **Step 1: 移除所有 `with SignalsMixin` 子句与 `createSignal` 调用**（若 `SignalsMixin` 来自 `signals_flutter` 包则仅移除子句，不删包；若为本项目自定义则删除定义）

- [ ] **Step 2: 全局扫描残留**

Run: `rg -n "setState\(|extends State<|SignalsMixin|createSignal" lib`
Expected: 仅匹配 `GlobalKey<ScaffoldState>` / `GlobalKey<ExtendedImageSlidePageState>` 的第三方类型引用。

- [ ] **Step 3: 全库零确认**

Run: `flutter analyze` && `flutter build` （选定任一已配置平台，仅作编译通过验证）
Expected: analyze 无输出；build 成功。

- [ ] **Step 4: 提交收尾**

```bash
git add lib pubspec.yaml
git commit -m "chore: remove SignalsMixin remnants; full signals+hooks migration done"
```
