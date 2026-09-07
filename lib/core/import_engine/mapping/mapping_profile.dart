/// Reusable saved field mapping preset for an entity import type.
class MappingProfile {
  const MappingProfile({
    required this.id,
    required this.name,
    required this.entityType,
    required this.fieldMappings,
    this.ignoredColumns = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory MappingProfile.fromJson(Map<String, dynamic> json) {
    return MappingProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      entityType: json['entityType'] as String,
      fieldMappings: Map<String, String>.from(
        json['fieldMappings'] as Map? ?? {},
      ),
      ignoredColumns: List<String>.from(json['ignoredColumns'] as List? ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final String id;
  final String name;
  final String entityType;

  /// Map of (normalized source column header -> target field key).
  final Map<String, String> fieldMappings;

  /// List of normalized source column headers to ignore.
  final List<String> ignoredColumns;

  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'entityType': entityType,
      'fieldMappings': fieldMappings,
      'ignoredColumns': ignoredColumns,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  MappingProfile copyWith({
    String? id,
    String? name,
    String? entityType,
    Map<String, String>? fieldMappings,
    List<String>? ignoredColumns,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MappingProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      entityType: entityType ?? this.entityType,
      fieldMappings: fieldMappings ?? this.fieldMappings,
      ignoredColumns: ignoredColumns ?? this.ignoredColumns,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
