import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../app/localization/app_localizations.dart';
import '../utils/formatters.dart';
import '../../features/challenges/data/gamification_repository.dart';
import '../../features/ecofriend/application/ecofriend_controller.dart';
import '../../features/wallet/data/wallet_providers.dart';
import 'firebase_providers.dart';
import 'preferences.dart';

const _goals = [3, 7, 14, 30, 60, 100, 365];
/// Streak tiers: (min days, text key, flame variant 0..3).
const _tiers = [
  (100, 'widget_motto_hero', 3),
  (30, 'widget_motto_legend', 3),
  (14, 'widget_motto_unstoppable', 2),
  (7, 'widget_motto_fire', 1),
  (3, 'widget_motto_keep', 0),
  (1, 'widget_motto_start', 0),
];
const _androidWidgets = [
  'az.ecopoint.widget.EpWidgetXsProvider',
  'az.ecopoint.widget.EpWidgetProvider',
  'az.ecopoint.widget.EpWidgetMProvider',
  'az.ecopoint.widget.EpWidgetLProvider',
  'az.ecopoint.widget.EpWidgetXlProvider',
];

/// Keeps the Android home-screen widget (balance + streak) in step with the
/// app. Best effort: if the widget was never added, or the native part is not
/// installed, every call is ignored.
final widgetSyncProvider = Provider<void>((ref) {
  if (kIsWeb || !Platform.isAndroid) return;
  final uid = ref.watch(uidProvider);
  final balance = ref.watch(balanceProvider).valueOrNull;
  final streak = ref.watch(streakProvider).valueOrNull;
  final locale = ref.watch(localeProvider);
  final l = AppLocalizations(locale);
  // EcoFriend: same single source of truth as the Dashboard. The widget picks
  // the mood itself at render time (event expiry / inactivity, see Kotlin),
  // so it stays correct even while the app is closed.
  final ef = ref.watch(ecoFriendProvider.select((s) => s.widget));
  final missions = ref.watch(missionsProvider);
  final dailyDone = missions.where((m) => m.complete).length;
  final dailyTotal = missions.length;
  final dailyPct =
      dailyTotal == 0 ? 0 : (dailyDone * 100 ~/ dailyTotal).clamp(0, 100);
  final weekly = ref.watch(weeklyActivityProvider).valueOrNull ?? const [];
  final weekEp = weekly.fold<int>(0, (a, b) => a + b.earned);
  final activeDays = weekly.where((b) => b.earned > 0).length;
  final level = ref.watch(levelProgressProvider);
  final impact = ref.watch(impactProvider);

  final lang = locale.languageCode;
  final balanceText =
      uid == null || balance == null ? '—' : Fmt.number(balance, lang);
  final streakText = uid == null || streak == null || streak.count <= 0
      ? ''
      : '${streak.count}';
  // Progress to the next streak milestone, e.g. 5/7 -> 71 %.
  final days = streak?.count ?? 0;
  final goal = _goals.firstWhere((g) => g > days, orElse: () => days);
  final goalText = days <= 0 ? '' : '$days/$goal';
  final goalPct = days <= 0 || goal <= 0 ? 0 : (days * 100 ~/ goal).clamp(0, 100);
  final tier = _tiers.where((t) => days >= t.$1).firstOrNull;
  final motto = tier == null ? '' : l.tr(tier.$2);
  final flame = tier?.$3 ?? 0;
  unawaited(() async {
    try {
      await HomeWidget.saveWidgetData<String>('label', 'EcoPoint');
      await HomeWidget.saveWidgetData<String>('balance_num', balanceText);
      await HomeWidget.saveWidgetData<String>('unit', l.tr('ep_unit'));
      await HomeWidget.saveWidgetData<String>('streak', streakText);
      await HomeWidget.saveWidgetData<String>('goal_text', goalText);
      await HomeWidget.saveWidgetData<String>('goal_pct', '$goalPct');
      await HomeWidget.saveWidgetData<String>('motto', motto);
      await HomeWidget.saveWidgetData<String>('tier', '$flame');
      // --- EcoFriend (mood is resolved natively from these) ---
      await HomeWidget.saveWidgetData<String>('ef_event', ef.eventMood);
      await HomeWidget.saveWidgetData<String>('ef_until', '${ef.eventUntilMs}');
      await HomeWidget.saveWidgetData<String>(
          'ef_last_active', '${ef.lastActiveMs}');
      for (final m in const ['sad', 'excited', 'cheering', 'proud']) {
        await HomeWidget.saveWidgetData<String>('ef_msg_$m', l.tr('ef_$m'));
      }
      // Calm day: show the daily-goal progress like the in-app bubble.
      await HomeWidget.saveWidgetData<String>(
          'ef_msg_normal',
          dailyTotal > 0 && dailyDone < dailyTotal
              ? l.tr('ef_goal_progress', {'done': dailyDone, 'total': dailyTotal})
              : l.tr('ef_normal'));
      await HomeWidget.saveWidgetData<String>('ef_msg_morning', l.tr('ef_w_morning'));
      await HomeWidget.saveWidgetData<String>('ef_msg_night', l.tr('ef_w_night'));
      await HomeWidget.saveWidgetData<String>('ef_msg_evening', l.tr('ef_w_evening'));
      // Week row (oldest -> today): 1 = day with confirmed EP.
      await HomeWidget.saveWidgetData<String>(
          'week_dots',
          weekly
              .skip(weekly.length > 7 ? weekly.length - 7 : 0)
              .map((b) => b.earned > 0 ? '1' : '0')
              .join()
              .padLeft(7, '0'));
      await HomeWidget.saveWidgetData<String>('lbl_scan', l.tr('nav_scan'));
      await HomeWidget.saveWidgetData<String>('lbl_missions', l.tr('ch_title'));
      await HomeWidget.saveWidgetData<String>(
          'lbl_history', l.tr('history_title'));
      await HomeWidget.saveWidgetData<String>('level_text',
          l.tr(level.current.l10nKey));
      await HomeWidget.saveWidgetData<String>(
          'daily_text', dailyTotal == 0 ? '' : '$dailyDone/$dailyTotal');
      await HomeWidget.saveWidgetData<String>('daily_pct', '$dailyPct');
      await HomeWidget.saveWidgetData<String>(
          'week_text', '+${Fmt.number(weekEp, lang)} ${l.tr('ep_unit')}');
      await HomeWidget.saveWidgetData<String>('week_days', '$activeDays/7');
      await HomeWidget.saveWidgetData<String>(
          'impact_text', '${impact.plasticGrams} g · ${impact.co2Grams} g CO₂');
      for (final w in _androidWidgets) {
        await HomeWidget.updateWidget(qualifiedAndroidName: w);
      }
    } catch (_) {}
  }());
});
