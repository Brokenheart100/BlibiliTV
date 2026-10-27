import 'package:mambatv/core/result.dart';
import 'package:mambatv/domain/overlays/overlays.dart';

class FakeOverlays implements SubtitleRepository, DanmakuRepository {
  List<SubtitleTrack> available = const [];
  Map<String, List<SubtitleCue>> contents = {};
  Map<int, List<DanmakuItem>> segments = {};
  final signals = <CancellationSignal>[];
  final requested = <int>[];
  @override
  Future<Result<List<SubtitleTrack>>> tracks(
    String videoId,
    String partId,
    CancellationSignal cancellation,
  ) async {
    signals.add(cancellation);
    return Success(available);
  }

  @override
  Future<Result<List<SubtitleCue>>> cues(
    String trackId,
    CancellationSignal cancellation,
  ) async {
    signals.add(cancellation);
    return Success(contents[trackId] ?? []);
  }

  @override
  Future<Result<DanmakuManifest>> manifest(
    String videoId,
    String partId,
    CancellationSignal cancellation,
  ) async {
    signals.add(cancellation);
    return const Success(DanmakuManifest(360000, 4));
  }

  @override
  Future<Result<List<DanmakuItem>>> segment(
    String partId,
    int index,
    CancellationSignal cancellation,
  ) async {
    signals.add(cancellation);
    requested.add(index);
    return Success(segments[index] ?? []);
  }
}

class MemoryOverlayPreferences implements OverlayPreferencesRepository {
  OverlayPreferences preferences = const OverlayPreferences();
  @override
  Future<OverlayPreferences> load() async => preferences;
  @override
  Future<void> save(OverlayPreferences preferences) async {
    this.preferences = preferences;
  }
}
