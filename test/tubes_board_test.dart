import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:up_water_sort/controllers/game_controller.dart';
import 'package:up_water_sort/controllers/settings_controller.dart';
import 'package:up_water_sort/ui/widgets/tube_widget.dart';
import 'package:up_water_sort/ui/widgets/tubes_board.dart';

import 'harness.dart';

void main() {
  testWidgets('renders one tube per layer and taps select a tube', (
    tester,
  ) async {
    final harness = await TestHarness.create();
    addTearDown(harness.dispose);
    harness.game.startLevel(
      testLevel(
        colorCount: 4,
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

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<GameController>.value(value: harness.game),
          ChangeNotifierProvider<SettingsController>.value(
            value: harness.settings,
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: TubesBoard())),
      ),
    );

    expect(find.byType(TubeWidget), findsNWidgets(6));

    await tester.tap(find.byType(TubeWidget).first);
    await tester.pump();

    expect(harness.game.selected, 0);
  });

  testWidgets('fits an 18-tube capacity-5 board on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final harness = await TestHarness.create();
    addTearDown(harness.dispose);
    harness.game.startLevel(
      testLevel(
        capacity: 5,
        colorCount: 16,
        tubes: [
          for (var color = 0; color < 16; color++)
            [
              color,
              color + 1,
              color + 2,
              color + 3,
              color + 4,
            ].map((c) => c % 16).toList(),
          <int>[],
          <int>[],
        ],
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<GameController>.value(value: harness.game),
          ChangeNotifierProvider<SettingsController>.value(
            value: harness.settings,
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: TubesBoard())),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(TubeWidget), findsNWidgets(18));
  });
}
