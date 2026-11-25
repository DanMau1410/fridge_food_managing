import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_food_managing/data/repositories/user_repository.dart';
import 'package:fridge_food_managing/domain/models/user_profile.dart';
import 'package:fridge_food_managing/ui/auth/widgets/choose_username_screen.dart';

import 'harness.dart';

const _user = AppUser(uid: 'u1', displayName: 'Dan');

void main() {
  late FakeFirebaseFirestore db;

  setUp(() => db = FakeFirebaseFirestore());

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      testApp(
        MockFirebaseAuth(),
        const ChooseUsernameScreen(user: _user),
        db: db,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> claim(WidgetTester tester, String username) async {
    await tester.enterText(find.byType(TextFormField).first, username);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
  }

  testWidgets('the display name is prefilled', (tester) async {
    await pump(tester);

    expect(find.widgetWithText(TextFormField, 'Dan'), findsOneWidget);
  });

  testWidgets('AC-ID-6: an invalid name shows a message, no write', (
    tester,
  ) async {
    await pump(tester);

    for (final name in ['ab', 'a' * 21, 'dan m', 'dan-m']) {
      await claim(tester, name);
      expect(
        find.text('Use 3–20 characters: a–z, 0–9 or _, with no spaces.'),
        findsOneWidget,
      );
    }
    expect((await db.collection('usernames').get()).size, 0);
  });

  testWidgets('AC-ID-5: a taken name shows "Username already taken"', (
    tester,
  ) async {
    await UserRepository(db).claimUsername('u2', 'dan_m', 'Other');
    await pump(tester);

    await claim(tester, 'Dan_M');

    expect(find.text('Username already taken'), findsOneWidget);
    expect((await db.doc('users/u1').get()).exists, isFalse);
  });

  testWidgets('AC-ID-10: renders in Spanish', (tester) async {
    setLanguage(tester, 'es');
    await pump(tester);
    await claim(tester, 'ab');

    expect(find.text('Elige un nombre de usuario'), findsOneWidget);
    expect(
      find.text('Usa 3–20 caracteres: a–z, 0–9 o _, sin espacios.'),
      findsOneWidget,
    );
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });

  testWidgets('a Google name over 30 characters must be shortened', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        MockFirebaseAuth(),
        ChooseUsernameScreen(
          user: AppUser(uid: 'g1', displayName: 'x' * 31),
        ),
        db: db,
      ),
    );
    await tester.pumpAndSettle();
    await claim(tester, 'ana');

    expect(find.text('Use at most 30 characters.'), findsOneWidget);
    expect((await db.collection('usernames').get()).size, 0);
  });
}
