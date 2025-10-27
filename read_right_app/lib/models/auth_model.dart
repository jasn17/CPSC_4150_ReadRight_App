// FILE: lib/models/auth_model.dart
// PURPOSE: Holds login state, current userId, and role (student/teacher).
// TOOLS: ChangeNotifier (Provider state).
// RELATIONSHIPS: Read by app.dart and shell_screen.dart; written by login_screen.dart and settings_screen.dart.

import 'package:flutter/foundation.dart';

enum UserRole { student, teacher }

class AuthModel extends ChangeNotifier {
  bool _isLoggedIn = false;
  UserRole _role = UserRole.student;

  bool get isLoggedIn => _isLoggedIn;
  UserRole get role => _role;

  void signIn({UserRole role = UserRole.student}) {
    _role = role;
    _isLoggedIn = true;
    notifyListeners();
  }

  void signOut() {
    _isLoggedIn = false;
    notifyListeners();
  }

  void toggleRole() {
    _role = _role == UserRole.student ? UserRole.teacher : UserRole.student;
    notifyListeners();
  }

  // Convenience so the app opens straight to the shell for quick screenshots.
  void bootstrapDemo() {
    _isLoggedIn = true;
    _role = UserRole.student;
  }
}
