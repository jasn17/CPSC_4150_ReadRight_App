// FILE: lib/main.dart
// PURPOSE: App entrypoint. Initializes Firebase, provides models, and boots the app.
// TOOLS: Flutter core; provider (MultiProvider + ChangeNotifier); firebase_core.
// RELATIONSHIPS: Creates instances of models in lib/models/* and hands control to ReadRightApp in lib/app.dart.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'models/auth_model.dart';
import 'models/word_list_model.dart';
import 'models/practice_model.dart';
import 'models/progress_model.dart';
import 'models/settings_model.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthModel(authService: AuthService())),
        ChangeNotifierProvider(create: (_) => SettingsModel()),
        ChangeNotifierProvider(create: (_) => WordListModel()..loadFromAssets()),
        ChangeNotifierProvider(create: (_) => PracticeModel()),
        ChangeNotifierProvider(create: (_) => ProgressModel()),
      ],
      child: const ReadRightApp(),
    ),
  );
}
