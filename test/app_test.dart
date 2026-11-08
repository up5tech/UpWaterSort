import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:up_water_sort/app.dart';
import 'package:up_water_sort/controllers/game_controller.dart';
import 'package:up_water_sort/controllers/progress_controller.dart';
import 'package:up_water_sort/controllers/settings_controller.dart';
import 'package:up_water_sort/ui/screens/game_screen.dart';
import 'package:up_water_sort/ui/widgets/tube_widget.dart';

import 'harness.dart';

Widget _app(TestHarness harness) => MultiProvider(
  providers: [
    ChangeNotifierProvider<ProgressController>.value(value: harness.progress),
    ChangeNotifierProvider<SettingsController>.value(value: harness.settings),
    ChangeNotifierProvider<GameController>.value(value: harness.game),
  ],
  child: const UpWaterSortApp(),
);

void main() {
  testWidgets('Phase 3: app opens on Home and Continue starts level 1', (
    tester,
  ) async {
    final harness = await TestHarness.create();
    addTearDown(harness.dispose);

    await tester.pumpWidget(_app(harness));

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'UpWaterSort');
    expect(find.text('UpWaterSort'), findsOneWidget);
    expect(find.text('0 stars'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Select level'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Level 1'), findsOneWidget);
    expect(harness.game.level!.id, 1);
    expect(find.text('Moves 0'), findsOneWidget);
  });

  testWidgets('Phase 2: eight tubes fit on a small phone without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final harness = await TestHarness.create();
    addTearDown(harness.dispose);
    harness.game.startLevel(
      testLevel(
        id: 25,
        colorCount: 6,
        par: 20,
        tubes: [
          [0, 1, 2, 3],
          [1, 2, 3, 4],
          [2, 3, 4, 5],
          [3, 4, 5, 0],
          [4, 5, 0, 1],
          [5, 0, 1, 2],
          <int>[],
          <int>[],
        ],
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ProgressController>.value(
            value: harness.progress,
          ),
          ChangeNotifierProvider<SettingsController>.value(
            value: harness.settings,
          ),
          ChangeNotifierProvider<GameController>.value(value: harness.game),
        ],
        child: const MaterialApp(home: GameScreen()),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(TubeWidget), findsNWidgets(8));
  });
}
