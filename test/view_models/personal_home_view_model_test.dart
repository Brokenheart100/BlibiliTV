import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/app/providers/repository_providers.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/memory_session_repository.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/domain/library/personal_home.dart';
import 'package:mambatv/ui/features/auth/view_models/personal_home_view_model.dart';

import '../support/fake_personal_home.dart';

void main() {
  test(
    'account switch cancels old collection and cannot publish its late content',
    () async {
      const first = Session(
        ownerKey: 'user:1',
        generation: 1,
        status: SessionStatus.authenticated,
      );
      final sessions = MemorySessionRepository(first);
      final repo = FakePersonalHomeRepository()
        ..gate = Completer<Result<PageSlice<PersonalItem>>>();
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(sessions),
          personalHomeRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await sessions.close();
      });
      container.listen(sessionProvider, (_, _) {});
      await container.read(sessionProvider.future);
      final old = personalCollectionProvider(
        scopeKey: first.scopeKey,
        section: PersonalSection.bangumi,
      );
      container.listen(old, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      expect(repo.calls.single.$1, 'user:1');
      sessions.replace(
        const Session(
          ownerKey: 'user:2',
          generation: 2,
          status: SessionStatus.authenticated,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      repo.gate!.complete(
        Success(
          PageSlice(
            items: [const PersonalSeason(id: 1, title: '旧账号', subtitle: '')],
          ),
        ),
      );
      await container.read(old.future);
      expect(repo.signals.first.isCancelled, isTrue);
      expect(container.read(old).value?.items, isEmpty);
    },
  );
}
