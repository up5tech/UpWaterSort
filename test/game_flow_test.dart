import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:up_water_sort/app.dart';
import 'package:up_water_sort/controllers/game_controller.dart';
import 'package:up_water_sort/controllers/progress_controller.dart';
import 'package:up_water_sort/domain/solver.dart';
import 'package:up_water_sort/ui/widgets/tube_widget.dart';

import 'harness.dart';

Widget _app(TestHarness harness) => MultiProvider(
  providers: [
    ChangeNotifierProvider<ProgressController>.value(value: harness.progress),
    ChangeNotifierProvider<GameController>.value(value: harness.game),
  ],
  child: const UpWaterSortApp(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Continue plays level 1 to the win, then advances to level 2', (
    tester,
  ) async {
    final harness = await TestHarness.create();
    addTearDown(harness.dispose);

    await tester.pumpWidget(_app(harness));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Level 1'), findsOneWidget);

    final level = harness.levels.byId(1)!;
    final solution = Solver.solve(level.tubes, level.capacity)!;
    for (final move in solution) {
      await tester.tap(find.byType(TubeWidget).at(move.from));
      await tester.pump();
      await tester.tap(find.byType(TubeWidget).at(move.to));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(harness.game.status, GameStatus.won);
    expect(find.text('Level 1 complete!'), findsOneWidget);
    expect(
      harness.progress.starsForLevel(1),
      starsFor(solution.length, level.par),
    );

    await tester.tap(find.text('Next level'));
    await tester.pumpAndSettle();

    expect(find.text('Level 2'), findsOneWidget);
    expect(harness.game.level!.id, 2);
    expect(harness.game.moves, 0);
    expect(harness.game.status, GameStatus.playing);
    expect(harness.progress.data.inProgress!.levelId, 2);
  });

  testWidgets('a relaunch resumes the in-progress game from Home', (
    tester,
  ) async {
    final harness = await TestHarness.create();
    addTearDown(harness.dispose);

    await tester.pumpWidget(_app(harness));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    final level = harness.levels.byId(1)!;
    final move = Solver.solve(level.tubes, level.capacity)!.first;
    await tester.tap(find.byType(TubeWidget).at(move.from));
    await tester.pump();
    await tester.tap(find.byType(TubeWidget).at(move.to));
    await tester.pump();

    final movedTubes = [
      for (final tube in harness.game.tubes) List<int>.of(tube),
    ];
    expect(harness.game.moves, 1);

    // Relaunch: fresh controllers reading the same stored save.
    final relaunched = await harness.relaunch();
    addTearDown(relaunched.dispose);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_app(relaunched));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Level 1'), findsOneWidget);
    expect(relaunched.game.tubes, movedTubes);
    expect(relaunched.game.moves, 1);
  });
}
