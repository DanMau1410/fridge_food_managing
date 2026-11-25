import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_food_managing/ui/auth/widgets/auth_gate.dart';
import 'package:fridge_food_managing/ui/auth/widgets/sign_in_screen.dart';

import '../../fakes.dart';
import 'harness.dart';

final _email = find.widgetWithText(TextFormField, 'Email');
final _password = find.widgetWithText(TextFormField, 'Password');

Future<void> _pump(WidgetTester tester, FirebaseAuth auth) async {
  await tester.pumpWidget(testApp(auth, const SignInScreen()));
  await tester.pumpAndSettle();
}

Future<void> _submit(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(FilledButton, label));
  await tester.pumpAndSettle();
}

void main() {
  group('AC-ID-2: a failed sign-in shows a localized message', () {
    const cases = {
      'wrong-password': 'Wrong email or password.',
      'user-not-found': 'Wrong email or password.',
      'invalid-credential': 'Wrong email or password.',
      'invalid-email': "That email address doesn't look right.",
    };
    for (final MapEntry(key: code, value: message) in cases.entries) {
      testWidgets(code, (tester) async {
        await _pump(tester, ThrowingAuth(code));
        await tester.enterText(_email, 'ana@example.com');
        await tester.enterText(_password, 'secret1');
        await _submit(tester, 'Sign in');

        expect(find.text(message), findsOneWidget);
        expect(find.textContaining(code), findsNothing);
        expect(find.byType(SignInScreen), findsOneWidget);
      });
    }
  });

  testWidgets('empty fields are refused before any call', (tester) async {
    final auth = MockFirebaseAuth();
    await _pump(tester, auth);
    await _submit(tester, 'Sign in');

    expect(find.text('Enter your email.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(auth.currentUser, isNull);
  });

  testWidgets('sign-up refuses 5 characters and accepts 6', (tester) async {
    final auth = MockFirebaseAuth();
    await _pump(tester, auth);
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();
    await tester.enterText(_email, 'ana@example.com');

    await tester.enterText(_password, '12345');
    await _submit(tester, 'Create account');
    expect(find.text('Use at least 6 characters.'), findsOneWidget);
    expect(auth.currentUser, isNull);

    await tester.enterText(_password, '123456');
    await _submit(tester, 'Create account');
    expect(find.text('Use at least 6 characters.'), findsNothing);
    expect(auth.currentUser?.email, 'ana@example.com');
  });

  testWidgets('sign-up refuses a 31-character display name', (tester) async {
    final auth = MockFirebaseAuth();
    await _pump(tester, auth);
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();
    await tester.enterText(_email, 'ana@example.com');
    await tester.enterText(_password, '123456');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Display name (optional)'),
      'x' * 31,
    );
    await _submit(tester, 'Create account');

    expect(find.text('Use at most 30 characters.'), findsOneWidget);
    expect(auth.currentUser, isNull);
  });

  testWidgets('AC-ID-10: renders in Spanish', (tester) async {
    setLanguage(tester, 'es');
    await _pump(tester, ThrowingAuth('wrong-password'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo electrónico'),
      'ana@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'secret1',
    );
    await _submit(tester, 'Iniciar sesión');

    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    expect(find.text('¿Eres nuevo? Crea una cuenta'), findsOneWidget);
    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
  });

  group('AC-ID-3: Continue with Google', () {
    testWidgets('a first-time user gets Choose-username, name prefilled', (
      tester,
    ) async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'g1', displayName: 'Ana Google'),
      );
      await tester.pumpWidget(testApp(auth, const AuthGate()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(find.text('Choose a username'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Ana Google'), findsOneWidget);
    });

    testWidgets('closing the popup shows no message', (tester) async {
      await _pump(tester, ThrowingAuth('popup-closed-by-user'));
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong. Try again.'), findsNothing);
      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('an email used by a password account shows a message', (
      tester,
    ) async {
      await _pump(
        tester,
        ThrowingAuth('account-exists-with-different-credential'),
      );
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(
        find.text('This email already signs in another way.'),
        findsOneWidget,
      );
    });
  });

  group('AC-ID-8: forgot password', () {
    const sent =
        'If an account uses that email, a reset link is on its way. '
        'Check your inbox.';

    Future<void> requestReset(
      WidgetTester tester,
      FirebaseAuth auth,
      String email,
    ) async {
      await _pump(tester, auth);
      await tester.enterText(_email, email);
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send link'));
      await tester.pumpAndSettle();
    }

    testWidgets('a known email gets the confirmation', (tester) async {
      await requestReset(tester, MockFirebaseAuth(), 'ana@example.com');

      expect(find.text(sent), findsOneWidget);
    });

    testWidgets('an unknown email gets the identical confirmation', (
      tester,
    ) async {
      await requestReset(
        tester,
        ThrowingAuth('user-not-found'),
        'nobody@example.com',
      );

      expect(find.text(sent), findsOneWidget);
    });

    testWidgets('a malformed email shows the email error', (tester) async {
      await requestReset(tester, ThrowingAuth('invalid-email'), 'ana@');

      expect(find.text(sent), findsNothing);
      expect(
        find.text("That email address doesn't look right."),
        findsOneWidget,
      );
    });

    testWidgets('an empty email is refused before any call', (tester) async {
      await requestReset(tester, ThrowingAuth('invalid-email'), '  ');

      expect(find.text('Enter your email.'), findsOneWidget);
      expect(find.text("That email address doesn't look right."), findsNothing);
    });
  });
}
