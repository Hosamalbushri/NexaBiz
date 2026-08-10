import 'package:flutter/material.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';

class SaveCountButton extends StatelessWidget {
  const SaveCountButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);

    return AppButton(
      label: localization.saveCount,
      icon: Icons.save_outlined,
      isLoading: isLoading,
      expand: true,
      onPressed: onPressed,
    );
  }
}
