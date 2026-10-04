import 'dart:async';
import 'dart:developer' as devtools;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mynotebook/constants/string_constants.dart';
import 'package:mynotebook/services/auth/auth_service.dart';
import 'package:mynotebook/services/crud/cloud_sync_services.dart';
import 'package:mynotebook/services/crud/database_migrator.dart';
import 'package:mynotebook/services/crud/database_model.dart';
import 'package:mynotebook/services/crud/note_service_exceptions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class NotesServices {
  Database? _db;
  DatabaseUser? _currentUser;
  // A private list to store the notes in memory
  List<DatabaseNotes> _notes = [];
  //Store changes of notes
  late final StreamController<List<DatabaseNotes>> _notesController;
  //the changes are provided as a stream to the UI
  Stream<List<DatabaseNotes>> get allNotes => _notesController.stream;

  StreamSubscription? _remoteSub;
  //--------------------------------

  ///SINGLETON
  ///
  /// Private named constructor to create a singleton instance
  NotesServices._sharedInstance() {
    _notesController = StreamController<List<DatabaseNotes>>.broadcast(
      onListen: () => _notesController.sink.add(_notes),
    );
  }
  //instance of that constructor
  static final NotesServices _shared = NotesServices._sharedInstance();
  //singleton
  factory NotesServices() => _shared;

  //------------------------------
  //DB MANAGEMENT
  //------------------------------

  //1. DB INITIALIZATION OPERATION
  ///Opens the database if it is not already open
  Future<void> open() {
    // If the database is already open, do nothing
    if (_db != null) return Future.value(null);
    // Otherwise, initialize the database
    return _initializeDb();
  }

  /// Initializes the database by opening it and creating the necessary tables.
  /// Throws [DatabaseInitException] if the database cannot be created.
  Future<void> _initializeDb() async {
    Database? db;
    try {
      final dbPath = await getApplicationDocumentsDirectory();
      final path = join(dbPath.path, StringConstants.databaseName);
      db = await const DatabaseMigrator().openDB(path);
      _db = db;
    } on MissingPlatformDirectoryException catch (e, st) {
      await db?.close();
      _db = null;
      devtools.log('Missing platform', error: e, stackTrace: st);
      throw DatabaseInitException('Could not find the database directory:');
    } catch (e, st) {
      await db?.close();
      _db = null;
      devtools.log('Error initializing the database', error: e, stackTrace: st);
      throw DatabaseInitException('Database initialization failed');
    }
  }

  ///Ensures that DB is always open before making any DB calls
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

  /// Closes the database if it is open
  Future<void> close() async {
    final db = _db;
    if (db == null) return; // already closed — idempotent, no exception needed
    await db.close();
    _db = null;
  }

  //2. SET AND MANAGE USER FOR WHICH SUBSEQUENT DB CALL HAPPENS
  /// set the current DatabaseUser and load their notes from db to local.
  /// If the user is registered in firebase, sync their notes from remote
  Future<void> setCurrentUser(DatabaseUser user) async {
    _currentUser = user;
    await _cachedNotes();
    final uid = AuthService.firebase().currentUser?.uid;
    if (uid != null) startRemoteSync(uid);
  }

  ///Remove DatabaseUser and cancel their sync with firestore. Close the DB
  ///Useful for logout operations
  Future<void> clearCurrentUser() async {
    _remoteSub?.cancel();
    _remoteSub = null;
    _currentUser = null;
    _notes = [];
    _notesController.add(_notes);
    await close();
  }

  ///Caches all notes of user locally
  ///This prevents frequent read requests to db
  Future<void> _cachedNotes() async {
    final user = _currentUser;
    _notes = user == null ? [] : await getAllNotesOfUser(user.userId);
    _notesController.add(_notes);
  }

  //------------------------
  //USER MANAGEMENT
  //------------------------
  ///Get user if present or create new from given values
  ///
  ///Throws [DatabaseOperationException] if user can't be fetched due to DB errors
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
  ///
  /// Returns a [DatabaseUser] object representing the created user.
  ///
  /// Throws [UserAlreadyExistsException] if a user with the given email already exists.
  ///
  /// Throws [DatabaseOperationException] if DB query(insertion) fails.
  Future<DatabaseUser> createUser(
      {required String email, String? username}) async {
    await _ensureDBisOpen();
    final database = _getDb;

    try {
      final existingUsers = await database.query(StringConstants.usersTable,
          limit: 1,
          where: '${StringConstants.email}=?',
          whereArgs: [email.toLowerCase()]);

      if (existingUsers.isNotEmpty) {
        throw UserAlreadyExistsException("User already exists");
      }
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
    } on DatabaseException catch (e, st) {
      if (e.isUniqueConstraintError()) {
        throw UserAlreadyExistsException(
            "Insertion failed as User already exists");
      }
      devtools.log("DB failure at createUser", error: e, stackTrace: st);
      throw DatabaseOperationException("user creation failed");
    }
  }

  /// Retrieves a user from the database by their email.
  ///
  /// Throws [UserDoesntExistException] if the user with the given email does not exist.
  ///
  /// Throws [DatabaseOperationException] if DB query for user fails
  Future<DatabaseUser> getUser({required String email}) async {
    await _ensureDBisOpen();
    final database = _getDb;
    try {
      final user = await database.query(StringConstants.usersTable,
          where: '${StringConstants.email} = ?',
          whereArgs: [email.toLowerCase()]);
      if (user.isEmpty) {
        throw UserDoesntExistException("User does not exist");
      } else {
        return DatabaseUser.fromMap(user.first);
      }
    } on DatabaseException catch (e, st) {
      devtools.log("DB failure at getUser", error: e, stackTrace: st);
      throw DatabaseOperationException("failed to get user");
    }
  }

  /// Deletes a user from the database by their email.
  ///
  /// Throws [DatabaseOperationException] if the user deletion fails due to underlying DB operation.
  Future<void> deleteUser({required String email}) async {
    await _ensureDBisOpen();
    final database = _getDb;
    try {
      await database.delete(StringConstants.usersTable,
          where: '${StringConstants.email} = ?',
          whereArgs: [email.toLowerCase()]);
    } on DatabaseException catch (e, st) {
      devtools.log("DB failure at deleteUser", error: e, stackTrace: st);
      throw DatabaseOperationException("failed to delete user");
    }
  }

  //-------------------------
  //NOTES MANAGEMENT
  //-------------------------

  ///Creates a note for the provided user
  ///
  ///Throws [DatabaseOperationException] for DB operation(insert) failure for note creation.
  ///
  ///Throws [UserMismatchException] if owners are not in sync. Advise user to relogin
  Future<DatabaseNotes> createNote({required DatabaseUser owner}) async {
    await _ensureDBisOpen();
    final database = _getDb;

    try {
      final dbUser = await getUser(email: owner.email);
      //Make sure owner exist in the database
      if (dbUser != owner) {
        throw UserMismatchException(
            "Owner reference doesn't match database record");
      }
      int creationTime = DateTime.now().millisecondsSinceEpoch;
      String firebaseNoteId = const Uuid().v4();
      //insert the note in the database
      final noteId = await database.insert(
        StringConstants.notesTable,
        {
          StringConstants.title: "",
          StringConstants.content: "",
          StringConstants.userId: dbUser.userId,
          StringConstants.cloudSync: 0, // Default value for cloud sync
          StringConstants.firestoreNoteId: firebaseNoteId,
          StringConstants.updatedAt: creationTime,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      //Return that note to the UI
      final note = DatabaseNotes(
        noteId: noteId,
        firestoreNoteId: firebaseNoteId,
        title: "",
        content: "",
        updatedAt: creationTime,
        userId: dbUser.userId,
        cloudSync: false, // Default value for cloud sync
      );
      _notes.add(note);
      _notesController.add(_notes);
      return note;
    } on DatabaseException catch (e, st) {
      devtools.log("DB failure at createNote", error: e, stackTrace: st);
      throw DatabaseOperationException("failed to create note");
    }
  }

  ///Get Note from DB based on NoteId
  ///
  ///Throws [NoteNotPresentException] if note is not present in DB
  ///
  ///Throws [DatabaseOperationException] for DB operation(query) failure to get note.
  Future<DatabaseNotes> getNote(int noteId) async {
    await _ensureDBisOpen();
    final database = _getDb;
    try {
      final notes = await database.query(
        StringConstants.notesTable,
        where: '${StringConstants.noteId} = ?',
        whereArgs: [noteId],
      );
      if (notes.isEmpty) {
        throw NoteNotPresentException('Note does not exist');
      }

      return DatabaseNotes.fromMap(notes.first);
    } on DatabaseException catch (e, st) {
      devtools.log("DB failure at getNote", error: e, stackTrace: st);
      throw DatabaseOperationException("failed to get note");
    }
  }

  ///Returns a list of all notes of a user. The list can be empty
  ///
  ///Throws [DatabaseOperationException] for DB operation(query) failure to get note.
  Future<List<DatabaseNotes>> getAllNotesOfUser(int userId) async {
    await _ensureDBisOpen();
    final database = _getDb;

    try {
      final notes = await database.query(StringConstants.notesTable,
          where: '${StringConstants.userId} = ?', whereArgs: [userId]);

      return notes.map((note) => DatabaseNotes.fromMap(note)).toList();
    } on DatabaseException catch (e, st) {
      devtools.log("DB failure at getAllNotesOfUser", error: e, stackTrace: st);
      throw DatabaseOperationException("failed to retrieve all notes of user");
    }
  }

  ///Updates a note before returning it back.
  ///
  ///Throws [CouldntUpdateNoteException] when update fails
  ///
  ///Throws [DatabaseOperationException] if updated note retrieval fails
  Future<DatabaseNotes> updateNote({
    required int noteId,
    String? title,
    String? content,
  }) async {
    await _ensureDBisOpen();

    final database = _getDb;

    final updateData = {
      if (title != null) StringConstants.title: title,
      if (content != null) StringConstants.content: content,
      StringConstants.cloudSync: 0,
      StringConstants.updatedAt: DateTime.now().millisecondsSinceEpoch,
    };

    try {
      final updatedCount = await database.update(
        StringConstants.notesTable,
        updateData,
        where: '${StringConstants.noteId} = ?',
        whereArgs: [noteId],
      );
      if (updatedCount == 0) {
        throw CouldntUpdateNoteException("The note may not exist");
      }
    } on DatabaseException catch (e, st) {
      devtools.log("DB failure at updateNote.", error: e, stackTrace: st);
      throw CouldntUpdateNoteException("Failed to update note");
    }
    //Update has been successful
    final note = await getNote(noteId);
    _markDirtyAndSync(note, delete: false);
    _notes.removeWhere((n) => n.noteId == noteId);
    _notes.add(note);
    _notesController.add(_notes);
    return note;
  }

  ///Deletes the note
  ///
  ///Throws [DatabaseOperationException] if DB operation(delete) for note in notesTable failed.
  Future<void> deleteNote(DatabaseNotes note) async {
    await _ensureDBisOpen();
    final database = _getDb;
    try {
      int deleteCount = await database.delete(
        StringConstants.notesTable,
        where: '${StringConstants.noteId} = ?',
        whereArgs: [note.noteId],
      );
      if (deleteCount == 0) {
        //Changed from throw NoteNotPresentException, since if the note is not present, nothing to delete. UI doesn't need to do anything
        devtools
            .log('delete Failed. Note with ID ${note.noteId} does not exist');
      }
      _markDirtyAndSync(note, delete: true);
      _notes.removeWhere((n) => n.noteId == note.noteId);
      _notesController.add(_notes);
    } on DatabaseException catch (e, st) {
      devtools.log("DB failure at deleteNote", error: e, stackTrace: st);
      throw DatabaseOperationException("failed to delete note");
    }
  }

  ///Deletes a list of notes
  ///
  ///Throws [DatabaseOperationException] if DB operation(delete) failed.
  Future<int> deleteNotesInBatch(List<int> noteIds) async {
    await _ensureDBisOpen();
    final database = _getDb;
    if (noteIds.isEmpty) return 0;

    final placeholders = List.filled(noteIds.length, '?').join(',');
    try {
      final List<Map<String, dynamic>> notesData = await database.query(
          StringConstants.notesTable,
          where: '${StringConstants.noteId} IN ($placeholders)',
          whereArgs: noteIds);

      final deleteCount = await database.delete(
        StringConstants.notesTable,
        where: '${StringConstants.noteId} IN ($placeholders)',
        whereArgs: noteIds,
      );
      List<DatabaseNotes> notes = [
        for (var n in notesData) DatabaseNotes.fromMap(n)
      ];
      for (var n in notes) {
        _markDirtyAndSync(n, delete: true);
      }
      _notes.removeWhere((n) => noteIds.contains(n.noteId));
      _notesController.add(_notes); // one emission for the whole batch
      return deleteCount;
    } on DatabaseException catch (e, st) {
      devtools.log("DB failure at deleteNotesInBatch",
          error: e, stackTrace: st);
      throw DatabaseOperationException("failed to delete notes");
    }
  }

  ///Delete all notes of user
  ///
  ///Throws [DatabaseOperationException] when delete operation fails
  Future<int> deleteAllNotesOfUser(int userId) async {
    await _ensureDBisOpen();

    final database = _getDb;
    try {
      List<DatabaseNotes> notes = await getAllNotesOfUser(userId);

      final deleteCount = await database.delete(
        StringConstants.notesTable,
        where: '${StringConstants.userId} = ?',
        whereArgs: [userId],
      );

      for (var n in notes) {
        _markDirtyAndSync(n, delete: true);
      }
      //Intead of filtering by user Ids, completely remove the _notes, since _notes contains notes of current user anyway
      _notes = [];
      _notesController.add(_notes);
      return deleteCount;
    } on DatabaseException catch (e, st) {
      devtools.log("DB failure at deleteAllNotesOfUser",
          error: e, stackTrace: st);
      throw DatabaseOperationException("failed to delete all notes of user");
    }
  }

  //---------------------------------
  //CLOUD FIRESTORE SYNC OPERATIONS
  //---------------------------------

  /// Syncs local updates with cloud firestore
  /// Mark delete=true if the note is being deleted and synced as such
  Future<void> _markDirtyAndSync(DatabaseNotes note,
      {bool delete = false}) async {
    // cloudSync = 0 already set by default on write; fire sync without blocking the caller
    unawaited(
      _syncOne(note, delete: delete).catchError((e, st) {
        // already logged inside _syncOne (and inside CloudSyncService) before it got here —
        // this catchError exists purely so the fire-and-forget Future never goes unhandled
      }),
    );
  }

  ///Syncs a note with cloud. If delete is true, deletes the note from cloud
  ///
  ///throws [CloudSyncException] for any firestore errors
  Future<void> _syncOne(DatabaseNotes note, {bool delete = false}) async {
    try {
      final uid = AuthService.firebase().currentUser?.uid;
      if (uid == null) return;
      if (delete) {
        await CloudSyncService()
            .deleteNote(uid: uid, firestoreNoteId: note.firestoreNoteId);
      } else {
        await CloudSyncService().pushNote(
            uid: uid,
            firestoreNoteId: note.firestoreNoteId,
            title: note.title,
            content: note.content);
      }

      await _ensureDBisOpen();

      final database = _getDb;
      if (!delete) {
        await database.update(
          StringConstants.notesTable,
          {StringConstants.cloudSync: 1},
          where: '${StringConstants.noteId} = ?',
          whereArgs: [note.noteId],
        );
      }
      //this needs to reach the syncAllNotes method
    } on CloudSyncException {
      rethrow;
    } catch (e, st) {
      devtools.log("sync failed, will retry later", error: e, stackTrace: st);
    }
  }

  ///Syncs all notes of the user
  ///
  ///throws [CloudSyncException] for any firestore errors for sync
  Future<bool> syncAllNotes() async {
    bool syncSucceeded = true;
    for (final note in _notes) {
      if (!note.cloudSync) {
        try {
          await _syncOne(note);
        } on CloudSyncException catch (e) {
          syncSucceeded = false;
          devtools.log(
              "syncAllNotes: skipping note ${note.noteId}, will retry next pass: $e");
        }
      }
    }
    return syncSucceeded;
  }

  ///Sets a subscriber to the remote stream to listen to any cloud DB changes
  void startRemoteSync(String uid) {
    _remoteSub?.cancel();
    _remoteSub = CloudSyncService().watchNotes(uid).listen(
      (snapshot) async {
        for (final change in snapshot.docChanges) {
          //If the change is firestore is from own device, don't loop the changes back from firestore to local
          if (change.doc.metadata.hasPendingWrites) continue;
          final data = change.doc.data();
          //If the content isn't different, don't sync remote to cloud
          if (data == null) continue;
          final firestoreNoteId = change.doc.id;

          try {
            switch (change.type) {
              case DocumentChangeType.added:
              case DocumentChangeType.modified:
                await _mergeRemoteNote(firestoreNoteId, data);
                break;
              case DocumentChangeType.removed:
                await _deleteLocalByFirestoreNoteId(firestoreNoteId);
                break;
            }
          } catch (e, st) {
            // catch-all here, not just DatabaseOperationException
            devtools.log("processing remote change failed",
                error: e, stackTrace: st);
          }
        }
      },
      onError: (e, st) =>
          devtools.log("remote sync stream error", error: e, stackTrace: st),
    );
  }

  ///Merges remote notes to local DB. If note not present in local, create it, else update it
  ///
  ///Throws [DatabaseOperationException] if any operation fails
  Future<void> _mergeRemoteNote(
      String firestoreNoteId, Map<String, dynamic> data) async {
    await _ensureDBisOpen();
    Database database = _getDb;
    try {
      final existing = await _findByFirestoreNoteId(firestoreNoteId);

      final remoteTitle = data['title'] as String? ?? '';
      final remoteContent = data['content'] as String? ?? '';

      if (existing != null &&
          existing.title == remoteTitle &&
          existing.content == remoteContent) {
        return; // nothing actually changed — don't re-write, don't re-trigger a push
      }
      final remoteUpdatedAt = (data['updatedAt'] as Timestamp?)?.toDate();

      var row = {
        StringConstants.title: data['title'],
        StringConstants.content: data['content'],
        StringConstants.userId: _currentUser!.userId,
        StringConstants.firestoreNoteId: firestoreNoteId,
        StringConstants.updatedAt: remoteUpdatedAt?.millisecondsSinceEpoch ?? 0,
        StringConstants.cloudSync: 1,
      };

      if (existing == null) {
        // new note from another device — insert locally
        await database.insert(StringConstants.notesTable, row);
      } else if (remoteUpdatedAt != null &&
          remoteUpdatedAt.isAfter(
              DateTime.fromMillisecondsSinceEpoch(existing.updatedAt))) {
        // remote is newer — overwrite local
        //Calling this method instead of updateNote, because updateNote contains _markDirty call,
        //which syncs the local changes back to cloud. Since we are syncing cloud changes to local, the extra remote call is not needed
        await _applyRemoteUpdatetoLocalDB(existing, row);
      }
      // else: local is newer or equal — do nothing, local will push its version up
      await _cachedNotes(); // refresh stream after merge
    } on DatabaseException catch (e, st) {
      devtools.log("DB failure at _mergeRemoteNote", error: e, stackTrace: st);
      throw DatabaseOperationException("failed to merge remote note");
    }
  }

  ///Updates local DB's existingNote with new changes from remote. Changes are passed as a map
  ///
  ///Throws [DatabaseOperationException] if the action fails
  Future<void> _applyRemoteUpdatetoLocalDB(
      DatabaseNotes existingNote, Map<String, dynamic> row) async {
    await _ensureDBisOpen();
    Database database = _getDb;
    try {
      await database.update(
        StringConstants.notesTable,
        row,
        where: '${StringConstants.noteId} = ?',
        whereArgs: [existingNote.noteId],
      );
    } on DatabaseException catch (e, st) {
      devtools.log("DB failure at _applyRemoteUpdatetoLocalDB",
          error: e, stackTrace: st);
      throw DatabaseOperationException("failed to apply remote update");
    }

    final note = await getNote(existingNote.noteId);
    _notes.removeWhere((n) => n.noteId == existingNote.noteId);
    _notes.add(note);
    _notesController.add(_notes);
  }

  ///Returns a note based on firestoreNoteId
  ///
  ///Throws [DatabaseOperationException] if Database Operation(query) fails
  Future<DatabaseNotes?> _findByFirestoreNoteId(String firestoreNoteId) async {
    await _ensureDBisOpen();
    final database = _getDb;

    try {
      final notes = await database.query(
        StringConstants.notesTable,
        where: '${StringConstants.firestoreNoteId} = ?',
        whereArgs: [firestoreNoteId],
      );

      if (notes.isEmpty) {
        return Future.value(null);
      }

      return DatabaseNotes.fromMap(notes.first);
    } on DatabaseException catch (e, st) {
      devtools.log("DB failure at _findByFirestoreNoteId",
          error: e, stackTrace: st);
      throw DatabaseOperationException("failed to query note");
    }
  }

  ///Deletes a note based on firestoreNoteId
  ///
  ///Throws [DatabaseOperationException] if the Database Operation(delete) fails
  Future<void> _deleteLocalByFirestoreNoteId(String firestoreNoteId) async {
    await _ensureDBisOpen();
    final database = _getDb;
    try {
      int deleteCount = await database.delete(
        StringConstants.notesTable,
        where: '${StringConstants.firestoreNoteId} = ?',
        whereArgs: [firestoreNoteId],
      );
      if (deleteCount == 0) return;
      _notes.removeWhere((note) => note.firestoreNoteId == firestoreNoteId);
      _notesController.add(_notes);
    } on DatabaseException catch (e, st) {
      devtools.log("DB failure at _deleteLocalByFirestoreNoteId",
          error: e, stackTrace: st);
      throw DatabaseOperationException("failed to delete local note");
    }
  }
}
