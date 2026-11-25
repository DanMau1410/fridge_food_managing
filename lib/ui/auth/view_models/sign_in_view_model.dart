import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth_repository.dart';

/// Email and Google sign-in, sign-up and password reset. On success the session moves on, and this view
/// model is disposed with its screen.
class SignInViewModel extends ChangeNotifier {
  SignInViewModel(this._auth);

  final AuthRepository _auth;
  bool _disposed = false;

  bool get signUp => _signUp;
  bool _signUp = false;

  bool get busy => _busy;
  bool _busy = false;

  /// The last attempt's failure, cleared by the next attempt or a mode switch.
  AuthFailure? get failure => _failure;
  AuthFailure? _failure;

  void toggleMode() {
    _signUp = !_signUp;
    _failure = null;
    notifyListeners();
  }

  Future<void> submit({
    required String email,
    required String password,
    String? displayName,
  }) => _run(
    () => _signUp
        ? _auth.signUpWithEmail(email, password, displayName: displayName)
        : _auth.signInWithEmail(email, password),
  );

  Future<void> signInWithGoogle() => _run(_auth.signInWithGoogle);

  /// Null once sent; an unknown email is "sent" too, so both get the same
  /// confirmation (AC-ID-8).
  Future<AuthFailure?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordReset(email);
      return null;
    } on AuthException catch (e) {
      return e.failure;
    } catch (e) {
      debugPrint('Password reset failed: ${e.runtimeType}');
      return AuthFailure.unknown;
    }
  }

  Future<void> _run(Future<void> Function() call) async {
    if (_busy) return;
    _busy = true;
    _failure = null;
    notifyListeners();
    try {
      await call();
    } on AuthException catch (e) {
      // Closing the Google popup is a choice, not an error.
      if (e.failure != AuthFailure.cancelled) _failure = e.failure;
    } catch (e) {
      debugPrint('Sign-in failed: ${e.runtimeType}');
      _failure = AuthFailure.unknown;
    } finally {
      _busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
