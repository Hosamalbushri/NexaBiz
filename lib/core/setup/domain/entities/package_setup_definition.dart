import 'package:flutter/foundation.dart';
import 'setup_dependency.dart';
import 'setup_section.dart';

/// Top-level setup contract exposed by a business package to the central orchestrator.
@immutable
class PackageSetupDefinition {
  const PackageSetupDefinition({
    required this.packageId,
    required this.displayNameAr,
    required this.displayNameEn,
    this.sections = const [],
    this.dependencies = const [],
    this.sortOrder = 0,
    this.isOptional = false,
  });

  /// Unique stable package identifier (e.g. 'accounting', 'inventory', 'sales').
  final String packageId;

  /// Arabic localized display name.
  final String displayNameAr;

  /// English localized display name.
  final String displayNameEn;

  /// Logical setup sections owned by this package.
  final List<SetupSection> sections;

  /// Setup dependencies declared by this package.
  final List<SetupDependency> dependencies;

  /// Sort ordering index for wizard display.
  final int sortOrder;

  /// Whether setup of this entire package is optional.
  final bool isOptional;

  /// Localized display name based on language code.
  String displayName(String languageCode) =>
      languageCode.toLowerCase() == 'ar' ? displayNameAr : displayNameEn;
}
