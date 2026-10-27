import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failure.dart';
import '../../../core/widgets/ep_button.dart';
import '../../../core/widgets/ep_card.dart';
import '../../../core/widgets/ep_feedback.dart';
import '../../../core/widgets/ep_text_field.dart';
import '../../wallet/data/wallet_providers.dart';
import '../data/profile_repository.dart';

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final code = _code.text.trim();
    if (code.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final bonus =
          await ref.read(profileRepositoryProvider).applyReferral(code);
      if (!mounted) return;
      _code.clear();
      showEpToast(context, context.tr('referral_applied', {'n': bonus}),
          kind: ToastKind.success);
    } catch (e) {
      if (!mounted) return;
      showEpToast(context, context.tr(Failure.from(e).l10nKey),
          kind: ToastKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    final profile = ref.watch(profileProvider).valueOrNull;
    final mine = profile?.referralCode ?? '';
    final canApply = !(profile?.hasReferrer ?? false);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('referral_title'))),
      body: ListView(
        padding: const EdgeInsets.all(Sp.gutter),
        children: [
          Text(context.tr('referral_sub'),
              style: context.text.bodyLarge?.copyWith(color: c.textSecondary)),
          const SizedBox(height: Sp.lg),
          EpCard(
            child: Column(
              children: [
                Text(context.tr('referral_your_code'),
                    style: context.text.bodySmall),
                const SizedBox(height: Sp.xs),
                SelectableText(
                  mine.isEmpty ? '—' : mine,
                  style: context.text.headlineMedium
                      ?.copyWith(letterSpacing: 4, color: c.lime),
                ),
                const SizedBox(height: Sp.md),
                Row(
                  children: [
                    Expanded(
                      child: EpButton(
                        label: context.tr('copy'),
                        kind: EpButtonKind.secondary,
                        icon: Icons.copy_rounded,
                        onPressed: mine.isEmpty
                            ? null
                            : () async {
                                await Clipboard.setData(
                                    ClipboardData(text: mine));
                                if (context.mounted) {
                                  showEpToast(context, context.tr('copied'),
                                      kind: ToastKind.success);
                                }
                              },
                      ),
                    ),
                    const SizedBox(width: Sp.xs),
                    Expanded(
                      child: EpButton(
                        label: context.tr('share'),
                        icon: Icons.ios_share_rounded,
                        onPressed: mine.isEmpty
                            ? null
                            : () => Share.share(context.tr(
                                'referral_share_text', {
                                'code': mine,
                                'link':
                                    '${AppConstants.backendUrl}/invite/$mine',
                              })),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (canApply) ...[
            const SizedBox(height: Sp.xl),
            Text(context.tr('referral_have_code'),
                style: context.text.titleMedium),
            const SizedBox(height: Sp.sm),
            EpTextField(
              label: context.tr('referral_enter'),
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _apply(),
              enabled: !_busy,
            ),
            const SizedBox(height: Sp.sm),
            EpButton(
              label: context.tr('referral_apply'),
              loading: _busy,
              onPressed: _apply,
            ),
          ],
        ],
      ),
    );
  }
}
