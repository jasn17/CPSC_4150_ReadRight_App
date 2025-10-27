// FILE: lib/widgets/score_badge.dart
// PURPOSE: Circular badge that renders a numeric score.
// TOOLS: Flutter core.
// RELATIONSHIPS: Used by feedback_screen.dart; can be reused in progress summaries.

import 'package:flutter/material.dart';

class ScoreBadge extends StatelessWidget {
  final int score;
  final String? label;
  const ScoreBadge({super.key, required this.score, this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 36,
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
