/// Route paths owned by the Inventory module.
class InventoryRoutes {
  const InventoryRoutes._();

  static const String root = '/inventory';

  /// Inventory count entry point — product search.
  static const String count = '/inventory/count';

  /// Selected product count / details screen.
  static const String countDetails = '/inventory/count/details';

  /// Alias kept for older call sites; same as [count].
  static const String search = count;

  static const String import = '/inventory/import';
  static const String reports = '/inventory/reports';
}
