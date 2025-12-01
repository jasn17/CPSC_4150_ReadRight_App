import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word_list_model.dart';
import '../models/practice_model.dart';
import '../models/shellModel.dart';

class WordListsScreen extends StatelessWidget {
  const WordListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<WordListModel>();
    final pm = context.watch<PracticeModel>();
    final lists = model.lists;
    final words = model.wordsInSelected;
    final mastered = pm.masteredWordsByList[model.selectedList] ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text('Word Lists')),
      body: Column(
        children: [
          if (lists.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                scrollDirection: Axis.horizontal,
                itemCount: lists.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final list = lists[i];
                  final selected = list == model.selectedList;
                  return ChoiceChip(
                    label: Text(list),
                    selected: selected,
                    onSelected: (_) => model.selectList(list),
                  );
                },
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: words.length,
              itemBuilder: (_, i) {
                final w = words[i];
                final isMastered = mastered.contains(w.word);
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(w.word),
                    subtitle: Text(w.sentence),
                    trailing: isMastered
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () {
                      context.read<PracticeModel>().setTarget(w);
                      context.read<ShellModel>().setIndex(2);
                    },
                    textColor: Theme.of(context).colorScheme.surface.computeLuminance() >= .5
                                ? Theme.of(context).colorScheme.inverseSurface
                                : Theme.of(context).colorScheme.surface,
                    tileColor: Theme.of(context).colorScheme.inversePrimary,
                    splashColor: Theme.of(context).colorScheme.secondary,
                  ),
                );
              },
            ),
    );
  }
}

