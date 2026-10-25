import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/errors/failure.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/ep_button.dart';
import '../../../core/widgets/ep_feedback.dart';
import '../../../core/widgets/ep_text_field.dart';
import '../data/auth_repository.dart';
import 'auth_widgets.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _googleBusy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithEmail(_email.text, _password.text);
      // Router redirect moves the user into the app.
    } on Failure catch (f) {
      if (mounted) {
        showEpToast(context, context.tr(authErrorKey(f.code)),
            kind: ToastKind.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    if (_googleBusy) return;
    setState(() => _googleBusy = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } on Failure catch (f) {
      if (mounted) {
        showEpToast(context, context.tr(authErrorKey(f.code)),
            kind: ToastKind.error);
      }
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    return AuthScaffold(
      title: context.tr('auth_welcome_back'),
      subtitle: context.tr('auth_welcome_back_sub'),
      child: AutofillGroup(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EpTextField(
                label: context.tr('auth_email'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                prefixIcon: Icons.mail_outline_rounded,
                inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                validator: (v) {
                  final k = Validators.email(v);
                  return k == null ? null : context.tr(k);
                },
              ),
              const SizedBox(height: Sp.md),
              EpTextField(
                label: context.tr('auth_password'),
                controller: _password,
                obscure: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                prefixIcon: Icons.lock_outline_rounded,
                onSubmitted: (_) => _submit(),
                validator: (v) =>
                    (v ?? '').isEmpty ? context.tr('auth_err_password_short') : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  child: Text(context.tr('auth_forgot_password')),
                ),
              ),
              const SizedBox(height: Sp.xs),
              EpButton(
                label: context.tr('auth_sign_in'),
                loading: _busy,
                onPressed: _submit,
              ),
              const SizedBox(height: Sp.lg),
              OrDivider(label: context.tr('auth_or')),
              const SizedBox(height: Sp.lg),
              EpButton(
                label: context.tr('auth_google'),
                kind: EpButtonKind.secondary,
                icon: Icons.g_mobiledata_rounded,
                loading: _googleBusy,
                onPressed: _google,
              ),
              const SizedBox(height: Sp.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(context.tr('auth_no_account'),
                      style: context.text.bodyMedium
                          ?.copyWith(color: c.textSecondary)),
                  TextButton(
                    onPressed: () => context.go('/sign-up'),
                    child: Text(context.tr('auth_sign_up')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
