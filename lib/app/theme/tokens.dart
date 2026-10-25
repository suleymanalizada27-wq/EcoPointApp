import 'package:flutter/material.dart';

/// Spacing scale (4pt grid).
abstract final class Sp {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double huge = 48;

  /// Horizontal page gutter used by every screen.
  static const double gutter = 20;
}

/// Corner radii.
abstract final class Rad {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;

  static BorderRadius get card => BorderRadius.circular(lg);
  static BorderRadius get field => BorderRadius.circular(md);
  static BorderRadius get sheet =>
      const BorderRadius.vertical(top: Radius.circular(xl));
}

/// Motion tokens.
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration base = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 480);
  static const Curve curve = Curves.easeOutCubic;
}

/// Minimum accessible touch target.
const double kMinTouch = 48;
