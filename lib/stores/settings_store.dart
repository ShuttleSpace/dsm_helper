import 'package:signals_flutter/signals_flutter.dart';

/// 设置状态管理
/// 
/// 管理应用的各种设置选项
class SettingsStore {
  // ==================== 单例模式 ====================
  
  static final SettingsStore _instance = SettingsStore._internal();
  factory SettingsStore() => _instance;
  SettingsStore._internal();

  // ==================== 震动设置 ====================
  
  final _vibrateOn = signal<bool>(true);
  final _vibrateWarning = signal<bool>(true);
  final _vibrateNormal = signal<bool>(true);
  
  bool get vibrateOn => _vibrateOn.value;
  bool get vibrateWarning => _vibrateWarning.value;
  bool get vibrateNormal => _vibrateNormal.value;
  
  void setVibrateOn(bool value) => _vibrateOn.value = value;
  void setVibrateWarning(bool value) => _vibrateWarning.value = value;
  void setVibrateNormal(bool value) => _vibrateNormal.value = value;

  // ==================== Dashboard 设置 ====================
  
  final _dashboardCardCollapseSwitch = signal<bool>(true);
  final _dashboardCardCollapseState = signal<Map<String, bool>>({});
  
  bool get dashboardCardCollapseSwitch => _dashboardCardCollapseSwitch.value;
  Map<String, bool> get dashboardCardCollapseState => _dashboardCardCollapseState.value;
  
  void setDashboardCardCollapseSwitch(bool value) => _dashboardCardCollapseSwitch.value = value;
  void setDashboardCardCollapseState(Map<String, bool> value) => _dashboardCardCollapseState.value = value;
  
  bool isCardItemCollapsed(String itemName) {
    return _dashboardCardCollapseState.value[itemName] ?? false;
  }
  
  void toggleCardItemCollapse(String itemName) {
    final newState = Map<String, bool>.from(_dashboardCardCollapseState.value);
    newState[itemName] = !(newState[itemName] ?? false);
    _dashboardCardCollapseState.value = newState;
  }

  // ==================== 下载设置 ====================
  
  final _downloadSavePath = signal<String>('');
  final _downloadWifiOnly = signal<bool>(true);
  
  String get downloadSavePath => _downloadSavePath.value;
  bool get downloadWifiOnly => _downloadWifiOnly.value;
  
  void setDownloadSavePath(String value) => _downloadSavePath.value = value;
  void setDownloadWifiOnly(bool value) => _downloadWifiOnly.value = value;

  // ==================== 初始化 ====================
  
  Future<void> initialize() async {
    // 从本地存储加载设置
    // 这里需要调用 StorageUtil 来读取持久化设置
    // await _loadVibrateSettings();
    // await _loadDownloadSettings();
  }
}

// 全局实例
final settingsStore = SettingsStore();