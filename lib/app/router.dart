import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../ui/features/catalog/views/catalog_page.dart';
import '../ui/features/preview/preview_pages.dart';
import '../ui/features/search/search_page.dart';
import '../ui/features/settings/views/settings_page.dart';
import '../ui/features/shell/tv_shell.dart';
import '../ui/features/video_detail/video_detail_page.dart';
import '../ui/features/player/views/player_page.dart';
import '../ui/features/auth/views/account_page.dart';
import '../ui/features/auth/views/qr_login_page.dart';
import 'providers/auth_providers.dart';

part 'router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            TvShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => CatalogPage(
                  section: state.uri.queryParameters['feed'] == 'popular'
                      ? 'popular'
                      : 'home',
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
        ],
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
        builder: (context, state) => PlayerPage(
          videoId: state.pathParameters['id']!,
          partId: state.uri.queryParameters['part'],
          pageId: state.pageKey.value,
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
