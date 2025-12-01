// FILE: lib/screens/data_preview_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DataPreviewScreen extends StatelessWidget {
  final String data;
  final String title;
  final String format; // 'csv' or 'json'

  const DataPreviewScreen({
    super.key,
    required this.data,
    required this.title,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy to clipboard',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: data));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                data,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Total characters: ${data.length}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (format == 'csv') ...[
              const SizedBox(height: 8),
              Text(
                'Total rows: ${data.split('\n').length}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}