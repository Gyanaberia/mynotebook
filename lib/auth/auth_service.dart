import 'package:mynotebook/auth/auth_provider.dart';
import 'package:mynotebook/auth/auth_user.dart';

class AuthService implements AuthProvider {
  final AuthProvider authProvider;

  AuthService({required this.authProvider});

  @override
  Future<AuthUser> createUser({
    required String userId,
    required String password,
  }) {
    return authProvider.createUser(userId: userId, password: password);
  }

  @override
  AuthUser? get currentUser => authProvider.currentUser;
  @override
  Future<AuthUser> logIn({
    required String userId,
    required String password,
  }) {
    return authProvider.logIn(userId: userId, password: password);
  }

  @override
  Future<void> logOut() {
    return authProvider.logOut();
  }

  @override
  Future<void> sendEmailVerification() {
    return authProvider.sendEmailVerification();
  }
}
