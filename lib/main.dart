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

/// The emulators' project (`firebase/.firebaserc`).
const _emulatorProjectId = 'demo-fridge';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final options = DefaultFirebaseOptions.currentPlatform;
  // Emulator runs get their own app on the demo project, so the app, the
  // Emulator UI and the seed share one namespace. Overriding the default
  // app's project doesn't work: on Android it comes from google-services.json.
  final app = _useEmulator
      ? await Firebase.initializeApp(
          name: 'emulator',
          options: options.copyWith(projectId: _emulatorProjectId),
        )
      : await Firebase.initializeApp(options: options);
  final auth = FirebaseAuth.instanceFor(app: app);
  final db = FirebaseFirestore.instanceFor(app: app);
  // Android persists offline by default; web needs it on, before the first Firestore use.
  if (kIsWeb) db.settings = const Settings(persistenceEnabled: true);
  if (_useEmulator) {
    // localhost everywhere: on Android, `adb reverse` forwards both ports to
    // this machine, so turn off the plugins' rewrite to 10.0.2.2.
    await auth.useAuthEmulator('localhost', 9099, automaticHostMapping: false);
    db.useFirestoreEmulator('localhost', 8085, automaticHostMapping: false);
    debugPrint(
      'Using Firebase emulators (Auth :9099, Firestore :8085, '
      'project $_emulatorProjectId)',
    );
  }
  runApp(
    MultiProvider(
      providers: providers(auth, db),
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
