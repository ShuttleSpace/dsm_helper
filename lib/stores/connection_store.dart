import 'package:garden/constants/app_constants.dart';
import 'package:garden/util/storage_util.dart';
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
  final _baseUri = signal<String>('https://dang8080.quickconnect.to');
  final _hostname = signal<String>('');
  final _cookie = signal<String>('');
  final _synoToken = signal<String>('');
  final _checkSsl = signal<bool>(true);
  final _dsmVersion = signal<int>(6);
  final _appName = signal<String>(AppConstants.appName);
  final _appUrl = signal<String>('https://dang8080.quickconnect.to');
  // FIXME: desktop init data strings???
  final _strings = signal<Map>({});
  final _notifies = signal<Map>({});

  ReadonlySignal<String> get sid => _sid;
  ReadonlySignal<String> get account => _account;
  ReadonlySignal<String> get baseUri => _baseUri;
  ReadonlySignal<String> get hostname => _hostname;
  ReadonlySignal<String> get cookie => _cookie;
  ReadonlySignal<bool> get checkSsl => _checkSsl;
  ReadonlySignal<int> get dsmVersion => _dsmVersion;
  ReadonlySignal<String> get appName => _appName;
  ReadonlySignal<String> get appUrl => _appUrl;
  ReadonlySignal<Map> get strings => _strings;
  ReadonlySignal<Map> get notifyStrings => _notifies;
  ReadonlySignal<bool> get notVisitorAccount =>
      computed(() => _account.value != "__**__Visitor__**__");
  ReadonlySignal<String> get synoToken => _synoToken;

  void setSid(String value) => _sid.value = value;
  void setAccount(String value) => _account.value = value;
  void setBaseUri(String value) => _baseUri.value = value;
  void setHostname(String value) => _hostname.value = value;
  void setCookie(String value) async {
    _cookie.value = value;
    // TODO: cookie name???
    await StorageUtil.setString("smid", value);
  }

  void setSynoToken(String value) async {
    _synoToken.value = value;
    await StorageUtil.setString("syno_token", value);
  }

  void setCheckSsl(bool value) async {
    _checkSsl.value = value;
    await StorageUtil.setBool("check_ssl", value);
  }

  void setVersion(int value) => _dsmVersion.value = value;
  void setAppName(String value) => _appName.value = value;
  void setAppUrl(String value) => _appUrl.value = value;
  void setStrings(Map value) => _strings.value = value;
  void setNotifies(Map value) => _notifies.value = value;

  void clear() {
    batch(() {
      _sid.value = '';
      _account.value = '';
      _cookie.value = '';
    });
  }

  Future<void> initialize() async {
    final checkSsl = await StorageUtil.getBool("check_ssl");
    connectionStore.setCheckSsl(checkSsl ?? true);
  }

  void dispose() {
    _sid.dispose();
    _account.dispose();
    _baseUri.dispose();
    _hostname.dispose();
    _cookie.dispose();
    _checkSsl.dispose();
    _dsmVersion.dispose();
    _appName.dispose();
    _appUrl.dispose();
    _strings.dispose();
    _notifies.dispose();
  }
}

// 全局实例
final connectionStore = ConnectionStore();
