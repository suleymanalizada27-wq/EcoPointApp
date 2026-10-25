import 'package:flutter/material.dart';

import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../wallet/domain/activity_aggregator.dart';

/// Dependency-free grouped bar chart: earned (emerald) vs spent (blue) per
/// day. Bars animate in; labels thin out automatically for long ranges.
class EpBarChart extends StatelessWidget {
  const EpBarChart({
    super.key,
    required this.buckets,
    required this.locale,
    this.height = 160,
    this.showSpent = true,
  });

  final List<DayBucket> buckets;
  final String locale;
  final double height;
  final bool showSpent;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    var maxV = 1;
    for (final b in buckets) {
      if (b.earned > maxV) maxV = b.earned;
      if (showSpent && b.spent > maxV) maxV = b.spent;
    }
    final dense = buckets.length > 10;
    final labelEvery = dense ? 5 : 1;

    return SizedBox(
      height: height + 28,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < buckets.length; i++)
            Expanded(
              child: _Column(
                bucket: buckets[i],
                maxValue: maxV,
                height: height,
                showSpent: showSpent,
                dense: dense,
                label: (i % labelEvery == 0 || i == buckets.length - 1)
                    ? (dense
                        ? '${buckets[i].day.day}'
                        : Fmt.weekdayShort(buckets[i].day, locale))
                    : '',
                isToday: i == buckets.length - 1,
                earnedColor: c.emerald,
                spentColor: c.info,
                trackColor: c.surfaceRaised,
                labelColor: c.textTertiary,
                todayColor: c.lime,
              ),
            ),
        ],
      ),
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({
    required this.bucket,
    required this.maxValue,
    required this.height,
    required this.showSpent,
    required this.dense,
    required this.label,
    required this.isToday,
    required this.earnedColor,
    required this.spentColor,
    required this.trackColor,
    required this.labelColor,
    required this.todayColor,
  });

  final DayBucket bucket;
  final int maxValue;
  final double height;
  final bool showSpent;
  final bool dense;
  final String label;
  final bool isToday;
  final Color earnedColor;
  final Color spentColor;
  final Color trackColor;
  final Color labelColor;
  final Color todayColor;

  @override
  Widget build(BuildContext context) {
    final barW = dense ? 4.0 : 12.0;

    Widget bar(int value, Color color) {
      final target = value / maxValue;
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: target),
        duration: Motion.slow,
        curve: Motion.curve,
        builder: (context, t, _) => Container(
          width: barW,
          height: value == 0 ? 3 : (height * t).clamp(3.0, height),
          decoration: BoxDecoration(
            color: value == 0 ? trackColor : color,
            borderRadius: BorderRadius.circular(barW / 2),
          ),
        ),
      );
    }

    return Semantics(
      label:
          '${Fmt.date(bucket.day, null)}: +${bucket.earned}${showSpent ? ' −${bucket.spent}' : ''}',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              bar(bucket.earned, earnedColor),
              if (showSpent && !dense) ...[
                const SizedBox(width: 3),
                bar(bucket.spent, spentColor),
              ],
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 16,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.visible,
              softWrap: false,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isToday ? todayColor : labelColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
