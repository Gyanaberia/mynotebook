import 'package:flutter/cupertino.dart';
import 'package:mynotebook/constants/string_constants.dart';

///Class representing a user in the database
///It contains userID, email and username

@immutable
class DatabaseUser {
  final int userId;
  final String email;
  final String username;

  const DatabaseUser(
      {required this.userId, required this.email, required this.username});

  DatabaseUser.fromMap(Map<String, Object?> map)
      : userId = map[StringConstants.userId] as int,
        email = map[StringConstants.email] as String,
        username = map[StringConstants.userName] as String;

  @override
  bool operator ==(covariant DatabaseUser other) {
    return userId == other.userId;
  }
  
  @override
  int get hashCode =>userId.hashCode;
  
}

/// A class that represents a note in the database.
/// It contains the note ID, title, content, user ID, and a flag indicating whether the note is synced with the cloud.
class DatabaseNotes{
  final int noteId;
  final String title;
  final String content;
  final int userId;
  final bool cloudSync;

  const DatabaseNotes( 
      {required this.noteId, required this.title, required this.content, required this.userId,required this.cloudSync});

  DatabaseNotes.fromMap(Map<String, Object?> map)
      : noteId = map[StringConstants.noteId] as int,
        title = map[StringConstants.title] as String,
        content = map[StringConstants.content] as String,
        userId = map[StringConstants.userId] as int,
        cloudSync = map[StringConstants.cloudSync] as int==1? true : false;

  @override
  bool operator ==(covariant DatabaseNotes other) {
    return noteId == other.noteId;
  }
  
  @override
  int get hashCode =>noteId.hashCode;
}
