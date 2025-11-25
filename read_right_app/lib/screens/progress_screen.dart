// FILE: lib/screens/progress_screen.dart
// PURPOSE: Shows attempt history and real average score with color-coded display.
// TOOLS: Flutter core; provider (watch ProgressModel).
// RELATIONSHIPS: Reads ProgressModel.attempts/averageScore from local database.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/progress_model.dart';
import '../models/practice_model.dart';
import '../widgets/score_badge.dart';
import '../widgets/analytics_section.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    // Load data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProgress();
    });
  }

  Future<void> _loadUserProgress() async {
    final model = context.read<ProgressModel>();
    
    // Get userId from Firebase Auth
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid ?? 'guest';
    
    // Load attempts for this user
    await model.loadAttemptsForUser(userId);
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ProgressModel>();
    
    // Get background color based on average score
    Color getBackgroundColor(int score) {
      if (score >= 90) {
        return Colors.green.withOpacity(0.1);
      } else if (score >= 80) {
        return Colors.yellow.withOpacity(0.1);
      } else if (score >= 70) {
        return Colors.orange.withOpacity(0.1);
      } else {
        return Colors.red.withOpacity(0.1);
      }
    }

    return Scaffold(
      backgroundColor: model.attempts.isNotEmpty 
          ? getBackgroundColor(model.average)
          : null,
      appBar: AppBar(
        title: const Text('Progress'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadUserProgress(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: model.isLoading
          ? const Center(child: CircularProgressIndicator())
          : model.attempts.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildAverageSection(model),
                      const Divider(height: 32, thickness: 2),
                      
                      // Analytics Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AnalyticsSection(model: model),
                      ),
                      
                      const Divider(height: 32, thickness: 2),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Attempts',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${model.attempts.length} total',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Build attempts list without Expanded (since we're in ScrollView)
                      _buildAttemptsListNonExpandable(model),
                      
                      const SizedBox(height: 16), // Bottom padding
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assessment_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No practice attempts yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start practicing to see your progress!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAverageSection(ProgressModel model) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ScoreBadge(
            score: model.average,
            label: 'Average Score',
            radius: 50,
          ),
          const SizedBox(height: 12),
          _buildScoreLabel(model.average),
        ],
      ),
    );
  }

  Widget _buildScoreLabel(int score) {
    String label;
    Color color;
    
    if (score >= 90) {
      label = 'Excellent! 🌟';
      color = Colors.green;
    } else if (score >= 80) {
      label = 'Great Job! 👍';
      color = Colors.yellow.shade700;
    } else if (score >= 70) {
      label = 'Keep Going! 💪';
      color = Colors.orange;
    } else {
      label = 'Practice More! 📚';
      color = Colors.red;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color.withOpacity(0.9),
        ),
      ),
    );
  }

  Widget _buildAttemptsList(ProgressModel model) {
    final dateFormatter = DateFormat('MMM d, y');
    final timeFormatter = DateFormat('h:mm a');
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: model.attempts.length,
      itemBuilder: (context, index) {
        final attempt = model.attempts[index];
        final date = dateFormatter.format(attempt.at);
        final time = timeFormatter.format(attempt.at);
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: ScoreBadge(
              score: attempt.score,
              radius: 24,
            ),
            title: Text(
              attempt.word,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            trailing: Icon(
              attempt.correct ? Icons.check_circle : Icons.cancel,
              color: attempt.correct ? Colors.green : Colors.red,
              size: 28,
            ),
          ),
        );
      },
    );
  }

  // Non-expandable version for use inside SingleChildScrollView
  Widget _buildAttemptsListNonExpandable(ProgressModel model) {
    final dateFormatter = DateFormat('MMM d, y');
    final timeFormatter = DateFormat('h:mm a');
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      shrinkWrap: true, // Important: allows ListView inside ScrollView
      physics: const NeverScrollableScrollPhysics(), // Disable inner scroll
      itemCount: model.attempts.length,
      itemBuilder: (context, index) {
        final attempt = model.attempts[index];
        final date = dateFormatter.format(attempt.at);
        final time = timeFormatter.format(attempt.at);
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: ScoreBadge(
              score: attempt.score,
              radius: 24,
            ),
            title: Text(
              attempt.word,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            trailing: Icon(
              attempt.correct ? Icons.check_circle : Icons.cancel,
              color: attempt.correct ? Colors.green : Colors.red,
              size: 28,
            ),
          ),
        );
      },
    );
  }
}