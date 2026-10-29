import '../../core/result.dart';
import '../../domain/playback/content_playback.dart';
import '../../domain/playback/playback.dart';
import '../services/bilibili/bilibili_api.dart';
import '../services/bilibili/bilibili_dto.dart';

class BilibiliLiveRepository implements LiveRepository {
  BilibiliLiveRepository(this.api);
  final BilibiliApi api;
  @override
  Future<Result<PageSlice<LiveRoom>>> browse(
    CancellationSignal cancellation, {
    int page = 1,
    String keyword = '',
  }) async {
    try {
      final data = await api.getLive(
        '/xlive/web-interface/v1/second/getUserRecommend',
        cancellation,
        query: {'page': page, 'page_size': 24},
      );
      final raw = data['room_list'] ?? data['list'];
      if (raw == null) throw const FormatException('Unsupported live catalog');
      final rows = jsonList(raw)
          .map(jsonObject)
          .map(
            (e) => LiveRoom(
              id: '${jsonInteger(e['roomid'] ?? e['room_id'])}',
              title: (e['title'] ?? '') as String,
              creator: (e['uname'] ?? '') as String,
              live: true,
              coverUrl: avatarUrl(e['cover'] ?? e['user_cover']),
            ),
          )
          .toList();
      return Success(
        PageSlice(
          items: rows,
          nextCursor: rows.length == 24 ? '${page + 1}' : null,
        ),
      );
    } catch (e) {
      return ResultFailure(safeApiFailure(e));
    }
  }

  @override
  Future<Result<LiveRoom>> room(
    String id,
    CancellationSignal cancellation,
  ) async {
    try {
      final data = await api.getLive(
        '/xlive/web-room/v1/index/getH5InfoByRoom',
        cancellation,
        query: {'room_id': int.parse(id)},
      );
      final info = jsonObject(data['room_info']);
      final anchor = jsonObject(jsonObject(data['anchor_info'])['base_info']);
      return Success(
        LiveRoom(
          id: '${jsonInteger(info['room_id'])}',
          title: (info['title'] ?? '') as String,
          creator: (anchor['uname'] ?? '') as String,
          coverUrl: avatarUrl(info['cover']),
          live: jsonInteger(info['live_status']) == 1,
          locked: info['is_locked'] == true || info['encrypted'] == true,
        ),
      );
    } catch (e) {
      return ResultFailure(safeApiFailure(e));
    }
  }

  @override
  Future<Result<PlaybackSource>> resolve(
    String roomId,
    CancellationSignal cancellation, {
    int? quality,
  }) async {
    try {
      final data = await api.getLive(
        '/xlive/web-room/v2/index/getRoomPlayInfo',
        cancellation,
        query: {
          'room_id': int.parse(roomId),
          'protocol': '0,1',
          'format': '0,1,2',
          'codec': '0',
          'qn': quality ?? 80,
          'platform': 'web',
          'ptype': 8,
        },
      );
      if (jsonInteger(data['live_status'] ?? 0) != 1) {
        throw const AppFailure(FailureKind.unavailable, '主播当前未开播');
      }
      if (data['is_locked'] == true ||
          data['is_hidden'] == true ||
          data['encrypted'] == true) {
        throw const AppFailure(FailureKind.permission, '当前直播间受限，无法播放');
      }
      final play = jsonObject(jsonObject(data['playurl_info'])['playurl']);
      final options = <PlaybackOption>[];
      for (final q in jsonList(play['g_qn_desc'] ?? const []).map(jsonObject)) {
        options.add(
          PlaybackOption(
            jsonInteger(q['qn']),
            (q['desc'] ?? '${q['qn']}') as String,
          ),
        );
      }
      for (final stream in jsonList(play['stream']).map(jsonObject)) {
        if (stream['protocol_name'] != 'http_hls') continue;
        for (final format in jsonList(stream['format']).map(jsonObject)) {
          if (format['format_name'] != 'ts') continue;
          for (final codec in jsonList(format['codec']).map(jsonObject)) {
            if (codec['codec_name'] != 'avc') continue;
            final urls = <String>[];
            for (final info in jsonList(codec['url_info']).map(jsonObject)) {
              final url =
                  '${info['host']}${codec['base_url']}${info['extra'] ?? ''}';
              final uri = Uri.tryParse(url);
              if (uri != null &&
                  uri.scheme == 'https' &&
                  uri.userInfo.isEmpty &&
                  (uri.host.endsWith('.bilivideo.com') ||
                      uri.host.endsWith('.bilivideo.cn') ||
                      uri.host.endsWith('.mcdn.bilivideo.cn'))) {
                urls.add(url);
              }
            }
            if (urls.isEmpty) continue;
            final accepted = jsonList(codec['accept_qn'] ?? const [])
                .map(jsonInteger)
                .toSet();
            return Success(
              PlaybackSource(
                videoUrl: urls.first,
                audioUrl: '',
                duration: Duration.zero,
                quality: jsonInteger(codec['current_qn']),
                codec: 'avc',
                transport: PlaybackTransport.hls,
                videoBackups: urls.skip(1).toList(),
                headers: {
                  ...bilibiliMediaHeaders,
                  'Referer': 'https://live.bilibili.com/$roomId',
                },
                qualities: options
                    .map(
                      (q) => accepted.contains(q.id)
                          ? q
                          : PlaybackOption(
                              q.id,
                              q.label,
                              reason: '当前直播源未提供此档位',
                            ),
                    )
                    .toList(),
              ),
            );
          }
        }
      }
      throw const AppFailure(FailureKind.unsupported, '当前直播未提供受支持的 HLS／AVC 源');
    } catch (e) {
      return ResultFailure(safeApiFailure(e));
    }
  }
}
