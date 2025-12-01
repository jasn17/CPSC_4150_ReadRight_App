// FILE: lib/widgets/score_badge.dart
// PURPOSE: Circular badge that renders a numeric score with color-coded background.
// TOOLS: Flutter core.
// RELATIONSHIPS: Used by progress_screen.dart for displaying scores.

import 'package:flutter/material.dart';

class ScoreBadge extends StatelessWidget {
  final int score;
  final String? label;
  final double radius;
  const ScoreBadge({
    super.key, 
    required this.score, 
    this.label,
    this.radius = 36,
  });

  // Helper to map score to a color based on requirements:
  // 90-100: Green
  // 80-89: Yellow
  // 70-79: Orange
  // 0-69: Red
  Color _getColorForScore() {
    if (score >= 90) {
      return Colors.green;           // Excellent: 90-100
    } else if (score >= 80) {
      return Colors.yellow.shade600;  // Good: 80-89
    } else if (score >= 70) {
      return Colors.orange;           // Average: 70-79
    } else {
      return Colors.red;              // Poor: 0-69
    }
  }

  // Get text color that contrasts well with background
  Color _getTextColor() {
    if (score >= 90) {
      return Colors.white;  // White on green
    } else if (score >= 80) {
      return Colors.black;  // Black on yellow
    } else if (score >= 70) {
      return Colors.white;  // White on orange
    } else {
      return Colors.white;  // White on red
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getColorForScore();
    final textColor = _getTextColor();
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: bgColor,
          child: Text(
            '$score',
            style: TextStyle(
              fontSize: radius * 0.6,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label!,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ],
    );
  }
}