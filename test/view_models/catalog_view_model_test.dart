import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/app/providers/repository_providers.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/fake_catalog_repository.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/ui/features/catalog/view_models/catalog_view_model.dart';

class PendingPage {
  PendingPage(this.owner, this.signal, this.cursor, this.forceRefresh);
  final String owner;
  final String? cursor;
  final bool forceRefresh;
  final CancellationSignal signal;
  final completer = Completer<Result<PageSlice<VideoSummary>>>();
}

class ControlledCatalog extends FakeCatalogRepository {
  ControlledCatalog() : super(latency: Duration.zero);
  final requests = <PendingPage>[];
  @override
  Future<Result<PageSlice<VideoSummary>>> fetchVideos({
    required String section,
    required String ownerKey,
    String query = '',
    CatalogOptions options = const CatalogOptions(),
    String? cursor,
    int limit = 12,
    bool forceRefresh = false,
    required CancellationSignal cancellation,
  }) {
    final request = PendingPage(ownerKey, cancellation, cursor, forceRefresh);
    requests.add(request);
    return request.completer.future;
  }
}

void main() {
  test('page instance and owner are part of the provider identity', () async {
    final repository = ControlledCatalog();
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [catalogRepositoryProvider.overrideWithValue(repository)],
    );
    final a = catalogViewModelProvider(
      section: 'home',
      pageId: 'page-1',
      ownerKey: 'A',
    );
    final same = catalogViewModelProvider(
      section: 'home',
      pageId: 'page-1',
      ownerKey: 'A',
    );
    final b = catalogViewModelProvider(
      section: 'home',
      pageId: 'page-1',
      ownerKey: 'B',
    );
    final another = catalogViewModelProvider(
      section: 'home',
      pageId: 'page-2',
      ownerKey: 'A',
    );
    final subscriptions = [
      for (final provider in [a, same, b, another])
        container.listen(provider, (_, _) {}),
    ];
    expect(repository.requests, hasLength(3));
    expect(repository.requests.map((r) => r.owner), ['A', 'B', 'A']);
    for (final request in repository.requests) {
      request.completer.complete(Success(PageSlice(items: const [])));
    }
    await Future.wait([
      container.read(a.future),
      container.read(b.future),
      container.read(another.future),
    ]);
    for (final subscription in subscriptions) {
      subscription.close();
    }
  });

  test(
    'refresh cancels stale pagination and late results cannot replace it',
    () async {
      final repository = ControlledCatalog();
      final container = ProviderContainer.test(
        retry: (_, _) => null,
        overrides: [catalogRepositoryProvider.overrideWithValue(repository)],
      );
      final provider = catalogViewModelProvider(
        section: 'home',
        pageId: 'p',
        ownerKey: 'guest',
      );
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      repository.requests[0].completer.complete(
        Success(
          PageSlice(items: [FakeCatalogRepository.videos[0]], nextCursor: '12'),
        ),
      );
      await container.read(provider.future);
      final vm = container.read(provider.notifier);
      final more = vm.loadMore();
      final refresh = vm.refresh();
      expect(repository.requests.map((r) => r.forceRefresh), [
        false,
        false,
        true,
      ]);
      expect(repository.requests[1].signal.isCancelled, isTrue);
      repository.requests[2].completer.complete(
        Success(PageSlice(items: [FakeCatalogRepository.videos[8]])),
      );
      await refresh;
      repository.requests[1].completer.complete(
        Success(PageSlice(items: [FakeCatalogRepository.videos[1]])),
      );
      await more;
      expect(container.read(provider).requireValue.items.single.id, 'demo-008');
    },
  );

  test(
    'disposing an unused page cancels its pending repository request',
    () async {
      final repository = ControlledCatalog();
      final container = ProviderContainer.test(
        retry: (_, _) => null,
        overrides: [catalogRepositoryProvider.overrideWithValue(repository)],
      );
      final provider = catalogViewModelProvider(
        section: 'home',
        pageId: 'p',
        ownerKey: 'guest',
      );
      final subscription = container.listen(provider, (_, _) {});
      subscription.close();
      await container.pump();
      expect(repository.requests.single.signal.isCancelled, isTrue);
      repository.requests.single.completer.complete(
        Success(PageSlice(items: const [])),
      );
      await container.pump();
    },
  );

  test('dependency invalidation cancels the old repository request', () async {
    final first = ControlledCatalog();
    final second = ControlledCatalog();
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [catalogRepositoryProvider.overrideWithValue(first)],
    );
    final provider = catalogViewModelProvider(
      section: 'home',
      pageId: 'p',
      ownerKey: 'guest',
    );
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    container.updateOverrides([
      catalogRepositoryProvider.overrideWithValue(second),
    ]);
    await container.pump();
    expect(first.requests.single.signal.isCancelled, isTrue);
    second.requests.single.completer.complete(
      Success(PageSlice(items: [FakeCatalogRepository.videos[4]])),
    );
    await container.read(provider.future);
    first.requests.single.completer.complete(
      Success(PageSlice(items: [FakeCatalogRepository.videos[0]])),
    );
    await container.pump();
    expect(container.read(provider).requireValue.items.single.id, 'demo-004');
  });
}
