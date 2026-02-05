import 'package:signals_flutter/signals_flutter.dart';

/// 连接状态管理
/// 
/// 管理 DSM 服务器的连接信息
class ConnectionStore {
  // ==================== 单例模式 ====================
  
  static final ConnectionStore _instance = ConnectionStore._internal();
  factory ConnectionStore() => _instance;
  ConnectionStore._internal();

  // ==================== 连接状态 ====================
  
  final _sid = signal<String>('');
  final _account = signal<String>('');
  final _baseUrl = signal<String>('https://dang8080.quickconnect.to');
  final _hostname = signal<String>('');
  final _cookie = signal<String>('');
  final _checkSsl = signal<bool>(true);
  final _version = signal<int>(6);
  final _appName = signal<String>('');
  final _appUrl = signal<String>('https://dang8080.quickconnect.to');
  final _isAuthPage = signal<bool>(false);
  final _strings = signal<Map>({});
  final _notifyStrings = signal<Map>({});
  
  String get sid => _sid.value;
  String get account => _account.value;
  String get baseUrl => _baseUrl.value;
  String get hostname => _hostname.value;
  String get cookie => _cookie.value;
  bool get checkSsl => _checkSsl.value;
  int get version => _version.value;
  String get appName => _appName.value;
  String get appUrl => _appUrl.value;
  bool get isAuthPage => _isAuthPage.value;
  Map get strings => _strings.value;
  Map get notifyStrings => _notifyStrings.value;
  bool get notReviewAccount => _account.value != "jinx";
  
  void setSid(String value) => _sid.value = value;
  void setAccount(String value) => _account.value = value;
  void setBaseUrl(String value) => _baseUrl.value = value;
  void setHostname(String value) => _hostname.value = value;
  void setCookie(String value) => _cookie.value = value;
  void setCheckSsl(bool value) => _checkSsl.value = value;
  void setVersion(int value) => _version.value = value;
  void setAppName(String value) => _appName.value = value;
  void setAppUrl(String value) => _appUrl.value = value;
  void setIsAuthPage(bool value) => _isAuthPage.value = value;
  void setStrings(Map value) => _strings.value = value;
  void setNotifyStrings(Map value) => _notifyStrings.value = value;
  
  void clear() {
    _sid.value = '';
    _account.value = '';
    _cookie.value = '';
  }
}

// 全局实例
final connectionStore = ConnectionStore();