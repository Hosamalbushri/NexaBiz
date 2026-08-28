import 'package:equatable/equatable.dart';

class OutboundLineRequest extends Equatable {
  const OutboundLineRequest({
    required this.itemCode,
    required this.itemName,
    required this.requestedQuantity,
  });

  final String itemCode;
  final String itemName;
  final double requestedQuantity;

  @override
  List<Object?> get props => [itemCode, itemName, requestedQuantity];
}

class StockShortageItem extends Equatable {
  const StockShortageItem({
    required this.itemCode,
    required this.itemName,
    required this.requested,
    required this.available,
    required this.shortage,
  });

  final String itemCode;
  final String itemName;
  final double requested;
  final double available;
  final double shortage;

  @override
  List<Object?> get props => [itemCode, itemName, requested, available, shortage];
}

abstract class StockValidationService {
  /// Calculates posted available quantity for an item code (and optional warehouse).
  Future<double> getPostedBalance({
    required String itemCode,
    String? warehouseId,
  });

  /// Validates a list of outbound lines against available posted stock.
  /// Returns a list of shortages. If empty, stock is available and sufficient.
  Future<List<StockShortageItem>> validateOutboundLines({
    required List<OutboundLineRequest> lines,
    String? warehouseId,
  });
}
