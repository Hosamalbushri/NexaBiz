import 'package:flutter/foundation.dart';

/// Supported types for strongly-typed setup configuration fields.
enum SetupFieldType {
  text,
  boolean,
  number,
  select,
  reference,
}

/// Strongly-typed setup field specification owned by a business package.
@immutable
class SetupField {
  const SetupField({
    required this.id,
    required this.sectionId,
    required this.key,
    required this.labelAr,
    required this.labelEn,
    required this.fieldType,
    this.isRequired = true,
    this.defaultValue,
    this.allowedValues,
  });

  /// Stable field identifier within the section.
  final String id;

  /// Parent section identifier.
  final String sectionId;

  /// Property key used for configuration persistence.
  final String key;

  /// Arabic display label.
  final String labelAr;

  /// English display label.
  final String labelEn;

  /// Type category of the field.
  final SetupFieldType fieldType;

  /// Whether this field is mandatory for complete configuration.
  final bool isRequired;

  /// Optional default value.
  final Object? defaultValue;

  /// Optional restricted set of allowed values for select/reference types.
  final List<Object>? allowedValues;

  /// Returns localized display label based on language code.
  String label(String languageCode) =>
      languageCode.toLowerCase() == 'ar' ? labelAr : labelEn;

  /// Validates a candidate value against this field's constraints.
  bool isValidValue(Object? value) {
    if (value == null || (value is String && value.trim().isEmpty)) {
      return !isRequired;
    }
    if (allowedValues != null && allowedValues!.isNotEmpty) {
      return allowedValues!.contains(value);
    }
    return switch (fieldType) {
      SetupFieldType.text => value is String,
      SetupFieldType.boolean => value is bool,
      SetupFieldType.number => value is num,
      SetupFieldType.select => true,
      SetupFieldType.reference => value is String && value.trim().isNotEmpty,
    };
  }
}
