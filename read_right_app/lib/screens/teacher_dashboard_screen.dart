// FILE: lib/screens/teacher_dashboard_screen.dart
// PURPOSE: Teacher-only dashboard placeholders (aggregates, struggled words, retention).
// TOOLS: Flutter core.
// RELATIONSHIPS: Included by Shell only when AuthModel.role == teacher; later consumes repositories for analytics.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/auth_model.dart';
import 'export_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  String? _selectedClassId;
  int _refreshKey = 0;

  void _refresh() {
    setState(() {
      _refreshKey++;
    });
  }

  Future<void> _showCreateClassDialog(BuildContext context, String teacherUid) async {
    final nameController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Class'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Class Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (result == true && nameController.text.trim().isNotEmpty) {
      try {
        final authService = context.read<AuthModel>().authService;
        final newClassId = await authService.createClass(
          teacherUid: teacherUid,
          className: nameController.text.trim(),
        );
        setState(() {
          _selectedClassId = newClassId;
        });
        _refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Class created!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _showCreateStudentDialog(BuildContext context, String classId) async {
    final emailController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Student Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Student Username'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Default student password: firstpassword',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Confirm your teacher password:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Your Password'),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (result == true &&
        emailController.text.trim().isNotEmpty &&
        usernameController.text.trim().isNotEmpty &&
        passwordController.text.isNotEmpty) {
      try {
        final auth = context.read<AuthModel>();
        final authService = auth.authService;
        await authService.createStudent(
          email: emailController.text.trim(),
          username: usernameController.text.trim(),
          classId: classId,
          teacherEmail: auth.email ?? '',
          teacherPassword: passwordController.text,
        );
        _refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student created and added to class!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthModel>();
    final authService = auth.authService;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create Class',
            onPressed: () => _showCreateClassDialog(context, auth.uid ?? ''),
          ),
        ],
      ),
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
            Row(
              children: [
                const Text('Your classes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Create Class',
                  onPressed: () => _showCreateClassDialog(context, auth.uid ?? ''),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              key: ValueKey(_refreshKey),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: authService.getClassesForTeacher(auth.uid ?? ''),
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) return Text('Error: ${snap.error}');
                  final classes = snap.data ?? [];
                  if (classes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('No classes yet.'),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Create your first class'),
                            onPressed: () => _showCreateClassDialog(context, auth.uid ?? ''),
                          ),
                        ],
                      ),
                    );
                  }
                  // Show all classes in a dropdown, then students for selected class
                  final currentClass = _selectedClassId != null
                      ? classes.firstWhere((c) => c['id'] == _selectedClassId,
                          orElse: () => classes.first)
                      : classes.first;
                  _selectedClassId = currentClass['id'];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButton<String>(
                        value: _selectedClassId,
                        items: classes.map((c) {
                          return DropdownMenuItem<String>(
                            value: c['id'],
                            child: Text(c['name'] ?? 'Unnamed'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedClassId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Students', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.person_add, size: 20),
                            tooltip: 'Add Student',
                            onPressed: () => _showCreateStudentDialog(context, _selectedClassId!),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _buildStudentList(authService, currentClass),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Practice Data'),
              subtitle: const Text('Download CSV or JSON'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ExportScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentList(authService, Map<String, dynamic> cls) {
    final students = (cls['students'] as List?)?.map((e) => e.toString()).toList() ?? [];
    if (students.isEmpty) {
      return const Center(child: Text('No students in this class yet.'));
    }
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: authService.getUserProfilesByUids(students),
      builder: (c2, s2) {
        if (s2.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
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
  }
}
