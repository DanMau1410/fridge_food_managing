import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_food_managing/ui/auth/widgets/auth_gate.dart';
import 'package:fridge_food_managing/ui/core/app_shell.dart';

import 'harness.dart';

void main() {
  testWidgets('AC-ID-1: sign up → Choose-username → shell', (tester) async {
    final auth = MockFirebaseAuth();
    final db = FakeFirebaseFirestore();
    await tester.pumpWidget(testApp(auth, const AuthGate(), db: db));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'ana@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret1',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a username'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Ana_1');
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(AppShell), findsOneWidget);
    final uid = auth.currentUser!.uid;
    expect((await db.doc('usernames/ana_1').get()).data(), {'uid': uid});
  });
}
