// FILE: lib/screens/shell_screen.dart
// PURPOSE: Bottom navigation container for 6+ sections of the app.
// TOOLS: Flutter core; provider (read AuthModel.role).
// RELATIONSHIPS: Hosts WordLists, Practice, Feedback, Progress, Teacher (if role==teacher), and Settings screens.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/auth_model.dart';
import 'word_lists_screen.dart';
import 'practice_screen.dart';
import 'feedback_screen.dart';
import 'progress_screen.dart';
import 'teacher_dashboard_screen.dart';
import 'settings_screen.dart';
import 'home_screen.dart';
import '../models/shellModel.dart';




class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {

  @override
  Widget build(BuildContext context) {
    final isTeacher = context.watch<AuthModel>().role == UserRole.teacher;

    final shellModel = context.watch<ShellModel>();
    final index = shellModel.index;

    final pages = <Widget>[
      const HomeScreen(),
      const WordListsScreen(),
      const PracticeScreen(),
      const FeedbackScreen(),
      const ProgressScreen(),
      if (isTeacher) const TeacherDashboardScreen(),
      const SettingsScreen(),
    ];
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.house), label: 'Home'),
      const BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Lists'),
      const BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Practice'),
      const BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Feedback'),
      const BottomNavigationBarItem(icon: Icon(Icons.insights), label: 'Progress'),
      if (isTeacher) const BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Teacher'),
      const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
    ];

    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        items: items,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => shellModel.setIndex(i),
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        backgroundColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.primary.computeLuminance() > 0.5
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.inversePrimary,
      ),
    );
  }
}
