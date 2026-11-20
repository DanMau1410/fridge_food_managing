import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/user_repository.dart';
import '../../../domain/models/user_profile.dart';
import '../../../domain/username.dart';
import '../../../l10n/app_localizations.dart';
import '../view_models/choose_username_view_model.dart';
import '../view_models/session_view_model.dart';

/// Picks the permanent username and the display name (AC-ID-4, 5, 6).
class ChooseUsernameScreen extends StatefulWidget {
  const ChooseUsernameScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<ChooseUsernameScreen> createState() => _ChooseUsernameScreenState();
}

class _ChooseUsernameScreenState extends State<ChooseUsernameScreen> {
  late final _viewModel = ChooseUsernameViewModel(
    context.read<UserRepository>(),
    widget.user,
  );
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  late final _displayName = TextEditingController(
    text: widget.user.displayName,
  );

  @override
  void dispose() {
    _viewModel.dispose();
    _username.dispose();
    _displayName.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    _viewModel.claim(_username.text, _displayName.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final failure = switch (_viewModel.failure) {
          null => null,
          ClaimFailure.taken => l10n.usernameTaken,
          ClaimFailure.network => l10n.errorNoConnection,
          ClaimFailure.other => l10n.errorGeneric,
        };
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.chooseUsernameTitle),
            actions: [
              TextButton(
                onPressed: context.read<SessionViewModel>().signOut,
                child: Text(l10n.signOut),
              ),
            ],
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 16,
                    children: [
                      Text(l10n.chooseUsernameIntro),
                      TextFormField(
                        controller: _username,
                        decoration: InputDecoration(
                          labelText: l10n.usernameLabel,
                          helperText: l10n.usernameHelper,
                          prefixText: '@',
                        ),
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        validator: (value) => parseUsername(value ?? '') == null
                            ? l10n.usernameInvalid
                            : null,
                      ),
                      TextFormField(
                        controller: _displayName,
                        decoration: InputDecoration(
                          labelText: l10n.displayNameLabel,
                          helperText: l10n.displayNameHelper,
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        // Blank falls back to the username; only length fails.
                        validator: (value) =>
                            parseDisplayName(value ?? '', '') == null
                            ? l10n.displayNameTooLong(displayNameMaxLength)
                            : null,
                      ),
                      if (failure != null)
                        Text(
                          failure,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      FilledButton(
                        onPressed: _viewModel.busy ? null : _submit,
                        child: _viewModel.busy
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.continueButton),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
