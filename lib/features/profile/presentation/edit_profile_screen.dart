import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/errors/failure.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/ep_avatar.dart';
import '../../../core/widgets/ep_button.dart';
import '../../../core/widgets/ep_feedback.dart';
import '../../../core/widgets/ep_text_field.dart';
import '../../wallet/data/wallet_providers.dart';
import '../data/profile_repository.dart';

/// Used both for first-time setup (`isSetup`) and later edits.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, this.isSetup = false});
  final bool isSetup;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _bio = TextEditingController();
  String _avatar = '';
  bool _busy = false;
  bool _seeded = false;

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _seed() {
    if (_seeded) return;
    final user = ref.read(authUserProvider).valueOrNull;
    final profile = ref.read(profileProvider).valueOrNull;
    if (user == null && profile == null) return;
    _seeded = true;
    _name.text = (profile?.name.isNotEmpty ?? false)
        ? profile!.name
        : (user?.displayName ?? '');
    _bio.text = profile?.bio ?? '';
    _avatar = profile?.avatar ?? '';
  }

  Future<void> _save() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile(
            name: _name.text,
            bio: _bio.text,
            avatar: _avatar,
          );
      if (!mounted) return;
      showEpToast(context, context.tr('profile_saved'),
          kind: ToastKind.success);
      if (widget.isSetup) {
        context.go('/home');
      } else {
        Navigator.of(context).maybePop();
      }
    } on Failure catch (f) {
      if (mounted) {
        showEpToast(context, context.tr(f.l10nKey), kind: ToastKind.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authUserProvider);
    ref.watch(profileProvider);
    _seed();
    final c = context.ep;
    final user = ref.watch(authUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSetup
            ? context.tr('setup_title')
            : context.tr('profile_edit')),
        actions: [
          if (widget.isSetup)
            TextButton(
              onPressed: () => context.go('/home'),
              child: Text(context.tr('skip')),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(Sp.gutter),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.isSetup)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Sp.lg),
                    child: Text(
                      context.tr('setup_sub'),
                      style: context.text.bodyLarge
                          ?.copyWith(color: c.textSecondary),
                    ),
                  ),
                Center(
                  child: EpAvatar(
                    size: 96,
                    ring: true,
                    name: _name.text,
                    presetKey: _avatar,
                    photoUrl: _avatar.isEmpty ? user?.photoURL : null,
                  ),
                ),
                const SizedBox(height: Sp.lg),
                Text(context.tr('profile_avatar'),
                    style: context.text.titleSmall),
                const SizedBox(height: Sp.sm),
                Wrap(
                  spacing: Sp.sm,
                  runSpacing: Sp.sm,
                  children: [
                    for (final key in AvatarPresets.keys)
                      _AvatarChoice(
                        presetKey: key,
                        selected: _avatar == key,
                        onTap: () => setState(() => _avatar = key),
                      ),
                  ],
                ),
                const SizedBox(height: Sp.xl),
                EpTextField(
                  label: context.tr('profile_name'),
                  controller: _name,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.person_outline_rounded,
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    final k = Validators.name(v);
                    return k == null ? null : context.tr(k);
                  },
                ),
                const SizedBox(height: Sp.md),
                EpTextField(
                  label: widget.isSetup
                      ? context.tr('setup_bio_hint')
                      : context.tr('profile_bio'),
                  controller: _bio,
                  maxLength: 160,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icons.notes_rounded,
                ),
                const SizedBox(height: Sp.xl),
                EpButton(
                  label: widget.isSetup
                      ? context.tr('continue')
                      : context.tr('save'),
                  loading: _busy,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarChoice extends StatelessWidget {
  const _AvatarChoice({
    required this.presetKey,
    required this.selected,
    required this.onTap,
  });

  final String presetKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    return Semantics(
      button: true,
      selected: selected,
      label: presetKey,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: AnimatedContainer(
          duration: Motion.fast,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? c.lime : Colors.transparent,
              width: 2,
            ),
          ),
          child: EpAvatar(presetKey: presetKey, size: 52),
        ),
      ),
    );
  }
}
