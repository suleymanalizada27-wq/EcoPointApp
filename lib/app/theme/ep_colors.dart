import 'package:flutter/material.dart';

/// EcoPoint colour tokens, exposed as a [ThemeExtension] so every widget reads
/// from one source and both themes stay consistent.
///
/// Palette: forest green + emerald on deep charcoal, with a single, carefully
/// rationed lime accent used only for "value" moments (EP amounts, CTAs).
@immutable
class EpColors extends ThemeExtension<EpColors> {
  const EpColors({
    required this.bg,
    required this.surface,
    required this.surfaceRaised,
    required this.outline,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.emerald,
    required this.emeraldDeep,
    required this.lime,
    required this.onLime,
    required this.warning,
    required this.danger,
    required this.info,
    required this.heroGradient,
  });

  final Color bg;
  final Color surface;
  final Color surfaceRaised;
  final Color outline;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color emerald;
  final Color emeraldDeep;
  final Color lime;
  final Color onLime;
  final Color warning;
  final Color danger;
  final Color info;
  final List<Color> heroGradient;

  static const EpColors dark = EpColors(
    bg: Color(0xFF0A1410),
    surface: Color(0xFF111D17),
    surfaceRaised: Color(0xFF182A21),
    outline: Color(0xFF243A2F),
    textPrimary: Color(0xFFEAF3EC),
    textSecondary: Color(0xFF9DB3A6),
    textTertiary: Color(0xFF6B8275),
    emerald: Color(0xFF2BC48A),
    emeraldDeep: Color(0xFF0E6B4B),
    lime: Color(0xFFC8F23A),
    onLime: Color(0xFF14210B),
    warning: Color(0xFFF2B544),
    danger: Color(0xFFEA6451),
    info: Color(0xFF58B7DB),
    heroGradient: [Color(0xFF0F6B4B), Color(0xFF0A3D2C), Color(0xFF0A1F18)],
  );

  static const EpColors light = EpColors(
    bg: Color(0xFFF3F7F3),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFE9F1EA),
    outline: Color(0xFFD5E2D8),
    textPrimary: Color(0xFF0E1E16),
    textSecondary: Color(0xFF4C6455),
    textTertiary: Color(0xFF7D9385),
    emerald: Color(0xFF12935F),
    emeraldDeep: Color(0xFF0B6B47),
    lime: Color(0xFFB4DE1E),
    onLime: Color(0xFF14210B),
    warning: Color(0xFFC98A12),
    danger: Color(0xFFC9432F),
    info: Color(0xFF2B8DB3),
    heroGradient: [Color(0xFF12935F), Color(0xFF0B6B47), Color(0xFF0A4B33)],
  );

  @override
  EpColors copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceRaised,
    Color? outline,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? emerald,
    Color? emeraldDeep,
    Color? lime,
    Color? onLime,
    Color? warning,
    Color? danger,
    Color? info,
    List<Color>? heroGradient,
  }) {
    return EpColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      outline: outline ?? this.outline,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      emerald: emerald ?? this.emerald,
      emeraldDeep: emeraldDeep ?? this.emeraldDeep,
      lime: lime ?? this.lime,
      onLime: onLime ?? this.onLime,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      heroGradient: heroGradient ?? this.heroGradient,
    );
  }

  @override
  EpColors lerp(ThemeExtension<EpColors>? other, double t) {
    if (other is! EpColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return EpColors(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      outline: l(outline, other.outline),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      emerald: l(emerald, other.emerald),
      emeraldDeep: l(emeraldDeep, other.emeraldDeep),
      lime: l(lime, other.lime),
      onLime: l(onLime, other.onLime),
      warning: l(warning, other.warning),
      danger: l(danger, other.danger),
      info: l(info, other.info),
      heroGradient: t < 0.5 ? heroGradient : other.heroGradient,
    );
  }
}

extension EpThemeContext on BuildContext {
  EpColors get ep => Theme.of(this).extension<EpColors>() ?? EpColors.dark;
  TextTheme get text => Theme.of(this).textTheme;
}
