import 'package:firebase_auth/firebase_auth.dart';
import 'package:mynotebook/auth/auth_exceptions.dart';
import 'package:mynotebook/auth/auth_provider.dart';
import 'package:mynotebook/auth/auth_user.dart';

class FirebaseAuthProvider implements AuthProvider {
  @override
  Future<AuthUser> createUser(
      {required String userId, required String password}) async {
    try {
      FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: userId, password: password);
      final user = currentUser;
      if (user != null) {
        return user;
      } else {
        throw UserNotLoggedInAuthException();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == "weak-password") {
        throw WeakPasswordAuthException();
      } else if (e.code == "invalid-email") {
        throw InvalidEmailAuthException();
      } else if (e.code == "email-already-in-use") {
        throw EmailAlreadyInUseAuthEXception();
      } else {
        throw GeneralAuthException();
      }
    } catch (_) {
      throw GeneralAuthException();
    }
  }

  @override
  AuthUser? get currentUser {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return AuthUser.fromFirebase(user);
    } else {
      return null;
    }
  }

  @override
  Future<AuthUser> logIn(
      {required String userId, required String password}) async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: userId, password: password);
      final user = currentUser;
      if (user != null) {
        return user;
      } else {
        throw UserNotLoggedInAuthException();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == "invalid-email") {
        throw InvalidEmailAuthException();
      } else if (e.code == "wrong-password") {
        throw WrongPasswordAuthEXception();
      } else if (e.code == "user-not-found") {
        throw UserNotFoundAuthException();
      } else {
        throw GeneralAuthException();
      }
    } catch (_) {
      throw GeneralAuthException();
    }
  }

  @override
  Future<void> logOut() async {
    final user = currentUser;
    if (user != null) {
      await FirebaseAuth.instance.signOut();
    } else {
      throw UserNotLoggedInAuthException();
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
    } else {
      throw UserNotLoggedInAuthException();
    }
  }
}
