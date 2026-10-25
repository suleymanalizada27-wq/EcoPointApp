import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../core/utils/qr_payload.dart';
import '../../../core/widgets/ep_avatar.dart';
import '../../../core/widgets/ep_button.dart';
import '../../../core/widgets/ep_feedback.dart';
import '../../wallet/data/wallet_providers.dart';

/// Shows a real, scannable QR for the signed-in user (the legacy web app drew
/// a decorative pseudo-QR that no scanner could read).
class MyQrScreen extends ConsumerWidget {
  const MyQrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.ep;
    final uid = ref.watch(uidProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
    final user = ref.watch(authUserProvider).valueOrNull;
    final name = (profile?.name.isNotEmpty ?? false)
        ? profile!.name
        : (user?.displayName ?? '');

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('qr_my_title'))),
      body: SafeArea(
        child: uid == null
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.all(Sp.gutter),
                child: Column(
                  children: [
                    const Spacer(),
                    EpAvatar(
                      size: 64,
                      ring: true,
                      name: name,
                      presetKey: profile?.avatar,
                      photoUrl: (profile?.avatar.isEmpty ?? true)
                          ? user?.photoURL
                          : null,
                    ),
                    const SizedBox(height: Sp.sm),
                    Text(name, style: context.text.titleLarge),
                    const SizedBox(height: Sp.lg),
                    Container(
                      padding: const EdgeInsets.all(Sp.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(Rad.xl),
                        boxShadow: [
                          BoxShadow(
                            color: c.emerald.withValues(alpha: 0.25),
                            blurRadius: 40,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Semantics(
                        label: context.tr('qr_my_title'),
                        image: true,
                        child: QrImageView(
                          data: QrPayload.forUser(uid),
                          size: 232,
                          backgroundColor: Colors.white,
                          errorCorrectionLevel: QrErrorCorrectLevel.M,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF0A3D2C),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF0A3D2C),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: Sp.lg),
                    Text(
                      context.tr('qr_my_hint'),
                      textAlign: TextAlign.center,
                      style: context.text.bodyMedium
                          ?.copyWith(color: c.textSecondary),
                    ),
                    const Spacer(),
                    EpButton(
                      label: context.tr('qr_my_copy_id'),
                      icon: Icons.copy_rounded,
                      kind: EpButtonKind.secondary,
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: uid));
                        if (context.mounted) {
                          showEpToast(context, context.tr('copied'),
                              kind: ToastKind.success);
                        }
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
