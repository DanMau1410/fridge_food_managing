import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_food_managing/data/repositories/auth_repository.dart';

import '../fakes.dart';

void main() {
  group('failureFor', () {
    final table = {
      'invalid-credential': AuthFailure.invalidCredentials,
      'invalid-login-credentials': AuthFailure.invalidCredentials,
      'wrong-password': AuthFailure.invalidCredentials,
      'user-not-found': AuthFailure.invalidCredentials,
      'email-already-in-use': AuthFailure.emailInUse,
      'weak-password': AuthFailure.weakPassword,
      'invalid-email': AuthFailure.invalidEmail,
      'too-many-requests': AuthFailure.tooManyRequests,
      'network-request-failed': AuthFailure.network,
      'account-exists-with-different-credential': AuthFailure.accountExists,
      'popup-closed-by-user': AuthFailure.cancelled,
      'cancelled-popup-request': AuthFailure.cancelled,
      'web-context-canceled': AuthFailure.cancelled,
      'web-context-cancelled': AuthFailure.cancelled,
      'internal-error': AuthFailure.unknown,
      '': AuthFailure.unknown,
    };
    for (final MapEntry(key: code, value: failure) in table.entries) {
      test('"$code" → ${failure.name}', () {
        expect(failureFor(code), failure);
      });
    }
  });

  test('AC-ID-1: sign-up sets the trimmed display name', () async {
    final auth = MockFirebaseAuth();
    await AuthRepository(auth)
        .signUpWithEmail(' ana@example.com ', 'secret1', displayName: '  Ana ');

    expect(auth.currentUser?.email, 'ana@example.com');
    expect(auth.currentUser?.displayName, 'Ana');
  });

  test('sign-up with a blank display name leaves it unset', () async {
    final auth = MockFirebaseAuth();
    await AuthRepository(auth)
        .signUpWithEmail('ana@example.com', 'secret1', displayName: '  ');

    // The mock's own default; a real new account has none.
    expect(auth.currentUser?.displayName, 'Mock User');
  });

  test('sign-in, then sign-out, through watchAuthUser', () async {
    final auth = MockFirebaseAuth(
      mockUser: MockUser(uid: 'u1', email: 'a@b.c'),
    );
    final repo = AuthRepository(auth);
    final uids = repo.watchAuthUser().map((u) => u?.uid);
    final expectation = expectLater(uids, emitsInOrder([null, 'u1', null]));

    await repo.signInWithEmail('a@b.c', 'secret1');
    await repo.signOut();
    await expectation;
  });

  test('a Firebase error becomes an AuthException', () async {
    final repo = AuthRepository(ThrowingAuth('wrong-password'));

    await expectLater(
      repo.signInWithEmail('a@b.c', 'nope'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.failure,
          'failure',
          AuthFailure.invalidCredentials,
        ),
      ),
    );
    await expectLater(
      repo.signUpWithEmail('a@b.c', 'secret1'),
      throwsA(isA<AuthException>()),
    );
  });

  test('AC-ID-3: Google signs in through the provider flow', () async {
    final auth = MockFirebaseAuth(
      mockUser: MockUser(uid: 'g1', displayName: 'Ana Google'),
    );
    await AuthRepository(auth).signInWithGoogle();

    expect(auth.currentUser?.uid, 'g1');
  });

  test('a Google failure becomes an AuthException', () async {
    final repo = AuthRepository(
      ThrowingAuth('account-exists-with-different-credential'),
    );

    await expectLater(
      repo.signInWithGoogle(),
      throwsA(
        isA<AuthException>().having(
          (e) => e.failure,
          'failure',
          AuthFailure.accountExists,
        ),
      ),
    );
  });

  group('AC-ID-8: sendPasswordReset', () {
    test('a known email completes', () async {
      await AuthRepository(MockFirebaseAuth()).sendPasswordReset('a@b.c');
    });

    test('an unknown email completes the same way', () async {
      await AuthRepository(ThrowingAuth('user-not-found'))
          .sendPasswordReset('a@b.c');
    });

    test('a malformed email fails', () async {
      await expectLater(
        AuthRepository(ThrowingAuth('invalid-email')).sendPasswordReset('a@'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.failure,
            'failure',
            AuthFailure.invalidEmail,
          ),
        ),
      );
    });
  });
}
