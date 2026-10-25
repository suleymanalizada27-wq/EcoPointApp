import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ep_card.dart';
import '../../../core/widgets/state_views.dart';
import '../data/marketplace_repository.dart';

class PurchaseHistoryScreen extends ConsumerWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.ep;
    final purchases = ref.watch(purchasesProvider);
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('reward_history'))),
      body: AsyncBody<List<PurchaseRecord>>(
        value: purchases,
        onRetry: () => ref.invalidate(purchasesProvider),
        data: (list) {
          if (list.isEmpty) {
            return EmptyView(
              icon: Icons.shopping_bag_outlined,
              message: context.tr('reward_history_empty'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(Sp.gutter),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: Sp.xs),
            itemBuilder: (context, i) {
              final p = list[i];
              return EpCard(
                child: Row(
                  children: [
                    IconTile(
                      icon: p.code != null
                          ? Icons.confirmation_number_rounded
                          : Icons.shopping_bag_rounded,
                    ),
                    const SizedBox(width: Sp.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.titleSmall),
                          const SizedBox(height: 2),
                          Text(Fmt.dateTime(p.time, locale),
                              style: context.text.bodySmall),
                          if (p.code != null)
                            SelectableText(p.code!,
                                style: context.text.labelMedium
                                    ?.copyWith(color: c.emerald)),
                          if (p.status == 'pending')
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: EpBadge(
                                label: context.tr('tx_status_pending'),
                                color: c.warning,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '−${Fmt.number(p.ep)} ${context.tr('ep_unit')}',
                      style: context.text.titleSmall
                          ?.copyWith(color: c.textPrimary),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
