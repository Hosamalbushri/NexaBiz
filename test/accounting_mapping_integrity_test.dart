import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:hive/hive.dart';

import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/missing_account_exception.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/shared/data/services/account_mapping_resolver_impl.dart';
import 'package:stock_count/modules/accounting/shared/data/services/account_validation_service_impl.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/accounting_entry_builder.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AccountingDatabase accDb;
  late AccountRepositoryImpl accRepoTenantA;
  late AccountRepositoryImpl accRepoTenantB;
  late AccountValidationServiceImpl accValidatorTenantA;
  late AccountMappingResolverImpl resolverTenantA;
  late AccountingEntryBuilder entryBuilderTenantA;

  const tenantA = 'company-tenant-a';
  const tenantB = 'company-tenant-b';

  setUpAll(() async {
    final tempDir = String.fromEnvironment('TMDIR', defaultValue: '/tmp');
    Hive.init(tempDir);
  });

  setUp(() async {
    accDb = AccountingDatabase.memory();

    accRepoTenantA = AccountRepositoryImpl(
      accDb,
      readCompanyId: () => tenantA,
    );
    accRepoTenantB = AccountRepositoryImpl(
      accDb,
      readCompanyId: () => tenantB,
    );

    accValidatorTenantA = AccountValidationServiceImpl(accRepoTenantA);
    resolverTenantA = AccountMappingResolverImpl(
      accountRepository: accRepoTenantA,
      validationService: accValidatorTenantA,
    );

    entryBuilderTenantA = AccountingEntryBuilder(
      mappingResolver: resolverTenantA,
      validationService: accValidatorTenantA,
    );
  });

  tearDown(() async {
    await accDb.close();
  });

  group('ROOT FIX 36 — Accounting Mapping Integrity Tests', () {
    test('1. Valid Mapping: Resolves system accounts deterministically for active tenant', () async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;

      // Seed Account 1230 for Tenant A
      await accDb.into(accDb.accounts).insert(
        AccountsCompanion.insert(
          uuid: generateUuidV4(),
          accountCode: '1230',
          name: 'حساب المخزون شركة A',
          accountType: 'asset',
          normalBalance: 'debit',
          createdAt: now,
          updatedAt: now,
          companyId: const drift.Value(tenantA),
        ),
      );

      // Seed Account 5100 for Tenant A
      await accDb.into(accDb.accounts).insert(
        AccountsCompanion.insert(
          uuid: generateUuidV4(),
          accountCode: '5100',
          name: 'تكلفة البضاعة المباعة شركة A',
          accountType: 'expense',
          normalBalance: 'debit',
          createdAt: now,
          updatedAt: now,
          companyId: const drift.Value(tenantA),
        ),
      );

      final mapping = await resolverTenantA.resolveForDocument(documentType: 'stock_issue');
      final invRef = mapping.getRole(AccountRole.inventory);
      final cogsRef = mapping.getRole(AccountRole.cogs);

      expect(invRef, isNotNull);
      expect(invRef!.accountCode, equals('1230'));
      expect(invRef.accountName, equals('حساب المخزون شركة A'));

      expect(cogsRef, isNotNull);
      expect(cogsRef!.accountCode, equals('5100'));
      expect(cogsRef.accountName, equals('تكلفة البضاعة المباعة شركة A'));
    });

    test('2. Missing Mapping: Throws MissingAccountException when required role is missing', () async {
      final mapping = await resolverTenantA.resolveForDocument(documentType: 'stock_issue');

      expect(
        () => mapping.assertRequiredRoles([AccountRole.inventory, AccountRole.tax]),
        throwsA(isA<MissingAccountException>()),
      );
    });

    test('3. Precedence Rules: Explicit override deterministically overrides default system mapping', () async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;

      final defaultCogsUuid = generateUuidV4();
      final customCogsUuid = generateUuidV4();

      // Seed Default COGS 5100
      await accDb.into(accDb.accounts).insert(
        AccountsCompanion.insert(
          uuid: defaultCogsUuid,
          accountCode: '5100',
          name: 'تكلفة المبيعات القياسية',
          accountType: 'expense',
          normalBalance: 'debit',
          createdAt: now,
          updatedAt: now,
          companyId: const drift.Value(tenantA),
        ),
      );

      // Seed Custom Special COGS 5190
      await accDb.into(accDb.accounts).insert(
        AccountsCompanion.insert(
          uuid: customCogsUuid,
          accountCode: '5190',
          name: 'تكلفة مبيعات خاصة',
          accountType: 'expense',
          normalBalance: 'debit',
          createdAt: now,
          updatedAt: now,
          companyId: const drift.Value(tenantA),
        ),
      );

      // Resolve WITH override for cogs -> customCogsUuid
      final mapping = await resolverTenantA.resolveForDocument(
        documentType: 'stock_issue',
        overrides: {
          AccountRole.cogs: customCogsUuid,
        },
      );

      final resolvedCogs = mapping.getRole(AccountRole.cogs);
      expect(resolvedCogs, isNotNull);
      expect(resolvedCogs!.accountUuid, equals(customCogsUuid));
      expect(resolvedCogs.accountCode, equals('5190'));
      expect(resolvedCogs.accountName, equals('تكلفة مبيعات خاصة'));
    });

    test('4. Multi-Tenant Cross Isolation: Account from Tenant B is rejected under Tenant A', () async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;

      final accUuidB = generateUuidV4();

      // Seed Account 1230 ONLY in Tenant B
      await accDb.into(accDb.accounts).insert(
        AccountsCompanion.insert(
          uuid: accUuidB,
          accountCode: '1230',
          name: 'حساب مخزون شركة B',
          accountType: 'asset',
          normalBalance: 'debit',
          createdAt: now,
          updatedAt: now,
          companyId: const drift.Value(tenantB),
        ),
      );

      // Tenant A tries to use Tenant B's account in override
      expect(
        () => resolverTenantA.resolveForDocument(
          documentType: 'stock_issue',
          overrides: {
            AccountRole.inventory: accUuidB,
          },
        ),
        throwsA(anything), // Must fail, never cross tenant boundary
      );
    });

    test('5. Historical Immutability: Changing default mapping after posting preserves historical identity', () async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;

      final accInvV1Uuid = generateUuidV4();
      final accCogsV1Uuid = generateUuidV4();

      // Seed initial accounts (V1)
      await accDb.into(accDb.accounts).insert(
        AccountsCompanion.insert(
          uuid: accInvV1Uuid,
          accountCode: '1230',
          name: 'حساب المخزون القديم',
          accountType: 'asset',
          normalBalance: 'debit',
          createdAt: now,
          updatedAt: now,
          companyId: const drift.Value(tenantA),
        ),
      );

      await accDb.into(accDb.accounts).insert(
        AccountsCompanion.insert(
          uuid: accCogsV1Uuid,
          accountCode: '5100',
          name: 'تكلفة المبيعات القديمة',
          accountType: 'expense',
          normalBalance: 'debit',
          createdAt: now,
          updatedAt: now,
          companyId: const drift.Value(tenantA),
        ),
      );

      // Build & post historical document entry draft
      final docRef = InventoryDocumentRef(
        documentId: generateUuidV4(),
        documentNumber: 'ISS-HIST-001',
        documentType: InventoryDocumentType.stockIssue,
        documentDate: DateTime.now().toUtc(),
      );

      final draft = await entryBuilderTenantA.buildDraftFromInventoryDocument(
        document: docRef,
        totalAmount: 1500.0,
      );

      // Save journal entry into database
      final entryUuid = generateUuidV4();
      await accDb.into(accDb.journalEntries).insert(
        JournalEntriesCompanion.insert(
          uuid: entryUuid,
          voucherNumber: 'JV-HIST-001',
          voucherType: draft.voucherType,
          currencyCode: 'YER',
          entryDate: now,
          description: drift.Value(draft.description),
          isPosted: const drift.Value(true),
          createdAt: now,
          updatedAt: now,
          companyId: const drift.Value(tenantA),
        ),
      );

      for (final line in draft.lines) {
        await accDb.into(accDb.journalLines).insert(
          JournalLinesCompanion.insert(
            uuid: generateUuidV4(),
            entryUuid: entryUuid,
            accountUuid: line.accountUuid,
            currencyCode: 'YER',
            debit: drift.Value(line.debit),
            credit: drift.Value(line.credit),
          ),
        );
      }

      final historicalLines = await (accDb.select(accDb.journalLines)
            ..where((tbl) => tbl.entryUuid.equals(entryUuid)))
          .get();
      expect(historicalLines.length, equals(2));

      final historicalLineUuids = historicalLines.map((l) => l.accountUuid).toSet();
      expect(historicalLineUuids.contains(accInvV1Uuid), isTrue);
      expect(historicalLineUuids.contains(accCogsV1Uuid), isTrue);

      // NOW: Change configuration (delete old 1230, seed new 1230 V2 with different UUID)
      await (accDb.delete(accDb.accounts)..where((tbl) => tbl.uuid.equals(accInvV1Uuid))).go();

      final accInvV2Uuid = generateUuidV4();
      await accDb.into(accDb.accounts).insert(
        AccountsCompanion.insert(
          uuid: accInvV2Uuid,
          accountCode: '1230',
          name: 'حساب المخزون الجددددد 2026',
          accountType: 'asset',
          normalBalance: 'debit',
          createdAt: now,
          updatedAt: now,
          companyId: const drift.Value(tenantA),
        ),
      );

      // Verify historical entry is 100% IMMUTABLE
      final reVerifiedLines = await (accDb.select(accDb.journalLines)
            ..where((tbl) => tbl.entryUuid.equals(entryUuid)))
          .get();
      expect(reVerifiedLines.length, equals(2));
      final reVerifiedLineUuids = reVerifiedLines.map((l) => l.accountUuid).toSet();

      expect(reVerifiedLineUuids.contains(accInvV1Uuid), isTrue, reason: 'Historical posted line MUST retain original account UUID');
      expect(reVerifiedLineUuids.contains(accInvV2Uuid), isFalse, reason: 'Historical posted line MUST NOT change to new default account');
    });
  });
}
