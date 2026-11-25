import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../domain/models/user_profile.dart';
import '../../../domain/username.dart';

enum SessionStatus { loading, signedOut, needsUsername, ready, error }

/// Who is signed in and whether they have a username yet; drives the gate.
class SessionViewModel extends ChangeNotifier {
  SessionViewModel(this._auth, this._users) {
    _authSub = _auth.watchAuthUser().listen(_onUser, onError: _onError);
  }

  final AuthRepository _auth;
  final UserRepository _users;
  late final StreamSubscription<AppUser?> _authSub;
  StreamSubscription<UserProfile?>? _profileSub;

  bool _authKnown = false;
  bool _profileKnown = false;
  bool _error = false;

  /// The signed-in account; set from [SessionStatus.needsUsername] on.
  AppUser? get user => _user;
  AppUser? _user;

  /// The claimed profile; set when [SessionStatus.ready].
  UserProfile? get profile => _profile;
  UserProfile? _profile;

  SessionStatus get status {
    if (_error) return SessionStatus.error;
    if (!_authKnown) return SessionStatus.loading;
    if (_user == null) return SessionStatus.signedOut;
    if (!_profileKnown) return SessionStatus.loading;
    return _profile == null ? SessionStatus.needsUsername : SessionStatus.ready;
  }

  Future<void> signOut() => _auth.signOut();

  /// Saves [input] as the display name, blank meaning the username; input
  /// that fails [parseDisplayName] is ignored. Firestore applies the write
  /// locally first, so [profile] updates at once, offline too; callers
  /// needn't wait for the server.
  Future<void> updateDisplayName(String input) async {
    final profile = _profile;
    if (profile == null) return;
    final name = parseDisplayName(input, profile.username);
    if (name == null) return;
    try {
      await _users.updateDisplayName(profile.uid, name);
    } catch (e) {
      debugPrint('Display name update failed: ${e.runtimeType}');
    }
  }

  void _onUser(AppUser? user) {
    final uidChanged = user?.uid != _user?.uid;
    _authKnown = true;
    _user = user;
    // A profile change (e.g. the display name set after sign-up) keeps the
    // subscription; only another account starts a new one.
    if (uidChanged) {
      _profileSub?.cancel();
      _profileSub = null;
      _profile = null;
      _profileKnown = false;
      _error = false;
      if (user != null) {
        _profileSub = _users
            .watchProfile(user.uid)
            .listen(_onProfile, onError: _onError);
      }
    }
    notifyListeners();
  }

  void _onProfile(UserProfile? profile) {
    _profile = profile;
    _profileKnown = true;
    notifyListeners();
  }

  void _onError(Object error) {
    debugPrint('Session failed: ${error.runtimeType}');
    _error = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
