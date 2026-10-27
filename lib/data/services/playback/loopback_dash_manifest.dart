import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Exposes only an unguessable, memory-only MPD on the app's loopback address.
/// Media bytes are fetched directly by Media3 from the signed HTTPS CDN URLs.
class LoopbackDashManifest {
  LoopbackDashManifest._(this._server, this.uri);
  final HttpServer _server;
  final Uri uri;
  Future<void>? _closing;

  static Future<LoopbackDashManifest> serve(String manifest) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final random = Random.secure();
    final token = base64UrlEncode(
      List.generate(24, (_) => random.nextInt(256)),
    );
    final path = '/$token.mpd';
    final bytes = utf8.encode(manifest);
    server.listen((request) async {
      try {
        if (request.uri.path != path ||
            request.method != 'GET' && request.method != 'HEAD') {
          request.response.statusCode = HttpStatus.notFound;
        } else {
          request.response.headers.contentType = ContentType(
            'application',
            'dash+xml',
            charset: 'utf-8',
          );
          request.response.headers.set(
            HttpHeaders.cacheControlHeader,
            'no-store',
          );
          request.response.contentLength = bytes.length;
          if (request.method == 'GET') request.response.add(bytes);
        }
        await request.response.close();
      } catch (_) {
        // A disconnected native client must not escape into the app's zone.
      }
    });
    return LoopbackDashManifest._(
      server,
      Uri.parse('http://127.0.0.1:${server.port}$path'),
    );
  }

  Future<void> close() =>
      _closing ??= _server.close(force: true).then<void>((_) {});
}
