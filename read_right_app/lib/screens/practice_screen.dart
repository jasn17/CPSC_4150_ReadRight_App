// FILE: lib/screens/practice_screen.dart
// PURPOSE: Shows target word and provides Record/Stop controls (skeleton).
// TOOLS: Flutter core; provider (watch PracticeModel).
// RELATIONSHIPS: Writes PracticeModel.startRecording()/stopRecording(); later will call AudioService -> STTService -> ScoringService.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/practice_model.dart';
import '../widgets/primary_button.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pm = context.watch<PracticeModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Practice')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text(
              pm.target?.word ?? 'Pick a word from Lists',
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (pm.target?.sentence.isNotEmpty == true)
              Text(pm.target!.sentence, textAlign: TextAlign.center),
            const Spacer(),
            PrimaryButton(
              label: 'Fake Assess (for screenshots)',
              onPressed: pm.target == null ? null : () {
                context.read<PracticeModel>().fakeAssess();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fake assessment complete')),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
