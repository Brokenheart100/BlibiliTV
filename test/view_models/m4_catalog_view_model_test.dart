import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/app/providers/repository_providers.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/fake_catalog_repository.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/domain/playback/playback.dart';
import 'package:mambatv/domain/repositories/repositories.dart';
import 'package:mambatv/ui/features/catalog/view_models/catalog_view_model.dart';
import 'package:mambatv/ui/features/video_detail/view_models/video_detail_view_model.dart';

import '../support/fake_playback.dart';

class PagedCatalog extends FakeCatalogRepository {
  PagedCatalog() : super(latency: Duration.zero);
  int active = 0, maximum = 0, requests = 0;
  bool fail = false, repeatCursor = false;
  @override
  Future<Result<PageSlice<VideoSummary>>> fetchVideos({
    required String section,
    required String ownerKey,
    String query = '',
    String? cursor,
    int limit = 12,
    bool forceRefresh = false,
    required CancellationSignal cancellation,
  }) async {
    requests++;
    active++;
    if (active > maximum) maximum = active;
    await Future<void>.delayed(Duration.zero);
    active--;
    if (fail) {
      return const ResultFailure(AppFailure(FailureKind.network, '合成断网'));
    }
    final page = int.parse(cursor ?? '1');
    final items = List.generate(
      12,
      (i) => FakeCatalogRepository.videos.first.copyWith(
        id: 'video-${(page - 1) * 11 + i}',
      ),
    );
    return Success(
      PageSlice(
        items: [...items, items.first],
        nextCursor: repeatCursor
            ? (cursor ?? '2')
            : page < 10
            ? '${page + 1}'
            : null,
      ),
    );
  }
}

class DetailSettings implements SettingsRepository {
  DetailSettings([this.resume = true]);
  final bool resume;
  @override
  Future<Result<AppSettings>> load() async =>
      Success(AppSettings(resumePlayback: resume));
  @override
  Future<Result<void>> save(AppSettings settings) async => const Success(null);
}

void main() {
  test(
    'ten pages remain unique and repeated load commands never overlap',
    () async {
      final repo = PagedCatalog();
      final container = ProviderContainer.test(
        retry: (_, _) => null,
        overrides: [catalogRepositoryProvider.overrideWithValue(repo)],
      );
      final provider = catalogViewModelProvider(
        section: 'popular',
        pageId: 'p',
        ownerKey: 'guest',
      );
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      await container.read(provider.future);
      final vm = container.read(provider.notifier);
      for (var page = 2; page <= 10; page++) {
        await Future.wait([vm.loadMore(), vm.loadMore(), vm.loadMore()]);
      }
      final state = container.read(provider).requireValue;
      expect(state.items, hasLength(111));
      expect(state.items.map((v) => v.id).toSet(), hasLength(111));
      expect(state.nextCursor, isNull);
      expect(repo.requests, 10);
      expect(repo.maximum, 1);
    },
  );
  test(
    'append failure retains items, cursor and an explicit retry action',
    () async {
      final repo = PagedCatalog();
      final container = ProviderContainer.test(
        retry: (_, _) => null,
        overrides: [catalogRepositoryProvider.overrideWithValue(repo)],
      );
      final provider = catalogViewModelProvider(
        section: 'popular',
        pageId: 'p',
        ownerKey: 'guest',
      );
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      await container.read(provider.future);
      repo.fail = true;
      await container.read(provider.notifier).loadMore();
      final failed = container.read(provider).requireValue;
      expect(failed.items, hasLength(12));
      expect(failed.nextCursor, '2');
      expect(failed.loadMoreFailed, isTrue);
      repo.fail = false;
      await container.read(provider.notifier).loadMore();
      expect(container.read(provider).requireValue.items, hasLength(23));
      expect(container.read(provider).requireValue.failure, isNull);
    },
  );
  test('a repeated cursor stops unbounded pagination without losing existing content', () async {
    final repo = PagedCatalog()..repeatCursor = true;
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [catalogRepositoryProvider.overrideWithValue(repo)],
    );
    final provider = catalogViewModelProvider(
      section: 'home',
      pageId: 'p',
      ownerKey: 'guest',
    );
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(provider.future);
    await container.read(provider.notifier).loadMore();
    expect(container.read(provider).requireValue.nextCursor, isNull);
    expect(container.read(provider).requireValue.notice, isNotNull);
    await container.read(provider.notifier).loadMore();
    expect(repo.requests, 2);
  });
  test('detail resumes the latest eligible part for its owner and respects the preference', () async {
    final progress = MemoryProgressRepository();
    await progress.save(
      const WatchProgress(
        ownerKey: 'guest',
        videoId: 'demo-000',
        partId: 'demo-000-p2',
        position: Duration(seconds: 25),
        duration: Duration(minutes: 2),
      ),
    );
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        catalogRepositoryProvider.overrideWithValue(
          FakeCatalogRepository(latency: Duration.zero),
        ),
        progressRepositoryProvider.overrideWithValue(progress),
        settingsRepositoryProvider.overrideWithValue(DetailSettings()),
      ],
    );
    final provider = videoDetailViewModelProvider(
      id: 'demo-000',
      pageId: 'p',
      ownerKey: 'guest',
    );
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    expect(
      (await container.read(provider.future)).resume?.partId,
      'demo-000-p2',
    );
    final other = videoDetailViewModelProvider(
      id: 'demo-000',
      pageId: 'p',
      ownerKey: 'A',
    );
    final otherSub = container.listen(other, (_, _) {});
    addTearDown(otherSub.close);
    expect((await container.read(other.future)).resume, isNull);
    final disabled = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        catalogRepositoryProvider.overrideWithValue(
          FakeCatalogRepository(latency: Duration.zero),
        ),
        progressRepositoryProvider.overrideWithValue(progress),
        settingsRepositoryProvider.overrideWithValue(DetailSettings(false)),
      ],
    );
    final disabledSub = disabled.listen(provider, (_, _) {});
    addTearDown(disabledSub.close);
    expect((await disabled.read(provider.future)).resume, isNull);
  });
}
