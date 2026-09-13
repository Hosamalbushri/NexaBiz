import 'package:drift/drift.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:drift/native.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import '../../domain/entities/cash_register.dart';
import '../../domain/repositories/cash_register_repository.dart';

/// Durable Drift-backed repository implementation for Cash Registers.
class CashRegisterRepositoryImpl implements CashRegisterRepository {
  static const entityType = 'cash_register';

  CashRegisterRepositoryImpl({
    required this.accountRepository,
    NexabizDatabase? db,
    this.settingsBox,
    List<CashRegister>? initialRegisters,
  }) : _db = db ?? NexabizDatabase.connect(NativeDatabase.memory()) {
    if (initialRegisters != null && initialRegisters.isNotEmpty) {
      for (final reg in initialRegisters) {
        _seedRegisterIfMissing(reg);
      }
    }
  }

  final AccountRepository accountRepository;
  final NexabizDatabase _db;
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

  CashRegister _rowToEntity(CashRegisterData row) {
    return CashRegister(
      id: row.id,
      companyId: row.companyId,
      name: row.name,
      code: row.code,
      isActive: row.isActive,
      accountingAccountId: row.accountId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  CashRegistersCompanion _entityToCompanion(CashRegister entity) {
    return CashRegistersCompanion(
      id: Value(entity.id),
      companyId: Value(entity.companyId),
      name: Value(entity.name),
      code: Value(entity.code),
      description: const Value.absent(),
      accountId: Value(entity.accountingAccountId),
      isActive: Value(entity.isActive),
      createdAt: Value(entity.createdAt),
      updatedAt: Value(entity.updatedAt),
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
    final query = _db.select(_db.cashRegisters);
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
    final query = _db.select(_db.cashRegisters)
      ..where((tbl) => tbl.id.equals(registerId.trim()));
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

    final rowsAffected =
        await (_db.update(_db.cashRegisters)
              ..where((tbl) => tbl.id.equals(register.id.trim())))
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

    if (register.isLinked &&
        register.accountingAccountId != null &&
        register.accountingAccountId != accountId) {
      final boundAccountId = register.accountingAccountId!;
      final currentAccount =
          await accountRepository.getByUuid(boundAccountId) ??
          await accountRepository.getByAccountCode(boundAccountId);
      final targetUuids = <String>{
        boundAccountId,
        if (currentAccount != null) currentAccount.id,
        if (currentAccount != null) currentAccount.accountCode,
      };

      for (final uuid in targetUuids) {
        final hasMovements =
            await (_db.select(_db.journalLines)
                  ..where((tbl) => tbl.accountId.equals(uuid))
                  ..limit(1))
                .get()
                .then((rows) => rows.isNotEmpty);

        if (hasMovements) {
          throw const CashRegisterException(
            'Cannot change accounting account: cash register has recorded transaction movements.',
            code: 'REGISTER_HAS_MOVEMENTS',
          );
        }
      }
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
      accountId: Value(account.id),
      updatedAt: Value(now),
    );

    await (_db.update(
      _db.cashRegisters,
    )..where((tbl) => tbl.id.equals(registerId.trim()))).write(companion);

    final readBack = await getCashRegisterById(registerId);
    if (readBack == null ||
        !readBack.isLinked ||
        readBack.accountingAccountId != account.id) {
      throw CashRegisterException(
        'Database link read-back verification failed for register $registerId and account ${account.id}',
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
        if (account != null) account.id,
        if (account != null) account.accountCode,
      };

      for (final uuid in targetUuids) {
        final hasMovements =
            await (_db.select(_db.journalLines)
                  ..where((tbl) => tbl.accountId.equals(uuid))
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
      accountId: const Value(null),
      updatedAt: Value(now),
    );

    await (_db.update(
      _db.cashRegisters,
    )..where((tbl) => tbl.id.equals(registerId.trim()))).write(companion);

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
    return register.copyWith(accountingAccountId: account.id);
  }

  @override
  Future<void> deleteCashRegister(String registerId) async {
    await (_db.delete(
      _db.cashRegisters,
    )..where((tbl) => tbl.id.equals(registerId.trim()))).go();
  }

  Future<void> markSynced({
    required String uuid,
    required int remoteVersion,
    DateTime? syncedAt,
  }) async {
    await (_db.update(
      _db.cashRegisters,
    )..where((t) => t.id.equals(uuid.trim()))).write(
      CashRegistersCompanion(
        updatedAt: Value(syncedAt ?? DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> markConflict(String uuid) async {}

  Future<void> applyRemotePayload(Map<String, dynamic> payload) async {
    final id = payload['id'] as String? ?? payload['uuid'] as String?;
    if (id == null || id.trim().isEmpty) return;
    final trimmedId = id.trim();

    final companyId = payload['companyId'] as String? ?? 'default';
    final name = payload['name'] as String? ?? 'Cash Register';
    final code = payload['code'] as String? ?? 'REG';
    final isActive = payload['isActive'] as bool? ?? true;
    final accountId = payload['accountingAccountId'] as String? ?? payload['accountId'] as String?;

    final companion = CashRegistersCompanion(
      id: Value(trimmedId),
      companyId: Value(companyId),
      name: Value(name),
      code: Value(code),
      isActive: Value(isActive),
      accountId: Value(accountId),
      updatedAt: Value(DateTime.now().toUtc()),
    );

    final existing = await (_db.select(
      _db.cashRegisters,
    )..where((t) => t.id.equals(trimmedId))).getSingleOrNull();

    if (existing != null) {
      await (_db.update(
        _db.cashRegisters,
      )..where((t) => t.id.equals(trimmedId))).write(companion);
    } else {
      await _db.into(_db.cashRegisters).insert(companion);
    }
  }
}
