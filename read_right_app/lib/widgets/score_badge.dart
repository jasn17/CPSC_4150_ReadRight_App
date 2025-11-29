// FILE: lib/widgets/score_badge.dart
// PURPOSE: Circular badge that renders a numeric score.
// TOOLS: Flutter core.
// RELATIONSHIPS: Used by feedback_screen.dart; can be reused in progress summaries.

import 'package:flutter/material.dart';
import '/models/progress_model.dart';

class ScoreBadge extends StatelessWidget {
  final int score;
  final String? label;
  const ScoreBadge({super.key, required this.score, this.label});

  // Helper to map score to a color
  Color _getColorForScore(BuildContext context) {
    if (score >= 90) {
      return const Color.fromARGB(255, 255, 185, 0);          // Excellent
    } else if (score >= 80) {
      return const Color.fromARGB(255, 192, 192, 192);     // Good
    } else if (score >= 70) {
      return const Color.fromARGB(255, 205, 127, 50);         // Average
    } else {
      return Colors.grey.shade700;      // Poor
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getColorForScore(context);
    return Column(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: bgColor,
          child: Text('$score', style: const TextStyle(fontSize: 22)),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(label!, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ],
    );
  }
}
