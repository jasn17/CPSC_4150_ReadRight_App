// FILE: lib/main.dart
// PURPOSE: App entrypoint. Initializes Firebase, provides models, and boots the app.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
import 'models/shellModel.dart';
import 'models/feedback_model.dart';


Future<void> main() async {
  await dotenv.load(fileName: '.env');

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Create instances
  final wordListModel = WordListModel();
  final syncService = SyncService();
  final practiceModel = PracticeModel(syncService);
  final progressModel = ProgressModel();
  final feedbackModel = FeedbackModel(maxItems: 6);


  // Load word lists first
  await wordListModel.loadFromAssets();

  // Get current user from Firebase Auth
  final currentUser = FirebaseAuth.instance.currentUser;
  final userId = currentUser?.uid ?? 'guest';

  // Initialize practice model with current userId
  await practiceModel.init(wordListModel, userId);
  practiceModel.setUserId(userId);

  // Load progress for current user
  await progressModel.loadAttemptsForUser(userId);

  // Connect PracticeModel to ProgressModel for real-time updates
  practiceModel.setProgressModel(progressModel);

  // Connect PracticeModel to FeedbackModel for history display
  practiceModel.setFeedbackModel(feedbackModel);

  // Listen for auth state changes and update models accordingly
  FirebaseAuth.instance.authStateChanges().listen((User? user) async {
    if (user != null) {
      // User logged in - update models with their userId
      debugPrint('User logged in: ${user.uid}');
      
      // Switch to new user and load their data
      await practiceModel.switchUser(user.uid, wordListModel);
      await progressModel.loadAttemptsForUser(user.uid);
    } else {
      // User logged out - switch to guest mode
      debugPrint('User logged out - using guest mode');
      
      await practiceModel.switchUser('guest', wordListModel);
      await progressModel.loadAttemptsForUser('guest');
    }
  });

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(
          create: (_) => AuthModel(authService: AuthService())),
      ChangeNotifierProvider(create: (_) => SettingsModel()),
      ChangeNotifierProvider.value(value: wordListModel),
      ChangeNotifierProvider<SyncService>.value(value: syncService),
      ChangeNotifierProvider.value(value: practiceModel),
      ChangeNotifierProvider.value(value: progressModel),
      ChangeNotifierProvider(create: (_) => ShellModel()),
      ChangeNotifierProvider(create: (_) => FeedbackModel(maxItems: 5)),
    ],
    child: const ReadRightApp(),
  ));
}