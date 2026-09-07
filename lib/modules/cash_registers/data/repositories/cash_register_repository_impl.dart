import 'package:drift/drift.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import '../../domain/entities/cash_register.dart';
import '../../domain/repositories/cash_register_repository.dart';

/// Durable Drift-backed repository implementation for Cash Registers.
class CashRegisterRepositoryImpl implements CashRegisterRepository {
  static const entityType = 'cash_register';

  CashRegisterRepositoryImpl({
    required this.accountRepository,
    AccountingDatabase? db,
    this.settingsBox,
    List<CashRegister>? initialRegisters,
  }) : _db = db ?? AccountingDatabase.memory() {
    if (initialRegisters != null && initialRegisters.isNotEmpty) {
      for (final reg in initialRegisters) {
        _seedRegisterIfMissing(reg);
      }
    }
  }

  final AccountRepository accountRepository;
  final AccountingDatabase _db;
  Box<dynamic>? settingsBox;
  final Map<String, String> _inMemoryDefaults = {};

  Future<void> _seedRegisterIfMissing(CashRegister reg) async {
    final existing = await getCashRegisterById(reg.id);
    if (existing == null) {
      await createCashRegister(reg);
    }
  }

  Future<Box<dynamic>?> _getSettingsBox() async {
    if (settingsBox != null && settingsBox!.isOpen) return settingsBox;
    try {
      if (Hive.isBoxOpen(HiveBoxes.settings)) {
        settingsBox = Hive.box<dynamic>(HiveBoxes.settings);
        return settingsBox;
      }
    } catch (_) {}
    return null;
  }

  String _defaultKey(String companyId) => 'default_cash_register_$companyId';

  String _normalizeUuid(String rawId) {
    final trimmed = rawId.trim();
    if (trimmed.length == 36) return trimmed;
    if (trimmed.length > 36) return trimmed.substring(0, 36);
    return trimmed.padRight(36, '_');
  }

  String _denormalizeUuid(String dbUuid) {
    return dbUuid.replaceAll(RegExp(r'_+$'), '');
  }

  CashRegister _rowToEntity(CashRegisterRow row) {
    return CashRegister(
      id: _denormalizeUuid(row.uuid),
      companyId: row.companyId,
      name: row.name,
      code: row.code,
      isActive: row.isActive,
      accountingAccountId: row.accountingAccountId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAt,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAt,
        isUtc: true,
      ),
    );
  }

  CashRegistersCompanion _entityToCompanion(CashRegister entity) {
    final isLinked =
        entity.accountingAccountId != null &&
        entity.accountingAccountId!.trim().isNotEmpty;
    return CashRegistersCompanion(
      uuid: Value(_normalizeUuid(entity.id)),
      companyId: Value(entity.companyId),
      name: Value(entity.name),
      code: Value(entity.code),
      description: const Value.absent(),
      accountingAccountId: Value(entity.accountingAccountId),
      accountingLinkStatus: Value(
        isLinked ? 'ACCOUNTING_READY' : 'ACCOUNTING_NOT_LINKED',
      ),
      isActive: Value(entity.isActive),
      createdAt: Value(entity.createdAt.millisecondsSinceEpoch),
      updatedAt: Value(entity.updatedAt.millisecondsSinceEpoch),
      syncStatus: const Value('synced'),
      version: const Value(1),
      deletedAt: const Value(null),
    );
  }

  @override
  Future<String?> getDefaultCashRegisterId(String companyId) async {
    final box = await _getSettingsBox();
    if (box != null) {
      final raw = box.get(_defaultKey(companyId));
      if (raw is String && raw.isNotEmpty) {
        return raw;
      }
    }
    return _inMemoryDefaults[companyId];
  }

  @override
  Future<void> setDefaultCashRegisterId({
    required String companyId,
    required String? registerId,
  }) async {
    if (registerId == null || registerId.isEmpty) {
      final box = await _getSettingsBox();
      if (box != null) {
        await box.delete(_defaultKey(companyId));
      }
      _inMemoryDefaults.remove(companyId);

      final check = await getDefaultCashRegisterId(companyId);
      if (check != null) {
        throw const CashRegisterException(
          'Failed to clear default cash register',
        );
      }
      return;
    }

    final readyRegisters = await getAccountingReadyCashRegisters(companyId);
    final isReady = readyRegisters.any((r) => r.id == registerId);

    if (!isReady) {
      final reg = await getCashRegisterById(registerId);
      if (reg == null) {
        throw const CashRegisterException(
          'Cash register not found',
          code: 'REGISTER_NOT_FOUND',
        );
      }
      if (reg.companyId != companyId) {
        throw const CashRegisterException(
          'Cross-company default cash register selection rejected',
          code: 'CROSS_COMPANY_DEFAULT',
        );
      }
      if (!reg.isLinked) {
        throw const CashRegisterException(
          'Unlinked cash register cannot be set as default',
          code: 'UNLINKED_REGISTER_CANNOT_BE_DEFAULT',
        );
      }
      throw const CashRegisterException(
        'Invalid cash register cannot be set as default',
        code: 'INVALID_REGISTER_CANNOT_BE_DEFAULT',
      );
    }

    final box = await _getSettingsBox();
    if (box != null) {
      await box.put(_defaultKey(companyId), registerId);
    }
    _inMemoryDefaults[companyId] = registerId;

    final readBack = await getDefaultCashRegisterId(companyId);
    if (readBack != registerId) {
      throw CashRegisterException(
        'Default cash register persistence verification failed. Expected: $registerId, Got: $readBack',
      );
    }
  }

  @override
  Future<List<CashRegister>> getCashRegisters(String companyId) async {
    final query = _db.select(_db.cashRegisters)
      ..where((tbl) => tbl.deletedAt.isNull());
    final trimmedCompany = companyId.trim();
    if (trimmedCompany.isNotEmpty) {
      query.where((tbl) => tbl.companyId.equals(trimmedCompany));
    }
    final rows = await query.get();
    return rows.map(_rowToEntity).toList(growable: false);
  }

  @override
  Future<CashRegister?> getCashRegisterById(
    String registerId, {
    String? companyId,
  }) async {
    final normalizedId = _normalizeUuid(registerId);
    final query = _db.select(_db.cashRegisters)
      ..where((tbl) => tbl.uuid.equals(normalizedId) & tbl.deletedAt.isNull());
    if (companyId != null && companyId.trim().isNotEmpty) {
      query.where((tbl) => tbl.companyId.equals(companyId.trim()));
    }
    final row = await query.getSingleOrNull();
    return row != null ? _rowToEntity(row) : null;
  }

  @override
  Future<List<CashRegister>> getAccountingReadyCashRegisters(
    String companyId,
  ) async {
    final registers = await getCashRegisters(companyId);
    final readyList = <CashRegister>[];

    for (final reg in registers) {
      if (!reg.isActive || !reg.isLinked) {
        continue;
      }
      final accountId = reg.accountingAccountId!;
      final account =
          await accountRepository.getByUuid(accountId) ??
          await accountRepository.getByAccountCode(accountId);

      final status = reg.evaluateStatus(
        account,
        targetCompanyId: companyId.isNotEmpty ? companyId : null,
      );
      if (status == CashRegisterAccountingStatus.ready) {
        readyList.add(reg);
      }
    }

    readyList.sort((a, b) => a.name.compareTo(b.name));
    return readyList;
  }

  @override
  Future<CashRegister> createCashRegister(CashRegister register) async {
    if (register.companyId.trim().isEmpty) {
      throw const CashRegisterException(
        'Company ID cannot be empty',
        code: 'INVALID_COMPANY',
      );
    }

    final existing = await getCashRegisterById(register.id);
    if (existing != null) {
      throw CashRegisterException(
        'Cash register with ID ${register.id} already exists',
      );
    }

    CashRegister created = register;
    if (created.isLinked) {
      created = await _validateAndApplyLink(created);
    }

    await _db.into(_db.cashRegisters).insert(_entityToCompanion(created));

    final readBack = await getCashRegisterById(created.id);
    if (readBack == null) {
      throw CashRegisterException(
        'Database persistence verification failed: Cash register ${created.id} was not retained in database.',
      );
    }
    return readBack;
  }

  @override
  Future<CashRegister> updateCashRegister(CashRegister register) async {
    if (register.companyId.trim().isEmpty) {
      throw const CashRegisterException(
        'Company ID cannot be empty',
        code: 'INVALID_COMPANY',
      );
    }

    final existing = await getCashRegisterById(register.id);
    if (existing == null) {
      throw CashRegisterException('Cash register not found: ${register.id}');
    }

    if (existing.companyId != register.companyId) {
      throw CashRegisterException(
        'Cross-company update rejected: Register belongs to ${existing.companyId}, update payload company is ${register.companyId}',
        code: 'CROSS_COMPANY_UPDATE',
      );
    }

    CashRegister updated = register;
    if (updated.isLinked &&
        updated.accountingAccountId != existing.accountingAccountId) {
      updated = await _validateAndApplyLink(updated);
    }

    final normalizedId = _normalizeUuid(register.id);
    final rowsAffected =
        await (_db.update(_db.cashRegisters)
              ..where((tbl) => tbl.uuid.equals(normalizedId)))
            .write(_entityToCompanion(updated));

    if (rowsAffected == 0) {
      throw CashRegisterException(
        'Failed to update cash register ${register.id} in database.',
      );
    }

    final readBack = await getCashRegisterById(register.id);
    if (readBack == null) {
      throw CashRegisterException(
        'Database persistence verification failed: Cash register ${register.id} lost after update.',
      );
    }
    return readBack;
  }

  @override
  Future<CashRegister> linkAccountingAccount({
    required String registerId,
    required String accountId,
    required String companyId,
  }) async {
    final register = await getCashRegisterById(registerId);
    if (register == null) {
      throw CashRegisterException('Cash register not found: $registerId');
    }
    if (register.companyId != companyId) {
      throw CashRegisterException(
        'Cross-company cash register linking rejected for company: $companyId',
      );
    }

    final account =
        await accountRepository.getByUuid(accountId) ??
        await accountRepository.getByAccountCode(accountId);

    if (account == null) {
      throw CashRegisterException(
        'Account not found in Chart of Accounts: $accountId',
      );
    }

    if (account.companyId != null &&
        account.companyId!.isNotEmpty &&
        account.companyId != companyId) {
      throw CashRegisterException(
        'Cross-company account assignment rejected. Account belongs to company ${account.companyId}',
        code: 'CROSS_COMPANY_ACCOUNT',
      );
    }

    if (!account.isActive || account.isDeleted) {
      throw CashRegisterException(
        'Linked account is inactive or deleted: ${account.name}',
        code: 'ACCOUNT_INACTIVE',
      );
    }

    if (!account.canPost) {
      throw CashRegisterException(
        'Selected account is a group account and cannot receive journal postings: ${account.name}',
        code: 'ACCOUNT_CANNOT_POST',
      );
    }

    if (account.accountType != AccountType.asset) {
      throw CashRegisterException(
        'This account cannot be linked to a cash register because its account type is not compatible with cash.',
        code: 'ACCOUNT_TYPE_MISMATCH',
      );
    }

    final now = DateTime.now().toUtc();
    final companion = CashRegistersCompanion(
      accountingAccountId: Value(account.uuid),
      accountingLinkStatus: const Value('ACCOUNTING_READY'),
      updatedAt: Value(now.millisecondsSinceEpoch),
    );

    final normalizedId = _normalizeUuid(registerId);
    await (_db.update(
      _db.cashRegisters,
    )..where((tbl) => tbl.uuid.equals(normalizedId))).write(companion);

    final readBack = await getCashRegisterById(registerId);
    if (readBack == null ||
        !readBack.isLinked ||
        readBack.accountingAccountId != account.uuid) {
      throw CashRegisterException(
        'Database link read-back verification failed for register $registerId and account ${account.uuid}',
      );
    }
    return readBack;
  }

  @override
  Future<CashRegister> unlinkAccountingAccount({
    required String registerId,
    required String companyId,
  }) async {
    final register = await getCashRegisterById(registerId);
    if (register == null) {
      throw CashRegisterException('Cash register not found: $registerId');
    }
    if (register.companyId != companyId) {
      throw CashRegisterException(
        'Cross-company operation rejected for company: $companyId',
      );
    }

    final boundAccountId = register.accountingAccountId;
    if (boundAccountId != null && boundAccountId.isNotEmpty) {
      final account =
          await accountRepository.getByUuid(boundAccountId) ??
          await accountRepository.getByAccountCode(boundAccountId);
      final targetUuids = <String>{
        boundAccountId,
        if (account != null) account.uuid,
        if (account != null) account.accountCode,
      };

      for (final uuid in targetUuids) {
        final hasMovements =
            await (_db.select(_db.journalLines)
                  ..where((tbl) => tbl.accountUuid.equals(uuid))
                  ..limit(1))
                .get()
                .then((rows) => rows.isNotEmpty);

        if (hasMovements) {
          throw CashRegisterException(
            'Cannot unlink accounting account: cash register "$registerId" has recorded transaction movements.',
            code: 'REGISTER_HAS_MOVEMENTS',
          );
        }
      }
    }

    final now = DateTime.now().toUtc();
    final companion = CashRegistersCompanion(
      accountingAccountId: const Value(null),
      accountingLinkStatus: const Value('ACCOUNTING_NOT_LINKED'),
      updatedAt: Value(now.millisecondsSinceEpoch),
    );

    final normalizedId = _normalizeUuid(registerId);
    await (_db.update(
      _db.cashRegisters,
    )..where((tbl) => tbl.uuid.equals(normalizedId))).write(companion);

    final readBack = await getCashRegisterById(registerId);
    if (readBack == null ||
        readBack.isLinked ||
        readBack.accountingAccountId != null) {
      throw CashRegisterException(
        'Database unlink read-back verification failed for register $registerId',
      );
    }
    return readBack;
  }

  Future<CashRegister> _validateAndApplyLink(CashRegister register) async {
    final accountId = register.accountingAccountId!;
    final account =
        await accountRepository.getByUuid(accountId) ??
        await accountRepository.getByAccountCode(accountId);
    if (account == null) {
      throw CashRegisterException(
        'Account not found in Chart of Accounts: $accountId',
      );
    }
    if (account.companyId != null &&
        account.companyId!.isNotEmpty &&
        account.companyId != register.companyId) {
      throw CashRegisterException(
        'Cross-company account assignment rejected.',
        code: 'CROSS_COMPANY_ACCOUNT',
      );
    }
    if (!account.isActive || account.isDeleted) {
      throw CashRegisterException(
        'Linked account is inactive or deleted.',
        code: 'ACCOUNT_INACTIVE',
      );
    }
    if (!account.canPost) {
      throw CashRegisterException(
        'Selected account cannot receive postings.',
        code: 'ACCOUNT_CANNOT_POST',
      );
    }
    if (account.accountType != AccountType.asset) {
      throw CashRegisterException(
        'This account cannot be linked to a cash register because its account type is not compatible with cash.',
        code: 'ACCOUNT_TYPE_MISMATCH',
      );
    }
    return register.copyWith(accountingAccountId: account.uuid);
  }

  @override
  Future<void> deleteCashRegister(String registerId) async {
    final normalizedId = _normalizeUuid(registerId);
    await (_db.update(
      _db.cashRegisters,
    )..where((tbl) => tbl.uuid.equals(normalizedId))).write(
      CashRegistersCompanion(
        deletedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> markSynced({
    required String uuid,
    required int remoteVersion,
    DateTime? syncedAt,
  }) async {
    final normalized = _normalizeUuid(uuid);
    await (_db.update(
      _db.cashRegisters,
    )..where((t) => t.uuid.equals(normalized))).write(
      CashRegistersCompanion(
        syncStatus: const Value('synced'),
        version: Value(remoteVersion),
        updatedAt: Value(
          (syncedAt ?? DateTime.now().toUtc()).millisecondsSinceEpoch,
        ),
      ),
    );
  }

  Future<void> markConflict(String uuid) async {
    final normalized = _normalizeUuid(uuid);
    await (_db.update(_db.cashRegisters)
          ..where((t) => t.uuid.equals(normalized)))
        .write(const CashRegistersCompanion(syncStatus: Value('conflict')));
  }

  Future<void> applyRemotePayload(Map<String, dynamic> payload) async {
    final uuid = payload['uuid'] as String?;
    if (uuid == null || uuid.trim().isEmpty) return;
    final normalized = _normalizeUuid(uuid);

    final companyId = payload['companyId'] as String? ?? 'default';
    final name = payload['name'] as String? ?? 'Cash Register';
    final code = payload['code'] as String? ?? 'REG';
    final isActive = payload['isActive'] as bool? ?? true;
    final accountId = payload['accountingAccountId'] as String?;
    final version = payload['version'] as int? ?? 1;
    final updatedAtMs =
        payload['updatedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch;
    final deletedAtMs = payload['deletedAt'] as int?;

    final isLinked = accountId != null && accountId.trim().isNotEmpty;

    final companion = CashRegistersCompanion(
      uuid: Value(normalized),
      companyId: Value(companyId),
      name: Value(name),
      code: Value(code),
      isActive: Value(isActive),
      accountingAccountId: Value(accountId),
      accountingLinkStatus: Value(
        isLinked ? 'ACCOUNTING_READY' : 'ACCOUNTING_NOT_LINKED',
      ),
      syncStatus: const Value('synced'),
      version: Value(version),
      createdAt: Value(updatedAtMs),
      updatedAt: Value(updatedAtMs),
      deletedAt: Value(deletedAtMs),
    );

    final existing = await (_db.select(
      _db.cashRegisters,
    )..where((t) => t.uuid.equals(normalized))).getSingleOrNull();

    if (existing != null) {
      await (_db.update(
        _db.cashRegisters,
      )..where((t) => t.uuid.equals(normalized))).write(companion);
    } else {
      await _db.into(_db.cashRegisters).insert(companion);
    }
  }
}
