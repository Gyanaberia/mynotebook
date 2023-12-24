import 'package:mynotebook/auth/auth_provider.dart';
import 'package:mynotebook/auth/auth_user.dart';
import 'package:mynotebook/auth/firebase_auth_provider.dart';

class AuthService implements AuthProvider {
  final AuthProvider authProvider;

  AuthService({required this.authProvider});

  factory AuthService.firebase() =>
      AuthService(authProvider: FirebaseAuthProvider());

  @override
  Future<AuthUser> createUser({
    required String userId,
    required String password,
  }) =>
      authProvider.createUser(userId: userId, password: password);

  @override
  AuthUser? get currentUser => authProvider.currentUser;
  @override
  Future<AuthUser> logIn({
    required String userId,
    required String password,
  }) =>
      authProvider.logIn(userId: userId, password: password);

  @override
  Future<void> logOut() => authProvider.logOut();

  @override
  Future<void> sendEmailVerification() => authProvider.sendEmailVerification();

  @override
  Future<void> initialize() => authProvider.initialize();
}
