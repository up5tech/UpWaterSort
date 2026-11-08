import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:up_water_sort/app.dart';
import 'package:up_water_sort/controllers/game_controller.dart';
import 'package:up_water_sort/controllers/progress_controller.dart';
import 'package:up_water_sort/controllers/settings_controller.dart';
import 'package:up_water_sort/ui/screens/game_screen.dart';
import 'package:up_water_sort/ui/widgets/tube_painter.dart';

import 'harness.dart';

Widget _app(TestHarness harness) => MultiProvider(
  providers: [
    ChangeNotifierProvider<ProgressController>.value(value: harness.progress),
    ChangeNotifierProvider<SettingsController>.value(value: harness.settings),
    ChangeNotifierProvider<GameController>.value(value: harness.game),
  ],
  child: const UpWaterSortApp(),
);

Widget _gameApp(TestHarness harness, GameController game) => MultiProvider(
  providers: [
    ChangeNotifierProvider<ProgressController>.value(value: harness.progress),
    ChangeNotifierProvider<SettingsController>.value(value: harness.settings),
    ChangeNotifierProvider<GameController>.value(value: game),
  ],
  child: const MaterialApp(home: GameScreen()),
);

Iterable<TubePainter> _tubePainters(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((paint) => paint.painter)
    .whereType<TubePainter>();

void main() {
  testWidgets('theme and language apply immediately', (tester) async {
    final harness = await TestHarness.create();
    addTearDown(harness.dispose);

    await tester.pumpWidget(_app(harness));
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Sound effects'), findsOneWidget);

    await tester.tap(find.text('Dark theme'));
    await tester.pumpAndSettle();

    expect(harness.settings.darkMode, isTrue);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    expect(
      Theme.of(tester.element(find.text('Settings'))).brightness,
      Brightness.dark,
    );

    await tester.tap(find.text('Tiếng Việt'));
    await tester.pumpAndSettle();

    expect(harness.settings.locale, 'vi');
    expect(find.text('Cài đặt'), findsOneWidget);
    expect(find.text('Giao diện tối'), findsOneWidget);
    expect(find.text('Chế độ mù màu'), findsOneWidget);
  });

  testWidgets('reset asks first, then clears progress and options', (
    tester,
  ) async {
    final harness = await TestHarness.create();
    addTearDown(harness.dispose);
    await harness.progress.completeLevel(harness.levels.byId(1)!, 3);
    await harness.settings.setDarkMode(true);

    await tester.pumpWidget(_app(harness));
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reset data'));
    await tester.pumpAndSettle();
    expect(find.text('Reset all progress?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(harness.progress.totalStars, greaterThan(0));
    expect(harness.settings.darkMode, isTrue);

    await tester.tap(find.text('Reset data'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await tester.pumpAndSettle();

    expect(harness.progress.totalStars, 0);
    expect(harness.progress.unlockedLevel, 1);
    expect(harness.settings.darkMode, isFalse);
    expect(find.text('Dark theme'), findsOneWidget);

    // Let the confirmation snackbar finish so no timer is left pending.
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('color-blind mode reaches every tube painter', (tester) async {
    final harness = await TestHarness.create();
    addTearDown(harness.dispose);
    harness.game.startLevelById(1);

    await tester.pumpWidget(_gameApp(harness, harness.game));
    expect(_tubePainters(tester), isNotEmpty);
    expect(_tubePainters(tester).every((p) => p.colorBlind), isFalse);

    await harness.settings.setColorBlind(true);
    await tester.pumpAndSettle();

    expect(_tubePainters(tester).every((p) => p.colorBlind), isTrue);
  });
}
