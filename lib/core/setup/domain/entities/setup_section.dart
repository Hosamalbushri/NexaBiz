import 'package:flutter/foundation.dart';
import 'setup_field.dart';

/// Represents a logical grouping of setup fields within a package setup.
@immutable
class SetupSection {
  const SetupSection({
    required this.id,
    required this.packageId,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.descriptionEn,
    this.fields = const [],
    this.sortOrder = 0,
    this.isOptional = false,
  });

  /// Stable section identifier within the package.
  final String id;

  /// Parent package identifier.
  final String packageId;

  /// Arabic display title.
  final String titleAr;

  /// English display title.
  final String titleEn;

  /// Arabic description.
  final String descriptionAr;

  /// English description.
  final String descriptionEn;

  /// Strongly-typed configuration fields in this section.
  final List<SetupField> fields;

  /// Execution or presentation ordering index.
  final int sortOrder;

  /// Whether this section is optional for overall package setup completion.
  final bool isOptional;

  /// Localized title based on language code.
  String title(String languageCode) =>
      languageCode.toLowerCase() == 'ar' ? titleAr : titleEn;

  /// Localized description based on language code.
  String description(String languageCode) =>
      languageCode.toLowerCase() == 'ar' ? descriptionAr : descriptionEn;
}
