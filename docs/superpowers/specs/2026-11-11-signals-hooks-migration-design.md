# Signals + Flutter Hooks 全量迁移设计（第 1 项）

Date: 2026-11-11
Repo: `garden` (dsm_helper)，分支 `dsm_api_tidy`

## 意图与原因

项目里并存两套状态范式：少数页面已用 signals（`SignalsMixin + createSignal + .watch(context)`），绝大多数页面仍是 `StatefulWidget + setState`。目标是把**所有**状态管理统一到 signals，widget 层用 `HookWidget`（有状态/有生命周期）与 `StatelessWidget`（纯展示），controller、订阅、动画等对象的创建与销毁交给 `flutter_hooks` 官方 hook。

用户明确要求「全部」，包括动画帧数值、手势拖拽坐标、输入焦点、选中/展开、loading、列表数据等瞬时 UI 状态，**不允许**保留 UI-only 的 `setState`。同时要求迁移后代码符合 Flutter 规范、易于阅读。

用户指定的执行顺序：

1. **阶段一：迁移**。只换状态，不拆文件、不改命名、不加自研适配层、不改 UI。验收条件是「无误、没有报错」，用户已明确为 **`flutter analyze` 全库零告警**。
2. **阶段二：拆分使其易读**。在阶段一验收通过后，再按模块拆分巨型文件、统一命名。

## 目标

- `lib/` 内不再有 `setState`、`StatefulWidget`、`State<...>`、`SignalsMixin`、`createSignal`（第三方/框架自身的 State 类型**引用**除外）。
- `lib/pages/` 与 `lib/widgets/` 都在范围内：`lib/widgets/` 下约 10 个文件仍含 `setState`，一并迁移。
- 所有状态值都是 `Signal` / `Computed` / 集合 signal；共享状态继续放在 `connection_store` / `settings_store`。
- 有状态的 widget 用 `HookWidget`，通过 `signals_hooks` 官方 hook 创建 signal；纯展示 widget 用 `StatelessWidget`。
- `AnimationController` / `TabController` / `TextEditingController` / `ScrollController` / `FocusNode` / `StreamSubscription` / `WidgetsBindingObserver` 由 `flutter_hooks` 官方 hook 创建并在卸载时自动清理。
- 阶段一验收：`flutter analyze` 全库零告警（含既存告警清理），且全文扫描无残留状态范式。
- 阶段二：拆分粒度与命名规范另写设计（见「留给 builder」）。

## 非目标

- 不改变任何业务逻辑、API 调用参数、错误处理、数据模型、路由行为。
- 不新增依赖、不改版本。`signals_hooks 0.4.0` 依赖 `signals ^6.3.0` 与 `flutter_hooks >=0.18.0 <1.0.0`，与现有 pubspec 完全匹配。
- 不恢复 `backup/hook.dart`（它当年靠 `setState` 触发重建，本质是 Stateful 思路）。
- 不删除或替换 `lib/util/api.dart`（第 2 项处理）。
- 不做 UI 视觉改动、平台分流、页面补全（第 3 项处理）。
- **不做第 2 项**（whistle 抓包补全 dsmapi）与**第 3 项**（页面补全 + Material/Cupertino 分流）。它们是三个独立工程，按 1→2→3 顺序各写独立设计与计划。本设计只覆盖第 1 项。

## 反目标（做到了也算失败）

- 迁移后仍需两套状态范式，或用 `useState` 承担业务状态。
- 为了「全部 signal」把 `AnimationController`、`TextEditingController` 这类 Flutter 对象本身塞进 signal —— 不规范也不好读。约定：**「全部 signal」指状态值，Flutter 对象的生命周期交给 hooks**。
- 用脚本一次性机械替换，导致无法定位回归。
- 在阶段一顺手拆文件、改命名、改 UI，使 diff 爆炸、验收无法进行。

## 约束与现状

- 规模：85 个文件含 `setState`（约 460 处）、95 个文件有生命周期方法、约 120 个 State 类；`lib/pages/file/file.dart` 3696 行、`lib/pages/dashborad/dashboard_cards.dart` 1528 行。
- 27+ 个类带 `TickerProviderStateMixin` / `SingleTickerProviderStateMixin`，约 30 处 `AnimationController` / `vsync` → `useTabController` / `useAnimationController` / `useSingleTickerProvider` 已覆盖。
- `home.dart` 的 `WidgetsBindingObserver` → `useOnAppLifecycleStateChange` / `useAppLifecycleState`。
- **最硬的一处**：7 个 `currentState` 跨组件调用。`home.dart` 用 `GlobalKey<FilesState>` / `GlobalKey<DashboardState>` 调 `closeDrawer()` / `onWillPop()`，`photos.dart` 用三个 State GlobalKey。转成 `HookWidget` 后没有 State 类，必须改成 signal / 回调驱动。
- **豁免白名单（我的决定）**：豁免的是「第三方/框架的 State 类型引用」，不是整个文件。具体保留：`GlobalKey<ScaffoldState>`、`GlobalKey<ExtendedImageSlidePageState>` 及其 `currentState?.offset/scale/popPage()` 调用（`hero_widget.dart`、`common/image_preview.dart` 依赖 `extended_image` 包）。这些文件本身仍要迁移自己的状态。`lib/widgets/animation_progress_bar.dart` 虽是 `flutter_animation_progress_bar` 的拷贝，仍在范围内。
- `lib/widgets/` 里还有 `didUpdateWidget` 驱动的动画、`didChangeDependencies`、`SingleTickerProviderStateMixin` 等场景，迁移顺序上要先于或同批于引用它们的页面。
- 仓库没有 `.dart_tool`、没有 `pubspec.lock`；`flutter pub get` 属于安装依赖，**在设计批准后才执行**。pubspec 含多个 gitee git 依赖，`flutter pub get` 可能失败，需作为前置风险处理。
- 环境：Flutter 3.47.2 / Dart >=3.5.0。
- 历史文档 `docs/superpowers/specs/2026-03-26-signals-ui-alignment-design.md` 写过「按用户要求不跑 `flutter analyze`」；**本次用户明确推翻该约束**，要求 `flutter analyze` 全库零告警。以后者为准。

## 方案（三选一，已选 B）

| 方案 | 做法 | 取舍 |
|---|---|---|
| A | 建薄适配层 `lib/hooks/dsm_hooks.dart`（re-export 官方 API + `useLoad` / `usePersistentSignal`），按模块分批迁移，**同时**拆分巨型文件 | 一步到位满足「全部」+「易读」；代价是 diff 最大、周期最长、前期要先建抽象 |
| **B（已选）** | 直接用官方 `signals_hooks` / `flutter_hooks` API，按文件逐个迁移，**只换状态、不拆文件、不加自研层**；迁移验收通过后再单独做拆分 | 最贴近官方范式、diff 最小、零自研抽象、验证成本最低；代价是阶段一结束时 3696 行单文件仍难读，样板代码在 85 个文件里重复 |
| C | 用 `migration_script.dart` 脚本一次性机械全量替换 | **否决**：`vsync: this`、`WidgetsBindingObserver`、`initState` 异步、`didUpdateWidget`、`currentState` 调用都换不了；无 lock 基线，一次全改后无法定位回归 |

**选 B 的理由**：用户要先把迁移正确性验证到「无误、没有报错」，再做易读性拆分；B 让阶段一的 diff 只与状态有关，任何回归都能归因到状态替换。用户额外指定的「先迁移、后拆分」顺序，等价于把 A 的拆分部分挪到独立阶段，因此不需要 A 的适配层。

## 如何构建（已决定的部分）

### 状态映射规则

| 现状 | 迁移后 |
|---|---|
| 字段 `int/bool/String/List/Map/Set` | `useSignal` / `useListSignal` / `useMapSignal` / `useSetSignal` |
| 派生值 | `useComputed` |
| `setState(() { x = y; })` | `x.value = y`；集合用新集合赋值或集合 signal 的 API |
| 读局部 signal | `HookWidget.build` 内直接读 `.value`，`signals_hooks` 自动订阅并重建 |
| 读全局 Store 的 `ReadonlySignal` | `useExistingSignal(store.xxx)` 或 `Watch(...)` / `.watch(context)`（保持现有风格，具体选择留给 builder） |
| `initState` 一次性加载 | `useSignalEffect` / `useFutureSignal` / `useAsyncSignal`；loading 与 error 也是 signal |
| `PersistentSignalExt.read/save` | 在 keys 固定的 `useSignalEffect` 中调用，避免每次 build 重复 |
| `AnimationController(vsync: this)` / `TabController(vsync: this)` | `useAnimationController` / `useTabController` / `useSingleTickerProvider` |
| `TextEditingController` / `ScrollController` / `FocusNode` / `PageController` | 对应的 `use*` hook |
| `StreamSubscription` / `Timer` / 手动 `addListener` | `useEffect` 内创建并返回清理函数 |
| `WidgetsBindingObserver.didChangeAppLifecycleState` | `useOnAppLifecycleStateChange` |
| `didUpdateWidget` | `useSignalEffect` 依赖 widget 参数 |
| `dispose` | hook 自动清理 + `useEffect` 返回清理函数 |
| `GlobalKey<XxxState>.currentState?.method()` | 改为 signal / 回调驱动，不再依赖 State 类 |

### 文件结构

- 阶段一：不改文件路径、不抽公共组件、不新建目录、不改类名结构（除 `XxxState` 合并进 `HookWidget`）、不改命名、不改 UI。
- 阶段二：在阶段一验收通过后另写设计与计划，按模块拆分巨型 build、抽取子组件、统一命名。

### 迁移批次（我的决定）

每批一个 commit，每批复跑 `flutter analyze`：

0. **前置：`flutter pub get` + 全库 lint 清理**（我的决定）。因为验收线是「全库零告警」，既存告警必须在迁移开始前清到零，否则早期批次永远无法达标。此批只做不改变行为的 lint 修复，不动状态范式。
1. 登录 / 账号 / 安全（`login`, `accounts`, `auth_page`, `user/otp_bind`, `user/setting`, `security_scan`）
2. 首页与框架（`main.dart`, `home.dart`）与 dashboard（`dashborad/*`）
3. 控制面板（`control_panel/*`）
4. 文件 / 下载 / 备份（`file/*`, `download*`, `backup/*`）
5. 资源监控 / 日志 / 通知 / 更新
6. 媒体 / 照片 / 时刻（`photos/*`, `moments/*`, `common/*`）
7. Docker / 虚拟机 / 存储 / 终端 / 套件 / 设置 / 杂项 + `lib/widgets/` 全部剩余文件
8. 收尾：删除 `SignalsMixin` 痕迹、清理 `flutter_hooks` / `signals_hooks` 之外的旧依赖注释、全文扫描

**批次边界（我的决定）**：上表是功能分组，不是不可跨越的墙。`home.dart` 的 `GlobalKey<FilesState>` / `GlobalKey<DashboardState>` 与 `file.dart`、`download` 的 State 类跨批耦合，而阶段一禁止临时 shim；因此允许按依赖簇调整边界（把 `home` + `dashboard` + `file` + `download` 放进同一簇，或让同一文件在两批各改一次），由计划在 `writing-plans` 阶段定稿。原则是**每批结束时仍能通过验收命令**，最终态满足全文零残留扫描。

### 验证（阶段一验收）

- 前置（设计批准后第一步）：`flutter pub get` 生成 `pubspec.lock`。我的决定：把 `pubspec.lock` 提交进仓库（多平台项目需要锁版本）；若 `flutter pub get` 因 gitee 依赖失败，**停下报告**，不擅自改依赖、不降级验收。
- **验收口径（用户已定）：`flutter analyze` 全库零告警** —— 输出必须为空，零 error / warning / info / lint，不是「零新增」。首次基线会记录既存告警总数，那个数字只作为工作量与进度参考，不作为达标线。
- 这条口径让阶段一额外包含**清理全库既存 lint 告警**：335 个 Dart 文件、启用 `flutter_lints`，静态可见至少 44 处显式 `// ignore` 与 14 处 `print(`；`flutter analyze` 首次基线预计数百条。
- 处理原则（我的决定）：逐条修复，**不批量加 `// ignore`、不改 `analysis_options.yaml` 的 linter 规则、不新增 exclude**；确需保留的 ignore 必须逐条写明原因。具体修复方式留给 builder。`backup/hook.dart`、`migration_script.dart` 若产生告警，在计划阶段单独列出逐条处理，不擅自删除用户文件。
- `flutter test` 与 `flutter build` 不作为阶段一验收门槛（现有 `test/widget_test.dart` 是空的 `void main() {}`）。
- 阶段一完成标准：`rg -n "setState\(|extends State<|SignalsMixin|createSignal" lib` 无匹配（第三方 State 类型引用除外），且 `flutter analyze` 输出为空。

## 留给 builder

- 每个文件具体的 signal 字段划分、命名、`useExistingSignal` 与 `Watch` 的取舍。
- 批次内文件顺序、每个 commit 的粒度。
- `currentState` 调用改 signal / 回调的具体形态。
- 阶段二的拆分粒度与命名规范（另写设计）。
- 测试覆盖方式（现有 `test/` 只有一个 `widget_test.dart`）。

## 规模

项目级：约 85 个文件、120 个 State 类、460 处 `setState`，阶段一分 9 批（含前置 lint 清理）；阶段二拆分是验收通过后的独立阶段，规模取决于阶段一结果。

**范围放大说明**：「全库零告警」把阶段一从单纯的状态迁移，扩大成「前置全库 lint 清理 + 状态迁移」两件事。前者单独成批、先于所有状态改动。`flutter analyze` 首次基线跑出来后，如果既存告警数量大到让这一批失控，会停下来重新报规模，不默默吞掉。
