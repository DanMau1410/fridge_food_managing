import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_food_managing/config/dependencies.dart';
import 'package:fridge_food_managing/main.dart';
import 'package:provider/provider.dart';

/// The app's real providers over [auth] and [db], showing [home].
Widget testApp(FirebaseAuth auth, Widget home, {FirebaseFirestore? db}) =>
    MultiProvider(
      providers: providers(auth, db ?? FakeFirebaseFirestore()),
      child: FridgeApp(home: home),
    );

/// Sets the device language for this test.
void setLanguage(WidgetTester tester, String language) {
  tester.platformDispatcher.localesTestValue = [Locale(language)];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
}
