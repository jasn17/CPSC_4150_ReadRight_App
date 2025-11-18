import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/practice_model.dart';
import '../models/word_list_model.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/primary_button.dart';
import '../widgets/flip_card.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  @override
  Widget build(BuildContext context) {
    final pm = context.watch<PracticeModel>();
    final wm = context.watch<WordListModel>();
    final target = pm.target;

    if (target == null) return const Center(child: CircularProgressIndicator());

    final mastered = pm.masteredCount(wm.selectedList ?? '');
    final totalWords = wm.wordsInSelected.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice'),
        actions: [
          IconButton(
            icon: Icon(pm.isCardMode ? Icons.mic : Icons.style),
            onPressed: () => pm.toggleMode(),
            tooltip:
                pm.isCardMode ? 'Switch to Speech Mode' : 'Switch to Card Mode',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Progress bar: mastered / total
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progress: $mastered / $totalWords',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: totalWords == 0 ? 0 : mastered / totalWords,
                      minHeight: 8,
                      color: Colors.green,
                      backgroundColor: Colors.white,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: pm.isCardMode
                    ? _buildCardMode(context, wm, target)
                    : _buildSpeechMode(context, pm, target),
              ),
            ],
          ),
          if (!pm.isCardMode)
            ConfettiOverlay(trigger: pm.lastResult?.correct == true),
        ],
      ),
    );
  }

  Widget _buildCardMode(
      BuildContext context, WordListModel wm, WordItem currentCard) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: FlipCard(
                word: currentCard.word,
                sentence1: currentCard.sentence1,
                sentence2: currentCard.sentence2,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => wm.nextCard(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Next',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeechMode(
      BuildContext context, PracticeModel pm, WordItem target) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () async {
                  // Replay word or sentence
                },
                child: pm.lastResult?.correct == true || pm.lastResult?.correct == false
                    ? _SentenceCard(sentence: target.sentence)
                    : _WordCard(word: target.word),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (pm.lastResult != null) _FeedbackBar(result: pm.lastResult!),
          const SizedBox(height: 16),
          PrimaryButton(
            label: pm.isRecording ? 'Recording...' : 'Tap to Record',
            onPressed: pm.isRecording
                ? null
                : () => pm.startRecording(context.read<WordListModel>()),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  final String word;
  const _WordCard({required this.word});

  @override
  Widget build(BuildContext context) => Card(
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Center(
            child: Text(
              word,
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
}

class _SentenceCard extends StatelessWidget {
  final String sentence;
  const _SentenceCard({required this.sentence});

  @override
  Widget build(BuildContext context) => Card(
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              sentence,
              style: const TextStyle(fontSize: 22),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
}

class _FeedbackBar extends StatelessWidget {
  final PracticeResult result;
  const _FeedbackBar({required this.result});

  @override
  Widget build(BuildContext context) {
    final emoji = result.correct ? '🎉' : '😕';
    return Column(
      children: [
        Text(
          '$emoji ${result.correct ? "Great job!" : "Try again!"}',
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: result.score / 100,
          backgroundColor: Colors.grey[300],
          color: result.correct ? Colors.green : Colors.red,
          minHeight: 10,
        ),
        const SizedBox(height: 4),
        Text('Score: ${result.score} | Heard: "${result.transcript}"'),
      ],
    );
  }
}
