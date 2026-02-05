import 'package:flutter/material.dart';
import 'package:garden/util/storage_util.dart';
import 'package:garden/stores/settings_store.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/pages/download/download.dart';
import 'package:garden/util/http_util.dart';
import 'package:media_kit/media_kit.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// 应用全局状态管理（增强版）
///
/// 使用 Signals 替代 Provider 和传统的单例模式
/// 将 Util 类中的可变状态迁移到 signals
class AppStoreV2 {
  // ==================== 单例模式 ====================

  static final AppStoreV2 _instance = AppStoreV2._internal();
  factory AppStoreV2() => _instance;
  AppStoreV2._internal();

  // ==================== 刷新设置 ====================

  final _refreshDuration = signal<int>(10);
  int get refreshDuration => _refreshDuration.value;

  void setRefreshDuration(int duration) async {
    _refreshDuration.value = duration;
    await StorageUtil.setString("refresh_duration", duration.toString());
  }

  // ==================== 深色模式 ====================

  /// 深色模式 0: 关闭 1: 开启 2: 随系统
  final _darkMode = signal<int>(2);
  int get darkMode => _darkMode.value;

  void changeMode(int darkMode) async {
    _darkMode.value = darkMode;
    await StorageUtil.setString("dark_mode", darkMode.toString());
  }

  // ==================== 快捷方式 ====================

  final _showShortcut = signal<bool>(true);
  bool get showShortcut => _showShortcut.value;

  void changeShortcut(bool showShortcut) async {
    _showShortcut.value = showShortcut;
    await StorageUtil.setString("show_shortcut", showShortcut ? "1" : "0");
  }

  // ==================== 壁纸 ====================

  final _showWallpaper = signal<bool>(true);
  bool get showWallpaper => _showWallpaper.value;

  void changeWallpaper(bool showWallpaper) async {
    _showWallpaper.value = showWallpaper;
    await StorageUtil.setString("show_wallpaper", showWallpaper ? "1" : "0");
  }

  // ==================== 音频播放器 ====================

  final _player = signal<Player?>(null);
  final _audioUrl = signal<String>('');
  final _audioName = signal<String>('');

  Player? get player => _player.value;
  String get audioUrl => _audioUrl.value;
  String get audioName => _audioName.value;

  void setPlayer(Player player) {
    _player.value = player;
  }

  void setAudioUrl(String url, String name) {
    _audioUrl.value = url;
    _audioName.value = name;
  }

  // ==================== 连接状态（从 Util 迁移）====================

  final _sid = signal<String>('');
  final _account = signal<String>('');
  final _baseUrl = signal<String>('https://dang8080.quickconnect.to');
  final _hostname = signal<String>('');
  final _cookie = signal<String>('');
  final _checkSsl = signal<bool>(true);

  String get sid => _sid.value;
  String get account => _account.value;
  String get baseUrl => _baseUrl.value;
  String get hostname => _hostname.value;
  String get cookie => _cookie.value;
  bool get checkSsl => _checkSsl.value;
  bool get notReviewAccount => _account.value != "jinx";

  void setSid(String value) {
    _sid.value = value;
    connectionStore.setSid(value);
  }

  void setAccount(String value) {
    _account.value = value;
    connectionStore.setAccount(value);
  }

  void setBaseUrl(String value) {
    _baseUrl.value = value;
    connectionStore.setBaseUrl(value);
  }

  void setHostname(String value) {
    _hostname.value = value;
    connectionStore.setHostname(value);
  }

  void setCookie(String value) {
    _cookie.value = value;
    connectionStore.setCookie(value);
  }

  void setCheckSsl(bool value) {
    _checkSsl.value = value;
    connectionStore.setCheckSsl(value);
  }

  // ==================== 震动设置（从 Util 迁移）====================

  final _vibrateOn = signal<bool>(true);
  final _vibrateWarning = signal<bool>(true);
  final _vibrateNormal = signal<bool>(true);

  bool get vibrateOn => _vibrateOn.value;
  bool get vibrateWarning => _vibrateWarning.value;
  bool get vibrateNormal => _vibrateNormal.value;

  void setVibrateOn(bool value) async {
    _vibrateOn.value = value;
    settingsStore.setVibrateOn(value);
    await StorageUtil.setString("vibrate_on", value ? "1" : "0");
  }

  void setVibrateWarning(bool value) async {
    _vibrateWarning.value = value;
    settingsStore.setVibrateWarning(value);
    await StorageUtil.setString("vibrate_warning", value ? "1" : "0");
  }

  void setVibrateNormal(bool value) async {
    _vibrateNormal.value = value;
    settingsStore.setVibrateNormal(value);
    await StorageUtil.setString("vibrate_normal", value ? "1" : "0");
  }

  // ==================== Dashboard 设置（从 Util 迁移）====================

  final _dashboardCardCollapseSwitch = signal<bool>(true);
  final _dashboardCardCollapseState = signal<Map<String, bool>>({});

  bool get dashboardCardCollapseSwitch => _dashboardCardCollapseSwitch.value;
  Map<String, bool> get dashboardCardCollapseState =>
      _dashboardCardCollapseState.value;

  void setDashboardCardCollapseSwitch(bool value) {
    _dashboardCardCollapseSwitch.value = value;
    settingsStore.setDashboardCardCollapseSwitch(value);
  }

  void setDashboardCardCollapseState(Map<String, bool> value) {
    _dashboardCardCollapseState.value = value;
    settingsStore.setDashboardCardCollapseState(value);
  }

  bool isCardItemCollapsed(String itemName) {
    return _dashboardCardCollapseState.value[itemName] ?? false;
  }

  void toggleCardItemCollapse(String itemName) {
    final newState = Map<String, bool>.from(_dashboardCardCollapseState.value);
    newState[itemName] = !(newState[itemName] ?? false);
    _dashboardCardCollapseState.value = newState;
    settingsStore.setDashboardCardCollapseState(newState);
  }

  // ==================== 下载设置（从 Util 迁移）====================

  final _downloadSavePath = signal<String>('');
  final _downloadWifiOnly = signal<bool>(true);
  final _downloadKey = signal<GlobalKey<DownloadState>?>(null);

  String get downloadSavePath => _downloadSavePath.value;
  bool get downloadWifiOnly => _downloadWifiOnly.value;
  GlobalKey<DownloadState>? get downloadKey => _downloadKey.value;

  void setDownloadSavePath(String value) async {
    _downloadSavePath.value = value;
    settingsStore.setDownloadSavePath(value);
    await StorageUtil.setString("download_save_path", value);
  }

  void setDownloadWifiOnly(bool value) async {
    _downloadWifiOnly.value = value;
    settingsStore.setDownloadWifiOnly(value);
    await StorageUtil.setString("download_wifi_only", value ? "1" : "0");
  }

  void setDownloadKey(GlobalKey<DownloadState> key) {
    _downloadKey.value = key;
    HttpUtil.instance.downloadKey = key;
  }

  // ==================== 字符串资源（从 Util 迁移）====================

  final _strings = signal<Map>({});
  final _notifyStrings = signal<Map>({});

  Map get strings => _strings.value;
  Map get notifyStrings => _notifyStrings.value;

  void setStrings(Map value) {
    _strings.value = value;
    connectionStore.setStrings(value);
  }

  void setNotifyStrings(Map value) {
    _notifyStrings.value = value;
    connectionStore.setNotifyStrings(value);
  }

  // ==================== 系统信息（从 Util 迁移）====================

  final _version = signal<int>(6);
  final _appName = signal<String>('');

  int get version => _version.value;
  String get appName => _appName.value;

  void setVersion(int value) {
    _version.value = value;
    connectionStore.setVersion(value);
  }

  void setAppName(String value) {
    _appName.value = value;
    connectionStore.setAppName(value);
  }

  // ==================== 认证状态 ====================

  final _isAuthPage = signal<bool>(false);

  bool get isAuthPage => _isAuthPage.value;

  void setIsAuthPage(bool value) {
    _isAuthPage.value = value;
    connectionStore.setIsAuthPage(value);
  }

  // ==================== 初始化 ====================

  Future<void> initialize() async {
    // 从本地存储加载设置
    final refreshDurationStr = await StorageUtil.getString("refresh_duration");
    if (refreshDurationStr != null) {
      _refreshDuration.value = int.tryParse(refreshDurationStr) ?? 10;
    }

    final darkModeStr = await StorageUtil.getString("dark_mode");
    if (darkModeStr != null) {
      _darkMode.value = int.tryParse(darkModeStr) ?? 2;
    }

    final showShortcutStr = await StorageUtil.getString("show_shortcut");
    if (showShortcutStr != null) {
      _showShortcut.value = showShortcutStr == "1";
    }

    final showWallpaperStr = await StorageUtil.getString("show_wallpaper");
    if (showWallpaperStr != null) {
      _showWallpaper.value = showWallpaperStr == "1";
    }

    // 加载震动设置
    final vibrateOnStr = await StorageUtil.getString("vibrate_on");
    if (vibrateOnStr != null) {
      _vibrateOn.value = vibrateOnStr == "1";
    }

    final vibrateWarningStr = await StorageUtil.getString("vibrate_warning");
    if (vibrateWarningStr != null) {
      _vibrateWarning.value = vibrateWarningStr == "1";
    }

    final vibrateNormalStr = await StorageUtil.getString("vibrate_normal");
    if (vibrateNormalStr != null) {
      _vibrateNormal.value = vibrateNormalStr == "1";
    }

    // 加载下载设置
    final downloadSavePathStr =
        await StorageUtil.getString("download_save_path");
    if (downloadSavePathStr != null) {
      _downloadSavePath.value = downloadSavePathStr;
    }

    final downloadWifiOnlyStr =
        await StorageUtil.getString("download_wifi_only");
    if (downloadWifiOnlyStr != null) {
      _downloadWifiOnly.value = downloadWifiOnlyStr == "1";
    }
  }
}

// 全局实例
final appStoreV2 = AppStoreV2();
