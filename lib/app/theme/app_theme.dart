import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ep_colors.dart';

/// Builds the light and dark [ThemeData].
///
/// Typography: Space Grotesk for display / numerals (carried over from the web
/// app's identity), Manrope for body copy. Fonts load through `google_fonts`
/// and fall back to the platform font if offline on first launch.
abstract final class AppTheme {
  static ThemeData get dark => _build(EpColors.dark, Brightness.dark);
  static ThemeData get light => _build(EpColors.light, Brightness.light);

  static ThemeData _build(EpColors c, Brightness b) {
    final scheme = ColorScheme(
      brightness: b,
      primary: c.emerald,
      onPrimary: b == Brightness.dark ? const Color(0xFF04140D) : Colors.white,
      secondary: c.lime,
      onSecondary: c.onLime,
      error: c.danger,
      onError: Colors.white,
      surface: c.surface,
      onSurface: c.textPrimary,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );

    final body = GoogleFonts.manropeTextTheme(base.textTheme)
        .apply(bodyColor: c.textPrimary, displayColor: c.textPrimary);

    TextStyle display(double size, FontWeight w, {double? h, double? ls}) =>
        GoogleFonts.spaceGrotesk(
          fontSize: size,
          fontWeight: w,
          height: h,
          letterSpacing: ls,
          color: c.textPrimary,
        );

    final textTheme = body.copyWith(
      displayLarge: display(44, FontWeight.w700, h: 1.05, ls: -1.2),
      displayMedium: display(34, FontWeight.w700, h: 1.1, ls: -0.8),
      headlineMedium: display(26, FontWeight.w700, h: 1.15, ls: -0.4),
      headlineSmall: display(22, FontWeight.w600, h: 1.2, ls: -0.2),
      titleLarge: display(19, FontWeight.w600, h: 1.25),
      titleMedium: body.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
      titleSmall: body.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
      bodyLarge: body.bodyLarge?.copyWith(fontSize: 16, height: 1.45),
      bodyMedium: body.bodyMedium?.copyWith(fontSize: 14, height: 1.45),
      bodySmall: body.bodySmall?.copyWith(
        fontSize: 12,
        height: 1.4,
        color: c.textSecondary,
      ),
      labelLarge: body.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 15,
        letterSpacing: 0.1,
      ),
      labelMedium: body.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 12,
        letterSpacing: 0.3,
      ),
      labelSmall: body.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 10.5,
        letterSpacing: 0.6,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[c],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: c.textPrimary,
        titleTextStyle: textTheme.titleLarge,
      ),
      dividerTheme: DividerThemeData(color: c.outline, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.surfaceRaised,
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: c.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
