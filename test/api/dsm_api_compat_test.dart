import 'package:flutter_test/flutter_test.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/util/http_util.dart' as http_util;

void main() {
  group('compat envelope', () {
    test('compatWrapSuccess wraps data in legacy success envelope', () {
      final envelope = compatWrapSuccess({'total': 2});
      expect(envelope, containsPair('success', true));
      expect(envelope, containsPair('data', {'total': 2}));
    });

    test('compatWrapError preserves nested rawError and msg', () {
      final e = DSMException.fromMap({
        'success': false,
        'error': {
          'code': 117,
          'errors': {
            'runningTasks': [
              {'name': 'task'}
            ]
          }
        },
        'msg': 'operation not allowed',
      });
      final wrapped = compatWrapError(e);
      expect(wrapped['success'], false);
      expect(wrapped['data'], null);
      final error = wrapped['error'] as Map;
      expect(error['code'], 117);
      expect((error['errors'] as Map)['runningTasks'], isNotNull);
      expect(wrapped['msg'], 'operation not allowed');
    });

    test('compatWrapError falls back to code -1 for non-DSM exceptions', () {
      final wrapped = compatWrapError(StateError('boom'));
      expect(wrapped['success'], false);
      expect((wrapped['error'] as Map)['code'], -1);
    });

    test('compatWrapError uses code when rawError absent', () {
      final wrapped = compatWrapError(DSMException('bad', 42));
      expect((wrapped['error'] as Map)['code'], 42);
    });
  });

  group('compat method inventory', () {
    test('all 137 legacy method names are present with compatible signatures',
        () {
      // 编译期即校验方法存在与签名可解析（ tear-off 类型为 Function ）。
      expect(DsmApi.api, isA<Function>(), reason: 'api');
      expect(DsmApi.login, isA<Function>(), reason: 'login');
      expect(DsmApi.shareList, isA<Function>(), reason: 'shareList');
      expect(DsmApi.listTarget, isA<Function>(), reason: 'listTarget');
      expect(DsmApi.shareCore, isA<Function>(), reason: 'shareCore');
      expect(DsmApi.shareDetail, isA<Function>(), reason: 'shareDetail');
      expect(DsmApi.addSharedFolder, isA<Function>(),
          reason: 'addSharedFolder');
      expect(DsmApi.deleteSharedFolder, isA<Function>(),
          reason: 'deleteSharedFolder');
      expect(DsmApi.cleanRecycleBin, isA<Function>(),
          reason: 'cleanRecycleBin');
      expect(DsmApi.fileList, isA<Function>(), reason: 'fileList');
      expect(DsmApi.smbFolder, isA<Function>(), reason: 'smbFolder');
      expect(DsmApi.remoteLink, isA<Function>(), reason: 'remoteLink');
      expect(DsmApi.remoteUnConnect, isA<Function>(),
          reason: 'remoteUnConnect');
      expect(DsmApi.mountFolder, isA<Function>(), reason: 'mountFolder');
      expect(DsmApi.unMountFolder, isA<Function>(), reason: 'unMountFolder');
      expect(DsmApi.favoriteList, isA<Function>(), reason: 'favoriteList');
      expect(DsmApi.favoriteAdd, isA<Function>(), reason: 'favoriteAdd');
      expect(DsmApi.favoriteRename, isA<Function>(), reason: 'favoriteRename');
      expect(DsmApi.favoriteDelete, isA<Function>(), reason: 'favoriteDelete');
      expect(DsmApi.deleteTask, isA<Function>(), reason: 'deleteTask');
      expect(DsmApi.deleteResult, isA<Function>(), reason: 'deleteResult');
      expect(DsmApi.searchTask, isA<Function>(), reason: 'searchTask');
      expect(DsmApi.searchResult, isA<Function>(), reason: 'searchResult');
      expect(DsmApi.compressTask, isA<Function>(), reason: 'compressTask');
      expect(DsmApi.compressResult, isA<Function>(), reason: 'compressResult');
      expect(DsmApi.copyMoveTask, isA<Function>(), reason: 'copyMoveTask');
      expect(DsmApi.createShare, isA<Function>(), reason: 'createShare');
      expect(DsmApi.editShare, isA<Function>(), reason: 'editShare');
      expect(DsmApi.listShare, isA<Function>(), reason: 'listShare');
      expect(DsmApi.deleteShare, isA<Function>(), reason: 'deleteShare');
      expect(DsmApi.backgroundTask, isA<Function>(), reason: 'backgroundTask');
      expect(DsmApi.copyMoveResult, isA<Function>(), reason: 'copyMoveResult');
      expect(DsmApi.dirSizeTask, isA<Function>(), reason: 'dirSizeTask');
      expect(DsmApi.dirSizeResult, isA<Function>(), reason: 'dirSizeResult');
      expect(DsmApi.extractTask, isA<Function>(), reason: 'extractTask');
      expect(DsmApi.extractResult, isA<Function>(), reason: 'extractResult');
      expect(DsmApi.systemInfo, isA<Function>(), reason: 'systemInfo');
      expect(DsmApi.notifyStrings, isA<Function>(), reason: 'notifyStrings');
      expect(DsmApi.notify, isA<Function>(), reason: 'notify');
      expect(DsmApi.storage, isA<Function>(), reason: 'storage');
      expect(DsmApi.kickConnection, isA<Function>(), reason: 'kickConnection');
      expect(DsmApi.clearNotify, isA<Function>(), reason: 'clearNotify');
      expect(DsmApi.initData, isA<Function>(), reason: 'initData');
      expect(DsmApi.networkInfo, isA<Function>(), reason: 'networkInfo');
      expect(DsmApi.checkPermission, isA<Function>(),
          reason: 'checkPermission');
      expect(DsmApi.createFolder, isA<Function>(), reason: 'createFolder');
      expect(DsmApi.rename, isA<Function>(), reason: 'rename');
      expect(DsmApi.power, isA<Function>(), reason: 'power');
      expect(DsmApi.setTerminal, isA<Function>(), reason: 'setTerminal');
      expect(DsmApi.terminalInfo, isA<Function>(), reason: 'terminalInfo');
      expect(DsmApi.upload, isA<Function>(), reason: 'upload');
      expect(DsmApi.uploadWeb, isA<Function>(), reason: 'uploadWeb');
      expect(DsmApi.volumes, isA<Function>(), reason: 'volumes');
      expect(DsmApi.packages, isA<Function>(), reason: 'packages');
      expect(DsmApi.installedPackages, isA<Function>(),
          reason: 'installedPackages');
      expect(DsmApi.launchedPackages, isA<Function>(),
          reason: 'launchedPackages');
      expect(DsmApi.launchPackage, isA<Function>(), reason: 'launchPackage');
      expect(DsmApi.installPackageTask, isA<Function>(),
          reason: 'installPackageTask');
      expect(DsmApi.installPackageStatus, isA<Function>(),
          reason: 'installPackageStatus');
      expect(DsmApi.installPackageQueue, isA<Function>(),
          reason: 'installPackageQueue');
      expect(DsmApi.uninstallPackageInfo, isA<Function>(),
          reason: 'uninstallPackageInfo');
      expect(DsmApi.uninstallPackageTask, isA<Function>(),
          reason: 'uninstallPackageTask');
      expect(DsmApi.taskScheduler, isA<Function>(), reason: 'taskScheduler');
      expect(DsmApi.taskRun, isA<Function>(), reason: 'taskRun');
      expect(DsmApi.eventRun, isA<Function>(), reason: 'eventRun');
      expect(DsmApi.taskRecord, isA<Function>(), reason: 'taskRecord');
      expect(DsmApi.taskEnable, isA<Function>(), reason: 'taskEnable');
      expect(DsmApi.users, isA<Function>(), reason: 'users');
      expect(DsmApi.userGroups, isA<Function>(), reason: 'userGroups');
      expect(DsmApi.userSetting, isA<Function>(), reason: 'userSetting');
      expect(DsmApi.mediaConverter, isA<Function>(), reason: 'mediaConverter');
      expect(DsmApi.utilization, isA<Function>(), reason: 'utilization');
      expect(DsmApi.process, isA<Function>(), reason: 'process');
      expect(DsmApi.processGroup, isA<Function>(), reason: 'processGroup');
      expect(DsmApi.cluster, isA<Function>(), reason: 'cluster');
      expect(DsmApi.checkPowerOn, isA<Function>(), reason: 'checkPowerOn');
      expect(DsmApi.vmmPower, isA<Function>(), reason: 'vmmPower');
      expect(DsmApi.dockerContainerInfo, isA<Function>(),
          reason: 'dockerContainerInfo');
      expect(DsmApi.dockerImageInfo, isA<Function>(),
          reason: 'dockerImageInfo');
      expect(DsmApi.dockerDetail, isA<Function>(), reason: 'dockerDetail');
      expect(DsmApi.dockerLog, isA<Function>(), reason: 'dockerLog');
      expect(DsmApi.dockerPower, isA<Function>(), reason: 'dockerPower');
      expect(DsmApi.lastLog, isA<Function>(), reason: 'lastLog');
      expect(DsmApi.log, isA<Function>(), reason: 'log');
      expect(DsmApi.logHistory, isA<Function>(), reason: 'logHistory');
      expect(DsmApi.reward, isA<Function>(), reason: 'reward');
      expect(DsmApi.downloadStationInfo, isA<Function>(),
          reason: 'downloadStationInfo');
      expect(DsmApi.downloadTaskAction, isA<Function>(),
          reason: 'downloadTaskAction');
      expect(DsmApi.downloadLocation, isA<Function>(),
          reason: 'downloadLocation');
      expect(DsmApi.downloadTaskCreate, isA<Function>(),
          reason: 'downloadTaskCreate');
      expect(DsmApi.downloadFileList, isA<Function>(),
          reason: 'downloadFileList');
      expect(DsmApi.downloadCreate, isA<Function>(), reason: 'downloadCreate');
      expect(DsmApi.downloadDetail, isA<Function>(), reason: 'downloadDetail');
      expect(DsmApi.downloadTracker, isA<Function>(),
          reason: 'downloadTracker');
      expect(DsmApi.downloadTrackerAdd, isA<Function>(),
          reason: 'downloadTrackerAdd');
      expect(DsmApi.downloadPeer, isA<Function>(), reason: 'downloadPeer');
      expect(DsmApi.downloadFile, isA<Function>(), reason: 'downloadFile');
      expect(DsmApi.trustDevice, isA<Function>(), reason: 'trustDevice');
      expect(DsmApi.normalUser, isA<Function>(), reason: 'normalUser');
      expect(DsmApi.externalDevice, isA<Function>(), reason: 'externalDevice');
      expect(DsmApi.ejectEsata, isA<Function>(), reason: 'ejectEsata');
      expect(DsmApi.smart, isA<Function>(), reason: 'smart');
      expect(DsmApi.diskTestLog, isA<Function>(), reason: 'diskTestLog');
      expect(DsmApi.smartTestLog, isA<Function>(), reason: 'smartTestLog');
      expect(DsmApi.doSmartTest, isA<Function>(), reason: 'doSmartTest');
      expect(DsmApi.saveMail, isA<Function>(), reason: 'saveMail');
      expect(DsmApi.getQrCode, isA<Function>(), reason: 'getQrCode');
      expect(DsmApi.authOtpCode, isA<Function>(), reason: 'authOtpCode');
      expect(DsmApi.currentConnect, isA<Function>(), reason: 'currentConnect');
      expect(DsmApi.userQuota, isA<Function>(), reason: 'userQuota');
      expect(DsmApi.fileService, isA<Function>(), reason: 'fileService');
      expect(DsmApi.fileServiceLog, isA<Function>(), reason: 'fileServiceLog');
      expect(DsmApi.fileServiceLogSave, isA<Function>(),
          reason: 'fileServiceLogSave');
      expect(DsmApi.fileServiceSave, isA<Function>(),
          reason: 'fileServiceSave');
      expect(DsmApi.securityRule, isA<Function>(), reason: 'securityRule');
      expect(DsmApi.securitySystem, isA<Function>(), reason: 'securitySystem');
      expect(DsmApi.mediaReindex, isA<Function>(), reason: 'mediaReindex');
      expect(DsmApi.mediaIndexStatus, isA<Function>(),
          reason: 'mediaIndexStatus');
      expect(DsmApi.mediaIndexSet, isA<Function>(), reason: 'mediaIndexSet');
      expect(DsmApi.quickConnect, isA<Function>(), reason: 'quickConnect');
      expect(DsmApi.quickConnectCn, isA<Function>(), reason: 'quickConnectCn');
      expect(DsmApi.pingpong, isA<Function>(), reason: 'pingpong');
      expect(DsmApi.powerStatus, isA<Function>(), reason: 'powerStatus');
      expect(DsmApi.powerScheduleSave, isA<Function>(),
          reason: 'powerScheduleSave');
      expect(DsmApi.powerSet, isA<Function>(), reason: 'powerSet');
      expect(DsmApi.powerHibernationSave, isA<Function>(),
          reason: 'powerHibernationSave');
      expect(DsmApi.userDetail, isA<Function>(), reason: 'userDetail');
      expect(DsmApi.userSave, isA<Function>(), reason: 'userSave');
      expect(DsmApi.userGroup, isA<Function>(), reason: 'userGroup');
      expect(DsmApi.firmwareVersion, isA<Function>(),
          reason: 'firmwareVersion');
      expect(DsmApi.firmwareUpgrade, isA<Function>(),
          reason: 'firmwareUpgrade');
      expect(DsmApi.publicAccessInfo, isA<Function>(),
          reason: 'publicAccessInfo');
      expect(DsmApi.ddnsSave, isA<Function>(), reason: 'ddnsSave');
      expect(DsmApi.ddnsUpdate, isA<Function>(), reason: 'ddnsUpdate');
      expect(DsmApi.ddnsDelete, isA<Function>(), reason: 'ddnsDelete');
      expect(DsmApi.ddnsTest, isA<Function>(), reason: 'ddnsTest');
      expect(DsmApi.networkStatus, isA<Function>(), reason: 'networkStatus');
    });

    test('reward URL helper stays on legacy endpoint', () {
      expect(dsmRewardUrl('http://192.168.8.40:5000/'),
          'http://192.168.8.40:5000/reward');
    });
  });

  group('http_util export', () {
    test('DsmApi via http_util export is the compat DsmApi', () {
      expect(http_util.DsmApi, same(DsmApi));
    });
  });
}
