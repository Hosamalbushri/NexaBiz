import 'package:flutter/foundation.dart';

/// Supported types of input parameters for the dynamic Report Engine.
enum ReportParameterType {
  text,
  number,
  date,
  dateRange,
  relativeDate,
  select,
  multiSelect,
  boolean,
  currency,
  product,
  category,
  warehouse,
  customer,
  supplier,
  account,
  postingStatus,
  custom,
}

/// Represents a single option item for select or multi-select parameters.
@immutable
class ReportSelectOption {
  const ReportSelectOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.iconName,
    this.extraData,
  });

  final String value;
  final String label;
  final String? subtitle;
  final String? iconName;
  final Map<String, dynamic>? extraData;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportSelectOption &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          label == other.label;

  @override
  int get hashCode => value.hashCode ^ label.hashCode;
}

/// Specification for declaring report query parameters & filters.
@immutable
class ReportParameterSpec {
  const ReportParameterSpec({
    required this.id,
    required this.label,
    required this.type,
    this.defaultValue,
    this.options = const [],
    this.dependsOn,
    this.isRequired = false,
    this.isMultiSelect = false,
    this.placeholder,
    this.helpText,
    this.flex = 1,
    this.extraConfig = const {},
  });

  /// Unique identifier of the parameter (e.g. 'warehouseId', 'fromDate', 'postingStatus').
  final String id;

  /// Display label (localized).
  final String label;

  /// Type of the parameter.
  final ReportParameterType type;

  /// Default value if none selected by user.
  final dynamic defaultValue;

  /// Available options for `select` or `multiSelect` types.
  final List<ReportSelectOption> options;

  /// ID of parent parameter that this parameter depends on (for cascading filters).
  final String? dependsOn;

  /// Whether this parameter is mandatory to execute report.
  final bool isRequired;

  /// Whether multiple values can be selected.
  final bool isMultiSelect;

  /// Optional hint / placeholder text.
  final String? placeholder;

  /// Optional helper tooltip or subtitle text.
  final String? helpText;

  /// Flex width factor in filter panel layout.
  final int flex;

  /// Additional metadata or custom options.
  final Map<String, dynamic> extraConfig;

  ReportParameterSpec copyWith({
    String? id,
    String? label,
    ReportParameterType? type,
    dynamic defaultValue,
    List<ReportSelectOption>? options,
    String? dependsOn,
    bool? isRequired,
    bool? isMultiSelect,
    String? placeholder,
    String? helpText,
    int? flex,
    Map<String, dynamic>? extraConfig,
  }) {
    return ReportParameterSpec(
      id: id ?? this.id,
      label: label ?? this.label,
      type: type ?? this.type,
      defaultValue: defaultValue ?? this.defaultValue,
      options: options ?? this.options,
      dependsOn: dependsOn ?? this.dependsOn,
      isRequired: isRequired ?? this.isRequired,
      isMultiSelect: isMultiSelect ?? this.isMultiSelect,
      placeholder: placeholder ?? this.placeholder,
      helpText: helpText ?? this.helpText,
      flex: flex ?? this.flex,
      extraConfig: extraConfig ?? this.extraConfig,
    );
  }
}
