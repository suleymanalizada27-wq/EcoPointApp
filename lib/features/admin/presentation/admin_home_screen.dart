import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ep_card.dart';
import '../../../core/widgets/state_views.dart';
import '../data/admin_api.dart';

final adminOverviewProvider = FutureProvider.autoDispose<Map<String, Object?>>(
  (ref) => ref.watch(adminApiProvider).overview(),
);

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Admin paneli')),
      body: isAdmin.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e),
        data: (ok) {
          if (!ok) {
            return const EmptyView(
              icon: Icons.lock_outline_rounded,
              message: 'Bu hesabın admin icazəsi yoxdur. '
                  'Admin e-poçtu ilə Google vasitəsilə daxil olun.',
            );
          }
          return _Body();
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ov = ref.watch(adminOverviewProvider);
    final tiles = <(IconData, String, String)>[
      (Icons.insights_rounded, 'Statistika', '/admin/stats'),
      (Icons.people_alt_rounded, 'İstifadəçilər', '/admin/users'),
      (Icons.card_giftcard_rounded, 'Mükafatlar', '/admin/rewards'),
      (Icons.delete_outline_rounded, 'Qutular və QR', '/admin/bins'),
      (Icons.directions_bus_rounded, 'BakıKart sorğuları', '/admin/transport'),
      (Icons.local_offer_rounded, 'Kupon yoxlama', '/admin/coupons'),
      (Icons.campaign_rounded, 'Elan göndər', '/admin/broadcast'),
      (Icons.bug_report_rounded, 'Xəta jurnalı', '/admin/errors'),
    ];
    return RefreshIndicator(
      onRefresh: () async => ref.refresh(adminOverviewProvider.future),
      child: ListView(
        padding: const EdgeInsets.all(Sp.gutter),
        children: [
          ov.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(Sp.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text(adminErrorText(e)),
            data: (m) => EpCard(
              child: Column(children: [
                _stat('İstifadəçi', m['users']),
                _stat('Ümumi EP', m['totalEp']),
                _stat('Qutu', m['bins']),
                _stat('Gözləyən BakıKart', m['pendingTransport']),
                _stat('Xəta (24 saat)', m['errors24h']),
                _stat('Bildiriş alan cihaz', m['pushDevices']),
              ]),
            ),
          ),
          const SizedBox(height: Sp.md),
          for (final t in tiles) ...[
            EpCard(
              onTap: () => context.push(t.$3),
              child: Row(children: [
                Icon(t.$1, color: context.ep.emerald),
                const SizedBox(width: Sp.md),
                Expanded(child: Text(t.$2)),
                const Icon(Icons.chevron_right_rounded),
              ]),
            ),
            const SizedBox(height: Sp.sm),
          ],
        ],
      ),
    );
  }

  Widget _stat(String l, Object? v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(child: Text(l)),
          Text('${v ?? '—'}', style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      );
}
