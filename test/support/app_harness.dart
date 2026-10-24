import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/app/app.dart';
import 'package:mambatv/app/bootstrap.dart';
import 'package:mambatv/app/providers/infrastructure_providers.dart';
import 'package:mambatv/app/providers/repository_providers.dart';
import 'package:mambatv/app/providers/playback_providers.dart';
import 'package:mambatv/data/repositories/fake_catalog_repository.dart';
import 'package:mambatv/data/repositories/memory_session_repository.dart';
import 'package:mambatv/domain/repositories/repositories.dart';
import 'package:mambatv/ui/features/settings/view_models/settings_view_model.dart';

import 'memory_preferences.dart';
import 'fake_playback.dart';
import 'fake_auth.dart';
import 'memory_search_history.dart';

Future<ProviderContainer> pumpMamba(
  WidgetTester tester, {
  CatalogRepository? catalog,
  Size size = const Size(960, 540),
  bool settle = true,
  FakeEngineFactory? engines,
  FakePlaybackRepository? playback,
  MemoryProgressRepository? progress,
  MemorySessionRepository? sessions,
  FakeAuthRepository? auth,
  SearchHistoryRepository? history,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final session = sessions ?? MemorySessionRepository();
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      searchHistoryRepositoryProvider.overrideWithValue(
        history ?? MemorySearchHistoryRepository(),
      ),
      preferencesStoreProvider.overrideWithValue(MemoryPreferencesStore()),
      authRepositoryProvider.overrideWithValue(
        auth ?? FakeAuthRepository(session),
      ),
      playbackAdapterProvider.overrideWithValue(
        (engines ?? FakeEngineFactory()).adapter,
      ),
      playbackRepositoryProvider.overrideWithValue(
        playback ?? FakePlaybackRepository(),
      ),
      progressRepositoryProvider.overrideWithValue(
        progress ?? MemoryProgressRepository(),
      ),
      sessionRepositoryProvider.overrideWithValue(session),
      catalogRepositoryProvider.overrideWithValue(
        catalog ?? FakeCatalogRepository(latency: Duration.zero),
      ),
      // Pure widget tests isolate platform plugins; native startup is tested separately.
      appStartupProvider.overrideWith((ref) async {
        await ref.watch(sessionProvider.future);
        await ref.watch(settingsViewModelProvider.future);
      }),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await session.close();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const MambaApp()),
  );
  if (settle) await tester.pumpAndSettle();
  return container;
}
