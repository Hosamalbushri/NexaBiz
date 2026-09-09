import '../data/providers/report_data_provider.dart';
import '../domain/models/report_definition_spec.dart';

/// Central Registry cataloging all declarative Report Specifications & Data Providers in NexaBiz ERP.
class ReportRegistry {
  ReportRegistry._();

  static final Map<String, ReportDefinitionSpec> _definitions = {};

  static final Map<String, ReportDataProvider> _providers = {};

  /// Registers a declarative [ReportDefinitionSpec].
  static void registerDefinition(ReportDefinitionSpec spec) {
    _definitions[spec.id] = spec;
  }

  /// Registers a custom or dynamic [ReportDataProvider].
  static void registerProvider(ReportDataProvider provider) {
    _providers[provider.reportId] = provider;
  }

  /// Returns all registered report definitions grouped by category.
  static List<ReportDefinitionSpec> get allDefinitions =>
      _definitions.values.toList();

  /// Gets a specific [ReportDefinitionSpec] by its report ID.
  static ReportDefinitionSpec? getDefinition(String id) => _definitions[id];

  /// Gets registered provider for a given report ID.
  static ReportDataProvider? getProvider(String id) => _providers[id];
}
