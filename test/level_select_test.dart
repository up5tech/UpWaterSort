import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:up_water_sort/app.dart';
import 'package:up_water_sort/controllers/game_controller.dart';
import 'package:up_water_sort/controllers/progress_controller.dart';
import 'package:up_water_sort/controllers/settings_controller.dart';
import 'package:up_water_sort/ui/screens/game_screen.dart';

import 'harness.dart';

void main() {
  testWidgets('shows locks and stars, and only unlocked levels open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final harness = await TestHarness.create();
    addTearDown(harness.dispose);
    await harness.progress.completeLevel(harness.levels.byId(1)!, 3);

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
        child: const UpWaterSortApp(),
      ),
    );

    await tester.tap(find.text('Select level'));
    await tester.pumpAndSettle();

    expect(find.text('Select level'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNWidgets(3));
    expect(find.byIcon(Icons.star_border), findsNWidgets(3));
    expect(find.byIcon(Icons.lock), findsNWidgets(28));

    // Level 3 is still locked.
    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsNothing);
    expect(harness.game.isStarted, isFalse);

    // Level 1 opens the game.
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text('Level 1'), findsOneWidget);
    expect(harness.game.level!.id, 1);
  });
}
