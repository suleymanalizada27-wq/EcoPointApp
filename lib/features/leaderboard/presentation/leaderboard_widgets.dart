import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ep_avatar.dart';
import '../../../core/widgets/ep_card.dart';
import '../../../core/widgets/state_views.dart';
import '../data/leaderboard_repository.dart';

class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({
    super.key,
    required this.rank,
    required this.entry,
    required this.isMe,
  });

  final int rank;
  final LeaderboardEntry entry;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    final medal = switch (rank) {
      1 => const Color(0xFFE6C34A),
      2 => const Color(0xFFB7C2BC),
      3 => const Color(0xFFC98B5A),
      _ => null,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: Sp.xs),
      decoration: BoxDecoration(
        color: isMe ? c.emerald.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(Rad.md),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: medal != null
                ? Icon(Icons.workspace_premium_rounded, color: medal, size: 24)
                : Text('$rank',
                    textAlign: TextAlign.center,
                    style: context.text.titleSmall
                        ?.copyWith(color: c.textTertiary)),
          ),
          const SizedBox(width: Sp.xs),
          EpAvatar(
            name: entry.name,
            photoUrl: entry.photoUrl,
            presetKey: entry.avatar,
            size: 38,
          ),
          const SizedBox(width: Sp.sm),
          Expanded(
            child: Text(
              isMe ? '${entry.name} · ${context.tr('lb_you')}' : entry.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleSmall,
            ),
          ),
          Text(
            Fmt.number(entry.ep),
            style: context.text.titleSmall?.copyWith(color: c.emerald),
          ),
        ],
      ),
    );
  }
}

/// Home-screen preview: top 5 + link to the full board.
class LeaderboardPreview extends ConsumerWidget {
  const LeaderboardPreview({super.key, this.limit = 5});
  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(leaderboardProvider);
    final me = ref.watch(uidProvider);

    return EpCard(
      padding: const EdgeInsets.all(Sp.xs),
      child: board.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(Sp.lg),
          child: LoadingView(),
        ),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(leaderboardProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(Sp.lg),
              child: Center(
                child: Text(context.tr('lb_empty'),
                    style: context.text.bodyMedium),
              ),
            );
          }
          final shown = list.take(limit).toList();
          return Column(
            children: [
              for (var i = 0; i < shown.length; i++)
                LeaderboardRow(
                  rank: i + 1,
                  entry: shown[i],
                  isMe: shown[i].uid == me,
                ),
            ],
          );
        },
      ),
    );
  }
}

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('lb_title')),
          bottom: TabBar(tabs: [
            Tab(text: context.tr('lb_weekly')),
            Tab(text: context.tr('lb_all_time')),
          ]),
        ),
        body: TabBarView(children: [
          _BoardList(
            provider: weeklyLeaderboardProvider,
            emptyKey: 'lb_weekly_empty',
            note: context.tr('lb_weekly_note'),
          ),
          _BoardList(
            provider: leaderboardProvider,
            emptyKey: 'lb_empty',
          ),
        ]),
      ),
    );
  }
}

class _BoardList extends ConsumerWidget {
  const _BoardList({required this.provider, required this.emptyKey, this.note});
  final StreamProvider<List<LeaderboardEntry>> provider;
  final String emptyKey;
  final String? note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(provider);
    final me = ref.watch(uidProvider);
    return AsyncBody<List<LeaderboardEntry>>(
      value: board,
      onRetry: () => ref.invalidate(provider),
      data: (list) {
        if (list.isEmpty) {
          return EmptyView(
            icon: Icons.emoji_events_outlined,
            message: context.tr(emptyKey),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(Sp.gutter),
          itemCount: list.length + (note == null ? 0 : 1),
          itemBuilder: (context, i) {
            if (note != null && i == list.length) {
              return Padding(
                padding: const EdgeInsets.only(top: Sp.md),
                child: Text(note!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.ep.textSecondary)),
              );
            }
            return LeaderboardRow(
              rank: i + 1,
              entry: list[i],
              isMe: list[i].uid == me,
            );
          },
        );
      },
    );
  }
}
