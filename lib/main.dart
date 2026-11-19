import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'ui/core/app_shell.dart';
import 'ui/core/theme.dart';

const _useEmulator = bool.fromEnvironment('USE_EMULATOR');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Android persists offline by default; web needs it on, before the first Firestore use.
  if (kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
  }
  if (_useEmulator) {
    // The plugins map localhost to 10.0.2.2 on the Android emulator.
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8085);
    debugPrint('Using Firebase emulators (Auth :9099, Firestore :8085)');
  }
  runApp(const FridgeApp());
}

class FridgeApp extends StatelessWidget {
  const FridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AppShell(),
    );
  }
}
