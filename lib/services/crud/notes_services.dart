import 'dart:async';
import 'package:mynotebook/constants/sql_commands.dart';
import 'package:mynotebook/constants/string_constants.dart';
import 'package:mynotebook/services/crud/database_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'package:sqflite/sqflite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NotesServices {
  Database? _db;
  // A private list to store the notes in memory
  List<DatabaseNotes> _notes = [];
  //Store changes of notes
  late final StreamController<List<DatabaseNotes>> _notesController;
  // Private named constructor to create a singleton instance
  NotesServices._sharedInstance() {
    _notesController = StreamController<List<DatabaseNotes>>.broadcast(
      onListen: () => _notesController.sink.add(_notes),
    );
  }
  //instance of that constructor
  static final NotesServices _shared = NotesServices._sharedInstance();
  //singleton
  factory NotesServices() => _shared;

  //the changes are provided as a stream to the UI
  Stream<List<DatabaseNotes>> get allNotes => _notesController.stream;

  /////////////////////////////////
  ///DB MANAGEMENT
  ////////////////////////////////

  DatabaseUser? _currentUser;
  // DatabaseUser? get getUser => _currentUser;
  // Setting the current user is what triggers loading their notes:
  Future<void> setCurrentUser(DatabaseUser user) async {
    _currentUser = user;
    await _cachedNotes();
  }


  //Private caches existing notes in the db
  Future<void> _cachedNotes() async {
    final user = _currentUser;
    _notes = user == null ? [] : await getAllNotesOfUser(user.userId);
    _notesController.add(_notes);
  }

  ///Opens the database if it is not already open
  Future<void> open() {
    // If the database is already open, do nothing
    if (_db != null) return Future.value(null);
    // Otherwise, initialize the database
    return _initializeDb();
  }

  Future<Database> _openDatabase(String path) {
    return openDatabase(
      path,
      version: int.tryParse(dotenv.env["DB_VERSION"] ?? "1"),
      onCreate: (db, version) async {
        // Runs for fresh installs AND legacy (version 0) files.
        await db
            .execute(SqlCommands.createUsersTable); // IF NOT EXISTS stays here
        await db.execute(SqlCommands.createNotesTable);
        await _ensureSchema(db); // repairs legacy tables
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 1) {
          await _ensureSchema(db); // add future steps below
        }
        //All versions should be added sequentially here
      },
      onOpen: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

//Checks if the provided table has the column or not
  Future<bool> _hasColumn(Database db, String table, String column) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    return info.any((row) => row['name'] == column);
  }

  /// Brings any older notes/users table up to the current shape.
  Future<void> _ensureSchema(Database db) async {
    if (!await _hasColumn(
        db, StringConstants.notesTable, StringConstants.cloudSync)) {
      await db.execute(
        'ALTER TABLE ${StringConstants.notesTable} '
        'ADD COLUMN ${StringConstants.cloudSync} INTEGER NOT NULL DEFAULT 0',
      );
    }
    // add further "if column missing, ALTER TABLE ADD COLUMN" checks here
  }

  /// Initializes the database by opening it and creating the necessary tables.
  /// Throws [MissingPlatformDirectoryException] if the platform directory is not found.
  /// Throws [DatabaseNotCreatedException] if the database cannot be created.
  Future<Database> _initializeDb() async {
    Database? db;
    try {
      final dbPath = await getApplicationDocumentsDirectory();
      final path = join(dbPath.path, StringConstants.databaseName);
      db = await _openDatabase(path);
      _db = db;
      return db;
    } on MissingPlatformDirectoryException catch (e) {
      await db?.close();
      _db = null;
      throw Exception('Could not find the database directory: $e');
    } catch (e) {
      await db?.close();
      _db = null;
      throw Exception('Error initializing the database: $e');
    }
  }

  Future<void> _ensureDBisOpen() async {
    await open();
  }

  ///Getter to access the database instance
  Database get _getDb {
    if (_db != null) {
      return _db!;
    } else {
      throw DatabaseNotOpenException();
    }
  }

  /// Closes the database if it is open, otherwise throws an exception
  /// Throws [DatabaseNotOpenException] if the database is not open.
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    } else {
      throw DatabaseNotOpenException();
    }
  }

  //////////////////////////////////
  //USER MANAGEMENT
  /////////////////////////////////

  //Get user if present or create new from given values
  Future<DatabaseUser> getOrCreateUser(
      {required String email, String? username}) async {
    await _ensureDBisOpen();

    DatabaseUser user;
    try {
      user = await getUser(email: email);
    } on UserDoesntExistException {
      user = await createUser(email: email, username: username);
    }
    return user;
  }

  /// Creates a new user in the database with the given email and username.
  /// Throws [UserAlreadyExistsException] if a user with the given email already exists.
  /// Returns a [DatabaseUser] object representing the created user.
  Future<DatabaseUser> createUser(
      {required String email, String? username}) async {
    await _ensureDBisOpen();
    final database = _getDb;

    final existingUsers = await database.query(StringConstants.usersTable,
        limit: 1,
        where: '${StringConstants.email}=?',
        whereArgs: [email.toLowerCase()]);
    if (existingUsers.isNotEmpty) {
      throw UserAlreadyExistsException("User with email $email already exists");
    }

    try {
      final userId = await database.insert(
        StringConstants.usersTable,
        {
          StringConstants.email: email.toLowerCase(),
          StringConstants.userName: username ?? email.toLowerCase(),
        },
        conflictAlgorithm:
            ConflictAlgorithm.abort, //This can give race condition errors
      );
      return DatabaseUser(
          userId: userId, email: email.toLowerCase(), username: username);
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw UserAlreadyExistsException(
            "User with email $email already exists");
      }
      rethrow;
    }
  }

  /// Retrieves a user from the database by their email.
  /// Throws [UserDoesntExistException] if the user with the given email does not exist.
  Future<DatabaseUser> getUser({required String email}) async {
    await _ensureDBisOpen();
    final database = _getDb;

    final user = await database.query(StringConstants.usersTable,
        where: '${StringConstants.email} = ?',
        whereArgs: [email.toLowerCase()]);
    if (user.isEmpty) {
      throw UserDoesntExistException("User with email $email does not exist");
    } else {
      return DatabaseUser.fromMap(user.first);
    }
  }

  /// Retrieves a user from the database by their email.
  /// Throws [CouldntDeleteUserException] if the user with the given email does not exist.
  Future<void> deleteUser({required String email}) async {
    await _ensureDBisOpen();
    final database = _getDb;

    final deletedUser = await database.delete(StringConstants.usersTable,
        where: '${StringConstants.email} = ?',
        whereArgs: [email.toLowerCase()]);
    if (deletedUser < 1) {
      throw CouldntDeleteUserException(
          "Could not delete user with email $email");
    }
  }

  /////////////////////////
  //NOTES MANAGEMENT
  /////////////////////////

  ///Creates a note for the provided user
  Future<DatabaseNotes> createNote({required DatabaseUser owner}) async {
    await _ensureDBisOpen();
    final database = _getDb;

    final dbUser = await getUser(email: owner.email);
    //Make sure owner exist in the database
    if (dbUser != owner) {
      throw UserMismatchException(
          "Owner reference doesn't match database record");
    }
    //insert the note in the database
    final noteId = await database.insert(
      StringConstants.notesTable,
      {
        StringConstants.title: "",
        StringConstants.content: "",
        StringConstants.userId: dbUser.userId,
        StringConstants.cloudSync: 0, // Default value for cloud sync
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    //Return that note to the UI
    final note = DatabaseNotes(
      noteId: noteId,
      title: "",
      content: "",
      userId: dbUser.userId,
      cloudSync: false, // Default value for cloud sync
    );
    _notes.add(note);
    _notesController.add(_notes);
    return note;
  }

  Future<DatabaseNotes> getNote(int noteId) async {
    await _ensureDBisOpen();
    final database = _getDb;

    final notes = await database.query(
      StringConstants.notesTable,
      where: '${StringConstants.noteId} = ?',
      whereArgs: [noteId],
    );

    if (notes.isEmpty) {
      throw NoteNotPresentException('Note with ID $noteId does not exist');
    }

    return DatabaseNotes.fromMap(notes.first);
  }

  Future<List<DatabaseNotes>> getAllNotesOfUser(int userId) async {
    await _ensureDBisOpen();
    final database = _getDb;

    final notes = await database.query(StringConstants.notesTable,
        where: '${StringConstants.userId} = ?', whereArgs: [userId]);
    return notes.map((note) => DatabaseNotes.fromMap(note)).toList();
  }

  ///Returns all notes in the database. Used for caching the local db
  Future<List<DatabaseNotes>> getAllNotes() async {
    await _ensureDBisOpen();
    final database = _getDb;

    final notes = await database.query(StringConstants.notesTable);
    return notes.map((note) => DatabaseNotes.fromMap(note)).toList();
  }

  ///Returns updated note
  ///
  ///Throws [CouldntUpdateNoteException] when update fails
  Future<DatabaseNotes> updateNote(
      {required int noteId,
      String? title,
      String? content,
      String? cloudSync}) async {
    await _ensureDBisOpen();

    final database = _getDb;

    final updateData = {
      if (title != null) StringConstants.title: title,
      if (content != null) StringConstants.content: content,
      if (cloudSync != null)
        StringConstants.cloudSync: cloudSync == 'true' ? 1 : 0,
    };
    final updatedCount = await database.update(
      StringConstants.notesTable,
      updateData,
      where: '${StringConstants.noteId} = ?',
      whereArgs: [noteId],
    );
    if (updatedCount == 0) {
      throw CouldntUpdateNoteException(
          "The note may not exist of update failed");
    }
    final note = await getNote(noteId);
    _notes.removeWhere((note) => note.noteId == noteId);
    _notes.add(note);
    _notesController.add(_notes);
    return note;
  }

  Future<void> deleteNote(int noteId) async {
    await _ensureDBisOpen();
    final database = _getDb;

    int deleteCount = await database.delete(
      StringConstants.notesTable,
      where: '${StringConstants.noteId} = ?',
      whereArgs: [noteId],
    );
    if (deleteCount == 0) {
      throw NoteNotPresentException('Note with ID $noteId does not exist');
    }
    _notes.removeWhere((note) => note.noteId == noteId);
    _notesController.add(_notes);
  }
  
  Future<int> deleteNotesInBatch(List<int> noteIds) async {
    await _ensureDBisOpen();
    final database = _getDb;
    if (noteIds.isEmpty) return 0;

    final placeholders = List.filled(noteIds.length, '?').join(',');
    final deleteCount = await database.delete(
      StringConstants.notesTable,
      where: '${StringConstants.noteId} IN ($placeholders)',
      whereArgs: noteIds,
    );

    _notes.removeWhere((note) => noteIds.contains(note.noteId));
    _notesController.add(_notes);   // one emission for the whole batch
    return deleteCount;
  }
  
  Future<int> deleteAllNotesOfUser(int userId) async {
    await _ensureDBisOpen();

    final database = _getDb;
    // final notes = await database.query(StringConstants.notesTable, where: '${StringConstants.userId} = ?', whereArgs: [userId]);

    final deleteCount = await database.delete(
      StringConstants.notesTable,
      where: '${StringConstants.userId} = ?',
      whereArgs: [userId],
    );
    _notes.removeWhere((note) => note.userId == userId);
    _notesController.add(_notes);
    return deleteCount;
  }

}

class CouldntUpdateNoteException implements Exception {
  final String message;
  CouldntUpdateNoteException(this.message);
}

class DatabaseAlreadyOpenException implements Exception {}

class DatabaseNotOpenException implements Exception {}

class DatabaseNotCreatedException implements Exception {
  final String message;
  DatabaseNotCreatedException(this.message);
}

class CouldntDeleteUserException implements Exception {
  final String message;
  CouldntDeleteUserException(this.message);
}

class UserAlreadyExistsException implements Exception {
  final String message;
  UserAlreadyExistsException(this.message);
}

class UserDoesntExistException implements Exception {
  final String message;
  UserDoesntExistException(this.message);
}

class UserMismatchException implements Exception {
  final String message;
  UserMismatchException(this.message);
}

class NoteNotPresentException implements Exception {
  final String message;
  NoteNotPresentException(this.message);
}
