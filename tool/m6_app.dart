import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:mambatv/app/app.dart';
import 'package:mambatv/app/bootstrap.dart';
import 'package:mambatv/app/providers/repository_providers.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/domain/library/library.dart';
import 'package:mambatv/ui/core/images/tv_image_cache.dart';

void main() {
  late final ProviderContainer container;
  enableFlutterDriverExtension(
    handler: (command) async {
      if (command != 'm6-readonly' ||
          !const bool.fromEnvironment('MAMBA_READ_ONLY_VALIDATION')) {
        return jsonEncode({
          'error': 'Read-only validation entrypoint required',
        });
      }
      await container.read(appStartupProvider.future);
      final session = container.read(sessionRepositoryProvider).current;
      if (!session.isAuthenticated) return jsonEncode({'authenticated': false});
      final repository = container.read(libraryRepositoryProvider);
      final api = container.read(bilibiliApiProvider);
      final writesBefore = api.remoteWriteRequestsSent;
      final signal = CancellationSignal();
      final results = <String, Object?>{};
      for (final section in [
        LibrarySection.remote,
        LibrarySection.folders,
        LibrarySection.watchLater,
      ]) {
        final page = await repository.list(
          ownerKey: session.ownerKey,
          section: section,
          cancellation: signal,
        );
        if (page is Success<PageSlice<LibraryEntry>>) {
          results[section.name] = {
            'status': 'passed',
            'paginationAvailable': page.value.nextCursor != null,
          };
          if (section == LibrarySection.folders &&
              page.value.items.isNotEmpty) {
            final contents = await repository.list(
              ownerKey: session.ownerKey,
              section: LibrarySection.folder,
              folderId: page.value.items.first.folderId,
              cancellation: signal,
            );
            results['folderContents'] = {
              'status': contents is Success ? 'passed' : 'failed',
              if (contents is ResultFailure<PageSlice<LibraryEntry>>)
                'category': contents.failure.kind.name,
            };
          }
          if (page.value.nextCursor != null) {
            final next = await repository.list(
              ownerKey: session.ownerKey,
              section: section,
              cursor: page.value.nextCursor,
              cancellation: signal,
            );
            results['${section.name}NextPage'] = {
              'status': next is Success ? 'passed' : 'failed',
              if (next is ResultFailure<PageSlice<LibraryEntry>>)
                'category': next.failure.kind.name,
            };
          }
        } else {
          results[section.name] = {
            'status': 'failed',
            'category': (page as ResultFailure).failure.kind.name,
          };
        }
      }
      final membership = await repository.membership(
        ownerKey: session.ownerKey,
        videoId: 'BV1hQHW63EMc',
        aid: 0,
        cancellation: signal,
      );
      results['membershipReads'] = {
        'status': membership is Success ? 'passed' : 'failed',
        if (membership is ResultFailure<LibraryMembership>)
          'category': membership.failure.kind.name,
      };
      return jsonEncode({
        'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
        'authenticated': true,
        'readOnly': true,
        'remoteWriteCommandsExecuted':
            api.remoteWriteRequestsSent - writesBefore,
        'privateIdentityAndContentsOmitted': true,
        'checks': results,
      });
    },
  );
  container = ProviderContainer(retry: (_, _) => null);
  TvImageCache.configure();
  MediaKit.ensureInitialized();
  runApp(
    UncontrolledProviderScope(container: container, child: const MambaApp()),
  );
}
