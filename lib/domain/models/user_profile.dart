import '../username.dart';

/// The signed-in Firebase Auth account, with or without a username yet.
class AppUser {
  const AppUser({required this.uid, this.email, this.displayName});

  final String uid;
  final String? email;

  /// From Google or the sign-up form; prefills Choose-username.
  final String? displayName;
}

/// A user's profile (`users/{uid}`). It exists once a username is claimed.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.username,
    required this.displayName,
    this.householdId,
  });

  final String uid;
  final String username;
  final String displayName;

  /// Written by `households`; null until the user joins one.
  final String? householdId;

  /// Parses `users/{uid}`, which any client could have written: null when
  /// [data] is missing or has no valid username, and other bad fields fall
  /// back to defaults instead of throwing.
  static UserProfile? fromMap(String uid, Map<String, Object?>? data) {
    final username = data?['username'];
    if (username is! String || parseUsername(username) != username) {
      return null;
    }
    final displayName = data!['displayName'];
    final householdId = data['householdId'];
    return UserProfile(
      uid: uid,
      username: username,
      displayName: displayName is String && displayName.trim().isNotEmpty
          ? displayName
          : username,
      householdId: householdId is String ? householdId : null,
    );
  }
}
