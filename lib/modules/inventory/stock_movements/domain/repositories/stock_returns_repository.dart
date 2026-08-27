import '../entities/stock_return.dart';

abstract class StockReturnsRepository {
  Future<List<StockReturn>> getAllReturns();
  Stream<List<StockReturn>> watchAllReturns();
  Future<StockReturn?> getReturnById(String id);
  Future<void> saveReturn(StockReturn returnDoc);
  Future<void> deleteReturn(String id);
}
