import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/user_profile.dart';
import '../../domain/username.dart';

/// Thrown when another account already holds the username.
class UsernameTaken implements Exception {
  const UsernameTaken(this.username);

  final String username;

  @override
  String toString() => 'UsernameTaken($username)';
}

/// Profiles (`users/{uid}`) and the username lock (`usernames/{username}`).
class UserRepository {
  UserRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _db.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> _username(String username) =>
      _db.collection('usernames').doc(username);

  /// Emits null until [uid] has claimed a username.
  Stream<UserProfile?> watchProfile(String uid) =>
      _user(uid)
          .snapshots()
          .map((snap) => UserProfile.fromMap(uid, snap.data()));

  Future<UserProfile?> getProfile(String uid) async =>
      UserProfile.fromMap(uid, (await _user(uid).get()).data());

  /// The account holding [username], in any casing; null when nobody does.
  Future<String?> uidForUsername(String username) async {
    final name = parseUsername(username);
    if (name == null) return null;
    final uid = (await _username(name).get()).data()?['uid'];
    return uid is String ? uid : null;
  }

  /// Claims [username] (as returned by [parseUsername]) for [uid] and creates
  /// the profile in one transaction, which the rules require. Needs a
  /// connection.
  ///
  /// Throws [UsernameTaken] when another account holds it.
  Future<void> claimUsername(String uid, String username, String displayName) =>
      _db.runTransaction((tx) async {
        if ((await tx.get(_username(username))).exists) {
          throw UsernameTaken(username);
        }
        tx.set(_username(username), {'uid': uid});
        tx.set(_user(uid), {'username': username, 'displayName': displayName});
      });

  /// Sets [displayName] (as returned by [parseDisplayName]); the rules allow
  /// no other field to change (AC-ID-11).
  Future<void> updateDisplayName(String uid, String displayName) =>
      _user(uid).update({'displayName': displayName});
}
