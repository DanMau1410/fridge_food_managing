import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../data/repositories/user_repository.dart';
import '../../../domain/models/user_profile.dart';
import '../../../domain/username.dart';

enum ClaimFailure { taken, network, other }

/// Claims [user]'s username (AC-ID-4, 5, 6). On success the session moves on,
/// and this view model is disposed with its screen.
class ChooseUsernameViewModel extends ChangeNotifier {
  ChooseUsernameViewModel(this._users, this.user);

  final UserRepository _users;
  final AppUser user;
  bool _disposed = false;

  bool get busy => _busy;
  bool _busy = false;

  ClaimFailure? get failure => _failure;
  ClaimFailure? _failure;

  /// Claims [username], with [displayName] falling back to it. Input that
  /// fails [parseUsername] or [parseDisplayName] never reaches Firestore; the
  /// form shows why.
  Future<void> claim(String username, String displayName) async {
    final name = parseUsername(username);
    final display = name == null ? null : parseDisplayName(displayName, name);
    if (name == null || display == null || _busy) return;
    _busy = true;
    _failure = null;
    notifyListeners();
    try {
      await _users.claimUsername(user.uid, name, display);
    } on UsernameTaken {
      _failure = ClaimFailure.taken;
    } on FirebaseException catch (e) {
      debugPrint('Claim failed: ${e.code}');
      _failure = e.code == 'unavailable'
          ? ClaimFailure.network
          : ClaimFailure.other;
    } catch (e) {
      debugPrint('Claim failed: ${e.runtimeType}');
      _failure = ClaimFailure.other;
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
