import 'package:garden/util/storage_util.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:media_kit/media_kit.dart';

/// 应用全局状态管理
/// 
/// 使用 Signals 替代 Provider，提供更高效的状态管理
class AppStore {
  // ==================== 单例模式 ====================
  
  static final AppStore _instance = AppStore._internal();
  factory AppStore() => _instance;
  AppStore._internal();

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
  }
}

// 全局实例
final appStore = AppStore();