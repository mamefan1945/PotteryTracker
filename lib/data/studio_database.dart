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
        'photos': jsonEncode(photos),
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
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE studio_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT NOT NULL,
            title TEXT NOT NULL,
            detail TEXT NOT NULL DEFAULT '',
            stage TEXT NOT NULL DEFAULT '',
            notes TEXT NOT NULL DEFAULT '',
            photos TEXT NOT NULL DEFAULT '[]',
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_studio_records_category ON studio_records(category)',
        );
        await db.execute('''
          CREATE TABLE record_links (
            record_id INTEGER NOT NULL,
            related_record_id INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            PRIMARY KEY (record_id, related_record_id),
            CHECK (record_id < related_record_id),
            FOREIGN KEY (record_id) REFERENCES studio_records(id) ON DELETE CASCADE,
            FOREIGN KEY (related_record_id) REFERENCES studio_records(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('CREATE INDEX idx_record_links_related ON record_links(related_record_id)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE studio_records ADD COLUMN photos TEXT NOT NULL DEFAULT '[]'");
        }
        if (oldVersion < 3) {
        await db.execute('''
          CREATE TABLE record_links (
            record_id INTEGER NOT NULL,
            related_record_id INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            PRIMARY KEY (record_id, related_record_id),
            CHECK (record_id < related_record_id),
            FOREIGN KEY (record_id) REFERENCES studio_records(id) ON DELETE CASCADE,
            FOREIGN KEY (related_record_id) REFERENCES studio_records(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('CREATE INDEX idx_record_links_related ON record_links(related_record_id)');
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

  /// Returns every record, optionally restricted to the supplied categories.
  Future<List<StudioRecord>> allRecords({List<String>? categories}) async {
    final db = await database;
    final rows = await db.query(
      'studio_records',
      where: categories == null || categories.isEmpty
          ? null
          : 'category IN (${List.filled(categories.length, '?').join(',')})',
      whereArgs: categories == null || categories.isEmpty ? null : categories,
      orderBy: 'category ASC, title COLLATE NOCASE ASC',
    );
    return rows.map(StudioRecord.fromMap).toList();
  }

  /// Returns records connected to [recordId], regardless of link direction.
  Future<List<StudioRecord>> linkedRecords(int recordId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT r.* FROM studio_records r
      INNER JOIN record_links l
        ON (l.record_id = ? AND l.related_record_id = r.id)
        OR (l.related_record_id = ? AND l.record_id = r.id)
      ORDER BY r.category ASC, r.title COLLATE NOCASE ASC
    ''', [recordId, recordId]);
    return rows.map(StudioRecord.fromMap).toList();
  }

  /// Replaces a record's complete set of relationships transactionally.
  /// Links are stored once with ordered IDs and are visible from both records.
  Future<void> setLinks(int recordId, List<int> relatedIds) async {
    final db = await database;
    final ids = relatedIds.where((id) => id != recordId).toSet();
    await db.transaction((txn) async {
      await txn.delete(
        'record_links',
        where: 'record_id = ? OR related_record_id = ?',
        whereArgs: [recordId, recordId],
      );
      for (final relatedId in ids) {
        final first = recordId < relatedId ? recordId : relatedId;
        final second = recordId < relatedId ? relatedId : recordId;
        await txn.insert('record_links', {
          'record_id': first,
          'related_record_id': second,
          'created_at': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
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

  Future<int> update({
    required int id,
    required String title,
    String detail = '',
    String stage = '',
    String notes = '',
    List<String> photos = const [],
  }) async {
    final db = await database;
    return db.update('studio_records', {
      'title': title.trim(),
      'detail': detail.trim(),
      'stage': stage.trim(),
      'notes': notes.trim(),
      'photos': jsonEncode(photos),
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(int id) async {
    final db = await database;
    return db.delete('studio_records', where: 'id = ?', whereArgs: [id]);
  }
}
