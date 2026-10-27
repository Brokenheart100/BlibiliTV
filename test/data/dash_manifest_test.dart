import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:mambatv/data/services/playback/dash_manifest.dart';
import 'package:mambatv/data/services/playback/loopback_dash_manifest.dart';
import 'package:mambatv/core/result.dart';

import '../support/dash_source.dart';
import '../support/fake_playback.dart';

void main() {
  test(
    'MPD preserves both signed URLs, codecs and independent byte ranges',
    () {
      final raw = buildDashManifest(dashSource);
      final xml = XmlDocument.parse(raw);
      expect(xml.rootElement.name.local, 'MPD');
      expect(
        xml.rootElement.getAttribute('mediaPresentationDuration'),
        'PT120.0S',
      );
      expect(xml.findAllElements('AdaptationSet').length, 2);
      expect(xml.findAllElements('BaseURL').map((e) => e.innerText), [
        dashSource.videoUrl,
        dashSource.audioUrl,
      ]);
      expect(raw, contains('&amp;'));
      expect(
        xml
            .findAllElements('SegmentBase')
            .map((e) => e.getAttribute('indexRange')),
        ['1000-1999', '700-999'],
      );
      expect(
        xml
            .findAllElements('Representation')
            .map((e) => e.getAttribute('codecs')),
        ['avc1.64001F', 'mp4a.40.2'],
      );
    },
  );
  test(
    'backup URLs retain DASH metadata without changing the selected tracks',
    () {
      final alternate = dashSource.alternate!;
      final xml = XmlDocument.parse(buildDashManifest(alternate));
      expect(xml.findAllElements('BaseURL').map((e) => e.innerText), [
        alternate.videoUrl,
        alternate.audioUrl,
      ]);
      expect(alternate.videoDash, same(dashSource.videoDash));
      expect(alternate.audioDash, same(dashSource.audioDash));
      expect(alternate.toString(), isNot(contains('https:')));
      expect(
        () => buildDashManifest(syntheticSource),
        throwsA(isA<AppFailure>()),
      );
    },
  );
  test(
    'loopback manifest serves only its nonce and closes with the engine',
    () async {
      final server = await LoopbackDashManifest.serve(
        buildDashManifest(dashSource),
      );
      final client = HttpClient();
      try {
        expect(server.uri.host, '127.0.0.1');
        final response = await (await client.getUrl(server.uri)).close();
        expect(response.statusCode, 200);
        expect(response.headers.contentType!.mimeType, 'application/dash+xml');
        expect(response.headers.value('cache-control'), 'no-store');
        await response.drain<void>();
        final wrong = await (await client.getUrl(
          server.uri.replace(path: '/other.mpd'),
        )).close();
        expect(wrong.statusCode, 404);
        await wrong.drain<void>();
        await server.close();
        final closedClient = HttpClient();
        try {
          await expectLater(() async {
            final request = await closedClient.getUrl(server.uri);
            await request.close();
          }, throwsA(isA<IOException>()));
        } finally {
          closedClient.close(force: true);
        }
      } finally {
        client.close(force: true);
        await server.close();
      }
    },
  );
}
