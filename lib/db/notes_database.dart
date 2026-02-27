import 'package:keepset/model/note.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../model/block.dart';

class NotesDatabase {
  static final NotesDatabase instance = NotesDatabase._init();
  static Database? _database;

  NotesDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // ───────────────── CREATE TABLE + INDEXES

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableNotes (
        ${NoteFields.id} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${NoteFields.title} TEXT NOT NULL,
        ${NoteFields.blocks} TEXT NOT NULL DEFAULT '[]',
        ${NoteFields.disableAutoDone} INTEGER NOT NULL DEFAULT 0,
        ${NoteFields.lifecycle} TEXT NOT NULL
          CHECK (${NoteFields.lifecycle} IN ('ACTIVE','DONE','ARCHIVED'))
          DEFAULT 'ACTIVE',
        ${NoteFields.time} TEXT NOT NULL,
        ${NoteFields.updatedAt} TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_notes_lifecycle ON $tableNotes(${NoteFields.lifecycle})',
    );

    await db.execute(
      'CREATE INDEX idx_notes_created ON $tableNotes(${NoteFields.time})',
    );

    await db.execute('''
      CREATE INDEX idx_notes_lifecycle_updated
      ON $tableNotes(${NoteFields.lifecycle}, ${NoteFields.updatedAt} DESC)
    ''');
  }

  // ───────────────── TRANSACTION HELPER

  Future<void> runInTransaction(
    Future<void> Function(Transaction txn) action,
  ) async {
    final db = await database;
    await db.transaction(action);
  }

  // ───────────────── CREATE

  Future<Note> create(Note note) async {
    final now = DateTime.now();
    final db = await database;

    final id = await db.insert(
      tableNotes,
      note.copy(createdTime: now, updatedAt: now).toJson(),
    );

    return note.copy(id: id, createdTime: now, updatedAt: now);
  }

  // ───────────────── READ

  Future<List<Note>> readItemsNotes({bool includeArchived = false}) async {
    final db = await database;

    final where =
        includeArchived ? null : "${NoteFields.lifecycle} != 'ARCHIVED'";

    final result = await db.query(
      tableNotes,
      where: where,
      orderBy: '''
        CASE ${NoteFields.lifecycle}
          WHEN 'ACTIVE' THEN 0
          WHEN 'DONE' THEN 1
          ELSE 2
        END,
        ${NoteFields.updatedAt} DESC
      ''',
    );

    return result.map(Note.fromJson).toList();
  }

  Future<List<Note>> readHomeNotes() async {
    final db = await database;

    final result = await db.query(
      tableNotes,
      where: "${NoteFields.lifecycle} = 'ACTIVE'",
      orderBy: '${NoteFields.updatedAt} DESC',
      limit: 5,
    );

    return result.map(Note.fromJson).toList();
  }

  Future<List<Note>> readArchivedNotes() async {
    final db = await database;

    final result = await db.query(
      tableNotes,
      where: "${NoteFields.lifecycle} = 'ARCHIVED'",
      orderBy: '${NoteFields.updatedAt} DESC',
    );

    return result.map(Note.fromJson).toList();
  }

  Future<List<Note>> readByLifecycle(Set<LifecycleState> states) async {
    final db = await database;
    final names = states.map((e) => e.name.toUpperCase()).toList();

    final result = await db.query(
      tableNotes,
      where:
          '${NoteFields.lifecycle} IN (${List.filled(names.length, '?').join(',')})',
      whereArgs: names,
      orderBy: '${NoteFields.updatedAt} DESC',
    );

    return result.map(Note.fromJson).toList();
  }

  Future<Note> readNote(int id) async {
    final db = await database;

    final maps = await db.query(
      tableNotes,
      where: '${NoteFields.id} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) throw Exception('Note $id not found');
    return Note.fromJson(maps.first);
  }

  Future<Note?> readNoteOrNull(int id) async {
    final db = await database;

    final maps = await db.query(
      tableNotes,
      where: '${NoteFields.id} = ?',
      whereArgs: [id],
      limit: 1,
    );

    return maps.isEmpty ? null : Note.fromJson(maps.first);
  }

  // ───────────────── UPDATE (PARTIAL)

  Future<void> update(Note note) async {
    await runInTransaction((txn) async {
      await txn.update(
        tableNotes,
        note.copy(updatedAt: DateTime.now()).toJson(),
        where: '${NoteFields.id} = ?',
        whereArgs: [note.id],
      );
    });
  }

  Future<void> updateTitle(int id, String title) async {
    await runInTransaction((txn) async {
      await txn.update(
        tableNotes,
        {
          NoteFields.title: title,
          NoteFields.updatedAt: DateTime.now().toIso8601String(),
        },
        where: '${NoteFields.id} = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> updateBlocks(int id, List<Block> blocks) async {
    await runInTransaction((txn) async {
      await txn.update(
        tableNotes,
        {
          NoteFields.blocks: Block.listToJson(blocks),
          NoteFields.updatedAt: DateTime.now().toIso8601String(),
        },
        where: '${NoteFields.id} = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> touch(int id) async {
    await runInTransaction((txn) async {
      await txn.update(
        tableNotes,
        {
          NoteFields.updatedAt: DateTime.now().toIso8601String(),
        },
        where: '${NoteFields.id} = ?',
        whereArgs: [id],
      );
    });
  }

  // ───────────────── LIFECYCLE

  Future<void> updateLifecycle(int id, LifecycleState next) async {
    await runInTransaction((txn) async {
      await txn.update(
        tableNotes,
        {
          NoteFields.lifecycle: next.name.toUpperCase(),
          NoteFields.updatedAt: DateTime.now().toIso8601String(),
        },
        where: '${NoteFields.id} = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> updateLifecycleBatch(
    List<int> ids,
    LifecycleState next,
  ) async {
    if (ids.isEmpty) return;

    final placeholders = List.filled(ids.length, '?').join(',');

    await runInTransaction((txn) async {
      await txn.update(
        tableNotes,
        {
          NoteFields.lifecycle: next.name.toUpperCase(),
          NoteFields.updatedAt: DateTime.now().toIso8601String(),
        },
        where: '${NoteFields.id} IN ($placeholders)',
        whereArgs: ids,
      );
    });
  }

  // ───────────────── DELETE

  Future<void> delete(int id) async {
    final db = await database;
    await db.delete(
      tableNotes,
      where: '${NoteFields.id} = ?',
      whereArgs: [id],
    );
  }

  // ───────────────── COUNTS / CHECKS

  Future<int> countByLifecycle(LifecycleState state) async {
    final db = await database;

    final result = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM $tableNotes WHERE ${NoteFields.lifecycle} = ?',
        [state.name.toUpperCase()],
      ),
    );

    return result ?? 0;
  }

  Future<bool> exists(int id) async {
    final db = await database;

    final result = await db.query(
      tableNotes,
      columns: [NoteFields.id],
      where: '${NoteFields.id} = ?',
      whereArgs: [id],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // ───────────────── LOGIC ONLY (NOT UI-WIRED)

  void evaluateChecklistCompletion(Note note) {
    if (note.lifecycleState != LifecycleState.active) return;
    if (note.disableAutoDone) return;

    final checklistBlocks = note.blocks.whereType<ChecklistBlock>().toList();
    if (checklistBlocks.isEmpty) return;

    final allChecked = checklistBlocks.every(
      (b) => b.items.every((i) => i.checked),
    );

    if (!allChecked) return;

    updateLifecycle(note.id!, LifecycleState.done);
  }
}
