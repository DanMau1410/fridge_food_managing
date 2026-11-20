import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_food_managing/domain/models/user_profile.dart';

(String, String, String, String?)? _fields(UserProfile? p) =>
    p == null ? null : (p.uid, p.username, p.displayName, p.householdId);

void main() {
  test('reads a full profile', () {
    final data = {'username': 'ana', 'displayName': 'Ana', 'householdId': 'h1'};
    expect(_fields(UserProfile.fromMap('u1', data)), (
      'u1',
      'ana',
      'Ana',
      'h1',
    ));
  });

  test('a missing or blank display name falls back to the username', () {
    for (final data in [
      {'username': 'ana'},
      {'username': 'ana', 'displayName': '  '},
      {'username': 'ana', 'displayName': 7},
    ]) {
      expect(UserProfile.fromMap('u1', data)?.displayName, 'ana');
    }
  });

  test('a non-string householdId is ignored', () {
    final data = {'username': 'ana', 'householdId': 3};
    expect(UserProfile.fromMap('u1', data)?.householdId, isNull);
  });

  test('no profile without a valid username', () {
    for (final data in <Map<String, Object?>?>[
      null,
      {},
      {'displayName': 'Ana'},
      {'username': 42},
      {'username': 'Ana'},
      {'username': 'an'},
    ]) {
      expect(UserProfile.fromMap('u1', data), isNull, reason: '$data');
    }
  });
}
