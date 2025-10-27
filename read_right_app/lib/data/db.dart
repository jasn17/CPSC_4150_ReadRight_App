import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'item_model.dart';


class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();


  Database? _db;


  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }


  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'solo4_items.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE items (
id INTEGER PRIMARY KEY AUTOINCREMENT,
title TEXT NOT NULL,
note TEXT,
is_done INTEGER NOT NULL DEFAULT 0,
created_at INTEGER NOT NULL
);
''');
      },
    );
  }


  Future<List<Item>> getAll() async {
    try {
      final db = await database;
      final rows = await db.query('items', orderBy: 'created_at DESC');
      return rows.map((m) => Item.fromMap(m)).toList();
    } catch (_) {
// Corruption or weird schema? Recreate table safely.
      await _safeReset();
      return <Item>[];
    }
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


}