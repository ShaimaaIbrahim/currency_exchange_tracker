import 'package:currency_exchange_tracker/core/responsive/app_breakpoints.dart';
import 'package:flutter/widgets.dart';

/// Builds a different subtree per size class, measured against the **parent's**
/// constraints rather than the whole window.
///
/// Prefer this over `MediaQuery` whenever a widget can appear inside a pane,
/// dialog or side sheet: a 380dp-wide detail pane on a desktop should lay out
/// like a phone, and only `LayoutBuilder` knows that.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    required this.compact,
    this.medium,
    this.expanded,
    this.large,
    super.key,
  });

  final WidgetBuilder compact;
  final WidgetBuilder? medium;
  final WidgetBuilder? expanded;
  final WidgetBuilder? large;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = AppBreakpoints.sizeForWidth(constraints.maxWidth);
        final builder = switch (size) {
          WindowSize.compact => compact,
          WindowSize.medium => medium ?? compact,
          WindowSize.expanded => expanded ?? medium ?? compact,
          WindowSize.large => large ?? expanded ?? medium ?? compact,
        };
        return builder(context);
      },
    );
  }
}
