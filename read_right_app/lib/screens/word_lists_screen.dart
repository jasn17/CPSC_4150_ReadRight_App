// FILE: lib/screens/word_lists_screen.dart
// PURPOSE: Select a word list and browse words in that list.
// TOOLS: Flutter core; provider (watch WordListModel).
// RELATIONSHIPS: Reads WordListModel.selectedList and .words; (future) sets targets in PracticeModel.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word_list_model.dart';
import '../models/practice_model.dart';
import '../widgets/word_card.dart';

class WordListsScreen extends StatelessWidget {
  const WordListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<WordListModel>();
    final lists = model.lists;

    return Scaffold(
      appBar: AppBar(title: const Text('Word Lists')),
      body: lists.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No lists found. Check assets/seed_words.csv in pubspec.yaml.'),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemCount: lists.length,
              itemBuilder: (ctx, i) {
                final list = lists[i];
                final isSelected = list == model.selectedList;
                final words = model.wordsFor(list);
                return ExpansionTile(
                  key: PageStorageKey('list-$list'),
                  title: Text(
                    list,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  initiallyExpanded: isSelected,
                  onExpansionChanged: (expanded) {
                    if (expanded) {
                      context.read<WordListModel>().selectList(list);
                    }
                  },
                  children: [
                    if (words.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('No words in this list.'),
                      ),
                    if (words.isNotEmpty)
                      ...words.map((w) {
                        return InkWell(
                          onTap: () {
                            context.read<PracticeModel>().setTarget(w);
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Selected "${w.word}" for practice')),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: WordCard(word: w.word, sentence: w.sentence),
                          ),
                        );
                      }).toList(),
                  ],
                );
              },
            ),
    );
  }
}
