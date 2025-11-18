import 'package:flutter/material.dart';
import 'theme_definition.dart';

/// Blue & Pink Theme implementing the AppThemeDefinition abstraction
class GoldBlueTheme implements AppThemeDefinition {
  @override
  String get id => 'blue_gold';
  @override
  String get name => 'Blue & Gold';

  // Centralized colors (kept from original AppTheme)
  static const Color primary = Color(0xFF1D3557);   // blue-ish
  static const Color secondary = Color(0xFFD9BF77); // gold accent
  static const Color background = Color(0xFF457B9D);
  static const Color surface = Color(0xFFCAF0F8);

  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.black;
  static const Color onBackground = Color(0xFF212121);
  static const Color onSurface = Color(0xFF424242);

  @override
  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: onPrimary,
      secondary: secondary,
      onSecondary: onSecondary,
      error: Colors.red,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      background: background,
      onBackground: onBackground,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 96, fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(color: onBackground),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: onPrimary,
      titleTextStyle: TextStyle(
        color: onPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: secondary,
      contentTextStyle: TextStyle(color: onSecondary),
    ),
  );

  @override
  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: onPrimary,
      secondary: secondary,
      onSecondary: onSecondary,
      error: Colors.redAccent,
      onError: Colors.white,
      surface: Color(0xFF1E1E1E),
      onSurface: Colors.white70,
      background: Color(0xFF121212),
      onBackground: Colors.white70,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: onPrimary,
      titleTextStyle: TextStyle(
        color: onPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
