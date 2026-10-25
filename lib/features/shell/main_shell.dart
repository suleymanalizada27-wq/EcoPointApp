import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/theme/ep_colors.dart';
import '../../app/theme/tokens.dart';
import '../../core/services/push_service.dart';
import '../auth/data/auth_repository.dart';

/// Hosts the four tabs with a bottom bar and a raised centre scan button.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Make sure the server-side profile exists once per sign-in.
    ref.watch(profileBootstrapProvider);
    // Push: register this device, sync the news topic, show/route messages.
    ref.watch(pushRegistrationProvider);
    ref.watch(pushTopicProvider);
    ref.watch(pushListenersProvider);
    final c = context.ep;

    void go(int i) =>
        shell.goBranch(i, initialLocation: i == shell.currentIndex);

    return Scaffold(
      extendBody: true,
      body: shell,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Semantics(
        button: true,
        label: context.tr('nav_scan'),
        child: SizedBox(
          width: 64,
          height: 64,
          child: FloatingActionButton(
            heroTag: 'scan-fab',
            elevation: 4,
            backgroundColor: c.lime,
            foregroundColor: c.onLime,
            shape: const CircleBorder(),
            tooltip: context.tr('nav_scan'),
            onPressed: () => context.push('/scan'),
            child: const Icon(Icons.qr_code_scanner_rounded, size: 30),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: EdgeInsets.zero,
        height: 64,
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: context.tr('nav_home'),
              selected: shell.currentIndex == 0,
              onTap: () => go(0),
            ),
            _NavItem(
              icon: Icons.storefront_rounded,
              label: context.tr('nav_rewards'),
              selected: shell.currentIndex == 1,
              onTap: () => go(1),
            ),
            const SizedBox(width: 72), // room for the FAB
            _NavItem(
              icon: Icons.location_on_rounded,
              label: context.tr('nav_bins'),
              selected: shell.currentIndex == 2,
              onTap: () => go(2),
            ),
            _NavItem(
              icon: Icons.person_rounded,
              label: context.tr('nav_profile'),
              selected: shell.currentIndex == 3,
              onTap: () => go(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    final color = selected ? c.emerald : c.textTertiary;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTouch),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: selected ? 1.12 : 1,
                  duration: Motion.base,
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelSmall?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
