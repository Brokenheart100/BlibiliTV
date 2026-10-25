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
    int? quality,
    int? audioId,
  }) async {
    try {
      final data = await api.get(
        '/x/player/wbi/playurl',
        cancellation,
        signed: true,
        query: {
          'bvid': videoId,
          'cid': int.parse(partId),
          'qn': quality ?? 32,
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
      List<Map<String, Object?>> tracks(String kind, String codec) =>
          jsonList(dash[kind])
              .map(jsonObject)
              .where(
                (track) => (track['codecs'] as String? ?? '').startsWith(codec),
              )
              .toList()
            ..sort(
              (a, b) =>
                  jsonInteger(a['bandwidth'])
                      .compareTo(jsonInteger(b['bandwidth'])),
            );
      final videos = tracks('video', 'avc1');
      final audios = tracks('audio', 'mp4a');
      if (videos.isEmpty || audios.isEmpty) {
        throw const AppFailure(
          FailureKind.unsupported,
          '此视频缺少可用的 AVC 视频或 AAC 音轨',
        );
      }
      final available = videos.map((v) => jsonInteger(v['id'])).toSet();
      final qualities = <int, PlaybackOption>{
        for (final id in available) id: PlaybackOption(id, qualityLabel(id)),
      };
      for (final value in jsonList(data['support_formats'] ?? const [])) {
        final format = jsonObject(value);
        final id = jsonInteger(format['quality']);
        qualities.putIfAbsent(
          id,
          () => PlaybackOption(
            id,
            qualityLabel(id),
            reason: '当前账号或 AVC 播放能力未提供此清晰度',
          ),
        );
      }
      if (quality != null && !available.contains(quality)) {
        throw const AppFailure(
          FailureKind.permission,
          '当前账号或设备暂不可用此清晰度，请选择其他档位',
        );
      }
      final video = quality == null
          ? videos.first
          : videos.firstWhere((v) => jsonInteger(v['id']) == quality);
      final matchingAudio = audios.where(
        (a) => jsonInteger(a['id']) == audioId,
      );
      if (audioId != null && matchingAudio.isEmpty) {
        throw const AppFailure(FailureKind.unsupported, '此分集没有所选 AAC 音轨');
      }
      final audio = audioId == null ? audios.first : matchingAudio.first;
      List<String> urls(Map<String, Object?> track) {
        final base = track['baseUrl'] ?? track['base_url'];
        final backups =
            track['backupUrl'] ?? track['backup_url'] ?? const <Object?>[];
        final result = <String>[];
        for (final value in [base, ...jsonList(backups)]) {
          if (value is! String) continue;
          final uri = Uri.tryParse(value);
          if (uri != null &&
              uri.scheme == 'https' &&
              uri.host.isNotEmpty &&
              uri.userInfo.isEmpty &&
              !result.contains(value)) {
            result.add(value);
          }
        }
        if (result.isEmpty) throw const FormatException('Invalid media');
        return result;
      }

      final videoUrls = urls(video), audioUrls = urls(audio);
      final qualityOptions = qualities.values.toList()
        ..sort((a, b) => b.id.compareTo(a.id));
      final audioOptions = <int, PlaybackOption>{
        for (final a in audios)
          jsonInteger(a['id']): PlaybackOption(
            jsonInteger(a['id']),
            'AAC · ${(jsonInteger(a['bandwidth']) / 1000).round()} kbps',
          ),
      };
      return Success(
        PlaybackSource(
          videoUrl: videoUrls.first,
          audioUrl: audioUrls.first,
          videoBackups: videoUrls.skip(1).toList(),
          audioBackups: audioUrls.skip(1).toList(),
          duration: Duration(milliseconds: jsonInteger(data['timelength'])),
          quality: jsonInteger(video['id']),
          codec: video['codecs']! as String,
          qualities: qualityOptions,
          audioTracks: audioOptions.values.toList(),
          audioId: jsonInteger(audio['id']),
        ),
      );
    } catch (error) {
      return ResultFailure(safeApiFailure(error));
    }
  }
}
