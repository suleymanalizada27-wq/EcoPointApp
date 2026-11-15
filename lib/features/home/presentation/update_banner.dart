import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/services/preferences.dart';
import '../../../core/services/update_check.dart';

/// "A new version is available" with an Update button (opens the download
/// link set on the server). Hidden per version once dismissed.
class UpdateBanner extends ConsumerStatefulWidget {
  const UpdateBanner({super.key});

  @override
  ConsumerState<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends ConsumerState<UpdateBanner> {
  String? _dismissed;

  @override
  void initState() {
    super.initState();
    try {
      _dismissed =
          ref.read(sharedPrefsProvider).getString(PrefKeys.updateDismissed);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(updateInfoProvider).valueOrNull;
    if (info == null || _dismissed == info.latest) {
      return const SizedBox.shrink();
    }
    final c = context.ep;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.gutter, Sp.xs, Sp.gutter, 0),
      child: Semantics(
        container: true,
        liveRegion: true,
        child: Material(
          color: c.emerald.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Sp.sm, vertical: Sp.xs),
            child: Row(
              children: [
                Icon(Icons.system_update_rounded, color: c.emerald),
                const SizedBox(width: Sp.xs),
                Expanded(
                  child: Text(
                    context.tr('update_available', {'v': info.latest}),
                    style: context.text.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      await launchUrl(Uri.parse(info.url),
                          mode: LaunchMode.externalApplication);
                    } catch (_) {}
                  },
                  child: Text(context.tr('update_action')),
                ),
                IconButton(
                  tooltip: context.tr('update_dismiss'),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () async {
                    setState(() => _dismissed = info.latest);
                    try {
                      await ref
                          .read(sharedPrefsProvider)
                          .setString(PrefKeys.updateDismissed, info.latest);
                    } catch (_) {}
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
