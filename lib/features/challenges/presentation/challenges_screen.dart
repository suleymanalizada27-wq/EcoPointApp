import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ep_card.dart';
import '../data/gamification_repository.dart';
import '../domain/gamification.dart';
import 'challenge_widgets.dart';

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missions = ref.watch(missionsProvider);
    final monthly = ref.watch(monthlyMissionsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('ch_title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Sp.gutter, 0, Sp.gutter, Sp.xxl),
        children: [
          const StreakCard(),
          SectionHeader(
            title: context.tr('ch_daily'),
            padding: const EdgeInsets.only(top: Sp.xl, bottom: Sp.sm),
          ),
          for (final m in missions)
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.xs),
              child: MissionTile(mission: m),
            ),
          SectionHeader(
            title: context.tr('ch_monthly'),
            padding: const EdgeInsets.only(top: Sp.xl, bottom: Sp.sm),
          ),
          for (final m in monthly)
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.xs),
              child: MissionTile(mission: m),
            ),
          Padding(
            padding: const EdgeInsets.only(top: Sp.md),
            child: Text(context.tr('ch_weekly_prize'),
                style: context.text.bodySmall),
          ),
        ],
      ),
    );
  }
}

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.ep;
    final unlocked = ref.watch(unlockedAchievementsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('ach_title'))),
      body: GridView.builder(
        padding: const EdgeInsets.all(Sp.gutter),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          mainAxisSpacing: Sp.sm,
          crossAxisSpacing: Sp.sm,
          mainAxisExtent: 168,
        ),
        itemCount: AchievementDef.all.length,
        itemBuilder: (context, i) {
          final a = AchievementDef.all[i];
          final on = unlocked.contains(a.id);
          return EpCard(
            borderColor: on ? c.emerald.withValues(alpha: 0.6) : null,
            semanticLabel:
                '${context.tr(a.titleKey)}, ${on ? context.tr('ach_unlocked') : context.tr('ach_locked')}',
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: on
                        ? c.emerald.withValues(alpha: 0.16)
                        : c.surfaceRaised,
                  ),
                  child: Icon(
                    on ? a.icon : Icons.lock_outline_rounded,
                    color: on ? c.emerald : c.textTertiary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: Sp.sm),
                Text(context.tr(a.titleKey),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: context.text.titleSmall?.copyWith(
                        color: on ? c.textPrimary : c.textTertiary)),
                const SizedBox(height: 2),
                Text(context.tr(a.descKey),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall),
              ],
            ),
          );
        },
      ),
    );
  }
}
