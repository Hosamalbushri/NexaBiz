import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/business_date.dart';
import '../../../sales/domain/services/device_sale_number.dart';
import '../../domain/entities/transaction_list_item.dart';
import '../../domain/entities/transaction_status.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/models/transaction_list_filter.dart';
import 'rp_providers.dart';

enum RpPostingLookupMode { byDate, byNumber }

enum RpPostingOperation { post, unpost }

class RpPostingServiceState {
  const RpPostingServiceState({
    this.transactionType = TransactionType.receipt,
    this.operation = RpPostingOperation.post,
    this.lookupMode = RpPostingLookupMode.byDate,
    this.fromDate,
    this.toDate,
    this.numberFrom = '',
    this.numberTo = '',
    this.items = const [],
    this.selectedId,
    this.hasSearched = false,
    this.isLoading = false,
    this.isApplying = false,
    this.error,
  });

  final TransactionType transactionType;
  final RpPostingOperation operation;
  final RpPostingLookupMode lookupMode;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String numberFrom;
  final String numberTo;
  final List<TransactionListItem> items;
  final int? selectedId;
  final bool hasSearched;
  final bool isLoading;
  final bool isApplying;
  final Object? error;

  TransactionStatus get targetStatus => operation == RpPostingOperation.post
      ? TransactionStatus.unposted
      : TransactionStatus.posted;

  RpPostingServiceState copyWith({
    TransactionType? transactionType,
    RpPostingOperation? operation,
    RpPostingLookupMode? lookupMode,
    DateTime? fromDate,
    bool clearFromDate = false,
    DateTime? toDate,
    bool clearToDate = false,
    String? numberFrom,
    String? numberTo,
    List<TransactionListItem>? items,
    int? selectedId,
    bool clearSelectedId = false,
    bool? hasSearched,
    bool? isLoading,
    bool? isApplying,
    Object? error,
    bool clearError = false,
  }) {
    return RpPostingServiceState(
      transactionType: transactionType ?? this.transactionType,
      operation: operation ?? this.operation,
      lookupMode: lookupMode ?? this.lookupMode,
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate: clearToDate ? null : (toDate ?? this.toDate),
      numberFrom: numberFrom ?? this.numberFrom,
      numberTo: numberTo ?? this.numberTo,
      items: items ?? this.items,
      selectedId: clearSelectedId ? null : (selectedId ?? this.selectedId),
      hasSearched: hasSearched ?? this.hasSearched,
      isLoading: isLoading ?? this.isLoading,
      isApplying: isApplying ?? this.isApplying,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RpPostingServiceNotifier extends StateNotifier<RpPostingServiceState> {
  RpPostingServiceNotifier(this._ref) : super(const RpPostingServiceState());

  final Ref _ref;

  void setTransactionType(TransactionType type) {
    state = state.copyWith(
      transactionType: type,
      items: const [],
      clearSelectedId: true,
      hasSearched: false,
      clearError: true,
    );
  }

  void setOperation(RpPostingOperation operation) {
    state = state.copyWith(
      operation: operation,
      items: const [],
      clearSelectedId: true,
      hasSearched: false,
      clearError: true,
    );
  }

  void setLookupMode(RpPostingLookupMode mode) {
    state = state.copyWith(
      lookupMode: mode,
      items: const [],
      clearSelectedId: true,
      hasSearched: false,
      clearError: true,
    );
  }

  void setFromDate(DateTime? date) {
    state = state.copyWith(
      fromDate: date,
      clearFromDate: date == null,
      items: const [],
      clearSelectedId: true,
      hasSearched: false,
      clearError: true,
    );
  }

  void setToDate(DateTime? date) {
    state = state.copyWith(
      toDate: date,
      clearToDate: date == null,
      items: const [],
      clearSelectedId: true,
      hasSearched: false,
      clearError: true,
    );
  }

  void setNumberFrom(String value) {
    state = state.copyWith(
      numberFrom: value,
      items: const [],
      clearSelectedId: true,
      hasSearched: false,
      clearError: true,
    );
  }

  void setNumberTo(String value) {
    state = state.copyWith(
      numberTo: value,
      items: const [],
      clearSelectedId: true,
      hasSearched: false,
      clearError: true,
    );
  }

  void selectItem(int? id) {
    state = state.copyWith(
      selectedId: id,
      clearSelectedId: id == null,
      clearError: true,
    );
  }

  Future<void> search() async {
    if (state.lookupMode == RpPostingLookupMode.byDate) {
      if (state.fromDate == null || state.toDate == null) {
        state = state.copyWith(error: 'date_required');
        return;
      }
      if (BusinessDate.utcDay(state.fromDate!)
          .isAfter(BusinessDate.utcDay(state.toDate!))) {
        state = state.copyWith(error: 'date_range_invalid');
        return;
      }
    } else {
      final from = parseSaleNumberSequence(state.numberFrom);
      final to = parseSaleNumberSequence(state.numberTo);
      if (from == null || to == null) {
        state = state.copyWith(error: 'number_required');
        return;
      }
      if (from > to) {
        state = state.copyWith(error: 'number_range_invalid');
        return;
      }
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      hasSearched: true,
      clearSelectedId: true,
    );
    try {
      final byDate = state.lookupMode == RpPostingLookupMode.byDate;
      final fromNum = byDate ? null : parseSaleNumberSequence(state.numberFrom);
      final toNum = byDate ? null : parseSaleNumberSequence(state.numberTo);
      final filter = TransactionListFilter(
        transactionType: state.transactionType,
        documentStatus: state.targetStatus,
        fromDate: byDate ? state.fromDate : null,
        toDate: byDate ? state.toDate : null,
        numberFrom: fromNum,
        numberTo: toNum,
      );
      final result = await _ref.read(searchFinancialTransactionsProvider)(
        filter: filter,
        page: 0,
        pageSize: 500,
      );
      state = state.copyWith(
        isLoading: false,
        items: result.items,
        selectedId: result.items.length == 1 ? result.items.first.id : null,
        clearSelectedId: result.items.length != 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, items: const [], error: e);
    }
  }

  Future<({int success, int failed, Object? firstError})> applySelected() {
    final id = state.selectedId;
    if (id == null) {
      return Future.value((success: 0, failed: 0, firstError: 'none_selected'));
    }
    return _applyIds([id]);
  }

  Future<({int success, int failed, Object? firstError})> applyAll() {
    final ids = state.items.map((e) => e.id).toList(growable: false);
    if (ids.isEmpty) {
      return Future.value((success: 0, failed: 0, firstError: 'empty_list'));
    }
    return _applyIds(ids);
  }

  Future<({int success, int failed, Object? firstError})> _applyIds(
    List<int> ids,
  ) async {
    state = state.copyWith(isApplying: true, clearError: true);
    var success = 0;
    var failed = 0;
    Object? firstError;
    final post = _ref.read(postFinancialTransactionProvider);
    final unpost = _ref.read(unpostFinancialTransactionProvider);
    for (final id in ids) {
      try {
        if (state.operation == RpPostingOperation.post) {
          await post(id);
        } else {
          await unpost(id);
        }
        success++;
      } catch (e) {
        failed++;
        firstError ??= e;
      }
    }
    state = state.copyWith(isApplying: false);
    await search();
    return (success: success, failed: failed, firstError: firstError);
  }
}

final rpPostingServiceProvider =
    StateNotifierProvider.autoDispose<
      RpPostingServiceNotifier,
      RpPostingServiceState
    >((ref) => RpPostingServiceNotifier(ref));
