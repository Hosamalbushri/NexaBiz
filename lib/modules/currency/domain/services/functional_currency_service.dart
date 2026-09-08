import 'package:drift/drift.dart';
import 'package:stock_count/core/errors/currency_exception.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import '../entities/currency.dart';
import '../repositories/currency_repository.dart';

/// Service responsible for managing, validating, and configuring a company's
/// functional (accounting base) currency.
///
/// Enforces all CURRENCY-02 invariants:
/// 1. Functional currency is configuration data, never inferred or defaulted.
/// 2. Must exist in currency master data and be active.
/// 3. Modifications after posted accounting activity exists are strictly locked
///    and require controlled migration.
class FunctionalCurrencyService {
  FunctionalCurrencyService({
    required this.settingsRepository,
    required this.currencyRepository,
    this.db,
  });

  final SettingsRepository settingsRepository;
  final CurrencyRepository currencyRepository;
  final AccountingDatabase? db;

  /// Retrieves and validates the company's active functional currency.
  ///
  /// Throws [CurrencyRequiredException] if not configured.
  /// Throws [InvalidFunctionalCurrencyException] if the configured currency is
  /// missing from master data or inactive.
  Future<Currency> getFunctionalCurrency([String? companyId]) async {
    final currency = await currencyRepository.getDefaultCurrency();

    if (currency == null) {
      throw CurrencyRequiredException(
        'Functional currency is not configured in currency master for company "${companyId ?? "default"}".',
      );
    }

    if (!currency.isActive) {
      throw InvalidFunctionalCurrencyException(
        'Configured functional currency "${currency.code}" is inactive and cannot be used.',
      );
    }

    return currency;
  }

  /// Sets or updates the company's functional currency.
  ///
  /// Validates that the new currency exists and is active.
  /// If accounting entries have already been posted for the company,
  /// changing the functional currency is blocked with a [FunctionalCurrencyLockedException].
  Future<Currency> setFunctionalCurrency(
    String currencyCode, [
    String? companyId,
  ]) async {
    final normalized = currencyCode.trim().toUpperCase();
    if (normalized.isEmpty) {
      throw const CurrencyRequiredException(
        'Functional currency code cannot be empty.',
      );
    }

    final targetCurrency = await currencyRepository.getByCode(normalized);
    if (targetCurrency == null) {
      throw InvalidFunctionalCurrencyException(
        'Functional currency "$normalized" does not exist in master data.',
      );
    }

    if (!targetCurrency.isActive) {
      throw InvalidFunctionalCurrencyException(
        'Functional currency "$normalized" is inactive and cannot be selected.',
      );
    }

    final current = await currencyRepository.getDefaultCurrency();
    final currentCode = current?.code.trim().toUpperCase() ?? '';

    if (currentCode.isNotEmpty && currentCode != normalized) {
      final hasPosted = await hasPostedAccountingActivity(companyId);
      if (hasPosted) {
        throw FunctionalCurrencyLockedException(
          'Cannot change functional currency from "$currentCode" to "$normalized" after accounting transactions have been posted. Controlled migration required.',
        );
      }
    }

    await currencyRepository.setDefaultCurrency(normalized);
    await settingsRepository.saveSystemBaseCurrencyLocked(true, companyId);

    return targetCurrency;
  }

  /// Checks whether posted accounting activity exists for the given company.
  Future<bool> hasPostedAccountingActivity([String? companyId]) async {
    final database = db;
    if (database == null) {
      return false;
    }

    final effectiveCompanyId = companyId?.trim();
    if (effectiveCompanyId != null && effectiveCompanyId.isNotEmpty) {
      final query = database.select(database.journalEntries)
        ..where(
          (t) =>
              t.companyId.equals(effectiveCompanyId) &
              t.isPosted.equals(true) &
              t.deletedAt.isNull(),
        );
      final count = await query.get();
      return count.isNotEmpty;
    } else {
      final query = database.select(database.journalEntries)
        ..where(
          (t) => t.isPosted.equals(true) & t.deletedAt.isNull(),
        );
      final count = await query.get();
      return count.isNotEmpty;
    }
  }

  /// Validates application startup currency configuration.
  ///
  /// Fails explicitly if the functional currency is missing or invalid.
  /// Never silently selects a currency.
  Future<Currency> validateStartupCurrencyConfig([String? companyId]) async {
    return getFunctionalCurrency(companyId);
  }
}
