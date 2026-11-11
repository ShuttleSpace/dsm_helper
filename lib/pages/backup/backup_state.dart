import 'package:garden/pages/backup/backup_model.dart';
import 'package:signals/signals_core.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class BackupState {
  static const lastBackupTimeKey = 'last_backup_time';

  final _uploads = signal<List<AssetEntity>>([]);
  final _albums = signal<List<AssetEntity>>([]);

  final _backupFolder = signal('');
  final _lastBackupTime = signal(DateTime.now());
  final _uploading = signal<UploadItem?>(null);
  final _cancel = signal(false);
  final _continueBackup = signal(true);

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
