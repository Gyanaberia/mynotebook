import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';

@immutable
class AuthUser {
  final bool isEmailVerifired;
  final String? email;
  const AuthUser({required this.isEmailVerifired, required this.email});

  factory AuthUser.fromFirebase(User user) =>
      AuthUser(isEmailVerifired: user.emailVerified, email: user.email);
}
