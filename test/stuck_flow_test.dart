import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:up_water_sort/controllers/game_controller.dart';
import 'package:up_water_sort/controllers/progress_controller.dart';
import 'package:up_water_sort/controllers/settings_controller.dart';
import 'package:up_water_sort/ui/screens/game_screen.dart';
import 'package:up_water_sort/ui/widgets/stuck_dialog.dart';
import 'package:up_water_sort/ui/widgets/tube_widget.dart';

import 'harness.dart';

Widget _gameApp(TestHarness harness) => MultiProvider(
  providers: [
    ChangeNotifierProvider<ProgressController>.value(value: harness.progress),
    ChangeNotifierProvider<SettingsController>.value(value: harness.settings),
    ChangeNotifierProvider<GameController>.value(value: harness.game),
  ],
  child: const MaterialApp(home: GameScreen()),
);

Finder _tube(int index) => find.byWidgetPredicate(
  (widget) => widget is TubeWidget && widget.index == index,
  description: 'tube $index',
);

Finder _dialogButton(String label) => find.descendant(
  of: find.byType(StuckDialog),
  matching: find.widgetWithText(TextButton, label),
);

/// A two-tube board whose only legal pour immediately dead-ends.
Future<void> _reachStuck(WidgetTester tester, TestHarness harness) async {
  harness.game.startLevel(
    testLevel(
      tubes: [
        [0, 1],
        [0, 1],
      ],
    ),
  );
  await tester.pumpWidget(_gameApp(harness));
  await tester.tap(_tube(0));
  await tester.pump();
  await tester.tap(_tube(1));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('stuck shows a popup, not the old bottom banner', (tester) async {
    final harness = await TestHarness.create();
    addTearDown(harness.dispose);
    await _reachStuck(tester, harness);

    expect(harness.game.status, GameStatus.stuck);
    expect(find.byType(StuckDialog), findsOneWidget);
    expect(find.text('No moves left'), findsOneWidget);
    expect(
      find.text('Undo a move, add an extra tube, or restart this level.'),
      findsOneWidget,
    );
    // The old inline banner is gone.
    expect(
      find.text('No moves left. Undo, add a tube or restart.'),
      findsNothing,
    );
  });

  testWidgets('Undo from the popup returns to play', (tester) async {
    final harness = await TestHarness.create();
    addTearDown(harness.dispose);
    await _reachStuck(tester, harness);

    expect(_dialogButton('Undo'), findsOneWidget);
    await tester.tap(_dialogButton('Undo'));
    await tester.pumpAndSettle();

    expect(harness.game.status, GameStatus.playing);
    expect(harness.game.moves, 0);
    expect(find.byType(StuckDialog), findsNothing);
  });

  testWidgets('Add tube from the popup unblocks the board', (tester) async {
    final harness = await TestHarness.create();
    addTearDown(harness.dispose);
    await _reachStuck(tester, harness);

    await tester.tap(_dialogButton('Add tube'));
    await tester.pumpAndSettle();

    expect(harness.game.status, GameStatus.playing);
    expect(harness.game.extraTubeUsed, isTrue);
    expect(harness.game.tubes, hasLength(3));
    expect(find.byType(StuckDialog), findsNothing);
  });

  testWidgets('Restart from the popup starts the level over', (tester) async {
    final harness = await TestHarness.create();
    addTearDown(harness.dispose);
    await _reachStuck(tester, harness);

    final restart = find.descendant(
      of: find.byType(StuckDialog),
      matching: find.widgetWithText(FilledButton, 'Restart'),
    );
    expect(restart, findsOneWidget);
    await tester.tap(restart);
    await tester.pumpAndSettle();

    expect(harness.game.status, GameStatus.playing);
    expect(harness.game.moves, 0);
    expect(harness.game.extraTubeUsed, isFalse);
    expect(find.byType(StuckDialog), findsNothing);
  });
}
