import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/app_shell.dart';
import '../view_models/session_view_model.dart';
import 'choose_username_screen.dart';
import 'sign_in_screen.dart';

/// Sign-in → Choose-username → the shell, following the session.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionViewModel>();
    return switch (session.status) {
      SessionStatus.loading => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      SessionStatus.signedOut => const SignInScreen(),
      // Keyed by the display name too: on real Firebase it arrives just
      // after sign-up, and the prefill should pick it up.
      SessionStatus.needsUsername => ChooseUsernameScreen(
        key: ValueKey((session.user!.uid, session.user!.displayName)),
        user: session.user!,
      ),
      SessionStatus.ready => AppShell(key: ValueKey(session.profile!.uid)),
      SessionStatus.error => const _SessionErrorScreen(),
    };
  }
}

class _SessionErrorScreen extends StatelessWidget {
  const _SessionErrorScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              Text(l10n.sessionError, textAlign: TextAlign.center),
              FilledButton(
                onPressed: context.read<SessionViewModel>().signOut,
                child: Text(l10n.signOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
