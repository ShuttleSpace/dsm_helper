part of 'dsm_api.dart';

/// List all items (photos and videos) in folders in Personal Space.
///
/// **Description:** List all items (photos and videos) in folders in Personal Space.
///
/// **Auth Level:** 1 (Authentication required)
///
/// **Response Fields:**
///
/// | Field | Type | Description |
/// |-------|------|-------------|
/// | `filename` | String | Name of file |
/// | `filesize` | Integer | Size of file in bytes |
/// | `folder_id` | Integer | ID of parent folder |
/// | `id` | Integer | Unique ID of file |
/// | `indexed_time` | Integer | Linux timestamp (milliseconds) of when file was indexed |
/// | `live_type` | String | Type for iPhone live photos (e.g., "photo") |
/// | `owner_user_id` | Integer | User ID of owner |
/// | `time` | Integer | Linux timestamp (seconds) of file creation |
/// | `type` | String | Type of item: `photo`, `video`, or `live` |
///
/// **Additional Fields (when requested):**
///
/// | Field | Type | Description |
/// |-------|------|-------------|
/// | `orientation` | Integer | Current orientation |
/// | `orientation_original` | Integer | Original orientation |
/// | `resolution` | Object | Height and width of original photo |
/// | `thumbnail` | Object | Thumbnail data with cache_key, preview, sm, m, xl sizes |
/// | `exif` | Object | EXIF data (aperture, camera, exposure_time, focal_length, iso, lens) |
/// | `tag` | Array | Tag objects with id and name |
/// | `description` | String | EXIF description |
/// | `gps` | Object | GPS coordinates (latitude, longitude) |
/// | `geocoding_id` | Integer | Internal geocoding database ID |
/// | `address` | Object | Address components (city, country, state, etc.) |
/// | `person` | Array | Person objects for tagged people |
///
/// ---
Future<Map> dsmFotoBrowseItemList(
    int
        offset, // Number of items to skip before beginning to return results (default: 0)
    int limit, // Number of items requested. 0 lists all items (default: 0)
    {int? folderId, // ID of folder to list items from
    int? albumId, // ID of album to list items from
    String?
        sortBy, // Field to sort on (only works when `folder_id` is given): `filename`, `filesize`, `takentime`, `item_type`
    String?
        sortDirection, // Sort order (only works when `folder_id` is given): `asc`, `desc`
    String? type, // Type of data to filter: `photo`, `video`, `live`
    String?
        passphrase, // Passphrase for a shared album (e.g., `xXHXZxIov`). Only items of this album will be listed.
    String?
        additional, // Get additional information about items (JSON array format): `thumbnail`, `resolution`, `orientation`, `video_convert`, `video_meta`, `provider_user_id`, `exif`, `tag`, `description`, `gps`, `geocoding_id`, `address`, `person`
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.${_fotoApiName()}Browse.Item', method: 'list', version: 1);
  data['offset'] = offset;
  data['limit'] = limit;
  if (folderId != null) data['folder_id'] = folderId;
  if (albumId != null) data['album_id'] = albumId;
  if (sortBy != null && sortBy.isNotEmpty) data['sort_by'] = sortBy;
  if (sortDirection != null && sortDirection.isNotEmpty) {
    data['sort_direction'] = sortDirection;
  }
  if (type != null && type.isNotEmpty) data['type'] = type;
  if (passphrase != null && passphrase.isNotEmpty) {
    data['passphrase'] = passphrase;
  }
  if (additional != null && additional.isNotEmpty) {
    data['additional'] = additional;
  }
  final res = await _httpGet(_fotoEntryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmFotoBrowseItemList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}
