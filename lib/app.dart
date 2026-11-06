import 'package:flutter/material.dart';

/// Root widget. Phase 0 ships a blank screen; routes and providers are wired
/// in later phases (PLAN.md sections 11 and 12).
class UpWaterSortApp extends StatelessWidget {
  const UpWaterSortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'UpWaterSort', home: Scaffold());
  }
}
