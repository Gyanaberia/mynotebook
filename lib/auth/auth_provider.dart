import 'package:mynotebook/auth/auth_user.dart';

abstract class AuthProvider {
  AuthUser? get currentUser;

  Future<void> initialize();
  Future<AuthUser> logIn({
    required String userId,
    required String password,
  });

  Future<void> logOut();

  Future<AuthUser> createUser({
    required String userId,
    required String password,
  });

  Future<void> sendEmailVerification();
}
