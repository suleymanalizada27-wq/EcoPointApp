import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failure.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../core/services/preferences.dart';
import '../../../core/widgets/ep_card.dart';
import '../../../core/widgets/ep_feedback.dart';
import '../../auth/data/auth_repository.dart';
import '../../wallet/data/wallet_providers.dart';
import '../data/profile_repository.dart';
import 'profile_screen.dart' show SettingsGroup, SettingsItem;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.ep;
    final locale = ref.watch(localeProvider);
    final mode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings_title'))),
      body: ListView(
        padding: const EdgeInsets.all(Sp.gutter),
        children: [
          Text(context.tr('settings_language'),
              style: context.text.titleSmall),
          const SizedBox(height: Sp.xs),
          EpCard(
            padding: const EdgeInsets.symmetric(vertical: Sp.xs),
            child: Column(
              children: [
                for (final l in AppLocalizations.supportedLocales)
                  RadioListTile<String>(
                    value: l.languageCode,
                    groupValue: locale.languageCode,
                    activeColor: c.emerald,
                    title: Text(AppLocalizations.nativeName(l.languageCode)),
                    onChanged: (v) {
                      if (v != null) {
                        ref.read(localeProvider.notifier).setLanguage(v);
                      }
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: Sp.lg),
          Text(context.tr('settings_theme'), style: context.text.titleSmall),
          const SizedBox(height: Sp.xs),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                    value: ThemeMode.system,
                    icon: const Icon(Icons.brightness_auto_rounded, size: 18),
                    label: Text(context.tr('theme_system'))),
                ButtonSegment(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode_rounded, size: 18),
                    label: Text(context.tr('theme_light'))),
                ButtonSegment(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode_rounded, size: 18),
                    label: Text(context.tr('theme_dark'))),
              ],
              selected: {mode},
              onSelectionChanged: (s) =>
                  ref.read(themeModeProvider.notifier).setMode(s.first),
            ),
          ),
          const SizedBox(height: Sp.lg),
          SettingsGroup(children: [
            SettingsItem(Icons.notifications_rounded,
                context.tr('settings_notifications'),
                () => context.push('/settings/notifications')),
            SettingsItem(Icons.privacy_tip_rounded,
                context.tr('settings_privacy'),
                () => context.push('/settings/privacy')),
            SettingsItem(Icons.info_rounded, context.tr('settings_about'),
                () => context.push('/settings/about')),
          ]),
          const SizedBox(height: Sp.xl),
          Text(context.tr('danger_zone'),
              style: context.text.titleSmall?.copyWith(color: c.danger)),
          const SizedBox(height: Sp.xs),
          SettingsGroup(children: [
            SettingsItem(Icons.delete_forever_rounded,
                context.tr('delete_account'),
                () => _delete(context, ref),
                tone: c.danger, chevron: false),
          ]),
          const SizedBox(height: Sp.lg),
          Center(
            child: Text(
              context.tr('settings_version', {'v': AppConstants.appVersion}),
              style: context.text.bodySmall?.copyWith(color: c.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await confirmSheet(
      context,
      title: context.tr('delete_confirm_title'),
      body: context.tr('delete_confirm_body'),
      confirmLabel: context.tr('delete_account'),
      destructive: true,
      icon: Icons.delete_forever_rounded,
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      if (context.mounted) {
        showEpToast(context, context.tr('delete_done'),
            kind: ToastKind.success);
      }
    } catch (e) {
      if (!context.mounted) return;
      final f = e is Failure ? e : Failure.from(e);
      final key = f.code == 'requires-recent-login'
          ? 'auth_err_recent_login'
          : f.l10nKey;
      showEpToast(context, context.tr(key), kind: ToastKind.error);
    }
  }
}

class NotificationPrefsScreen extends ConsumerWidget {
  const NotificationPrefsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final uid = ref.watch(uidProvider);

    Future<void> set(String key, bool v) async {
      if (uid == null) return;
      try {
        await ref.read(profileRepositoryProvider).setPref(uid, key, v);
      } catch (e) {
        if (context.mounted) {
          showEpToast(context, context.tr(Failure.from(e).l10nKey),
              kind: ToastKind.error);
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('notif_prefs_title'))),
      body: ListView(
        padding: const EdgeInsets.all(Sp.gutter),
        children: [
          EpCard(
            padding: const EdgeInsets.symmetric(vertical: Sp.xs),
            child: Column(
              children: [
                SwitchListTile(
                  value: profile?.notifyActivity ?? true,
                  activeColor: context.ep.emerald,
                  title: Text(context.tr('notif_pref_activity')),
                  onChanged: (v) => set('notifyActivity', v),
                ),
                SwitchListTile(
                  value: profile?.notifyNews ?? true,
                  activeColor: context.ep.emerald,
                  title: Text(context.tr('notif_pref_news')),
                  onChanged: (v) => set('notifyNews', v),
                ),
              ],
            ),
          ),
          const SizedBox(height: Sp.sm),
          Text(context.tr('notif_prefs_note'),
              style: context.text.bodySmall
                  ?.copyWith(color: context.ep.textTertiary)),
        ],
      ),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings_privacy'))),
      body: ListView(
        padding: const EdgeInsets.all(Sp.gutter),
        children: [
          Text(context.tr('privacy_body'), style: context.text.bodyLarge),
        ],
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings_about'))),
      body: ListView(
        padding: const EdgeInsets.all(Sp.gutter),
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset('assets/images/logo.png',
                  width: 88, height: 88, semanticLabel: AppConstants.appName),
            ),
          ),
          const SizedBox(height: Sp.md),
          Center(
              child: Text(AppConstants.appName,
                  style: context.text.headlineSmall)),
          Center(
            child: Text(
              context.tr('settings_version', {'v': AppConstants.appVersion}),
              style: context.text.bodySmall?.copyWith(color: c.textTertiary),
            ),
          ),
          const SizedBox(height: Sp.lg),
          Text(context.tr('about_body'), style: context.text.bodyLarge),
          const SizedBox(height: Sp.lg),
          OutlinedButton.icon(
            onPressed: () => launchUrl(
              Uri.parse(AppConstants.partnerSiteUrl),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: Text(context.tr('about_open_site')),
          ),
        ],
      ),
    );
  }
}
