import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:up_water_sort/controllers/game_controller.dart';
import 'package:up_water_sort/controllers/progress_controller.dart';
import 'package:up_water_sort/controllers/settings_controller.dart';
import 'package:up_water_sort/domain/models/move.dart';
import 'package:up_water_sort/ui/screens/game_screen.dart';
import 'package:up_water_sort/ui/widgets/tube_painter.dart';
import 'package:up_water_sort/ui/widgets/tube_widget.dart';

import 'harness.dart';

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
  testWidgets('Add tube adds one tube and then disables itself', (
    tester,
  ) async {
    final harness = await TestHarness.create();
    addTearDown(harness.dispose);
    harness.game.startLevel(
      testLevel(
        tubes: [
          [0, 1],
          [1, 0],
          [0, 1],
          [1, 0],
          <int>[],
          <int>[],
        ],
      ),
    );

    await tester.pumpWidget(_gameApp(harness, harness.game));
    expect(find.byType(TubeWidget), findsNWidgets(6));

    await tester.tap(find.text('Add tube'));
    await tester.pumpAndSettle();

    expect(find.byType(TubeWidget), findsNWidgets(7));
    expect(harness.game.extraTubeUsed, isTrue);

    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Add tube'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('Hint highlights the suggested tubes and names the move', (
    tester,
  ) async {
    final harness = await TestHarness.create();
    addTearDown(harness.dispose);
    final game = GameController(
      levels: harness.levels,
      progress: harness.progress,
      audio: harness.audio,
      settings: harness.settings,
      hintSolver: (tubes, capacity) async => const Move(0, 2, 2),
    );
    addTearDown(game.dispose);
    game.startLevel(
      testLevel(
        tubes: [
          [0, 1],
          [1, 0],
          [0, 1],
          [1, 0],
          <int>[],
          <int>[],
        ],
      ),
    );

    await tester.pumpWidget(_gameApp(harness, game));
    await tester.tap(find.text('Hint'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(game.hint, const Move(0, 2, 2));
    expect(find.text('Pour tube 1 into tube 3'), findsOneWidget);
    expect(_tubePainters(tester).where((p) => p.hinted), hasLength(2));

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('Hint reports when no solution is found', (tester) async {
    final harness = await TestHarness.create();
    addTearDown(harness.dispose);
    final game = GameController(
      levels: harness.levels,
      progress: harness.progress,
      audio: harness.audio,
      settings: harness.settings,
      hintSolver: (tubes, capacity) async => null,
    );
    addTearDown(game.dispose);
    game.startLevel(
      testLevel(
        tubes: [
          [0, 1],
          [1, 0],
          [],
          [],
        ],
      ),
    );

    await tester.pumpWidget(_gameApp(harness, game));
    await tester.tap(find.text('Hint'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(game.hint, isNull);
    expect(find.text('No hint found, try Undo.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
