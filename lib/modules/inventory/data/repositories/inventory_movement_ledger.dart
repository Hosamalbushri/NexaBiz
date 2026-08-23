import 'dart:async';

import '../../../../core/sync/sync_operation.dart';
import '../../../../core/sync/sync_queue.dart';
import '../repositories/inventory_repository_impl.dart';

/// Represents an append-only inventory movement event.
class InventoryMovementEvent {
  const InventoryMovementEvent({
    required this.uuid,
    required this.itemCode,
    required this.quantityChange,
    required this.movementType,
    required this.createdAt,
    this.referenceId,
    this.version = 1,
  });

  final String uuid;
  final String itemCode;
  final double quantityChange;
  final String movementType; // 'sale', 'purchase', 'adjustment', 'transfer', 'stock_count'
  final String? referenceId;
  final DateTime createdAt;
  final int version;

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'itemCode': itemCode,
      'quantityChange': quantityChange,
      'movementType': movementType,
      'referenceId': referenceId,
      'createdAt': createdAt.toUtc().millisecondsSinceEpoch,
      'version': version,
    };
  }

  factory InventoryMovementEvent.fromMap(Map<String, dynamic> map) {
    return InventoryMovementEvent(
      uuid: map['uuid'] as String? ?? map['id'] as String? ?? '',
      itemCode: map['itemCode'] as String? ?? '',
      quantityChange: (map['quantityChange'] as num?)?.toDouble() ?? 0.0,
      movementType: map['movementType'] as String? ?? 'adjustment',
      referenceId: map['referenceId'] as String?,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '')?.toUtc() ??
          (map['createdAt'] is num
              ? DateTime.fromMillisecondsSinceEpoch((map['createdAt'] as num).toInt(), isUtc: true)
              : DateTime.now().toUtc()),
      version: (map['version'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Ledger managing append-only inventory movement events and derived stock snapshots.
class InventoryMovementLedger {
  InventoryMovementLedger({
    InventoryRepositoryImpl? inventoryRepo,
    SyncQueue? syncQueue,
  }) : _inventoryRepo = inventoryRepo,
       _syncQueue = syncQueue;

  final InventoryRepositoryImpl? _inventoryRepo;
  final SyncQueue? _syncQueue;

  static const entityType = 'inventory_movement';

  final Map<String, List<InventoryMovementEvent>> _eventsByItem = {};

  /// Record an append-only movement event and update derived inventory item stock snapshot.
  Future<void> recordMovement(InventoryMovementEvent event) async {
    _eventsByItem.putIfAbsent(event.itemCode, () => []).add(event);

    // Queue outbound sync operation for remote propagation
    final queue = _syncQueue;
    if (queue != null) {
      await queue.enqueue(
        SyncOperation.create(
          entityType: entityType,
          entityId: event.uuid,
          type: SyncOperationType.create,
          baseVersion: event.version,
          payload: event.toMap(),
        ),
      );
    }

    // Update local derived inventory snapshot
    final repo = _inventoryRepo;
    if (repo != null) {
      final existing = await repo.getByCode(event.itemCode);
      if (existing != null) {
        final currentActual = existing.actualQuantity ?? 0.0;
        final newActual = currentActual + event.quantityChange;
        await repo.save(
          existing.copyWith(
            actualQuantity: newActual,
            mainQuantity: newActual,
            version: existing.version + 1,
          ),
        );
      }
    }
  }

  /// Calculate authoritative derived stock snapshot for a product item code.
  ///
  /// `Stock = Opening Balance + Sum(Movement Quantity Changes)`
  double calculateDerivedStock({
    required String itemCode,
    double openingBalance = 0.0,
  }) {
    final events = _eventsByItem[itemCode] ?? [];
    double totalChange = 0.0;
    for (final event in events) {
      totalChange += event.quantityChange;
    }
    return openingBalance + totalChange;
  }

  /// Apply incoming remote movement event from change stream safely.
  Future<void> applyRemoteMovement(Map<String, dynamic> payload) async {
    final event = InventoryMovementEvent.fromMap(payload);
    final existingList = _eventsByItem[event.itemCode] ?? [];
    if (existingList.any((e) => e.uuid == event.uuid)) {
      // Idempotent ignore duplicate event
      return;
    }
    _eventsByItem.putIfAbsent(event.itemCode, () => []).add(event);

    final repo = _inventoryRepo;
    if (repo != null) {
      final existing = await repo.getByCode(event.itemCode);
      if (existing != null) {
        final currentActual = existing.actualQuantity ?? 0.0;
        final newActual = currentActual + event.quantityChange;
        await repo.save(
          existing.copyWith(
            actualQuantity: newActual,
            mainQuantity: newActual,
            version: existing.version + 1,
          ),
        );
      }
    }
  }
}
