// FILE: lib/screens/login_screen.dart
// PURPOSE: Demo login form; triggers sign-in and role switching.
// TOOLS: Flutter core widgets; provider (read/write AuthModel).
// RELATIONSHIPS: Calls AuthModel.signIn()/switchRole(); when AuthModel.isLoggedIn == true, app lands on ShellScreen.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/auth_model.dart';
import '../widgets/primary_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthModel>().role;
    return Scaffold(
      appBar: AppBar(title: const Text('ReadRight — Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Spacer(),
            const Text('Demo Login', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Role: ${role.name}'),
            const SizedBox(height: 8),
            PrimaryButton(
              label: 'Toggle Role (Student/Teacher)',
              onPressed: () => context.read<AuthModel>().toggleRole(),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Continue',
              onPressed: () => context.read<AuthModel>().signIn(role: role),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
