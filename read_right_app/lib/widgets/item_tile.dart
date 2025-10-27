import 'package:flutter/material.dart';
import '../data/item_model.dart';


class ItemTile extends StatelessWidget {
  final Item item;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;


  const ItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });


  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Checkbox(value: item.isDone, onChanged: (_) => onToggle()),
        title: Text(
          item.title,
          style: TextStyle(
            decoration: item.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: item.note == null || item.note!.isEmpty
            ? null
            : Text(item.note!),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}