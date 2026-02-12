import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:garden/extensions/string.dart';
import 'package:garden/util/storage_util.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// 设置状态管理
///
/// 管理应用的各种设置选项
class SettingsStore {
  // ==================== 单例模式 ====================

  static final SettingsStore _instance = SettingsStore._internal();
  factory SettingsStore() => _instance;
  SettingsStore._internal();

  // ==================== 音频播放器 ====================

  final _player = signal<Player?>(null);
  final _audioUrl = signal<String>('');
  final _audioName = signal<String>('');

  ReadonlySignal<Player?> get player => _player;
  ReadonlySignal<String> get audioUrl => _audioUrl;
  ReadonlySignal<String> get audioName => _audioName;

  void setPlayer(Player player) {
    _player.value = player;
  }

  void setAudioUrl(String url, String name) {
    batch(() {
      _audioUrl.value = url;
      _audioName.value = name;
    });
  }

  // ==================== Apps====================
  final _isWechatInstalled = signal<bool>(false);
  ReadonlySignal<bool> get isWechatInstalled => _isWechatInstalled;

  void setIsWechatInstalled(bool isWechatInstalled) {
    _isWechatInstalled.value = isWechatInstalled;
  }

  // ==================== 系统信息（从 Util 迁移）====================

  final _dsmApiversion = signal<int>(6);
  final _appName = signal<String>('');
  final _firmwareVersion = signal<String>('');

  ReadonlySignal<int> get dsmApiVersion => _dsmApiversion;
  ReadonlySignal<String> get appName => _appName;
  ReadonlySignal<String> get firmwareVersion => _firmwareVersion;

  void setDsmApiVersion(int value) {
    _dsmApiversion.value = value;
  }

  void setAppName(String value) {
    _appName.value = value;
  }

  void setFirmwareVersion(String value) async {
    _firmwareVersion.value = value;
    await StorageUtil.setString("firmware_version", value);
  }

  // ==================== auth page ====================
  final launchAuth = computed(() async {
    return await StorageUtil.getBool("launch_auth") ?? false;
  });

  void setLaunchAuth(bool value) async {
    await StorageUtil.setBool("launch_auth", value);
  }

  final launchAuthPasswd = computed(() async {
    return await StorageUtil.getBool("launch_auth_passwd") ?? false;
  });

  void setLaunchAuthPasswd(bool value) async {
    await StorageUtil.setBool("launch_auth_passwd", value);
  }

  final launchAuthBiometric = computed(() async {
    return await StorageUtil.getBool("launch_auth_biometric") ?? false;
  });

  void setLaunchAuthBiometric(bool value) async {
    await StorageUtil.setBool("launch_auth_biometric", value);
  }

  final launchAccountPage = computed(() async {
    return await StorageUtil.getBool("launch_account_page") ?? false;
  });

  final authPage = computed(() async =>
      (await settingsStore.launchAuth.value) &&
      ((await settingsStore.launchAuthPasswd.value) ||
          (await settingsStore.launchAuthBiometric.value)));

  // ==================== 震动设置 ====================

  final _vibrateOn = signal<bool>(true);
  final _vibrateWarning = signal<bool>(true);
  final _vibrateNormal = signal<bool>(true);

  ReadonlySignal<bool> get vibrateOn => _vibrateOn;
  ReadonlySignal<bool> get vibrateWarning => _vibrateWarning;
  ReadonlySignal<bool> get vibrateNormal => _vibrateNormal;

  void setVibrateOn(bool value) => _vibrateOn.value = value;
  void setVibrateWarning(bool value) => _vibrateWarning.value = value;
  void setVibrateNormal(bool value) => _vibrateNormal.value = value;

  // ==================== Dashboard 设置 ====================

  final _dashboardCardCollapseSwitch = signal<bool>(true);
  final _dashboardCardCollapseState = signal<Map<String, bool>>({});

  ReadonlySignal<bool> get dashboardCardCollapseSwitch =>
      _dashboardCardCollapseSwitch;
  ReadonlySignal<Map<String, bool>> get dashboardCardCollapseState =>
      _dashboardCardCollapseState;

  void setDashboardCardCollapseSwitch(bool value) =>
      _dashboardCardCollapseSwitch.value = value;
  void setDashboardCardCollapseState(
      {Map<String, bool>? value, (String, bool)? item}) {
    if (value != null) {
      _dashboardCardCollapseState.value = value;
    } else if (item != null) {
      _dashboardCardCollapseState.update(item.$1, (ov) => item.$2,
          ifAbsent: () => item.$2);
    }
  }

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

  ReadonlySignal<String> get downloadSavePath => _downloadSavePath;
  ReadonlySignal<bool> get downloadWifiOnly => _downloadWifiOnly;

  void setDownloadSavePath(String value) => _downloadSavePath.value = value;
  void setDownloadWifiOnly(bool value) => _downloadWifiOnly.value = value;

  // ==================== 快捷方式 ====================

  final _showShortcut = signal<bool>(true);
  ReadonlySignal<bool> get showShortcut => _showShortcut;

  void setShowShortcut(bool showShortcut) async {
    _showShortcut.value = showShortcut;
    await StorageUtil.setBool("show_shortcut", showShortcut);
  }
  // ==================== 刷新设置 ====================

  final _refreshDuration = signal<int>(10);
  ReadonlySignal<int> get refreshDuration => _refreshDuration;

  void setRefreshDuration(int duration) async {
    _refreshDuration.value = duration;
    await StorageUtil.setInt("refresh_duration", duration);
  }

  // ==================== 壁纸 ====================

  final _showWallpaper = signal<bool>(true);
  ReadonlySignal<bool> get showWallpaper => _showWallpaper;

  void setShowWallpaper(bool showWallpaper) async {
    _showWallpaper.value = showWallpaper;
    await StorageUtil.setBool("show_wallpaper", showWallpaper);
  }

  // ==================== 深色模式 ====================

  /// 深色模式 0: 关闭 1: 开启 2: 随系统
  final _darkMode = signal<int>(2);
  ReadonlySignal<int> get darkMode => _darkMode;

  void setDarkMode(int darkMode) async {
    _darkMode.value = darkMode;
    await StorageUtil.setInt("dark_mode", darkMode);
  }
  // ==================== 初始化 ====================

  Future<void> initialize() async {
    final path = await StorageUtil.getString("download_save_path") ??
        await downloadTargetDir();
    setDownloadSavePath(path);
    final onyWifi = await StorageUtil.getBool("download_wifi_only");
    setDownloadWifiOnly(onyWifi ?? true);
    //震动开关
    final vibrateOn = await StorageUtil.getBool("vibrate_on");
    setVibrateOn(vibrateOn ?? true);

    final vibrateNormal = await StorageUtil.getBool("vibrate_normal");
    setVibrateNormal(vibrateNormal ?? true);

    final vibrateWarning = await StorageUtil.getBool("vibrate_warning");
    setVibrateWarning(vibrateWarning ?? true);

    final duration = await StorageUtil.getInt("refresh_duration");
    setRefreshDuration(duration ?? 10);

    final dm = await StorageUtil.getInt("dark_mode");
    setDarkMode(dm ?? 2);

    final ss = await StorageUtil.getBool("show_shortcut");
    setShowShortcut(ss ?? false);

    final sw = await StorageUtil.getBool("show_wallpaper");
    setShowWallpaper(sw ?? false);

    // 加载下载设置
    final downloadSavePathStr =
        await StorageUtil.getString("download_save_path");
    if (downloadSavePathStr != null) {
      if (downloadSavePathStr.isNotEmpty) {
        setDownloadSavePath(downloadSavePathStr);
      } else {
        if (Platform.isAndroid) {
          DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
          AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
          if (androidInfo.version.sdkInt < 30) {
            final directory = await getExternalStorageDirectory();
            setDownloadSavePath(
                "${directory?.path}${Platform.pathSeparator}Download${Platform.pathSeparator}DSM");
          } else {
            final directory = await getExternalStorageDirectory();

            setDownloadSavePath(
                "${directory?.path}${Platform.pathSeparator}Download${Platform.pathSeparator}DSM");
          }
        } else {
          final directory = await getApplicationDocumentsDirectory();
          setDownloadSavePath(
              "${directory.path}${Platform.pathSeparator}Download${Platform.pathSeparator}DSM");
        }
      }
    }

    final downloadWifiOnlyStr =
        await StorageUtil.getString("download_wifi_only");
    if (downloadWifiOnlyStr != null) {
      setDownloadWifiOnly(downloadWifiOnlyStr == "1");
    }
  }

  void dispose() {
    _downloadSavePath.dispose();
    _downloadWifiOnly.dispose();
    _showShortcut.dispose();
    _refreshDuration.dispose();
    _showWallpaper.dispose();
    _darkMode.dispose();

    _dashboardCardCollapseSwitch.dispose();
    _dashboardCardCollapseState.dispose();

    _isWechatInstalled.dispose();
    _dsmApiversion.dispose();
    _appName.dispose();
    _firmwareVersion.dispose();

    _vibrateOn.dispose();
    _vibrateNormal.dispose();
    _vibrateWarning.dispose();

    _player.dispose();
    _audioName.dispose();
    _audioUrl.dispose();
  }
}

// 全局实例
final settingsStore = SettingsStore();
