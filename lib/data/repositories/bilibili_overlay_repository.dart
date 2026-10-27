import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../core/result.dart';
import '../../domain/overlays/overlays.dart';
import '../services/bilibili/bilibili_api.dart';
import '../services/bilibili/bilibili_dto.dart';
import '../services/danmaku/generated/danmaku.pb.dart' as wire;

/// Signed subtitle resource locators remain here, never in domain/UI state.
class BilibiliOverlayRepository
    implements SubtitleRepository, DanmakuRepository {
  BilibiliOverlayRepository(this.api, {this.onDiagnostic});
  final BilibiliApi api;
  final void Function(String stage, String category)? onDiagnostic;
  final _scope = CancellationSignal();
  final _tracks = <String, Uri>{};
  void close() {
    _scope.cancel();
    _tracks.clear();
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    if (_scope.isCancelled) {
      throw const AppFailure(FailureKind.cancelled, '增强加载已取消');
    }
    late final T result;
    try {
      result = await action();
    } catch (error) {
      onDiagnostic?.call('operation', error.runtimeType.toString());
      rethrow;
    }
    if (_scope.isCancelled) {
      throw const AppFailure(FailureKind.cancelled, '增强加载已取消');
    }
    return result;
  }

  @override
  Future<Result<List<SubtitleTrack>>> tracks(
    String videoId,
    String partId,
    CancellationSignal cancellation,
  ) async {
    try {
      return Success(
        await _guard(() async {
          final data = await api.get(
            '/x/player/wbi/v2',
            cancellation,
            signed: true,
            query: {'bvid': videoId, 'cid': partId},
          );
          final subtitle = data['subtitle'] as Map<String, Object?>?;
          final rows = subtitle?['subtitles'] as List<Object?>? ?? [];
          final result = <SubtitleTrack>[];
          for (final value in rows.take(32)) {
            final row = jsonObject(value);
            final id = '$videoId:$partId:${row['id_str'] ?? row['id']}';
            final raw = row['subtitle_url'];
            if (raw is! String) continue;
            final uri = Uri.tryParse(raw.startsWith('//') ? 'https:$raw' : raw);
            if (uri == null ||
                uri.scheme != 'https' ||
                uri.userInfo.isNotEmpty ||
                uri.port != 443 ||
                !(uri.host.endsWith('.hdslb.com') ||
                    uri.host.endsWith('.bilibili.com'))) {
              continue;
            }
            _tracks[id] = uri;
            while (_tracks.length > 96) {
              _tracks.remove(_tracks.keys.first);
            }
            result.add(
              SubtitleTrack(
                id: id,
                language: row['lan'] as String? ?? '',
                title: row['lan_doc'] as String? ?? '字幕',
                ai:
                    row['ai_type'] != null && row['ai_type'] != 0 ||
                    (row['lan'] as String? ?? '').startsWith('ai-'),
              ),
            );
          }
          return result;
        }),
      );
    } catch (e) {
      return ResultFailure(safeApiFailure(e));
    }
  }

  Future<List<int>> _bytes(
    Uri uri,
    CancellationSignal cancellation, {
    Map<String, Object> query = const {},
  }) async {
    final token = CancelToken();
    final cancel = cancellation.onCancel(() => token.cancel('cancelled'));
    final cancelScope = _scope.onCancel(() => token.cancel('closed'));
    try {
      final response = await api.client.get<ResponseBody>(
        uri.toString(),
        queryParameters: query,
        cancelToken: token,
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: false,
          headers: bilibiliMediaHeaders,
        ),
      );
      final declared = int.tryParse(
        response.headers.value('content-length') ?? '',
      );
      if (declared != null && declared > 2 * 1024 * 1024) {
        token.cancel('size');
        throw const FormatException('Resource size');
      }
      final output = BytesBuilder(copy: false);
      await for (final chunk in response.data!.stream) {
        if (output.length + chunk.length > 8 * 1024 * 1024) {
          token.cancel('size');
          throw const FormatException('Decoded size');
        }
        output.add(chunk);
      }
      if (cancellation.isCancelled || _scope.isCancelled) {
        throw const AppFailure(FailureKind.cancelled, '增强加载已取消');
      }
      return output.takeBytes();
    } finally {
      cancel();
      cancelScope();
    }
  }

  @override
  Future<Result<List<SubtitleCue>>> cues(
    String trackId,
    CancellationSignal cancellation,
  ) async {
    try {
      return Success(
        await _guard(() async {
          final uri = _tracks[trackId];
          if (uri == null) {
            throw const AppFailure(
              FailureKind.resourceExpired,
              '字幕资源已过期，请重新加载轨道',
            );
          }
          final bytes = await _bytes(uri, cancellation);
          return decodeSubtitle(bytes);
        }),
      );
    } catch (e) {
      return ResultFailure(safeApiFailure(e));
    }
  }

  @override
  Future<Result<DanmakuManifest>> manifest(
    String videoId,
    String partId,
    CancellationSignal cancellation,
  ) async {
    try {
      return Success(
        await _guard(() async {
          final bytes = await _bytes(
            Uri.https('api.bilibili.com', '/x/v2/dm/web/view'),
            cancellation,
            query: {'type': 1, 'oid': partId},
          );
          final config = wire.WebView.fromBuffer(bytes).dmSge;
          onDiagnostic?.call(
            'manifest',
            'bytes:${bytes.length},size:${config.pageSize},total:${config.total}',
          );
          final segmentMs = config.pageSize.toInt(),
              total = config.total.toInt();
          if (segmentMs <= 0 ||
              segmentMs > 3600000 ||
              total < 0 ||
              total > 10000) {
            throw const FormatException('Segment metadata');
          }
          return DanmakuManifest(segmentMs, total);
        }),
      );
    } catch (e) {
      onDiagnostic?.call('failure', e.runtimeType.toString());
      return ResultFailure(safeApiFailure(e));
    }
  }

  @override
  Future<Result<List<DanmakuItem>>> segment(
    String partId,
    int index,
    CancellationSignal cancellation,
  ) async {
    try {
      return Success(
        await _guard(() async {
          if (index < 1 || index > 10000) {
            throw const FormatException('Segment index');
          }
          final bytes = await _bytes(
            Uri.https('api.bilibili.com', '/x/v2/dm/web/seg.so'),
            cancellation,
            query: {'type': 1, 'oid': partId, 'segment_index': index},
          );
          return decodeDanmaku(bytes);
        }),
      );
    } catch (e) {
      return ResultFailure(safeApiFailure(e));
    }
  }
}

// Top-level closures capture only bytes, never this repository/Dio/native ports.
Future<List<SubtitleCue>> decodeSubtitle(List<int> bytes) =>
    Isolate.run(() => parseSubtitle(bytes));
Future<List<DanmakuItem>> decodeDanmaku(List<int> bytes) =>
    Isolate.run(() => parseDanmaku(bytes));

List<SubtitleCue> parseSubtitle(List<int> bytes) {
  final body = jsonObject(jsonDecode(utf8.decode(bytes)))['body'];
  if (body is! List || body.length > 20000) {
    throw const FormatException('Subtitle size');
  }
  final cues = <SubtitleCue>[];
  for (final value in body) {
    final row = jsonObject(value);
    final from = row['from'], to = row['to'], text = row['content'];
    if (from is! num ||
        to is! num ||
        !from.isFinite ||
        !to.isFinite ||
        from < 0 ||
        to <= from ||
        text is! String ||
        text.length > 512) {
      continue;
    }
    cues.add(
      SubtitleCue(
        startMs: (from * 1000).round(),
        endMs: (to * 1000).round(),
        text: text.trim(),
      ),
    );
  }
  cues.sort((a, b) => a.startMs.compareTo(b.startMs));
  return List.unmodifiable(cues);
}

List<DanmakuItem> parseDanmaku(List<int> bytes) {
  final message = wire.Segment.fromBuffer(bytes);
  if (message.elems.length > 20000) {
    throw const FormatException('Danmaku count');
  }
  final unique = <String, DanmakuItem>{};
  for (final e in message.elems) {
    if (!const [1, 4, 5].contains(e.mode) ||
        e.progress < 0 ||
        e.content.isEmpty ||
        e.content.length > 512) {
      continue;
    }
    final id = e.idStr.isEmpty ? e.id.toString() : e.idStr;
    unique[id] = DanmakuItem(
      id: id,
      timeMs: e.progress,
      mode: e.mode,
      color: e.color & 0xffffff,
      text: e.content,
    );
  }
  final items = unique.values.toList()
    ..sort(
      (a, b) => a.timeMs != b.timeMs
          ? a.timeMs.compareTo(b.timeMs)
          : a.id.compareTo(b.id),
    );
  return List.unmodifiable(items);
}
