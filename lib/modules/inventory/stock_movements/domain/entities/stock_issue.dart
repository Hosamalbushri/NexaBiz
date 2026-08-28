import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'stock_movement_line.dart';

/// Represents an outgoing stock issue movement document.
class StockIssue {
  StockIssue({
    String? id,
    required this.issueNumber,
    this.destination,
    this.accountId,
    this.accountName,
    this.currencyCode = 'SAR',
    this.exchangeRate = 1.0,
    this.voucherBookId,
    this.warehouse,
    this.notes,
    required this.issueDate,
    this.lines = const [],
    this.status = InventoryDocumentStatus.draft,
    this.postedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncStatus = SyncStatus.synced,
    this.lastSyncedAt,
    this.version = 1,
    this.companyId,
    this.deletedAt,
  })  : id = id ?? generateUuidV4(),
        createdAt = createdAt ?? DateTime.now().toUtc(),
        updatedAt = updatedAt ?? DateTime.now().toUtc();

  final String id;
  final String issueNumber;
  final String? destination;
  final String? accountId;
  final String? accountName;
  final String currencyCode;
  final double exchangeRate;
  final int? voucherBookId;
  final String? warehouse;
  final String? notes;
  final DateTime issueDate;
  final List<StockMovementLine> lines;
  final InventoryDocumentStatus status;
  final DateTime? postedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final DateTime? lastSyncedAt;
  final int version;
  final String? companyId;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;
  bool get isPosted => status == InventoryDocumentStatus.posted;
  bool get isDraft => status == InventoryDocumentStatus.draft;

  double get totalQuantity => lines.fold(0.0, (sum, line) => sum + line.quantity);
  double get totalCost => lines.fold(0.0, (sum, line) => sum + line.totalCost);

  StockIssue copyWith({
    String? id,
    String? issueNumber,
    String? destination,
    String? accountId,
    bool clearAccountId = false,
    String? accountName,
    bool clearAccountName = false,
    String? currencyCode,
    double? exchangeRate,
    int? voucherBookId,
    bool clearVoucherBookId = false,
    String? warehouse,
    bool clearWarehouse = false,
    String? notes,
    DateTime? issueDate,
    List<StockMovementLine>? lines,
    InventoryDocumentStatus? status,
    DateTime? postedAt,
    bool clearPostedAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    DateTime? lastSyncedAt,
    bool clearLastSyncedAt = false,
    int? version,
    String? companyId,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return StockIssue(
      id: id ?? this.id,
      issueNumber: issueNumber ?? this.issueNumber,
      destination: destination ?? this.destination,
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
      accountName: clearAccountName ? null : (accountName ?? this.accountName),
      currencyCode: currencyCode ?? this.currencyCode,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      voucherBookId: clearVoucherBookId ? null : (voucherBookId ?? this.voucherBookId),
      warehouse: clearWarehouse ? null : (warehouse ?? this.warehouse),
      notes: notes ?? this.notes,
      issueDate: issueDate ?? this.issueDate,
      lines: lines ?? this.lines,
      status: status ?? this.status,
      postedAt: clearPostedAt ? null : (postedAt ?? this.postedAt),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: clearLastSyncedAt ? null : (lastSyncedAt ?? this.lastSyncedAt),
      version: version ?? this.version,
      companyId: companyId ?? this.companyId,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
