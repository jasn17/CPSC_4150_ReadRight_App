// FILE: lib/main.dart
// PURPOSE: App entrypoint. Initializes Provider models and boots the MaterialApp.
// TOOLS: Flutter core; provider (MultiProvider + ChangeNotifier).
// RELATIONSHIPS: Creates instances of models in lib/models/* and hands control to ReadRightApp in lib/app.dart.
// FILE: lib/main.dart
// PURPOSE: App entrypoint. Provides models and boots the app.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'models/auth_model.dart';
import 'models/word_list_model.dart';
import 'models/practice_model.dart';
import 'models/progress_model.dart';
import 'models/settings_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthModel()..bootstrapDemo()),
        ChangeNotifierProvider(create: (_) => SettingsModel()),
        ChangeNotifierProvider(create: (_) => WordListModel()..loadFromAssets()),
        ChangeNotifierProvider(create: (_) => PracticeModel()),
        ChangeNotifierProvider(create: (_) => ProgressModel()),
      ],
      child: const ReadRightApp(),
    ),
  );
}
