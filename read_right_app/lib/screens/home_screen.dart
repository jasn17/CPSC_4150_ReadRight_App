import 'package:flutter/material.dart';
import '../widgets/character_widget.dart';
import '../data/db.dart';
import '../data/item_model.dart';
import '../widgets/home_card.dart';
import 'package:provider/provider.dart';
import '../models/practice_model.dart';
import '../models/word_list_model.dart';
import '/services/wordOfTheDay_service.dart';
import '/models/shellModel.dart';
import '../models/auth_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = AppDatabase();
  final _items = <Item>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Widget _timeGreeting(BuildContext context) {
    final hour = DateTime.now().hour;

    String text;
    if (hour >= 5 && hour < 12) {
      text = "Good morning!";
    } else if (hour >= 12 && hour < 18) {
      text = "Good afternoon!";
    } else {
      text = "Good evening!";
    }

    final textColor = Colors.black;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
      ),
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await _db.getAll();
      setState(() {
        _items
          ..clear()
          ..addAll(rows);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wordOfTheDayService =
        WordOfTheDayService(context.watch<WordListModel>());

    final pm = context.watch<PracticeModel>();
    final wm = context.watch<WordListModel>();

    final mastered = pm.masteredCount(wm.selectedList ?? '');
    final totalWords = wm.wordsInSelected.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ReadRight 📚'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting with character
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .inversePrimary
                          .withAlpha(255),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: Colors.grey.shade300, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          offset: const Offset(0, 2),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CharacterWidget(),
                        const SizedBox(width: 10),
                        _timeGreeting(context),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Main action buttons (Word Lists, Practice, Progress, Settings)
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      HomeCard(
                        icon: Icons.list,
                        label: "Word Lists",
                        onTap: () => context.read<ShellModel>().setIndex(1),
                      ),
                      HomeCard(
                        icon: Icons.mic,
                        label: "Practice",
                        onTap: () => context.read<ShellModel>().setIndex(2),
                      ),
                      HomeCard(
                        icon: Icons.insights,
                        label: "Progress",
                        onTap: () => context.read<ShellModel>().setIndex(4),
                      ),
                      HomeCard(
                        icon: Icons.settings,
                        label: "Settings",
                        onTap: () {
                          final isTeacher = context.read<AuthModel>().role ==
                              UserRole.teacher;
                          context
                              .read<ShellModel>()
                              .setIndex(isTeacher ? 6 : 5);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Word of The Day card
                  FutureBuilder<WordItem?>(
                    future: wordOfTheDayService.getWordOfTheDay(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData) {
                        return Card(
                          color:
                              Theme.of(context).colorScheme.secondaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              "Word of the Day unavailable",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          ),
                        );
                      }

                      final wordOfTheDay = snapshot.data!;
                      return Card(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Word of the Day:",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                wordOfTheDay.word,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              if (wordOfTheDay.sentence.isNotEmpty)
                                Text(
                                  wordOfTheDay.sentence,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Visual Progress / call progress bar
                  Text(
                    'Progress: $mastered / $totalWords',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: totalWords == 0 ? 0 : mastered / totalWords,
                    minHeight: 8,
                    color: Theme.of(context).colorScheme.secondary,
                    backgroundColor: Colors.white,
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
