// 传输契约常量与开关。
//
// 来源：docs/superpowers/specs/2026-11-13-transfer-contract.md
// 来自 Whistle 抓包的事实：下载走 /fbdownload + base64(path) 的 dlink；
// 上传在官方网页端即使 238MB 也是单个 v2 multipart POST（不分片）。
//
// 重要：v3 分片上传 与 /fbdownload 是否认 Range 尚未用有效 FileStation 会话实测确认。
// 当前按 fallback 落地（见下方开关），待真机/有效 SID 补验后开启。

/// 是否启用 v3 分片上传。未实测确认 → 回退 v2 单请求上传。
const bool kUploadV3Supported = false;

/// DSM Upload 是否具备已验证的字节级续传（offset/append/分片合并）能力。
///
/// Task 8 Step 1 结论：官方客户端 238MB 仍走 v2 单请求、抓包零
/// `part_number`/`upload_id`、`all_api.json5` 无分片参数 → 无可用契约，
/// 故不宣称字节级续传。见
/// docs/superpowers/specs/2026-11-16-transfer-capability-probe.md
bool get uploadByteResumeSupported => kUploadV3Supported;

/// 上传策略（由能力探测结论决定，禁止无提示假续传）。
enum UploadStrategy {
  v2SingleRequest,
  v3Chunked,
}

/// 当前上传策略：未实测 v3 → v2 单请求（完整保留 Task 7 备份上传契约）。
UploadStrategy selectUploadStrategy() => kUploadV3Supported
    ? UploadStrategy.v3Chunked
    : UploadStrategy.v2SingleRequest;

/// 必须在 UI/文档明示的上传能力边界，禁止误导性的「断点续传」承诺。
const String uploadResumeBoundaryText =
    '上传断点续传受 DSM 限制：DSM Upload API 未提供已验证的偏移/追加语义，'
    '网络中断或应用重启后需重新上传（可从传输列表一键重试），暂不支持字节级续传。';

/// 默认分片大小（上传分片用）。
const int kDefaultChunkSizeBytes = 8 * 1024 * 1024;

/// 上传分片并发度。
const int kDefaultConcurrency = 4;

/// v3 分片上传的 multipart 字段名映射（**未实测**，待 Task 8 真机确认后生效）。
///
/// 字段名取自 Synology 官方 FileStation API 文档的 v3 约定；若真机实测发现偏差，
/// 改这里即可，不需要动上传逻辑。
class UploadV3Fields {
  const UploadV3Fields({
    this.path = 'path',
    this.filename = 'filename',
    this.uploadId = 'upload_id',
    this.partNumber = 'part_number',
    this.totalParts = 'total_parts',
    this.offset = 'offset',
    this.offsetSize = 'offset_size',
    this.overwrite = 'overwrite',
    this.mtime = 'mtime',
    this.size = 'size',
    this.file = 'file',
  });

  final String path;
  final String filename;
  final String uploadId;
  final String partNumber;
  final String totalParts;
  final String offset;
  final String offsetSize;
  final String overwrite;
  final String mtime;
  final String size;
  final String file;

  /// 末片上传完成即触发 NAS 拼合（vs 需单独 complete 调用）。未实测。
  static const bool assemblyOnFinalPart = true;
}
