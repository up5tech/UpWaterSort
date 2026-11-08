import 'package:flutter/material.dart';

const Color _seed = Color(0xFF1E88E5);

/// Light theme (PLAN.md §21 Phase 5 adds the dark variant).
ThemeData buildAppTheme({required Brightness brightness}) => ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: brightness),
  useMaterial3: true,
);

final ThemeData kLightTheme = buildAppTheme(brightness: Brightness.light);
final ThemeData kDarkTheme = buildAppTheme(brightness: Brightness.dark);

/// Backwards-compatible alias used before the settings screen existed.
final ThemeData kAppTheme = kLightTheme;
