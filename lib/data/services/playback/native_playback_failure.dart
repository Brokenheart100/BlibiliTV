import '../../../core/result.dart';

// Native messages are inspected locally and discarded; signed URLs never escape.
AppFailure classifyNativePlaybackFailure(String message) {
  final text = message.toLowerCase();
  if (RegExp(r'\b(403|410)\b').hasMatch(text)) {
    return const AppFailure(FailureKind.resourceExpired, '播放地址已失效，正在尝试重新获取');
  }
  if (RegExp(
    r'\b(404|500|502|503|504)\b|timed out|connection|network|failed to open|error opening',
  ).hasMatch(text)) {
    return const AppFailure(FailureKind.cdn, '播放线路暂不可用');
  }
  return const AppFailure(FailureKind.unsupported, '当前解码器无法播放此内容，请返回选择其他视频');
}
