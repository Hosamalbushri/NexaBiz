import '../../../../core/sync/sync_status.dart';
import 'transaction_status.dart';
import 'transaction_type.dart';

/// Lightweight list row (projection — no full hydrate).
class TransactionListItem {
  const TransactionListItem({
    required this.id,
    required this.uuid,
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

  final int id;
  final String uuid;
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
}
