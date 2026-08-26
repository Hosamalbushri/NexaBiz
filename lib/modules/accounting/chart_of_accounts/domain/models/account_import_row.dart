/// One editable account row on the Chart of Accounts import step (structure only).
class AccountImportRow {
  const AccountImportRow({
    required this.id,
    this.code = '',
    this.name = '',
  });

  /// Stable local id for Flutter list keys / edits.
  final String id;
  final String code;
  final String name;

  bool get hasName => name.trim().isNotEmpty;

  AccountImportRow copyWith({
    String? code,
    String? name,
  }) {
    return AccountImportRow(
      id: id,
      code: code ?? this.code,
      name: name ?? this.name,
    );
  }
}

/// Result of parsing an Excel workbook into editable import rows.
class AccountExcelParseResult {
  const AccountExcelParseResult({
    required this.rows,
    this.ignoredCount = 0,
    this.warnings = const [],
  });

  final List<AccountImportRow> rows;
  final int ignoredCount;
  final List<String> warnings;
}

/// Thrown when an Excel workbook cannot be parsed / setup fails.
class AccountImportException implements Exception {
  const AccountImportException(this.code, [this.message]);

  static const emptyWorkbook = 'empty_workbook';
  static const noValidRows = 'no_valid_rows';
  static const decodeFailed = 'decode_failed';
  static const parentRequired = 'parent_required';
  static const parentNotGroup = 'parent_not_group';
  static const invalidRow = 'invalid_row';
  static const bothOpeningSides = 'both_opening_sides';
  static const duplicateCurrency = 'duplicate_currency';
  static const capitalMissing = 'capital_missing';
  static const noRows = 'no_rows';
  static const noBalances = 'no_balances';
  static const accountNotFound = 'account_not_found';
  static const currencyNotConfigured = 'currency_not_configured';
  static const accountRequired = 'account_required';

  final String code;
  final String? message;

  @override
  String toString() =>
      'AccountImportException($code${message == null ? '' : ': $message'})';
}

/// Counts from a completed account-structure import run.
class AccountImportResult {
  const AccountImportResult({
    required this.insertedCount,
    required this.skippedCount,
  });

  final int insertedCount;
  final int skippedCount;
}
