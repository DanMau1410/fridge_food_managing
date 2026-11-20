import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/dependencies.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'ui/auth/widgets/auth_gate.dart';
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
    // localhost everywhere: on Android, `adb reverse` forwards both ports to
    // this machine, so turn off the plugins' rewrite to 10.0.2.2.
    await FirebaseAuth.instance.useAuthEmulator(
      'localhost',
      9099,
      automaticHostMapping: false,
    );
    FirebaseFirestore.instance.useFirestoreEmulator(
      'localhost',
      8085,
      automaticHostMapping: false,
    );
    debugPrint('Using Firebase emulators (Auth :9099, Firestore :8085)');
  }
  runApp(
    MultiProvider(
      providers: providers(FirebaseAuth.instance, FirebaseFirestore.instance),
      child: const FridgeApp(home: AuthGate()),
    ),
  );
}

class FridgeApp extends StatelessWidget {
  const FridgeApp({super.key, required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );
  }
}
