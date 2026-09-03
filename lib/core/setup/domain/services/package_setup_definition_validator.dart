import '../entities/package_setup_definition.dart';

/// Exception thrown when a package setup definition or setup registry fails validation.
class PackageSetupValidationException implements Exception {
  const PackageSetupValidationException(this.message);

  final String message;

  @override
  String toString() => 'PackageSetupValidationException: $message';
}

/// Service that enforces structural invariants on [PackageSetupDefinition]s.
class PackageSetupDefinitionValidator {
  const PackageSetupDefinitionValidator();

  /// Validates a single package setup definition.
  void validateDefinition(PackageSetupDefinition definition) {
    if (definition.packageId.trim().isEmpty) {
      throw const PackageSetupValidationException(
        'Package setup definition packageId cannot be empty or blank.',
      );
    }
    if (definition.displayNameAr.trim().isEmpty ||
        definition.displayNameEn.trim().isEmpty) {
      throw PackageSetupValidationException(
        'Package "${definition.packageId}" must provide non-empty localized display names.',
      );
    }

    final seenSectionIds = <String>{};
    for (final section in definition.sections) {
      final sectionId = section.id.trim();
      if (sectionId.isEmpty) {
        throw PackageSetupValidationException(
          'Package "${definition.packageId}" contains a section with an empty or blank section ID.',
        );
      }
      if (seenSectionIds.contains(sectionId)) {
        throw PackageSetupValidationException(
          'Package "${definition.packageId}" contains duplicate section ID "$sectionId".',
        );
      }
      seenSectionIds.add(sectionId);

      if (section.packageId.trim().isNotEmpty &&
          section.packageId.trim() != definition.packageId.trim()) {
        throw PackageSetupValidationException(
          'Section "$sectionId" packageId "${section.packageId}" does not match parent package "${definition.packageId}".',
        );
      }

      final seenFieldKeys = <String>{};
      for (final field in section.fields) {
        final fieldKey = field.key.trim();
        if (fieldKey.isEmpty) {
          throw PackageSetupValidationException(
            'Section "$sectionId" in package "${definition.packageId}" contains a field with an empty key.',
          );
        }
        if (seenFieldKeys.contains(fieldKey)) {
          throw PackageSetupValidationException(
            'Section "$sectionId" in package "${definition.packageId}" contains duplicate field key "$fieldKey".',
          );
        }
        seenFieldKeys.add(fieldKey);
      }
    }

    for (final dep in definition.dependencies) {
      if (dep.targetPackageId.trim().isEmpty) {
        throw PackageSetupValidationException(
          'Package "${definition.packageId}" declares a dependency with an empty targetPackageId.',
        );
      }
      if (dep.targetPackageId.trim() == definition.packageId.trim()) {
        throw PackageSetupValidationException(
          'Package "${definition.packageId}" cannot declare a setup dependency on itself.',
        );
      }
    }
  }

  /// Validates a collection of setup definitions across all registered packages.
  void validateRegistry(Iterable<PackageSetupDefinition> definitions) {
    final seenPackageIds = <String>{};
    for (final def in definitions) {
      validateDefinition(def);

      final pkgId = def.packageId.trim();
      if (seenPackageIds.contains(pkgId)) {
        throw PackageSetupValidationException(
          'Duplicate package setup registration detected for packageId "$pkgId".',
        );
      }
      seenPackageIds.add(pkgId);
    }
  }
}
