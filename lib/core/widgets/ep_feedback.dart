import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/theme/ep_colors.dart';
import '../../app/theme/tokens.dart';
import 'ep_button.dart';

enum ToastKind { success, error, info }

/// Floating snack-bar styled to the design system.
void showEpToast(
  BuildContext context,
  String message, {
  ToastKind kind = ToastKind.info,
}) {
  final c = context.ep;
  final (IconData icon, Color tone) = switch (kind) {
    ToastKind.success => (Icons.check_circle_rounded, c.emerald),
    ToastKind.error => (Icons.error_rounded, c.danger),
    ToastKind.info => (Icons.info_rounded, c.info),
  };
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: Duration(seconds: kind == ToastKind.error ? 4 : 3),
      margin: const EdgeInsets.fromLTRB(Sp.md, 0, Sp.md, Sp.md),
      content: Row(
        children: [
          Icon(icon, color: tone, size: 20),
          const SizedBox(width: Sp.sm),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

/// Bottom-sheet confirmation. Returns true if the user confirmed.
Future<bool> confirmSheet(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  bool destructive = false,
  IconData icon = Icons.help_outline_rounded,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final c = ctx.ep;
      final tone = destructive ? c.danger : c.emerald;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Sp.gutter, 0, Sp.gutter, Sp.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: tone, size: 28),
                ),
              ),
              const SizedBox(height: Sp.md),
              Text(
                title,
                style: ctx.text.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Sp.xs),
              Text(
                body,
                style: ctx.text.bodyMedium?.copyWith(color: c.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Sp.xl),
              EpButton(
                label: confirmLabel,
                kind: destructive ? EpButtonKind.danger : EpButtonKind.primary,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(ctx).pop(true);
                },
              ),
              const SizedBox(height: Sp.xs),
              EpButton(
                label: ctx.tr('cancel'),
                kind: EpButtonKind.ghost,
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}

/// Animated count-up for EP values.
class CountUpText extends StatelessWidget {
  const CountUpText({
    super.key,
    required this.value,
    this.style,
    this.format,
    this.duration = const Duration(milliseconds: 700),
  });

  final int value;
  final TextStyle? style;
  final String Function(int)? format;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final n = v.round();
        return Text(
          format != null ? format!(n) : '$n',
          style: style,
          semanticsLabel: format != null ? format!(value) : '$value',
        );
      },
    );
  }
}
