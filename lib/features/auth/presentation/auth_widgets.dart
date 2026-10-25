import 'package:flutter/material.dart';

import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';

/// Shared chrome for sign-in / sign-up / reset screens: brand header, scroll
/// view that survives the keyboard, consistent gutters.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    return Scaffold(
      body: Stack(
        children: [
          // Soft emerald glow behind the header.
          Positioned(
            top: -120,
            left: -60,
            right: -60,
            child: Container(
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    c.emerald.withValues(alpha: 0.28),
                    c.emerald.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: Sp.gutter),
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 56,
                        child: showBack
                            ? Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  tooltip: MaterialLocalizations.of(context)
                                      .backButtonTooltip,
                                  onPressed: () =>
                                      Navigator.of(context).maybePop(),
                                  icon: const Icon(
                                      Icons.arrow_back_rounded),
                                ),
                              )
                            : null,
                      ),
                      const BrandMark(),
                      const SizedBox(height: Sp.xl),
                      Semantics(
                        header: true,
                        child: Text(title,
                            style: context.text.headlineMedium),
                      ),
                      const SizedBox(height: Sp.xs),
                      Text(
                        subtitle,
                        style: context.text.bodyLarge
                            ?.copyWith(color: c.textSecondary),
                      ),
                      const SizedBox(height: Sp.xl),
                      child,
                      const SizedBox(height: Sp.xl),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo + wordmark.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44});
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.3),
          child: Image.asset(
            'assets/images/logo.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: size,
              height: size,
              color: c.emerald,
              child: const Icon(Icons.eco_rounded, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: Sp.sm),
        Text.rich(
          TextSpan(
            style: context.text.titleLarge,
            children: [
              const TextSpan(text: 'Eco'),
              TextSpan(
                text: 'Point',
                style: TextStyle(color: c.emerald),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "—— or ——" separator.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    return Row(
      children: [
        Expanded(child: Divider(color: c.outline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.md),
          child: Text(label, style: context.text.bodySmall),
        ),
        Expanded(child: Divider(color: c.outline)),
      ],
    );
  }
}
