import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../core/services/push_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ep_avatar.dart';
import '../../../core/widgets/ep_card.dart';
import '../../../core/widgets/ep_feedback.dart';
import '../../../core/widgets/state_views.dart';
import '../../admin/data/admin_api.dart';
import '../../auth/data/auth_repository.dart';
import '../../wallet/data/wallet_providers.dart';

/// Profile tab: identity, level, Pro status, shortcuts and account actions.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.ep;
    final User? user = ref.watch(authUserProvider).valueOrNull;
    final profile = ref.watch(profileProvider).valueOrNull;
    final stats = ref.watch(statsProvider).valueOrNull;
    final balance = ref.watch(balanceProvider).valueOrNull ?? 0;
    final level = ref.watch(levelProgressProvider);

    final name = (profile?.name.isNotEmpty ?? false)
        ? profile!.name
        : (user?.displayName ?? '');
    final email = (profile?.email.isNotEmpty ?? false)
        ? profile!.email
        : (user?.email ?? '');
    final isPro = profile?.isProAt(DateTime.now()) ?? false;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Sp.gutter, Sp.md, Sp.gutter, 120),
        children: [
          const OfflineBanner(),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(context.tr('profile_title'),
                      style: context.text.headlineMedium),
                ),
              ),
              IconButton(
                tooltip: context.tr('settings_title'),
                onPressed: () => context.push('/settings'),
                icon: const Icon(Icons.settings_rounded),
              ),
            ],
          ),
          const SizedBox(height: Sp.md),
          EpCard(
            child: Column(
              children: [
                EpAvatar(
                  size: 88,
                  ring: true,
                  name: name,
                  presetKey: profile?.avatar,
                  photoUrl: (profile?.avatar.isEmpty ?? true)
                      ? (profile?.photoUrl.isNotEmpty ?? false
                          ? profile!.photoUrl
                          : user?.photoURL)
                      : null,
                ),
                const SizedBox(height: Sp.sm),
                Text(name.isEmpty ? '—' : name,
                    style: context.text.titleLarge,
                    textAlign: TextAlign.center),
                if (email.isNotEmpty)
                  Text(email,
                      style: context.text.bodyMedium
                          ?.copyWith(color: c.textSecondary),
                      textAlign: TextAlign.center),
                const SizedBox(height: Sp.xs),
                Text(
                  (profile?.bio.isNotEmpty ?? false)
                      ? profile!.bio
                      : context.tr('profile_bio_empty'),
                  style: context.text.bodyMedium?.copyWith(
                    color: (profile?.bio.isNotEmpty ?? false)
                        ? c.textPrimary
                        : c.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Sp.sm),
                Wrap(
                  spacing: Sp.xs,
                  alignment: WrapAlignment.center,
                  children: [
                    EpBadge(
                        label: context.tr(level.current.l10nKey),
                        color: c.lime),
                    if (isPro)
                      EpBadge(
                          label: context.tr('pro_active'),
                          icon: Icons.workspace_premium_rounded,
                          color: c.warning),
                  ],
                ),
                const SizedBox(height: Sp.md),
                OutlinedButton.icon(
                  onPressed: () => context.push('/profile/edit'),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: Text(context.tr('profile_edit')),
                ),
              ],
            ),
          ),
          const SizedBox(height: Sp.md),
          Row(
            children: [
              Expanded(
                  child: _Stat(
                      label: context.tr('home_balance'),
                      value: Fmt.number(balance))),
              const SizedBox(width: Sp.xs),
              Expanded(
                  child: _Stat(
                      label: context.tr('home_earned'),
                      value: Fmt.number(stats?.earned ?? 0))),
              const SizedBox(width: Sp.xs),
              Expanded(
                  child: _Stat(
                      label: context.tr('stats_total_scans'),
                      value: Fmt.number(stats?.scans ?? 0))),
            ],
          ),
          if (isPro && profile?.proExpiry != null) ...[
            const SizedBox(height: Sp.xs),
            Text(
              context.tr('pro_active_until',
                  {'d': Fmt.date(profile!.proExpiry!, null)}),
              style: context.text.bodySmall?.copyWith(color: c.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: Sp.lg),
          SettingsGroup(children: [
            SettingsItem(Icons.qr_code_2_rounded, context.tr('settings_my_qr'),
                () => context.push('/my-qr')),
            SettingsItem(Icons.card_giftcard_rounded, context.tr('settings_referral'),
                () => context.push('/referral')),
            SettingsItem(Icons.emoji_events_rounded,
                context.tr('settings_achievements'),
                () => context.push('/achievements')),
            SettingsItem(Icons.bar_chart_rounded, context.tr('settings_stats'),
                () => context.push('/stats')),
            SettingsItem(Icons.receipt_long_rounded, context.tr('settings_history'),
                () => context.push('/transactions')),
            SettingsItem(Icons.shopping_bag_rounded,
                context.tr('settings_purchases'),
                () => context.push('/purchases')),
            SettingsItem(Icons.eco_rounded, context.tr('settings_guide'),
                () => context.push('/guide')),
            if (ref.watch(isAdminProvider).valueOrNull == true)
              SettingsItem(Icons.admin_panel_settings_rounded,
                  context.tr('settings_admin'), () => context.push('/admin')),
          ]),
          const SizedBox(height: Sp.md),
          SettingsGroup(children: [
            SettingsItem(Icons.settings_rounded, context.tr('settings_title'),
                () => context.push('/settings')),
          ]),
          const SizedBox(height: Sp.md),
          SettingsGroup(children: [
            SettingsItem(Icons.logout_rounded, context.tr('sign_out'),
                () => _signOut(context, ref),
                tone: c.danger, chevron: false),
          ]),
          const SizedBox(height: Sp.md),
          Center(
            child: Text(
              '${context.tr('profile_user_id')}: ${user?.uid.substring(0, user.uid.length < 8 ? user.uid.length : 8) ?? '—'}',
              style: context.text.bodySmall?.copyWith(color: c.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final ok = await confirmSheet(
      context,
      title: context.tr('sign_out'),
      body: context.tr('sign_out_confirm'),
      confirmLabel: context.tr('sign_out'),
      destructive: true,
      icon: Icons.logout_rounded,
    );
    if (!ok) return;
    await ref.read(pushServiceProvider).unregister();
    await ref.read(authRepositoryProvider).signOut();
    // The router redirect sends the user to sign-in once auth state changes.
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return EpCard(
      padding: const EdgeInsets.all(Sp.sm),
      child: Column(
        children: [
          FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: context.text.titleLarge)),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall),
        ],
      ),
    );
  }
}

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    return EpCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(height: 1, indent: 56, color: c.outline),
          ],
        ],
      ),
    );
  }
}

class SettingsItem extends StatelessWidget {
  const SettingsItem(this.icon, this.label, this.onTap,
      {super.key, this.tone, this.chevron = true});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? tone;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    final color = tone ?? c.textPrimary;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinTouch),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
          child: Row(
            children: [
              Icon(icon, color: tone ?? c.emerald, size: 22),
              const SizedBox(width: Sp.sm),
              Expanded(
                  child: Text(label,
                      style: context.text.bodyLarge?.copyWith(color: color))),
              if (chevron)
                Icon(Icons.chevron_right_rounded, color: c.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
