import 'package:flutter/material.dart';

/// Raw palette. Widgets should read `Theme.of(context)` instead of these
/// constants wherever a semantic slot exists; the exceptions are the
/// gain/loss colours below, which have no Material equivalent.
abstract final class AppColors {
  static const Color brand = Color(0xFF0B6B5B);
  static const Color brandDark = Color(0xFF4ECDB6);

  /// EGP got **stronger** (fewer EGP buy one foreign unit).
  static const Color gainLight = Color(0xFF0F8A4C);
  static const Color gainDark = Color(0xFF4ADE80);

  /// EGP got **weaker** (more EGP buy one foreign unit).
  static const Color lossLight = Color(0xFFC62828);
  static const Color lossDark = Color(0xFFFF6B6B);

  /// No measurable movement.
  static const Color flatLight = Color(0xFF5F6B6A);
  static const Color flatDark = Color(0xFF9BA6A5);

  static const Color offlineAmber = Color(0xFF8A5A00);
  static const Color offlineAmberDark = Color(0xFFFFC53D);
  static const Color offlineAmberSurface = Color(0xFFFFF4D6);
  static const Color offlineAmberSurfaceDark = Color(0xFF3A2E10);
}

/// Semantic colours that depend on the active brightness.
///
/// Exposed as a [ThemeExtension] so widgets read them the same way they read
/// any other theme value, and dark mode needs no `if` at the call site.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.gain,
    required this.loss,
    required this.flat,
    required this.offlineForeground,
    required this.offlineBackground,
  });

  factory AppSemanticColors.of(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return AppSemanticColors(
      gain: isDark ? AppColors.gainDark : AppColors.gainLight,
      loss: isDark ? AppColors.lossDark : AppColors.lossLight,
      flat: isDark ? AppColors.flatDark : AppColors.flatLight,
      offlineForeground: isDark
          ? AppColors.offlineAmberDark
          : AppColors.offlineAmber,
      offlineBackground: isDark
          ? AppColors.offlineAmberSurfaceDark
          : AppColors.offlineAmberSurface,
    );
  }

  final Color gain;
  final Color loss;
  final Color flat;
  final Color offlineForeground;
  final Color offlineBackground;

  @override
  AppSemanticColors copyWith({
    Color? gain,
    Color? loss,
    Color? flat,
    Color? offlineForeground,
    Color? offlineBackground,
  }) {
    return AppSemanticColors(
      gain: gain ?? this.gain,
      loss: loss ?? this.loss,
      flat: flat ?? this.flat,
      offlineForeground: offlineForeground ?? this.offlineForeground,
      offlineBackground: offlineBackground ?? this.offlineBackground,
    );
  }

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      gain: Color.lerp(gain, other.gain, t)!,
      loss: Color.lerp(loss, other.loss, t)!,
      flat: Color.lerp(flat, other.flat, t)!,
      offlineForeground: Color.lerp(
        offlineForeground,
        other.offlineForeground,
        t,
      )!,
      offlineBackground: Color.lerp(
        offlineBackground,
        other.offlineBackground,
        t,
      )!,
    );
  }
}

extension AppSemanticColorsX on BuildContext {
  /// Gain/loss/offline colours for the current brightness.
  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>() ??
      AppSemanticColors.of(Theme.of(this).brightness);
}
