import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/domain/playback/history_progress_reporter.dart';
import 'package:mambatv/domain/playback/playback.dart';

import '../support/fake_library.dart';

void main() {
  test('history reporting requires thirty active seconds, ignores paused time, and cancels on close', () async {
    final repository = FakeLibraryRepository();
    var elapsed = Duration.zero;
    final reporter = HistoryProgressReporter(
      repository,
      'user:101',
      'BVtest',
      '11',
      elapsed: () => elapsed,
    );
    EngineSnapshot snap({bool playing = true, bool buffering = false}) =>
        EngineSnapshot(
          playing: playing,
          buffering: buffering,
          position: const Duration(seconds: 42),
          duration: const Duration(minutes: 2),
        );
    reporter.accept(snap());
    elapsed = const Duration(seconds: 29);
    reporter.accept(snap());
    expect(repository.heartbeats, 0);
    elapsed = const Duration(seconds: 30);
    reporter.accept(snap());
    await Future<void>.delayed(Duration.zero);
    expect(repository.heartbeats, 1);
    reporter.accept(snap(playing: false));
    elapsed = const Duration(minutes: 3);
    reporter.accept(snap());
    await Future<void>.delayed(Duration.zero);
    expect(repository.heartbeats, 1);
    elapsed += const Duration(seconds: 30);
    reporter.accept(snap());
    await Future<void>.delayed(Duration.zero);
    expect(repository.heartbeats, 2);
    reporter.close();
    elapsed += const Duration(minutes: 1);
    reporter.accept(snap());
    expect(repository.heartbeats, 2);
  });
}
