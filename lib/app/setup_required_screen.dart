import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/firebase_providers.dart';
import '../core/widgets/ep_card.dart';
import 'localization/app_localizations.dart';
import 'theme/ep_colors.dart';
import 'theme/tokens.dart';

/// Shown when Firebase has no real credentials (or failed to initialise), so
/// a fresh checkout explains what to do instead of crashing.
class SetupRequiredScreen extends ConsumerWidget {
  const SetupRequiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.ep;
    final boot = ref.watch(bootProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Sp.gutter),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: EpCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.settings_suggest_rounded,
                        size: 40, color: c.warning),
                    const SizedBox(height: Sp.md),
                    Text(context.tr('setup_required_title'),
                        style: context.text.titleLarge),
                    const SizedBox(height: Sp.xs),
                    Text(context.tr('setup_required_body'),
                        style: context.text.bodyMedium
                            ?.copyWith(color: c.textSecondary)),
                    if (boot.error != null) ...[
                      const SizedBox(height: Sp.md),
                      SelectableText(boot.error!,
                          style: context.text.bodySmall
                              ?.copyWith(color: c.textTertiary)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
