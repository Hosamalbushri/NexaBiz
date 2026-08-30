import '../../domain/models/report_dataset.dart';
import '../../domain/models/report_query_context.dart';

/// Abstract contract for report data providers fetching & aggregating report datasets.
abstract class ReportDataProvider {
  const ReportDataProvider();

  /// Unique identifier matching [ReportDefinitionSpec.id].
  String get reportId;

  /// Executes data fetching, applying security scope, permissions, pagination, and calculations.
  Future<ReportDataset> query(ReportQueryContext context);
}
