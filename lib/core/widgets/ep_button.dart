import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/ep_colors.dart';
import '../../app/theme/tokens.dart';

enum EpButtonKind { primary, accent, secondary, ghost, danger }

/// The one button used across the app. 52dp tall (≥48dp touch target), pill
/// radius, optional leading icon, built-in loading state that also blocks
/// duplicate taps.
class EpButton extends StatelessWidget {
  const EpButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = EpButtonKind.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final EpButtonKind kind;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    final enabled = onPressed != null && !loading;

    late Color bg;
    late Color fg;
    BorderSide? border;
    switch (kind) {
      case EpButtonKind.primary:
        bg = c.emerald;
        fg = Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF04140D)
            : Colors.white;
        break;
      case EpButtonKind.accent:
        bg = c.lime;
        fg = c.onLime;
        break;
      case EpButtonKind.secondary:
        bg = c.surfaceRaised;
        fg = c.textPrimary;
        border = BorderSide(color: c.outline);
        break;
      case EpButtonKind.ghost:
        bg = Colors.transparent;
        fg = c.emerald;
        break;
      case EpButtonKind.danger:
        bg = c.danger.withValues(alpha: 0.12);
        fg = c.danger;
        border = BorderSide(color: c.danger.withValues(alpha: 0.4));
        break;
    }

    final content = AnimatedSwitcher(
      duration: Motion.fast,
      child: loading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: fg),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelLarge?.copyWith(color: fg),
                  ),
                ),
              ],
            ),
    );

    final button = Opacity(
      opacity: onPressed == null && !loading ? 0.45 : 1,
      child: Material(
        color: bg,
        shape: StadiumBorder(side: border ?? BorderSide.none),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  onPressed!();
                }
              : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52, minWidth: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Center(widthFactor: expand ? null : 1, child: content),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}

/// Compact circular icon button (≥48dp target).
class EpIconButton extends StatelessWidget {
  const EpIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.badge = false,
    this.filled = true,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final bool badge;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: SizedBox(
        width: kMinTouch,
        height: kMinTouch,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Material(
              color: filled ? c.surfaceRaised : Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onPressed,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(icon, size: 22, color: c.textPrimary),
                ),
              ),
            ),
            if (badge)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: c.lime,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.bg, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
