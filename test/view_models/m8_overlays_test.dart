import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/app/providers/overlay_providers.dart';
import 'package:mambatv/app/providers/ui_providers.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/domain/overlays/overlays.dart';
import 'package:mambatv/ui/features/player/view_models/overlay_view_models.dart';

import '../support/fake_overlays.dart';

class DeferredSubtitles extends FakeOverlays {
  bool defer = false;
  final pending = <String, Completer<Result<List<SubtitleCue>>>>{};
  @override
  Future<Result<List<SubtitleCue>>> cues(
    String trackId,
    CancellationSignal cancellation,
  ) {
    signals.add(cancellation);
    if (!defer) return Future.value(Success(contents[trackId] ?? []));
    final gate = Completer<Result<List<SubtitleCue>>>();
    pending[trackId] = gate;
    return gate.future;
  }
}

class DeferredSegments extends FakeOverlays {
  final gate = Completer<Result<List<DanmakuItem>>>();
  @override
  Future<Result<List<DanmakuItem>>> segment(
    String partId,
    int index,
    CancellationSignal cancellation,
  ) {
    signals.add(cancellation);
    requested.add(index);
    if (index == 1) return gate.future;
    return Future.value(
      Success([
        DanmakuItem(
          id: '$index',
          timeMs: index * 360000,
          mode: 1,
          color: 0xffffff,
          text: 'synthetic',
        ),
      ]),
    );
  }
}

void main() {
  test(
    'track choice outlives an engine but is scoped to the current content',
    () async {
      final repo = FakeOverlays()
        ..available = const [
          SubtitleTrack(id: 'a', language: 'zh', title: 'A'),
          SubtitleTrack(id: 'b', language: 'en', title: 'B'),
        ];
      final container = ProviderContainer(
        overrides: [
          subtitleRepositoryProvider.overrideWithValue(repo),
          overlayPreferencesRepositoryProvider.overrideWithValue(
            MemoryOverlayPreferences(),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(overlaySettingsViewModelProvider.future);
      final choice = subtitleChoiceProvider(
        videoId: 'v',
        partId: '1',
        scopeKey: 'guest:1',
      );
      final anchor = container.listen(choice, (_, _) {});
      addTearDown(anchor.close);
      final provider = subtitleViewModelProvider(
        videoId: 'v',
        partId: '1',
        scopeKey: 'guest:1',
      );
      var listener = container.listen(provider, (_, _) {});
      await container.read(provider.future);
      await container.read(provider.notifier).select('b');
      listener.close();
      await container.pump();
      listener = container.listen(provider, (_, _) {});
      addTearDown(listener.close);
      expect((await container.read(provider.future)).selected, 'b');
      expect(
        container
            .read(
              subtitleChoiceProvider(
                videoId: 'v',
                partId: '2',
                scopeKey: 'guest:1',
              ),
            )
            .explicit,
        false,
      );
      await container.read(provider.notifier).select(null);
      container.read(appForegroundProvider.notifier).update(false);
      await container.pump();
      container.read(appForegroundProvider.notifier).update(true);
      await container.pump();
      expect((await container.read(provider.future)).selected, isNull);
    },
  );
  test('background cancels media requests even while an enhancement menu watches them', () async {
    final repo = DeferredSegments();
    final container = ProviderContainer(
      overrides: [
        danmakuRepositoryProvider.overrideWithValue(repo),
        overlayPreferencesRepositoryProvider.overrideWithValue(
          MemoryOverlayPreferences()
            ..preferences = const OverlayPreferences(danmaku: true),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(overlaySettingsViewModelProvider.future);
    final provider = danmakuViewModelProvider(
      videoId: 'v',
      partId: '1',
      scopeKey: 'guest:1',
    );
    final listener = container.listen(provider, (_, _) {});
    addTearDown(listener.close);
    await container.read(provider.future);
    container.read(provider.notifier).moveTo(0);
    final pending = repo.signals.last;
    container.read(appForegroundProvider.notifier).update(false);
    await container.pump();
    expect(pending.isCancelled, true);
    repo.gate.complete(const Success([]));
    await container.pump();
    expect((await container.read(provider.future)).items, isEmpty);
  });
  test('late track request cannot replace selection, and style does not refetch tracks', () async {
    final repo = DeferredSubtitles()
      ..available = const [
        SubtitleTrack(id: 'a', language: 'zh', title: 'A'),
        SubtitleTrack(id: 'b', language: 'en', title: 'B'),
      ];
    final prefs = MemoryOverlayPreferences();
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        subtitleRepositoryProvider.overrideWithValue(repo),
        overlayPreferencesRepositoryProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);
    await container.read(overlaySettingsViewModelProvider.future);
    final provider = subtitleViewModelProvider(
      videoId: 'BVsynthetic',
      partId: '1',
      scopeKey: 'guest:1',
    );
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);
    await container.read(provider.future);
    final requests = repo.signals.length;
    await container
        .read(overlaySettingsViewModelProvider.notifier)
        .savePreferences(const OverlayPreferences(fontSize: 32));
    await container.pump();
    expect(repo.signals.length, requests);
    repo.defer = true;
    final first = container.read(provider.notifier).select('a');
    final firstSignal = repo.signals.last;
    final second = container.read(provider.notifier).select('b');
    expect(firstSignal.isCancelled, true);
    repo.pending['b']!.complete(
      const Success([SubtitleCue(startMs: 0, endMs: 1000, text: 'B')]),
    );
    await second;
    repo.pending['a']!.complete(
      const Success([SubtitleCue(startMs: 0, endMs: 1000, text: 'A')]),
    );
    await first;
    expect(container.read(provider).requireValue.selected, 'b');
    expect(container.read(provider).requireValue.cues.single.text, 'B');
  });
  test(
    'seek cancels obsolete segment window; disabling clears pending work',
    () async {
      final repo = DeferredSegments();
      final prefs = MemoryOverlayPreferences()
        ..preferences = const OverlayPreferences(danmaku: true);
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          danmakuRepositoryProvider.overrideWithValue(repo),
          overlayPreferencesRepositoryProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);
      await container.read(overlaySettingsViewModelProvider.future);
      final provider = danmakuViewModelProvider(
        videoId: 'BVsynthetic',
        partId: '1',
        scopeKey: 'guest:1',
      );
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);
      await container.read(provider.future);
      container.read(provider.notifier).moveTo(0);
      final old = repo.signals.last;
      container.read(provider.notifier).moveTo(750000);
      await container.pump();
      expect(old.isCancelled, true);
      repo.gate.complete(
        const Success([
          DanmakuItem(
            id: 'obsolete',
            timeMs: 0,
            mode: 1,
            color: 0xffffff,
            text: 'old',
          ),
        ]),
      );
      await container.pump();
      expect(
        container
            .read(provider)
            .requireValue
            .items
            .any((e) => e.id == 'obsolete'),
        false,
      );
      expect(container.read(provider).requireValue.window, 3);
      await container
          .read(overlaySettingsViewModelProvider.notifier)
          .savePreferences(const OverlayPreferences(danmaku: false));
      await container.pump();
      await container.read(provider.future);
      expect(container.read(provider).requireValue.items, isEmpty);
      expect(repo.signals.last.isCancelled, true);
    },
  );
}
