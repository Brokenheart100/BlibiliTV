import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/domain/playback/playback.dart';
import 'package:mambatv/domain/playback/playback_target.dart';
import 'package:mambatv/ui/features/content/views/content_pages.dart';

void main() {
  test(
    'part replacement retains content identity; live has no episode or resume',
    () {
      const ugc = PlaybackTarget.ugc(bvid: 'BV1wR4Xz6EqG', cid: '1');
      const pgc = PlaybackTarget.pgc(seasonId: '1', episodeId: '1');
      const live = PlaybackTarget.live(roomId: '1');
      expect(ugc.withPart('2').location, '/player/BV1wR4Xz6EqG?part=2');
      expect(pgc.withPart('2').location, '/watch/pgc/1/2');
      expect(live.withPart('2'), live);
      expect(PlaybackCapabilities.live.seek, isFalse);
      expect(PlaybackCapabilities.live.resume, isFalse);
      expect(PlaybackCapabilities.pgc.remoteHistory, isFalse);
      expect(
        const WatchProgress(
          ownerKey: 'guest',
          videoId: '1',
          partId: '',
          kind: ContentKind.live,
          position: Duration(seconds: 20),
          duration: Duration(minutes: 5),
        ).isValid,
        isFalse,
      );
    },
  );
  test('content link input accepts known B站 paths and rejects other schemes and hosts', () {
    expect(
      contentInputId(
        'https://www.bilibili.com/bangumi/play/ss28320?from=test',
        live: false,
      ),
      '28320',
    );
    expect(contentInputId('ss28320', live: false), '28320');
    expect(contentInputId('https://live.bilibili.com/6', live: true), '6');
    for (final bad in [
      'https://evil.invalid/6',
      'http://live.bilibili.com/6',
      'javascript:6',
      '-1',
      '0',
      '6/../7',
    ]) {
      expect(contentInputId(bad, live: true), isNull);
    }
  });
}
