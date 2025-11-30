// FILE: lib/screens/feedback_item_screen.dart
// PURPOSE: Displays requested result (transcript, score, correctness)
// TOOLS: Flutter core; provider (watch PracticeModel).
// RELATIONSHIPS: Reads PracticeModel.lastResult; uses widgets/score_badge.dart; Retry calls PracticeModel.reset().

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/practice_model.dart';
import '../widgets/score_badge.dart';
import '../widgets/primary_button.dart';
import '/widgets/character_widget.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final last = context.watch<PracticeModel>().lastResult;
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: last == null
              ? const Text('No recent practice results.\nPractice now!', textAlign: TextAlign.center)
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CharacterWidget(),
              const SizedBox(height: 24),
              ScoreBadge(score: last.score),
              const SizedBox(height: 16),
              Text(last.correct ? '✅ Correct' : '❌ Try Again', style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 8),
              Text('You said: "${last.transcript}"'),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Reset',
                onPressed: () => context.read<PracticeModel>().reset(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
