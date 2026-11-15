import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One-shot celebration: coloured pieces fall from the top. Purely visual
/// (ignored by touch and screen readers) and skipped when the system asks
/// for reduced motion.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.pieces = 36});
  final int pieces;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();
  late final List<_Piece> _pieces = () {
    final r = math.Random(7);
    return List<_Piece>.generate(
      widget.pieces,
      (_) => _Piece(
        x: r.nextDouble(),
        delay: r.nextDouble() * 0.35,
        drift: (r.nextDouble() - 0.5) * 0.25,
        size: 5 + r.nextDouble() * 5,
        turns: 1 + r.nextDouble() * 3,
        color: _palette[r.nextInt(_palette.length)],
      ),
    );
  }();

  static const _palette = <Color>[
    Color(0xFF10B981),
    Color(0xFFA3E635),
    Color(0xFFF59E0B),
    Color(0xFF38BDF8),
    Color(0xFFF472B6),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return const SizedBox.shrink();
    return ExcludeSemantics(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) => CustomPaint(
            painter: _ConfettiPainter(_pieces, _ctrl.value),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _Piece {
  const _Piece({
    required this.x,
    required this.delay,
    required this.drift,
    required this.size,
    required this.turns,
    required this.color,
  });
  final double x;
  final double delay;
  final double drift;
  final double size;
  final double turns;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);
  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final k = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (k <= 0) continue;
      final dx = (p.x + p.drift * k) * size.width;
      final dy = -p.size + (size.height + p.size * 2) * Curves.easeIn.transform(k);
      final paint = Paint()
        ..color = p.color.withValues(alpha: (1 - k * 0.8).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.turns * math.pi * 2 * k);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

/// Gentle repeating "breathing" scale (e.g. the streak flame). Static when
/// [active] is false or reduced motion is requested.
class PulseScale extends StatefulWidget {
  const PulseScale({super.key, required this.child, this.active = true});
  final Widget child;
  final bool active;

  @override
  State<PulseScale> createState() => _PulseScaleState();
}

class _PulseScaleState extends State<PulseScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(PulseScale old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.active) {
      if (!_ctrl.isAnimating) _ctrl.repeat(reverse: true);
    } else {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active || MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.14)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}

/// Fires a one-off confetti burst above everything (e.g. after the sheet that
/// triggered it has closed). Removes itself; no-op without an overlay.
void showConfetti(BuildContext context) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => const Positioned.fill(child: ConfettiBurst()),
  );
  overlay.insert(entry);
  Future<void>.delayed(const Duration(milliseconds: 2200), () {
    if (entry.mounted) entry.remove();
  });
}

/// Springy press feedback: the child shrinks a little while a finger is down
/// and eases back. Does not take part in the gesture arena (taps still reach
/// the child's own InkWell/GestureDetector). Off for reduced motion.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.scale = 0.97,
  });

  final Widget child;
  final bool enabled;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (!widget.enabled || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final calm = MediaQuery.disableAnimationsOf(context);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down && !calm ? widget.scale : 1,
        duration: Duration(milliseconds: _down ? 90 : 220),
        curve: _down ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

/// Fades and slides its child up once, [index] * 55 ms after first build —
/// gives lists a staggered, fluid entrance. Plays once per mounted widget.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});
  final Widget child;
  final int index;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final Animation<double> _t =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    final ms = (widget.index.clamp(0, 10)) * 55;
    Future<void>.delayed(Duration(milliseconds: ms), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(
          offset: Offset(0, 22 * (1 - _t.value)),
          child: child,
        ),
      ),
    );
  }
}
