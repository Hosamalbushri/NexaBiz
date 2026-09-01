import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/core/domain/ports/posting_port.dart';
import 'package:stock_count/core/domain/services/inventory_subledger_port.dart';

import 'package:stock_count/core/domain/ports/period_validator_port.dart';

final postingCoordinatorPortProvider = Provider<PostingCoordinatorPort>((ref) {
  throw UnimplementedError('postingCoordinatorPortProvider must be overridden or registered');
});

final inventorySubledgerQueryPortProvider = Provider<InventorySubledgerQueryPort>((ref) {
  throw UnimplementedError('inventorySubledgerQueryPortProvider must be overridden or registered');
});

final periodValidatorPortProvider = Provider<PeriodValidatorPort>((ref) {
  throw UnimplementedError('periodValidatorPortProvider must be overridden or registered');
});

