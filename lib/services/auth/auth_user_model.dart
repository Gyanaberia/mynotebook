import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';

@immutable
class AuthUser {
  final String uid;
  final bool isEmailVerifired;
  final String? email;
  final String? username;
  const AuthUser({required this.uid, required this.isEmailVerifired, required this.email,this.username, });

  factory AuthUser.fromFirebase(User user) =>
      AuthUser(uid:user.uid, isEmailVerifired: user.emailVerified, email: user.email,username:user.displayName);
}
