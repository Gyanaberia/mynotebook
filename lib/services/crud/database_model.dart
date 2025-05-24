import 'package:flutter/cupertino.dart';
import 'package:mynotebook/constants/string_constants.dart';

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

  // @override
  // bool operator ==(covariant DatabaseUser other) {
  //   return userId == other.userId;
  // }

  // @override

  // int get hashCode => super.id;
}
