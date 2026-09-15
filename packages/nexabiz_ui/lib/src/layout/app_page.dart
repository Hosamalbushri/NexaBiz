import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import 'app_breakpoints.dart';
import 'app_layout_tokens.dart';

/// Central canonical page layout abstraction for NexaBiz screens.
///
/// Controls Safe Areas, max content width constraints, responsive padding,
/// bi-directional RTL alignment, background color, and single scroll strategy.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.child,
    this.header,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.maxWidth = AppLayoutTokens.maxPageWidth,
    this.padding,
    this.backgroundColor,
    this.scrollable = true,
  });

  final Widget child;
  final Widget? header;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final shadcnTheme = shadcn.Theme.of(context);
    final mediaWidth = MediaQuery.of(context).size.width;

    final defaultPadding = padding ??
        (AppBreakpoints.isCompact(mediaWidth)
            ? AppLayoutTokens.pagePaddingDirectionalCompact
            : AppLayoutTokens.pagePaddingDirectionalStandard);

    final pageBody = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: scrollable ? MainAxisSize.min : MainAxisSize.max,
      children: [
        if (header != null) ...[
          header!,
          const SizedBox(height: AppLayoutTokens.pageHeaderGap),
        ],
        if (scrollable) child else Expanded(child: child),
      ],
    );

    if (scrollable) {
      return Scaffold(
        backgroundColor:
            backgroundColor ?? shadcnTheme.colorScheme.background,
        appBar: appBar,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: defaultPadding,
              child: Align(
                alignment: AlignmentDirectional.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: pageBody,
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
      );
    }

    return Scaffold(
      backgroundColor:
          backgroundColor ?? shadcnTheme.colorScheme.background,
      appBar: appBar,
      body: SafeArea(
        child: Padding(
          padding: defaultPadding,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Align(
                alignment: AlignmentDirectional.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth,
                    minHeight: constraints.maxHeight,
                    maxHeight: constraints.maxHeight,
                  ),
                  child: pageBody,
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
