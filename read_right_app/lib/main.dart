// FILE: lib/main.dart
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

  // Create instances
  final wordListModel = WordListModel();
  final practiceModel = PracticeModel();

  // Load word lists first
  await wordListModel.loadFromAssets();
  
  // Then initialize practice model with the loaded words
  await practiceModel.init(wordListModel);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthModel(authService: AuthService())),
        ChangeNotifierProvider(create: (_) => SettingsModel()),
        ChangeNotifierProvider.value(value: wordListModel),
        ChangeNotifierProvider.value(value: practiceModel),
        ChangeNotifierProvider(create: (_) => ProgressModel()),
      ],
      child: const ReadRightApp(),
    ),
  );
}