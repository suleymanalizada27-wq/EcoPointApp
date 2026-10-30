import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ep_button.dart';
import '../../../core/widgets/ep_feedback.dart';
import '../../challenges/data/gamification_repository.dart';
import '../../wallet/data/wallet_providers.dart';
import '../../wallet/domain/wallet_models.dart';

/// Opens a preview of the shareable "my EcoPoint results" picture.
void showShareCard(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _ShareSheet(),
  );
}

class _ShareSheet extends ConsumerStatefulWidget {
  const _ShareSheet();

  @override
  ConsumerState<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<_ShareSheet> {
  final GlobalKey _boundary = GlobalKey();
  bool _busy = false;

  String get _code =>
      ref.read(profileProvider).valueOrNull?.referralCode ?? '';

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ro = _boundary.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (ro == null) return;
      final image = await ro.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return;
      final dir = await Directory.systemTemp.createTemp('ecopoint_share');
      final file = File('${dir.path}/ecopoint.png');
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      final code = _code;
      final link = code.isEmpty ? '' : '${AppConstants.backendUrl}/invite/$code';
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: code.isEmpty
            ? context.tr('share_card_text_plain')
            : context.tr('referral_share_text', {'code': code, 'link': link}),
      );
    } catch (_) {
      if (mounted) {
        showEpToast(context, context.tr('error_generic'), kind: ToastKind.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(statsProvider).valueOrNull ?? WalletStats.empty;
    final scansMonth = ref.watch(scansThisMonthProvider).valueOrNull ?? 0;
    final streak = ref.watch(streakProvider).valueOrNull?.count ?? 0;
    final code = ref.watch(profileProvider).valueOrNull?.referralCode ?? '';
    final name = ref.watch(profileProvider).valueOrNull?.name ?? '';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Sp.gutter),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: FittedBox(
                  child: RepaintBoundary(
                    key: _boundary,
                    child: _CardArt(
                      name: name,
                      scansMonth: scansMonth,
                      totalScans: stats.scans,
                      earned: stats.earned,
                      streak: streak,
                      code: code,
                      labels: _Labels(
                        title: context.tr('share_card_title'),
                        month: context.tr('share_card_month'),
                        total: context.tr('share_card_total'),
                        earned: context.tr('share_card_earned'),
                        streak: context.tr('share_card_streak'),
                        code: context.tr('share_card_code'),
                        tagline: context.tr('share_card_tagline'),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Sp.md),
              EpButton(
                label: context.tr('share'),
                icon: Icons.ios_share_rounded,
                loading: _busy,
                onPressed: _share,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Labels {
  const _Labels({
    required this.title,
    required this.month,
    required this.total,
    required this.earned,
    required this.streak,
    required this.code,
    required this.tagline,
  });
  final String title, month, total, earned, streak, code, tagline;
}

/// Fixed 360×450 design (captured at 3× → 1080×1350 px), independent of the
/// app theme so the picture always looks the same.
class _CardArt extends StatelessWidget {
  const _CardArt({
    required this.name,
    required this.scansMonth,
    required this.totalScans,
    required this.earned,
    required this.streak,
    required this.code,
    required this.labels,
  });

  final String name;
  final int scansMonth;
  final int totalScans;
  final int earned;
  final int streak;
  final String code;
  final _Labels labels;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF6EE7B7);
    Widget stat(String value, String label) => Expanded(
          child: Column(
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF9DB3A6), fontSize: 11)),
            ],
          ),
        );

    return Container(
      width: 360,
      height: 450,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B3D2C), Color(0xFF000000)],
        ),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset('assets/images/logo.png', width: 96, height: 96),
          ),
          const SizedBox(height: 14),
          Text(labels.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: green, fontSize: 20, fontWeight: FontWeight.w800)),
          if (name.isNotEmpty)
            Text(name,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 18),
          Text('$scansMonth',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  height: 1.0)),
          Text(labels.month,
              style: const TextStyle(color: Color(0xFF9DB3A6), fontSize: 13)),
          const SizedBox(height: 20),
          Row(children: [
            stat(Fmt.number(totalScans), labels.total),
            stat(Fmt.number(earned), labels.earned),
            stat('$streak', labels.streak),
          ]),
          const Spacer(),
          if (code.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: green, width: 1.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(children: [
                Text(labels.code,
                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
                Text(code,
                    style: const TextStyle(
                        color: green,
                        fontSize: 24,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w800)),
              ]),
            ),
          const SizedBox(height: 10),
          Text(labels.tagline,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }
}
