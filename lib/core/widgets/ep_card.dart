import 'package:flutter/material.dart';

import '../../app/theme/ep_colors.dart';
import '../../app/theme/tokens.dart';

/// Standard surface card. One radius, one border, one padding — everywhere.
class EpCard extends StatelessWidget {
  const EpCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(Sp.md),
    this.color,
    this.gradient,
    this.borderColor,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Gradient? gradient;
  final Color? borderColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    final radius = Rad.card;
    final deco = BoxDecoration(
      color: gradient == null ? (color ?? c.surface) : null,
      gradient: gradient,
      borderRadius: radius,
      border: Border.all(color: borderColor ?? c.outline),
    );

    final inner = Padding(padding: padding, child: child);

    Widget card = DecoratedBox(
      decoration: deco,
      child: onTap == null
          ? inner
          : Material(
              color: Colors.transparent,
              borderRadius: radius,
              child: InkWell(
                borderRadius: radius,
                onTap: onTap,
                child: inner,
              ),
            ),
    );

    if (semanticLabel != null) {
      card = Semantics(
        container: true,
        button: onTap != null,
        label: semanticLabel,
        child: card,
      );
    }
    return card;
  }
}

/// Section title row with optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(Sp.gutter, Sp.xl, Sp.gutter, Sp.sm),
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: context.text.titleLarge),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: c.emerald,
                minimumSize: const Size(kMinTouch, kMinTouch),
              ),
              child: Text(actionLabel!, style: context.text.labelMedium),
            ),
        ],
      ),
    );
  }
}

/// Small uppercase pill (statuses, categories, "Estimate").
class EpBadge extends StatelessWidget {
  const EpBadge({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.filled = false,
  });

  final String label;
  final Color? color;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    final tone = color ?? c.emerald;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? tone : tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Rad.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: filled ? c.onLime : tone),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: context.text.labelSmall?.copyWith(
              color: filled ? c.onLime : tone,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded-square icon tile used in lists and tiles.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.color,
    this.size = 44,
  });

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? context.ep.emerald;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Rad.md),
      ),
      child: Icon(icon, size: size * 0.5, color: tone),
    );
  }
}

/// Linear progress bar with rounded ends and animated fill.
class EpProgressBar extends StatelessWidget {
  const EpProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 8,
    this.background,
  });

  final double value; // 0..1
  final Color? color;
  final double height;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    final v = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(Rad.pill),
      child: Stack(
        children: [
          Container(height: height, color: background ?? c.surfaceRaised),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: v),
            duration: Motion.slow,
            curve: Motion.curve,
            builder: (context, t, _) => FractionallySizedBox(
              widthFactor: t,
              child: Container(height: height, color: color ?? c.emerald),
            ),
          ),
        ],
      ),
    );
  }
}
