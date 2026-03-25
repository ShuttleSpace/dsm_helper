# Signals 全量迁移设计（dsm_api_tidy）

## 目标
- 以 `~/Project/Flutter/dsm_helper` 为对照基线，对齐 signals 迁移模式与结构。
- 将当前 worktree 所有残留 `provider/setState` 使用迁移到 `signals`。
- 允许少量“纯 UI 瞬时状态”继续使用 `setState`。
- 可复用 UI 抽取到 `lib/widgets/common/`，避免重复实现。

## 范围
- 全部 `provider` 与 `setState` 使用点（含页面、组件、状态管理、网络/下载/通知等）。
- 已迁移的 dashboard 与 http api 只做对齐补齐，不回滚、不改行为。
- 仅进行与迁移相关的重构，不做功能扩展。

## 约束与原则
- 行为对齐 `dsm_helper`：优先采用其实现方式、命名与组织结构。
- 抽取组件只包含 UI 逻辑与参数，不直接依赖全局 Store（除非 `dsm_helper` 同样如此）。
- 对共享/持久状态使用 Store + signals；对短期 UI 状态保留 `setState` 或局部 signal。
- 迁移过程不引入新依赖，沿用现有 `signals_flutter`。

## 迁移策略
### 1. 盘点与分组
- 枚举所有 `setState` 与 `provider` 使用点。
- 按模块分组（登录、设置、下载、通知、存储管理、控制面板、终端等）。

### 2. 状态归类
- **共享/持久状态**：迁入 Store（如 `connection_store`, `settings_store`，或新 Store）。
- **页面级状态**：使用局部 signal 或页面私有 Store。
- **短时 UI 状态**（动画/手势过程）：允许保留 `setState`。

### 3. 对齐 dsm_helper
- 对应文件逐个对比，优先采用 dsm_helper 的 signals 迁移方式。
- 保持 API/方法命名一致，减少两项目分叉。

### 4. 抽取公共组件
- 识别 2+ 页面重复 UI。
- 抽到 `lib/widgets/common/`，只保留必要参数与回调。

## 组件/模块边界
- Store：仅负责状态、持久化、异步加载；不直接操作 UI。
- 页面：通过 `Watch` 订阅信号，触发 UI 更新。
- 公共组件：无业务依赖、无全局单例访问（除非基线也这样）。

## 错误与边界处理
- 迁移过程中保持原逻辑错误处理行为（提示、日志、回滚）。
- signals 更新需保持同步时序与原 setState 触发时机一致。

## 验证
- 代码可编译通过。
- 核心流程（登录/下载/设置/通知/终端/控制面板）行为与 `dsm_helper` 对齐。
- UI 刷新与状态联动正常，无丢失更新。

