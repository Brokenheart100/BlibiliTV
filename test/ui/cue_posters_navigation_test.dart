import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/app/router.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/ui/core/theme/tv_theme.dart';
import 'package:mambatv/ui/core/widgets/creator_avatar.dart';
import 'package:mambatv/ui/core/widgets/tv_pill_tabs.dart';
import 'package:mambatv/ui/core/widgets/tv_video_card.dart';
import 'package:mambatv/ui/features/settings/view_models/settings_view_model.dart';

import '../support/app_harness.dart';
import '../support/fake_content.dart';
import 'tv_shell_test.dart' show press;

class PosterCatalog extends FakePgcRepository {
  @override
  Future<Result<PageSlice<VideoSummary>>> browse(
    CancellationSignal signal, {
    int page = 1,
    String keyword = '',
  }) async => Success(
    PageSlice(
      items: List.generate(
        15,
        (i) => VideoSummary(
          id: '${10 + i}',
          title: '第 $i 部番剧',
          creator: '全 12 话',
          durationSeconds: 0,
          viewCount: 0,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'PGC is a persistent rail branch and D-pad returns to the saved poster',
    (tester) async {
      final container = await pumpMamba(tester, pgc: PosterCatalog());
      expect(find.byKey(const Key('catalog-pgc')), findsNothing);
      await tester.tap(find.byKey(const Key('nav-5')));
      await tester.pumpAndSettle();
      expect(container.read(appRouterProvider).state.uri.path, '/pgc');
      expect(find.byKey(const Key('icon-navigation-rail')), findsOneWidget);
      await press(tester, LogicalKeyboardKey.arrowRight);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'video-10');
      await press(tester, LogicalKeyboardKey.arrowDown);
      final selected = FocusManager.instance.primaryFocus?.debugLabel;
      expect(selected, 'video-15');
      await press(tester, LogicalKeyboardKey.select);
      expect(container.read(appRouterProvider).state.uri.path, '/season/15');
      await press(tester, LogicalKeyboardKey.goBack);
      expect(FocusManager.instance.primaryFocus?.debugLabel, selected);
      await press(tester, LogicalKeyboardKey.arrowLeft);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'nav-5');
      await tester.tap(find.byKey(const Key('nav-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-5')));
      await tester.pumpAndSettle();
      await press(tester, LogicalKeyboardKey.arrowRight);
      expect(FocusManager.instance.primaryFocus?.debugLabel, selected);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(640, 360),
    const Size(960, 540),
    const Size(1280, 720),
  ]) {
    testWidgets(
      'portrait posters fit $size in both themes and reduced motion keeps focus',
      (tester) async {
        final container = await pumpMamba(
          tester,
          pgc: PosterCatalog(),
          size: size,
        );
        await tester.tap(find.byKey(const Key('nav-5')));
        await tester.pumpAndSettle();
        final card = find.byKey(const Key('video-10'));
        final artwork = find.descendant(
          of: card,
          matching: find.byType(TvArtwork),
        );
        expect(
          tester.getSize(artwork).height,
          greaterThan(tester.getSize(artwork).width),
        );
        expect(tester.widget<TvArtwork>(artwork).poster, isTrue);
        final viewport = tester.getRect(
          find.byKey(const Key('catalog-scroll')),
        );
        expect(
          tester.getRect(card).bottom,
          lessThanOrEqualTo(viewport.bottom + 1),
        );
        expect(
          find.descendant(of: card, matching: find.byType(CreatorAvatar)),
          findsNothing,
        );
        expect(find.textContaining('万次观看'), findsNothing);
        await tester.tap(find.byKey(const Key('nav-theme')));
        await tester.pumpAndSettle();
        expect(Theme.of(tester.element(card)).brightness, Brightness.light);
        final settings = container
            .read(settingsViewModelProvider)
            .requireValue
            .settings;
        await container
            .read(settingsViewModelProvider.notifier)
            .savePreferences(settings.copyWith(reducedMotion: true));
        await tester.pumpAndSettle();
        expect(MediaQuery.disableAnimationsOf(tester.element(card)), isTrue);
        await tester.tap(find.byKey(const Key('nav-5')));
        await tester.pumpAndSettle();
        await press(tester, LogicalKeyboardKey.arrowRight);
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'video-10');
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'poster page opens a season by link and returns to the compact header',
    (tester) async {
      await pumpMamba(tester);
      await tester.tap(find.byKey(const Key('nav-5')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('content-input')), findsNothing);
      await tester.tap(find.byKey(const Key('content-link-toggle')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('content-input')),
        'https://www.bilibili.com/bangumi/play/ss10',
      );
      await tester.tap(find.byKey(const Key('content-open')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('season-episodes')), findsOneWidget);
      await press(tester, LogicalKeyboardKey.goBack);
      expect(find.byKey(const Key('content-input')), findsNothing);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'content-link');
    },
  );

  testWidgets(
    'Cue pill retargets rapid selection and reduced motion snaps without delaying input',
    (tester) async {
      final nodes = List.generate(3, (_) => FocusNode());
      addTearDown(() {
        for (final node in nodes) {
          node.dispose();
        }
      });
      var selected = 0, reduced = false;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          theme: tvTheme(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 600,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    update = setState;
                    return TvCapsuleTabs<int>(
                      values: const [0, 1, 2],
                      selected: selected,
                      nodes: nodes,
                      label: (i) => '标签 $i',
                      tabKey: (i) => ValueKey('cue-tab-$i'),
                      onSelected: (i) => setState(() => selected = i),
                      onKey: (_, _) => KeyEventResult.ignored,
                      reducedMotion: reduced,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      final pill = find.byKey(const Key('capsule-selection'));
      final start = tester.getCenter(pill).dx;
      await tester.tap(find.byKey(const Key('cue-tab-2')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      final end = tester.getCenter(find.byKey(const Key('cue-tab-2'))).dx;
      expect(selected, 2);
      expect(tester.getCenter(pill).dx, inExclusiveRange(start, end));
      await tester.tap(find.byKey(const Key('cue-tab-1')));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.tap(find.byKey(const Key('cue-tab-0')));
      await tester.pumpAndSettle();
      expect(selected, 0);
      expect(tester.getCenter(pill).dx, closeTo(start, 1));
      await tester.tap(find.byKey(const Key('cue-tab-2')));
      await tester.pump(const Duration(milliseconds: 16));
      update(() => reduced = true);
      await tester.pump();
      expect(tester.getCenter(pill).dx, closeTo(end, 1));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );
}
