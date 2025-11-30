import 'package:flutter/material.dart';
import '../widgets/character_widget.dart';
import '../data/db.dart';
import '../data/item_model.dart';



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

  Widget _timeGreeting() {
    final hour = DateTime.now().hour;

    String text;
    if (hour >= 5 && hour < 12) {
      text = "Good morning!";
    } else if (hour >= 12 && hour < 18) {
      text = "Good afternoon!";
    } else {
      text = "Good evening!";
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReadRight'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.inversePrimary,             // background
              borderRadius: BorderRadius.circular(55),   // rounded corners
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  offset: const Offset(0, 2),   // horizontal, vertical
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CharacterWidget(),
                const SizedBox(width: 10),
                _timeGreeting(),
              ],
            ),
          )

          // Add the rest of your UI below...
        ],
      ),
    );
  }
}

