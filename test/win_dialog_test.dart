import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:up_water_sort/controllers/settings_controller.dart';
import 'package:up_water_sort/ui/widgets/win_dialog.dart';

import 'harness.dart';

void main() {
  testWidgets('WinDialog shows the earned stars and stats', (tester) async {
    final harness = await TestHarness.create();
    addTearDown(harness.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsController>.value(
            value: harness.settings,
          ),
        ],
        child: MaterialApp(
          home: WinDialog(
            levelNumber: 3,
            moves: 10,
            par: 10,
            stars: 2,
            canContinue: true,
          ),
        ),
      ),
    );

    // 2 filled stars + 1 outline star, for 3 total star icons.
    final stars = tester.widgetList<Icon>(find.byType(Icon)).toList();
    expect(stars, hasLength(3));
    expect(stars.where((i) => i.icon == Icons.star_rounded).length, 2);
    expect(stars.where((i) => i.icon == Icons.star_outline_rounded).length, 1);

    // Stats and the earned-star count are shown.
    expect(find.text('Moves: 10   Par: 10'), findsOneWidget);
    expect(find.text('2 stars'), findsOneWidget);
    expect(find.text('Level 3 complete!'), findsOneWidget);
  });
}
