// FILE: lib/screens/teacher_dashboard_screen.dart
// PURPOSE: Teacher-only dashboard placeholders (aggregates, struggled words, retention).
// TOOLS: Flutter core.
// RELATIONSHIPS: Included by Shell only when AuthModel.role == teacher; later consumes repositories for analytics.

import 'package:flutter/material.dart';

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Teacher Dashboard')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.assessment),
              title: Text('Class Averages'),
              subtitle: Text('Coming soon…'),
            ),
            ListTile(
              leading: Icon(Icons.warning),
              title: Text('Top Struggled Words'),
              subtitle: Text('Coming soon…'),
            ),
            ListTile(
              leading: Icon(Icons.audiotrack),
              title: Text('Audio Retention'),
              subtitle: Text('Coming soon…'),
            ),
          ],
        ),
      ),
    );
  }
}
