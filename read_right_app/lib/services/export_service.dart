// FILE: lib/services/export_service.dart
// PURPOSE: Export practice attempts to CSV or JSON format

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/practice_attempt.dart';
import 'local_db_service.dart';

class ExportService {
  final LocalDbService _localDb = LocalDbService.instance;

  /// Export attempts to CSV format
  Future<String> exportToCSV({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Get attempts for date range
    final attempts = await _getAttempts(userId, startDate, endDate);

    // Build CSV
    final buffer = StringBuffer();
    
    // Header row
    buffer.writeln('Date,Time,Word List,Target Word,Transcript,Score,Correct,Synced');

    // Data rows
    for (final attempt in attempts) {
      final date = _formatDate(attempt.timestamp);
      final time = _formatTime(attempt.timestamp);
      final correct = attempt.correct ? 'Yes' : 'No';
      final synced = attempt.synced ? 'Yes' : 'No';
      
      // Escape commas in transcript
      final transcript = _escapeCsv(attempt.transcript);
      
      buffer.writeln('$date,$time,${attempt.wordList},'
          '${attempt.targetWord},$transcript,'
          '${attempt.score},$correct,$synced');
    }

    return buffer.toString();
  }

  /// Export attempts to JSON format
  Future<String> exportToJSON({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final attempts = await _getAttempts(userId, startDate, endDate);

    // Convert to JSON-friendly format
    final jsonData = {
      'exportDate': DateTime.now().toIso8601String(),
      'userId': userId,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'totalAttempts': attempts.length,
      'attempts': attempts.map((a) => {
        'id': a.id,
        'timestamp': a.timestamp.toIso8601String(),
        'wordList': a.wordList,
        'targetWord': a.targetWord,
        'transcript': a.transcript,
        'score': a.score,
        'correct': a.correct,
        'synced': a.synced,
      }).toList(),
    };

    // Pretty print JSON
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(jsonData);
  }

  /// Save and share CSV file
  Future<void> shareCSV({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    String? studentName,
  }) async {
    final csv = await exportToCSV(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );

    final fileName = _generateFileName(
      prefix: studentName ?? 'student',
      extension: 'csv',
      startDate: startDate,
      endDate: endDate,
    );

    await _saveAndShare(csv, fileName);
  }

  /// Save and share JSON file
  Future<void> shareJSON({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    String? studentName,
  }) async {
    final json = await exportToJSON(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );

    final fileName = _generateFileName(
      prefix: studentName ?? 'student',
      extension: 'json',
      startDate: startDate,
      endDate: endDate,
    );

    await _saveAndShare(json, fileName);
  }

  /// Get summary statistics
  Future<Map<String, dynamic>> getStatistics({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final attempts = await _getAttempts(userId, startDate, endDate);

    if (attempts.isEmpty) {
      return {
        'totalAttempts': 0,
        'averageScore': 0,
        'correctCount': 0,
        'incorrectCount': 0,
        'accuracyRate': 0.0,
        'uniqueWords': 0,
      };
    }

    final correctCount = attempts.where((a) => a.correct).length;
    final totalScore = attempts.fold<int>(0, (sum, a) => sum + a.score);
    final uniqueWords = attempts.map((a) => a.targetWord).toSet().length;

    return {
      'totalAttempts': attempts.length,
      'averageScore': (totalScore / attempts.length).round(),
      'correctCount': correctCount,
      'incorrectCount': attempts.length - correctCount,
      'accuracyRate': (correctCount / attempts.length * 100).round(),
      'uniqueWords': uniqueWords,
    };
  }

  // Helper methods

  Future<List<PracticeAttempt>> _getAttempts(
    String userId,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    if (startDate != null && endDate != null) {
      return await _localDb.getAttemptsByDateRange(userId, startDate, endDate);
    } else {
      return await _localDb.getAttemptsForUser(userId);
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  String _escapeCsv(String value) {
    // If value contains comma, quote, or newline, wrap in quotes and escape quotes
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _generateFileName({
    required String prefix,
    required String extension,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    
    String rangeStr = '';
    if (startDate != null && endDate != null) {
      final start = _formatDate(startDate).replaceAll('-', '');
      final end = _formatDate(endDate).replaceAll('-', '');
      rangeStr = '_${start}_to_$end';
    }

    return '${prefix}_practice_data$rangeStr\_$dateStr.$extension';
  }

  Future<void> _saveAndShare(String content, String fileName) async {
    try {
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';

      // Write file
      final file = File(filePath);
      await file.writeAsString(content);

      // Share file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'ReadRight Practice Data Export',
        text: 'Practice data exported from ReadRight',
      );
    } catch (e) {
      throw Exception('Failed to export file: $e');
    }
  }
}