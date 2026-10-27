/// Developer entrypoint. Compile with MAMBA_READ_ONLY_VALIDATION=true.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:mambatv/app/app.dart';
import 'package:mambatv/app/logging/app_container.dart';
import 'package:mambatv/app/bootstrap.dart';
import 'package:mambatv/app/providers/repository_providers.dart';
import 'package:mambatv/app/router.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/domain/overlays/overlays.dart';
import 'package:mambatv/domain/library/personal_home.dart';
import 'package:mambatv/domain/library/library.dart';
import 'package:mambatv/ui/core/images/tv_image_cache.dart';
import 'package:mambatv/data/repositories/bilibili_overlay_repository.dart';

void main() {
  late ProviderContainer container;
  enableFlutterDriverExtension(
    handler: (command) async {
      if (!const bool.fromEnvironment('MAMBA_READ_ONLY_VALIDATION')) {
        return jsonEncode({'error': 'Read-only validation flag required'});
      }
      await container.read(appStartupProvider.future);
      final api = container.read(bilibiliApiProvider),
          before = container.read(bilibiliApiProvider).remoteWriteRequestsSent;
      final session = container.read(sessionRepositoryProvider).current;
      if (command == 'personal-readonly') {
        final report = <String, Object?>{
          'authenticated': session.isAuthenticated,
          'readOnly': true,
        };
        if (session.isAuthenticated) {
          final repository = container.read(personalHomeRepositoryProvider);
          final profile = await repository.profile(
            session.ownerKey,
            CancellationSignal(),
          );
          report['profileStatus'] = profile is Success ? 'passed' : 'failed';
          if (profile is Success<PersonalProfile>) {
            report['hasAvatar'] = profile.value.avatarUrl != null;
          }
          final collections = <String, Object?>{};
          for (final section in PersonalSection.values) {
            final result = await repository.list(
              ownerKey: session.ownerKey,
              section: section,
              cancellation: CancellationSignal(),
            );
            collections[section.name] = switch (result) {
              Success(:final value) => {
                'status': 'passed',
                'count': value.items.length,
                'hasMore': value.nextCursor != null,
              },
              ResultFailure(:final failure) => {
                'status': 'failed',
                'failure': failure.kind.name,
              },
            };
            if (result is Success<PageSlice<PersonalItem>>) {
              final entry = collections[section.name]! as Map<String, Object?>;
              if (result.value.nextCursor != null) {
                final next = await repository.list(
                  ownerKey: session.ownerKey,
                  section: section,
                  cursor: result.value.nextCursor,
                  cancellation: CancellationSignal(),
                );
                entry['nextStatus'] = next is Success ? 'passed' : 'failed';
                if (next is Success<PageSlice<PersonalItem>>) {
                  entry['nextCount'] = next.value.items.length;
                  entry['pageOverlap'] = next.value.items
                      .where(
                        (item) => result.value.items.any(
                          (old) => old.key == item.key,
                        ),
                      )
                      .length;
                }
              }
              if (section == PersonalSection.folders &&
                  result.value.items.isNotEmpty) {
                final folders = result.value.items
                    .whereType<PersonalFolder>()
                    .toList();
                final first = folders.firstWhere(
                  (folder) => folder.count > 0,
                  orElse: () => folders.first,
                );
                final folder = await repository.list(
                  ownerKey: session.ownerKey,
                  section: section,
                  folderId: first.id,
                  cancellation: CancellationSignal(),
                );
                entry['folderContentsStatus'] = folder is Success
                    ? 'passed'
                    : 'failed';
                if (folder is Success<PageSlice<PersonalItem>>) {
                  entry['folderContentsCount'] = folder.value.items.length;
                }
              }
            }
          }
          report['collections'] = collections;
          final history = await container
              .read(libraryRepositoryProvider)
              .list(
                ownerKey: session.ownerKey,
                section: LibrarySection.remote,
                cancellation: CancellationSignal(),
              );
          report['history'] = switch (history) {
            Success(:final value) => {
              'status': 'passed',
              'count': value.items.length,
            },
            ResultFailure(:final failure) => {
              'status': 'failed',
              'failure': failure.kind.name,
            },
          };
        }
        report['remoteWrites'] = api.remoteWriteRequestsSent - before;
        report['recordedAtUtc'] = DateTime.now().toUtc().toIso8601String();
        return jsonEncode(report);
      }
      if (command == 'appearance-home') {
        container.read(appRouterProvider).go('/home');
        return '{}';
      }
      if (command == 'm8-player') {
        container.read(appRouterProvider).go('/player/BV1wR4Xz6EqG');
        return '{}';
      }
      if (command != 'm8-readonly') return '{}';
      final diagnostics = <String>[];
      final repository = BilibiliOverlayRepository(
        api,
        onDiagnostic: (stage, category) => diagnostics.add('$stage:$category'),
      );
      final catalog = container.read(catalogRepositoryProvider);
      final signal = CancellationSignal();
      final report = <String, Object?>{
        'readOnly': true,
        'authenticated': session.isAuthenticated,
        'samples': <Object?>[],
        'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
      };
      for (final id in ['BV1wR4Xz6EqG', 'BV1hQHW63EMc', 'BV19wnQ6sExk']) {
        final entry = <String, Object?>{'videoId': id};
        try {
          final detail = (await catalog.getVideo(
            id,
            ownerKey: session.ownerKey,
            cancellation: signal,
          )).valueOrThrow;
          final part = detail.parts.first.id;
          final tracks = (await repository.tracks(
            id,
            part,
            signal,
          )).valueOrThrow;
          entry['trackCount'] = tracks.length;
          if (tracks.isNotEmpty) {
            final cues = await repository.cues(tracks.first.id, signal);
            entry['cuesStatus'] = cues is Success ? 'passed' : 'failed';
            if (cues is Success<List<SubtitleCue>>) {
              entry['cueCount'] = cues.value.length;
            }
          }
          final manifest = (await repository.manifest(
            id,
            part,
            signal,
          )).valueOrThrow;
          final items = (await repository.segment(
            part,
            1,
            signal,
          )).valueOrThrow;
          entry['segmentMs'] = manifest.segmentMs;
          entry['segmentCount'] = manifest.total;
          entry['danmakuCount'] = items.length;
          final creator = await catalog.fetchVideos(
            section: 'creator',
            ownerKey: session.ownerKey,
            options: CatalogOptions(
              creatorId: detail.creatorId,
              order: VideoOrder.newest,
            ),
            cancellation: signal,
          );
          entry['creatorStatus'] = creator is Success ? 'passed' : 'failed';
          if (creator is Success<PageSlice<VideoSummary>>) {
            entry['creatorCount'] = creator.value.items.length;
          }
          if (creator is ResultFailure<PageSlice<VideoSummary>>) {
            entry['creatorFailure'] = creator.failure.kind.name;
          }
        } catch (e) {
          entry['failure'] = e is AppFailure
              ? e.kind.name
              : e.runtimeType.toString();
        }
        (report['samples']! as List).add(entry);
      }
      if (session.isAuthenticated) {
        final following = await catalog.fetchVideos(
          section: 'following',
          ownerKey: session.ownerKey,
          cancellation: signal,
        );
        report['followingStatus'] = following is Success ? 'passed' : 'failed';
        if (following is Success<PageSlice<VideoSummary>>) {
          report['followingCount'] = following.value.items.length;
          if (following.value.nextCursor != null) {
            final next = await catalog.fetchVideos(
              section: 'following',
              ownerKey: session.ownerKey,
              cursor: following.value.nextCursor,
              cancellation: signal,
            );
            report['followingNextPage'] = next is Success ? 'passed' : 'failed';
          }
        }
      }
      final search = await catalog.fetchVideos(
        section: 'search',
        ownerKey: session.ownerKey,
        query: 'Flutter',
        options: const CatalogOptions(order: VideoOrder.newest, duration: 1),
        cancellation: signal,
      );
      report['filteredSearchStatus'] = search is Success ? 'passed' : 'failed';
      report['remoteWrites'] = api.remoteWriteRequestsSent - before;
      report['diagnostics'] = diagnostics;
      repository.close();
      return jsonEncode(report);
    },
  );
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  TvImageCache.configure();
  container = createAppContainer();
  runApp(
    UncontrolledProviderScope(container: container, child: const MambaApp()),
  );
}
