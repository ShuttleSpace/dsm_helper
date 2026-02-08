part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "tasks": [
///       {
///         "id": 1,
///         "name": "Daily Backup",
///         "type": "script",
///         "enabled": true,
///         "next_trigger_time": 1732788000,
///         "last_run_time": 1732701600,
///         "last_run_status": "success"
///       }
///     ],
///     "total": 1
///   }
/// }
///
/// **Response Fields:**
///
/// | Field | Type | Description |
/// |-------|------|-------------|
/// | `id` | integer | Task ID |
/// | `name` | string | Task name |
/// | `type` | string | Task type (`script`, `service`, `beep`, `recycle_bin`) |
/// | `enabled` | boolean | Task enabled |
/// | `next_trigger_time` | integer | Next run timestamp (Unix time) |
/// | `last_run_time` | integer | Last run timestamp (Unix time) |
/// | `last_run_status` | string | Last run status (`success`, `failed`) |
///
/// ---
Future<Map> dsmCoreTaskSchedulerList(
    {String? sortBy, // Sort field (default: `next_trigger_time`)
    String? sortDirection, // `asc` or `desc`
    int? offset, // Starting index
    int? limit, // Max results
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.TaskScheduler', method: 'List', version: 2);
  if (sortBy != null && sortBy.isNotEmpty) data['sort_by'] = sortBy;
  if (sortDirection != null && sortDirection.isNotEmpty) {
    data['sort_direction'] = sortDirection;
  }
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmCoreTaskSchedulerList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "id": 1,
///     "name": "Daily Backup",
///     "type": "script",
///     "enabled": true,
///     "schedule": {
///       "date_type": 0,
///       "hour": 2,
///       "minute": 0
///     },
///     "script": "#!/bin/bash\necho 'Backup started'"
///   }
/// }
Future<Map> dsmCoreTaskSchedulerGet(int taskId, // Task ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.TaskScheduler', method: 'Get', version: 2);
  data['task_id'] = taskId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmCoreTaskSchedulerGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmCoreTaskSchedulerSetEnable(
    int taskId, // Task ID
    bool enable, // Enable status (true/false)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.TaskScheduler', method: 'SetEnable', version: 2);
  data['task_id'] = taskId;
  data['enable'] = enable;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCoreTaskSchedulerSetEnable: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
///
/// **Notes:**
/// - Runs task immediately regardless of schedule
/// - Task must be enabled to run
///
/// ---
Future<Map> dsmCoreTaskSchedulerRun(int taskId, // Task ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.TaskScheduler', method: 'Run', version: 2);
  data['task_id'] = taskId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCoreTaskSchedulerRun: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmCoreTaskSchedulerDelete(int taskId, // Task ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.TaskScheduler', method: 'Delete', version: 2);
  data['task_id'] = taskId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCoreTaskSchedulerDelete: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "results": [
///       {
///         "time": 1732701600,
///         "status": "success",
///         "output": "Backup completed successfully"
///       }
///     ]
///   }
/// }
///
/// **Notes:**
/// - Task results include execution output
/// - Output logging must be enabled in task settings
/// - Results are limited to recent executions
///
/// ---
Future<Map> dsmCoreTaskSchedulerResultGet(int taskId, // Task ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.TaskScheduler.Result', method: 'Get', version: 1);
  data['task_id'] = taskId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmCoreTaskSchedulerResultGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// **Daily Backup Script:**
/// ```bash
/// #!/bin/bash
/// # Daily backup script
/// SOURCE="/volume1/important"
/// DEST="/volume1/backup/$(date +%Y%m%d)"
/// mkdir -p "$DEST"
/// rsync -av "$SOURCE/" "$DEST/"
/// echo "Backup completed: $DEST"
/// ```
///
/// **Schedule (Daily at 2:00 AM):**
/// ```json
/// {
///   "date_type": 0,
///   "hour": 2,
///   "minute": 0
/// }
/// ```
///
/// **Repeat Every 30 Minutes:**
/// ```json
/// {
///   "date_type": 4,
///   "repeat_hour": 0,
///   "repeat_min": 30,
///   "last_work_hour": 23
/// }
/// ```
///
/// **Weekly on Monday and Friday:**
/// ```json
/// {
///   "date_type": 1,
///   "hour": 9,
///   "minute": 0,
///   "week_day": "1,5"
/// }
/// ```
///
/// **Notes:**
/// - Week days: 0=Sunday, 1=Monday, ..., 6=Saturday
/// - Scripts have access to DSM environment variables
/// - Long-running scripts should handle interruption gracefully
/// - Use absolute paths in scripts

/// {
///   "success": true,
///   "data": {
///     "task_id": 5
///   }
/// }
///
/// **Schedule Configuration:**
/// ```json
/// {
///   "date_type": 0,
///   "hour": 2,
///   "minute": 0,
///   "repeat_hour": 0,
///   "repeat_min": 0,
///   "last_work_hour": 0,
///   "week_day": "0,1,2,3,4,5,6"
/// }
/// ```
///
/// **Schedule Types:**
/// - `date_type: 0` - Daily
/// - `date_type: 1` - Weekly (use `week_day`)
/// - `date_type: 2` - Monthly (use `month_day`)
/// - `date_type: 3` - Run on boot
/// - `date_type: 4` - Repeat (use `repeat_hour`, `repeat_min`)
///
/// ---
Future<Map> dsmCoreTaskSchedulerScriptCreate(
    String taskName, // Task name
    String script, // Script content
    Map schedule, // Schedule configuration (JSON object)
    {bool? enabled, // Enable task (default: true)
    bool? notifyEnable, // Enable notifications (default: false)
    String? notifyMail, // Notification email
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.TaskScheduler.Script', method: 'Create', version: 2);
  data['task_name'] = taskName;
  data['script'] = script;
  data['schedule'] = schedule;
  if (enabled != null) data['enabled'] = enabled;
  if (notifyEnable != null) data['notify_enable'] = notifyEnable;
  if (notifyMail != null && notifyMail.isNotEmpty) {
    data['notify_mail'] = notifyMail;
  }
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCoreTaskSchedulerScriptCreate: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
/// **Notes:**
/// - Scripts can be bash, python, or other interpreters
/// - Use shebang line (e.g., `#!/bin/bash`) to specify interpreter
/// - Scripts run with DSM user permissions
/// - Output can be logged for debugging
///
/// ---
Future<Map> dsmCoreTaskSchedulerScriptModify(int taskId, // Task ID
    {String? taskName, // New task name
    String? script, // New script content
    Map? schedule, // New schedule configuration
    bool? enabled, // Enable status
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.TaskScheduler.Script', method: 'Modify', version: 2);
  data['task_id'] = taskId;
  if (taskName != null && taskName.isNotEmpty) data['task_name'] = taskName;
  if (script != null && script.isNotEmpty) data['script'] = script;
  if (schedule != null) data['schedule'] = schedule;
  if (enabled != null) data['enabled'] = enabled;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCoreTaskSchedulerScriptModify: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// ## Example Service Tasks
///
/// **Restart SSH Daily:**
/// ```json
/// {
///   "task_name": "Daily SSH Restart",
///   "service_name": "sshd",
///   "action": "restart",
///   "schedule": {
///     "date_type": 0,
///     "hour": 3,
///     "minute": 0
///   }
/// }
/// ```
///
/// **Stop FTP on Weekends:**
/// ```json
/// {
///   "task_name": "Weekend FTP Stop",
///   "service_name": "ftpd",
///   "action": "stop",
///   "schedule": {
///     "date_type": 1,
///     "hour": 18,
///     "minute": 0,
///     "week_day": "5"
///   }
/// }
/// ```
///
/// **Start FTP on Weekdays:**
/// ```json
/// {
///   "task_name": "Weekday FTP Start",
///   "service_name": "ftpd",
///   "action": "start",
///   "schedule": {
///     "date_type": 1,
///     "hour": 8,
///     "minute": 0,
///     "week_day": "1"
///   }
/// }
/// ```
///
/// **Notes:**
/// - Service control tasks are useful for security and resource management
/// - Stopping services reduces attack surface
/// - Restarting services can resolve memory leaks
/// - Coordinate start/stop tasks to avoid conflicts

/// {
///   "success": true,
///   "data": {
///     "task_id": 6
///   }
/// }
///
/// **Common Service Names:**
/// - `sshd` - SSH service
/// - `nmbd` - Samba NetBIOS service
/// - `smbd` - Samba file sharing service
/// - `afpd` - AFP file sharing service
/// - `ftpd` - FTP service
/// - `nfsd` - NFS service
/// - `snmpd` - SNMP service
///
/// ---
Future<Map> dsmCoreTaskSchedulerServiceCreate(
    String taskName, // Task name
    String serviceName, // Service name
    String action, // Service action (`start`, `stop`, `restart`)
    Map schedule, // Schedule configuration (JSON object)
    {bool? enabled, // Enable task (default: true)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.TaskScheduler.Service', method: 'Create', version: 1);
  data['task_name'] = taskName;
  data['service_name'] = serviceName;
  data['action'] = action;
  data['schedule'] = schedule;
  if (enabled != null) data['enabled'] = enabled;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCoreTaskSchedulerServiceCreate: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
///
/// **Notes:**
/// - Service tasks control DSM system services
/// - Useful for scheduled service restarts
/// - Actions: `start`, `stop`, `restart`
/// - Requires administrator privileges
///
/// ---
Future<Map> dsmCoreTaskSchedulerServiceModify(int taskId, // Task ID
    {String? taskName, // New task name
    String? serviceName, // New service name
    String? action, // New service action
    Map? schedule, // New schedule configuration
    bool? enabled, // Enable status
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.TaskScheduler.Service', method: 'Modify', version: 1);
  data['task_id'] = taskId;
  if (taskName != null && taskName.isNotEmpty) data['task_name'] = taskName;
  if (serviceName != null && serviceName.isNotEmpty) {
    data['service_name'] = serviceName;
  }
  if (action != null && action.isNotEmpty) data['action'] = action;
  if (schedule != null) data['schedule'] = schedule;
  if (enabled != null) data['enabled'] = enabled;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCoreTaskSchedulerServiceModify: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}
