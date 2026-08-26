import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/transaction_list_item.dart';
import '../../domain/models/transaction_list_filter.dart';
import '../../domain/repositories/financial_transaction_repository.dart';
import 'rp_providers.dart';

const kTransactionListPageSize = 30;

final transactionListFilterProvider = StateProvider<TransactionListFilter>(
  (ref) => const TransactionListFilter(),
);

class TransactionListState {
  const TransactionListState({
    this.items = const [],
    this.totalCount = 0,
    this.nextPage = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  final List<TransactionListItem> items;
  final int totalCount;
  final int nextPage;
  final bool hasMore;
  final bool isLoadingMore;

  TransactionListState copyWith({
    List<TransactionListItem>? items,
    int? totalCount,
    int? nextPage,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return TransactionListState(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      nextPage: nextPage ?? this.nextPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class TransactionListNotifier extends StateNotifier<AsyncValue<TransactionListState>> {
  TransactionListNotifier(this._ref) : super(const AsyncLoading()) {
    _filter = _ref.read(transactionListFilterProvider);
    _listenFilter();
    _listenDb();
    unawaited(reload());
  }

  final Ref _ref;
  late TransactionListFilter _filter;
  StreamSubscription<void>? _dbSub;
  ProviderSubscription<TransactionListFilter>? _filterSub;
  var _loadToken = 0;

  FinancialTransactionRepository get _repo =>
      _ref.read(financialTransactionRepositoryProvider);

  void _listenFilter() {
    _filterSub = _ref.listen<TransactionListFilter>(
      transactionListFilterProvider,
      (previous, next) {
        _filter = next;
        unawaited(reload());
      },
    );
  }

  void _listenDb() {
    _dbSub = _repo.watchListChanges().listen((_) {
      unawaited(reload());
    });
  }

  Future<void> reload() async {
    final token = ++_loadToken;
    final wasReady = state.hasValue;
    if (!wasReady) {
      state = const AsyncLoading();
    }
    try {
      final page = await _repo.searchListPaged(
        filter: _filter,
        page: 0,
        pageSize: kTransactionListPageSize,
      );
      if (token != _loadToken) {
        return;
      }
      state = AsyncData(
        TransactionListState(
          items: page.items,
          totalCount: page.totalCount,
          nextPage: 1,
          hasMore: page.hasNext,
        ),
      );
    } catch (e, st) {
      if (token != _loadToken) {
        return;
      }
      state = AsyncError(e, st);
    }
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !current.hasMore || current.isLoadingMore) {
      return;
    }
    final token = _loadToken;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final page = await _repo.searchListPaged(
        filter: _filter,
        page: current.nextPage,
        pageSize: kTransactionListPageSize,
      );
      if (token != _loadToken) {
        return;
      }
      final merged = [...current.items, ...page.items];
      state = AsyncData(
        TransactionListState(
          items: merged,
          totalCount: page.totalCount,
          nextPage: current.nextPage + 1,
          hasMore: page.hasNext,
        ),
      );
    } catch (e, st) {
      if (token != _loadToken) {
        return;
      }
      state = AsyncError(e, st);
    }
  }

  @override
  void dispose() {
    _dbSub?.cancel();
    _filterSub?.close();
    super.dispose();
  }
}

final transactionListProvider = StateNotifierProvider.autoDispose<
    TransactionListNotifier, AsyncValue<TransactionListState>>(
  (ref) => TransactionListNotifier(ref),
);
