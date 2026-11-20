import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_food_managing/data/repositories/auth_repository.dart';
import 'package:fridge_food_managing/data/repositories/user_repository.dart';
import 'package:fridge_food_managing/domain/models/user_profile.dart';
import 'package:fridge_food_managing/ui/auth/view_models/session_view_model.dart';

class _BrokenUsers extends UserRepository {
  _BrokenUsers() : super(FakeFirebaseFirestore());

  @override
  Stream<UserProfile?> watchProfile(String uid) => Stream.error(
    FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
  );
}

void main() {
  late AuthRepository auth;
  late UserRepository users;
  late SessionViewModel vm;
  late List<SessionStatus> seen;

  /// Starts [vm] over [userRepo] and records each status change.
  Future<void> start([UserRepository? userRepo]) async {
    vm = SessionViewModel(auth, userRepo ?? users);
    seen = [vm.status];
    vm.addListener(() {
      if (vm.status != seen.last) seen.add(vm.status);
    });
    addTearDown(vm.dispose);
    await pumpEventQueue();
  }

  setUp(() {
    auth = AuthRepository(MockFirebaseAuth());
    users = UserRepository(FakeFirebaseFirestore());
  });

  test('AC-ID-1: sign-up → needs username → claim → ready', () async {
    await start();
    await auth.signUpWithEmail('ana@example.com', 'secret1');
    await pumpEventQueue();
    expect(vm.status, SessionStatus.needsUsername);

    await users.claimUsername(vm.user!.uid, 'ana', 'Ana');
    await pumpEventQueue();

    expect(seen, [
      SessionStatus.loading,
      SessionStatus.signedOut,
      SessionStatus.loading,
      SessionStatus.needsUsername,
      SessionStatus.ready,
    ]);
    expect(vm.profile?.username, 'ana');
  });

  test('AC-ID-7: sign out, then back in, skips Choose-username', () async {
    await start();
    await auth.signUpWithEmail('ana@example.com', 'secret1');
    await pumpEventQueue();
    await users.claimUsername(vm.user!.uid, 'ana', 'Ana');
    await pumpEventQueue();

    await vm.signOut();
    await pumpEventQueue();
    expect(vm.status, SessionStatus.signedOut);
    expect(vm.profile, isNull);

    seen = [vm.status];
    await auth.signInWithEmail('ana@example.com', 'secret1');
    await pumpEventQueue();
    expect(seen, [
      SessionStatus.signedOut,
      SessionStatus.loading,
      SessionStatus.ready,
    ]);
  });

  test('a profile stream error → the error state', () async {
    await start(_BrokenUsers());
    await auth.signUpWithEmail('ana@example.com', 'secret1');
    await pumpEventQueue();

    expect(vm.status, SessionStatus.error);

    await vm.signOut();
    await pumpEventQueue();
    expect(vm.status, SessionStatus.signedOut);
  });
}
