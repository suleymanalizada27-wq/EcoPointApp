import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/errors/failure.dart';
import '../../../core/utils/qr_payload.dart';
import '../../../core/widgets/ep_button.dart';
import '../../../core/widgets/ep_card.dart';
import '../../../core/widgets/ep_feedback.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../ecofriend/application/ecofriend_controller.dart';
import '../../ecofriend/domain/ecofriend_engine.dart';
import '../../ecofriend/presentation/ecofriend_view.dart';
import '../data/qr_repository.dart';

enum _Gate { checking, granted, denied, permanentlyDenied }

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with WidgetsBindingObserver {
  MobileScannerController? _controller;
  _Gate _gate = _Gate.checking;

  /// True while a code is being verified or a result is on screen: further
  /// detections are ignored (duplicate-scan prevention).
  bool _locked = false;
  bool _torch = false;
  String? _message; // transient hint under the frame
  String? _lastRaw;
  DateTime _lastRawAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
    // EcoFriend "thinking" while the scanner is open (not during build).
    _ef = ref.read(ecoFriendProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ef.thinking(_efToken);
    });
  }

  static const String _efToken = 'scanner';
  late final EcoFriendController _ef;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    final ef = _ef;
    Future<void>.microtask(() => ef.endThinking(_efToken));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check after returning from system settings.
    if (state == AppLifecycleState.resumed &&
        (_gate == _Gate.denied || _gate == _Gate.permanentlyDenied)) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission({bool request = false}) async {
    var status = await Permission.camera.status;
    if (!status.isGranted && request) {
      status = await Permission.camera.request();
    }
    if (!mounted) return;
    if (status.isGranted || status.isLimited) {
      _controller ??= MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        formats: const [BarcodeFormat.qrCode],
      );
      setState(() => _gate = _Gate.granted);
    } else if (status.isPermanentlyDenied) {
      setState(() => _gate = _Gate.permanentlyDenied);
    } else {
      setState(() => _gate = _Gate.denied);
    }
  }

  void _hint(String message) {
    setState(() => _message = message);
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted && _message == message) setState(() => _message = null);
    });
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_locked) return;
    String? raw;
    for (final b in capture.barcodes) {
      if (b.rawValue != null && b.rawValue!.isNotEmpty) {
        raw = b.rawValue;
        break;
      }
    }
    if (raw == null) return;

    // Same invalid code in view: don't spam the user.
    final now = DateTime.now();
    if (raw == _lastRaw && now.difference(_lastRawAt).inSeconds < 3) return;
    _lastRaw = raw;
    _lastRawAt = now;

    final payload = QrPayload.parse(raw);
    if (!payload.isValid) {
      HapticFeedback.heavyImpact();
      _hint(context.tr('scan_invalid'));
      return;
    }

    if (payload.isUser) {
      _locked = true;
      HapticFeedback.mediumImpact();
      await _controller?.stop();
      if (!mounted) return;
      final send = await confirmSheet(
        context,
        title: context.tr('scan_friend_title'),
        body: context.tr('scan_friend_body'),
        confirmLabel: context.tr('home_send'),
        icon: Icons.person_add_alt_1_rounded,
      );
      if (!mounted) return;
      if (send) {
        context.pushReplacement('/transfer?to=${payload.userId}');
      } else {
        _locked = false;
        await _controller?.start();
      }
      return;
    }

    // Bin code.
    _locked = true;
    HapticFeedback.mediumImpact();
    setState(() => _message = context.tr('scan_processing'));
    await _controller?.stop();
    QrSession session;
    try {
      session = await ref.read(qrRepositoryProvider).open(payload);
    } on Failure catch (f) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      showEpToast(context, context.tr(f.l10nKey), kind: ToastKind.error);
      // Allow another attempt, but never the same raw value within 3s.
      _lastRaw = raw;
      _lastRawAt = DateTime.now();
      setState(() => _message = null);
      _locked = false;
      await _controller?.start();
      return;
    }
    if (!mounted) return;
    setState(() => _message = null);

    // The bin itself confirms the deposit; we only wait for that.
    final outcome = await showModalBottomSheet<QrSessionStatus>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => _WaitSheet(session: session),
    );
    if (!mounted) return;
    final done = outcome?.result;
    if (outcome != null && outcome.state == QrSessionState.done && done != null) {
      HapticFeedback.heavyImpact();
      // Server-confirmed deposit → EcoFriend reacts (release thinking first).
      _ef.endThinking(_efToken);
      _ef.scanConfirmed(session.sessionId);
      await _showSuccess(done);
      if (mounted) _ef.thinking(_efToken);
      return;
    }
    if (outcome != null) {
      HapticFeedback.heavyImpact();
      final key = outcome.state == QrSessionState.failed
          ? (outcome.reason == 'daily-limit'
              ? 'scan_daily_limit'
              : 'error_generic')
          : 'scan_wait_expired';
      showEpToast(context, context.tr(key), kind: ToastKind.error);
    }
    _lastRaw = raw;
    _lastRawAt = DateTime.now();
    _locked = false;
    await _controller?.start();
  }

  Future<void> _showSuccess(QrRedeemResult r) async {
    final again = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) {
        final c = ctx.ep;
        return Stack(children: [
          SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Sp.gutter, 0, Sp.gutter, Sp.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Consumer(
                  builder: (context, ref, _) => Row(
                    children: [
                      EcoFriendView(
                        mood: ref.watch(ecoFriendMoodProvider),
                        size: 150,
                      ),
                      const SizedBox(width: Sp.xs),
                      Expanded(
                        child: EcoFriendBubble(
                          child: Text(context.tr('ef_excited'),
                              style: ctx.text.titleMedium),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Sp.md),
                Text(ctx.tr('scan_success_title'),
                    textAlign: TextAlign.center,
                    style: ctx.text.titleLarge),
                const SizedBox(height: Sp.xs),
                CountUpText(
                  value: r.ep,
                  format: (n) => '+$n ${ctx.tr('ep_unit')}',
                  style: ctx.text.displayMedium?.copyWith(color: c.lime),
                ),
                if (r.multiplier > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: Sp.xs),
                    child: Center(
                      child: EpBadge(
                        label: ctx.tr('scan_pro_bonus', {'n': r.multiplier}),
                        color: c.lime,
                      ),
                    ),
                  ),
                const SizedBox(height: Sp.xs),
                Text(ctx.tr('scan_success_body'),
                    textAlign: TextAlign.center,
                    style: ctx.text.bodyMedium
                        ?.copyWith(color: c.textSecondary)),
                const SizedBox(height: Sp.xl),
                EpButton(
                  label: ctx.tr('done'),
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
                const SizedBox(height: Sp.xs),
                EpButton(
                  label: ctx.tr('scan_again'),
                  kind: EpButtonKind.ghost,
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              ],
            ),
          ),
          ),
          const Positioned.fill(child: ConfettiBurst()),
        ]);
      },
    );
    if (!mounted) return;
    if (again == true) {
      setState(() => _message = null);
      _locked = false;
      await _controller?.start();
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: switch (_gate) {
        _Gate.checking => const LoadingView(),
        _Gate.granted => _buildCamera(context),
        _ => _buildPermission(context),
      },
    );
  }

  Widget _buildPermission(BuildContext context) {
    final c = context.ep;
    final permanent = _gate == _Gate.permanentlyDenied;
    return Container(
      color: c.bg,
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: IconButton(
                tooltip: context.tr('close'),
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(Sp.gutter),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: c.emerald.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.qr_code_scanner_rounded,
                          size: 46, color: c.emerald),
                    ),
                    const SizedBox(height: Sp.xl),
                    Text(context.tr('scan_perm_title'),
                        textAlign: TextAlign.center,
                        style: context.text.headlineSmall),
                    const SizedBox(height: Sp.sm),
                    Text(
                      permanent
                          ? context.tr('scan_perm_denied')
                          : context.tr('scan_perm_body'),
                      textAlign: TextAlign.center,
                      style: context.text.bodyLarge
                          ?.copyWith(color: c.textSecondary),
                    ),
                    const SizedBox(height: Sp.xl),
                    EpButton(
                      label: permanent
                          ? context.tr('scan_perm_settings')
                          : context.tr('scan_perm_grant'),
                      onPressed: () => permanent
                          ? openAppSettings()
                          : _checkPermission(request: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCamera(BuildContext context) {
    final c = context.ep;
    final size = MediaQuery.of(context).size;
    final frame = (size.shortestSide * 0.68).clamp(220.0, 320.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _controller!,
          onDetect: _onDetect,
          errorBuilder: (context, error, child) {
            final denied =
                error.errorCode == MobileScannerErrorCode.permissionDenied;
            return Container(
              color: c.bg,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(Sp.gutter),
              child: Text(
                denied
                    ? context.tr('scan_perm_denied')
                    : context.tr('scan_unsupported_camera'),
                textAlign: TextAlign.center,
                style: context.text.bodyLarge,
              ),
            );
          },
        ),
        // Dimmed surround with a clear scan window.
        IgnorePointer(
          child: CustomPaint(
            painter: _ScrimPainter(frame: frame, radius: 28),
            size: Size.infinite,
          ),
        ),
        IgnorePointer(
          child: Center(
            child: _CornerFrame(size: frame, color: c.lime, busy: _locked),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Sp.xs),
            child: Row(
              children: [
                EpIconButton(
                  icon: Icons.close_rounded,
                  semanticLabel: context.tr('close'),
                  onPressed: () => context.pop(),
                ),
                const Spacer(),
                Text(context.tr('scan_title'),
                    style: context.text.titleMedium
                        ?.copyWith(color: Colors.white)),
                const Spacer(),
                EpIconButton(
                  icon: _torch
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  semanticLabel: context.tr('scan_torch'),
                  onPressed: () async {
                    await _controller?.toggleTorch();
                    if (mounted) setState(() => _torch = !_torch);
                  },
                ),
              ],
            ),
          ),
        ),
        // EcoFriend: thinking while scanning / waiting for the server.
        Positioned(
          left: Sp.sm,
          right: Sp.sm,
          top: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 52),
              child: IgnorePointer(
                child: Consumer(
                  builder: (context, ref, _) {
                    final m = ref.watch(ecoFriendMoodProvider);
                    return Row(
                      children: [
                        EcoFriendView(mood: m, size: 96),
                        const SizedBox(width: Sp.xs),
                        Flexible(
                          child: EcoFriendBubble(
                            child: Text(
                              context.tr(m == EcoFriendMood.thinking
                                  ? 'ef_tip_3'
                                  : m.messageKey),
                              style: context.text.titleSmall,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: Sp.gutter,
          right: Sp.gutter,
          bottom: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: Sp.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: Motion.fast,
                    child: _message == null
                        ? const SizedBox(key: ValueKey('none'), height: 0)
                        : Container(
                            key: ValueKey(_message),
                            margin: const EdgeInsets.only(bottom: Sp.sm),
                            padding: const EdgeInsets.symmetric(
                                horizontal: Sp.md, vertical: Sp.xs),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(Rad.pill),
                            ),
                            child: Semantics(
                              liveRegion: true,
                              child: Text(_message!,
                                  textAlign: TextAlign.center,
                                  style: context.text.bodyMedium
                                      ?.copyWith(color: Colors.white)),
                            ),
                          ),
                  ),
                  Text(
                    context.tr('scan_hint'),
                    textAlign: TextAlign.center,
                    style: context.text.bodyLarge
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('scan_hint_friend'),
                    textAlign: TextAlign.center,
                    style: context.text.bodySmall
                        ?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScrimPainter extends CustomPainter {
  _ScrimPainter({required this.frame, required this.radius});
  final double frame;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final hole = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: size.center(Offset.zero),
        width: frame,
        height: frame,
      ),
      Radius.circular(radius),
    );
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(hole);
    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(_ScrimPainter old) =>
      old.frame != frame || old.radius != radius;
}

class _CornerFrame extends StatefulWidget {
  const _CornerFrame({
    required this.size,
    required this.color,
    required this.busy,
  });
  final double size;
  final Color color;
  final bool busy;

  @override
  State<_CornerFrame> createState() => _CornerFrameState();
}

class _CornerFrameState extends State<_CornerFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _scan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _scan,
        builder: (context, _) => CustomPaint(
          painter: _CornerPainter(
            color: widget.color,
            progress: widget.busy ? 0.5 : _scan.value,
            showLine: !widget.busy,
          ),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter({
    required this.color,
    required this.progress,
    required this.showLine,
  });
  final Color color;
  final double progress;
  final bool showLine;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const len = 34.0;
    const r = 28.0;
    final w = size.width;
    final h = size.height;

    Path corner(double x, double y, double dx, double dy) => Path()
      ..moveTo(x, y + dy * len)
      ..lineTo(x, y + dy * r)
      ..quadraticBezierTo(x, y, x + dx * r, y)
      ..lineTo(x + dx * len, y);

    canvas.drawPath(corner(0, 0, 1, 1), p);
    canvas.drawPath(corner(w, 0, -1, 1), p);
    canvas.drawPath(corner(0, h, 1, -1), p);
    canvas.drawPath(corner(w, h, -1, -1), p);

    if (showLine) {
      final y = 20 + (h - 40) * progress;
      canvas.drawLine(
        Offset(24, y),
        Offset(w - 24, y),
        Paint()
          ..color = color.withValues(alpha: 0.7)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_CornerPainter old) =>
      old.progress != progress || old.color != color || old.showLine != showLine;
}

/// "Put your waste into the bin": polls the server until the bin confirms.
class _WaitSheet extends ConsumerStatefulWidget {
  const _WaitSheet({required this.session});
  final QrSession session;

  @override
  ConsumerState<_WaitSheet> createState() => _WaitSheetState();
}

class _WaitSheetState extends ConsumerState<_WaitSheet> {
  Timer? _poll;
  Timer? _tick;
  int _left = 0;
  bool _busy = false;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _left = _secondsLeft();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _left = _secondsLeft());
    });
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _check());
    _check();
  }

  int _secondsLeft() {
    final n =
        widget.session.expiresAt.difference(DateTime.now()).inSeconds;
    return n < 0 ? 0 : n;
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  void _finish(QrSessionStatus? s) {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.of(context).pop(s);
  }

  Future<void> _check() async {
    if (_busy || _closed) return;
    _busy = true;
    try {
      final st = await ref.read(qrRepositoryProvider).status(widget.session);
      if (st.state != QrSessionState.open) {
        _finish(st.state == QrSessionState.cancelled ? null : st);
      }
    } catch (_) {
      // Network hiccup: the next poll retries; the countdown still ends it.
    } finally {
      _busy = false;
    }
    if (_secondsLeft() <= 0 && !_closed) {
      // One last look, then give up.
      try {
        final st = await ref.read(qrRepositoryProvider).status(widget.session);
        _finish(st);
      } catch (_) {
        _finish(const QrSessionStatus(QrSessionState.expired));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    return PopScope(
      canPop: false,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Sp.gutter, Sp.md, Sp.gutter, Sp.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    strokeWidth: 5,
                    color: c.emerald,
                    semanticsLabel: context.tr('scan_wait_title'),
                  ),
                ),
              ),
              const SizedBox(height: Sp.md),
              Text(context.tr('scan_wait_title'),
                  textAlign: TextAlign.center, style: context.text.titleLarge),
              const SizedBox(height: Sp.xs),
              Text(
                widget.session.binName,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: Sp.xs),
              Text(context.tr('scan_wait_body'),
                  textAlign: TextAlign.center,
                  style:
                      context.text.bodyMedium?.copyWith(color: c.textSecondary)),
              const SizedBox(height: Sp.sm),
              Text(context.tr('scan_wait_left', {'n': _left}),
                  textAlign: TextAlign.center,
                  style: context.text.labelLarge
                      ?.copyWith(color: c.textTertiary)),
              const SizedBox(height: Sp.lg),
              EpButton(
                label: context.tr('scan_wait_cancel'),
                kind: EpButtonKind.ghost,
                onPressed: () async {
                  await ref.read(qrRepositoryProvider).cancel(widget.session);
                  _finish(null);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
