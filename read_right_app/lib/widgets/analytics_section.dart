// FILE: lib/widgets/analytics_section.dart
// PURPOSE: Display analytics like most missed words and improvement trends
// TOOLS: Flutter core, ProgressModel
// RELATIONSHIPS: Used in progress_screen.dart to show analytics

import 'package:flutter/material.dart';
import '../models/progress_model.dart';

class AnalyticsSection extends StatelessWidget {
  final ProgressModel model;
  
  const AnalyticsSection({
    super.key,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    final mostMissed = model.getMostMissedWords(limit: 5);
    final needsPractice = model.getWordsNeedingPractice();
    final improvementTrend = model.getImprovementTrend();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Improvement Trend Card
        if (model.attempts.length >= 20) _buildImprovementTrend(context, improvementTrend),
        
        const SizedBox(height: 16),
        
        // Most Missed Words
        if (mostMissed.isNotEmpty) _buildMostMissedWords(context, mostMissed),
        
        const SizedBox(height: 16),
        
        // Words Needing Practice
        if (needsPractice.isNotEmpty) _buildWordsNeedingPractice(context, needsPractice),
      ],
    );
  }

  Widget _buildImprovementTrend(BuildContext context, double trend) {
    final isImproving = trend > 0;
    final trendColor = isImproving ? Colors.green : Colors.red;
    final trendIcon = isImproving ? Icons.trending_up : Icons.trending_down;
    final trendText = isImproving 
        ? 'You\'re improving! +${trend.toStringAsFixed(1)} points'
        : 'Keep practicing! ${trend.toStringAsFixed(1)} points';

    return Card(
      color: trendColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(trendIcon, color: trendColor, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance Trend',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trendText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: trendColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMostMissedWords(
    BuildContext context,
    List<({String word, double avgScore, int attempts})> mostMissed,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Most Missed Words',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'These words need extra practice:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            ...mostMissed.map((stat) => _buildWordStatRow(
              context,
              word: stat.word,
              score: stat.avgScore.round(),
              attempts: stat.attempts,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildWordsNeedingPractice(
    BuildContext context,
    List<({String word, double successRate, int attempts})> needsPractice,
  ) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.priority_high, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Priority Practice',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Words with less than 50% success rate:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 12),
            ...needsPractice.take(5).map((stat) => _buildWordStatRow(
              context,
              word: stat.word,
              score: (stat.successRate * 100).round(),
              attempts: stat.attempts,
              showAsPercentage: true,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildWordStatRow(
    BuildContext context, {
    required String word,
    required int score,
    required int attempts,
    bool showAsPercentage = false,
  }) {
    Color getScoreColor(int score) {
      if (score >= 90) return Colors.green;
      if (score >= 80) return Colors.yellow.shade700;
      if (score >= 70) return Colors.orange;
      return Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Word
          Expanded(
            flex: 3,
            child: Text(
              word,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // Score
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: getScoreColor(score).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: getScoreColor(score),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    showAsPercentage ? '$score%' : '$score',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: getScoreColor(score),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Attempts count
          Expanded(
            flex: 2,
            child: Text(
              '$attempts ${attempts == 1 ? 'try' : 'tries'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}