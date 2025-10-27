// FILE: lib/screens/progress_screen.dart
// PURPOSE: Shows attempt history and simple average (skeleton data).
// TOOLS: Flutter core; provider (watch ProgressModel).
// RELATIONSHIPS: Reads ProgressModel.attempts/averageScore; later fed by data/attempts_repository.dart.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/progress_model.dart';
import '../widgets/score_badge.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ProgressModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Center(child: ScoreBadge(score: model.average, label: 'Average')),
          const Divider(height: 32),
          Expanded(
            child: ListView.separated(
              itemCount: model.attempts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final a = model.attempts[i];
                return ListTile(
                  title: Text(a.word),
                  subtitle: Text(a.at.toIso8601String()),
                  trailing: Text('${a.score}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
