# Signals 迁移指南

## 概述

本文档说明如何将传统的单例模式（Java 风格）迁移到 Signals 状态管理，以提高代码的可维护性和响应性。

## 为什么要迁移？

### 传统单例模式的问题

1. **状态更新不透明**：直接修改实例变量，难以追踪状态变化
2. **无自动响应**：需要手动调用 `setState()` 来触发 UI 更新
3. **测试困难**：单例模式导致测试时状态难以隔离
4. **代码耦合**：多处直接访问 `Util.instance.xxx`，耦合度高

### Signals 的优势

1. **响应式**：状态变化自动触发 UI 更新
2. **类型安全**：编译时类型检查
3. **易于测试**：可以轻松创建独立实例
4. **性能优化**：细粒度的响应式更新，避免不必要的重建

## 迁移步骤

### 1. 识别可迁移的状态

在 `Util` 类中，以下状态适合迁移到 Signals：

#### 连接状态

```dart
// 传统方式
Util.instance.sid = "xxx";
Util.instance.account = "admin";

// Signals 方式
appStore.setSid("xxx");
appStore.setAccount("admin");
```

#### 用户设置

```dart
// 传统方式
Util.instance.vibrateOn = true;
Util.instance.darkMode = 2;

// Signals 方式
appStore.setVibrateOn(true);
appStore.changeMode(2);
```

#### UI 状态

```dart
// 传统方式
Util.instance.dashboardCardCollapseState = {...};
// 需要手动调用 setState()

// Signals 方式
appStore.toggleCardItemCollapse("itemName");
// 自动触发 UI 更新
```

### 2. UI 组件中使用 Signals

#### 使用 Watch 组件

```dart
// 传统方式
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(Util.instance.account);
  }
}

// Signals 方式
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      return Text(appStore.account);
    });
  }
}
```

#### 使用 computed 值

```dart
// 在 appStore 中添加
final notReviewAccount = computed(() => _account.value != "jinx");

// 在 UI 中使用
Watch((context) {
  if (appStore.notReviewAccount.value) {
    return PremiumWidget();
  }
  return FreeWidget();
})
```

### 3. 迁移示例

#### 示例 1：登录状态

**迁移前：**

```dart
// 在登录页面
await Api.login(...);
Util.instance.sid = response['sid'];
Util.instance.account = account;
setState(() {}); // 需要手动触发更新

// 在其他页面使用
Text(Util.instance.account)
```

**迁移后：**

```dart
// 在登录页面
await Api.login(...);
appStore.setSid(response['sid']);
appStore.setAccount(account);
// 自动触发所有使用这些状态的 UI 更新

// 在其他页面使用
Watch((context) {
  return Text(appStore.account);
})
```

#### 示例 2：设置页面

**迁移前：**

```dart
class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
    return Switch(
      value: Util.instance.vibrateOn,
      onChanged: (value) {
        setState(() {
          Util.instance.vibrateOn = value;
        });
      },
    );
  }
}
```

**迁移后：**

```dart
class SettingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      return Switch(
        value: appStore.vibrateOn,
        onChanged: (value) {
          appStore.setVibrateOn(value);
          // 不需要 setState()
        },
      );
    });
  }
}
```

## 已创建的 Store 类

### appStore

`appStore` 是 `AppStore` 的增强版本，包含了从 `Util` 类迁移过来的所有状态：

#### 连接状态

- `sid`: 会话 ID
- `account`: 账户名
- `baseUrl`: 基础 URL
- `hostname`: 主机名
- `cookie`: Cookie
- `checkSsl`: SSL 检查

#### 震动设置

- `vibrateOn`: 震动开关
- `vibrateWarning`: 警告震动
- `vibrateNormal`: 普通震动

#### Dashboard 设置

- `dashboardCardCollapseSwitch`: 卡片折叠开关
- `dashboardCardCollapseState`: 卡片折叠状态
- `isCardItemCollapsed()`: 检查卡片是否折叠
- `toggleCardItemCollapse()`: 切换卡片折叠状态

#### 下载设置

- `downloadSavePath`: 下载保存路径
- `downloadWifiOnly`: 仅 WiFi 下载
- `downloadKey`: 下载页面 Key

#### 其他

- `strings`: 字符串资源
- `notifyStrings`: 通知字符串
- `version`: 版本号
- `appName`: 应用名称
- `isAuthPage`: 是否为认证页面

## 迁移检查清单

- [ ] 识别所有使用 `Util.instance.xxx` 的地方
- [ ] 更新状态访问为使用 `appStore.xxx`
- [ ] 将需要响应式更新的 Widget 包裹在 `Watch()` 中
- [ ] 删除不必要的 `setState()` 调用
- [ ] 更新测试代码以使用 Signals
- [ ] 验证状态持久化是否正常工作
- [ ] 检查性能是否有改善

## 注意事项

### 1. 向后兼容

为了平滑迁移，建议保持 `Util` 类的状态同步：

```dart
void setSid(String value) {
  _sid.value = value;
  Util.instance.sid = value; // 保持同步
}
```

这样可以在逐步迁移的过程中，旧的代码仍然可以工作。

### 2. 避免循环依赖

确保 Store 之间没有循环依赖。如果需要，使用 computed signals 来计算派生状态。

### 3. 性能优化

对于频繁更新的状态，考虑使用 `debounce` 或 `throttle`：

```dart
import 'package:signals_flutter/signals_flutter.dart';

final _searchQuery = signal<String>('');
final searchResults = signal<List>([]);

_searchQuery.debounce(Duration(milliseconds: 300)).listen((query) {
  // 执行搜索
  performSearch(query);
});
```

## 下一步

1. **逐步迁移**：不要一次性迁移所有代码，按模块逐步进行
2. **充分测试**：确保迁移后功能正常
3. **更新文档**：更新相关文档和注释
4. **代码审查**：确保代码质量

## 参考资料

- [Signals 官方文档](https://dartsignals.dev/)
- [Flutter Signals 集成](https://pub.dev/packages/signals_flutter)
- [响应式编程最佳实践](https://dart.dev/guides/language/effective-dart/usage)
