# Util 类迁移计划

## 目标

完全删除 `Util` 单例类，将其功能拆分到专门的工具类和 Signals Store 中。

## 迁移策略

### 1. 状态管理 → Signals Store

将 `Util` 类中的所有可变状态迁移到 Signals Store：

#### ConnectionStore (lib/stores/connection_store.dart)
```dart
// 迁移前
Util.instance.sid = "xxx";
Util.instance.account = "admin";

// 迁移后
connectionStore.setSid("xxx");
connectionStore.setAccount("admin");
```

#### SettingsStore (lib/stores/settings_store.dart)
```dart
// 迁移前
Util.instance.vibrateOn = true;
Util.instance.dashboardCardCollapseState = {...};

// 迁移后
settingsStore.setVibrateOn(true);
settingsStore.toggleCardItemCollapse("itemName");
```

### 2. 工具方法 → 静态工具类

将 `Util` 类中的纯方法迁移到专门的静态工具类：

#### StorageUtil (lib/util/storage_util.dart)
```dart
// 迁移前
await Util.instance.setStorage("key", "value");
String? value = await Util.instance.getStorage("key");

// 迁移后
await StorageUtil.setString("key", "value");
String? value = await StorageUtil.getString("key");
```

#### UiUtil (lib/util/ui_util.dart)
```dart
// 迁移前
Util.instance.toast("提示信息");
Util.instance.vibrate(FeedbackType.light);

// 迁移后
UiUtil.toast("提示信息");
UiUtil.vibrate(FeedbackType.light);
```

#### FormatUtil (lib/util/format_util.dart)
```dart
// 迁移前
Util.instance.formatSize(1024 * 1024);
Util.instance.parseOpTime("120:30:15");

// 迁移后
FormatUtil.formatSize(1024 * 1024);
FormatUtil.parseOpTime("120:30:15");
```

#### FileTypeUtil (lib/util/file_type_util.dart)
```dart
// 迁移前
Util.instance.fileType("image.png");
Util.instance.isImage("photo.jpg");

// 迁移后
FileTypeUtil.getFileType("image.png");
FileTypeUtil.isImage("photo.jpg");
```

## 迁移步骤

### 第一阶段：创建新的工具类和 Store ✅

- [x] 创建 `ConnectionStore`
- [x] 创建 `SettingsStore`
- [x] 创建 `StorageUtil`
- [x] 创建 `UiUtil`
- [x] 创建 `FormatUtil`
- [x] 创建 `FileTypeUtil`

### 第二阶段：全局搜索替换

```bash
# 搜索所有使用 Util.instance 的地方
rg "Util\.instance\." lib/pages --dart

# 逐个文件替换
```

#### 替换规则

**连接相关：**
```dart
Util.instance.sid → connectionStore.sid
Util.instance.account → connectionStore.account
Util.instance.baseUrl → connectionStore.baseUrl
Util.instance.hostname → connectionStore.hostname
Util.instance.cookie → connectionStore.cookie
Util.instance.checkSsl → connectionStore.checkSsl
Util.instance.notReviewAccount → connectionStore.notReviewAccount
```

**设置相关：**
```dart
Util.instance.vibrateOn → settingsStore.vibrateOn
Util.instance.vibrateWarning → settingsStore.vibrateWarning
Util.instance.vibrateNormal → settingsStore.vibrateNormal
Util.instance.dashboardCardCollapseSwitch → settingsStore.dashboardCardCollapseSwitch
Util.instance.dashboardCardCollapseState → settingsStore.dashboardCardCollapseState
Util.instance.downloadSavePath → settingsStore.downloadSavePath
Util.instance.downloadWifiOnly → settingsStore.downloadWifiOnly
```

**工具方法：**
```dart
Util.instance.setStorage → StorageUtil.setString
Util.instance.getStorage → StorageUtil.getString
Util.instance.removeStorage → StorageUtil.remove
Util.instance.toast → UiUtil.toast
Util.instance.vibrate → UiUtil.vibrate
Util.instance.formatSize → FormatUtil.formatSize
Util.instance.parseOpTime → FormatUtil.parseOpTime
Util.instance.timeLong → FormatUtil.timeLong
Util.instance.fileType → FileTypeUtil.getFileType
```

### 第三阶段：UI 组件更新

#### 在需要响应式更新的地方使用 Watch

```dart
// 迁移前
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return Text(Util.instance.account);
  }
}

// 迁移后
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      return Text(connectionStore.account);
    });
  }
}
```

### 第四阶段：删除 Util 类

在确认所有引用都已替换后：

1. 删除 `lib/util/function.dart` 中的 `Util` 类
2. 运行 `flutter analyze` 检查是否有遗漏
3. 运行测试确保功能正常

## 迁移检查清单

### 状态迁移
- [ ] ConnectionStore 中的所有状态都已迁移
- [ ] SettingsStore 中的所有状态都已迁移
- [ ] 所有状态访问都使用 Watch 包裹（如需要响应式更新）

### 工具方法迁移
- [ ] StorageUtil 已替换所有存储相关调用
- [ ] UiUtil 已替换所有 UI 相关调用
- [ ] FormatUtil 已替换所有格式化相关调用
- [ ] FileTypeUtil 已替换所有文件类型相关调用

### 代码质量
- [ ] 没有 `Util.instance` 的引用
- [ ] 所有静态工具类都已正确导入
- [ ] 所有 Store 都已正确导入
- [ ] 代码通过 `flutter analyze` 检查
- [ ] 功能测试通过

## 注意事项

### 1. 向后兼容

在迁移过程中，可以暂时保留 `Util` 类作为代理：

```dart
class Util {
  // 代理到 ConnectionStore
  static String get sid => connectionStore.sid;
  static set sid(String value) => connectionStore.setSid(value);
  
  // 代理到 SettingsStore
  static bool get vibrateOn => settingsStore.vibrateOn;
  static set vibrateOn(bool value) => settingsStore.setVibrateOn(value);
  
  // 代理到静态工具类
  static Future<bool> setStorage(String name, String value) => 
    StorageUtil.setString(name, value);
  
  static String? getStorage(String name) => 
    StorageUtil.getString(name);
}
```

这样可以逐步迁移，最后再删除代理。

### 2. 测试策略

- 单元测试：测试每个工具类和 Store
- 集成测试：测试迁移后的功能
- UI 测试：确保 UI 正确响应状态变化

### 3. 性能考虑

- Signals 的细粒度更新性能优于全局 setState
- 静态工具类无性能开销
- 避免在 Watch 中执行耗时操作

## 迁移后的代码结构

```
lib/
├── stores/
│   ├── app_store.dart           # 原有的 AppStore
│   ├── connection_store.dart    # 新增：连接状态
│   └── settings_store.dart      # 新增：应用设置
├── util/
│   ├── storage_util.dart        # 新增：存储工具
│   ├── ui_util.dart             # 新增：UI 工具
│   ├── format_util.dart         # 新增：格式化工具
│   ├── file_type_util.dart      # 新增：文件类型工具
│   ├── api.dart                 # 保留：API 工具
│   ├── log.dart                 # 保留：日志工具
│   └── ...
└── ...
```

## 预期收益

1. **代码更清晰**：职责分离，每个类都有明确的职责
2. **更易测试**：静态工具类和独立的 Store 更容易测试
3. **性能更好**：Signals 的响应式更新更高效
4. **更易维护**：删除了庞大的 Util 类，代码更模块化
5. **类型安全**：编译时类型检查，减少运行时错误

## 下一步行动

1. 开始全局搜索替换
2. 逐步迁移各个模块
3. 充分测试
4. 删除 Util 类
5. 更新文档