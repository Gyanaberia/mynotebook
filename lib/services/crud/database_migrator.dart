// lib/services/crud/database_migrator.dart
import 'package:mynotebook/constants/sql_commands.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mynotebook/constants/string_constants.dart';


///Enables DB inistialization and schema upgrades of deployed applications
class DatabaseMigrator {
  const DatabaseMigrator();

  static const int currentVersion = 2;

  Future<Database> openDB(String path) {
    return openDatabase(
      path,
      version: currentVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(SqlCommands.createUsersTable);
    await db.execute(SqlCommands.createNotesTable);
    await _ensureSchema(db, 0);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _ensureSchema(db, oldVersion);
  }

  Future<bool> _hasColumn(Database db, String table, String column) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    return info.any((row) => row['name'] == column);
  }

  /// Brings any older notes/users table up to the current shape.
  /// oldVersion == 0 means a legacy (pre-versioning) database.
  /// Add new version steps here, sequentially, as the schema evolves.
  Future<void> _ensureSchema(Database db, int oldVersion) async {
    if (oldVersion < 2) {
      await _addColumnIfMissing(
        db,
        table: StringConstants.notesTable,
        column: StringConstants.firestoreNoteId,
        definition: 'TEXT',
      );
      await _addColumnIfMissing(
        db,
        table: StringConstants.notesTable,
        column: StringConstants.updatedAt,
        definition: 'INTEGER NOT NULL DEFAULT 0',
      );
    }
    // if (oldVersion < 3) { ...future migration step... }
  }

  Future<void> _addColumnIfMissing(
    Database db, {
    required String table,
    required String column,
    required String definition,
  }) async {
    if (!await _hasColumn(db, table, column)) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }
}