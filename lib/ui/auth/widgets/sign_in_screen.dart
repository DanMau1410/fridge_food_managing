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

/// Email sign-in, switchable to sign-up, plus Google and password reset
/// (AC-ID-1, 2, 3, 8).
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

  void _forgotPassword() => showDialog<void>(
    context: context,
    builder: (_) => _ResetPasswordDialog(_viewModel, _email.text),
  );

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
                        if (!signUp)
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TextButton(
                              onPressed: _viewModel.busy
                                  ? null
                                  : _forgotPassword,
                              child: Text(l10n.forgotPassword),
                            ),
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
                        OutlinedButton(
                          onPressed: _viewModel.busy
                              ? null
                              : _viewModel.signInWithGoogle,
                          child: Text(l10n.continueWithGoogle),
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

/// Asks for the email and sends a reset link (AC-ID-8). Known and unknown
/// emails get the same confirmation.
class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog(this.viewModel, this.email);

  final SignInViewModel viewModel;
  final String email;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email.trim());
  bool _busy = false;
  bool _sent = false;
  AuthFailure? _failure;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    final failure = await widget.viewModel.sendPasswordReset(_email.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _failure = failure;
      _sent = failure == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    final failure = _failure;
    if (_sent) {
      return AlertDialog(
        title: Text(l10n.resetPasswordTitle),
        content: Text(l10n.resetPasswordSent),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(material.okButtonLabel),
          ),
        ],
      );
    }
    return AlertDialog(
      title: Text(l10n.resetPasswordTitle),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            Text(l10n.resetPasswordIntro),
            TextFormField(
              controller: _email,
              decoration: InputDecoration(labelText: l10n.emailLabel),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _send(),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? l10n.errorEmailRequired : null,
            ),
            if (failure != null)
              Text(
                authFailureMessage(l10n, failure),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(material.cancelButtonLabel),
        ),
        FilledButton(
          onPressed: _busy ? null : _send,
          child: Text(l10n.sendResetLink),
        ),
      ],
    );
  }
}
