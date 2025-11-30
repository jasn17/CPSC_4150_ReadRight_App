// FILE: lib/app.dart
// PURPOSE: Hosts MaterialApp (theme, title) and chooses home screen by auth state.
// TOOLS: Flutter core; provider (watch AuthModel).
// RELATIONSHIPS: Reads AuthModel to show either lib/screens/login_screen.dart or lib/screens/shell_screen.dart.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/auth_model.dart';
import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';
import 'models/settings_model.dart';
import '/models/shellModel.dart';



class ReadRightApp extends StatelessWidget {
  const ReadRightApp({super.key});

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<AuthModel>().isLoggedIn;
    final settings = context.watch<SettingsModel>();


    return MaterialApp(
      title: 'ReadRight',
      debugShowCheckedModeBanner: false,

      theme: settings.currentTheme.lightTheme,
      darkTheme: settings.currentTheme.darkTheme,

      // Apply your app-wide theme
      themeMode: settings.themeMode,

      home: loggedIn
          ? const ShellScreen()

          : const LoginScreen(),
    );
  }
}
