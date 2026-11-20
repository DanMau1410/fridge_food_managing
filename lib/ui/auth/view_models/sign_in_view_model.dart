import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth_repository.dart';

/// Email sign-in and sign-up. On success the session moves on, and this view
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
  }) async {
    if (_busy) return;
    _busy = true;
    _failure = null;
    notifyListeners();
    try {
      if (_signUp) {
        await _auth.signUpWithEmail(email, password, displayName: displayName);
      } else {
        await _auth.signInWithEmail(email, password);
      }
    } on AuthException catch (e) {
      _failure = e.failure;
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
