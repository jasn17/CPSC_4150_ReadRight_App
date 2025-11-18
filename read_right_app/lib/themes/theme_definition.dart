import 'package:flutter/material.dart';

/// Interface / abstraction for a theme
abstract class AppThemeDefinition {
  String get id;              // Unique identifier
  String get name;            // Display name
  ThemeData get lightTheme;   // Light variant
  ThemeData get darkTheme;    // Dark variant
}
