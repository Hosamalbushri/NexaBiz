import 'package:stock_count/core/sync/sync_core.dart';
import 'transaction_status.dart';
import 'transaction_type.dart';

/// Lightweight list row (projection — no full hydrate).
class TransactionListItem {
  const TransactionListItem({
    required this.id,
    required this.transactionNumber,
    required this.transactionType,
    required this.transactionDate,
    required this.amount,
    required this.currencyCode,
    required this.documentStatus,
    required this.syncStatus,
    this.cashAccountName,
    this.counterAccountName,
    this.partyDisplayName,
    this.reference,
    this.description,
  });

  final String id;
  final String transactionNumber;
  final TransactionType transactionType;
  final DateTime transactionDate;
  final double amount;
  final String currencyCode;
  final String? cashAccountName;
  final String? counterAccountName;
  final String? partyDisplayName;
  final String? reference;
  final String? description;
  final TransactionStatus documentStatus;
  final SyncStatus syncStatus;

  String get uuid => id;
}
