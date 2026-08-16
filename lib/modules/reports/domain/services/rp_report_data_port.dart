/// Receipts & Payments report kinds (Reports module — no R&P imports).
enum RpReportKind {
  receipts,
  payments,
  cashMovement,
  bankMovement,
  customerReceipts,
  dailySummary,
  periodSummary,
}

class RpReportRow {
  const RpReportRow({
    required this.transactionNumber,
    required this.transactionDate,
    required this.typeLabel,
    required this.partyLabel,
    required this.amount,
    required this.currencyCode,
    required this.statusLabel,
  });

  final String transactionNumber;
  final DateTime transactionDate;
  final String typeLabel;
  final String partyLabel;
  final double amount;
  final String currencyCode;
  final String statusLabel;
}

class RpReportPayload {
  const RpReportPayload({
    required this.companyName,
    required this.reportTitle,
    required this.periodLabel,
    required this.generatedAtLabel,
    required this.totalLabel,
    required this.countLabel,
    required this.totalAmount,
    required this.totalCount,
    required this.columnNumber,
    required this.columnDate,
    required this.columnType,
    required this.columnParty,
    required this.columnAmount,
    required this.columnStatus,
    required this.rows,
    this.truncatedNote,
  });

  final String companyName;
  final String reportTitle;
  final String periodLabel;
  final String generatedAtLabel;
  final String totalLabel;
  final String countLabel;
  final double totalAmount;
  final int totalCount;
  final String columnNumber;
  final String columnDate;
  final String columnType;
  final String columnParty;
  final String columnAmount;
  final String columnStatus;
  final List<RpReportRow> rows;
  final String? truncatedNote;
}

class RpReportQuery {
  const RpReportQuery({
    required this.kind,
    required this.from,
    required this.to,
    this.customerId,
    this.rowLimit = 5000,
  });

  final RpReportKind kind;
  final DateTime from;
  final DateTime to;
  final String? customerId;
  final int rowLimit;
}

class RpReportData {
  const RpReportData({
    required this.totalAmount,
    required this.totalCount,
    required this.rows,
  });

  final double totalAmount;
  final int totalCount;
  final List<RpReportRow> rows;
}

/// App wires to Receipts & Payments repository (modules ↛ modules).
abstract class RpReportDataPort {
  Future<RpReportData> load(RpReportQuery query);
}

class NoOpRpReportDataPort implements RpReportDataPort {
  const NoOpRpReportDataPort();

  @override
  Future<RpReportData> load(RpReportQuery query) async {
    return const RpReportData(totalAmount: 0, totalCount: 0, rows: []);
  }
}
