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

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _googleBusy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).signUpWithEmail(
            name: _name.text,
            email: _email.text,
            password: _password.text,
          );
      if (mounted) context.go('/setup');
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
      title: context.tr('auth_create_account'),
      subtitle: context.tr('auth_create_account_sub'),
      child: AutofillGroup(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EpTextField(
                label: context.tr('auth_full_name'),
                controller: _name,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                prefixIcon: Icons.person_outline_rounded,
                maxLength: 40,
                validator: (v) {
                  final k = Validators.name(v);
                  return k == null ? null : context.tr(k);
                },
              ),
              const SizedBox(height: Sp.md),
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
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                prefixIcon: Icons.lock_outline_rounded,
                validator: (v) {
                  final k = Validators.password(v);
                  return k == null ? null : context.tr(k);
                },
              ),
              const SizedBox(height: Sp.md),
              EpTextField(
                label: context.tr('auth_confirm_password'),
                controller: _confirm,
                obscure: true,
                textInputAction: TextInputAction.done,
                prefixIcon: Icons.lock_outline_rounded,
                onSubmitted: (_) => _submit(),
                validator: (v) {
                  final k = Validators.passwordMatch(v, _password.text);
                  return k == null ? null : context.tr(k);
                },
              ),
              const SizedBox(height: Sp.xl),
              EpButton(
                label: context.tr('auth_sign_up'),
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
                  Text(context.tr('auth_have_account'),
                      style: context.text.bodyMedium
                          ?.copyWith(color: c.textSecondary)),
                  TextButton(
                    onPressed: () => context.go('/sign-in'),
                    child: Text(context.tr('auth_sign_in')),
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
