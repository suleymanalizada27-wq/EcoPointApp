import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ep_avatar.dart';
import '../../../core/widgets/ep_button.dart';
import '../../../core/widgets/ep_card.dart';
import '../../../core/widgets/ep_feedback.dart';
import '../../../core/widgets/state_views.dart';
import '../../challenges/data/gamification_repository.dart';
import '../../challenges/presentation/challenge_widgets.dart';
import '../../leaderboard/data/leaderboard_repository.dart';
import '../../leaderboard/presentation/leaderboard_widgets.dart';
import '../../marketplace/data/marketplace_repository.dart';
import '../../marketplace/presentation/marketplace_screen.dart';
import '../../notifications/data/notifications_repository.dart';
import '../../smart_bins/data/bins_repository.dart';
import '../../smart_bins/presentation/bin_detail_sheet.dart';
import '../../smart_bins/presentation/bins_screen.dart';
import '../../statistics/presentation/ep_bar_chart.dart';
import '../../statistics/presentation/statistics_screen.dart';
import '../../wallet/data/wallet_providers.dart';
import '../../wallet/domain/activity_aggregator.dart';

String _greetingKey(DateTime now) {
  final h = now.hour;
  if (h < 12) return 'greet_morning';
  if (h < 18) return 'greet_afternoon';
  return 'greet_evening';
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: context.ep.emerald,
        backgroundColor: context.ep.surface,
        onRefresh: () async {
          // Streams are live; refresh re-subscribes the one-shot-ish ones.
          ref.invalidate(leaderboardProvider);
          ref.invalidate(rewardsProvider);
          await Future<void>.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 120),
          children: const [
            OfflineBanner(),
            _Header(),
            _BalanceHero(),
            _SummaryRow(),
            _WeekCard(),
            _MissionsSection(),
            _ImpactSection(),
            _LeaderboardSection(),
            _FeaturedRewards(),
            _BinsSection(),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.ep;
    final user = ref.watch(authUserProvider).valueOrNull;
    final profile = ref.watch(profileProvider).valueOrNull;
    final name = (profile?.name.isNotEmpty ?? false)
        ? profile!.firstName
        : (user?.displayName ?? '').split(' ').first;
    final unread = ref.watch(hasUnreadNotificationsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.gutter, Sp.md, Sp.xs, Sp.sm),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: context.tr('profile_title'),
            child: GestureDetector(
              onTap: () => context.go('/profile'),
              child: EpAvatar(
                size: 46,
                ring: true,
                name: name,
                presetKey: profile?.avatar,
                photoUrl:
                    (profile?.avatar.isEmpty ?? true) ? user?.photoURL : null,
              ),
            ),
          ),
          const SizedBox(width: Sp.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr(_greetingKey(DateTime.now())),
                    style: context.text.bodySmall
                        ?.copyWith(color: c.textSecondary)),
                Text(
                  name.isEmpty ? context.tr('app_name') : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleLarge,
                ),
              ],
            ),
          ),
          EpIconButton(
            icon: Icons.notifications_none_rounded,
            semanticLabel: context.tr('notif_title'),
            badge: unread,
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _BalanceHero extends ConsumerWidget {
  const _BalanceHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.ep;
    final balance = ref.watch(balanceProvider);
    final level = ref.watch(levelProgressProvider);
    final locale = Localizations.localeOf(context).languageCode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Sp.gutter),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Rad.xl),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: c.heroGradient,
          ),
          boxShadow: [
            BoxShadow(
              color: c.emeraldDeep.withValues(alpha: 0.35),
              blurRadius: 36,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Icon(Icons.eco_rounded,
                  size: 180, color: Colors.white.withValues(alpha: 0.06)),
            ),
            Padding(
              padding: const EdgeInsets.all(Sp.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(context.tr('home_balance'),
                          style: context.text.labelMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.75))),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(Rad.pill),
                        ),
                        child: Text(
                          context.tr(level.current.l10nKey),
                          style: context.text.labelSmall
                              ?.copyWith(color: c.lime),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Sp.xs),
                  balance.when(
                    loading: () => const SkeletonBox(height: 48, width: 160),
                    error: (_, __) => Text('—',
                        style: context.text.displayLarge
                            ?.copyWith(color: Colors.white)),
                    data: (v) => Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        CountUpText(
                          value: v,
                          format: (n) => Fmt.number(n, locale),
                          style: context.text.displayLarge
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Text(context.tr('ep_unit'),
                            style: context.text.titleMedium
                                ?.copyWith(color: c.lime)),
                      ],
                    ),
                  ),
                  const SizedBox(height: Sp.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Rad.pill),
                    child: LinearProgressIndicator(
                      value: level.fraction,
                      minHeight: 6,
                      backgroundColor: Colors.black.withValues(alpha: 0.25),
                      valueColor: AlwaysStoppedAnimation<Color>(c.lime),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    level.isMax
                        ? context.tr('home_level_max')
                        : context.tr('home_level_progress', {
                            'cur': Fmt.number(level.earned, locale),
                            'next': Fmt.number(level.next!.minEarned, locale),
                          }),
                    style: context.text.bodySmall
                        ?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: Sp.lg),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: EpButton(
                          label: context.tr('home_scan_cta'),
                          icon: Icons.qr_code_scanner_rounded,
                          kind: EpButtonKind.accent,
                          onPressed: () => context.push('/scan'),
                        ),
                      ),
                      const SizedBox(width: Sp.xs),
                      _RoundAction(
                        icon: Icons.send_rounded,
                        label: context.tr('home_send'),
                        onTap: () => context.push('/transfer'),
                      ),
                      const SizedBox(width: Sp.xs),
                      _RoundAction(
                        icon: Icons.qr_code_2_rounded,
                        label: context.tr('qr_my_title'),
                        onTap: () => context.push('/my-qr'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.white.withValues(alpha: 0.14),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(icon, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends ConsumerWidget {
  const _SummaryRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.ep;
    final week = ref.watch(weeklyActivityProvider).valueOrNull;
    final stats = ref.watch(statsProvider).valueOrNull;
    final earned = week == null ? null : ActivityAggregator.totalEarned(week);
    final spent = week == null ? null : ActivityAggregator.totalSpent(week);

    Widget tile(String label, int? value, IconData icon, Color color) {
      return Expanded(
        child: EpCard(
          padding: const EdgeInsets.all(Sp.sm),
          onTap: () => context.push('/transactions'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 6),
              if (value == null)
                const SkeletonBox(height: 20, width: 50)
              else
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(Fmt.number(value),
                      style: context.text.titleLarge),
                ),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.gutter, Sp.md, Sp.gutter, 0),
      child: Row(
        children: [
          tile('${context.tr('home_earned')} · 7d', earned,
              Icons.south_west_rounded, c.emerald),
          const SizedBox(width: Sp.xs),
          tile('${context.tr('home_spent')} · 7d', spent,
              Icons.shopping_bag_outlined, c.info),
          const SizedBox(width: Sp.xs),
          tile(context.tr('home_sent'), stats?.sent,
              Icons.north_east_rounded, c.warning),
        ],
      ),
    );
  }
}

class _WeekCard extends ConsumerWidget {
  const _WeekCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.ep;
    final week = ref.watch(weeklyActivityProvider);
    final locale = Localizations.localeOf(context).languageCode;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.gutter, Sp.md, Sp.gutter, 0),
      child: EpCard(
        onTap: () => context.push('/stats'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(context.tr('home_week'),
                      style: context.text.titleMedium),
                ),
                Text(context.tr('stats_title'),
                    style: context.text.labelMedium
                        ?.copyWith(color: c.emerald)),
                Icon(Icons.chevron_right_rounded, color: c.emerald),
              ],
            ),
            const SizedBox(height: Sp.sm),
            week.when(
              loading: () => const SkeletonBox(height: 120),
              error: (e, _) => Text(context.tr('error_generic')),
              data: (buckets) {
                final total = ActivityAggregator.totalEarned(buckets);
                if (total == 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: Sp.lg),
                    child: Center(
                      child: Text(context.tr('home_no_activity'),
                          style: context.text.bodyMedium
                              ?.copyWith(color: c.textSecondary)),
                    ),
                  );
                }
                return EpBarChart(
                  buckets: buckets,
                  locale: locale,
                  height: 110,
                  showSpent: false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionsSection extends ConsumerWidget {
  const _MissionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missions = ref.watch(missionsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: context.tr('home_challenges'),
          actionLabel: context.tr('see_all'),
          onAction: () => context.push('/challenges'),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: Sp.gutter),
          child: StreakCard(),
        ),
        const SizedBox(height: Sp.xs),
        for (final m in missions.take(2))
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Sp.gutter, 0, Sp.gutter, Sp.xs),
            child: MissionTile(mission: m),
          ),
      ],
    );
  }
}

class _ImpactSection extends ConsumerWidget {
  const _ImpactSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final impact = ref.watch(impactProvider);
    final c = context.ep;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: context.tr('home_impact')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.gutter),
          child: ImpactCard(
              impact: impact, title: context.tr('stats_impact_title')),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              Sp.gutter, Sp.xs, Sp.gutter, 0),
          child: Text(context.tr('home_impact_note'),
              style: context.text.bodySmall
                  ?.copyWith(color: c.textTertiary)),
        ),
      ],
    );
  }
}

class _LeaderboardSection extends StatelessWidget {
  const _LeaderboardSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: context.tr('home_leaderboard'),
          actionLabel: context.tr('see_all'),
          onAction: () => context.push('/leaderboard'),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: Sp.gutter),
          child: LeaderboardPreview(),
        ),
      ],
    );
  }
}

class _FeaturedRewards extends ConsumerWidget {
  const _FeaturedRewards();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewards = ref.watch(rewardsProvider).valueOrNull;
    final balance = ref.watch(balanceProvider).valueOrNull ?? 0;
    if (rewards == null || rewards.items.isEmpty) {
      return const SizedBox.shrink();
    }
    final featured = rewards.items.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: context.tr('home_featured'),
          actionLabel: context.tr('see_all'),
          onAction: () => context.go('/rewards'),
        ),
        SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Sp.gutter),
            itemCount: featured.length,
            separatorBuilder: (_, __) => const SizedBox(width: Sp.sm),
            itemBuilder: (context, i) => SizedBox(
              width: 168,
              child: RewardCard(
                reward: featured[i],
                balance: balance,
                onTap: () => openRewardFlow(context, featured[i]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BinsSection extends ConsumerWidget {
  const _BinsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bins = ref.watch(binsProvider);
    final loc = ref.watch(locationProvider).valueOrNull;
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: context.tr('home_nearby'),
          actionLabel: context.tr('see_all'),
          onAction: () => context.go('/bins'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.gutter),
          child: bins.when(
            loading: () => const SkeletonBox(height: 84, radius: Rad.lg),
            error: (e, _) => EpCard(child: Text(context.tr('error_generic'))),
            data: (list) {
              if (list.isEmpty) {
                return EpCard(
                  child: Row(
                    children: [
                      const IconTile(icon: Icons.recycling_rounded),
                      const SizedBox(width: Sp.sm),
                      Expanded(
                        child: Text(context.tr('home_no_bins'),
                            style: context.text.bodyMedium),
                      ),
                    ],
                  ),
                );
              }
              final sorted = [...list];
              if (loc != null && loc.hasFix) {
                sorted.sort((a, b) {
                  final da = loc.distanceTo(a) ?? double.infinity;
                  final db = loc.distanceTo(b) ?? double.infinity;
                  return da.compareTo(db);
                });
              }
              return Column(
                children: [
                  for (final b in sorted.take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: Sp.xs),
                      child: BinTile(
                        bin: b,
                        online: b.isOnline(now),
                        distanceMeters: loc?.distanceTo(b),
                        onTap: () => showBinDetail(context, b),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
