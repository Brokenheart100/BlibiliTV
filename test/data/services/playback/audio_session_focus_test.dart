import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/data/services/playback/audio_session_focus.dart';

class SessionFake extends Fake implements AudioSession {
  final interruptions = StreamController<AudioInterruptionEvent>.broadcast(
    sync: true,
  );
  final noisy = StreamController<void>.broadcast(sync: true);
  final activeCalls = <bool>[];
  AudioSessionConfiguration? configured;
  bool granted = true;
  Completer<bool>? activation;
  @override
  Future<void> configure(AudioSessionConfiguration configuration) async {
    configured = configuration;
  }

  @override
  Stream<AudioInterruptionEvent> get interruptionEventStream =>
      interruptions.stream;
  @override
  Stream<void> get becomingNoisyEventStream => noisy.stream;
  @override
  Future<bool> setActive(
    bool active, {
    AVAudioSessionSetActiveOptions? avAudioSessionSetActiveOptions,
    AndroidAudioFocusGainType? androidAudioFocusGainType,
    AndroidAudioAttributes? androidAudioAttributes,
    bool? androidWillPauseWhenDucked,
    AudioSessionConfiguration fallbackConfiguration =
        const AudioSessionConfiguration.music(),
  }) async {
    activeCalls.add(active);
    return active ? await activation?.future ?? granted : true;
  }

  Future<void> close() async {
    await interruptions.close();
    await noisy.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SessionFake session;
  late AudioSessionFocus focus;
  setUp(() {
    session = SessionFake();
    focus = AudioSessionFocus(sessionFactory: () async => session);
  });
  tearDown(() async {
    await focus.dispose();
    await session.close();
  });
  test('configures media/movie focus and pauses rather than ducking', () async {
    await focus.acquire(Object());
    expect(
      session.configured!.androidAudioAttributes!.contentType,
      AndroidAudioContentType.movie,
    );
    expect(
      session.configured!.androidAudioAttributes!.usage,
      AndroidAudioUsage.media,
    );
    expect(session.configured!.androidWillPauseWhenDucked, isTrue);
  });
  test('old route disposal cannot abandon a newer owner audio focus', () async {
    final old = Object(), current = Object();
    await focus.acquire(old);
    await focus.acquire(current);
    await focus.release(old);
    expect(session.activeCalls, [true, true]);
    await focus.release(current);
    expect(session.activeCalls, [true, true, false]);
  });
  test(
    'acquire and release serialize across an in-flight native request',
    () async {
      final owner = Object();
      session.activation = Completer<bool>();
      final acquiring = focus.acquire(owner);
      await Future<void>.delayed(Duration.zero);
      final releasing = focus.release(owner);
      expect(session.activeCalls, [true]);
      session.activation!.complete(true);
      await acquiring;
      await releasing;
      expect(session.activeCalls, [true, false]);
    },
  );
  test(
    'denied focus has no owner and cannot accidentally release another session',
    () async {
      session.granted = false;
      final owner = Object();
      expect(await focus.acquire(owner), isFalse);
      await focus.release(owner);
      expect(session.activeCalls, [true]);
    },
  );
  test('interruption beginnings and noisy events pause, focus gains never auto-resume', () async {
    var interruptions = 0;
    final listener = focus.interruptions.listen((_) => interruptions++);
    await focus.acquire(Object());
    session.interruptions.add(
      AudioInterruptionEvent(true, AudioInterruptionType.duck),
    );
    session.interruptions.add(
      AudioInterruptionEvent(false, AudioInterruptionType.pause),
    );
    session.noisy.add(null);
    expect(interruptions, 2);
    await listener.cancel();
  });
  test(
    'dispose during activation releases the late grant once and is idempotent',
    () async {
      session.activation = Completer<bool>();
      final acquiring = focus.acquire(Object());
      await Future<void>.delayed(Duration.zero);
      final closing = focus.dispose();
      session.activation!.complete(true);
      await acquiring;
      await closing;
      await focus.dispose();
      expect(session.activeCalls, [true, false]);
      expect(await focus.acquire(Object()), isFalse);
    },
  );
}
