import 'dart:convert';

/// One counter/party CoA allocation on a receipt or payment.
class FinancialTransactionLine {
  const FinancialTransactionLine({
    required this.accountId,
    required this.amount,
    required this.currencyCode,
    required this.exchangeRate,
    required this.lineOrder,
    this.accountCode,
    this.accountName,
    this.description,
  });

  final String accountId;
  final String? accountCode;
  final String? accountName;
  final double amount;
  final String currencyCode;

  /// Party currency → base rate snapshot.
  final double exchangeRate;
  final String? description;
  final int lineOrder;

  Map<String, dynamic> toJson() => {
        'accountId': accountId,
        'accountCode': accountCode,
        'accountName': accountName,
        'amount': amount,
        'currencyCode': currencyCode,
        'exchangeRate': exchangeRate,
        'description': description,
        'lineOrder': lineOrder,
      };

  factory FinancialTransactionLine.fromJson(Map<String, dynamic> json) {
    return FinancialTransactionLine(
      accountId: (json['accountId'] as String?)?.trim() ?? '',
      accountCode: (json['accountCode'] as String?)?.trim(),
      accountName: (json['accountName'] as String?)?.trim(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currencyCode:
          ((json['currencyCode'] as String?)?.trim().isNotEmpty ?? false)
              ? (json['currencyCode'] as String).trim().toUpperCase()
              : 'SAR',
      exchangeRate: (json['exchangeRate'] as num?)?.toDouble() ?? 1,
      description: (json['description'] as String?)?.trim(),
      lineOrder: (json['lineOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Encode / decode allocation lines stored as JSON on the header row.
abstract final class FinancialTransactionLinesCodec {
  static String? encode(List<FinancialTransactionLine> lines) {
    if (lines.isEmpty) return null;
    return jsonEncode([for (final line in lines) line.toJson()]);
  }

  static List<FinancialTransactionLine> decode(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return const [];
    try {
      final decoded = jsonDecode(text);
      if (decoded is! List) return const [];
      final lines = <FinancialTransactionLine>[];
      for (var i = 0; i < decoded.length; i++) {
        final item = decoded[i];
        if (item is! Map) continue;
        final line = FinancialTransactionLine.fromJson(
          Map<String, dynamic>.from(item),
        );
        if (line.accountId.isEmpty) continue;
        lines.add(
          FinancialTransactionLine(
            accountId: line.accountId,
            accountCode: line.accountCode,
            accountName: line.accountName,
            amount: line.amount,
            currencyCode: line.currencyCode,
            exchangeRate: line.exchangeRate <= 0 ? 1 : line.exchangeRate,
            description: line.description,
            lineOrder: line.lineOrder > 0 ? line.lineOrder : i,
          ),
        );
      }
      lines.sort((a, b) => a.lineOrder.compareTo(b.lineOrder));
      return lines;
    } catch (_) {
      return const [];
    }
  }

  /// Legacy single-counter documents become one allocation line.
  static List<FinancialTransactionLine> fromHeader({
    required String accountId,
    String? accountCode,
    String? accountName,
    required double amount,
    required String currencyCode,
    required double exchangeRate,
    String? description,
  }) {
    final id = accountId.trim();
    if (id.isEmpty) return const [];
    return [
      FinancialTransactionLine(
        accountId: id,
        accountCode: accountCode,
        accountName: accountName,
        amount: amount,
        currencyCode: currencyCode,
        exchangeRate: exchangeRate <= 0 ? 1 : exchangeRate,
        description: description,
        lineOrder: 0,
      ),
    ];
  }
}
