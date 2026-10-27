import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ep_button.dart';
import '../../../core/widgets/ep_card.dart';
import '../../../core/widgets/ep_feedback.dart';
import '../../../core/widgets/ep_text_field.dart';
import '../../../core/widgets/state_views.dart';
import '../data/admin_api.dart';
import 'admin_common.dart';

// ───────────────────────── BakıKart requests ─────────────────────────

final adminTransportProvider =
    FutureProvider.autoDispose<List<Map<String, Object?>>>(
  (ref) => ref.watch(adminApiProvider).transport(),
);

class AdminTransportScreen extends ConsumerWidget {
  const AdminTransportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(adminTransportProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('BakıKart sorğuları')),
      body: AsyncBody<List<Map<String, Object?>>>(
        value: list,
        onRetry: () => ref.invalidate(adminTransportProvider),
        data: (rows) {
          if (rows.isEmpty) {
            return const EmptyView(
                icon: Icons.check_circle_outline_rounded,
                message: 'Gözləyən sorğu yoxdur.');
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(adminTransportProvider.future),
            child: ListView(padding: adminPad, children: [
              for (final r in rows) ...[
                EpCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AdminLine('Kart', '${r['card']}'),
                      AdminLine('EP', '${r['ep']} (xalis ${r['netEp']}, komissiya ${r['fee']})'),
                      AdminLine('İstifadəçi', '${r['uid']}'),
                      AdminLine('Vaxt', fmtTs(r['ts'])),
                      const SizedBox(height: Sp.sm),
                      Row(children: [
                        Expanded(
                          child: EpButton(
                            label: 'Təsdiq (yükləndi)',
                            onPressed: () => _resolve(context, ref, r, true),
                          ),
                        ),
                        const SizedBox(width: Sp.sm),
                        Expanded(
                          child: EpButton(
                            label: 'Rədd',
                            kind: EpButtonKind.danger,
                            onPressed: () => _resolve(context, ref, r, false),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: Sp.sm),
              ],
            ]),
          );
        },
      ),
    );
  }

  Future<void> _resolve(BuildContext context, WidgetRef ref,
      Map<String, Object?> r, bool approve) async {
    final yes = await confirmSheet(context,
        title: approve ? 'Təsdiq et' : 'Rədd et',
        body: approve
            ? 'Kartı əl ilə yüklədiyinizi təsdiq edirsiniz.'
            : 'EP istifadəçiyə qaytarılacaq.',
        confirmLabel: 'Bəli',
        destructive: !approve);
    if (!yes || !context.mounted) return;
    final ok = await runAdmin(context,
        () => ref.read(adminApiProvider).resolveTransport('${r['id']}', approve));
    if (ok) ref.invalidate(adminTransportProvider);
  }
}

// ───────────────────────── coupons ─────────────────────────

class AdminCouponsScreen extends ConsumerStatefulWidget {
  const AdminCouponsScreen({super.key});
  @override
  ConsumerState<AdminCouponsScreen> createState() => _CouponState();
}

class _CouponState extends ConsumerState<AdminCouponsScreen> {
  final _code = TextEditingController();
  Map<String, Object?>? _info;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    setState(() => _busy = true);
    try {
      final r = await ref.read(adminApiProvider).lookupCoupon(_code.text.trim());
      if (mounted) setState(() => _info = r);
    } catch (e) {
      if (mounted) {
        setState(() => _info = null);
        showEpToast(context, adminErrorText(e), kind: ToastKind.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _redeem() async {
    final yes = await confirmSheet(context,
        title: 'İstifadə edildi',
        body: 'Kupon bir dəfə istifadə olunmuş kimi qeyd ediləcək.',
        confirmLabel: 'Təsdiq et');
    if (!yes || !mounted) return;
    final ok = await runAdmin(
        context, () => ref.read(adminApiProvider).redeemCoupon(_code.text.trim()));
    if (ok) await _lookup();
  }

  @override
  Widget build(BuildContext context) {
    final i = _info;
    return Scaffold(
      appBar: AppBar(title: const Text('Kupon yoxlama')),
      body: ListView(padding: adminPad, children: [
        EpTextField(
          label: 'Kupon kodu (məs. BRA-AB12CD)',
          controller: _code,
          textCapitalization: TextCapitalization.characters,
          onSubmitted: (_) => _lookup(),
        ),
        const SizedBox(height: Sp.sm),
        EpButton(label: 'Yoxla', onPressed: _lookup, loading: _busy),
        if (i != null) ...[
          const SizedBox(height: Sp.md),
          EpCard(
            child: Column(children: [
              AdminLine('Kod', '${i['code']}'),
              AdminLine('Tərəfdaş', '${i['partnerId']}'),
              AdminLine('Dəyər', '${i['azn']} AZN (${i['ep']} EP)'),
              AdminLine('Sahib', '${i['owner']}'),
              AdminLine('Tarix', fmtTs(i['ts'])),
              AdminLine('Status',
                  i['status'] == 'issued' ? 'Etibarlı (istifadə olunmayıb)' : '${i['status']}'),
            ]),
          ),
          if (i['status'] == 'issued') ...[
            const SizedBox(height: Sp.md),
            EpButton(label: 'İstifadə edildi kimi qeyd et', onPressed: _redeem),
          ],
        ],
      ]),
    );
  }
}

// ───────────────────────── broadcast ─────────────────────────

class AdminBroadcastScreen extends ConsumerStatefulWidget {
  const AdminBroadcastScreen({super.key});
  @override
  ConsumerState<AdminBroadcastScreen> createState() => _BroadcastState();
}

class _BroadcastState extends ConsumerState<AdminBroadcastScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
      showEpToast(context, 'Başlıq və mətn yazın', kind: ToastKind.error);
      return;
    }
    final yes = await confirmSheet(context,
        title: 'Hamıya göndər',
        body: 'Elan bütün istifadəçilərə (bildiriş və daxili qutu) göndəriləcək.',
        confirmLabel: 'Göndər');
    if (!yes || !mounted) return;
    setState(() => _busy = true);
    final ok = await runAdmin(
        context,
        () => ref
            .read(adminApiProvider)
            .broadcast(_title.text.trim(), _body.text.trim()),
        ok: 'Göndərildi');
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      _title.clear();
      _body.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Elan göndər')),
      body: ListView(padding: adminPad, children: [
        EpTextField(label: 'Başlıq', controller: _title, maxLength: 80),
        const SizedBox(height: Sp.sm),
        EpTextField(label: 'Mətn', controller: _body, maxLines: 4, maxLength: 240),
        const SizedBox(height: Sp.md),
        EpButton(label: 'Göndər', onPressed: _send, loading: _busy),
      ]),
    );
  }
}

// ───────────────────────── error log ─────────────────────────

final adminErrorsProvider =
    FutureProvider.autoDispose<List<Map<String, Object?>>>(
  (ref) => ref.watch(adminApiProvider).errors(),
);

class AdminErrorsScreen extends ConsumerWidget {
  const AdminErrorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(adminErrorsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Xəta jurnalı')),
      body: AsyncBody<List<Map<String, Object?>>>(
        value: list,
        onRetry: () => ref.invalidate(adminErrorsProvider),
        data: (rows) {
          if (rows.isEmpty) {
            return const EmptyView(
                icon: Icons.verified_outlined, message: 'Xəta qeydi yoxdur.');
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(adminErrorsProvider.future),
            child: ListView(padding: adminPad, children: [
              for (final e in rows) ...[
                EpCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${e['message']}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('${fmtTs(e['ts'])} · ${e['platform']} · v${e['app']}'),
                      if ('${e['stack'] ?? ''}'.isNotEmpty)
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: const Text('Stack'),
                          children: [SelectableText('${e['stack']}')],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: Sp.sm),
              ],
            ]),
          );
        },
      ),
    );
  }
}
