import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../ui/features/catalog/views/catalog_page.dart';
import '../ui/features/preview/preview_pages.dart';
import '../ui/features/search/search_page.dart';
import '../ui/features/settings/views/settings_page.dart';
import '../ui/features/settings/views/licenses_page.dart';
import '../ui/features/settings/views/diagnostics_page.dart';
import '../ui/features/shell/tv_shell.dart';
import '../ui/features/video_detail/video_detail_page.dart';
import '../ui/features/player/views/player_page.dart';
import '../ui/features/auth/views/account_page.dart';
import '../ui/features/auth/views/qr_login_page.dart';
import '../ui/features/library/views/library_page.dart';
import '../domain/library/library.dart';
import '../domain/playback/playback_target.dart';
import '../ui/features/content/views/content_pages.dart';
import 'providers/auth_providers.dart';
import '../domain/discovery/home_feed.dart';
import '../ui/core/theme/tv_theme.dart';
import '../ui/features/creator/creator_page.dart';
import '../ui/features/player/views/overlay_settings_dialog.dart';

part 'router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/season/:id',
        builder: (context, state) =>
            SeasonPage(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/watch/pgc/:season/:episode',
        builder: (context, state) {
          final target = PlaybackTarget.pgc(
            seasonId: state.pathParameters['season']!,
            episodeId: state.pathParameters['episode']!,
          );
          return Theme(
            data: tvTheme(),
            child: PlayerPage(
              videoId: target.contentId,
              target: target,
              pageId: state.pageKey.value,
            ),
          );
        },
      ),
      GoRoute(
        path: '/watch/live/:room',
        builder: (context, state) {
          final target = PlaybackTarget.live(
            roomId: state.pathParameters['room']!,
          );
          return Theme(
            data: tvTheme(),
            child: PlayerPage(
              videoId: target.contentId,
              target: target,
              pageId: state.pageKey.value,
            ),
          );
        },
      ),
      GoRoute(
        path: '/settings/logs',
        builder: (context, state) => const DiagnosticsPage(),
      ),
      GoRoute(
        path: '/settings/overlays',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: OverlaySettingsDialog(
              videoId: '',
              partId: '',
              scopeKey: 'preferences',
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/creator/:mid',
        builder: (context, state) => CreatorPage(
          mid: int.tryParse(state.pathParameters['mid'] ?? '') ?? 0,
          name: state.extra is Map<String, String?>
              ? (state.extra! as Map<String, String?>)['name']
              : null,
          avatar: state.extra is Map<String, String?>
              ? (state.extra! as Map<String, String?>)['avatar']
              : null,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            TvShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => CatalogPage(
                  section: HomeFeed.fromSection(
                    state.uri.queryParameters['feed'],
                  ).section,
                  pageId: 'home',
                  branchIndex: 0,
                  title: '发现',
                  subtitle: '此刻热门，总有一个故事值得停留',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                builder: (context, state) => const AccountPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) =>
                    const LibraryPage(historyOnly: true, branchIndex: 4),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/pgc',
                builder: (context, state) => const ContentBrowsePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/settings/licenses',
        builder: (context, state) => const LicensesPage(),
      ),
      GoRoute(
        path: '/library/records',
        builder: (context, state) => const LibraryPage(),
      ),
      GoRoute(
        path: '/library/folder/:id',
        builder: (context, state) => LibraryPage(
          initialSection: LibrarySection.folder,
          initialFolderId: state.pathParameters['id'],
          initialFolderTitle: state.extra is String
              ? state.extra! as String
              : '收藏夹',
        ),
      ),
      GoRoute(
        path: '/video/:id',
        builder: (context, state) => VideoDetailPage(
          id: state.pathParameters['id']!,
          pageId: state.pageKey.value,
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => QrLoginPage(
          pageId: state.pageKey.value,
          returnTo: safeLoginReturn(state.uri.queryParameters['returnTo']),
        ),
      ),
      GoRoute(
        path: '/player/:id',
        builder: (context, state) => Theme(
          data: tvTheme(),
          child: PlayerPage(
            videoId: state.pathParameters['id']!,
            partId: state.uri.queryParameters['part'],
            remoteResume: state.uri.queryParameters.containsKey('remote_ms')
                ? Duration(
                    milliseconds:
                        (int.tryParse(
                                  state.uri.queryParameters['remote_ms'] ?? '',
                                ) ??
                                0)
                            .clamp(0, 86400000),
                  )
                : null,
            pageId: state.pageKey.value,
          ),
        ),
      ),
    ],
    errorBuilder: (context, state) => const PreviewPage(
      title: '页面没有找到',
      message: '返回主页继续浏览。',
      icon: Icons.explore_off_outlined,
    ),
  );
  ref.onDispose(router.dispose);
  return router;
}
