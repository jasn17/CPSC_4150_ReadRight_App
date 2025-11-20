// FILE: lib/models/auth_model.dart
// PURPOSE: Holds login state, current userId, and role (student/teacher). Bridges UI to Firebase Auth + Realtime DB.
// TOOLS: ChangeNotifier (Provider state), firebase_auth, firebase_database via AuthService.
// RELATIONSHIPS: Read by app.dart and shell_screen.dart; written by login_screen.dart and settings_screen.dart.

import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

enum UserRole { student, teacher }

class AuthModel extends ChangeNotifier {
  AuthModel({required AuthService authService}) : _authService = authService;

  final AuthService _authService;

  bool _isLoggedIn = false;
  String? _uid;
  String? _email;
  UserRole _role = UserRole.student;

  bool get isLoggedIn => _isLoggedIn;
  String? get uid => _uid;
  String? get email => _email;
  UserRole get role => _role;
  AuthService get authService => _authService;

  /// Sign in using email/password through Firebase Auth and load role from Realtime Database
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw Exception('Authentication failed: no user returned');
    }

    _uid = user.uid;
    _email = user.email;

    // Load role from /users/{uid}; require profile to exist to allow access
    final data = await _authService.getUserData(user.uid);
    if (data == null) {
      // If there's no user profile, deny login (limits access to our test users)
      await _authService.signOut();
      throw Exception('Account is not provisioned in ReadRight (no user profile).');
    }
    final roleStr = (data['role'] as String?)?.toLowerCase();
    _role = roleStr == 'teacher' ? UserRole.teacher : UserRole.student;

    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _isLoggedIn = false;
    _uid = null;
    _email = null;
    _role = UserRole.student;
    notifyListeners();
  }

  void toggleRole() {
    _role = _role == UserRole.student ? UserRole.teacher : UserRole.student;
    notifyListeners();
  }

  // Optionally restore auth state on app start (if needed later)
  // Future<void> restore() async {
  //   final user = _authService.currentUser;
  //   if (user != null) {
  //     _uid = user.uid;
  //     _email = user.email;
  //     final data = await _authService.getUserData(user.uid);
  //     final roleStr = (data?['role'] as String?)?.toLowerCase();
  //     _role = roleStr == 'teacher' ? UserRole.teacher : UserRole.student;
  //     _isLoggedIn = true;
  //   }
  //   notifyListeners();
  // }
}
