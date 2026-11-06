import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:up_water_sort/app.dart';

void main() {
  testWidgets('Phase 0: app launches to a blank screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const UpWaterSortApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'UpWaterSort');
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(Text), findsNothing);
  });
}
