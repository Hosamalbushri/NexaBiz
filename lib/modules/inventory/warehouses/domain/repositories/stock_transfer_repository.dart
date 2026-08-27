import '../entities/stock_transfer.dart';

abstract class StockTransferRepository {
  Future<List<StockTransfer>> getAllTransfers();
  Stream<List<StockTransfer>> watchAllTransfers();
  Future<StockTransfer?> getTransferById(String id);
  Future<void> saveTransfer(StockTransfer transfer);
  Future<void> deleteTransfer(String id);
}
