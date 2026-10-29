import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/bilibili_catalog_repository.dart';
import '../../data/repositories/bilibili_playback_repository.dart';
import '../../data/repositories/local_progress_repository.dart';
import '../../data/repositories/local_search_history_repository.dart';
import '../../data/services/bilibili/bilibili_api.dart';
import '../../domain/playback/playback.dart';
import '../../data/repositories/local_settings_repository.dart';
import '../../data/repositories/persistent_session_repository.dart';
import '../../data/repositories/web_auth_repository.dart';
import '../../data/services/auth/web_auth_service.dart';
import '../../data/services/auth/request_identity.dart';
import '../../domain/auth/auth.dart';
import '../../domain/entities/app_models.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/library/library.dart';
import '../../data/repositories/drift_history_repository.dart';
import '../../data/repositories/bilibili_library_repository.dart';
import '../../data/repositories/bilibili_personal_home_repository.dart';
import '../../domain/library/personal_home.dart';
import '../../domain/playback/content_playback.dart';
import '../../data/repositories/bilibili_pgc_repository.dart';
import '../../data/repositories/bilibili_live_repository.dart';
import '../../data/repositories/bilibili_content_search_repository.dart';
import '../../domain/discovery/content_search.dart';
import 'infrastructure_providers.dart';

part 'repository_providers.g.dart';

@Riverpod(keepAlive: true)
ContentSearchRepository contentSearchRepository(Ref ref) =>
    BilibiliContentSearchRepository(ref.watch(bilibiliApiProvider));

@Riverpod(keepAlive: true)
PgcRepository pgcRepository(Ref ref) =>
    BilibiliPgcRepository(ref.watch(bilibiliApiProvider));
@Riverpod(keepAlive: true)
LiveRepository liveRepository(Ref ref) =>
    BilibiliLiveRepository(ref.watch(bilibiliApiProvider));
@Riverpod(keepAlive: true)
ContentProgressRepository contentProgressRepository(Ref ref) =>
    LocalProgressRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
PersonalHomeRepository personalHomeRepository(Ref ref) =>
    BilibiliPersonalHomeRepository(
      ref.watch(bilibiliApiProvider),
      ref.watch(catalogRepositoryProvider),
      ref.watch(libraryRepositoryProvider),
    );

@Riverpod(keepAlive: true)
LocalHistoryRepository localHistoryRepository(Ref ref) =>
    DriftHistoryRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
LibraryRepository libraryRepository(Ref ref) =>
    BilibiliLibraryRepository(ref.watch(bilibiliApiProvider));

@Riverpod(keepAlive: true)
SearchHistoryRepository searchHistoryRepository(Ref ref) =>
    LocalSearchHistoryRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
BilibiliApi bilibiliApi(Ref ref) {
  final snapshot = ref.watch(sessionProvider).value ?? const Session();
  final repository = ref.watch(sessionRepositoryProvider);
  final persistent = repository is PersistentSessionRepository
      ? repository
      : null;
  final api = BilibiliApi(
    ref.watch(apiClientProvider),
    identity: persistent?.capture() ?? RequestIdentity(snapshot),
    onAuthenticationFailure: persistent?.authenticationFailed,
  );
  ref.onDispose(api.close);
  return api;
}

@Riverpod(keepAlive: true)
AuthGateway authGateway(Ref ref) =>
    WebAuthService(ref.watch(apiClientProvider));

@Riverpod(keepAlive: true)
PersistentSessionRepository persistentSession(Ref ref) {
  final repository = PersistentSessionRepository(
    ref.watch(authGatewayProvider),
    ref.watch(credentialStoreProvider),
    ref.watch(preferencesStoreProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => WebAuthRepository(
  ref.watch(authGatewayProvider),
  ref.watch(persistentSessionProvider),
);

@Riverpod(keepAlive: true)
CatalogRepository catalogRepository(Ref ref) =>
    BilibiliCatalogRepository(ref.watch(bilibiliApiProvider));

@Riverpod(keepAlive: true)
PlaybackRepository playbackRepository(Ref ref) =>
    BilibiliPlaybackRepository(ref.watch(bilibiliApiProvider));

@Riverpod(keepAlive: true)
ProgressRepository progressRepository(Ref ref) =>
    LocalProgressRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
SessionRepository sessionRepository(Ref ref) {
  return ref.watch(persistentSessionProvider);
}

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) =>
    LocalSettingsRepository(ref.watch(preferencesStoreProvider));

@Riverpod(keepAlive: true)
Stream<Session> session(Ref ref) async* {
  final repository = ref.watch(sessionRepositoryProvider);
  await repository.restore();
  yield* repository.watch();
}
