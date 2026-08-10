/// Display layout for the products catalog.
enum ProductsViewMode {
  list,
  grid;

  static ProductsViewMode fromStorage(String? value) {
    switch (value) {
      case 'grid':
        return ProductsViewMode.grid;
      case 'list':
      default:
        return ProductsViewMode.list;
    }
  }

  String get storageValue => name;
}
