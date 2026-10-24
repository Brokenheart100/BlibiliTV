import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:mambatv/app/app.dart';
import 'package:mambatv/app/providers/infrastructure_providers.dart';
import 'package:mambatv/app/providers/repository_providers.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/persistent_session_repository.dart';

void main() {
  late final ProviderContainer container;
  // Development-only, read-only diagnostics. Never return identifiers, cookies,
  // QR challenges, names, signed media URLs, or raw service responses.
  enableFlutterDriverExtension(
    handler: (message) async {
      try {
        final session = await container.read(sessionProvider.future);
        final hasSaved =
            await container
                .read(credentialStoreProvider)
                .read(PersistentSessionRepository.credentialKey) !=
            null;
        if (message == 'status') {
          return jsonEncode({
            'status': session.status.name,
            'persisted': hasSaved,
            'notice': session.notice != null,
          });
        }
        if (message == 'account-contract' && session.isAuthenticated) {
          final signal = CancellationSignal();
          final api = container.read(bilibiliApiProvider);
          final nav = await api.get('/x/web-interface/nav', signal);
          final page =
              (await container
                      .read(catalogRepositoryProvider)
                      .fetchVideos(
                        section: 'home',
                        ownerKey: session.ownerKey,
                        cancellation: signal,
                      ))
                  .valueOrThrow;
          final detail =
              (await container
                      .read(catalogRepositoryProvider)
                      .getVideo(
                        page.items.first.id,
                        ownerKey: session.ownerKey,
                        cancellation: signal,
                      ))
                  .valueOrThrow;
          final source =
              (await container
                      .read(playbackRepositoryProvider)
                      .resolve(
                        videoId: detail.video.id,
                        partId: detail.parts.first.id,
                        cancellation: signal,
                      ))
                  .valueOrThrow;
          return jsonEncode({
            'navAuthenticated': nav['isLogin'] == true,
            'ownerMatchesNav': session.ownerKey == 'user:${nav['mid']}',
            'credentialBoundToApi': api.identity.cookie != null,
            'catalogCount': page.items.length,
            'detailAndPart': detail.parts.isNotEmpty,
            'separateAvcAndAac':
                source.codec.startsWith('avc1') && source.audioUrl.isNotEmpty,
            'videoId': detail.video.id,
            'quality': source.quality,
          });
        }
        return jsonEncode({'unsupported': true});
      } catch (_) {
        return jsonEncode({'failed': true, 'detailsRedacted': true});
      }
    },
  );
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  container = ProviderContainer(retry: (_, _) => null);
  runApp(
    UncontrolledProviderScope(container: container, child: const MambaApp()),
  );
}
