/// A page of results from a paginated query.
class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;

  int get totalPages {
    if (totalCount <= 0 || pageSize <= 0) {
      return 0;
    }
    return (totalCount / pageSize).ceil();
  }

  bool get hasNext => page + 1 < totalPages;

  bool get hasPrevious => page > 0;
}
