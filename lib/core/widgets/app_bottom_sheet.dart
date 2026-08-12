import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme/app_spacing.dart';

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
      final maxHeight =
          media.size.height -
          media.viewPadding.vertical -
          media.viewInsets.bottom;

      return Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.md,
              bottom: media.viewInsets.bottom + AppSpacing.md,
            ),
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
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    child,
                  ],
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
