import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ep_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../transactions/presentation/tx_widgets.dart';
import '../../wallet/data/wallet_providers.dart';
import '../../wallet/domain/activity_aggregator.dart';
import '../../wallet/domain/ep_transaction.dart';
import '../../wallet/domain/impact_estimator.dart';
import '../../share/presentation/share_card.dart';
import 'ep_bar_chart.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    final txs = ref.watch(transactionsProvider);
    final stats = ref.watch(statsProvider).valueOrNull;
    final level = ref.watch(levelProgressProvider);
    final impact = ref.watch(impactProvider);
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('stats_title')),
        actions: [
          IconButton(
            tooltip: context.tr('share'),
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => showShareCard(context),
          ),
        ],
      ),
      body: AsyncBody<List<EpTransaction>>(
        value: txs,
        onRetry: () => ref.invalidate(transactionsProvider),
        data: (list) {
          final buckets = ActivityAggregator.daily(list,
              days: _days, now: DateTime.now());
          final earned = ActivityAggregator.totalEarned(buckets);
          final spent = ActivityAggregator.totalSpent(buckets);

          return ListView(
            padding: const EdgeInsets.fromLTRB(
                Sp.gutter, 0, Sp.gutter, Sp.xxl),
            children: [
              // Lifetime tiles (server-maintained counters).
              Row(
                children: [
                  Expanded(
                    child: _Tile(
                      label: context.tr('home_earned'),
                      value: Fmt.number(stats?.earned ?? 0),
                      caption: context.tr('stats_lifetime'),
                      color: c.emerald,
                    ),
                  ),
                  const SizedBox(width: Sp.xs),
                  Expanded(
                    child: _Tile(
                      label: context.tr('stats_total_scans'),
                      value: Fmt.number(stats?.scans ?? 0),
                      caption: context.tr('stats_lifetime'),
                      color: c.lime,
                    ),
                  ),
                  const SizedBox(width: Sp.xs),
                  Expanded(
                    child: _Tile(
                      label: context.tr('home_sent'),
                      value: Fmt.number(stats?.sent ?? 0),
                      caption: context.tr('stats_lifetime'),
                      color: c.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Sp.lg),
              EpCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(context.tr('stats_activity'),
                              style: context.text.titleMedium),
                        ),
                        SegmentedButton<int>(
                          showSelectedIcon: false,
                          style: SegmentedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          segments: [
                            ButtonSegment(
                                value: 7,
                                label: Text(context.tr('stats_week'))),
                            ButtonSegment(
                                value: 30,
                                label: Text(context.tr('stats_month'))),
                          ],
                          selected: {_days},
                          onSelectionChanged: (s) =>
                              setState(() => _days = s.first),
                        ),
                      ],
                    ),
                    const SizedBox(height: Sp.md),
                    Row(
                      children: [
                        _Legend(
                            color: c.emerald,
                            label:
                                '${context.tr('stats_earned_period')} ${Fmt.number(earned)}'),
                        const SizedBox(width: Sp.md),
                        _Legend(
                            color: c.info,
                            label:
                                '${context.tr('stats_spent_period')} ${Fmt.number(spent)}'),
                      ],
                    ),
                    const SizedBox(height: Sp.md),
                    if (earned == 0 && spent == 0)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: Sp.xl),
                        child: Center(
                          child: Text(context.tr('home_no_activity'),
                              style: context.text.bodyMedium
                                  ?.copyWith(color: c.textSecondary)),
                        ),
                      )
                    else
                      EpBarChart(
                        buckets: buckets,
                        locale: locale,
                        showSpent: _days == 7,
                      ),
                    const SizedBox(height: Sp.xs),
                    Text(
                      context.tr('stats_limit_note',
                          {'n': AppConstants.txWindow}),
                      style: context.text.bodySmall
                          ?.copyWith(color: c.textTertiary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Sp.md),
              EpCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(context.tr('stats_level'),
                            style: context.text.titleMedium),
                        const Spacer(),
                        EpBadge(
                          label: context.tr(level.current.l10nKey),
                          color: c.lime,
                        ),
                      ],
                    ),
                    const SizedBox(height: Sp.sm),
                    EpProgressBar(value: level.fraction, color: c.lime),
                    const SizedBox(height: 6),
                    Text(
                      level.isMax
                          ? context.tr('home_level_max')
                          : context.tr('home_level_progress', {
                              'cur': Fmt.number(level.earned),
                              'next': Fmt.number(level.next!.minEarned),
                            }),
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Sp.md),
              ImpactCard(impact: impact, title: context.tr('stats_impact_title')),
              const SizedBox(height: Sp.xs),
              Text(context.tr('stats_impact_disclaimer'),
                  style: context.text.bodySmall
                      ?.copyWith(color: c.textTertiary)),
              SectionHeader(
                title: context.tr('stats_recent'),
                padding: const EdgeInsets.only(top: Sp.xl, bottom: Sp.sm),
              ),
              if (list.isEmpty)
                EmptyView(
                  icon: Icons.receipt_long_outlined,
                  message: context.tr('history_empty'),
                )
              else
                for (final t in list.take(8))
                  Padding(
                    padding: const EdgeInsets.only(bottom: Sp.xs),
                    child: TxTile(tx: t),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
  });
  final String label;
  final String value;
  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return EpCard(
      padding: const EdgeInsets.all(Sp.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: Sp.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: context.text.headlineSmall),
          ),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall),
          Text(caption,
              style: context.text.labelSmall
                  ?.copyWith(color: context.ep.textTertiary)),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: context.text.bodySmall),
      ],
    );
  }
}

/// Environmental impact, always labelled as an estimate.
class ImpactCard extends StatelessWidget {
  const ImpactCard({super.key, required this.impact, required this.title});
  final ImpactEstimate impact;
  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    Widget cell(IconData icon, Color color, String value, String unit,
        String label) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(TextSpan(children: [
                TextSpan(text: value, style: context.text.titleLarge),
                TextSpan(
                    text: ' $unit',
                    style: context.text.bodySmall
                        ?.copyWith(color: c.textSecondary)),
              ])),
            ),
            Text(label,
                maxLines: 2,
                style: context.text.bodySmall),
          ],
        ),
      );
    }

    return EpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(title, style: context.text.titleMedium)),
              EpBadge(
                  label: context.tr('estimate_tag'),
                  color: c.warning,
                  icon: Icons.calculate_outlined),
            ],
          ),
          const SizedBox(height: Sp.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              cell(Icons.recycling_rounded, c.emerald,
                  Fmt.number(impact.plasticGrams), context.tr('unit_g'),
                  context.tr('impact_plastic')),
              const SizedBox(width: Sp.sm),
              cell(Icons.cloud_outlined, c.info,
                  Fmt.number(impact.co2Grams), context.tr('unit_g'),
                  context.tr('impact_co2')),
            ],
          ),
          const SizedBox(height: Sp.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              cell(Icons.water_drop_outlined, c.info,
                  Fmt.number(impact.waterLiters), context.tr('unit_l'),
                  context.tr('impact_water')),
              const SizedBox(width: Sp.sm),
              cell(Icons.bolt_rounded, c.warning,
                  Fmt.number(impact.energyWh), context.tr('unit_wh'),
                  context.tr('impact_energy')),
            ],
          ),
        ],
      ),
    );
  }
}
