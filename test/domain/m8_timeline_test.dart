import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/domain/playback/playback.dart';
import 'package:mambatv/domain/playback/playback_timeline.dart';
import 'package:mambatv/domain/overlays/overlays.dart';

void main() {
  test('a delayed native sample during normal playback is not a seek', () {
    final timeline = PlaybackTimeline();
    timeline.update(
      const EngineSnapshot(
        playing: true,
        position: Duration(seconds: 10),
        rate: 2,
      ),
      0,
    );
    final generation = timeline.generation;
    expect(
      timeline.update(
        const EngineSnapshot(
          playing: true,
          position: Duration(seconds: 14),
          rate: 2,
        ),
        2000000,
      ),
      isFalse,
    );
    expect(timeline.generation, generation);
    expect(timeline.positionMs(2000000), 14000);
  });
  test('a delayed stationary sample does not clear overlays; reverse seeks still do', () {
    final timeline = PlaybackTimeline();
    timeline.update(
      const EngineSnapshot(playing: true, position: Duration(seconds: 20)),
      0,
    );
    expect(
      timeline.update(
        const EngineSnapshot(playing: true, position: Duration(seconds: 20)),
        2000000,
      ),
      isFalse,
    );
    expect(
      timeline.update(
        const EngineSnapshot(playing: true, position: Duration(seconds: 5)),
        2100000,
      ),
      isTrue,
    );
  });
  test(
    'native clock bounds interpolation and freezes on pause or buffering',
    () {
      final timeline = PlaybackTimeline();
      timeline.update(
        const EngineSnapshot(
          position: Duration(seconds: 10),
          duration: Duration(minutes: 2),
          playing: true,
          rate: 2,
        ),
        1000000,
      );
      expect(timeline.positionMs(1100000), 10200);
      expect(timeline.positionMs(9000000), 10500);
      expect(timeline.advancingAt(9000000), false);
      timeline.update(
        const EngineSnapshot(position: Duration(seconds: 12), playing: false),
        2000000,
      );
      expect(timeline.positionMs(5000000), 12000);
      timeline.update(
        const EngineSnapshot(
          position: Duration(seconds: 15),
          playing: true,
          buffering: true,
        ),
        6000000,
      );
      expect(timeline.positionMs(9000000), 15000);
    },
  );
  test(
    'seek and rate changes reset the generation; reset drops prior media',
    () {
      final timeline = PlaybackTimeline();
      timeline.update(
        const EngineSnapshot(position: Duration(seconds: 10), playing: true),
        0,
      );
      final epoch = timeline.generation;
      expect(
        timeline.update(
          const EngineSnapshot(position: Duration(seconds: 40), playing: true),
          200000,
        ),
        true,
      );
      expect(timeline.generation, epoch + 1);
      timeline.update(
        const EngineSnapshot(position: Duration(seconds: 40), rate: .5),
        200000,
      );
      expect(timeline.generation, epoch + 2);
      timeline.reset();
      expect(timeline.positionMs(100000000), 0);
    },
  );
  test(
    'subtitle sweep handles overlap, equal boundaries, offset and reverse seek',
    () {
      final index = SubtitleIndex(const [
        SubtitleCue(startMs: 1000, endMs: 5000, text: 'long'),
        SubtitleCue(startMs: 2000, endMs: 3000, text: 'short'),
        SubtitleCue(startMs: 3000, endMs: 4000, text: 'next'),
      ]);
      expect(index.at(999, 0), '');
      expect(index.at(2500, 0), 'long\nshort');
      expect(index.at(3000, 0), 'long\nnext');
      expect(index.at(5000, 0), '');
      expect(index.at(1500, 1000), '');
      expect(index.at(1500, -1000), 'long\nshort');
      expect(index.at(1000, 0), 'long');
    },
  );
  test(
    'segment boundary is supplied by metadata and bounded at either end',
    () {
      const manifest = DanmakuManifest(360000, 3);
      expect(manifest.segmentAt(359999), 1);
      expect(manifest.segmentAt(360000), 2);
      expect(manifest.segmentAt(99999999), 3);
      expect(const DanmakuManifest(360000, 0).segmentAt(0), 0);
    },
  );
}
