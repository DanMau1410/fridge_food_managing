import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_food_managing/data/repositories/user_repository.dart';
import 'package:fridge_food_managing/ui/auth/widgets/account_screen.dart';
import 'package:fridge_food_managing/ui/auth/widgets/auth_gate.dart';
import 'package:fridge_food_managing/ui/auth/widgets/sign_in_screen.dart';
import 'package:fridge_food_managing/ui/core/app_shell.dart';

import 'harness.dart';

void main() {
  late MockFirebaseAuth auth;
  late FakeFirebaseFirestore db;

  setUp(() async {
    auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'u1', email: 'ana@example.com'),
    );
    db = FakeFirebaseFirestore();
    await UserRepository(db).claimUsername('u1', 'ana', 'Ana');
  });

  /// The whole app, signed in as ana, on the account screen.
  Future<void> openAccount(WidgetTester tester) async {
    await tester.pumpWidget(testApp(auth, const AuthGate(), db: db));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.account_circle_outlined));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the username, display name and email', (tester) async {
    await openAccount(tester);

    expect(find.text('@ana'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('ana@example.com'), findsOneWidget);
  });

  testWidgets('AC-ID-7: sign out leaves only Sign-in; back in → shell', (
    tester,
  ) async {
    await openAccount(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.byType(AccountScreen), findsNothing);
    expect(find.byType(AppShell), findsNothing);
    expect(find.text('@ana'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'ana@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret1',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.text('Choose a username'), findsNothing);
  });

  testWidgets('AC-ID-10: renders in Spanish', (tester) async {
    setLanguage(tester, 'es');
    await openAccount(tester);

    expect(find.text('Hogar y cuenta'), findsOneWidget);
    expect(find.text('Cuenta'), findsOneWidget);
    expect(find.text('Nombre de usuario'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });

  group('AC-ID-11: edit the display name', () {
    Future<Object?> stored() async =>
        (await db.doc('users/u1').get()).data()?['displayName'];

    Future<void> openDialog(WidgetTester tester) async {
      await openAccount(tester);
      await tester.tap(find.byTooltip('Edit display name'));
      await tester.pumpAndSettle();
    }

    Future<void> save(WidgetTester tester, String name) async {
      await tester.enterText(find.byType(TextFormField), name);
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
    }

    testWidgets('prefilled; saving updates the screen', (tester) async {
      await openDialog(tester);
      expect(find.widgetWithText(TextFormField, 'Ana'), findsOneWidget);

      await save(tester, '  Ana María ');

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Ana María'), findsOneWidget);
      expect(await stored(), 'Ana María');
    });

    testWidgets('empty stores the username', (tester) async {
      await openDialog(tester);
      await save(tester, '');

      expect(await stored(), 'ana');
    });

    testWidgets('31 characters shows the message and writes nothing', (
      tester,
    ) async {
      await openDialog(tester);
      await save(tester, 'x' * 31);

      expect(find.text('Use at most 30 characters.'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(await stored(), 'Ana');
    });

    testWidgets('a 30-character name ends in "…" at 360 px', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final wide = 'W' * 30;
      await UserRepository(db).updateDisplayName('u1', wide);
      await openAccount(tester);

      final paragraph = tester.renderObject<RenderParagraph>(find.text(wide));
      expect(paragraph.didExceedMaxLines, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AC-ID-10: the dialog renders in Spanish', (tester) async {
      setLanguage(tester, 'es');
      await openAccount(tester);
      await tester.tap(find.byTooltip('Editar nombre visible'));
      await tester.pumpAndSettle();

      expect(find.text('Editar nombre visible'), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });
  });
}
