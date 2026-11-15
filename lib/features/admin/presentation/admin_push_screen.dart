import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ep_card.dart';
import '../../../core/widgets/state_views.dart';
import '../data/admin_api.dart';
import 'admin_common.dart';

final adminPushStatsProvider =
    FutureProvider.autoDispose<Map<String, Object?>>(
        (ref) => ref.watch(adminApiProvider).pushStats());

const _kindNames = {
  'tip': 'Məsləhət',
  'recap': 'Günün xülasəsi',
  'mission': 'Missiya',
  'leaderboard': 'Reytinq',
  'milestone': 'Rekord',
  'bin': 'Qutu dolur',
};

/// Notification stats (last 14 days) and the master on/off switch.
class AdminPushScreen extends ConsumerWidget {
  const AdminPushScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(adminPushStatsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Bildiriş statistikası')),
      body: AsyncBody<Map<String, Object?>>(
        value: st,
        onRetry: () => ref.invalidate(adminPushStatsProvider),
        data: (m) {
          final disabled = m['disabled'] == true;
          final rows = (m['rows'] is List)
              ? [
                  for (final r in m['rows'] as List)
                    if (r is Map) Map<String, Object?>.from(r)
                ]
              : <Map<String, Object?>>[];
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(adminPushStatsProvider.future),
            child: ListView(padding: adminPad, children: [
              EpCard(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Avtomatik bildirişlər'),
                  subtitle: Text(disabled
                      ? 'Hamısı dayandırılıb.'
                      : 'Aktivdir (son ${m['days'] ?? 14} gün göstərilir).'),
                  value: !disabled,
                  onChanged: (v) async {
                    try {
                      await ref.read(adminApiProvider).setPushEnabled(v);
                      ref.invalidate(adminPushStatsProvider);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(adminErrorText(e))));
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: Sp.md),
              if (rows.isEmpty)
                const EmptyView(
                    icon: Icons.notifications_none_rounded,
                    message: 'Hələ statistika yoxdur.')
              else
                for (final r in rows) ...[
                  EpCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_kindNames['${r['kind']}'] ?? '${r['kind']}',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: Sp.xs),
                        AdminLine('Göndərilib', '${r['sent']}'),
                        AdminLine('Açılıb', '${r['opened']}'),
                        AdminLine('Açılma faizi',
                            '${(((r['rate'] as num?) ?? 0) * 100).round()}%'),
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
