import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failure.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ep_button.dart';
import '../../../core/widgets/ep_card.dart';
import '../../../core/widgets/ep_feedback.dart';
import '../data/gamification_repository.dart';
import '../domain/gamification.dart';

/// Streak summary with a 7-day dot row and a check-in button.
class StreakCard extends ConsumerStatefulWidget {
  const StreakCard({super.key});

  @override
  ConsumerState<StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends ConsumerState<StreakCard> {
  bool _busy = false;

  Future<void> _checkIn() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final r = await ref.read(gamificationRepositoryProvider).checkIn();
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      showEpToast(
        context,
        r.bonus > 0
            ? context.tr('streak_bonus_success', {'n': r.bonus})
            : context.tr('streak_checkin_success', {'n': r.streak}),
        kind: ToastKind.success,
      );
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
    final streak = ref.watch(streakProvider).valueOrNull ?? StreakState.empty;
    final now = DateTime.now();
    final today = Fmt.dayKey(now);
    final done = streak.checkedInOn(today);
    final locale = Localizations.localeOf(context).languageCode;

    // Last 7 days, oldest → today; a dot is lit if that day was a check-in.
    final days = List<DateTime>.generate(
        7, (i) => now.subtract(Duration(days: 6 - i)));
    final hist = streak.history.toSet();

    return EpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(
                icon: Icons.local_fire_department_rounded,
                color: c.warning,
              ),
              const SizedBox(width: Sp.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('streak_title'),
                        style: context.text.titleSmall),
                    Text(
                      context.tr('streak_bonus_note',
                          {'n': AppConstants.streakBonusEp}),
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                context.tr('home_streak_days', {'n': streak.count}),
                style: context.text.titleLarge?.copyWith(color: c.warning),
              ),
            ],
          ),
          const SizedBox(height: Sp.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final d in days)
                _Dot(
                  label: _firstLetter(Fmt.weekdayShort(d, locale)),
                  lit: hist.contains(Fmt.dayKey(d)),
                  isToday: Fmt.dayKey(d) == today,
                ),
            ],
          ),
          const SizedBox(height: Sp.md),
          EpButton(
            label: done
                ? context.tr('home_streak_done')
                : context.tr('home_streak_checkin'),
            kind: done ? EpButtonKind.secondary : EpButtonKind.accent,
            icon: done ? Icons.check_rounded : Icons.bolt_rounded,
            loading: _busy,
            onPressed: done ? null : _checkIn,
          ),
        ],
      ),
    );
  }
}

String _firstLetter(String s) =>
    s.isEmpty ? '' : String.fromCharCode(s.runes.first).toUpperCase();

class _Dot extends StatelessWidget {
  const _Dot({required this.label, required this.lit, required this.isToday});
  final String label;
  final bool lit;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    return Column(
      children: [
        AnimatedContainer(
          duration: Motion.base,
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: lit ? c.warning : c.surfaceRaised,
            border: Border.all(
              color: isToday ? c.lime : Colors.transparent,
              width: 2,
            ),
          ),
          child: lit
              ? Icon(Icons.check_rounded,
                  size: 18, color: c.onLime)
              : null,
        ),
        const SizedBox(height: 4),
        Text(label, style: context.text.labelSmall?.copyWith(color: c.textTertiary)),
      ],
    );
  }
}

/// One mission row with progress and claim button.
class MissionTile extends ConsumerStatefulWidget {
  const MissionTile({super.key, required this.mission});
  final MissionProgress mission;

  @override
  ConsumerState<MissionTile> createState() => _MissionTileState();
}

class _MissionTileState extends ConsumerState<MissionTile> {
  bool _busy = false;

  Future<void> _claim() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ep = await ref
          .read(gamificationRepositoryProvider)
          .claimMission(widget.mission.def.id);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      showEpToast(context, context.tr('ch_claim_success', {'n': ep}),
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
    final m = widget.mission;
    final tone = m.claimed ? c.textTertiary : c.emerald;

    return EpCard(
      padding: const EdgeInsets.all(Sp.md),
      child: Row(
        children: [
          IconTile(icon: m.def.icon, color: tone),
          const SizedBox(width: Sp.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr(m.def.titleKey),
                    style: context.text.titleSmall),
                const SizedBox(height: 2),
                Text(
                  '${context.tr('ch_progress', {'a': m.shown, 'b': m.def.goal})} · +${m.def.ep} ${context.tr('ep_unit')}',
                  style: context.text.bodySmall,
                ),
                const SizedBox(height: 8),
                EpProgressBar(value: m.fraction, color: tone, height: 6),
              ],
            ),
          ),
          const SizedBox(width: Sp.sm),
          if (m.claimed)
            EpBadge(label: context.tr('ch_claimed'), color: c.textTertiary)
          else if (m.claimable)
            EpButton(
              label: context.tr('ch_claim'),
              expand: false,
              kind: EpButtonKind.accent,
              loading: _busy,
              onPressed: _claim,
            ),
        ],
      ),
    );
  }
}
