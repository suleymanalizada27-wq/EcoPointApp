import 'package:ecopoint_pro/app/localization/app_localizations.dart';
import 'package:ecopoint_pro/features/ecofriend/domain/ecofriend_messages.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

EcoMsgContext ctx(DateTime now,
        {int goalPct = -1,
        int streak = 0,
        bool activeToday = true,
        DateTime? lastScan,
        double level = 0,
        bool hasEarned = true,
        int inactive = 0}) =>
    EcoMsgContext(
      now: now,
      goalPct: goalPct,
      streak: streak,
      activeToday: activeToday,
      lastScan: lastScan,
      levelFraction: level,
      hasEarned: hasEarned,
      inactiveDays: inactive,
    );

void main() {
  test('scene boundaries: 05 / 10 / 16 / 20 (night wraps midnight)', () {
    EcoScene at(int h, [int m = 0]) => EcoScene.at(DateTime(2026, 11, 18, h, m));
    expect(at(4, 59), EcoScene.night);
    expect(at(5), EcoScene.morning);
    expect(at(9, 59), EcoScene.morning);
    expect(at(10), EcoScene.day);
    expect(at(15, 59), EcoScene.day);
    expect(at(16), EcoScene.evening);
    expect(at(19, 59), EcoScene.evening);
    expect(at(20), EcoScene.night);
    expect(at(0), EcoScene.night);
  });

  test('every message key used by the engine exists in all 16 languages', () {
    final keys = <String>{};
    final t = DateTime(2026, 11, 18, 17);
    for (final s in EcoScene.values) {
      for (final c in [
        ctx(t),
        ctx(t, goalPct: 0),
        ctx(t, goalPct: 55, streak: 4, lastScan: t, level: 0.9),
        ctx(t, goalPct: 85, streak: 4, activeToday: false, inactive: 4),
        ctx(t, goalPct: 100, hasEarned: false),
      ]) {
        keys.addAll(EcoFriendMessages.pool(s, c).map((m) => m.key));
      }
      keys.addAll(EcoFriendMessages.basePool(s).map((m) => m.key));
    }
    keys.addAll(EcoFriendMessages.riskPool(5).map((m) => m.key));
    keys.add('efm_goal_label');
    for (final loc in AppLocalizations.supportedLocales) {
      final table = AppLocalizations.tableFor(loc.languageCode);
      for (final k in keys) {
        expect(table[k], isNotNull, reason: '$k missing in ${loc.languageCode}');
        expect(table[k]!.trim(), isNotEmpty);
      }
    }
    // placeholder survives translation
    for (final loc in AppLocalizations.supportedLocales) {
      expect(AppLocalizations.tableFor(loc.languageCode)['efm_streak_keep'],
          contains('{n}'));
    }
  });

  test('state decides the message; urgent states win', () {
    final eve = DateTime(2026, 11, 18, 17);
    // streak at risk (not opened today, evening)
    var p = EcoFriendMessages.pool(
        EcoScene.evening, ctx(eve, streak: 6, activeToday: false));
    expect(p.first.key, 'efm_streak_risk');
    // goal almost done
    p = EcoFriendMessages.pool(EcoScene.day, ctx(DateTime(2026, 11, 18, 12), goalPct: 90));
    expect(p.first.key, 'efm_goal_close');
    // goal done is celebrated
    p = EcoFriendMessages.pool(EcoScene.day, ctx(DateTime(2026, 11, 18, 12), goalPct: 100));
    expect(p.map((m) => m.key), contains('efm_goal_done_1'));
    // gentle comeback after 3-6 days
    p = EcoFriendMessages.pool(EcoScene.day, ctx(DateTime(2026, 11, 18, 12), inactive: 4));
    expect(p.first.key, 'efm_comeback');
    // brand-new user is invited, but never at night
    p = EcoFriendMessages.pool(EcoScene.morning, ctx(DateTime(2026, 11, 18, 8), hasEarned: false));
    expect(p.first.key, 'efm_new_user');
    p = EcoFriendMessages.pool(EcoScene.night, ctx(DateTime(2026, 11, 18, 23), hasEarned: false));
    expect(p.map((m) => m.key), isNot(contains('efm_new_user')));
  });

  test('no pressure at night: no streak-risk after 22:00', () {
    final late = DateTime(2026, 11, 18, 23);
    final p = EcoFriendMessages.pool(
        EcoScene.night, ctx(late, streak: 9, activeToday: false));
    expect(p.map((m) => m.key), isNot(contains('efm_streak_risk')));
    expect(p.map((m) => m.key), contains('efm_night_1'));
  });

  test('pool never contains duplicates and streak args are filled', () {
    final t = DateTime(2026, 11, 18, 17);
    final p = EcoFriendMessages.pool(
        EcoScene.evening, ctx(t, streak: 8, activeToday: false, goalPct: 60));
    expect(p.map((m) => m.key).toSet().length, p.length);
    final keep = p.firstWhere((m) => m.key == 'efm_streak_keep');
    expect(keep.args['n'], 8);
    expect(const AppLocalizations(Locale('az')).tr(keep.key, keep.args),
        contains('8'));
  });

  test('rotation: changes every 3 h, never repeats the last key back to back', () {
    final pool = EcoFriendMessages.basePool(EcoScene.day);
    final seen = <String>[];
    for (var h = 10; h < 16; h += 3) {
      seen.add(EcoFriendMessages.pick(pool, DateTime(2026, 11, 18, h)).key);
    }
    expect(seen[0], isNot(seen[1]));
    final a = EcoFriendMessages.pick(pool, DateTime(2026, 11, 18, 10));
    final b = EcoFriendMessages.pick(pool, DateTime(2026, 11, 18, 10),
        lastKey: a.key);
    expect(b.key, isNot(a.key));
    // same slot -> stable (no flicker on rebuild)
    expect(EcoFriendMessages.pick(pool, DateTime(2026, 11, 18, 10, 5)).key,
        EcoFriendMessages.pick(pool, DateTime(2026, 11, 18, 11, 55)).key);
    // empty pool is safe
    expect(EcoFriendMessages.pick(const [], DateTime(2026, 11, 18)).key, 'ef_normal');
  });
}
