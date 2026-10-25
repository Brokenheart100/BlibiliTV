import 'dart:convert';

import '../../core/result.dart';
import '../../domain/entities/app_models.dart';
import '../../domain/repositories/repositories.dart';
import '../services/local/local_stores.dart';

class LocalSettingsRepository implements SettingsRepository {
  const LocalSettingsRepository(this._store);
  final PreferencesStore _store;
  @override
  Future<Result<AppSettings>> load() async {
    try {
      final stored = await _store.read('app.preferences.v1');
      if (stored == null) return const Success(AppSettings());
      final values = jsonDecode(stored) as Map<String, Object?>;
      return Success(
        AppSettings(
          reducedMotion: values['reducedMotion'] as bool? ?? false,
          resumePlayback: values['resumePlayback'] as bool? ?? true,
          defaultRate:
              values['defaultRate'] is num &&
                  (values['defaultRate']! as num) >= .5 &&
                  (values['defaultRate']! as num) <= 2
              ? (values['defaultRate']! as num).toDouble()
              : 1,
          defaultQuality:
              const [
                0,
                16,
                32,
                64,
                80,
                112,
                116,
              ].contains(values['defaultQuality'])
              ? values['defaultQuality']! as int
              : 0,
          autoNext: values['autoNext'] as bool? ?? false,
          syncHistory: values['syncHistory'] as bool? ?? false,
        ),
      );
    } catch (_) {
      return const ResultFailure(
        AppFailure(FailureKind.storage, '本地设置暂时无法读取，请重试'),
      );
    }
  }

  @override
  Future<Result<void>> save(AppSettings settings) async {
    try {
      // One preference write avoids partially committing a multi-key update.
      await _store.write(
        'app.preferences.v1',
        jsonEncode({
          'reducedMotion': settings.reducedMotion,
          'resumePlayback': settings.resumePlayback,
          'defaultRate': settings.defaultRate,
          'defaultQuality': settings.defaultQuality,
          'autoNext': settings.autoNext,
          'syncHistory': settings.syncHistory,
        }),
      );
      return const Success(null);
    } catch (_) {
      return const ResultFailure(AppFailure(FailureKind.storage, '设置未能保存，请重试'));
    }
  }
}
