import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_food_managing/data/repositories/auth_repository.dart';
import 'package:fridge_food_managing/ui/auth/view_models/sign_in_view_model.dart';

import '../../../fakes.dart';

void main() {
  test('AC-ID-2: a failed sign-in sets the failure and ends busy', () async {
    final vm = SignInViewModel(AuthRepository(ThrowingAuth('user-not-found')));

    final call = vm.submit(email: 'a@b.c', password: 'secret1');
    expect(vm.busy, isTrue);
    await call;

    expect(vm.busy, isFalse);
    expect(vm.failure, AuthFailure.invalidCredentials);
  });

  test('switching mode clears the failure', () async {
    final vm = SignInViewModel(AuthRepository(ThrowingAuth('wrong-password')));
    await vm.submit(email: 'a@b.c', password: 'nope');

    vm.toggleMode();
    expect(vm.signUp, isTrue);
    expect(vm.failure, isNull);
  });

  test('AC-ID-1: sign-up mode creates the account', () async {
    final auth = MockFirebaseAuth();
    final vm = SignInViewModel(AuthRepository(auth))..toggleMode();

    await vm.submit(email: 'a@b.c', password: 'secret1', displayName: 'Ana');

    expect(vm.failure, isNull);
    expect(auth.currentUser?.displayName, 'Ana');
  });

  test('finishing after dispose does not throw', () async {
    final vm = SignInViewModel(AuthRepository(MockFirebaseAuth()));
    final call = vm.submit(email: 'a@b.c', password: 'secret1');
    vm.dispose();
    await call;
  });

  group('Google', () {
    for (final code in ['popup-closed-by-user', 'web-context-canceled']) {
      test('cancelling ($code) shows nothing', () async {
        final vm = SignInViewModel(AuthRepository(ThrowingAuth(code)));
        await vm.signInWithGoogle();

        expect(vm.failure, isNull);
        expect(vm.busy, isFalse);
      });
    }

    test('account-exists-with-different-credential is reported', () async {
      final vm = SignInViewModel(
        AuthRepository(
          ThrowingAuth('account-exists-with-different-credential'),
        ),
      );
      await vm.signInWithGoogle();

      expect(vm.failure, AuthFailure.accountExists);
    });
  });

  test('AC-ID-8: known and unknown emails both count as sent', () async {
    final known = SignInViewModel(AuthRepository(MockFirebaseAuth()));
    final unknown = SignInViewModel(
      AuthRepository(ThrowingAuth('user-not-found')),
    );
    final malformed = SignInViewModel(
      AuthRepository(ThrowingAuth('invalid-email')),
    );

    expect(await known.sendPasswordReset('a@b.c'), isNull);
    expect(await unknown.sendPasswordReset('a@b.c'), isNull);
    expect(await malformed.sendPasswordReset('a@'), AuthFailure.invalidEmail);
  });
}
