import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/models/api_model.dart';
import 'package:garden/stores/connection_store.dart';

/// Task 5: 固定 15 个 compound + 17 个 quirk 旧方法的请求体与返回信封契约。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'), (call) async {
    if (call.method == 'getApplicationDocumentsDirectory') return '/tmp';
    return null;
  });
  Map<String, dynamic> fakeResponse = {};
  String? capturedEndpoint;
  Map<String, dynamic>? capturedData;

  setUp(() {
    capturedEndpoint = null;
    capturedData = null;
    fakeResponse = {
      'success': true,
      'data': {
        'result': [
          {'success': true, 'api': 'SYNO.Core.System', 'data': {'model': 'DS'}},
          {
            'success': false,
            'api': 'SYNO.Core.Hardware.ZRAM',
            'error': {'code': 102}
          },
        ]
      },
    };
    compatPostForTesting = (endpoint, {data}) async {
      capturedEndpoint = endpoint;
      capturedData = data;
      return fakeResponse;
    };
  });

  tearDown(() {
    compatPostForTesting = null;
    connectionStore.setVersion(6);
  });

  Map<String, dynamic> sent() {
    expect(capturedData, isNotNull, reason: 'compat 方法应发出一次 POST');
    return capturedData!;
  }

  List compoundApis() => jsonDecode(sent()['compound'] as String) as List;

  void expectCompoundEnvelope({
    required List expectedApis,
    required String mode,
    bool? stopWhenError,
  }) {
    expect(capturedEndpoint, 'webapi/entry.cgi');
    final data = sent();
    expect(data['api'], 'SYNO.Entry.Request');
    expect(data['method'], 'request');
    expect(data['version'], 1);
    expect(data['mode'], mode);
    expect(data['_sid'], connectionStore.sid.value);
    if (stopWhenError == null) {
      expect(data.containsKey('stop_when_error'), isFalse,
          reason: '旧方法未设置 stop_when_error');
    } else {
      expect(data['stop_when_error'], stopWhenError);
    }
    expect(compoundApis(), equals(expectedApis));
  }

  group('compound 请求体与整包返回契约', () {
    test('systemInfo 全 widget 时 compound 顺序与字段与旧版一致', () async {
      final result = await DsmApi.systemInfo(const [
        'SYNO.SDS.ResourceMonitor.Widget',
        'SYNO.SDS.SystemInfoApp.StorageUsageWidget',
        'SYNO.SDS.SystemInfoApp.ConnectionLogWidget',
        'SYNO.SDS.TaskScheduler.TaskSchedulerWidget',
        'SYNO.SDS.SystemInfoApp.RecentLogWidget',
        'SYNO.SDS.SystemInfoApp.FileChangeLogWidget',
      ]);

      expect(result, same(fakeResponse), reason: '整包原样返回，不得二次包装');
      expect(capturedEndpoint, 'webapi/entry.cgi');
      final apis = compoundApis();
      expect(apis.length, 9);
      expect(apis[0], {
        'api': 'SYNO.Core.System.Utilization',
        'method': 'get',
        'version': 1,
        'type': 'current',
        'resource': ['cpu', 'memory', 'network', 'disk'],
      });
      expect(apis[1], {
        'api': 'SYNO.Storage.CGI.Storage',
        'method': 'load_info',
        'version': 1
      });
      expect(apis[2], {
        'api': 'SYNO.Core.CurrentConnection',
        'method': 'list',
        'sort_direction': 'DESC',
        'sort_by': 'time',
        'version': 1
      });
      expect(apis[3], {
        'api': 'SYNO.Core.TaskScheduler',
        'sort_by': 'next_trigger_time',
        'sort_direction': 'ASC',
        'start': 0,
        'limit': 50,
        'method': 'list',
        'version': 1
      });
      expect(apis[4], {
        'api': 'SYNO.Core.SyslogClient.Status',
        'start': 0,
        'limit': 50,
        'widget': true,
        'dir': 'desc',
        'method': 'latestlog_get',
        'version': 1
      });
      expect(apis[5], {
        'start': 0,
        'limit': 50,
        'target': 'LOCAL',
        'logtype': 'ftp,filestation,webdav,cifs,tftp,afp',
        'dir': 'desc',
        'api': 'SYNO.Core.SyslogClient.Log',
        'method': 'list',
        'version': 1
      });
      expect(apis[6], {
        'api': 'SYNO.Core.System',
        'method': 'info',
        'version': 1
      });
      expect(apis[8], {
        'api': 'SYNO.Core.AppNotify',
        'method': 'get',
        'version': 1
      });
      final notify = apis[7] as Map;
      expect(notify['action'], 'load');
      expect(notify['api'], 'SYNO.Core.DSMNotify');
      expect(notify['method'], 'notify');
      expect(notify['version'], 1);
      expect(notify['lastRead'], isA<int>());
      expect(notify['lastSeen'], isA<int>());
      expect(sent()['mode'], '"parallel"');
    });

    test('systemInfo 无 widget 时仍有 system/info + notify + appNotify', () async {
      await DsmApi.systemInfo(const []);
      final apis = compoundApis();
      expect(apis.length, 3);
      expect((apis[0] as Map)['api'], 'SYNO.Core.System');
      expect((apis[1] as Map)['api'], 'SYNO.Core.DSMNotify');
      expect((apis[2] as Map)['api'], 'SYNO.Core.AppNotify');
      expect(sent()['mode'], '"parallel"');
    });

    test('dockerContainerInfo compact 三项且 mode 为 parallel', () async {
      await DsmApi.dockerContainerInfo();
      expectCompoundEnvelope(
        mode: '"parallel"',
        expectedApis: [
          {
            'api': 'SYNO.Docker.Container',
            'method': 'list',
            'version': 1,
            'limit': -1,
            'offset': 0,
            'type': 'all'
          },
          {
            'api': 'SYNO.Docker.Container.Resource',
            'method': 'get',
            'version': 1
          },
          {'api': 'SYNO.Core.System.Utilization', 'method': 'get', 'version': 1},
        ],
      );
    });

    test('dockerImageInfo 保留 show_dsm 与 registry 项', () async {
      await DsmApi.dockerImageInfo();
      expectCompoundEnvelope(
        mode: '"parallel"',
        expectedApis: [
          {
            'api': 'SYNO.Docker.Image',
            'method': 'list',
            'version': 1,
            'limit': -1,
            'offset': 0,
            'show_dsm': false
          },
          {
            'api': 'SYNO.Docker.Registry',
            'method': 'get',
            'version': 1,
            'limit': -1,
            'offset': 0
          },
        ],
      );
    });

    test('downloadStationInfo 使用 DownloadStation2 且 type_inverse 为 true',
        () async {
      await DsmApi.downloadStationInfo();
      expectCompoundEnvelope(
        mode: '"parallel"',
        expectedApis: [
          {
            'api': 'SYNO.DownloadStation2.Task',
            'method': 'list',
            'version': 2,
            'limit': 500,
            'offset': 0,
            'sort_by': 'task_id',
            'order': 'ASC',
            'additional': ['detail', 'transfer'],
            'type': ['emule'],
            'type_inverse': true,
          },
          {
            'api': 'SYNO.DownloadStation2.Task.Statistic',
            'method': 'get',
            'version': 1,
            'type': ['emule'],
            'type_inverse': true,
          },
        ],
      );
    });

    test('externalDevice 只有 USB/eSATA 且 mode 为 sequential', () async {
      await DsmApi.externalDevice();
      expectCompoundEnvelope(
        mode: '"sequential"',
        expectedApis: [
          {
            'api': 'SYNO.Core.ExternalDevice.Storage.USB',
            'method': 'list',
            'version': 1,
            'additional': ['all']
          },
          {
            'api': 'SYNO.Core.ExternalDevice.Storage.eSATA',
            'method': 'list',
            'version': 1,
            'additional': ['all']
          },
        ],
      );
    });

    test('fileService 的六个 get 子请求版本顺序不变', () async {
      await DsmApi.fileService();
      expectCompoundEnvelope(
        mode: '"sequential"',
        expectedApis: [
          {'api': 'SYNO.Core.FileServ.SMB', 'method': 'get', 'version': 3},
          {'api': 'SYNO.Core.FileServ.AFP', 'method': 'get', 'version': 1},
          {'api': 'SYNO.Core.FileServ.NFS', 'method': 'get', 'version': 2},
          {'api': 'SYNO.Core.FileServ.FTP', 'method': 'get', 'version': 3},
          {'api': 'SYNO.Core.FileServ.FTP.SFTP', 'method': 'get', 'version': 1},
          {
            'api': 'SYNO.Core.SyslogClient.FileTransfer',
            'method': 'get',
            'version': 1
          },
        ],
      );
    });

    test('fileServiceSave 保留 FTP/SFTP 字符串 version 与字段映射', () async {
      await DsmApi.fileServiceSave(
        {'enable_samba': true, 'workgroup': 'WG', 'disable_shadow_copy': false},
        {'cifs': 1, 'afp': 2},
        {'enable_afp': true},
        {
          'enable_nfs': true,
          'enable_nfs_v4': true,
          'nfs_v4_domain': 'local'
        },
        {
          'enable_ftp': true,
          'enable_ftps': false,
          'timeout': 60,
          'portnum': 21,
          'custom_port_range': '1-2',
          'use_ext_ip': false,
          'enable_fxp': false,
          'enable_fips': false,
          'enable_ascii': false,
          'utf8_mode': true
        },
        {'enable': true, 'portnum': 22},
      );
      expectCompoundEnvelope(
        mode: '"sequential"',
        expectedApis: [
          {
            'api': 'SYNO.Core.FileServ.SMB',
            'method': 'set',
            'version': 3,
            'enable_samba': true,
            'workgroup': 'WG',
            'disable_shadow_copy': false,
            'smb_transfer_log_enable': 1
          },
          {
            'api': 'SYNO.Core.FileServ.AFP',
            'method': 'set',
            'version': 1,
            'enable_afp': true,
            'afp_transfer_log_enable': 2
          },
          {
            'api': 'SYNO.Core.FileServ.NFS',
            'method': 'set',
            'version': 2,
            'enable_nfs': true,
            'enable_nfs_v4': true,
            'enable_nfs_v4_1': true,
            'nfs_v4_domain': 'local'
          },
          {
            'api': 'SYNO.Core.SyslogClient.FileTransfer',
            'method': 'set',
            'version': 1,
            'cifs': 1,
            'afp': 2
          },
          {
            'api': 'SYNO.Core.FileServ.FTP',
            'method': 'set',
            'version': '3',
            'enable_ftp': true,
            'enable_ftps': false,
            'timeout': 60,
            'portnum': 21,
            'custom_port_range': '1-2',
            'use_ext_ip': false,
            'enable_fxp': false,
            'enable_fips': false,
            'enable_ascii': false,
            'utf8_mode': true
          },
          {
            'api': 'SYNO.Core.FileServ.FTP.SFTP',
            'method': 'set',
            'version': '1',
            'enable': true,
            'sftp_portnum': 22,
            'portnum': 22
          },
        ],
      );
    });

    test('mediaIndexStatus DSM6 含 MobileEnabled，DSM7 不含', () async {
      await DsmApi.mediaIndexStatus();
      expectCompoundEnvelope(
        mode: '"sequential"',
        expectedApis: [
          {
            'api': 'SYNO.Core.MediaIndexing.ThumbnailQuality',
            'method': 'get',
            'version': 1
          },
          {'api': 'SYNO.Core.MediaIndexing', 'method': 'status', 'version': 1},
          {
            'api': 'SYNO.Core.MediaIndexing.MobileEnabled',
            'method': 'get',
            'version': 1
          },
        ],
      );

      connectionStore.setVersion(7);
      await DsmApi.mediaIndexStatus();
      expect(compoundApis().length, 2);
      expect(
          compoundApis()
              .map((e) => (e as Map)['api'])
              .contains('SYNO.Core.MediaIndexing.MobileEnabled'),
          isFalse);
    });

    test('mediaIndexSet 的 version 为字符串且 DSM 分支一致', () async {
      await DsmApi.mediaIndexSet('high', true);
      expectCompoundEnvelope(
        mode: '"sequential"',
        expectedApis: [
          {
            'api': 'SYNO.Core.MediaIndexing.ThumbnailQuality',
            'method': 'set',
            'version': '1',
            'thumbnail_quality': 'high'
          },
          {
            'api': 'SYNO.Core.MediaIndexing.MobileEnabled',
            'method': 'set',
            'version': '1',
            'mobile_profile_enabled': true
          },
        ],
      );

      connectionStore.setVersion(7);
      await DsmApi.mediaIndexSet('low', false);
      expect(compoundApis(), [
        {
          'api': 'SYNO.Core.MediaIndexing.ThumbnailQuality',
          'method': 'set',
          'version': '1',
          'thumbnail_quality': 'low'
        }
      ]);
    });

    test('powerStatus 八项与 stop_when_error 固定，返回整包 result[]', () async {
      final result = await DsmApi.powerStatus();
      expectCompoundEnvelope(
        mode: '"sequential"',
        stopWhenError: false,
        expectedApis: [
          {'api': 'SYNO.Core.Hardware.ZRAM', 'method': 'get', 'version': 1},
          {
            'api': 'SYNO.Core.Hardware.PowerRecovery',
            'method': 'get',
            'version': 1
          },
          {
            'api': 'SYNO.Core.Hardware.BeepControl',
            'method': 'get',
            'version': 1
          },
          {'api': 'SYNO.Core.Hardware.FanSpeed', 'method': 'get', 'version': 1},
          {
            'api': 'SYNO.Core.Hardware.Led.Brightness',
            'method': 'get',
            'version': 1
          },
          {'api': 'SYNO.Core.Hardware.Hibernation', 'method': 'get', 'version': 1},
          {'api': 'SYNO.Core.ExternalDevice.UPS', 'method': 'get', 'version': 1},
          {
            'api': 'SYNO.Core.Hardware.PowerSchedule',
            'method': 'load',
            'version': 1
          },
        ],
      );
      expect(result, same(fakeResponse));
      final envelope = result;
      expect(envelope['success'], true);
      final entries = envelope['data']['result'] as List;
      expect(entries[0]['api'], 'SYNO.Core.System');
      expect(entries[0]['data'], {'model': 'DS'});
      expect(entries[1]['error']['code'], 102);
    });

    test('powerSet 五项 version 均为字符串且缺省布尔补 false', () async {
      await DsmApi.powerSet(true, {'rc_power_config': 1}, {}, {}, {
        'led_brightness': 3,
        'schedule': {'enabled': true}
      });
      expectCompoundEnvelope(
        mode: '"sequential"',
        stopWhenError: false,
        expectedApis: [
          {
            'api': 'SYNO.Core.Hardware.ZRAM',
            'method': 'set',
            'version': '1',
            'enable_zram': true
          },
          {
            'api': 'SYNO.Core.Hardware.PowerRecovery',
            'method': 'set',
            'version': '1',
            'rc_power_config': 1,
            'wol1': false,
            'wol2': false
          },
          {
            'api': 'SYNO.Core.Hardware.BeepControl',
            'method': 'set',
            'version': '1',
            'fan_fail': false,
            'volume_crash': false,
            'ssd_cache_crash': false,
            'poweron_beep': false,
            'poweroff_beep': false
          },
          {
            'api': 'SYNO.Core.Hardware.FanSpeed',
            'method': 'set',
            'version': '1',
            'dual_fan_speed': null
          },
          {
            'api': 'SYNO.Core.Hardware.Led.Brightness',
            'method': 'set',
            'version': '1',
            'led_brightness': 3,
            'schedule': {'enabled': true}
          },
        ],
      );
    });

    test('userDetail 八项 additional/user_group_type 保持旧值', () async {
      await DsmApi.userDetail('alice');
      expectCompoundEnvelope(
        mode: '"sequential"',
        expectedApis: [
          {
            'api': 'SYNO.Core.User',
            'method': 'get',
            'version': 1,
            'name': 'alice',
            'additional': [
              'description',
              'email',
              'expired',
              'cannot_chg_passwd',
              'passwd_never_expire'
            ]
          },
          {
            'api': 'SYNO.Core.User.PasswordExpiry',
            'method': 'get',
            'version': 1
          },
          {
            'api': 'SYNO.Core.Share.Permission',
            'method': 'list_by_user',
            'version': 1,
            'name': 'alice',
            'user_group_type': 'local_user',
            'share_type': [
              'dec',
              'local',
              'usb',
              'sata',
              'cluster',
              'cold_storage'
            ],
            'additional': ['hidden', 'encryption', 'is_aclmode']
          },
          {
            'api': 'SYNO.Core.Storage.Volume',
            'method': 'list',
            'version': 1,
            'offset': 0,
            'limit': -1,
            'location': 'internal'
          },
          {
            'api': 'SYNO.Core.BandwidthControl',
            'method': 'get',
            'version': 2,
            'name': 'alice',
            'owner_type': 'local_user'
          },
          {
            'api': 'SYNO.Core.OTP.Admin',
            'method': 'get',
            'version': 1,
            'name': 'alice'
          },
          {'api': 'SYNO.Core.FileServ.SMB', 'method': 'get', 'version': 1},
          {
            'api': 'SYNO.Core.Quota',
            'method': 'get',
            'version': 1,
            'name': 'alice',
            'support_share_quota': true
          },
        ],
      );
    });

    test('userSave 含密码时先 set 再 add/remove 分组，stop_when_error=false',
        () async {
      await DsmApi.userSave(
        {
          'name': 'alice',
          'description': 'd',
          'email': 'a@b.c',
          'cannot_chg_passwd': false,
          'expired': false,
          'new_name': 'alice2',
          'password': 'secret'
        },
        ['g1'],
        ['g2'],
      );
      expectCompoundEnvelope(
        mode: '"sequential"',
        stopWhenError: false,
        expectedApis: [
          {
            'api': 'SYNO.Core.User',
            'method': 'set',
            'version': 1,
            'name': 'alice',
            'description': 'd',
            'email': 'a@b.c',
            'cannot_chg_passwd': false,
            'expired': false,
            'new_name': 'alice2',
            'password': 'secret'
          },
          {
            'api': 'SYNO.Core.Group.Member',
            'method': 'add',
            'version': 1,
            'group': 'g1',
            'name': 'alice'
          },
          {
            'api': 'SYNO.Core.Group.Member',
            'method': 'remove',
            'version': 1,
            'group': 'g2',
            'name': 'alice'
          },
        ],
      );
    });

    test('userSave 空密码时不发送 password 字段', () async {
      await DsmApi.userSave(
        {
          'name': 'alice',
          'description': 'd',
          'email': 'a@b.c',
          'cannot_chg_passwd': false,
          'expired': false,
          'new_name': null,
          'password': ''
        },
        const [],
        const [],
      );
      expect(compoundApis().length, 1);
      expect((compoundApis()[0] as Map).containsKey('password'), isFalse);
    });

    test('publicAccessInfo 四项 parallel 且 ExtIP retry=true', () async {
      await DsmApi.publicAccessInfo();
      expectCompoundEnvelope(
        mode: '"parallel"',
        expectedApis: [
          {'api': 'SYNO.Core.DDNS.Provider', 'version': 1, 'method': 'list'},
          {'api': 'SYNO.Core.DDNS.Record', 'version': 1, 'method': 'list'},
          {
            'api': 'SYNO.Core.DDNS.ExtIP',
            'version': 2,
            'method': 'list',
            'retry': true
          },
          {
            'api': 'SYNO.Core.DDNS.Synology',
            'version': 1,
            'method': 'get_myds_account'
          },
        ],
      );
    });

    test('networkStatus 首项 version 按 apiList.minVersion 截断到 2', () async {
      await DsmApi.networkStatus();
      expectCompoundEnvelope(
        mode: '"sequential"',
        stopWhenError: false,
        expectedApis: [
          {'api': 'SYNO.Core.Network', 'method': 'get', 'version': 1},
          {'api': 'SYNO.Core.Network.Ethernet', 'method': 'list', 'version': 2},
          {'api': 'SYNO.Core.Network.PPPoE', 'method': 'list', 'version': 1},
          {'api': 'SYNO.Core.Network.Proxy', 'method': 'get', 'version': 1},
          {
            'api': 'SYNO.Core.Network.Router.Gateway.List',
            'method': 'get',
            'version': 1,
            'iptype': 'ipv4',
            'type': 'wan'
          },
          {'api': 'SYNO.Core.Web.DSM', 'method': 'get', 'version': 2},
        ],
      );

      final previous = DsmApi.apiList['SYNO.Core.Network'];
      addTearDown(() {
        if (previous == null) {
          DsmApi.apiList.remove('SYNO.Core.Network');
        } else {
          DsmApi.apiList['SYNO.Core.Network'] = previous;
        }
      });
      DsmApi.apiList['SYNO.Core.Network'] =
          DsmApiInfo('SYNO.Core.Network', minVersion: 9);
      await DsmApi.networkStatus();
      expect((compoundApis()[0] as Map)['version'], 2);
    });

    test('compound 错误响应也原样返回（保留 error.code/errors）', () async {
      fakeResponse = {
        'success': false,
        'error': {
          'code': 117,
          'errors': {'runningTasks': []}
        },
        'data': null,
      };
      final result = await DsmApi.powerStatus();
      expect(result, same(fakeResponse));
      expect((result['error'] as Map)['code'], 117);
      expect(((result['error'] as Map)['errors'] as Map)['runningTasks'], []);
    });
  });

  group('quirk 请求体契约', () {
    final cases = <({
      String name,
      Future<Map?> Function() call,
      Map<String, dynamic> expected
    })>[
      (
        name: 'installPackageStatus',
        call: () => DsmApi.installPackageStatus('task-1'),
        expected: {
          'task_id': 'task-1',
          'api': 'SYNO.Core.Package.Installation',
          'version': 1,
          'method': 'status',
          '_sid': '',
        }
      ),
      (
        name: 'installPackageQueue',
        call: () => DsmApi.installPackageQueue('SynoFinder', '1.2'),
        expected: {
          'pkgs': '[{"pkg":"SynoFinder", "version": "1.2","beta":false}]',
          'api': 'SYNO.Core.Package.Installation',
          'version': 1,
          'method': 'get_queue',
          '_sid': '',
        }
      ),
      (
        name: 'installPackageQueue(beta=true)',
        call: () =>
            DsmApi.installPackageQueue('Docker', '2.0', beta: true),
        expected: {
          'pkgs': '[{"pkg":"Docker", "version": "2.0","beta":true}]',
          'api': 'SYNO.Core.Package.Installation',
          'version': 1,
          'method': 'get_queue',
          '_sid': '',
        }
      ),
      (
        name: 'eventRun',
        call: () => DsmApi.eventRun('nightly'),
        expected: {
          'api': 'SYNO.Core.EventScheduler',
          'version': 1,
          'method': 'run',
          'task_name': 'nightly',
          '_sid': '',
        }
      ),
      (
        name: 'taskRecord',
        call: () => DsmApi.taskRecord(7),
        expected: {
          'api': 'SYNO.Core.TaskScheduler',
          'version': 1,
          'offset': 0,
          'limit': 2,
          'method': 'view',
          'id': 7,
          '_sid': '',
        }
      ),
      (
        name: 'downloadTaskAction(version 仍为 1)',
        call: () => DsmApi.downloadTaskAction(['dbid_39'], 'pause'),
        expected: {
          'id': '["dbid_39"]',
          'api': 'SYNO.DownloadStation2.Task',
          'method': 'pause',
          'version': 1,
          '_sid': '',
        }
      ),
      (
        name: 'downloadTaskCreate(url)',
        call: () => DsmApi.downloadTaskCreate('/downloads', 'url',
            url: 'http://a\n \nhttp://b'),
        expected: {
          'api': 'SYNO.DownloadStation2.Task',
          'method': 'create',
          'version': 2,
          'type': '"url"',
          'create_list': true,
          'url': '["http://a","http://b"]',
          'destination': '"/downloads"',
          '_sid': '',
        }
      ),
      (
        name: 'downloadDetail',
        call: () => DsmApi.downloadDetail('dbid_1'),
        expected: {
          'api': 'SYNO.DownloadStation2.Task',
          'id': '["dbid_1"]',
          'additional': '["detail","transfer"]',
          'method': 'get',
          'version': 2,
          '_sid': '',
        }
      ),
      (
        name: 'downloadTracker',
        call: () => DsmApi.downloadTracker('dbid_1'),
        expected: {
          'api': 'SYNO.DownloadStation2.Task.BT.Tracker',
          'task_id': '"dbid_1"',
          'method': 'list',
          'version': 2,
          '_sid': '',
        }
      ),
      (
        name: 'downloadTrackerAdd',
        call: () =>
            DsmApi.downloadTrackerAdd('dbid_1', ['udp://tracker:80']),
        expected: {
          'api': 'SYNO.DownloadStation2.Task.BT.Tracker',
          'task_id': '"dbid_1"',
          'method': 'add',
          'tracker': '["udp://tracker:80"]',
          'version': 2,
          '_sid': '',
        }
      ),
      (
        name: 'downloadPeer',
        call: () => DsmApi.downloadPeer('dbid_1'),
        expected: {
          'api': 'SYNO.DownloadStation2.Task.BT.Peer',
          'task_id': '"dbid_1"',
          'method': 'list',
          'version': 2,
          '_sid': '',
        }
      ),
      (
        name: 'downloadFile',
        call: () => DsmApi.downloadFile('dbid_1'),
        expected: {
          'api': 'SYNO.DownloadStation2.Task.BT.File',
          'offset': 0,
          'limit': 50,
          'sort_by': 'name',
          'order': 'ASC',
          'query': '',
          'task_id': '"dbid_1"',
          'method': 'list',
          'version': 2,
          '_sid': '',
        }
      ),
      (
        name: 'fileServiceLog(get_level)',
        call: () => DsmApi.fileServiceLog('ftp'),
        expected: {
          'protocol': '"ftp"',
          'api': 'SYNO.Core.SyslogClient.FileTransfer',
          'method': 'get_level',
          'version': 1,
        }
      ),
      (
        name: 'fileServiceLogSave(set_level)',
        call: () => DsmApi.fileServiceLogSave('ftp', {'a': 1}),
        expected: {
          'protocol': '"ftp"',
          'loglevel': '{"a":1}',
          'api': 'SYNO.Core.SyslogClient.FileTransfer',
          'method': 'set_level',
          'version': 1,
        }
      ),
      (
        name: 'mediaReindex',
        call: () => DsmApi.mediaReindex(),
        expected: {
          'api': 'SYNO.Core.MediaIndexing',
          'method': 'reindex',
          'version': 1,
        }
      ),
      (
        name: 'uninstallPackageTask(双重 jsonEncode)',
        call: () => DsmApi.uninstallPackageTask('pkg', extra: {'a': 1}),
        expected: {
          'id': 'pkg',
          'api': 'SYNO.Core.Package.Uninstallation',
          'version': 1,
          'method': 'uninstall',
          '_sid': '',
          'extra_values': '"{\\"a\\":1}"',
        }
      ),
      (
        name: 'launchPackage(start 带 dsm_apps)',
        call: () => DsmApi.launchPackage('p1', 'Video Station', 'start'),
        expected: {
          'id': 'p1',
          'api': 'SYNO.Core.Package.Control',
          'version': 1,
          'method': 'start',
          '_sid': '',
          'dsm_apps': '["Video Station"]',
        }
      ),
      (
        name: 'launchPackage(stop 不带 dsm_apps)',
        call: () => DsmApi.launchPackage('p1', 'Video Station', 'stop'),
        expected: {
          'id': 'p1',
          'api': 'SYNO.Core.Package.Control',
          'version': 1,
          'method': 'stop',
          '_sid': '',
        }
      ),
      (
        name: 'power(api 串带引号且 method 动态)',
        call: () => DsmApi.power('reboot', true),
        expected: {
          'api': '"SYNO.Core.System"',
          'force': true,
          'local': true,
          'version': 1,
          'method': 'reboot',
          '_sid': '',
        }
      ),
      (
        name: 'cluster',
        call: () => DsmApi.cluster('list'),
        expected: {
          'api': 'SYNO.Virtualization.Cluster',
          'method': 'list',
          'version': 1,
          '_sid': '',
        }
      ),
      (
        name: 'dockerDetail',
        call: () => DsmApi.dockerDetail('c1', 'get'),
        expected: {
          'api': 'SYNO.Docker.Container',
          'method': 'get',
          'name': '"c1"',
          'version': 1,
          '_sid': '',
        }
      ),
      (
        name: 'dockerLog(get 带排序/日期)',
        call: () => DsmApi.dockerLog('c1', 'get', date: '2026-01-01'),
        expected: {
          'api': 'SYNO.Docker.Container.Log',
          'method': 'get',
          'name': '"c1"',
          'version': 1,
          '_sid': '',
          'sort_dir': '"ASC"',
          'date': '"2026-01-01"',
          'limit': 1000,
          'offset': 0,
        }
      ),
      (
        name: 'dockerPower(signal)',
        call: () => DsmApi.dockerPower('c1', 'signal'),
        expected: {
          'api': 'SYNO.Docker.Container',
          'method': 'signal',
          'name': '"c1"',
          'version': 1,
          '_sid': '',
          'signal': 9,
        }
      ),
      (
        name: 'trustDevice',
        call: () => DsmApi.trustDevice('list'),
        expected: {
          'api': 'SYNO.Core.TrustDevice',
          'method': 'list',
          'version': 1,
          '_sid': '',
        }
      ),
      (
        name: 'normalUser(get 为 v1)',
        call: () => DsmApi.normalUser('get'),
        expected: {
          'api': 'SYNO.Core.NormalUser',
          'method': 'get',
          'version': 1,
          '_sid': '',
        }
      ),
      (
        name: 'normalUser(set 为 v2 且合并 changedData)',
        call: () => DsmApi.normalUser('set', changedData: {'uid': 3}),
        expected: {
          'api': 'SYNO.Core.NormalUser',
          'method': 'set',
          'version': 2,
          '_sid': '',
          'uid': 3,
        }
      ),
      (
        name: 'mediaConverter(hours 为空串)',
        call: () => DsmApi.mediaConverter('get'),
        expected: {
          'api': 'SYNO.Core.MediaIndexing.MediaConverter',
          'method': 'get',
          'version': 1,
          'delay_hours': '',
        }
      ),
    ];

    for (final c in cases) {
      test('${c.name} 与旧版请求体逐字段一致', () async {
        final result = await c.call();
        expect(result, same(fakeResponse), reason: 'quirk 也不得二次包装');
        expect(capturedEndpoint, 'webapi/entry.cgi');
        expect(sent(), equals(c.expected));
      });
    }
  });
}
