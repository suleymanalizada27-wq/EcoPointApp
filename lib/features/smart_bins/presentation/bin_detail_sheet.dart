import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/errors/failure.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ep_button.dart';
import '../../../core/widgets/ep_card.dart';
import '../../../core/widgets/ep_feedback.dart';
import '../data/bins_repository.dart';
import '../domain/smart_bin.dart';
import 'bin_navigation.dart';
import 'bins_screen.dart' show fillColor;

void showBinDetail(BuildContext context, SmartBin bin) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BinDetailSheet(binId: bin.id, initial: bin),
  );
}

/// Live bin details. Re-reads the bin from the stream so fill level and
/// scale reading stay current while the sheet is open.
class BinDetailSheet extends ConsumerStatefulWidget {
  const BinDetailSheet({super.key, required this.binId, required this.initial});
  final String binId;
  final SmartBin initial;

  @override
  ConsumerState<BinDetailSheet> createState() => _BinDetailSheetState();
}

class _BinDetailSheetState extends ConsumerState<BinDetailSheet> {
  bool _busy = false;

  Future<void> _redeem() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ep = await ref
          .read(binsRepositoryProvider)
          .redeemWeight(widget.binId);
      if (!mounted) return;
      showEpToast(context, context.tr('bins_redeemed', {'n': ep}),
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
    final live = ref.watch(binsProvider).valueOrNull;
    SmartBin bin = widget.initial;
    if (live != null) {
      for (final b in live) {
        if (b.id == widget.binId) bin = b;
      }
    }
    final now = DateTime.now();
    final online = bin.isOnline(now);
    final tone = fillColor(c, bin.fillPercent);
    final location = ref.watch(locationProvider).valueOrNull;
    final dist = location?.distanceTo(bin);

    String lastSeenText() {
      final seen = bin.lastSeen;
      if (seen == null) return context.tr('bins_never_seen');
      final rel = RelativeTime.since(seen, now);
      return context.tr('bins_last_seen',
          {'t': context.tr(rel.l10nKey, {'n': rel.value})});
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Sp.gutter, 0, Sp.gutter, Sp.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconTile(icon: Icons.recycling_rounded, color: tone, size: 56),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(bin.name, style: context.text.titleLarge),
                        if (bin.locationText.isNotEmpty)
                          Text(bin.locationText,
                              style: context.text.bodyMedium),
                      ],
                    ),
                  ),
                  EpBadge(
                    label: online
                        ? context.tr('bins_online')
                        : context.tr('bins_offline'),
                    color: online ? c.emerald : c.textTertiary,
                  ),
                ],
              ),
              const SizedBox(height: Sp.lg),
              EpCard(
                color: c.surfaceRaised,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(context.tr('bins_fill'),
                            style: context.text.bodyMedium),
                        const Spacer(),
                        Text('${bin.fillPercent}%',
                            style: context.text.titleMedium
                                ?.copyWith(color: tone)),
                      ],
                    ),
                    const SizedBox(height: Sp.xs),
                    EpProgressBar(
                        value: bin.fillPercent / 100, color: tone, height: 10),
                    if (bin.isNearlyFull) ...[
                      const SizedBox(height: Sp.xs),
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 16, color: c.danger),
                          const SizedBox(width: 6),
                          Text(context.tr('bins_full_warning'),
                              style: context.text.bodySmall
                                  ?.copyWith(color: c.danger)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: Sp.sm),
              Row(
                children: [
                  if (bin.temperature != null)
                    Expanded(
                      child: _Stat(
                        label: context.tr('bins_temp'),
                        value: '${bin.temperature!.toStringAsFixed(0)}°C',
                      ),
                    ),
                  if (bin.temperature != null && bin.weightGrams != null)
                    const SizedBox(width: Sp.sm),
                  if (bin.weightGrams != null)
                    Expanded(
                      child: _Stat(
                        label: context.tr('bins_weight'),
                        value:
                            '${Fmt.number(bin.weightGrams!)} ${context.tr('unit_g')}',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: Sp.sm),
              Text(
                [
                  lastSeenText(),
                  if (dist != null)
                    context.tr('bins_distance', {'d': Fmt.distance(dist)}),
                ].join(' · '),
                style: context.text.bodySmall,
              ),
              if (bin.hasCoordinates) ...[
                const SizedBox(height: Sp.md),
                EpButton(
                  label: context.tr('bins_directions'),
                  icon: Icons.directions_walk_rounded,
                  kind: EpButtonKind.secondary,
                  onPressed: () => openDirections(context, bin),
                ),
              ],
              if (online && bin.supportsWeightRedeem) ...[
                const SizedBox(height: Sp.lg),
                Text(context.tr('bins_redeem_hint'),
                    style: context.text.bodySmall),
                const SizedBox(height: Sp.sm),
                EpButton(
                  label: context.tr('bins_redeem_weight'),
                  icon: Icons.scale_rounded,
                  kind: EpButtonKind.accent,
                  loading: _busy,
                  onPressed: _redeem,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return EpCard(
      color: context.ep.surfaceRaised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text.bodySmall),
          const SizedBox(height: 2),
          Text(value, style: context.text.titleMedium),
        ],
      ),
    );
  }
}
