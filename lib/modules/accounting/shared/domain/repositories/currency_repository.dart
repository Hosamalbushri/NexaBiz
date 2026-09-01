import '../entities/currency.dart';

abstract class CurrencyRepository {
  Future<List<Currency>> getAll({bool includeInactive = true});

  Stream<List<Currency>> watchAll({bool includeInactive = true});

  Future<Currency?> getByCode(String code);

  Future<Currency?> getByUuid(String uuid);

  Future<Currency?> getDefaultCurrency();

  Future<Currency> upsert(CurrencyDraft draft);

  Future<void> setDefaultCurrency(String code);

  Future<void> toggleActive(String code, bool isActive);

  Future<void> deleteByCode(String code);

  Future<void> ensureDefaultCurrenciesSeeded({String defaultCode = 'SAR'});
}
