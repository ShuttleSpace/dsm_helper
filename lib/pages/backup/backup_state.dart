import 'package:garden/extensions/signal.dart';
import 'package:garden/pages/file/upload.dart';
import 'package:garden/util/storage_util.dart';
import 'package:signals/signals_core.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class BackupState {
  static const lastBackupTimeKey = 'last_backup_time';

  final _uploads = listSignal<AssetEntity>([]);
  final _albums = listSignal<AssetEntity>([]);

  final _backupFolder = signal('');
  final _lastBackupTime = signal(DateTime.now());
  final _uploading = signal<UploadItem?>(null);
  final _cancel = signal(false);
  final _continueBackup = signal(true);

  final _getData = futureSignal(() async {
    final lastBackupTime =
        await StorageUtil.getString(lastBackupTimeKey) ?? '';
    if (await PhotoManager.requestPermissionExtend() ==
        PermissionState.authorized) {}
  });

  dispose() {
    _uploads.dispose();
    _albums.dispose();
    _backupFolder.dispose();
    _lastBackupTime.dispose();
    _uploading.dispose();
    _cancel.dispose();
    _continueBackup.dispose();
  }
}
