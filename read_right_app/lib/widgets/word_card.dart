// FILE: lib/widgets/word_card.dart
// PURPOSE: Displays a target word with an optional sample sentence.
// TOOLS: Flutter core.
// RELATIONSHIPS: Used by practice_screen.dart; can be reused in word list previews.

import 'package:flutter/material.dart';

class WordCard extends StatelessWidget {
  final String word;
  final String? sentence;
  const WordCard({super.key, required this.word, this.sentence});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        title: Text(word, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        subtitle: (sentence == null || sentence!.isEmpty) ? null : Text(sentence!),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
