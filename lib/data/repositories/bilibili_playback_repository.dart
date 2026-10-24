import '../../core/result.dart';
import '../../domain/playback/playback.dart';
import '../services/bilibili/bilibili_api.dart';
import '../services/bilibili/bilibili_dto.dart';

class BilibiliPlaybackRepository implements PlaybackRepository {
  BilibiliPlaybackRepository(this.api);
  final BilibiliApi api;
  @override
  Future<Result<PlaybackSource>> resolve({
    required String videoId,
    required String partId,
    required CancellationSignal cancellation,
  }) async {
    try {
      final data = await api.get(
        '/x/player/wbi/playurl',
        cancellation,
        signed: true,
        query: {
          'bvid': videoId,
          'cid': int.parse(partId),
          'qn': 32,
          'fnval': 4048,
          'fnver': 0,
          'fourk': 1,
        },
      );
      if (data['is_drm'] == true ||
          data['is_drm'] == 1 ||
          data['dash'] == null) {
        throw const AppFailure(FailureKind.unsupported, '此内容的播放格式暂不支持');
      }
      final dash = jsonObject(data['dash']);
      List<DashTrackDto> tracks(String kind) =>
          jsonList(dash[kind])
              .map((v) => DashTrackDto.fromJson(jsonObject(v)))
              .toList();
      final videos =
          tracks('video').where((t) => t.codecs.startsWith('avc1')).toList()
            ..sort((a, b) => a.bandwidth.compareTo(b.bandwidth));
      final audios =
          tracks('audio').where((t) => t.codecs.startsWith('mp4a')).toList()
            ..sort((a, b) => a.bandwidth.compareTo(b.bandwidth));
      if (videos.isEmpty || audios.isEmpty) {
        throw const AppFailure(
          FailureKind.unsupported,
          '此视频缺少可用的 AVC 视频或 AAC 音轨',
        );
      }
      final video = videos.first;
      final audio = audios.first;
      for (final url in [video.baseUrl, audio.baseUrl]) {
        final uri = Uri.parse(url);
        if (uri.scheme != 'https' || uri.host.isEmpty) {
          throw const FormatException('Invalid media');
        }
      }
      return Success(
        PlaybackSource(
          videoUrl: video.baseUrl,
          audioUrl: audio.baseUrl,
          duration: Duration(milliseconds: jsonInteger(data['timelength'])),
          quality: video.id,
          codec: video.codecs,
        ),
      );
    } catch (error) {
      return ResultFailure(safeApiFailure(error));
    }
  }
}
