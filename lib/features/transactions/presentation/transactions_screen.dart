import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/state_views.dart';
import '../../wallet/data/wallet_providers.dart';
import '../../wallet/domain/ep_transaction.dart';
import 'tx_widgets.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  TxType? _filter;

  static const _filters = <TxType?>[
    null,
    TxType.earn,
    TxType.received,
    TxType.sent,
    TxType.purchase,
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    final txs = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('history_title'))),
      body: Column(
        children: [
          const OfflineBanner(),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Sp.gutter),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: Sp.xs),
              itemBuilder: (context, i) {
                final f = _filters[i];
                final selected = _filter == f;
                final label = f == null
                    ? context.tr('tx_filter_all')
                    : context.tr(txLabelKey(f));
                return Center(
                  child: ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = f),
                    showCheckmark: false,
                    selectedColor: c.emerald.withValues(alpha: 0.2),
                    backgroundColor: c.surface,
                    side: BorderSide(
                        color: selected ? c.emerald : c.outline),
                    labelStyle: context.text.labelMedium?.copyWith(
                        color: selected ? c.emerald : c.textSecondary),
                    shape: const StadiumBorder(),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: AsyncBody<List<EpTransaction>>(
              value: txs,
              onRetry: () => ref.invalidate(transactionsProvider),
              data: (all) {
                final list = _filter == null
                    ? all
                    : all.where((t) => t.type == _filter).toList();
                if (list.isEmpty) {
                  return EmptyView(
                    icon: Icons.receipt_long_outlined,
                    message: context.tr('history_empty'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                      Sp.gutter, Sp.sm, Sp.gutter, Sp.xxl),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: Sp.xs),
                  itemBuilder: (context, i) => TxTile(tx: list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
