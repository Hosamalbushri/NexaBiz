import 'package:flutter/material.dart';

import '../../layout/app_page.dart';

/// Legacy compatible responsive page shell pattern delegating to canonical [AppPage].
class AppPageShell extends StatelessWidget {
  const AppPageShell({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.maxWidth = 1400.0,
    this.padding,
    this.backgroundColor,
    this.scrollable = true,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      maxWidth: maxWidth,
      padding: padding,
      backgroundColor: backgroundColor,
      scrollable: scrollable,
      child: child,
    );
  }
}
