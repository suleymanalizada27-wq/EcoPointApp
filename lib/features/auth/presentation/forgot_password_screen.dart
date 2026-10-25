import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/errors/failure.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/ep_button.dart';
import '../../../core/widgets/ep_feedback.dart';
import '../../../core/widgets/ep_text_field.dart';
import '../data/auth_repository.dart';
import 'auth_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(_email.text);
      if (mounted) {
        showEpToast(context, context.tr('auth_reset_sent'),
            kind: ToastKind.success);
        Navigator.of(context).maybePop();
      }
    } on Failure catch (f) {
      // `user-not-found` is reported as success-neutral wording elsewhere;
      // here we show the precise reason because the user typed the address.
      if (mounted) {
        showEpToast(context, context.tr(authErrorKey(f.code)),
            kind: ToastKind.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: true,
      title: context.tr('auth_forgot_title'),
      subtitle: context.tr('auth_forgot_sub'),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EpTextField(
              label: context.tr('auth_email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.mail_outline_rounded,
              autofocus: true,
              onSubmitted: (_) => _submit(),
              validator: (v) {
                final k = Validators.email(v);
                return k == null ? null : context.tr(k);
              },
            ),
            const SizedBox(height: 24),
            EpButton(
              label: context.tr('auth_send_reset'),
              loading: _busy,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
