import 'package:mynotebook/constants/string_constants.dart';

class SqlCommands {
  static final String createUsersTable =
      '''CREATE TABLE IF NOT EXISTS ${StringConstants.usersTable} (
      ${StringConstants.userId}	INTEGER NOT NULL ,
      ${StringConstants.userName}	TEXT NOT NULL,
      ${StringConstants.email}	TEXT NOT NULL UNIQUE,
      PRIMARY KEY(${StringConstants.userId})
    );''';
    
  static final String createNotesTable = '''
          CREATE TABLE IF NOT EXISTS ${StringConstants.notesTable}(
            ${StringConstants.noteId} INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            ${StringConstants.title} TEXT,
            ${StringConstants.content} TEXT,
            ${StringConstants.userId} INTEGER NOT NULL REFERENCES users(${StringConstants.userId}) ON DELETE CASCADE,
            ${StringConstants.cloudSync} INTEGER NOT NULL DEFAULT 0
          )
        ''';
}
