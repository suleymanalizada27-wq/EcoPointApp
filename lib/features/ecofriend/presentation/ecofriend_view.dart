import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ep_card.dart';
import '../../challenges/data/gamification_repository.dart';
import '../../wallet/data/wallet_providers.dart';
import '../application/ecofriend_controller.dart';
import '../domain/ecofriend_engine.dart';

/// Renders one EcoFriend mood: full body, original proportions, cross-fade
/// between moods. Falls back to the static still when animations are off
/// (reduce-motion, [animate] false, or the route is not visible) — never
/// silently: the still is the same character, same pose family.
class EcoFriendView extends StatelessWidget {
  const EcoFriendView({
    super.key,
    required this.mood,
    required this.size,
    this.animate = true,
  });

  final EcoFriendMood mood;
  final double size;
  final bool animate;

  /// Pre-decodes first frames so mood changes never flash.
  static void warm(BuildContext context, double size,
      {Iterable<EcoFriendMood> moods = const [
        EcoFriendMood.normal,
        EcoFriendMood.breathing,
      ]}) {
    final px = (size * MediaQuery.devicePixelRatioOf(context)).round();
    for (final m in moods) {
      precacheImage(
        ResizeImage(AssetImage(m.animatedAsset), width: px),
        context,
        onError: (_, __) {},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final px = (size * MediaQuery.devicePixelRatioOf(context)).round();
    final still = reduce || !animate;
    final img = still
        ? Image.asset(
            mood.stillAsset,
            key: ValueKey('still-${mood.name}'),
            width: size,
            height: size,
            fit: BoxFit.contain,
            cacheWidth: px,
            gaplessPlayback: true,
          )
        : Image.asset(
            mood.animatedAsset,
            key: ValueKey('anim-${mood.name}'),
            width: size,
            height: size,
            fit: BoxFit.contain,
            cacheWidth: px,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => Image.asset(
              mood.stillAsset,
              width: size,
              height: size,
              fit: BoxFit.contain,
            ),
          );
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          layoutBuilder: (cur, prev) => Stack(
            alignment: Alignment.center,
            children: [...prev, if (cur != null) cur],
          ),
          child: ExcludeSemantics(key: ValueKey('${still ? 's' : 'a'}-${mood.name}'), child: img),
        ),
      ),
    );
  }
}

/// Dashboard mascot: ONE animation, driven by the shared controller, plus a
/// short message with EP balance and daily-goal progress.
class EcoFriendCard extends ConsumerStatefulWidget {
  const EcoFriendCard({super.key});

  @override
  ConsumerState<EcoFriendCard> createState() => _EcoFriendCardState();
}

class _EcoFriendCardState extends ConsumerState<EcoFriendCard> {
  bool _warmed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_warmed) return;
    _warmed = true;
    EcoFriendView.warm(context, 150);
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      EcoFriendView.warm(context, 150, moods: const [
        EcoFriendMood.thinking,
        EcoFriendMood.excited,
        EcoFriendMood.cheering,
        EcoFriendMood.proud,
        EcoFriendMood.sad,
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    final mood = ref.watch(ecoFriendMoodProvider);
    final balance = ref.watch(balanceProvider).valueOrNull;
    final missions = ref.watch(missionsProvider);
    final done = missions.where((m) => m.complete).length;
    final total = missions.length;
    final lang = Localizations.localeOf(context).languageCode;

    final String message;
    if (mood.isEvent) {
      message = context.tr(mood.messageKey);
    } else if (total > 0 && done < total) {
      message = context.tr('ef_goal_progress', {'done': done, 'total': total});
    } else {
      message = context.tr(mood.messageKey);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.gutter, Sp.md, Sp.gutter, 0),
      child: EpCard(
        semanticLabel: 'EcoFriend: $message',
        onTap: () {
          HapticFeedback.selectionClick();
          context.push('/challenges');
        },
        padding: const EdgeInsets.all(Sp.sm),
        child: LayoutBuilder(builder: (context, box) {
          final size = (box.maxWidth * 0.40).clamp(96.0, 150.0);
          return Row(
            children: [
              EcoFriendView(mood: mood, size: size),
              const SizedBox(width: Sp.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('EcoFriend',
                        style: context.text.labelMedium
                            ?.copyWith(color: c.textSecondary)),
                    const SizedBox(height: Sp.xxs),
                    AnimatedSwitcher(
                      duration: Motion.base,
                      child: Text(
                        message,
                        key: ValueKey(message),
                        style: context.text.titleSmall,
                      ),
                    ),
                    const SizedBox(height: Sp.xs),
                    Wrap(spacing: Sp.xs, runSpacing: Sp.xxs, children: [
                      if (balance != null)
                        _Chip(
                            '${Fmt.number(balance, lang)} ${context.tr('ep_unit')}',
                            c.lime),
                      if (total > 0) _Chip('$done/$total', c.emerald),
                    ]),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(Rad.pill),
        ),
        child: Text(text,
            style: context.text.labelSmall?.copyWith(color: color)),
      );
}

/// Small static EcoFriend for empty / error / offline states (no animation,
/// no extra decoding cost). Always the calm "normal" pose.
class EcoFriendHint extends StatelessWidget {
  const EcoFriendHint({super.key, this.size = 96});
  final double size;

  @override
  Widget build(BuildContext context) =>
      EcoFriendView(mood: EcoFriendMood.normal, size: size, animate: false);
}
