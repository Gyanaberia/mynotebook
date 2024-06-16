import 'package:flutter_test/flutter_test.dart';
import 'package:mynotebook/auth/auth_exceptions.dart';
import 'package:mynotebook/auth/auth_provider.dart';
import 'package:mynotebook/auth/auth_user.dart';

void main() {
  group("Testing Auth Provider", () {
    var provider = MockAuthProvider();
    test("Before Initialization", () {
      expect(provider.isInitialized, false);
    });

    test(
      "Login before Initialization",
      () => expect(provider.logIn(userId: "abcd", password: "asdv"),
          throwsA(const TypeMatcher<NotInitializedException>())),
    );

    test(
      "Initilization",
      () async {
        await provider.initialize();
        expect(provider.isInitialized, true);
      },
    );

    test('User should be null after initialization', () {
      expect(provider.currentUser, null);
    });

    test("Initilization with timeout test", () async {
      await provider.initialize();
      expect(provider.isInitialized, true);
    }, timeout: const Timeout(Duration(seconds: 2)));
  });
}

class NotInitializedException implements Exception {}

class MockAuthProvider implements AuthProvider {
  bool _isInitialized = false;
  AuthUser? _user;
  bool get isInitialized => _isInitialized;
  @override
  Future<AuthUser> createUser(
      {required String userId, required String password}) async {
    if (!isInitialized) throw NotInitializedException();
    await Future.delayed(const Duration(seconds: 1));
    return logIn(userId: userId, password: password);
  }

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<void> initialize() async {
    await Future.delayed(const Duration(seconds: 1));
    _isInitialized = true;
  }

  @override
  Future<AuthUser> logIn({required String userId, required String password}) {
    if (!isInitialized) throw NotInitializedException();
    if (userId == 'ssahu72731@gmail.com') throw UserNotFoundAuthException();
    if (password == '12345678') throw WrongPasswordAuthEXception();
    var user = AuthUser(isEmailVerifired: false, email: userId);
    _user = user;

    return Future.value(_user);
  }

  @override
  Future<void> logOut() async {
    if (!isInitialized) throw NotInitializedException();
    if (_user == null) throw UserNotFoundAuthException();
    await Future.delayed(const Duration(seconds: 1));
    _user = null;
  }

  @override
  Future<void> sendEmailVerification() async {
    if (!isInitialized) throw NotInitializedException();
    if (_user == null) throw UserNotFoundAuthException();
    _user = AuthUser(isEmailVerifired: true, email: _user?.email);
    await Future.delayed(const Duration(seconds: 1));
  }
}
