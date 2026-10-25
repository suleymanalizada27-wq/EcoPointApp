import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ep_card.dart';
import '../../../core/widgets/state_views.dart';
import '../data/notifications_repository.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Opening the screen marks everything currently loaded as seen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final list = ref.read(notificationsProvider).valueOrNull;
      if (list != null && list.isNotEmpty) {
        ref
            .read(notifSeenProvider.notifier)
            .markSeen(list.first.time.millisecondsSinceEpoch);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    final feed = ref.watch(notificationsProvider);
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('notif_title'))),
      body: AsyncBody<List<AppNotification>>(
        value: feed,
        onRetry: () => ref.invalidate(notificationsProvider),
        data: (list) {
          if (list.isEmpty) {
            return EmptyView(
              icon: Icons.notifications_none_rounded,
              message: context.tr('notif_empty'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(Sp.gutter),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: Sp.xs),
            itemBuilder: (context, i) {
              final n = list[i];
              return EpCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconTile(
                      icon: n.personal
                          ? Icons.person_rounded
                          : Icons.campaign_rounded,
                      color: n.personal ? c.emerald : c.info,
                    ),
                    const SizedBox(width: Sp.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (n.title.isNotEmpty)
                            Text(n.title, style: context.text.titleSmall),
                          if (n.body.isNotEmpty)
                            Text(n.body,
                                style: context.text.bodyMedium
                                    ?.copyWith(color: c.textSecondary)),
                          const SizedBox(height: 4),
                          Text(Fmt.dateTime(n.time, locale),
                              style: context.text.bodySmall
                                  ?.copyWith(color: c.textTertiary)),
                        ],
                      ),
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
