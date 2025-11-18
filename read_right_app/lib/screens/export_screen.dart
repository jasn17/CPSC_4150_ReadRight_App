// FILE: lib/screens/export_screen.dart
// PURPOSE: Screen for exporting practice data

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/auth_model.dart';
import '../services/export_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final ExportService _exportService = ExportService();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isExporting = false;
  Map<String, dynamic>? _statistics;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final authModel = context.read<AuthModel>();
    final userId = authModel.uid;
    
    if (userId == null) return;

    final stats = await _exportService.getStatistics(
      userId: userId,
      startDate: _startDate,
      endDate: _endDate,
    );

    setState(() {
      _statistics = stats;
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      await _loadStatistics();
    }
  }

  Future<void> _clearDateRange() async {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    await _loadStatistics();
  }

  Future<void> _exportCSV() async {
    final authModel = context.read<AuthModel>();
    final userId = authModel.uid;
    
    if (userId == null) return;

    setState(() {
      _isExporting = true;
    });

    try {
      await _exportService.shareCSV(
        userId: userId,
        startDate: _startDate,
        endDate: _endDate,
        studentName: authModel.email?.split('@').first,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV exported successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _exportJSON() async {
    final authModel = context.read<AuthModel>();
    final userId = authModel.uid;
    
    if (userId == null) return;

    setState(() {
      _isExporting = true;
    });

    try {
      await _exportService.shareJSON(
        userId: userId,
        startDate: _startDate,
        endDate: _endDate,
        studentName: authModel.email?.split('@').first,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('JSON exported successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Practice Data'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Range Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date Range',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_startDate != null && _endDate != null)
                      Text(
                        '${_formatDate(_startDate!)} to ${_formatDate(_endDate!)}',
                        style: const TextStyle(fontSize: 16),
                      )
                    else
                      const Text(
                        'All time',
                        style: TextStyle(fontSize: 16),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _selectDateRange,
                            icon: const Icon(Icons.date_range),
                            label: const Text('Select Range'),
                          ),
                        ),
                        if (_startDate != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _clearDateRange,
                            icon: const Icon(Icons.clear),
                            tooltip: 'Clear date range',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Statistics
            if (_statistics != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildStatRow('Total Attempts', '${_statistics!['totalAttempts']}'),
                      _buildStatRow('Average Score', '${_statistics!['averageScore']}%'),
                      _buildStatRow('Correct', '${_statistics!['correctCount']}'),
                      _buildStatRow('Incorrect', '${_statistics!['incorrectCount']}'),
                      _buildStatRow('Accuracy Rate', '${_statistics!['accuracyRate']}%'),
                      _buildStatRow('Unique Words', '${_statistics!['uniqueWords']}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Export Buttons
            const Text(
              'Export Format',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportCSV,
              icon: const Icon(Icons.table_chart),
              label: const Text('Export as CSV'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportJSON,
              icon: const Icon(Icons.code),
              label: const Text('Export as JSON'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            if (_isExporting) ...[
              const SizedBox(height: 16),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],

            const SizedBox(height: 24),

            const Text(
              'Note: Exported files will include all practice attempts for the selected date range. You can open CSV files in Excel or Google Sheets.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}