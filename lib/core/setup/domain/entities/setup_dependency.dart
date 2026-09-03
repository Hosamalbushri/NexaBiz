import 'package:flutter/foundation.dart';

/// Degree of dependency between setup packages or sections.
enum SetupDependencyType {
  /// Target setup must be completed before dependent setup can proceed.
  required,

  /// Target setup is recommended but not mandatory.
  optional,
}

/// Represents a prerequisite dependency declared by a package setup.
@immutable
class SetupDependency {
  const SetupDependency({
    required this.targetPackageId,
    this.targetSectionId,
    this.dependencyType = SetupDependencyType.required,
    this.reasonAr,
    this.reasonEn,
  });

  /// Target package identifier that must be setup first.
  final String targetPackageId;

  /// Optional specific section within the target package.
  final String? targetSectionId;

  /// Dependency strictness level.
  final SetupDependencyType dependencyType;

  /// Optional Arabic rationale for user display.
  final String? reasonAr;

  /// Optional English rationale for user display.
  final String? reasonEn;

  /// Localized reason based on language code.
  String? reason(String languageCode) =>
      languageCode.toLowerCase() == 'ar' ? reasonAr : reasonEn;
}
