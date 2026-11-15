import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/services/preferences.dart';
import '../../../core/widgets/ep_card.dart';
import '../../challenges/data/gamification_repository.dart';
import '../../wallet/data/wallet_providers.dart';

/// "First steps" checklist for new people. Every tick comes from real data
/// (a check-in, a deposit, a purchase); it disappears when finished or hidden.
class FirstStepsCard extends ConsumerStatefulWidget {
  const FirstStepsCard({super.key});

  @override
  ConsumerState<FirstStepsCard> createState() => _FirstStepsCardState();
}

class _FirstStepsCardState extends ConsumerState<FirstStepsCard> {
  bool _hidden = false;

  @override
  void initState() {
    super.initState();
    try {
      _hidden = ref
              .read(sharedPrefsProvider)
              .getBool(PrefKeys.firstStepsHidden) ??
          false;
    } catch (_) {
      _hidden = false;
    }
  }

  Future<void> _hide() async {
    setState(() => _hidden = true);
    try {
      await ref
          .read(sharedPrefsProvider)
          .setBool(PrefKeys.firstStepsHidden, true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_hidden) return const SizedBox.shrink();
    final stats = ref.watch(statsProvider).valueOrNull;
    final streak = ref.watch(streakProvider).valueOrNull;
    if (stats == null || streak == null) return const SizedBox.shrink();

    final steps = <_Step>[
      _Step('first_steps_checkin', streak.count > 0 || streak.history.isNotEmpty,
          '/challenges'),
      _Step('first_steps_scan', stats.scans > 0, '/scan'),
      _Step('first_steps_reward', stats.spent > 0, '/rewards'),
    ];
    final done = steps.where((s) => s.done).length;
    if (done == steps.length) return const SizedBox.shrink();

    final c = context.ep;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.gutter, Sp.md, Sp.gutter, 0),
      child: EpCard(
        semanticLabel: context.tr('first_steps_title'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(context.tr('first_steps_title'),
                      style: context.text.titleMedium),
                ),
                Text('$done/${steps.length}',
                    style: context.text.labelLarge?.copyWith(color: c.emerald)),
                IconButton(
                  tooltip: context.tr('first_steps_hide'),
                  onPressed: _hide,
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: Sp.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: done / steps.length,
                minHeight: 6,
                color: c.emerald,
                backgroundColor: c.outline,
              ),
            ),
            const SizedBox(height: Sp.xs),
            for (final s in steps)
              InkWell(
                onTap: s.done
                    ? null
                    : () => s.route == '/rewards'
                        ? context.go(s.route)
                        : context.push(s.route),
                borderRadius: BorderRadius.circular(10),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(
                    children: [
                      Icon(
                        s.done
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: s.done ? c.emerald : c.textTertiary,
                      ),
                      const SizedBox(width: Sp.sm),
                      Expanded(
                        child: Text(
                          context.tr(s.key),
                          style: context.text.bodyMedium?.copyWith(
                            decoration:
                                s.done ? TextDecoration.lineThrough : null,
                            color: s.done ? c.textTertiary : c.textPrimary,
                          ),
                        ),
                      ),
                      if (!s.done)
                        Icon(Icons.chevron_right_rounded, color: c.textTertiary),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Step {
  const _Step(this.key, this.done, this.route);
  final String key;
  final bool done;
  final String route;
}
