/// 媒体播放器状态枚举
enum PlayerStateX {
  /// 空闲状态，播放器已创建但未初始化
  idle,

  /// 初始化中
  initializing,

  /// 准备中（设置数据源后）
  preparing,

  /// 已准备，可以开始播放
  prepared,

  /// 正在播放
  playing,

  /// 已暂停
  paused,

  /// 正在缓冲
  buffering,

  /// 播放完成
  completed,

  /// 播放结束
  ended,

  /// 播放停止
  stopped,

  /// 播放错误
  error,

  /// 播放器被释放
  released
}
