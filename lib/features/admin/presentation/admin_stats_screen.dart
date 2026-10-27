import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ep_card.dart';
import '../../../core/widgets/state_views.dart';
import '../data/admin_api.dart';
import 'admin_common.dart';

final adminStatsProvider = FutureProvider.autoDispose<Map<String, Object?>>(
  (ref) => ref.watch(adminApiProvider).stats(),
);

class AdminStatsScreen extends ConsumerWidget {
  const AdminStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminStatsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Statistika')),
      body: AsyncBody<Map<String, Object?>>(
        value: stats,
        onRetry: () => ref.invalidate(adminStatsProvider),
        data: (m) {
          final days = (m['days'] as List? ?? const [])
              .map((e) => Map<String, Object?>.from(e as Map))
              .toList();
          final top = (m['topRewards'] as List? ?? const [])
              .map((e) => Map<String, Object?>.from(e as Map))
              .toList();
          List<double> series(String k) =>
              [for (final d in days) ((d[k] as num?) ?? 0).toDouble()];
          final labels = [
            for (final d in days) '${d['day']}'.substring(5).replaceAll('-', '.')
          ];
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(adminStatsProvider.future),
            child: ListView(padding: adminPad, children: [
              const Text(
                'Son 14 gün. Sayğaclar bu yeniləmədən sonra toplanmağa başlayır, '
                'ona görə əvvəlki günlər 0 görünür.',
              ),
              const SizedBox(height: Sp.md),
              _ChartCard(
                title: 'Yeni istifadəçilər',
                values: series('signups'),
                labels: labels,
                color: context.ep.emerald,
              ),
              _ChartCard(
                title: 'Qazanılan EP',
                values: series('earnedEp'),
                labels: labels,
                color: context.ep.lime,
              ),
              _ChartCard(
                title: 'Xərclənən EP',
                values: series('spentEp'),
                labels: labels,
                color: context.ep.info,
              ),
              _ChartCard(
                title: 'Skan sayı',
                values: series('earns'),
                labels: labels,
                color: context.ep.emerald,
              ),
              EpCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ən çox alınan mükafatlar',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: Sp.sm),
                    if (top.isEmpty) const Text('Hələ məlumat yoxdur.'),
                    for (final r in top)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(children: [
                          Expanded(child: Text('${r['name']}')),
                          Text('${r['count']}×'),
                        ]),
                      ),
                  ],
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.values,
    required this.labels,
    required this.color,
  });

  final String title;
  final List<double> values;
  final List<String> labels;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final total = values.fold<double>(0, (a, b) => a + b);
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.sm),
      child: EpCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              Text('cəmi ${total.round()}'),
            ]),
            const SizedBox(height: Sp.sm),
            SizedBox(
              height: 120,
              width: double.infinity,
              child: CustomPaint(
                painter: _BarPainter(
                  values: values,
                  color: color,
                  grid: context.ep.outline,
                  text: context.ep.textSecondary,
                  labels: labels,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.values,
    required this.color,
    required this.grid,
    required this.text,
    required this.labels,
  });

  final List<double> values;
  final Color color;
  final Color grid;
  final Color text;
  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const bottom = 16.0;
    final h = size.height - bottom;
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final scale = maxV <= 0 ? 0.0 : h / maxV;
    final slot = size.width / values.length;
    final barW = slot * 0.62;

    final line = Paint()
      ..color = grid
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, h), Offset(size.width, h), line);

    final paint = Paint()..color = color;
    for (var i = 0; i < values.length; i++) {
      final bh = values[i] * scale;
      final x = i * slot + (slot - barW) / 2;
      if (bh > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, h - bh, barW, bh),
            const Radius.circular(3),
          ),
          paint,
        );
      }
      // label every 3rd day (and the last) to avoid clutter
      if (i % 3 == 0 || i == values.length - 1) {
        _label(canvas, labels[i], Offset(i * slot + slot / 2, h + 3));
      }
    }
    if (maxV > 0) {
      _label(canvas, maxV.round().toString(), const Offset(14, 0), left: true);
    }
  }

  void _label(Canvas canvas, String s, Offset center, {bool left = false}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: 9, color: text)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = left ? 0.0 : (center.dx - tp.width / 2).clamp(0.0, double.infinity);
    tp.paint(canvas, Offset(dx, center.dy));
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      old.values != values || old.color != color;
}
