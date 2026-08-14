import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/sale_list_item.dart';
import '../../domain/models/sale_list_filter.dart';
import '../../domain/repositories/sale_repository.dart';
import 'sale_providers.dart';

const kSalesListPageSize = 30;

class SalesListState {
  const SalesListState({
    this.items = const [],
    this.totalCount = 0,
    this.nextPage = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  final List<SaleListItem> items;
  final int totalCount;
  final int nextPage;
  final bool hasMore;
  final bool isLoadingMore;

  SalesListState copyWith({
    List<SaleListItem>? items,
    int? totalCount,
    int? nextPage,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return SalesListState(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      nextPage: nextPage ?? this.nextPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class SalesListNotifier extends StateNotifier<AsyncValue<SalesListState>> {
  SalesListNotifier(this._ref)
      : super(const AsyncLoading()) {
    _filter = _ref.read(saleListFilterProvider);
    _listenFilter();
    _listenDb();
    unawaited(reload());
  }

  final Ref _ref;
  late SaleListFilter _filter;
  StreamSubscription<void>? _dbSub;
  ProviderSubscription<SaleListFilter>? _filterSub;
  var _loadToken = 0;

  SaleRepository get _repo => _ref.read(saleRepositoryProvider);

  void _listenFilter() {
    _filterSub = _ref.listen<SaleListFilter>(saleListFilterProvider, (
      previous,
      next,
    ) {
      _filter = next;
      unawaited(reload());
    });
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
        _filter,
        page: 0,
        pageSize: kSalesListPageSize,
      );
      if (token != _loadToken) {
        return;
      }
      state = AsyncData(
        SalesListState(
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
        _filter,
        page: current.nextPage,
        pageSize: kSalesListPageSize,
      );
      if (token != _loadToken) {
        return;
      }
      final merged = [...current.items, ...page.items];
      state = AsyncData(
        SalesListState(
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

final salesListProvider =
    StateNotifierProvider.autoDispose<SalesListNotifier, AsyncValue<SalesListState>>(
  (ref) => SalesListNotifier(ref),
);
