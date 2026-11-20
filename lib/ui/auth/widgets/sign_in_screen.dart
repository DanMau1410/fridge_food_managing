import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../domain/username.dart';
import '../../../l10n/app_localizations.dart';
import '../view_models/sign_in_view_model.dart';

/// The localized message for [failure]; never the Firebase code.
String authFailureMessage(AppLocalizations l10n, AuthFailure failure) =>
    switch (failure) {
      AuthFailure.invalidCredentials => l10n.authInvalidCredentials,
      AuthFailure.emailInUse => l10n.authEmailInUse,
      AuthFailure.weakPassword => l10n.authWeakPassword,
      AuthFailure.invalidEmail => l10n.authInvalidEmail,
      AuthFailure.tooManyRequests => l10n.authTooManyRequests,
      AuthFailure.network => l10n.errorNoConnection,
      AuthFailure.accountExists => l10n.authAccountExists,
      AuthFailure.cancelled || AuthFailure.unknown => l10n.errorGeneric,
    };

/// Email sign-in, switchable to sign-up (AC-ID-1, AC-ID-2).
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  late final _viewModel = SignInViewModel(context.read<AuthRepository>());
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();

  @override
  void dispose() {
    _viewModel.dispose();
    _email.dispose();
    _password.dispose();
    _displayName.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    _viewModel.submit(
      email: _email.text,
      password: _password.text,
      displayName: _viewModel.signUp ? _displayName.text : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final signUp = _viewModel.signUp;
        final failure = _viewModel.failure;
        final title = signUp ? l10n.createAccount : l10n.signIn;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.appTitle)),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _form,
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 16,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        TextFormField(
                          controller: _email,
                          decoration: InputDecoration(
                            labelText: l10n.emailLabel,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.next,
                          validator: (value) => (value ?? '').trim().isEmpty
                              ? l10n.errorEmailRequired
                              : null,
                        ),
                        TextFormField(
                          controller: _password,
                          decoration: InputDecoration(
                            labelText: l10n.passwordLabel,
                          ),
                          obscureText: true,
                          autofillHints: [
                            signUp
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          textInputAction: signUp
                              ? TextInputAction.next
                              : TextInputAction.done,
                          onFieldSubmitted: signUp ? null : (_) => _submit(),
                          validator: (value) {
                            final password = value ?? '';
                            if (password.isEmpty) {
                              return l10n.errorPasswordRequired;
                            }
                            if (signUp && password.length < minPasswordLength) {
                              return l10n.errorPasswordTooShort(
                                minPasswordLength,
                              );
                            }
                            return null;
                          },
                        ),
                        if (signUp)
                          TextFormField(
                            controller: _displayName,
                            decoration: InputDecoration(
                              labelText: l10n.displayNameOptionalLabel,
                            ),
                            autofillHints: const [AutofillHints.name],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            // Blank is fine here; only the length can fail.
                            validator: (value) =>
                                parseDisplayName(value ?? '', '') == null
                                ? l10n.displayNameTooLong(displayNameMaxLength)
                                : null,
                          ),
                        if (failure != null)
                          Text(
                            authFailureMessage(l10n, failure),
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
                              : Text(title),
                        ),
                        TextButton(
                          onPressed: _viewModel.busy
                              ? null
                              : _viewModel.toggleMode,
                          child: Text(
                            signUp ? l10n.switchToSignIn : l10n.switchToSignUp,
                          ),
                        ),
                      ],
                    ),
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
