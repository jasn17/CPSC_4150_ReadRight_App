import 'package:flutter/material.dart';
import '../data/db.dart';
import '../data/item_model.dart';
import '../widgets/item_tile.dart';


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
  Future<void> _createOrEdit({Item? existing}) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final noteCtrl = TextEditingController(text: existing?.note ?? '');


    final result = await showDialog<Item>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(existing == null ? 'Add item' : 'Edit item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Title can\'t be empty')),
                  );
                  return;
                }
                final item = (existing ?? Item(title: title, note: noteCtrl.text.trim(), createdAt: DateTime.now()))
                    .copyWith(title: title, note: noteCtrl.text.trim());
                Navigator.pop(ctx, item);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (result == null) return;


    try {
      if (existing == null) {
        final inserted = await _db.insert(result);
        setState(() => _items.insert(0, inserted));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved')),
        );
      } else {
        await _db.update(result.copyWith(id: existing.id));
        final idx = _items.indexWhere((i) => i.id == existing.id);
        if (idx != -1) setState(() => _items[idx] = result.copyWith(id: existing.id));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Updated')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('DB error: $e')),
      );
    }
  }


  Future<void> _toggle(Item item) async {
    final updated = item.copyWith(isDone: !item.isDone);
    try {
      await _db.update(updated);
      final idx = _items.indexWhere((i) => i.id == item.id);
      if (idx != -1) setState(() => _items[idx] = updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Couldn\'t update: $e')),
      );
    }
  }
  Future<void> _delete(Item item) async {
    try {
      await _db.delete(item.id!);
      setState(() => _items.removeWhere((i) => i.id == item.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Couldn\'t delete: $e')),
      );
    }
  }


  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all?'),
        content: const Text('This will remove all items.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok != true) return;
    await _db.clearAll();
    setState(() => _items.clear());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All cleared')),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solo 4 — Local Data'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Clear all',
            onPressed: _items.isEmpty ? null : _clearAll,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const _EmptyView()
          : ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final item = _items[i];
          return ItemTile(
            item: item,
            onToggle: () => _toggle(item),
            onEdit: () => _createOrEdit(existing: item),
            onDelete: () => _delete(item),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createOrEdit(),
        tooltip: 'Add item',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.inbox_outlined, size: 72),
            SizedBox(height: 12),
            Text('No items yet'),
            SizedBox(height: 4),
            Text('Tap + to add your first item'),
          ],
        ),
      ),
    );
  }
}