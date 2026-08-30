import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/modules/inventory/permissions/inventory_permission_package.dart';
import '../entities/inventory_item.dart';
import '../repositories/inventory_repository.dart';

class GetInventoryItems {
  const GetInventoryItems(this._repository);

  final InventoryRepository _repository;

  Future<List<InventoryItem>> call() => _repository.getAll();
}

class WatchInventoryItems {
  const WatchInventoryItems(this._repository);

  final InventoryRepository _repository;

  Stream<List<InventoryItem>> call() => _repository.watchAll();
}

class SearchInventoryItems {
  const SearchInventoryItems(this._repository);

  final InventoryRepository _repository;

  Future<List<InventoryItem>> call(String query) => _repository.search(query);
}

class SaveInventoryCount {
  const SaveInventoryCount(
    this._repository, {
    required PermissionGuard permissionGuard,
  }) : _guard = permissionGuard;

  final InventoryRepository _repository;
  final PermissionGuard _guard;

  Future<void> call(InventoryItem item) async {
    _guard.requireAny(InventoryPermissions.stockAdjust);
    return _repository.save(item);
  }
}

class ReplaceInventoryItems {
  const ReplaceInventoryItems(
    this._repository, {
    required PermissionGuard permissionGuard,
  }) : _guard = permissionGuard;

  final InventoryRepository _repository;
  final PermissionGuard _guard;

  Future<void> call(
    List<InventoryItem> items, {
    void Function(int processed, int total)? onProgress,
  }) async {
    _guard.requireAny(InventoryPermissions.stockImport);
    return _repository.replaceAll(items, onProgress: onProgress);
  }
}

class ClearInventoryItems {
  const ClearInventoryItems(
    this._repository, {
    required PermissionGuard permissionGuard,
  }) : _guard = permissionGuard;

  final InventoryRepository _repository;
  final PermissionGuard _guard;

  Future<void> call() async {
    _guard.requireAny(InventoryPermissions.stockClear);
    return _repository.clear();
  }
}
