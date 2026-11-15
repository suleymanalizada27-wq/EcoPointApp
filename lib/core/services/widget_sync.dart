import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../app/localization/app_localizations.dart';
import '../utils/formatters.dart';
import '../../features/challenges/data/gamification_repository.dart';
import '../../features/wallet/data/wallet_providers.dart';
import 'firebase_providers.dart';
import 'preferences.dart';

const _androidWidget = 'az.ecopoint.widget.EpWidgetProvider';

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

  final lang = locale.languageCode;
  final balanceText =
      uid == null || balance == null ? '—' : Fmt.number(balance, lang);
  final streakText = uid == null || streak == null || streak.count <= 0
      ? ''
      : '🔥 ${streak.count}';
  final tagline = l.tr('onb_1_title');
  unawaited(() async {
    try {
      await HomeWidget.saveWidgetData<String>('label', 'EcoPoint');
      await HomeWidget.saveWidgetData<String>('balance_num', balanceText);
      await HomeWidget.saveWidgetData<String>('unit', l.tr('ep_unit'));
      await HomeWidget.saveWidgetData<String>('tagline', tagline);
      await HomeWidget.saveWidgetData<String>('streak', streakText);
      await HomeWidget.updateWidget(qualifiedAndroidName: _androidWidget);
    } catch (_) {}
  }());
});
