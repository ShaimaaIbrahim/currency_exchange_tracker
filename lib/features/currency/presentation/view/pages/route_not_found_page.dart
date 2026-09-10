import 'package:currency_exchange_tracker/core/router/app_router.dart';
import 'package:currency_exchange_tracker/core/widgets/app_state_views.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shown for an unknown route or an untracked currency code.
///
/// Reachable in practice because the currency code lives in the URL, which
/// means a stale deep link or a hand-edited web address can land here.
class RouteNotFoundPage extends StatelessWidget {
  const RouteNotFoundPage({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: AppMessageView(
        icon: Icons.travel_explore_rounded,
        title: 'Page not found',
        message: message,
        actionLabel: 'Back to rates',
        onAction: () => context.go(AppRoutes.rates),
      ),
    );
  }
}
