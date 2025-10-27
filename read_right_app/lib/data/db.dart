// lib/data/db.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'item_model.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, 'solo4_items.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            note TEXT,
            is_done INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL
          );
        ''');
      },
    );
    return _db!;
  }

  Future<List<Item>> getAll() async {
    final db = await database;
    final rows = await db.query('items', orderBy: 'created_at DESC');
    return rows.map(Item.fromMap).toList();
  }

  Future<Item> insert(Item item) async {
    final db = await database;
    final id = await db.insert('items', item.toMap());
    return item.copyWith(id: id);
  }

  Future<int> update(Item item) async {
    final db = await database;
    return db.update('items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  // >>> Add these two if missing <<<
  Future<int> delete(int id) async {
    final db = await database;
    return db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearAll() async {
    final db = await database;
    return db.delete('items');
  }
}