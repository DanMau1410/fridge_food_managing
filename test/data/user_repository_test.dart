import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_food_managing/data/repositories/user_repository.dart';

void main() {
  late FakeFirebaseFirestore db;
  late UserRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = UserRepository(db);
  });

  Future<Map<String, dynamic>?> read(String path) async =>
      (await db.doc(path).get()).data();

  test('AC-ID-4: a claim writes exactly the lock and the profile', () async {
    await repo.claimUsername('u1', 'dan_m', 'Dan');

    expect(await read('usernames/dan_m'), {'uid': 'u1'});
    expect(await read('users/u1'), {'username': 'dan_m', 'displayName': 'Dan'});
    expect((await db.collection('usernames').get()).size, 1);
    expect((await db.collection('users').get()).size, 1);
  });

  test('AC-ID-5: a taken username throws and changes nothing', () async {
    await repo.claimUsername('u1', 'dan_m', 'Dan');

    await expectLater(
      repo.claimUsername('u2', 'dan_m', 'Other'),
      throwsA(isA<UsernameTaken>()),
    );
    expect(await read('usernames/dan_m'), {'uid': 'u1'});
    expect(await read('users/u2'), isNull);
  });

  test('watchProfile emits null, then the profile once claimed', () async {
    final usernames = repo.watchProfile('u1').map((p) => p?.username);
    final expectation = expectLater(usernames, emitsInOrder([null, 'dan_m']));

    await repo.claimUsername('u1', 'dan_m', 'Dan');
    await expectation;
  });

  test('getProfile is null before the claim and filled after it', () async {
    expect(await repo.getProfile('u1'), isNull);
    await repo.claimUsername('u1', 'dan_m', 'Dan');

    final profile = await repo.getProfile('u1');
    expect((profile?.username, profile?.displayName), ('dan_m', 'Dan'));
  });

  test('uidForUsername matches any casing and rejects bad input', () async {
    await repo.claimUsername('u1', 'dan_m', 'Dan');

    expect(await repo.uidForUsername('dan_m'), 'u1');
    expect(await repo.uidForUsername(' DAN_M '), 'u1');
    expect(await repo.uidForUsername('nobody'), isNull);
    // Never reaches Firestore: a `/` would otherwise name another path.
    expect(await repo.uidForUsername('dan/m'), isNull);
  });
}
