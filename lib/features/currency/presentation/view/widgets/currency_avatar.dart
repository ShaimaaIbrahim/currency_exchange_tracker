import 'package:currency_exchange_tracker/features/currency/domain/entities/currency.dart';
import 'package:flutter/material.dart';

/// Flag-emoji avatar for a currency.
///
/// Emoji rather than image assets: no download, no licensing, and it inherits
/// the platform's own flag artwork. The ISO code is used as the fallback for
/// platforms whose font lacks regional-indicator glyphs.
class CurrencyAvatar extends StatelessWidget {
  const CurrencyAvatar({required this.currency, this.size = 44, super.key});

  final Currency currency;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Text(
        currency.flag,
        // Fixed scale: an emoji that grows with the user's text-size setting
        // would burst out of its circle.
        textScaler: TextScaler.noScaling,
        style: TextStyle(fontSize: size * 0.5),
        semanticsLabel: currency.displayName,
      ),
    );
  }
}
