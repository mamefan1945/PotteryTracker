import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class StudioRecord {
  const StudioRecord({
    required this.id,
    required this.category,
    required this.title,
    this.detail = '',
    this.stage = '',
    this.notes = '',
    this.photos = const [],
    required this.createdAt,
  });

  final int id;
  final String category;
  final String title;
  final String detail;
  final String stage;
  final String notes;
  final List<String> photos;
  final String createdAt;

  factory StudioRecord.fromMap(Map<String, Object?> map) => StudioRecord(
        id: map['id'] as int,
        category: map['category'] as String,
        title: map['title'] as String,
        detail: (map['detail'] as String?) ?? '',
        stage: (map['stage'] as String?) ?? '',
        notes: (map['notes'] as String?) ?? '',
        photos: (jsonDecode((map['photos'] as String?) ?? '[]') as List).cast<String>(),
        createdAt: map['created_at'] as String,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'category': category,
        'title': title,
        'detail': detail,
        'stage': stage,
        'notes': notes,
        'created_at': createdAt,
      };
}

class StudioDatabase {
  StudioDatabase._();
  static final StudioDatabase instance = StudioDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final root = await getDatabasesPath();
    _database = await openDatabase(
      p.join(root, 'pottery_tracker.db'),
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE studio_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT NOT NULL,
            title TEXT NOT NULL,
            detail TEXT NOT NULL DEFAULT '',
            stage TEXT NOT NULL DEFAULT '',
            notes TEXT NOT NULL DEFAULT '',
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_studio_records_category ON studio_records(category)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE studio_records ADD COLUMN photos TEXT NOT NULL DEFAULT '[]'");
        }
      },
    );
    return _database!;
  }

  Future<List<StudioRecord>> records(String category) async {
    final db = await database;
    final rows = await db.query(
      'studio_records',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(StudioRecord.fromMap).toList();
  }

  Future<int> add({
    required String category,
    required String title,
    String detail = '',
    String stage = '',
    String notes = '',
    List<String> photos = const [],
  }) async {
    final db = await database;
    return db.insert('studio_records', {
      'category': category,
      'title': title.trim(),
      'detail': detail.trim(),
      'stage': stage.trim(),
      'notes': notes.trim(),
      'photos': jsonEncode(photos),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> delete(int id) async {
    final db = await database;
    return db.delete('studio_records', where: 'id = ?', whereArgs: [id]);
  }
}
