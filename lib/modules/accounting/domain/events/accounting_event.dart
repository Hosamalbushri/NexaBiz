import 'package:equatable/equatable.dart';

/// Domain integration event contract emitted by operational modules.
///
/// Distinct from [PostingEventLog] infrastructure/audit records.
class AccountingEvent extends Equatable {
  const AccountingEvent({
    required this.eventId,
    required this.companyId,
    required this.eventType,
    required this.sourceType,
    required this.sourceId,
    required this.eventDate,
    required this.payload,
    this.currencyCode,
    this.amount,
  });

  final String eventId;
  final String companyId;
  final String eventType;
  final String sourceType;
  final String sourceId;
  final DateTime eventDate;
  final String? currencyCode;
  final double? amount;
  final Map<String, dynamic> payload;

  @override
  List<Object?> get props => [
        eventId,
        companyId,
        eventType,
        sourceType,
        sourceId,
        eventDate,
        currencyCode,
        amount,
        payload,
      ];
}
