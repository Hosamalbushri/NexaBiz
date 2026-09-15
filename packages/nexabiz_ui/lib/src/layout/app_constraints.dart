import 'package:flutter/widgets.dart';
import 'app_layout_tokens.dart';

/// Standardized layout constraint wrappers for capping max content width across screen types.
class AppContentConstraint extends StatelessWidget {
  const AppContentConstraint({
    super.key,
    required this.child,
    this.maxWidth = AppLayoutTokens.maxPageWidth,
    this.alignment = AlignmentDirectional.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Content constraint specifically capped for Form views.
class AppFormConstraint extends StatelessWidget {
  const AppFormConstraint({
    super.key,
    required this.child,
    this.maxWidth = AppLayoutTokens.maxFormWidth,
    this.alignment = AlignmentDirectional.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return AppContentConstraint(
      maxWidth: maxWidth,
      alignment: alignment,
      child: child,
    );
  }
}

/// Content constraint specifically capped for Data Tables and Grids.
class AppTableConstraint extends StatelessWidget {
  const AppTableConstraint({
    super.key,
    required this.child,
    this.maxWidth = AppLayoutTokens.maxTableWidth,
    this.alignment = AlignmentDirectional.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return AppContentConstraint(
      maxWidth: maxWidth,
      alignment: alignment,
      child: child,
    );
  }
}

/// Content constraint specifically capped for Dashboard layouts.
class AppDashboardConstraint extends StatelessWidget {
  const AppDashboardConstraint({
    super.key,
    required this.child,
    this.maxWidth = AppLayoutTokens.maxDashboardWidth,
    this.alignment = AlignmentDirectional.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return AppContentConstraint(
      maxWidth: maxWidth,
      alignment: alignment,
      child: child,
    );
  }
}

/// Content constraint specifically capped for Detail views.
class AppDetailsConstraint extends StatelessWidget {
  const AppDetailsConstraint({
    super.key,
    required this.child,
    this.maxWidth = AppLayoutTokens.maxDetailsWidth,
    this.alignment = AlignmentDirectional.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return AppContentConstraint(
      maxWidth: maxWidth,
      alignment: alignment,
      child: child,
    );
  }
}

/// Content constraint specifically capped for Settings layouts.
class AppSettingsConstraint extends StatelessWidget {
  const AppSettingsConstraint({
    super.key,
    required this.child,
    this.maxWidth = AppLayoutTokens.maxSettingsWidth,
    this.alignment = AlignmentDirectional.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return AppContentConstraint(
      maxWidth: maxWidth,
      alignment: alignment,
      child: child,
    );
  }
}

