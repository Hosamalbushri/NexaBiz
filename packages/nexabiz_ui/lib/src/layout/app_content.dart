import 'package:flutter/widgets.dart';

import 'app_breakpoints.dart';
import 'app_layout_tokens.dart';

/// Central container managing maximum content width, alignment, and responsive padding.
class AppContent extends StatelessWidget {
  const AppContent({
    super.key,
    required this.child,
    this.maxWidth = AppLayoutTokens.maxPageWidth,
    this.padding,
    this.alignment = AlignmentDirectional.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    final defaultPadding = AppBreakpoints.isCompact(mediaWidth)
        ? AppLayoutTokens.pagePaddingDirectionalCompact
        : AppLayoutTokens.pagePaddingDirectionalStandard;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? defaultPadding,
          child: child,
        ),
      ),
    );
  }
}
