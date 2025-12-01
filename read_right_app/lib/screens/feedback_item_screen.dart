import 'package:flutter/material.dart';
import '../models/feedback_model.dart';
import '../widgets/score_badge.dart';
import '../widgets/primary_button.dart';
import '/widgets/character_widget.dart';

class feedback_item_screen extends StatelessWidget {
  final FeedbackItem item;

  const feedback_item_screen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CharacterWidget(),
              const SizedBox(height: 24),
              ScoreBadge(score: item.score),
              const SizedBox(height: 16),
              Text(item.correct ? '✅ Correct' : '❌ Try Again',
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 8),
              Text('You said: "${item.transcript}"'),
            ],
          ),
        ),
      ),
    );
  }
}
