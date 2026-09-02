import 'package:flutter/material.dart';
import '../../app/theme/app_spacing.dart';

/// Centered progress indicator shown at the bottom of infinite-scroll lists.
class AppLoadMoreFooter extends StatelessWidget {
  const AppLoadMoreFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
