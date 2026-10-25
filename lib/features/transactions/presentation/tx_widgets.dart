import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ep_card.dart';
import '../../wallet/domain/ep_transaction.dart';

IconData txIcon(TxType t) => switch (t) {
      TxType.earn => Icons.recycling_rounded,
      TxType.received => Icons.south_west_rounded,
      TxType.sent => Icons.north_east_rounded,
      TxType.purchase => Icons.shopping_bag_rounded,
      TxType.weight => Icons.scale_rounded,
      TxType.bonus => Icons.auto_awesome_rounded,
      TxType.other => Icons.swap_horiz_rounded,
    };

String txLabelKey(TxType t) => switch (t) {
      TxType.earn => 'tx_earn',
      TxType.received => 'tx_received',
      TxType.sent => 'tx_sent',
      TxType.purchase => 'tx_purchase',
      TxType.weight => 'tx_weight',
      TxType.bonus => 'tx_bonus',
      TxType.other => 'tx_other',
    };

/// Removes the leading emoji the legacy app put in descriptions
/// ("♻️ QR Skan" → "QR Skan") so lists look clean.
String cleanDescription(String raw) {
  var s = raw.trim();
  // Strip leading non-letter/number symbols (emoji, arrows) and spaces.
  final m = RegExp(r'^[^\p{L}\p{N}]+', unicode: true).firstMatch(s);
  if (m != null) s = s.substring(m.end);
  return s;
}

class TxTile extends StatelessWidget {
  const TxTile({super.key, required this.tx});
  final EpTransaction tx;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    final locale = Localizations.localeOf(context).languageCode;
    final credit = tx.isCredit;
    final tone = credit ? c.emerald : c.textPrimary;
    final desc = cleanDescription(tx.description);

    return EpCard(
      padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
      semanticLabel:
          '${context.tr(txLabelKey(tx.type))}, ${Fmt.signed(tx.delta, locale)} ${context.tr('ep_unit')}',
      child: Row(
        children: [
          IconTile(
            icon: txIcon(tx.type),
            color: credit ? c.emerald : c.info,
            size: 42,
          ),
          const SizedBox(width: Sp.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr(txLabelKey(tx.type)),
                    style: context.text.titleSmall),
                if (desc.isNotEmpty)
                  Text(desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall),
                Text(Fmt.dateTime(tx.time, locale),
                    style: context.text.bodySmall
                        ?.copyWith(color: c.textTertiary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Fmt.signed(tx.delta, locale),
                style: context.text.titleMedium?.copyWith(color: tone),
              ),
              if (tx.status != TxStatus.completed)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: EpBadge(
                    label: tx.status == TxStatus.pending
                        ? context.tr('tx_status_pending')
                        : context.tr('tx_status_failed'),
                    color: tx.status == TxStatus.pending ? c.warning : c.danger,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
