import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/core/theme/tv_theme.dart';
import '../domain/entities/app_models.dart';
import '../ui/features/settings/view_models/settings_view_model.dart';
import '../ui/core/widgets/tv_button.dart';
import '../ui/core/widgets/glass_panel.dart';
import 'bootstrap.dart';
import 'lifecycle_bridge.dart';
import 'router.dart';
import 'providers/repository_providers.dart';
import 'providers/ui_providers.dart';

class TvBackIntent extends Intent {
  const TvBackIntent();
}

class MambaApp extends ConsumerWidget {
  const MambaApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(sessionProvider, (previous, next) {
      if (next.hasValue && previous?.value?.ownerKey != next.value?.ownerKey) {
        ref.read(focusMemoryProvider).clear();
      }
    });
    ref.listen(appForegroundProvider, (_, foreground) {
      if (foreground) {
        unawaited(ref.read(sessionRepositoryProvider).revalidate());
      }
    });
    final startup = ref.watch(appStartupProvider);
    final router = ref.watch(appRouterProvider);
    final theme =
        ref.watch(settingsViewModelProvider).value?.settings.theme ??
        AppTheme.dark;
    return MaterialApp.router(
      title: 'MambaTV',
      debugShowCheckedModeBanner: false,
      theme: tvTheme(brightness: Brightness.light),
      darkTheme: tvTheme(),
      themeMode: switch (theme) {
        AppTheme.dark => ThemeMode.dark,
        AppTheme.light => ThemeMode.light,
        AppTheme.system => ThemeMode.system,
      },
      routerConfig: router,
      builder: (context, child) => LifecycleBridge(
        child: Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
            // Android's Back also arrives through the platform popRoute
            // callback. Mapping its key event here would pop two routes.
            SingleActivator(LogicalKeyboardKey.escape): TvBackIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              TvBackIntent: CallbackAction<TvBackIntent>(
                onInvoke: (_) {
                  unawaited(router.routerDelegate.popRoute());
                  return null;
                },
              ),
            },
            child: TvBackdrop(
              child: FocusTraversalGroup(
                child: Stack(
                  children: [
                    child!,
                    if (startup.isLoading)
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    if (startup.hasError)
                      Positioned(
                        bottom: 12,
                        right: 24,
                        child: Material(
                          color: context.tvColors.surface,
                          child: TvButton(
                            label: '本地服务暂不可用 · 重试',
                            onPressed: () => ref.invalidate(appStartupProvider),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
