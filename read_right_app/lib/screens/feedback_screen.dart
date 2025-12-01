import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/feedback_model.dart';
import '../widgets/feedback_widget.dart';
import 'feedback_item_screen.dart';



class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<FeedbackModel>().history;

    return Scaffold(
      appBar: AppBar(title: const Text('Feedback History')),
      body: history.isEmpty
          ? const Center(child: Text('No feedback yet.'))
          : GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
        padding: const EdgeInsets.all(16),
        children: [
          for (int i = 0; i < history.length; i++)
            FeedbackWidget(
              item: history[i],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => feedback_item_screen(item: history[i]),
                  ),
                );
              },
            )
        ],
      ),
    );
  }
}
