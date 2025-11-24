// FILE: lib/main.dart
// PURPOSE: App entrypoint. Initializes Firebase, provides models, and boots the app.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'models/auth_model.dart';
import 'models/word_list_model.dart';
import 'models/practice_model.dart';
import 'models/progress_model.dart';
import 'models/settings_model.dart';
import 'services/sync_service.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env');

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Create instances
  final wordListModel = WordListModel();
  final syncService = SyncService(); // Create sync service
  final practiceModel =
      PracticeModel(syncService); // Pass sync service to practice model

  // Load word lists first
  await wordListModel.loadFromAssets();

  // Initialize practice model (userId will be set after login)
  // We'll set it to a default for now, will update after auth
  await practiceModel.init(wordListModel, 'guest');

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(
          create: (_) => AuthModel(authService: AuthService())),
      ChangeNotifierProvider(create: (_) => SettingsModel()),
      ChangeNotifierProvider.value(value: wordListModel),

      // Correct provider for SyncService (ChangeNotifier!)
      ChangeNotifierProvider<SyncService>.value(value: syncService),

      // PracticeModel depends on SyncService
      ChangeNotifierProvider.value(value: practiceModel),

      ChangeNotifierProvider(create: (_) => ProgressModel()),
    ],
    child: const ReadRightApp(),
  ));
}
