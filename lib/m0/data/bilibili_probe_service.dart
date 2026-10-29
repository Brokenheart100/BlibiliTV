import 'dart:io';

import 'package:dio/dio.dart';

import '../../data/repositories/bilibili_playback_repository.dart';
import '../domain/probe_models.dart';
import 'wbi_signer.dart';

/// Temporary M0 protocol spike, not the production Repository implementation.
class BilibiliProbeService {
  BilibiliProbeService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
              headers: mediaHeaders,
            ),
          );

  static const mediaHeaders = <String, String>{
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com/',
  };
  final Dio _dio;
  String? _cookie;
  String? _imageKey;
  String? _subKey;
  ProbeMedia? media;

  void close() => _dio.close(force: true);
  void setCookie(String? value) => _cookie = value;

  Future<Map<String, Object?>> _get(
    String path, {
    Map<String, Object>? query,
    CancelToken? cancelToken,
    bool passport = false,
    bool allowLoggedOut = false,
    String? cookieOverride,
  }) async {
    final response = await _dio.get<Object?>(
      '${passport ? 'https://passport.bilibili.com' : 'https://api.bilibili.com'}$path',
      queryParameters: query,
      cancelToken: cancelToken,
      options: Options(
        headers: {
          if ((cookieOverride ?? _cookie) != null)
            'Cookie': cookieOverride ?? _cookie,
        },
      ),
    );
    final root = objectMap(response.data);
    final code = root['code'];
    if (code != 0 && !(allowLoggedOut && code == -101)) {
      throw ProbeFailure('business:$code');
    }
    return objectMap(root['data']);
  }

  Future<Map<String, Object>> _signed(
    Map<String, Object> query,
    CancelToken? token,
  ) async {
    if (_imageKey == null || _subKey == null) {
      final nav = await _get(
        '/x/web-interface/nav',
        cancelToken: token,
        allowLoggedOut: true,
      );
      final images = objectMap(nav['wbi_img']);
      String key(Object? value) =>
          Uri.parse(value! as String).pathSegments.last.split('.').first;
      _imageKey = key(images['img_url']);
      _subKey = key(images['sub_url']);
    }
    return signWbi(
      query,
      _imageKey!,
      _subKey!,
      timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  Future<List<ProbeCheck>> probeGuest({CancelToken? cancelToken}) async {
    final checks = <ProbeCheck>[];
    media = null;
    Map<String, Object?>? sample;
    Future<void> check(String name, Future<String> Function() body) async {
      try {
        checks.add(
          ProbeCheck(capability: name, passed: true, detail: await body()),
        );
      } catch (error) {
        if (error is DioException && CancelToken.isCancel(error)) rethrow;
        checks.add(
          ProbeCheck(
            capability: name,
            passed: false,
            detail: describeFailure(error),
          ),
        );
      }
    }

    await check('popular', () async {
      final data = await _get(
        '/x/web-interface/popular',
        query: {'pn': 1, 'ps': 20},
        cancelToken: cancelToken,
      );
      final items = (data['list']! as List<Object?>).map(objectMap).toList();
      sample = items.where((item) => (item['duration']! as num) >= 30).first;
      return 'items=${items.length}; sample=${sample!['bvid']}';
    });
    await check('search', () async {
      final query = await _signed({
        'search_type': 'video',
        'keyword': 'Flutter',
        'page': 1,
      }, cancelToken);
      final data = await _get(
        '/x/web-interface/wbi/search/type',
        query: query,
        cancelToken: cancelToken,
      );
      return 'results=${(data['result']! as List<Object?>).length}';
    });
    if (sample != null) {
      final bvid = sample!['bvid']! as String;
      await check('detail_and_parts', () async {
        final data = await _get(
          '/x/web-interface/wbi/view',
          query: await _signed({'bvid': bvid}, cancelToken),
          cancelToken: cancelToken,
        );
        sample = data;
        return 'bvid=$bvid; parts=${(data['pages']! as List<Object?>).length}';
      });
      await check('dash_playback_source', () async {
        final cid = (sample!['cid']! as num).toInt();
        final data = await _get(
          '/x/player/wbi/playurl',
          query: await _signed({
            'bvid': bvid,
            'cid': cid,
            'qn': 32,
            'fnval': 4048,
            'fnver': 0,
            'fourk': 1,
          }, cancelToken),
          cancelToken: cancelToken,
        );
        final dash = objectMap(data['dash']);
        final videos = (dash['video']! as List<Object?>)
            .map(objectMap)
            .where((item) => (item['codecs']! as String).startsWith('avc1'))
            .toList();
        videos.sort(
          (a, b) => (a['bandwidth']! as num).compareTo(b['bandwidth']! as num),
        );
        final video = videos.first;
        media = ProbeMedia(
          bvid: bvid,
          cid: cid,
          source: decodeDashPlayback(
            data,
            quality: (video['id']! as num).toInt(),
          ),
        );
        return 'bvid=$bvid; cid=$cid; video=${videos.length}; audio=${(dash['audio']! as List<Object?>).length}; codec=${media!.codec}; quality=${media!.quality}';
      });
    }
    return checks;
  }

  Future<QrChallenge> createQr(CancelToken token) async {
    final data = await _get(
      '/x/passport-login/web/qrcode/generate',
      passport: true,
      cancelToken: token,
    );
    return QrChallenge(data['qrcode_key']! as String, data['url']! as String);
  }

  Future<QrPoll> pollQr(QrChallenge challenge, CancelToken token) async {
    final response = await _dio.get<Object?>(
      'https://passport.bilibili.com/x/passport-login/web/qrcode/poll',
      queryParameters: {'qrcode_key': challenge.key},
      cancelToken: token,
    );
    final root = objectMap(response.data);
    if (root['code'] != 0) throw ProbeFailure('business:${root['code']}');
    final data = objectMap(root['data']);
    final code = (data['code']! as num).toInt();
    if (code != 0) return QrPoll(code);
    final values = response.headers['set-cookie'] ?? <String>[];
    final cookies = values.map(Cookie.fromSetCookieValue).toList();
    if (!cookies.any((cookie) => cookie.name == 'SESSDATA')) {
      throw const ProbeFailure('missing_login_cookie');
    }
    final cookie = cookies
        .map((item) => '${item.name}=${item.value}')
        .join('; ');
    return QrPoll(code, cookie: cookie);
  }

  Future<bool> verifySession(CancelToken token, {String? cookie}) async {
    final data = await _get(
      '/x/web-interface/nav',
      cancelToken: token,
      cookieOverride: cookie,
    );
    return data['isLogin'] == true;
  }
}

Map<String, Object?> objectMap(Object? value) {
  if (value is! Map<Object?, Object?>) {
    throw const FormatException('Expected object');
  }
  return Map<String, Object?>.from(value);
}

String describeFailure(Object error) => switch (error) {
  ProbeFailure(:final category) => category,
  DioException(:final response, :final type) =>
    'network:${response?.statusCode ?? type.name}',
  FormatException() ||
  TypeError() ||
  StateError() => 'contract_or_media_unavailable',
  _ => 'unexpected:${error.runtimeType}',
};

class ProbeFailure implements Exception {
  const ProbeFailure(this.category);
  final String category;
  @override
  String toString() => category;
}
