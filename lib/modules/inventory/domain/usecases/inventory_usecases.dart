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
  const SaveInventoryCount(this._repository);

  final InventoryRepository _repository;

  Future<void> call(InventoryItem item) => _repository.save(item);
}

class ReplaceInventoryItems {
  const ReplaceInventoryItems(this._repository);

  final InventoryRepository _repository;

  Future<void> call(List<InventoryItem> items) => _repository.replaceAll(items);
}

class ClearInventoryItems {
  const ClearInventoryItems(this._repository);

  final InventoryRepository _repository;

  Future<void> call() => _repository.clear();
}
