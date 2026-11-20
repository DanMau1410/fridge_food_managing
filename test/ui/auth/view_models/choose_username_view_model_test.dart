import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_food_managing/data/repositories/user_repository.dart';
import 'package:fridge_food_managing/domain/models/user_profile.dart';
import 'package:fridge_food_managing/ui/auth/view_models/choose_username_view_model.dart';

const _user = AppUser(uid: 'u1', displayName: 'Dan');

class _OfflineUsers extends UserRepository {
  _OfflineUsers() : super(FakeFirebaseFirestore());

  @override
  Future<void> claimUsername(String uid, String username, String displayName) =>
      Future.error(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );
}

void main() {
  late FakeFirebaseFirestore db;
  late ChooseUsernameViewModel vm;

  setUp(() {
    db = FakeFirebaseFirestore();
    vm = ChooseUsernameViewModel(UserRepository(db), _user);
  });

  Future<Map<String, dynamic>?> read(String path) async =>
      (await db.doc(path).get()).data();

  test('AC-ID-6: invalid names never reach Firestore', () async {
    for (final name in ['ab', 'a' * 21, 'dan m', 'dan-m']) {
      await vm.claim(name, 'Dan');
    }
    await vm.claim('dan_m', 'x' * 31);

    expect((await db.collection('usernames').get()).size, 0);
    expect((await db.collection('users').get()).size, 0);
    expect(vm.failure, isNull);
  });

  test('AC-ID-4: Dan_M stores dan_m', () async {
    await vm.claim('Dan_M', ' Dan ');

    expect(await read('usernames/dan_m'), {'uid': 'u1'});
    expect(await read('users/u1'), {'username': 'dan_m', 'displayName': 'Dan'});
  });

  test('an empty display name is stored as the username', () async {
    await vm.claim('dan_m', '  ');

    expect(await read('users/u1'), {
      'username': 'dan_m',
      'displayName': 'dan_m',
    });
  });

  test('AC-ID-5: a taken name fails and changes nothing', () async {
    await UserRepository(db).claimUsername('u2', 'dan_m', 'Other');

    await vm.claim('DAN_M', 'Dan');

    expect(vm.failure, ClaimFailure.taken);
    expect(vm.busy, isFalse);
    expect(await read('usernames/dan_m'), {'uid': 'u2'});
    expect(await read('users/u1'), isNull);
  });

  test('offline → the network failure', () async {
    final offline = ChooseUsernameViewModel(_OfflineUsers(), _user);
    await offline.claim('dan_m', 'Dan');

    expect(offline.failure, ClaimFailure.network);
  });
}
