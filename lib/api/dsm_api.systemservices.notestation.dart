part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "notes": [
///       {
///         "note_id": "note_123",
///         "title": "Meeting Notes",
///         "content": "Discussion points...",
///         "notebook_id": "notebook_1",
///         "created_time": 1732788000,
///         "updated_time": 1732788000,
///         "tags": ["work", "meeting"]
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
/// | `note_id` | string | Note ID |
/// | `title` | string | Note title |
/// | `content` | string | Note content |
/// | `notebook_id` | string | Parent notebook ID |
/// | `created_time` | integer | Creation timestamp (Unix time) |
/// | `updated_time` | integer | Last update timestamp (Unix time) |
/// | `tags` | array | Note tags |
///
/// ---
Future<Map> dsmNoteStationNoteList(
    {int? offset, int? limit, CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.NoteStation.Note', method: 'List', version: 1);
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmNoteStationNoteList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "note_id": "note_123",
///     "title": "Meeting Notes",
///     "content": "Discussion points...",
///     "notebook_id": "notebook_1",
///     "created_time": 1732788000,
///     "updated_time": 1732788000,
///     "tags": ["work", "meeting"]
///   }
/// }
Future<Map> dsmNoteStationNoteGet(String noteId, // Note ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.NoteStation.Note', method: 'Get', version: 1);
  data['note_id'] = noteId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmNoteStationNoteGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "notebooks": [
///       {
///         "notebook_id": "notebook_1",
///         "name": "Work",
///         "note_count": 15,
///         "created_time": 1732788000
///       }
///     ],
///     "total": 1
///   }
/// }
Future<Map> dsmNoteStationNotebookList({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.NoteStation.Notebook', method: 'List', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmNoteStationNotebookList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "tags": [
///       {
///         "tag_name": "work",
///         "note_count": 10
///       },
///       {
///         "tag_name": "meeting",
///         "note_count": 5
///       }
///     ],
///     "total": 2
///   }
/// }
///
/// **Notes:**
/// - Note Station package must be installed
/// - Notes support rich text formatting
/// - Tags help organize notes across notebooks
/// - Notes can be shared with other users
///
/// ---
Future<Map> dsmNoteStationTagList({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.NoteStation.Tag', method: 'List', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmNoteStationTagList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
