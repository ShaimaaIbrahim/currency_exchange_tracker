import 'package:currency_exchange_tracker/core/error/failures.dart';
import 'package:currency_exchange_tracker/core/responsive/app_breakpoints.dart';
import 'package:currency_exchange_tracker/core/responsive/responsive_context.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Shared layout for the three "nothing to show" screens: error, empty and
/// not-found. Keeping one implementation means they stay visually identical,
/// which is what makes them read as deliberate states rather than accidents.
class AppMessageView extends StatelessWidget {
  const AppMessageView({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.tone,
    super.key,
  });

  /// Renders a [Failure] with the right icon, copy and retry affordance.
  ///
  /// [onRetry] is only wired up when the failure is actually retryable — a
  /// button that cannot succeed is worse than no button.
  factory AppMessageView.fromFailure(Failure failure, {VoidCallback? onRetry}) {
    return AppMessageView(
      icon: switch (failure) {
        OfflineFailure() => Icons.wifi_off_rounded,
        TimeoutFailure() => Icons.hourglass_disabled_rounded,
        ConnectionFailure() => Icons.cloud_off_rounded,
        ServerFailure() => Icons.dns_rounded,
        NoDataFailure() => Icons.query_stats_rounded,
        CacheFailure() => Icons.sd_card_alert_rounded,
        ParsingFailure() => Icons.rule_rounded,
        RequestFailure() => Icons.error_outline_rounded,
        UnexpectedFailure() => Icons.error_outline_rounded,
      },
      title: switch (failure) {
        OfflineFailure() => "You're offline",
        TimeoutFailure() => 'Connection timed out',
        ConnectionFailure() => "Can't reach the service",
        ServerFailure() => 'Service unavailable',
        NoDataFailure() => 'No data available',
        CacheFailure() => 'Saved data unavailable',
        ParsingFailure() => 'Unexpected response',
        RequestFailure() => 'Something went wrong',
        UnexpectedFailure() => 'Something went wrong',
      },
      message: failure.message,
      actionLabel: failure.isRetryable && onRetry != null ? 'Try again' : null,
      onAction: failure.isRetryable ? onRetry : null,
    );
  }

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Overrides the icon colour; defaults to a muted on-surface tone.
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = tone ?? theme.colorScheme.onSurfaceVariant;

    return Center(
      child: SingleChildScrollView(
        // Scrollable so the view still works at 200% text scale on a short
        // landscape phone instead of overflowing.
        padding: EdgeInsets.symmetric(
          horizontal: context.pagePadding,
          vertical: AppSpacing.xl,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: context.responsive<double>(compact: 56, medium: 72),
                color: iconColor,
              ),
              const Gap(AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const Gap(AppSpacing.xl),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The empty state: the request succeeded but there is nothing to list.
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({this.onRefresh, super.key});

  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return AppMessageView(
      icon: Icons.currency_exchange_rounded,
      title: 'No rates to show',
      message:
          'The exchange-rate feed returned no rates for the currencies '
          'we track. Pull down to try again.',
      actionLabel: onRefresh == null ? null : 'Refresh',
      onAction: onRefresh,
    );
  }
}

/// Makes any of the above usable inside a `CustomScrollView`, so pull-to-
/// refresh keeps working on the error and empty states too — the states where
/// a user most wants to retry.
class SliverFillMessage extends StatelessWidget {
  const SliverFillMessage({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppBreakpoints.shortViewportHeight / 2,
        ),
        child: child,
      ),
    );
  }
}
