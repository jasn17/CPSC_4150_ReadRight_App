// FILE: lib/services/local_db_service.dart
// PURPOSE: Manages SQLite database for offline practice attempt queue

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/practice_attempt.dart';

class LocalDbService {
  static Database? _database;
  static const String _tableName = 'practice_attempts';

  // Singleton pattern
  static final LocalDbService instance = LocalDbService._internal();
  LocalDbService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'readright.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName(
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            wordList TEXT NOT NULL,
            targetWord TEXT NOT NULL,
            transcript TEXT NOT NULL,
            score INTEGER NOT NULL,
            correct INTEGER NOT NULL,
            timestamp TEXT NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  /// Save a practice attempt to local database
  Future<void> saveAttempt(PracticeAttempt attempt) async {
    final db = await database;
    await db.insert(
      _tableName,
      attempt.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all unsynced attempts
  Future<List<PracticeAttempt>> getUnsyncedAttempts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'timestamp ASC',
    );

    return List.generate(maps.length, (i) => PracticeAttempt.fromMap(maps[i]));
  }

  /// Mark an attempt as synced
  Future<void> markAsSynced(String id) async {
    final db = await database;
    await db.update(
      _tableName,
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get all attempts for a specific user
  Future<List<PracticeAttempt>> getAttemptsForUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) => PracticeAttempt.fromMap(maps[i]));
  }

  /// Get attempts by date range
  Future<List<PracticeAttempt>> getAttemptsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'userId = ? AND timestamp >= ? AND timestamp <= ?',
      whereArgs: [
        userId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) => PracticeAttempt.fromMap(maps[i]));
  }

  /// Delete old synced attempts (older than 30 days)
  Future<void> cleanupOldAttempts() async {
    final db = await database;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    await db.delete(
      _tableName,
      where: 'synced = ? AND timestamp < ?',
      whereArgs: [1, thirtyDaysAgo.toIso8601String()],
    );
  }

  /// Get count of unsynced attempts
  Future<int> getUnsyncedCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE synced = 0'
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Clear all data (for testing/debug)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(_tableName);
  }
}