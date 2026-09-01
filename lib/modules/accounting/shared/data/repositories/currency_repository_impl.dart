import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import '../database/accounting_database.dart';
import '../../domain/entities/currency.dart';
import '../../domain/repositories/currency_repository.dart';

class CurrencyRepositoryImpl implements CurrencyRepository {
  CurrencyRepositoryImpl(this._db, {required String Function() readCompanyId})
      : _readCompanyId = readCompanyId;

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

    final rows = await _db.customSelect(
      query.toString(),
      variables: variables,
    ).get();

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
        )
        .watch()
        .map((rows) => rows.map(_mapRow).toList());
  }

  @override
  Future<Currency?> getByCode(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) return null;

    final rows = await _db.customSelect(
      'SELECT * FROM currencies WHERE code = ? AND deleted_at IS NULL AND company_id = ? LIMIT 1',
      variables: [
        Variable.withString(trimmed),
        Variable.withString(_currentCompanyId),
      ],
    ).get();

    if (rows.isEmpty) return null;
    return _mapRow(rows.first);
  }

  @override
  Future<Currency?> getByUuid(String uuid) async {
    final trimmed = uuid.trim();
    if (trimmed.isEmpty) return null;

    final rows = await _db.customSelect(
      'SELECT * FROM currencies WHERE uuid = ? AND deleted_at IS NULL AND company_id = ? LIMIT 1',
      variables: [
        Variable.withString(trimmed),
        Variable.withString(_currentCompanyId),
      ],
    ).get();

    if (rows.isEmpty) return null;
    return _mapRow(rows.first);
  }

  @override
  Future<Currency?> getDefaultCurrency() async {
    final rows = await _db.customSelect(
      'SELECT * FROM currencies WHERE is_default = 1 AND deleted_at IS NULL AND company_id = ? LIMIT 1',
      variables: [Variable.withString(_currentCompanyId)],
    ).get();

    if (rows.isEmpty) return null;
    return _mapRow(rows.first);
  }

  @override
  Future<Currency> upsert(CurrencyDraft draft) async {
    final code = draft.code.trim().toUpperCase();
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final uuid = draft.uuid ?? generateUuidV4();

    return await _db.transaction(() async {
      if (draft.isDefault) {
        await _db.customUpdate(
          'UPDATE currencies SET is_default = 0, updated_at = ? WHERE company_id = ?',
          variables: [
            Variable.withInt(now),
            Variable.withString(_currentCompanyId),
          ],
        );
      }

      final existing = await getByCode(code);
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

    await _db.customUpdate(
      'UPDATE currencies SET deleted_at = ?, updated_at = ? WHERE code = ? AND company_id = ?',
      variables: [
        Variable.withInt(now),
        Variable.withInt(now),
        Variable.withString(trimmed),
        Variable.withString(_currentCompanyId),
      ],
    );
  }

  @override
  Future<void> ensureDefaultCurrenciesSeeded({String defaultCode = 'SAR'}) async {
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
