import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';

class CostValuationMethodNotifier extends StateNotifier<CostValuationMethod> {
  CostValuationMethodNotifier() : super(CostValuationMethod.fifo);

  void setMethod(CostValuationMethod method) {
    state = method;
  }
}

final costValuationMethodProvider = StateNotifierProvider<CostValuationMethodNotifier, CostValuationMethod>((ref) {
  return CostValuationMethodNotifier();
});
