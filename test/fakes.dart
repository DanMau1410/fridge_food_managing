import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

/// A [MockFirebaseAuth] whose sign-up, sign-in (email and Google) and
/// password reset fail with [code].
class ThrowingAuth extends MockFirebaseAuth {
  ThrowingAuth(this.code);

  final String code;

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async => throw FirebaseAuthException(code: code);

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async => throw FirebaseAuthException(code: code);

  @override
  Future<UserCredential> signInWithProvider(AuthProvider provider) async =>
      throw FirebaseAuthException(code: code);

  @override
  Future<UserCredential> signInWithPopup(AuthProvider provider) async =>
      throw FirebaseAuthException(code: code);

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async => throw FirebaseAuthException(code: code);
}
