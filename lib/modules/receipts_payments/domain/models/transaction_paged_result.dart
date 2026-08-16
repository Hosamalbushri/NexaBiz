class TransactionPagedResult<T> {
  const TransactionPagedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;

  bool get hasMore => (page + 1) * pageSize < totalCount;

  bool get hasNext => hasMore;

  int get totalPages => pageSize <= 0
      ? 0
      : ((totalCount + pageSize - 1) / pageSize).floor();
}
