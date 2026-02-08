import 'package:garden/stores/connection_store.dart';

/// cache_key : "611690_1665630858"
/// m : "ready"
/// preview : "broken"
/// sm : "ready"
/// unit_id : 611690
/// xl : "ready"

class ThumbnailModel {
  ThumbnailModel({
    this.cacheKey,
    this.m,
    this.preview,
    this.sm,
    this.unitId,
    this.xl,
    this.folderCoverSeq,
  });

  ThumbnailModel.fromJson(dynamic json) {
    cacheKey = json['cache_key'];
    m = json['m'];
    preview = json['preview'];
    sm = json['sm'];
    unitId = json['unit_id'];
    xl = json['xl'];
    folderCoverSeq = json['folder_cover_seq'];
  }
  String? cacheKey;
  String? m;
  String? preview;
  String? sm;
  num? unitId;
  String? xl;
  num? folderCoverSeq;
  String thumbUrl({String size = 'sm', int? folderId, bool isTeam = false}) {
    return '${connectionStore.baseUri}/webapi/entry.cgi?id=$unitId&cache_key="$cacheKey"&type="unit"&size="$size"&api="SYNO.Foto${isTeam ? 'Team' : ''}.Thumbnail"&method="get"&version=1&_sid=${connectionStore.sid}';
  }

  ThumbnailModel copyWith({
    String? cacheKey,
    String? m,
    String? preview,
    String? sm,
    num? unitId,
    String? xl,
    num? folderCoverSeq,
  }) =>
      ThumbnailModel(
        cacheKey: cacheKey ?? this.cacheKey,
        m: m ?? this.m,
        preview: preview ?? this.preview,
        sm: sm ?? this.sm,
        unitId: unitId ?? this.unitId,
        xl: xl ?? this.xl,
        folderCoverSeq: folderCoverSeq ?? this.folderCoverSeq,
      );
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['cache_key'] = cacheKey;
    map['m'] = m;
    map['preview'] = preview;
    map['sm'] = sm;
    map['unit_id'] = unitId;
    map['xl'] = xl;
    map['folder_cover_seq'] = folderCoverSeq;
    return map;
  }
}
