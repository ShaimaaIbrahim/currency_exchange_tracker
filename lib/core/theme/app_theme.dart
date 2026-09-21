import 'package:currency_exchange_tracker/core/responsive/app_breakpoints.dart';
import 'package:currency_exchange_tracker/core/responsive/app_fluid.dart';
import 'package:currency_exchange_tracker/core/theme/app_colors.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Light and dark themes for the app.
///
/// Both are generated from one seed colour so contrast pairs stay consistent,
/// and every component override lives here rather than being sprinkled across
/// widgets. Call this from inside [FluidInit] so `.r` / `.sp` have metrics.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: brightness == Brightness.dark
          ? AppColors.brandDark
          : AppColors.brand,
      brightness: brightness,
    );

    final base = ThemeData(
      colorScheme: colorScheme,
      brightness: brightness,
      useMaterial3: true,
    );

    final iconSize = 24.r;
    final themed = base.copyWith(
      scaffoldBackgroundColor: colorScheme.surface,
      extensions: [AppSemanticColors.of(brightness)],
      iconTheme: IconThemeData(size: iconSize),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        iconTheme: IconThemeData(size: iconSize),
        actionsIconTheme: IconThemeData(size: iconSize),
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.lg).r,
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          // Touch targets stay at least 48dp — scaling them down on a small
          // phone would fail WCAG 2.5.5 / Material.
          minimumSize: const Size(
            AppBreakpoints.minTouchTarget * 2,
            AppBreakpoints.minTouchTarget,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.md).r,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(minVerticalPadding: AppSpacing.md.r),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md).r,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
      ),
    );

    final scaled = ResponsiveTheme.fromTheme(themed);
    return scaled.copyWith(
      appBarTheme: scaled.appBarTheme.copyWith(
        titleTextStyle: scaled.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}
