// FILE: lib/themes/theme_registry.dart
// PURPOSE: manage themes and make multiple themes simpler to plug in to existing architecture.
// RELATIONSHIPS: theme_definition.dart, blue_pink_theme.dart, gold_blue_theme.dart, app.dart, settings, etc.



import 'theme_definition.dart';
import 'blue_pink_theme.dart';
import 'gold_blue_theme.dart';

final List<AppThemeDefinition> availableThemes = [
  BluePinkTheme(),
  GoldBlueTheme(),
  // Add new themes here
];
