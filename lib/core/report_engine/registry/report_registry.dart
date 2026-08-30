import '../data/definitions/sales_period_report_spec.dart';
import '../data/definitions/stock_movement_report_spec.dart';
import '../data/providers/report_data_provider.dart';
import '../domain/models/report_definition_spec.dart';

/// Central Registry cataloging all declarative Report Specifications & Data Providers in NexaBiz ERP.
class ReportRegistry {
  ReportRegistry._();

  static final Map<String, ReportDefinitionSpec> _definitions = {
    stockMovementReportSpec.id: stockMovementReportSpec,
    salesPeriodReportSpec.id: salesPeriodReportSpec,
  };

  static final Map<String, ReportDataProvider> _providers = {};

  /// Registers a custom or dynamic [ReportDataProvider].
  static void registerProvider(ReportDataProvider provider) {
    _providers[provider.reportId] = provider;
  }

  /// Returns all registered report definitions grouped by category.
  static List<ReportDefinitionSpec> get allDefinitions => _definitions.values.toList();

  /// Gets a specific [ReportDefinitionSpec] by its report ID.
  static ReportDefinitionSpec? getDefinition(String id) => _definitions[id];

  /// Gets registered provider for a given report ID.
  static ReportDataProvider? getProvider(String id) => _providers[id];
}
