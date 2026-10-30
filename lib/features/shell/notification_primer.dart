import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/theme/ep_colors.dart';
import '../../app/theme/tokens.dart';
import '../../core/services/preferences.dart';
import '../../core/services/push_service.dart';
import '../../core/widgets/ep_button.dart';

/// Invisible widget that, at most 3 times, explains WHY notifications are
/// useful before the Android/iOS permission prompt appears. Only shown while
/// the system permission is still undecided.
class NotificationPrimerHost extends ConsumerStatefulWidget {
  const NotificationPrimerHost({super.key});

  @override
  ConsumerState<NotificationPrimerHost> createState() => _State();
}

class _State extends ConsumerState<NotificationPrimerHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAsk());
  }

  Future<void> _maybeAsk() async {
    if (!PushService.isSupported) return;
    final prefs = ref.read(sharedPrefsProvider);
    final asks = prefs.getInt(PrefKeys.notifAsks) ?? 0;
    if (asks >= 3) return;
    final svc = ref.read(pushServiceProvider);
    if (!await svc.needsPermission()) return;
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    await prefs.setInt(PrefKeys.notifAsks, asks + 1);
    if (!mounted) return;

    final yes = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final c = ctx.ep;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Sp.gutter),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_active_rounded,
                    size: 44, color: c.emerald),
                const SizedBox(height: Sp.md),
                Text(ctx.tr('notif_primer_title'),
                    textAlign: TextAlign.center,
                    style: ctx.text.titleLarge),
                const SizedBox(height: Sp.sm),
                Text(ctx.tr('notif_primer_body'),
                    textAlign: TextAlign.center,
                    style: ctx.text.bodyMedium?.copyWith(color: c.textSecondary)),
                const SizedBox(height: Sp.lg),
                EpButton(
                  label: ctx.tr('notif_primer_yes'),
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
                const SizedBox(height: Sp.xs),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(ctx.tr('notif_primer_later')),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (yes != true || !mounted) return;
    final lang = ref.read(localeProvider).languageCode;
    final ok = await svc.registerDevice(lang);
    // Declined in the system prompt: do not nag again.
    if (!ok) await prefs.setInt(PrefKeys.notifAsks, 3);
    ref.invalidate(pushRegistrationProvider);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
