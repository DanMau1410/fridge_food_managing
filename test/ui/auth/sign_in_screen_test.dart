import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  });
}
