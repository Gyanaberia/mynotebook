import 'dart:async';

import 'package:mynotebook/constants/sql_commands.dart';
import 'package:mynotebook/constants/string_constants.dart';
import 'package:mynotebook/services/crud/database_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart'show join;
import 'package:sqflite/sqflite.dart';

class NotesServices {
  Database? _db;
  List<DatabaseNotes>_notes = [];
  final StreamController _notesController = StreamController<List<DatabaseNotes>>.broadcast();


  Future<void>_cachedNotes()async{
    _notes = await getAllNotes();
    _notesController.add(_notes);
  }
  ///Opens the sdatabase if it is not already open, otherwise throws an exception
  Future<void>open(){
    // If the database is already open, throw an exception
    if(_db!=null) throw DatabaseAlreadyOpenException();
    // Otherwise, initialize the database
    return _initializeDb();
  }

  Future<void> _ensureDBisOpen()async{
    try{
      await open();
    } on DatabaseAlreadyOpenException{
      //empty
    }
  }
  ///Getter to access the database instance
  Database get db{
    if (_db != null) {
      return _db!;
    } else {
      throw DatabaseNotOpenException();
    }
  }

  /// Initializes the database by opening it and creating the necessary tables.
  /// Throws [MissingPlatformDirectoryException] if the platform directory is not found.
  /// Throws [DatabaseNotCreatedException] if the database cannot be created.
  Future<Database> _initializeDb() async {
    try{
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, StringConstants.databaseName);
    Database db = await openDatabase(path);

    // Create the NOTES table if it doesn't exist
    await db.execute(SqlCommands.createNotesTable);

    // Create the users table if it doesn't exist
    await db.execute(SqlCommands.createUsersTable);
    await _cachedNotes();
    return db;
    } on MissingPlatformDirectoryException catch (e) {
      throw Exception('Could not find the database directory: $e');
    } catch (e) {
      throw Exception('Error initializing the database: $e');
    }
    
  }

  /// Closes the database if it is open, otherwise throws an exception
  /// Throws [DatabaseNotOpenException] if the database is not open.
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    } else{ 
      throw DatabaseNotOpenException();
    }

  }
  
  ///Creates a note for the provided user
  Future<DatabaseNotes>createNote({required String title,required String content,required int userId})async {
    _ensureDBisOpen();
    final database = db;
    //insert the note in the database
    final noteId =await  database.insert(StringConstants.notesTable, {
      StringConstants.title: title,
      StringConstants.content: content,
      StringConstants.userId: userId,
      StringConstants.cloudSync: 0, // Default value for cloud sync
    }, conflictAlgorithm: ConflictAlgorithm.replace,);

    final note =  DatabaseNotes(
      noteId: noteId,
      title: title,
      content: content,
      userId: userId,
      cloudSync: false, // Default value for cloud sync
    );
    _notes.add(note);
    _notesController.add(_notes);
    return note;
  }


  Future<void> deleteNote(int noteId) async {
        _ensureDBisOpen();
    final database = db;
    final notePresent = await database.query(
      StringConstants.notesTable,
      where: '${StringConstants.noteId} = ?',
      whereArgs: [noteId],
    );
    if (notePresent.isEmpty) {
      throw NoteNotPresentException('Note with ID $noteId does not exist');
    }
    await database.delete(
      StringConstants.notesTable,
      where: '${StringConstants.noteId} = ?',
      whereArgs: [noteId],
    );
    _notes.removeWhere((note)=>note.noteId==noteId);
    _notesController.add(_notes);
  }

  Future<int>deleteAllNotesOfUser(int userId)async{
        _ensureDBisOpen();

    final database = db;
    // final notes = await database.query(StringConstants.notesTable, where: '${StringConstants.userId} = ?', whereArgs: [userId]);

    final deleteCount= await database.delete(
      StringConstants.notesTable,
      where: '${StringConstants.userId} = ?',
      whereArgs: [userId],
    );
    _notes = [];
    _notesController.add(_notes);
    return deleteCount;
  }

  Future<DatabaseNotes>getNote(int noteId)async {
        _ensureDBisOpen();

    final database = db;
    final notes = await database.query(
      StringConstants.notesTable,
      where: '${StringConstants.noteId} = ?',
      whereArgs: [noteId],
    );

    if (notes.isEmpty) {
      throw NoteNotPresentException('Note with ID $noteId does not exist');
    }
    
    final note = DatabaseNotes.fromMap(notes.first);
    _notes.removeWhere((note)=>note.noteId == noteId);
    _notesController.add(_notes);
    return note;
  }

  Future<List<DatabaseNotes>> getAllNotesOfUser(int userId) async {
        _ensureDBisOpen();

    final database = db;
    final notes = await database.query(StringConstants.notesTable,where: '${StringConstants.userId} = ?', whereArgs: [userId]);
    if (notes.isEmpty) {
      throw NoteNotPresentException('No notes found for user with ID $userId');
    }
    return notes.map((note)=>DatabaseNotes.fromMap(note)).toList();
  }

  ///Returns all notes in the database
  Future<List<DatabaseNotes>>getAllNotes()async{
        _ensureDBisOpen();

    final database = db;
    final notes = await database.query(StringConstants.notesTable);
        if (notes.isEmpty) {
      throw NoteNotPresentException('No notes found in the database');
    }
    return notes.map((note)=>DatabaseNotes.fromMap(note)).toList();
  }

  Future<DatabaseNotes> updateNote({required int noteId,String?title,String? content,String? cloudSync}) async {
        _ensureDBisOpen();

    final database = db;
await getNote(noteId);
    final updateData ={
      if (title != null) StringConstants.title: title,
      if (content != null) StringConstants.content: content,
      if (cloudSync != null) StringConstants.cloudSync: cloudSync == 'true' ? 1 : 0,
    };
    final updatedCount =await database.update(
      StringConstants.notesTable,
      updateData,
      where: '${StringConstants.noteId} = ?',
      whereArgs: [noteId],
    );
    if(updatedCount == 0){
      throw CouldntUpdateNoteException();
    }
    final note = await getNote(noteId);
    _notes.removeWhere((note)=>note.noteId==noteId);
    _notes.add(note);
    _notesController.add(_notes);
    return note;
  }


  /// Creates a new user in the database with the given email and username.
  /// Throws [UserAlreadyExistsException] if a user with the given email already exists.
  /// Returns a [DatabaseUser] object representing the created user.
  Future<DatabaseUser>createUser({
    required String email,
    required String username,
  }) async {
        _ensureDBisOpen();

    final database = db;
    final existingUsers = await database.query(StringConstants.usersTable,limit: 1, where: '${StringConstants.email}=?',whereArgs: [email.toLowerCase()]);
    if(existingUsers.isNotEmpty){
      throw UserAlreadyExistsException("User with email $email already exists");
    }
    
    final userId = await database.insert(
      StringConstants.usersTable,
      {
        StringConstants.email: email.toLowerCase(),
        StringConstants.userName: username,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return DatabaseUser(userId: userId, email: email.toLowerCase(), username: username);
  }

  /// Retrieves a user from the database by their email.
  /// Throws [UserDoesntExistException] if the user with the given email does not exist.
  Future<DatabaseUser>fetchUser({required String email}) async{
        _ensureDBisOpen();

    final database = db;
    final user =await database.query(StringConstants.usersTable, where: '${StringConstants.email} = ?', whereArgs: [email.toLowerCase()]);
    if(user.isEmpty){
      throw UserDoesntExistException("User with email $email does not exist");
    }else{
      return DatabaseUser.fromMap(user.first);
    }
  }

  Future<DatabaseUser>getOrCreateUser({required String email,required String username})async{
        _ensureDBisOpen();

    DatabaseUser user;
    try {
          user = await fetchUser(email: email);
    } on UserDoesntExistException {user = await createUser(email: email, username: username);} catch(e){
      rethrow;
    }
    return user;
  }

  /// Retrieves a user from the database by their email.
  /// Throws [CouldntDeleteUserException] if the user with the given email does not exist.
  Future<void> deleteUser({required String email})async{
        _ensureDBisOpen();

    final database = db;
    final deletedUser = await database.delete(StringConstants.usersTable, where: '${StringConstants.email} = ?', whereArgs: [email.toLowerCase()]);
    if(deletedUser != 1){
      throw CouldntDeleteUserException("Could not delete user with email $email");}
  } 
}

class CouldntUpdateNoteException {
}

class DatabaseAlreadyOpenException implements Exception{}
class DatabaseNotOpenException implements Exception{}
class DatabaseNotCreatedException implements Exception{
  final String message;
  DatabaseNotCreatedException(this.message);
}
class CouldntDeleteUserException implements Exception{
  final String message;
  CouldntDeleteUserException(this.message);
}

class UserAlreadyExistsException implements Exception{
  final String message;
  UserAlreadyExistsException(this.message);
}
class UserDoesntExistException implements Exception{
  final String message;
  UserDoesntExistException(this.message);
}

class NoteNotPresentException implements Exception {
  final String message;
  NoteNotPresentException(this.message);
}