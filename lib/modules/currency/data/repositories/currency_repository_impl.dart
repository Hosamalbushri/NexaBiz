import 'package:drift/drift.dart';
import 'package:stock_count/shared/contracts/errors/currency_exception.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import '../../domain/entities/currency.dart';
import '../../domain/repositories/currency_repository.dart';

class CurrencyRepositoryImpl implements CurrencyRepository {
  CurrencyRepositoryImpl(this._db, {required this._readCompanyId});

  final AccountingDatabase _db;
  final String Function() _readCompanyId;

  String get _currentCompanyId => _readCompanyId().trim();

  @override
  Future<List<Currency>> getAll({bool includeInactive = true}) async {
    final query = StringBuffer(
      'SELECT * FROM currencies WHERE deleted_at IS NULL AND company_id = ? ',
    );
    final variables = <Variable>[Variable.withString(_currentCompanyId)];

    if (!includeInactive) {
      query.write('AND is_active = 1 ');
    }
    query.write('ORDER BY is_default DESC, code ASC');

    final rows = await _db
        .customSelect(
          query.toString(),
          variables: variables,
        )
        .get();

    return rows.map(_mapRow).toList();
  }

  @override
  Stream<List<Currency>> watchAll({bool includeInactive = true}) {
    final query = StringBuffer(
      'SELECT * FROM currencies WHERE deleted_at IS NULL AND company_id = ? ',
    );
    final variables = <Variable>[Variable.withString(_currentCompanyId)];

    if (!includeInactive) {
      query.write('AND is_active = 1 ');
    }
    query.write('ORDER BY is_default DESC, code ASC');

    return _db
        .customSelect(
          query.toString(),
          variables: variables,
          readsFrom: {_db.currencyRates},
        )
        .watch()
        .map((rows) => rows.map(_mapRow).toList());
  }

  @override
  Future<Currency?> getByCode(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) return null;

    final rows = await _db
        .customSelect(
          'SELECT * FROM currencies WHERE code = ? AND deleted_at IS NULL AND company_id = ? LIMIT 1',
          variables: [
            Variable.withString(trimmed),
            Variable.withString(_currentCompanyId),
          ],
        )
        .get();

    if (rows.isEmpty) return null;
    return _mapRow(rows.first);
  }

  @override
  Future<Currency?> getByUuid(String uuid) async {
    final trimmed = uuid.trim();
    if (trimmed.isEmpty) return null;

    final rows = await _db
        .customSelect(
          'SELECT * FROM currencies WHERE uuid = ? AND deleted_at IS NULL AND company_id = ? LIMIT 1',
          variables: [
            Variable.withString(trimmed),
            Variable.withString(_currentCompanyId),
          ],
        )
        .get();

    if (rows.isEmpty) return null;
    return _mapRow(rows.first);
  }

  @override
  Future<Currency?> getDefaultCurrency() async {
    final rows = await _db
        .customSelect(
          'SELECT * FROM currencies WHERE is_default = 1 AND deleted_at IS NULL AND company_id = ? LIMIT 1',
          variables: [Variable.withString(_currentCompanyId)],
        )
        .get();

    if (rows.isEmpty) return null;
    return _mapRow(rows.first);
  }

  @override
  Future<Currency> upsert(CurrencyDraft draft) async {
    draft.validate();
    final code = draft.code.trim().toUpperCase();
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final uuid = draft.uuid ?? generateUuidV4();

    return await _db.transaction(() async {
      final existing = await getByCode(code);
      final isNew = draft.uuid == null || draft.uuid!.isEmpty;
      if (existing != null) {
        if (isNew || existing.uuid != draft.uuid) {
          throw CurrencyValidationException('رمز العملة $code مستخدم بالفعل.');
        }
      }

      if (draft.isDefault) {
        await _db.customUpdate(
          'UPDATE currencies SET is_default = 0, updated_at = ? WHERE company_id = ?',
          variables: [
            Variable.withInt(now),
            Variable.withString(_currentCompanyId),
          ],
        );
      }

      if (existing != null) {
        await _db.customUpdate(
          '''
          UPDATE currencies SET
            name_ar = ?,
            name_en = ?,
            symbol = ?,
            decimal_digits = ?,
            is_default = ?,
            is_active = ?,
            updated_at = ?
          WHERE code = ? AND company_id = ?
          ''',
          variables: [
            Variable.withString(draft.nameAr.trim()),
            Variable.withString(draft.nameEn.trim()),
            Variable.withString(draft.symbol.trim()),
            Variable.withInt(draft.decimalDigits),
            Variable.withBool(draft.isDefault),
            Variable.withBool(draft.isActive),
            Variable.withInt(now),
            Variable.withString(code),
            Variable.withString(_currentCompanyId),
          ],
        );
      } else {
        await _db.customInsert(
          '''
          INSERT INTO currencies (
            uuid, code, name_ar, name_en, symbol, decimal_digits,
            is_default, is_active, created_at, updated_at, company_id
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          variables: [
            Variable.withString(uuid),
            Variable.withString(code),
            Variable.withString(draft.nameAr.trim()),
            Variable.withString(draft.nameEn.trim()),
            Variable.withString(draft.symbol.trim()),
            Variable.withInt(draft.decimalDigits),
            Variable.withBool(draft.isDefault),
            Variable.withBool(draft.isActive),
            Variable.withInt(now),
            Variable.withInt(now),
            Variable.withString(_currentCompanyId),
          ],
        );
      }

      final updated = await getByCode(code);
      return updated!;
    });
  }

  @override
  Future<void> setDefaultCurrency(String code) async {
    final trimmed = code.trim().toUpperCase();
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    await _db.transaction(() async {
      await _db.customUpdate(
        'UPDATE currencies SET is_default = 0, updated_at = ? WHERE company_id = ?',
        variables: [
          Variable.withInt(now),
          Variable.withString(_currentCompanyId),
        ],
      );

      await _db.customUpdate(
        'UPDATE currencies SET is_default = 1, is_active = 1, updated_at = ? WHERE code = ? AND company_id = ?',
        variables: [
          Variable.withInt(now),
          Variable.withString(trimmed),
          Variable.withString(_currentCompanyId),
        ],
      );
    });
  }

  @override
  Future<void> toggleActive(String code, bool isActive) async {
    final trimmed = code.trim().toUpperCase();
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    if (!isActive) {
      final inUse = await hasTransactions(trimmed);
      if (inUse) {
        throw CurrencyValidationException(
          'لا يمكن تعطيل العملة ($trimmed) لكونها مستخدمة في حركات مسجلة بالمنشأة.',
        );
      }
    }

    await _db.customUpdate(
      'UPDATE currencies SET is_active = ?, updated_at = ? WHERE code = ? AND company_id = ?',
      variables: [
        Variable.withBool(isActive),
        Variable.withInt(now),
        Variable.withString(trimmed),
        Variable.withString(_currentCompanyId),
      ],
    );
  }

  @override
  Future<void> deleteByCode(String code) async {
    final trimmed = code.trim().toUpperCase();
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    // 1. Check if currency has transactions
    final inUse = await hasTransactions(trimmed);
    if (inUse) {
      throw CurrencyValidationException(
        'لا يمكن حذف العملة ($trimmed) لكونها مستخدمة في حركات مسجلة بالمنشأة.',
      );
    }

    // 2. Fetch target currency details
    final rows = await _db.customSelect(
      'SELECT is_default, is_active FROM currencies WHERE UPPER(code) = ? AND company_id = ? AND deleted_at IS NULL',
      variables: [
        Variable.withString(trimmed),
        Variable.withString(_currentCompanyId),
      ],
    ).get();

    if (rows.isNotEmpty) {
      final isDefault = (rows.first.read<int>('is_default')) == 1;
      final isActive = (rows.first.read<int>('is_active')) == 1;

      // Rule 1: Cannot delete System Base Currency
      if (isDefault) {
        throw CurrencyValidationException(
          'لا يمكن حذف العملة ($trimmed) لكونها العملة الرئيسية للنظام.',
        );
      }

      // Rule 2: Cannot delete Active currency (Must deactivate first)
      if (isActive) {
        throw CurrencyValidationException(
          'لا يمكن حذف العملة ($trimmed) وهي نشطة. يرجى تعطيلها أولاً.',
        );
      }
    }

    // Rule 3: Cannot delete Inventory Valuation Currency
    try {
      final settingsRow = await _db.customSelect(
        "SELECT value FROM settings WHERE key = 'company_inventory_valuation_currency' AND company_id = ?",
        variables: [Variable.withString(_currentCompanyId)],
      ).get();
      if (settingsRow.isNotEmpty) {
        final valCurrency =
            settingsRow.first.read<String>('value').trim().toUpperCase();
        if (valCurrency == trimmed) {
          throw CurrencyValidationException(
            'لا يمكن حذف العملة ($trimmed) لكونها عملة تقييم المخزون المعتمدة بالمنشأة.',
          );
        }
      }
    } catch (e) {
      if (e is CurrencyValidationException) rethrow;
    }

    // Rule 4: Check if currency has exchange rate history/records
    try {
      final rateRows = await _db.customSelect(
        'SELECT COUNT(*) as cnt FROM currency_rates WHERE UPPER(currency_code) = ? AND company_id = ?',
        variables: [
          Variable.withString(trimmed),
          Variable.withString(_currentCompanyId),
        ],
      ).get();
      if (rateRows.isNotEmpty && (rateRows.first.read<int>('cnt')) > 0) {
        throw CurrencyValidationException(
          'لا يمكن حذف العملة ($trimmed) لوجود أسعار صرف مسجلة لها.',
        );
      }
    } catch (e) {
      if (e is CurrencyValidationException) rethrow;
    }

    // Rule 5: Check if currency is linked to any account in chart of accounts
    try {
      final accRows = await _db.customSelect(
        'SELECT COUNT(*) as cnt FROM accounts WHERE UPPER(currency_code) = ? AND company_id = ? AND deleted_at IS NULL',
        variables: [
          Variable.withString(trimmed),
          Variable.withString(_currentCompanyId),
        ],
      ).get();
      if (accRows.isNotEmpty && (accRows.first.read<int>('cnt')) > 0) {
        throw CurrencyValidationException(
          'لا يمكن حذف العملة ($trimmed) لارتباطها بحسابات مالية في دليل الحسابات.',
        );
      }
    } catch (e) {
      if (e is CurrencyValidationException) rethrow;
    }

    await _db.customUpdate(
      'UPDATE currencies SET deleted_at = ?, updated_at = ? WHERE UPPER(code) = ? AND company_id = ?',
      variables: [
        Variable.withInt(now),
        Variable.withInt(now),
        Variable.withString(trimmed),
        Variable.withString(_currentCompanyId),
      ],
    );
  }

  @override
  Future<bool> hasTransactions(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) return false;

    // Check accounting journal lines
    try {
      final journalRows = await _db.customSelect(
        '''
        SELECT COUNT(*) as cnt FROM journal_lines jl
        INNER JOIN journal_entries je ON jl.entry_uuid = je.uuid
        WHERE UPPER(jl.currency_code) = ? AND je.company_id = ? AND je.deleted_at IS NULL
        ''',
        variables: [
          Variable.withString(trimmed),
          Variable.withString(_currentCompanyId),
        ],
      ).get();
      if (journalRows.isNotEmpty && (journalRows.first.read<int>('cnt')) > 0) {
        return true;
      }
    } catch (_) {}

    // Check stock receipts
    try {
      final receiptRows = await _db.customSelect(
        '''
        SELECT COUNT(*) as cnt FROM stock_receipts
        WHERE UPPER(currency_code) = ? AND company_id = ? AND deleted_at IS NULL
        ''',
        variables: [
          Variable.withString(trimmed),
          Variable.withString(_currentCompanyId),
        ],
      ).get();
      if (receiptRows.isNotEmpty && (receiptRows.first.read<int>('cnt')) > 0) {
        return true;
      }
    } catch (_) {}

    // Check stock issues
    try {
      final issueRows = await _db.customSelect(
        '''
        SELECT COUNT(*) as cnt FROM stock_issues
        WHERE UPPER(currency_code) = ? AND company_id = ? AND deleted_at IS NULL
        ''',
        variables: [
          Variable.withString(trimmed),
          Variable.withString(_currentCompanyId),
        ],
      ).get();
      if (issueRows.isNotEmpty && (issueRows.first.read<int>('cnt')) > 0) {
        return true;
      }
    } catch (_) {}

    // Check cost layers
    try {
      final layerRows = await _db.customSelect(
        '''
        SELECT COUNT(*) as cnt FROM inventory_cost_layers
        WHERE UPPER(currency_code) = ? AND company_id = ? AND deleted_at IS NULL
        ''',
        variables: [
          Variable.withString(trimmed),
          Variable.withString(_currentCompanyId),
        ],
      ).get();
      if (layerRows.isNotEmpty && (layerRows.first.read<int>('cnt')) > 0) {
        return true;
      }
    } catch (_) {}

    return false;
  }

  @override
  Future<void> ensureDefaultCurrenciesSeeded({String defaultCode = ''}) async {
    final existing = await getAll(includeInactive: true);
    if (existing.isNotEmpty) return;

    final upperDefault = defaultCode.trim().toUpperCase();

    final defaults = [
      CurrencyDraft(
        code: 'SAR',
        nameAr: 'ريال سعودي',
        nameEn: 'Saudi Riyal',
        symbol: 'ر.س',
        decimalDigits: 2,
        isDefault: upperDefault == 'SAR',
        isActive: true,
      ),
      CurrencyDraft(
        code: 'YER',
        nameAr: 'ريال يمني',
        nameEn: 'Yemeni Rial',
        symbol: 'ر.ي',
        decimalDigits: 2,
        isDefault: upperDefault == 'YER',
        isActive: true,
      ),
      CurrencyDraft(
        code: 'USD',
        nameAr: 'دولار أمريكي',
        nameEn: 'US Dollar',
        symbol: '\$',
        decimalDigits: 2,
        isDefault: upperDefault == 'USD',
        isActive: true,
      ),
      CurrencyDraft(
        code: 'EUR',
        nameAr: 'يورو',
        nameEn: 'Euro',
        symbol: '€',
        decimalDigits: 2,
        isDefault: upperDefault == 'EUR',
        isActive: true,
      ),
      CurrencyDraft(
        code: 'AED',
        nameAr: 'درهم إماراتي',
        nameEn: 'UAE Dirham',
        symbol: 'د.إ',
        decimalDigits: 2,
        isDefault: upperDefault == 'AED',
        isActive: true,
      ),
      CurrencyDraft(
        code: 'OMR',
        nameAr: 'ريال عماني',
        nameEn: 'Omani Rial',
        symbol: 'ر.ع',
        decimalDigits: 3,
        isDefault: upperDefault == 'OMR',
        isActive: true,
      ),
      CurrencyDraft(
        code: 'KWD',
        nameAr: 'دينار كويتي',
        nameEn: 'Kuwaiti Dinar',
        symbol: 'د.ك',
        decimalDigits: 3,
        isDefault: upperDefault == 'KWD',
        isActive: true,
      ),
      CurrencyDraft(
        code: 'QAR',
        nameAr: 'ريال قطري',
        nameEn: 'Qatari Riyal',
        symbol: 'ر.ق',
        decimalDigits: 2,
        isDefault: upperDefault == 'QAR',
        isActive: true,
      ),
      CurrencyDraft(
        code: 'BHD',
        nameAr: 'دينار بحريني',
        nameEn: 'Bahraini Dinar',
        symbol: 'د.ب',
        decimalDigits: 3,
        isDefault: upperDefault == 'BHD',
        isActive: true,
      ),
      CurrencyDraft(
        code: 'EGP',
        nameAr: 'جنيه مصري',
        nameEn: 'Egyptian Pound',
        symbol: 'ج.م',
        decimalDigits: 2,
        isDefault: upperDefault == 'EGP',
        isActive: true,
      ),
      CurrencyDraft(
        code: 'JOD',
        nameAr: 'دينار أردني',
        nameEn: 'Jordanian Dinar',
        symbol: 'د.أ',
        decimalDigits: 3,
        isDefault: upperDefault == 'JOD',
        isActive: true,
      ),
      CurrencyDraft(
        code: 'GBP',
        nameAr: 'جنيه إسترليني',
        nameEn: 'British Pound',
        symbol: '£',
        decimalDigits: 2,
        isDefault: upperDefault == 'GBP',
        isActive: true,
      ),
      CurrencyDraft(
        code: 'TRY',
        nameAr: 'ليرة تركية',
        nameEn: 'Turkish Lira',
        symbol: '₺',
        decimalDigits: 2,
        isDefault: upperDefault == 'TRY',
        isActive: true,
      ),
      CurrencyDraft(
        code: 'CNY',
        nameAr: 'يوان صيني',
        nameEn: 'Chinese Yuan',
        symbol: '¥',
        decimalDigits: 2,
        isDefault: upperDefault == 'CNY',
        isActive: true,
      ),
    ];

    for (final draft in defaults) {
      await upsert(draft);
    }
  }

  Currency _mapRow(QueryRow row) {
    return Currency(
      id: row.read<int>('id'),
      uuid: row.read<String>('uuid'),
      code: row.read<String>('code'),
      nameAr: row.read<String>('name_ar'),
      nameEn: row.read<String>('name_en'),
      symbol: row.read<String>('symbol'),
      decimalDigits: row.read<int>('decimal_digits'),
      isDefault: row.read<bool>('is_default'),
      isActive: row.read<bool>('is_active'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('created_at'),
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('updated_at'),
        isUtc: true,
      ),
      deletedAt: row.read<int?>('deleted_at') != null
          ? DateTime.fromMillisecondsSinceEpoch(
              row.read<int>('deleted_at'),
              isUtc: true,
            )
          : null,
      companyId: row.read<String?>('company_id'),
    );
  }
}
