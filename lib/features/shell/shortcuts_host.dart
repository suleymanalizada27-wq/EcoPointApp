import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_actions/quick_actions.dart';

import '../../app/localization/app_localizations.dart';

/// Android launcher shortcuts (long-press the app icon): "Scan" and "Balance".
/// Best effort: any platform error is ignored.
class ShortcutsHost extends StatefulWidget {
  const ShortcutsHost({super.key});

  @override
  State<ShortcutsHost> createState() => _ShortcutsHostState();
}

class _ShortcutsHostState extends State<ShortcutsHost> {
  final QuickActions _quick = const QuickActions();
  bool _ready = false;
  String? _lang;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Localizations.localeOf(context).languageCode;
    if (_lang == lang) return;
    _lang = lang;
    _setup();
  }

  Future<void> _setup() async {
    try {
      if (!_ready) {
        _ready = true;
        await _quick.initialize((type) {
          if (!mounted) return;
          final router = GoRouter.of(context);
          if (type == 'scan') {
            router.push('/scan');
          } else if (type == 'balance') {
            router.go('/home');
          } else if (type == 'missions') {
            // Home-screen widget quick links (not launcher shortcuts).
            router.push('/challenges');
          } else if (type == 'history') {
            router.push('/transactions');
          }
        });
      }
      if (!mounted) return;
      await _quick.setShortcutItems([
        ShortcutItem(type: 'scan', localizedTitle: context.tr('nav_scan')),
        ShortcutItem(
            type: 'balance', localizedTitle: context.tr('shortcut_balance')),
      ]);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
