import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// 8-point spacing scale for consistent layout rhythm across NexaBiz.
class AppSpacing {
  const AppSpacing._();

  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 40.0;
  static const double xxxl = 48.0;

  /// Default page/content padding.
  static const double page = md;

  /// Compact inset for dense lists & tables.
  static const double compact = xs;

  /// Section gap between major blocks.
  static const double section = lg;

  /// Standard card internal padding.
  static const double cardPadding = md;

  /// Standard form field vertical gap.
  static const double formGap = md;

  /// Standard EdgeInsets helpers
  static const EdgeInsets insetAllXs = EdgeInsets.all(xs);
  static const EdgeInsets insetAllSm = EdgeInsets.all(sm);
  static const EdgeInsets insetAllMd = EdgeInsets.all(md);
  static const EdgeInsets insetAllLg = EdgeInsets.all(lg);

  static const EdgeInsets insetPage = EdgeInsets.all(page);
  static const EdgeInsets insetCompact = EdgeInsets.all(compact);

  /// Dynamic context-aware density accessors delegating to shadcn ThemeData
  static shadcn.Density densityOf(BuildContext context) =>
      shadcn.Theme.of(context).density;

  static double baseGapOf(BuildContext context) =>
      shadcn.Theme.of(context).density.baseGap * shadcn.Theme.of(context).scaling;

  static double baseContainerPaddingOf(BuildContext context) =>
      shadcn.Theme.of(context).density.baseContainerPadding *
      shadcn.Theme.of(context).scaling;

  static double baseContentPaddingOf(BuildContext context) =>
      shadcn.Theme.of(context).density.baseContentPadding *
      shadcn.Theme.of(context).scaling;
}

