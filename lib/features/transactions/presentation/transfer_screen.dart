import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failure.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/request_id.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/ep_avatar.dart';
import '../../../core/widgets/ep_button.dart';
import '../../../core/widgets/ep_card.dart';
import '../../../core/widgets/ep_feedback.dart';
import '../../../core/widgets/ep_text_field.dart';
import '../../wallet/data/wallet_providers.dart';
import '../../wallet/data/wallet_repository.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key, this.recipientUid});

  /// Pre-selected recipient (from a scanned friend QR).
  final String? recipientUid;

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _search = TextEditingController();
  final _amount = TextEditingController();
  Timer? _debounce;
  List<UserSummary> _results = const [];
  bool _searching = false;
  bool _searched = false;
  UserSummary? _recipient;
  String? _error;
  bool _busy = false;

  /// Idempotency key for the *current* transfer attempt; regenerated only
  /// after a transfer succeeds so retries can never double-send.
  String _requestId = newRequestId();

  @override
  void initState() {
    super.initState();
    final to = widget.recipientUid;
    if (to != null && to.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _preselect(to));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _preselect(String uid) async {
    setState(() => _searching = true);
    try {
      final found =
          await ref.read(walletRepositoryProvider).lookupUsers(uid);
      if (!mounted) return;
      if (found.isNotEmpty) {
        setState(() => _recipient = found.first);
      } else {
        setState(() => _error = context.tr('transfer_no_results'));
      }
    } on Failure catch (f) {
      if (mounted) setState(() => _error = context.tr(f.l10nKey));
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _onQuery(String q) {
    _debounce?.cancel();
    final query = q.trim();
    if (query.length < 2) {
      setState(() {
        _results = const [];
        _searched = false;
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final list = await ref.read(walletRepositoryProvider).lookupUsers(query);
        if (!mounted || _search.text.trim() != query) return;
        final me = ref.read(uidProvider);
        setState(() {
          _results = list.where((u) => u.uid != me).toList();
          _searched = true;
          _searching = false;
        });
      } on Failure catch (f) {
        if (!mounted) return;
        setState(() {
          _searching = false;
          _error = context.tr(f.l10nKey);
        });
      }
    });
  }

  Future<void> _review() async {
    if (_busy) return;
    final balance = ref.read(balanceProvider).valueOrNull ?? 0;
    final amount = int.tryParse(_amount.text.trim());
    final key = TransferValidator.validate(
      amount: amount,
      balance: balance,
      senderUid: ref.read(uidProvider),
      recipientUid: _recipient?.uid,
    );
    if (key != null) {
      setState(() => _error = context.tr(key, {'n': Fmt.number(AppConstants.maxTransferEp)}));
      return;
    }
    setState(() => _error = null);

    final recipient = _recipient!;
    final ok = await confirmSheet(
      context,
      title: context.tr('transfer_confirm_title'),
      body: context.tr('transfer_confirm_body',
          {'n': Fmt.number(amount!), 'name': recipient.name}),
      confirmLabel: context.tr('home_send'),
      icon: Icons.send_rounded,
    );
    if (!ok || !mounted) return;

    setState(() => _busy = true);
    try {
      final receipt = await ref.read(walletRepositoryProvider).transfer(
            recipientUid: recipient.uid,
            amount: amount,
            requestId: _requestId,
          );
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      _requestId = newRequestId();
      showEpToast(
        context,
        context.tr('transfer_success', {
          'n': Fmt.number(receipt.amount),
          'name': receipt.recipientName,
        }),
        kind: ToastKind.success,
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    } on Failure catch (f) {
      if (mounted) {
        setState(() => _error = context.tr(f.l10nKey,
            {'n': Fmt.number(AppConstants.maxTransferEp)}));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    final balance = ref.watch(balanceProvider).valueOrNull ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('transfer_title'))),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(Sp.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EpCard(
                color: c.surfaceRaised,
                child: Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: c.lime),
                    const SizedBox(width: Sp.xs),
                    Text(
                      context.tr('transfer_available',
                          {'n': Fmt.number(balance)}),
                      style: context.text.titleSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Sp.lg),
              Text(context.tr('transfer_recipient'),
                  style: context.text.titleSmall),
              const SizedBox(height: Sp.xs),
              if (_recipient != null)
                _RecipientCard(
                  user: _recipient!,
                  onClear: () => setState(() => _recipient = null),
                )
              else ...[
                EpTextField(
                  label: context.tr('transfer_search'),
                  controller: _search,
                  prefixIcon: Icons.search_rounded,
                  onChanged: _onQuery,
                  suffix: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          tooltip: context.tr('transfer_scan_friend'),
                          icon: const Icon(Icons.qr_code_scanner_rounded),
                          onPressed: () => context.push('/scan'),
                        ),
                ),
                const SizedBox(height: Sp.xs),
                if (_searched && _results.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(Sp.sm),
                    child: Text(context.tr('transfer_no_results'),
                        style: context.text.bodyMedium
                            ?.copyWith(color: c.textSecondary)),
                  ),
                for (final u in _results)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Sp.xs),
                    child: _RecipientCard(
                      user: u,
                      onTap: () => setState(() {
                        _recipient = u;
                        _results = const [];
                        _error = null;
                      }),
                    ),
                  ),
              ],
              const SizedBox(height: Sp.lg),
              EpTextField(
                label: context.tr('transfer_amount'),
                controller: _amount,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                prefixIcon: Icons.bolt_rounded,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() => _error = null),
                onSubmitted: (_) => _review(),
              ),
              const SizedBox(height: Sp.xs),
              Wrap(
                spacing: Sp.xs,
                children: [
                  for (final v in const [50, 100, 250, 500])
                    ActionChip(
                      label: Text('$v'),
                      onPressed: () =>
                          setState(() => _amount.text = '$v'),
                      backgroundColor: c.surface,
                      side: BorderSide(color: c.outline),
                      shape: const StadiumBorder(),
                    ),
                ],
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: Sp.sm),
                  child: Semantics(
                    liveRegion: true,
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 18, color: c.danger),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(_error!,
                              style: context.text.bodyMedium
                                  ?.copyWith(color: c.danger)),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: Sp.xl),
              EpButton(
                label: context.tr('transfer_send'),
                loading: _busy,
                onPressed: _review,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipientCard extends StatelessWidget {
  const _RecipientCard({required this.user, this.onTap, this.onClear});
  final UserSummary user;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    return EpCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
      borderColor: onClear != null ? c.emerald : null,
      child: Row(
        children: [
          EpAvatar(name: user.name, photoUrl: user.photoUrl, size: 40),
          const SizedBox(width: Sp.sm),
          Expanded(
            child: Text(user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleSmall),
          ),
          if (onClear != null)
            IconButton(
              tooltip: context.tr('close'),
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
            )
          else
            Icon(Icons.chevron_right_rounded, color: c.textTertiary),
        ],
      ),
    );
  }
}
