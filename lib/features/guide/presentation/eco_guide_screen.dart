import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ep_card.dart';

/// Static recycling guide (texts live in the localisation tables).
class EcoGuideScreen extends StatelessWidget {
  const EcoGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    final items = <(IconData, String)>[
      (Icons.local_drink_rounded, 'plastic'),
      (Icons.wine_bar_rounded, 'glass'),
      (Icons.description_rounded, 'paper'),
      (Icons.settings_input_component_rounded, 'metal'),
      (Icons.battery_alert_rounded, 'battery'),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('guide_title'))),
      body: ListView(
        padding: const EdgeInsets.all(Sp.gutter),
        children: [
          Text(context.tr('guide_intro'),
              style: TextStyle(color: c.textSecondary)),
          const SizedBox(height: Sp.md),
          for (final it in items) ...[
            EpCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(it.$1, color: c.emerald),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('guide_${it.$2}_t'),
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(context.tr('guide_${it.$2}_b')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Sp.sm),
          ],
          const SizedBox(height: Sp.sm),
          Text(context.tr('guide_tips_t'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: Sp.sm),
          for (final k in ['guide_tip_1', 'guide_tip_2', 'guide_tip_3'])
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.eco_rounded, size: 18, color: c.emerald),
                  const SizedBox(width: Sp.sm),
                  Expanded(child: Text(context.tr(k))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
