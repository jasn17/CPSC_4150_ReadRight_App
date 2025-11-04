// FILE: lib/app.dart
// PURPOSE: Hosts MaterialApp (theme, title) and chooses home screen by auth state.
// TOOLS: Flutter core; provider (watch AuthModel).
// RELATIONSHIPS: Reads AuthModel to show either lib/screens/login_screen.dart or lib/screens/shell_screen.dart.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/auth_model.dart';
import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/theme.dart';


class ReadRightApp extends StatelessWidget {
  const ReadRightApp({super.key});

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<AuthModel>().isLoggedIn;

    return MaterialApp(
      title: 'ReadRight',
      debugShowCheckedModeBanner: false,

      // Apply your app-wide theme
      theme: AppTheme.lightTheme,      // Light theme
      darkTheme: AppTheme.darkTheme,   // Dark theme
      themeMode: ThemeMode.system,     // Auto-switches with system preference

      home: loggedIn
          ? const ShellScreen()        // main app shell when logged in
          : const LoginScreen(),       // login screen otherwise
    );
  }
}
