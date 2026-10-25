/// Progression levels, carried over 1:1 from the web app
/// (thresholds are lifetime *earned* EP).
class Level {
  const Level(this.index, this.minEarned);
  final int index;
  final int minEarned;

  String get l10nKey => 'lvl_$index';
}

class LevelProgress {
  const LevelProgress({
    required this.current,
    required this.next,
    required this.fraction,
    required this.earned,
  });

  final Level current;
  final Level? next;

  /// 0..1 progress toward [next]; 1.0 when at max level.
  final double fraction;
  final int earned;

  bool get isMax => next == null;
}

abstract final class Levels {
  static const List<Level> all = [
    Level(0, 0),
    Level(1, 500),
    Level(2, 2000),
    Level(3, 5000),
    Level(4, 10000),
    Level(5, 25000),
  ];

  static LevelProgress forEarned(int earned) {
    final e = earned < 0 ? 0 : earned;
    var idx = 0;
    for (var i = 0; i < all.length; i++) {
      if (e >= all[i].minEarned) idx = i;
    }
    final current = all[idx];
    final next = idx + 1 < all.length ? all[idx + 1] : null;
    double fraction = 1;
    if (next != null) {
      final span = next.minEarned - current.minEarned;
      fraction = span <= 0 ? 1 : (e - current.minEarned) / span;
    }
    return LevelProgress(
      current: current,
      next: next,
      fraction: fraction.clamp(0.0, 1.0),
      earned: e,
    );
  }
}
