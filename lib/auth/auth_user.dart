import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';

@immutable
class AuthUser {
  final bool isEmailVerifired;

  const AuthUser({required this.isEmailVerifired});

  factory AuthUser.fromFirebase(User user) =>
      AuthUser(isEmailVerifired: user.emailVerified);
}
