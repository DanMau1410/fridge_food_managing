import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/username.dart';
import '../../../l10n/app_localizations.dart';
import '../view_models/session_view_model.dart';

/// "Household & account": for now, the account section (AC-ID-7, AC-ID-11).
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _signOut(BuildContext context) {
    final session = context.read<SessionViewModel>();
    // Pop first, so no screen stays above Sign-in.
    Navigator.of(context).popUntil((route) => route.isFirst);
    return session.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = context.watch<SessionViewModel>();
    final profile = session.profile;
    final email = session.user?.email;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountTitle)),
      body: profile == null
          ? const SizedBox.shrink()
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView(
                  children: [
                    ListTile(
                      title: Text(
                        l10n.accountSection,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    ListTile(
                      title: Text(l10n.usernameLabel),
                      subtitle: _OneLine('@${profile.username}'),
                    ),
                    ListTile(
                      title: Text(l10n.displayNameLabel),
                      subtitle: _OneLine(profile.displayName),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: l10n.editDisplayName,
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) =>
                              _EditDisplayNameDialog(profile.displayName),
                        ),
                      ),
                    ),
                    if (email != null)
                      ListTile(
                        title: Text(l10n.emailLabel),
                        subtitle: _OneLine(email),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: OutlinedButton(
                        onPressed: () => _signOut(context),
                        child: Text(l10n.signOut),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Edits the display name (AC-ID-11). Save closes at once: the write lands
/// locally first, and the profile stream refreshes the screen.
class _EditDisplayNameDialog extends StatefulWidget {
  const _EditDisplayNameDialog(this.current);

  final String current;

  @override
  State<_EditDisplayNameDialog> createState() => _EditDisplayNameDialogState();
}

class _EditDisplayNameDialogState extends State<_EditDisplayNameDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.current);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    context.read<SessionViewModel>().updateDisplayName(_name.text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.editDisplayName),
      content: Form(
        key: _form,
        child: TextFormField(
          controller: _name,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.displayNameLabel,
            helperText: l10n.displayNameHelper,
            helperMaxLines: 2,
          ),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _save(),
          // Blank falls back to the username; only length fails.
          validator: (value) => parseDisplayName(value ?? '', '') == null
              ? l10n.displayNameTooLong(displayNameMaxLength)
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(material.cancelButtonLabel),
        ),
        FilledButton(onPressed: _save, child: Text(material.saveButtonLabel)),
      ],
    );
  }
}

/// User text on one line, ending in "…" when it doesn't fit.
class _OneLine extends StatelessWidget {
  const _OneLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);
}
