import 'package:mynotebook/constants/string_constants.dart';

class SqlCommands {
  static final String createUsersTable = '''CREATE TABLE IF NOTE EXIST ${StringConstants.usersTable} (
      ${StringConstants.userId}	INTEGER NOT NULL,
      ${StringConstants.userName}	TEXT NOT NULL,
      ${StringConstants.email}	TEXT NOT NULL,
      PRIMARY KEY(${StringConstants.userId})
    );''';
  static final String createNotesTable = '''
          CREATE TABLE IF NOTE EXISTS ${StringConstants.notesTable}(
            ${StringConstants.noteId} INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            ${StringConstants.title} TEXT,
            ${StringConstants.content} TEXT,
            ${StringConstants.userId} INTEGER NOT NULL REFRENCES users(${StringConstants.userId}),
            ${StringConstants.cloudSync} INTEGER DEFAULT 0
          )
        ''';
}