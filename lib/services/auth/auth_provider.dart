import 'package:mynotebook/services/auth/auth_user_model.dart';

abstract class UserAuthProvider {
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
