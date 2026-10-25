import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/errors/failure.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/request_id.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/ep_button.dart';
import '../../../core/widgets/ep_card.dart';
import '../../../core/widgets/ep_feedback.dart';
import '../../../core/widgets/ep_text_field.dart';
import '../../wallet/data/wallet_providers.dart';
import '../data/marketplace_repository.dart';
import '../domain/reward.dart';
import '../domain/reward_catalog.dart';

Widget _sheetFrame(BuildContext context, {required List<Widget> children}) {
  return SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        Sp.gutter,
        0,
        Sp.gutter,
        MediaQuery.of(context).viewInsets.bottom + Sp.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );
}

class _RewardHeader extends StatelessWidget {
  const _RewardHeader({required this.reward});
  final Reward reward;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    final lang = Localizations.localeOf(context).languageCode;
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: c.emerald.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(Rad.lg),
          ),
          child: Icon(reward.icon, size: 32, color: c.emerald),
        ),
        const SizedBox(width: Sp.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(reward.nameFor(lang), style: context.text.titleLarge),
              const SizedBox(height: 2),
              Text(reward.brand, style: context.text.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

/// Standard item redemption.
class RewardSheet extends ConsumerStatefulWidget {
  const RewardSheet({super.key, required this.reward});
  final Reward reward;

  @override
  ConsumerState<RewardSheet> createState() => _RewardSheetState();
}

class _RewardSheetState extends ConsumerState<RewardSheet> {
  // One key per sheet: a retry after a timeout reuses it, so the backend
  // cannot apply the purchase twice.
  final String _requestId = newRequestId();
  bool _busy = false;

  Future<void> _redeem() async {
    if (_busy) return;
    final reward = widget.reward;
    final ok = await confirmSheet(
      context,
      title: context.tr('reward_confirm_title'),
      body: context.tr('reward_confirm_body', {'price': Fmt.number(reward.ep)}),
      confirmLabel: context.tr('reward_buy'),
      icon: Icons.card_giftcard_rounded,
    );
    if (!ok || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(marketplaceRepositoryProvider)
          .purchase(rewardId: reward.id, requestId: _requestId);
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      final lang = Localizations.localeOf(context).languageCode;
      final name = reward.nameFor(lang);
      Navigator.of(context).pop();
      showEpToast(
        context,
        context.tr('reward_success_body', {'name': name}),
        kind: ToastKind.success,
      );
    } on Failure catch (f) {
      if (mounted) {
        showEpToast(context, context.tr(f.l10nKey), kind: ToastKind.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    final reward = widget.reward;
    final balance = ref.watch(balanceProvider).valueOrNull ?? 0;
    final after = balance - reward.ep;
    final enough = after >= 0;

    return _sheetFrame(context, children: [
      _RewardHeader(reward: reward),
      const SizedBox(height: Sp.lg),
      EpCard(
        color: c.surfaceRaised,
        child: Column(
          children: [
            _Row(
              label: context.tr('home_balance'),
              value: '${Fmt.number(balance)} ${context.tr('ep_unit')}',
            ),
            const SizedBox(height: Sp.xs),
            _Row(
              label: context.tr('reward_buy'),
              value: '−${Fmt.number(reward.ep)} ${context.tr('ep_unit')}',
              valueColor: c.lime,
            ),
            Divider(height: Sp.lg, color: c.outline),
            _Row(
              label: context.tr('reward_balance_after'),
              value: enough
                  ? '${Fmt.number(after)} ${context.tr('ep_unit')}'
                  : '—',
              strong: true,
            ),
          ],
        ),
      ),
      const SizedBox(height: Sp.sm),
      if (!reward.inStock)
        Text(context.tr('reward_out_of_stock'),
            style: context.text.bodyMedium?.copyWith(color: c.danger))
      else if (!enough)
        Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 16, color: c.warning),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                context.tr('reward_need_more', {'n': Fmt.number(-after)}),
                style: context.text.bodyMedium?.copyWith(color: c.warning),
              ),
            ),
          ],
        ),
      const SizedBox(height: Sp.lg),
      EpButton(
        label: enough
            ? context.tr('reward_buy')
            : context.tr('reward_insufficient'),
        loading: _busy,
        onPressed: (enough && reward.inStock) ? _redeem : null,
        kind: EpButtonKind.accent,
      ),
    ]);
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.valueColor,
    this.strong = false,
  });
  final String label;
  final String value;
  final Color? valueColor;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: context.text.bodyMedium?.copyWith(color: c.textSecondary)),
        ),
        Text(
          value,
          style: (strong ? context.text.titleMedium : context.text.titleSmall)
              ?.copyWith(color: valueColor),
        ),
      ],
    );
  }
}

/// Convert EP to a partner coupon (Bravo / Bolmart).
class CouponSheet extends ConsumerStatefulWidget {
  const CouponSheet({super.key, required this.reward});
  final Reward reward;

  @override
  ConsumerState<CouponSheet> createState() => _CouponSheetState();
}

class _CouponSheetState extends ConsumerState<CouponSheet> {
  final _amount = TextEditingController();
  String _requestId = newRequestId();
  bool _busy = false;
  String? _code;
  double? _azn;

  CouponPartner? get _partner => CouponPartner.all[widget.reward.partnerId];

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  int get _ep => int.tryParse(_amount.text.trim()) ?? 0;

  Future<void> _create() async {
    final partner = _partner;
    if (partner == null || _busy) return;
    final balance = ref.read(balanceProvider).valueOrNull ?? 0;
    if (_ep < partner.minEp) {
      showEpToast(context, context.tr('coupon_min', {'n': partner.minEp}),
          kind: ToastKind.error);
      return;
    }
    if (_ep > balance) {
      showEpToast(context, context.tr('transfer_err_balance'),
          kind: ToastKind.error);
      return;
    }
    setState(() => _busy = true);
    try {
      final receipt = await ref.read(marketplaceRepositoryProvider).createCoupon(
            partnerId: partner.id,
            ep: _ep,
            requestId: _requestId,
          );
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _code = receipt.code;
        _azn = receipt.azn;
        // New key for any subsequent coupon.
        _requestId = newRequestId();
      });
    } on Failure catch (f) {
      if (mounted) {
        showEpToast(context, context.tr(f.l10nKey), kind: ToastKind.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    final partner = _partner;
    final balance = ref.watch(balanceProvider).valueOrNull ?? 0;

    if (partner == null) {
      return _sheetFrame(context, children: [
        Text(context.tr('error_generic')),
      ]);
    }

    if (_code != null) {
      return _sheetFrame(context, children: [
        Icon(Icons.verified_rounded, size: 48, color: c.emerald),
        const SizedBox(height: Sp.sm),
        Text(context.tr('coupon_ready'),
            textAlign: TextAlign.center, style: context.text.titleLarge),
        const SizedBox(height: Sp.lg),
        EpCard(
          color: c.surfaceRaised,
          child: Column(
            children: [
              Text(partner.name, style: context.text.titleMedium),
              const SizedBox(height: 4),
              Text(
                '${(_azn ?? 0).toStringAsFixed(2)} AZN',
                style: context.text.headlineMedium?.copyWith(color: c.lime),
              ),
              const SizedBox(height: Sp.sm),
              SelectableText(
                _code!,
                style: context.text.titleLarge?.copyWith(letterSpacing: 2),
              ),
              const SizedBox(height: Sp.xs),
              Text(context.tr('coupon_show'),
                  textAlign: TextAlign.center, style: context.text.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: Sp.md),
        EpButton(
          label: context.tr('copy'),
          icon: Icons.copy_rounded,
          kind: EpButtonKind.secondary,
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: _code!));
            if (context.mounted) {
              showEpToast(context, context.tr('copied'),
                  kind: ToastKind.success);
            }
          },
        ),
        const SizedBox(height: Sp.xs),
        EpButton(
          label: context.tr('done'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ]);
    }

    final ep = _ep;
    return _sheetFrame(context, children: [
      _RewardHeader(reward: widget.reward),
      const SizedBox(height: Sp.sm),
      Text(
        context.tr('coupon_sub', {'fee': partner.commissionPercent}),
        style: context.text.bodyMedium?.copyWith(color: c.textSecondary),
      ),
      const SizedBox(height: Sp.lg),
      EpTextField(
        label: context.tr('coupon_amount'),
        controller: _amount,
        hint: context.tr('coupon_min', {'n': partner.minEp}),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        prefixIcon: Icons.bolt_rounded,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: Sp.xs),
      Text(
        ep > 0
            ? context.tr('coupon_preview', {
                'ep': Fmt.number(ep),
                'azn': partner.aznFor(ep).toStringAsFixed(2),
                'fee': partner.feeFor(ep),
              })
            : context.tr('transfer_available', {'n': Fmt.number(balance)}),
        style: context.text.bodySmall,
      ),
      const SizedBox(height: Sp.lg),
      EpButton(
        label: context.tr('coupon_create'),
        loading: _busy,
        kind: EpButtonKind.accent,
        onPressed: _create,
      ),
    ]);
  }
}

/// BakıKart top-up request. Honest about its state: EP are reserved and a
/// request record is created; the transport partner completes the top-up.
class TransportSheet extends ConsumerStatefulWidget {
  const TransportSheet({super.key, required this.reward});
  final Reward reward;

  @override
  ConsumerState<TransportSheet> createState() => _TransportSheetState();
}

class _TransportSheetState extends ConsumerState<TransportSheet> {
  final _form = GlobalKey<FormState>();
  final _card = TextEditingController();
  final _amount = TextEditingController();
  final String _requestId = newRequestId();
  bool _busy = false;

  @override
  void dispose() {
    _card.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await ref.read(marketplaceRepositoryProvider).requestTransportTopUp(
            cardNumber: _card.text,
            ep: int.parse(_amount.text.trim()),
            requestId: _requestId,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      showEpToast(context, context.tr('transport_pending'),
          kind: ToastKind.success);
    } on Failure catch (f) {
      if (mounted) {
        showEpToast(context, context.tr(f.l10nKey), kind: ToastKind.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    final balance = ref.watch(balanceProvider).valueOrNull ?? 0;
    return _sheetFrame(context, children: [
      _RewardHeader(reward: widget.reward),
      const SizedBox(height: Sp.sm),
      Text(context.tr('transport_sub'),
          style: context.text.bodyMedium?.copyWith(color: c.textSecondary)),
      const SizedBox(height: Sp.lg),
      Form(
        key: _form,
        child: Column(
          children: [
            EpTextField(
              label: context.tr('transport_card'),
              controller: _card,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                LengthLimitingTextInputFormatter(19),
              ],
              prefixIcon: Icons.credit_card_rounded,
              validator: (v) {
                final k = Validators.cardNumber(v);
                return k == null ? null : context.tr(k);
              },
            ),
            const SizedBox(height: Sp.md),
            EpTextField(
              label: context.tr('transport_amount'),
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              prefixIcon: Icons.bolt_rounded,
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                if (n == null || n < 100) {
                  return context.tr('coupon_min', {'n': 100});
                }
                if (n > balance) return context.tr('transfer_err_balance');
                return null;
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: Sp.xs),
      Text(context.tr('transport_fee_note'), style: context.text.bodySmall),
      const SizedBox(height: Sp.lg),
      EpButton(
        label: context.tr('transport_submit'),
        loading: _busy,
        kind: EpButtonKind.accent,
        onPressed: _submit,
      ),
    ]);
  }
}
