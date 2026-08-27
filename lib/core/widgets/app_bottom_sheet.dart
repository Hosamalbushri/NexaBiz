import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme/app_spacing.dart';
import 'app_responsive.dart';

/// Shows a themed modal bottom sheet.
///
/// Uses the root navigator so the sheet covers shell chrome (bottom nav / FAB)
/// instead of sitting under it inside a nested branch navigator.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    useRootNavigator: true,
    builder: (context) {
      final media = MediaQuery.of(context);
      final isLandscape = media.size.height < 500;
      final maxHeight =
          (media.size.height -
              media.viewPadding.vertical -
              media.viewInsets.bottom) *
          (isLandscape ? 0.92 : 1.0);

      final horizontalPadding = isLandscape ? AppSpacing.xs : AppSpacing.md;
      final verticalPadding = isLandscape ? AppSpacing.xs : AppSpacing.md;

      return Padding(
        padding: EdgeInsets.only(
          left: horizontalPadding,
          right: horizontalPadding,
          top: verticalPadding,
          bottom: media.viewInsets.bottom + verticalPadding,
        ),
        child: AppContentConstraint(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (title != null) ...[
                    Center(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: (isLandscape
                                ? Theme.of(context).textTheme.titleMedium
                                : Theme.of(context).textTheme.titleLarge)
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    SizedBox(
                      height: isLandscape ? AppSpacing.xs : AppSpacing.md,
                    ),
                  ],
                  child,
                ],
              ),
            ),
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 160.ms)
          .moveY(
            begin: 12,
            end: 0,
            duration: 200.ms,
            curve: Curves.easeOutCubic,
          );
    },
  );
}
