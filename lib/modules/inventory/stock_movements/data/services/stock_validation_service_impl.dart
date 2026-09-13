import 'package:drift/drift.dart';
import 'package:stock_count/core/data/multi_tenant_repository_guard.dart';
import 'package:stock_count/core/auth/domain/services/local_authorization_guard.dart';
import 'package:stock_count/core/database/tenant_database_name.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import '../../domain/services/stock_validation_service.dart';

class StockValidationServiceImpl implements StockValidationService {
  StockValidationServiceImpl(this._db, [String Function()? readCompanyId])
    : _readCompanyId = readCompanyId;

  final NexabizDatabase _db;
  final String Function()? _readCompanyId;

  String get _currentCompanyId {
    final id = _readCompanyId?.call();
    return MultiTenantRepositoryGuard.enforceCompanyContext(
      companyId: id,
      activeCompanyId: id,
    );
  }

  @override
  Future<double> getPostedBalance({
    required String itemCode,
    String? warehouseId,
  }) async {
    final query = _db.select(_db.inventoryCostLayers)
      ..where(
        (tbl) =>
            tbl.itemCode.equals(itemCode) &
            tbl.companyId.equals(_currentCompanyId) &
            tbl.closed.equals(0) &
            tbl.deletedAt.isNull(),
      );

    if (warehouseId != null && warehouseId.isNotEmpty) {
      query.where((tbl) => tbl.warehouseId.equals(warehouseId));
    }

    final layers = await query.get();
    double total = 0.0;
    for (final layer in layers) {
      total += layer.remainingQty;
    }
    return total;
  }

  @override
  Future<List<StockShortageItem>> validateOutboundLines({
    required List<OutboundLineRequest> lines,
    String? warehouseId,
  }) async {
    final shortages = <StockShortageItem>[];

    // Group requested quantities by itemCode to handle multiple lines of same item
    final requestedByItem = <String, OutboundLineRequest>{};
    final totalRequested = <String, double>{};

    for (final line in lines) {
      requestedByItem[line.itemCode] = line;
      totalRequested[line.itemCode] =
          (totalRequested[line.itemCode] ?? 0.0) + line.requestedQuantity;
    }

    for (final entry in totalRequested.entries) {
      final itemCode = entry.key;
      final requestedQty = entry.value;

      final availableQty = await getPostedBalance(
        itemCode: itemCode,
        warehouseId: warehouseId,
      );

      if (availableQty < requestedQty) {
        final lineReq = requestedByItem[itemCode]!;
        shortages.add(
          StockShortageItem(
            itemCode: itemCode,
            itemName: lineReq.itemName,
            requested: requestedQty,
            available: availableQty,
            shortage: requestedQty - availableQty,
          ),
        );
      }
    }

    return shortages;
  }

  @override
  Future<void> validateWarehouseAccess({
    required String? warehouseId,
    String? companyId,
  }) async {
    if (warehouseId == null || warehouseId.trim().isEmpty) {
      throw StateError(
        'Warehouse selection is mandatory for inventory transaction',
      );
    }

    final targetCompanyId = companyId ?? _currentCompanyId;

    final warehouse =
        await (_db.select(_db.warehouses)..where(
              (tbl) => tbl.id.equals(warehouseId) & tbl.isActive.equals(true),
            ))
            .getSingleOrNull();

    if (warehouse == null) {
      throw StateError('Warehouse with ID ($warehouseId) does not exist');
    }

    if (warehouse.companyId != targetCompanyId) {
      throw CompanyContextMismatchException(
        message:
            'Cross-tenant warehouse access denied for warehouse ($warehouseId). Expected company: $targetCompanyId, actual: ${warehouse.companyId}',
        expectedCompanyId: targetCompanyId,
        actualCompanyId: warehouse.companyId ?? '',
      );
    }

    if (!warehouse.isActive) {
      throw StateError(
        'Warehouse (${warehouse.name}) is inactive and cannot be used for transactions',
      );
    }
  }
}
