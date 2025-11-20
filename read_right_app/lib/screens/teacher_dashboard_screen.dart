// FILE: lib/screens/teacher_dashboard_screen.dart
// PURPOSE: Teacher-only dashboard placeholders (aggregates, struggled words, retention).
// TOOLS: Flutter core.
// RELATIONSHIPS: Included by Shell only when AuthModel.role == teacher; later consumes repositories for analytics.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/auth_model.dart';

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthModel>();
    final authService = auth.authService;
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ListTile(
              leading: Icon(Icons.assessment),
              title: Text('Class Averages'),
              subtitle: Text('Coming soon…'),
            ),
            const SizedBox(height: 12),
            const Text('Your classes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: authService.getClassesForTeacher(auth.uid ?? ''),
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
                  if (snap.hasError) return Text('Error: ${snap.error}');
                  final classes = snap.data ?? [];
                  if (classes.isEmpty) return const Text('No classes yet.');
                  // For MVP show first class and its students
                  final cls = classes.first;
                  final students = (cls['students'] as List?)?.map((e) => e.toString()).toList() ?? [];
                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: authService.getUserProfilesByUids(students),
                    builder: (c2, s2) {
                      if (s2.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
                      if (s2.hasError) return Text('Error: ${s2.error}');
                      final profiles = s2.data ?? [];
                      return ListView(
                        children: profiles.map((p) {
                          return ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(p['username'] ?? p['email'] ?? 'Unknown'),
                            subtitle: Text(p['email'] ?? ''),
                          );
                        }).toList(),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
