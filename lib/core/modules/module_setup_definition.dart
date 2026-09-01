import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class ModuleSetupStepDefinition {
  const ModuleSetupStepDefinition({
    required this.id,
    required this.moduleId,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.icon,
    required this.sortOrder,
    required this.builder,
    this.onSave,
    this.isOptional = false,
  });

  final String id;
  final String moduleId;
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final String descriptionEn;
  final IconData icon;
  final int sortOrder;
  final Widget Function(BuildContext context, WidgetRef ref) builder;
  final Future<bool> Function(BuildContext context, WidgetRef ref)? onSave;
  final bool isOptional;

  String title(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return isAr ? titleAr : titleEn;
  }

  String description(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return isAr ? descriptionAr : descriptionEn;
  }
}
