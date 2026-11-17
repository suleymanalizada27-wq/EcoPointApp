import 'package:ecopoint_pro/features/ecofriend/domain/ecofriend_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime(2026, 11, 17, 12);

  test('all 7 moods have an animated asset and a still', () {
    expect(EcoFriendMood.values.length, 7);
    for (final m in EcoFriendMood.values) {
      expect(m.animatedAsset, 'assets/ecofriend/${m.name}.webp');
      expect(m.stillAsset, 'assets/ecofriend/still/${m.name}.png');
      expect(m.messageKey, 'ef_${m.name}');
    }
  });

  test('temporary mood returns to resting mood', () {
    final e = EcoFriendEngine(resting: EcoFriendMood.breathing);
    expect(e.trigger(EcoFriendMood.excited, now: t0, eventKey: 'a'), isTrue);
    expect(e.current(t0), EcoFriendMood.excited);
    expect(e.current(t0.add(const Duration(seconds: 6))),
        EcoFriendMood.breathing);
  });

  test('same event key never plays twice', () {
    final e = EcoFriendEngine();
    expect(e.trigger(EcoFriendMood.proud, now: t0, eventKey: 'lvl_1'), isTrue);
    final later = t0.add(const Duration(minutes: 5));
    expect(e.trigger(EcoFriendMood.proud, now: later, eventKey: 'lvl_1'),
        isFalse);
  });

  test('higher priority interrupts, lower never interrupts', () {
    final e = EcoFriendEngine();
    expect(e.trigger(EcoFriendMood.excited, now: t0, eventKey: 'x'), isTrue);
    expect(e.trigger(EcoFriendMood.cheering, now: t0, eventKey: 'g'), isTrue);
    expect(e.current(t0), EcoFriendMood.cheering);
    // cheering is never overlapped by ordinary events
    expect(e.trigger(EcoFriendMood.excited, now: t0, eventKey: 'y'), isFalse);
    expect(e.trigger(EcoFriendMood.proud, now: t0, eventKey: 'p'), isFalse);
    expect(e.trigger(EcoFriendMood.thinking, now: t0, token: 's'), isFalse);
    expect(e.current(t0), EcoFriendMood.cheering);
  });

  test('scan: thinking while scanning, excited after confirmation', () {
    final e = EcoFriendEngine(resting: EcoFriendMood.breathing);
    expect(e.trigger(EcoFriendMood.thinking, now: t0, token: 'scanner'), isTrue);
    expect(e.current(t0.add(const Duration(seconds: 20))),
        EcoFriendMood.thinking); // held, not time-limited at 20 s
    expect(e.release('scanner'), isTrue);
    expect(e.trigger(EcoFriendMood.excited, now: t0, eventKey: 'scan_1'),
        isTrue);
    expect(e.current(t0), EcoFriendMood.excited);
  });

  test('thinking has a safety timeout', () {
    final e = EcoFriendEngine(resting: EcoFriendMood.breathing);
    e.trigger(EcoFriendMood.thinking, now: t0, token: 'x');
    expect(e.current(t0.add(kThinkingMax + const Duration(seconds: 1))),
        EcoFriendMood.breathing);
  });

  test('scan result + balance stream = one excited reaction (cool-down)', () {
    final e = EcoFriendEngine(resting: EcoFriendMood.breathing);
    expect(e.trigger(EcoFriendMood.excited, now: t0, eventKey: 'scan_1'),
        isTrue);
    final after = t0.add(const Duration(seconds: 8)); // first one finished
    expect(e.current(after), EcoFriendMood.breathing);
    expect(e.trigger(EcoFriendMood.excited, now: after, eventKey: 'bal_150'),
        isFalse);
  });

  group('widget mood', () {
    test('recent confirmed event wins', () {
      expect(
        widgetMoodAt(
          now: t0,
          eventMood: EcoFriendMood.cheering,
          eventUntil: t0.add(const Duration(hours: 1)),
          lastActive: t0,
        ),
        EcoFriendMood.cheering,
      );
    });
    test('expired event falls back to normal', () {
      expect(
        widgetMoodAt(
          now: t0,
          eventMood: EcoFriendMood.excited,
          eventUntil: t0.subtract(const Duration(minutes: 1)),
          lastActive: t0,
        ),
        EcoFriendMood.normal,
      );
    });
    test('thinking is never shown on the widget', () {
      expect(
        widgetMoodAt(
          now: t0,
          eventMood: EcoFriendMood.thinking,
          eventUntil: t0.add(const Duration(hours: 1)),
        ),
        EcoFriendMood.normal,
      );
    });
    test('long inactivity -> sad; brand-new user (no timestamp) -> normal', () {
      expect(
        widgetMoodAt(now: t0, lastActive: t0.subtract(const Duration(days: 8))),
        EcoFriendMood.sad,
      );
      expect(widgetMoodAt(now: t0), EcoFriendMood.normal);
    });
  });
}
