import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../domain/models/user_profile.dart';

/// Firebase's default minimum; the app checks it at sign-up.
const minPasswordLength = 6;

/// What went wrong, as far as the user is told. Never the raw Firebase code.
enum AuthFailure {
  invalidCredentials,
  emailInUse,
  weakPassword,
  invalidEmail,
  tooManyRequests,
  network,
  accountExists,
  cancelled,
  unknown,
}

class AuthException implements Exception {
  const AuthException(this.failure);

  final AuthFailure failure;

  @override
  String toString() => 'AuthException(${failure.name})';
}

/// Maps a Firebase Auth error code. A wrong password and an unknown email give
/// the same failure, so sign-in never reveals whether an account exists.
AuthFailure failureFor(String code) => switch (code) {
  'invalid-credential' ||
  'invalid-login-credentials' ||
  'wrong-password' ||
  'user-not-found' => AuthFailure.invalidCredentials,
  'email-already-in-use' => AuthFailure.emailInUse,
  'weak-password' => AuthFailure.weakPassword,
  'invalid-email' => AuthFailure.invalidEmail,
  'too-many-requests' => AuthFailure.tooManyRequests,
  'network-request-failed' => AuthFailure.network,
  'account-exists-with-different-credential' => AuthFailure.accountExists,
  'popup-closed-by-user' ||
  'cancelled-popup-request' ||
  'web-context-canceled' ||
  'web-context-cancelled' => AuthFailure.cancelled,
  _ => AuthFailure.unknown,
};

/// Sign-up, sign-in and sign-out through Firebase Auth.
class AuthRepository {
  AuthRepository(this._auth);

  final FirebaseAuth _auth;

  /// The signed-in account, or null. Also emits when its profile changes,
  /// such as the display name set right after sign-up.
  Stream<AppUser?> watchAuthUser() => _auth.userChanges().map(
    (user) => user == null
        ? null
        : AppUser(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName,
          ),
  );

  Future<void> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
  }) => _guard(() async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final name = displayName?.trim() ?? '';
    if (name.isNotEmpty) await credential.user?.updateDisplayName(name);
  });

  Future<void> signInWithEmail(String email, String password) => _guard(
    () => _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    ),
  );

  Future<void> signOut() => _auth.signOut();

  /// Rethrows Firebase errors as [AuthException], logging only the code.
  Future<void> _guard(Future<void> Function() call) async {
    try {
      await call();
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth failed: ${e.code}');
      throw AuthException(failureFor(e.code));
    }
  }
}
