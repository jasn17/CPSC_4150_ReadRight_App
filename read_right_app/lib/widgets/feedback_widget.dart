import 'package:flutter/material.dart';
import '../models/feedback_model.dart';

class FeedbackWidget extends StatelessWidget {
  final FeedbackItem item;
  final VoidCallback onTap;

  const FeedbackWidget({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      color: Theme.of(context).colorScheme.inversePrimary,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item.transcript, style: TextStyle(fontSize: 28, color: Theme.of(context).primaryColor)),
              Divider(color: Theme.of(context).primaryColor),
              Text('Score: ${item.score}', style: TextStyle(fontSize: 18, color: Theme.of(context).primaryColor)),
              const SizedBox(height: 8),
              Text(item.correct ? 'Correct' : 'Incorrect',
                  style: TextStyle(
                      color: item.correct ? Colors.green : Colors.red
                  )),
              const SizedBox(height: 8),
              Text(
                item.timestamp.toLocal().toString().split('.')[0],
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
