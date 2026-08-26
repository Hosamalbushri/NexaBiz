/// SQL-aggregated dashboard metrics (never built from full table scans in Dart).
class TransactionDashboardSummary {
  const TransactionDashboardSummary({
    required this.todayReceiptsTotal,
    required this.todayReceiptsCount,
    required this.todayPaymentsTotal,
    required this.todayPaymentsCount,
    required this.periodReceiptsTotal,
    required this.periodReceiptsCount,
    required this.periodPaymentsTotal,
    required this.periodPaymentsCount,
    required this.cashMovementNet,
    required this.bankMovementNet,
    required this.pendingSyncCount,
    required this.failedSyncCount,
  });

  final double todayReceiptsTotal;
  final int todayReceiptsCount;
  final double todayPaymentsTotal;
  final int todayPaymentsCount;
  final double periodReceiptsTotal;
  final int periodReceiptsCount;
  final double periodPaymentsTotal;
  final int periodPaymentsCount;
  final double cashMovementNet;
  final double bankMovementNet;
  final int pendingSyncCount;
  final int failedSyncCount;

  double get netMovement => periodReceiptsTotal - periodPaymentsTotal;

  static const empty = TransactionDashboardSummary(
    todayReceiptsTotal: 0,
    todayReceiptsCount: 0,
    todayPaymentsTotal: 0,
    todayPaymentsCount: 0,
    periodReceiptsTotal: 0,
    periodReceiptsCount: 0,
    periodPaymentsTotal: 0,
    periodPaymentsCount: 0,
    cashMovementNet: 0,
    bankMovementNet: 0,
    pendingSyncCount: 0,
    failedSyncCount: 0,
  );
}
