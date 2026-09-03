/// Reusable import template configuration for an entity import source.
class ImportTemplate {
  ImportTemplate({
    required this.templateId,
    required this.name,
    this.description,
    required this.companyId,
    required this.targetProfileId,
    required this.targetEntityType,
    this.schemaVersion = currentSchemaVersion,
    this.fieldMappings = const {},
    this.ignoredColumns = const [],
    this.normalizationConfig = const {},
    this.validationConfig = const {},
    this.relationStrategies = const {},
    this.assignments = const {},
    this.executionPolicy = const {},
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now().toUtc(),
        updatedAt = updatedAt ?? DateTime.now().toUtc() {
    if (templateId.trim().isEmpty) {
      throw ArgumentError('ImportTemplate templateId cannot be empty.');
    }
    if (companyId.trim().isEmpty) {
      throw ArgumentError('ImportTemplate companyId cannot be empty for multi-company isolation.');
    }
    if (targetProfileId.trim().isEmpty) {
      throw ArgumentError('ImportTemplate targetProfileId cannot be empty.');
    }
  }

  factory ImportTemplate.fromJson(Map<String, dynamic> json) {
    // Sanitize any accidental secret keys from config maps
    final rawNorm = Map<String, dynamic>.from(json['normalizationConfig'] as Map? ?? {});
    final rawVal = Map<String, dynamic>.from(json['validationConfig'] as Map? ?? {});
    final rawExec = Map<String, dynamic>.from(json['executionPolicy'] as Map? ?? {});

    return ImportTemplate(
      templateId: json['templateId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      companyId: json['companyId'] as String,
      targetProfileId: json['targetProfileId'] as String,
      targetEntityType: json['targetEntityType'] as String,
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      fieldMappings: Map<String, String>.from(json['fieldMappings'] as Map? ?? {}),
      ignoredColumns: List<String>.from(json['ignoredColumns'] as List? ?? []),
      normalizationConfig: _sanitizeSecrets(rawNorm),
      validationConfig: _sanitizeSecrets(rawVal),
      relationStrategies: Map<String, dynamic>.from(json['relationStrategies'] as Map? ?? {}),
      assignments: Map<String, dynamic>.from(json['assignments'] as Map? ?? {}),
      executionPolicy: _sanitizeSecrets(rawExec),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String).toUtc() : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String).toUtc() : null,
    );
  }

  static const int currentSchemaVersion = 1;

  /// Sensitive key patterns forbidden from being stored in templates.
  static const Set<String> _forbiddenSecretKeys = {
    'api_key',
    'apikey',
    'secret',
    'password',
    'auth_token',
    'token',
    'credential',
    'credentials',
  };

  /// Unique template ID.
  final String templateId;

  /// User-defined template name (e.g. "Supplier ABC Products").
  final String name;

  /// Optional description.
  final String? description;

  /// Multi-company tenant scope.
  final String companyId;

  /// Target profile ID.
  final String targetProfileId;

  /// Target entity type (e.g. "Product").
  final String targetEntityType;

  /// Template schema version for migration & compatibility checks.
  final int schemaVersion;

  /// Column header -> Target field key mappings.
  final Map<String, String> fieldMappings;

  /// Column headers to ignore.
  final List<String> ignoredColumns;

  /// Normalization configuration (locales, date formats, casing).
  final Map<String, dynamic> normalizationConfig;

  /// Validation rules & overrides.
  final Map<String, dynamic> validationConfig;

  /// Relation resolution strategy settings by relation key.
  final Map<String, dynamic> relationStrategies;

  /// Post-import assignment rules.
  final Map<String, dynamic> assignments;

  /// Execution policy (chunk size, persistence mode, retry rules).
  final Map<String, dynamic> executionPolicy;

  /// Template creation timestamp.
  final DateTime createdAt;

  /// Template last update timestamp.
  final DateTime updatedAt;

  ImportTemplate copyWith({
    String? templateId,
    String? name,
    String? description,
    String? companyId,
    String? targetProfileId,
    String? targetEntityType,
    int? schemaVersion,
    Map<String, String>? fieldMappings,
    List<String>? ignoredColumns,
    Map<String, dynamic>? normalizationConfig,
    Map<String, dynamic>? validationConfig,
    Map<String, dynamic>? relationStrategies,
    Map<String, dynamic>? assignments,
    Map<String, dynamic>? executionPolicy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ImportTemplate(
      templateId: templateId ?? this.templateId,
      name: name ?? this.name,
      description: description ?? this.description,
      companyId: companyId ?? this.companyId,
      targetProfileId: targetProfileId ?? this.targetProfileId,
      targetEntityType: targetEntityType ?? this.targetEntityType,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      fieldMappings: fieldMappings ?? this.fieldMappings,
      ignoredColumns: ignoredColumns ?? this.ignoredColumns,
      normalizationConfig: normalizationConfig ?? this.normalizationConfig,
      validationConfig: validationConfig ?? this.validationConfig,
      relationStrategies: relationStrategies ?? this.relationStrategies,
      assignments: assignments ?? this.assignments,
      executionPolicy: executionPolicy ?? this.executionPolicy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'templateId': templateId,
      'name': name,
      'description': description,
      'companyId': companyId,
      'targetProfileId': targetProfileId,
      'targetEntityType': targetEntityType,
      'schemaVersion': schemaVersion,
      'fieldMappings': fieldMappings,
      'ignoredColumns': ignoredColumns,
      'normalizationConfig': _sanitizeSecrets(normalizationConfig),
      'validationConfig': _sanitizeSecrets(validationConfig),
      'relationStrategies': relationStrategies,
      'assignments': assignments,
      'executionPolicy': _sanitizeSecrets(executionPolicy),
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  static Map<String, dynamic> _sanitizeSecrets(Map<String, dynamic> input) {
    final result = <String, dynamic>{};
    for (final entry in input.entries) {
      final cleanKey = entry.key.toLowerCase().trim();
      if (_forbiddenSecretKeys.contains(cleanKey)) {
        continue; // Strip secret
      }
      if (entry.value is Map<String, dynamic>) {
        result[entry.key] = _sanitizeSecrets(entry.value as Map<String, dynamic>);
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }
}
