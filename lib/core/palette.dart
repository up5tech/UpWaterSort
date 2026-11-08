import 'package:flutter/material.dart';

/// Liquid colors. A tube layer stores an index into this list.
const List<Color> kPalette = [
  Color(0xFFE53935), // 0 red
  Color(0xFF1E88E5), // 1 blue
  Color(0xFF43A047), // 2 green
  Color(0xFFFDD835), // 3 yellow
  Color(0xFF8E24AA), // 4 purple
  Color(0xFFFB8C00), // 5 orange
  Color(0xFF00ACC1), // 6 teal
  Color(0xFFD81B60), // 7 magenta
  Color(0xFF6D4C41), // 8 brown
  Color(0xFF7CB342), // 9 lime
  Color(0xFF546E7A), // 10 blue-gray
  Color(0xFFF48FB1), // 11 light pink
  Color(0xFF3F51B5), // 12 indigo
  Color(0xFFD84315), // 13 deep orange
  Color(0xFF212121), // 14 charcoal
  Color(0xFF9E9E9E), // 15 grey
];

/// Symbols drawn on liquid layers in color-blind mode (PLAN.md §12.4).
const List<String> kSymbols = [
  '●',
  '■',
  '▲',
  '★',
  '◆',
  '✚',
  '♥',
  '☾',
  '✿',
  '☀',
  '✖',
  '⬟',
  '⬢',
  '◉',
  '▣',
  '✱',
];
