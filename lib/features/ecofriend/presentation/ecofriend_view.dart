import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../challenges/data/gamification_repository.dart';
import '../../wallet/data/wallet_providers.dart';
import '../application/ecofriend_controller.dart';
import '../application/ecofriend_messages_provider.dart';
import '../domain/ecofriend_engine.dart';
import '../domain/ecofriend_messages.dart';

/// Renders one EcoFriend mood: full body, original proportions, cross-fade
/// between moods, a pop-in on every mood change, and (when [interactive]) a
/// tap-to-jump with sparkles — like a Duolingo character. All motion is
/// cosmetic: it never changes the mood engine or EP.
///
/// Falls back to the static still when animations are off (reduce-motion,
/// [animate] false, or the route is not visible).
class EcoFriendView extends StatefulWidget {
  const EcoFriendView({
    super.key,
    required this.mood,
    required this.size,
    this.animate = true,
    this.interactive = true,
    this.sleepy = false,
    this.onTap,
  });

  /// Night scene: floating "Zzz" next to the (unchanged) mascot.
  final bool sleepy;
  final EcoFriendMood mood;
  final double size;
  final bool animate;
  final bool interactive;
  final VoidCallback? onTap;

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
  State<EcoFriendView> createState() => _EcoFriendViewState();
}

class _EcoFriendViewState extends State<EcoFriendView>
    with TickerProviderStateMixin {
  late final AnimationController _jump = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 750));
  late final AnimationController _pop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 560));

  @override
  void initState() {
    super.initState();
    _pop.forward(from: 0);
  }

  @override
  void didUpdateWidget(EcoFriendView old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood) _pop.forward(from: 0);
  }

  @override
  void dispose() {
    _jump.dispose();
    _pop.dispose();
    super.dispose();
  }

  void _tap(bool reduce) {
    HapticFeedback.selectionClick();
    if (!reduce) _jump.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final size = widget.size;
    final mood = widget.mood;
    final px = (size * MediaQuery.devicePixelRatioOf(context)).round();
    final still = reduce || !widget.animate;
    final img = still
        ? Image.asset(
            mood.stillAsset,
            width: size,
            height: size,
            fit: BoxFit.contain,
            cacheWidth: px,
            gaplessPlayback: true,
          )
        : Image.asset(
            mood.animatedAsset,
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

    Widget body = AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (cur, prev) => Stack(
        alignment: Alignment.center,
        children: [...prev, if (cur != null) cur],
      ),
      child: ExcludeSemantics(
        key: ValueKey('${still ? 's' : 'a'}-${mood.name}'),
        child: img,
      ),
    );

    if (!reduce) {
      body = AnimatedBuilder(
        animation: Listenable.merge([_jump, _pop]),
        builder: (context, child) {
          final j = _jump.value;
          final lift = -math.sin(math.pi * j) * size * 0.17;
          final squash = 1 + 0.05 * math.sin(2 * math.pi * j) * (1 - j);
          final pop = 0.86 + 0.14 * Curves.elasticOut.transform(_pop.value);
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Transform.translate(
                offset: Offset(0, lift),
                child: Transform.scale(
                  alignment: Alignment.bottomCenter,
                  scaleX: pop / squash,
                  scaleY: pop * squash,
                  child: child,
                ),
              ),
              if (_jump.isAnimating)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _SparklePainter(
                        j,
                        const [
                          Color(0xFFC8F23A),
                          Color(0xFFFFD54F),
                          Color(0xFFFFFFFF),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        child: body,
      );
    }

    body = RepaintBoundary(child: SizedBox(width: size, height: size, child: body));
    if (widget.sleepy) {
      body = Stack(
        clipBehavior: Clip.none,
        children: [
          body,
          PositionedDirectional(
            top: size * 0.02,
            end: size * 0.02,
            child: IgnorePointer(child: _Zzz(size: size, animate: !reduce)),
          ),
        ],
      );
    }
    if (widget.interactive || widget.onTap != null) {
      body = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _tap(reduce),
        child: body,
      );
    }
    return body;
  }
}

/// Three "z" letters drifting up and fading (night / sleepy scene).
class _Zzz extends StatefulWidget {
  const _Zzz({required this.size, required this.animate});
  final double size;
  final bool animate;

  @override
  State<_Zzz> createState() => _ZzzState();
}

class _ZzzState extends State<_Zzz> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3200));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void didUpdateWidget(_Zzz old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.animate && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = widget.size * 0.34;
    return SizedBox(
      width: box,
      height: box,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < 3; i++)
              Builder(builder: (_) {
                final t = widget.animate ? (_c.value + i / 3) % 1.0 : (i + 1) / 4;
                final fade = math.sin(math.pi * t).clamp(0.0, 1.0).toDouble();
                return PositionedDirectional(
                  start: box * (0.05 + 0.55 * t),
                  bottom: box * (0.05 + 0.7 * t),
                  child: Opacity(
                    opacity: widget.animate ? fade : 0.9,
                    child: Text(
                      i == 0 ? 'z' : 'Z',
                      style: TextStyle(
                        fontSize: widget.size * (0.075 + 0.05 * t),
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF9FC0FF),
                        height: 1,
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

/// Four-point stars flying outwards and fading (tap reaction).
class _SparklePainter extends CustomPainter {
  _SparklePainter(this.t, this.colors);
  final double t;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset(0, -s.height * 0.05));
    for (var i = 0; i < 8; i++) {
      final a = (i / 8) * 2 * math.pi + 0.4;
      final r = s.width * (0.28 + 0.32 * Curves.easeOut.transform(t));
      final p = c + Offset(math.cos(a), math.sin(a)) * r;
      final k = s.width * 0.055 * (1 - t * 0.5);
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: (1 - t).clamp(0.0, 1.0).toDouble());
      final path = Path()
        ..moveTo(p.dx, p.dy - k)
        ..quadraticBezierTo(p.dx, p.dy, p.dx + k, p.dy)
        ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + k)
        ..quadraticBezierTo(p.dx, p.dy, p.dx - k, p.dy)
        ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - k)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter o) => o.t != t;
}

/// Falling confetti for the big celebration (no package).
class _Confetti extends StatefulWidget {
  const _Confetti();
  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3600))
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) =>
              CustomPaint(size: Size.infinite, painter: _ConfettiPainter(_c.value)),
        ),
      );
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t);
  final double t;
  static const _colors = [
    Color(0xFFC8F23A),
    Color(0xFF4FA81E),
    Color(0xFFFF9600),
    Color(0xFFFFD54F),
    Color(0xFFFFFFFF),
    Color(0xFF4FC3F7),
  ];

  @override
  void paint(Canvas canvas, Size s) {
    final rnd = math.Random(7);
    for (var i = 0; i < 70; i++) {
      final x0 = rnd.nextDouble();
      final delay = rnd.nextDouble() * 0.35;
      final speed = 0.55 + rnd.nextDouble() * 0.6;
      final sway = (rnd.nextDouble() - 0.5) * 0.18;
      final rot = rnd.nextDouble() * 6.28;
      final color = _colors[i % _colors.length];
      final p = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (p <= 0) continue;
      final y = -20 + (s.height + 60) * p * speed * 1.25;
      final x = s.width * (x0 + sway * math.sin(p * 9 + i));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot + p * 10);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-5, -3, 10, 6), const Radius.circular(2)),
        Paint()..color = color.withValues(alpha: (1 - p * 0.6)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter o) => o.t != t;
}

/// Duolingo-style speech bubble with a tail on the mascot side.
class EcoFriendBubble extends StatelessWidget {
  const EcoFriendBubble({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final side = BorderSide(color: c.outline, width: 2);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.fromBorderSide(side),
          ),
          child: child,
        ),
        PositionedDirectional(
          start: -8,
          top: 24,
          child: Transform.rotate(
            angle: rtl ? -math.pi / 4 : math.pi / 4,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: c.surface,
                border: rtl
                    ? Border(right: side, bottom: side)
                    : Border(left: side, bottom: side),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dashboard hero: big mascot + speech bubble + EP / daily-goal chips.
/// Tap the mascot: it jumps and tells you a tip.
class EcoFriendCard extends ConsumerStatefulWidget {
  const EcoFriendCard({super.key});

  @override
  ConsumerState<EcoFriendCard> createState() => _EcoFriendCardState();
}

class _EcoFriendCardState extends ConsumerState<EcoFriendCard> {
  bool _warmed = false;
  int _tip = 0;
  bool _showTip = false;
  Timer? _tipTimer;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    // Scene (morning / day / evening / night) and the message slot follow the
    // clock even if the screen stays open. One cheap rebuild every 10 minutes.
    _clock = Timer.periodic(const Duration(minutes: 10), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _clock?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_warmed) return;
    _warmed = true;
    EcoFriendView.warm(context, 180);
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      EcoFriendView.warm(context, 180, moods: const [
        EcoFriendMood.thinking,
        EcoFriendMood.excited,
        EcoFriendMood.cheering,
        EcoFriendMood.proud,
        EcoFriendMood.sad,
      ]);
    });
  }

  void _poke() {
    _tipTimer?.cancel();
    setState(() {
      _tip = _tip % 4 + 1;
      _showTip = true;
    });
    _tipTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _showTip = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    final snap = ref.watch(ecoFriendProvider);
    final mood = snap.mood;
    final balance = ref.watch(balanceProvider).valueOrNull;
    final missions = ref.watch(missionsProvider);
    final done = missions.where((m) => m.complete).length;
    final total = missions.length;
    final lang = Localizations.localeOf(context).languageCode;

    final now = DateTime.now();
    final scene = EcoScene.at(now);
    final ctx = ref.watch(ecoMsgContextProvider);
    final level = ref.watch(levelProgressProvider);
    final sleepy = scene == EcoScene.night && !mood.isEvent && !_showTip;
    final accent = switch (scene) {
      EcoScene.morning => const Color(0xFFFF9F6B),
      EcoScene.day => c.emerald,
      EcoScene.evening => const Color(0xFFC265C9),
      EcoScene.night => const Color(0xFF5B7CFA),
    };

    final String message;
    if (_showTip && !mood.isEvent) {
      message = context.tr('ef_tip_$_tip');
    } else if (mood.isEvent) {
      message = snap.text(context.tr);
    } else {
      // Smart message: scene + real state (goal, streak, last recycle, level…),
      // rotating every 3 h, never repeating back to back.
      final m = EcoFriendMessages.pick(EcoFriendMessages.pool(scene, ctx), now);
      message = context.tr(m.key, m.args);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.gutter, Sp.md, Sp.gutter, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(Sp.sm, Sp.sm, Sp.md, Sp.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Rad.xl),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.24),
              accent.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.40)),
        ),
        child: LayoutBuilder(builder: (context, box) {
          final size = (box.maxWidth * 0.50).clamp(130.0, 220.0);
          return Row(
            children: [
              Semantics(
                button: true,
                label: 'EcoFriend',
                child: EcoFriendView(
                    mood: mood, size: size, sleepy: sleepy, onTap: _poke),
              ),
              const SizedBox(width: Sp.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => context.push('/challenges'),
                      child: EcoFriendBubble(
                        child: AnimatedSwitcher(
                          duration: Motion.base,
                          child: Text(
                            message,
                            key: ValueKey(message),
                            style: context.text.titleSmall,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: Sp.xs),
                    Wrap(spacing: Sp.xs, runSpacing: Sp.xxs, children: [
                      if (balance != null)
                        _Chip(
                            '${Fmt.number(balance, lang)} ${context.tr('ep_unit')}',
                            c.lime),
                      if (total > 0) _Chip('$done/$total', c.emerald),
                      if (ctx.streak > 0)
                        _Chip('🔥 ${ctx.streak}', const Color(0xFFF57C00)),
                      _Chip(context.tr(level.current.l10nKey), accent),
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

/// A screen's own EcoFriend: animated mascot + speech bubble with a message
/// that fits the screen. Live events (excited, thinking…) override [base].
class EcoFriendBanner extends ConsumerWidget {
  const EcoFriendBanner({
    super.key,
    required this.msgKey,
    this.base = EcoFriendMood.breathing,
    this.size = 92,
    this.padding = const EdgeInsets.symmetric(vertical: Sp.xs),
  });

  final String msgKey;
  final EcoFriendMood base;
  final double size;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(ecoFriendProvider);
    final mood = snap.mood.isEvent ? snap.mood : base;
    final text =
        snap.mood.isEvent ? snap.text(context.tr) : context.tr(msgKey);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          EcoFriendView(mood: mood, size: size),
          const SizedBox(width: Sp.sm),
          Expanded(
            child: EcoFriendBubble(
              child: AnimatedSwitcher(
                duration: Motion.base,
                child: Text(text,
                    key: ValueKey(text), style: context.text.titleSmall),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rewards on EVERY tab: a small excited toast for new EP, and a full-screen
/// confetti party (big EcoFriend) for cheering / proud (daily goal, level-up,
/// streak milestone). Tap to dismiss.
class EcoFriendCelebrationHost extends ConsumerStatefulWidget {
  const EcoFriendCelebrationHost({super.key});

  @override
  ConsumerState<EcoFriendCelebrationHost> createState() =>
      _EcoFriendCelebrationHostState();
}

class _EcoFriendCelebrationHostState
    extends ConsumerState<EcoFriendCelebrationHost> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<EcoFriendMood>(ecoFriendMoodProvider, (prev, next) {
      if (prev != next && _dismissed) setState(() => _dismissed = false);
    });
    final snap = ref.watch(ecoFriendProvider);
    final mood = snap.mood;
    final full = !_dismissed &&
        (mood == EcoFriendMood.cheering || mood == EcoFriendMood.proud);
    final toast = !_dismissed && mood == EcoFriendMood.excited;
    final text = snap.text(context.tr);
    final w = MediaQuery.sizeOf(context).width;

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !(full || toast),
        child: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              child: full
                  ? GestureDetector(
                      key: ValueKey('full-${mood.name}-${snap.msgKey}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _dismissed = true),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const ColoredBox(color: Color(0xB3000000)),
                          const _Confetti(),
                          SafeArea(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(Sp.gutter),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    EcoFriendView(
                                        mood: mood,
                                        size: math.min(w * 0.82, 340)),
                                    const SizedBox(height: Sp.md),
                                    Text(
                                      text,
                                      textAlign: TextAlign.center,
                                      style: context.text.headlineSmall
                                          ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: Sp.lg),
                                    FilledButton(
                                      onPressed: () =>
                                          setState(() => _dismissed = true),
                                      child: Text(context.tr('continue')),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('full-none')),
            ),
            PositionedDirectional(
              start: Sp.sm,
              end: Sp.sm,
              bottom: 84,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 340),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0, 0.35), end: Offset.zero)
                        .animate(anim),
                    child: child,
                  ),
                ),
                child: toast
                    ? GestureDetector(
                        key: const ValueKey('toast'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _dismissed = true),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            EcoFriendView(mood: mood, size: 150),
                            const SizedBox(width: Sp.xs),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 40),
                                child: EcoFriendBubble(
                                  child: Text(text,
                                      style: context.text.titleMedium),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('toast-none')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small static EcoFriend for empty / error / offline states.
class EcoFriendHint extends StatelessWidget {
  const EcoFriendHint(
      {super.key, this.size = 96, this.mood = EcoFriendMood.normal});
  final double size;

  /// `thinking` = puzzled (offline), `normal` = calm and ready to help.
  final EcoFriendMood mood;

  @override
  Widget build(BuildContext context) => EcoFriendView(
      mood: mood, size: size, animate: false, interactive: false);
}
