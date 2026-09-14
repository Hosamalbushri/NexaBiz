import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:hive/hive.dart';

import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/models/account_exception.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/missing_account_exception.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/accounting/shared/data/services/account_mapping_resolver_impl.dart';
import 'package:stock_count/modules/accounting/shared/data/services/account_validation_service_impl.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/accounting_entry_builder.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_accounting_config.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_inventory_config.dart';
import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';

class FakeCompanyInitRepo implements CompanyInitializationRepository {
  FakeCompanyInitRepo(this.companyId, this.invCode, this.cogsCode);

  final String companyId;
  final String invCode;
  final String cogsCode;

  @override
  Future<CompanyAccountingConfig?> getAccountingConfig() async {
    return CompanyAccountingConfig(
      companyId: companyId,
      accountMappings: {
        AccountRole.inventory: invCode,
        AccountRole.cogs: cogsCode,
      },
    );
  }

  @override
  Future<CompanyInventoryConfig?> getInventoryConfig() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NexabizDatabase accDb;
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
    accDb = NexabizDatabase.memory();

    accRepoTenantA = AccountRepositoryImpl(accDb, readCompanyId: () => tenantA);
    accRepoTenantB = AccountRepositoryImpl(accDb, readCompanyId: () => tenantB);

    await accRepoTenantA.seedDefaultChart();
    await accRepoTenantB.seedDefaultChart();

    accValidatorTenantA = AccountValidationServiceImpl(accRepoTenantA);
    resolverTenantA = AccountMappingResolverImpl(
      accountRepository: accRepoTenantA,
      validationService: accValidatorTenantA,
      initRepository: FakeCompanyInitRepo(tenantA, '1230', '5100'),
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
    test(
      '1. Valid Mapping: Resolves system accounts deterministically for active tenant',
      () async {
        final mapping = await resolverTenantA.resolveForDocument(
          documentType: 'stock_issue',
        );
        final invRef = mapping.getRole(AccountRole.inventory);
        final cogsRef = mapping.getRole(AccountRole.cogs);

        expect(invRef, isNotNull);
        expect(invRef!.accountCode, equals('1230'));

        expect(cogsRef, isNotNull);
        expect(cogsRef!.accountCode, equals('5100'));
      },
    );

    test(
      '2. Missing Mapping: Throws MissingAccountException when required role is missing',
      () async {
        final mapping = await resolverTenantA.resolveForDocument(
          documentType: 'stock_issue',
        );

        expect(
          () => mapping.assertRequiredRoles([
            AccountRole.inventory,
            AccountRole.tax,
          ]),
          throwsA(isA<MissingAccountException>()),
        );
      },
    );

    test(
      '3. Precedence Rules: Explicit override deterministically overrides default system mapping',
      () async {
        final now = DateTime.now().toUtc();

        final customCogsUuid = generateUuidV4();

        // Seed Custom Special COGS 5190
        await accDb
            .into(accDb.accounts)
            .insert(
              AccountsCompanion.insert(
                id: drift.Value(customCogsUuid),
                accountCode: '5190',
                name: 'تكلفة مبيعات خاصة',
                accountType: 'expense',
                normalBalance: 'debit',
                createdAt: drift.Value(now),
                updatedAt: drift.Value(now),
                companyId: tenantA,
                isSystemAccount: const drift.Value(true),
              ),
            );

        // Resolve WITH override for cogs -> customCogsUuid
        final mapping = await resolverTenantA.resolveForDocument(
          documentType: 'stock_issue',
          overrides: {AccountRole.cogs: customCogsUuid},
        );

        final resolvedCogs = mapping.getRole(AccountRole.cogs);
        expect(resolvedCogs, isNotNull);
        expect(resolvedCogs!.accountUuid, equals(customCogsUuid));
        expect(resolvedCogs.accountCode, equals('5190'));
        expect(resolvedCogs.accountName, equals('تكلفة مبيعات خاصة'));
      },
    );

    test(
      '4. Multi-Tenant Cross Isolation: Account from Tenant B is rejected under Tenant A',
      () async {
        final now = DateTime.now().toUtc();

        final accUuidB = generateUuidV4();

        // Seed Account 9999 ONLY in Tenant B
        await accDb
            .into(accDb.accounts)
            .insert(
              AccountsCompanion.insert(
                id: drift.Value(accUuidB),
                accountCode: '9999',
                name: 'حساب خاص شركة B',
                accountType: 'asset',
                normalBalance: 'debit',
                createdAt: drift.Value(now),
                updatedAt: drift.Value(now),
                companyId: tenantB,
                isSystemAccount: const drift.Value(true),
              ),
            );

        // Tenant A tries to use Tenant B's account in override
        expect(
          () => resolverTenantA.resolveForDocument(
            documentType: 'stock_issue',
            overrides: {AccountRole.inventory: accUuidB},
          ),
          throwsA(anything), // Must fail, never cross tenant boundary
        );
      },
    );

    test(
      '5. Historical Immutability: Changing default mapping after posting preserves historical identity',
      () async {
        final now = DateTime.now().toUtc();
        final nowMs = now.millisecondsSinceEpoch;

        final invAcc = await accRepoTenantA.getByAccountCode('1230');
        final cogsAcc = await accRepoTenantA.getByAccountCode('5100');
        expect(invAcc, isNotNull);
        expect(cogsAcc, isNotNull);

        final accInvV1Uuid = invAcc!.id;
        final accCogsV1Uuid = cogsAcc!.id;

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
        final entryId = generateUuidV4();
        await accDb
            .into(accDb.journalEntries)
            .insert(
              JournalEntriesCompanion.insert(
                id: drift.Value(entryId),
                voucherNumber: 'JV-HIST-001',
                voucherType: draft.voucherType,
                currencyCode: 'YER',
                entryDate: nowMs,
                description: drift.Value(draft.description),
                isPosted: const drift.Value(true),
                createdAt: nowMs,
                updatedAt: nowMs,
                companyId: drift.Value(tenantA),
              ),
            );

        for (final line in draft.lines) {
          await accDb
              .into(accDb.journalLines)
              .insert(
                JournalLinesCompanion.insert(
                  id: drift.Value(generateUuidV4()),
                  entryId: entryId,
                  accountId: line.accountUuid,
                  currencyCode: 'YER',
                  debit: drift.Value(line.debit),
                  credit: drift.Value(line.credit),
                  companyId: drift.Value(tenantA),
                ),
              );
        }

        final historicalLines = await (accDb.select(
          accDb.journalLines,
        )..where((tbl) => tbl.entryId.equals(entryId))).get();
        expect(historicalLines.length, equals(2));

        final historicalLineUuids = historicalLines
            .map((l) => l.accountId)
            .toSet();
        expect(historicalLineUuids.contains(accInvV1Uuid), isTrue);
        expect(historicalLineUuids.contains(accCogsV1Uuid), isTrue);

        // Verify soft delete protection for in-use account
        expect(
          () => accRepoTenantA.softDelete(accInvV1Uuid),
          throwsA(isA<AccountException>()),
        );

        // Update account code of V1 account to 1230-OLD
        await (accDb.update(accDb.accounts)..where((t) => t.id.equals(accInvV1Uuid))).write(
          const AccountsCompanion(accountCode: drift.Value('1230-OLD')),
        );

        final accInvV2Uuid = generateUuidV4();
        await accDb
            .into(accDb.accounts)
            .insert(
              AccountsCompanion.insert(
                id: drift.Value(accInvV2Uuid),
                accountCode: '1230',
                name: 'حساب المخزون الجديد 2026',
                accountType: 'asset',
                normalBalance: 'debit',
                createdAt: drift.Value(now),
                updatedAt: drift.Value(now),
                companyId: tenantA,
                isSystemAccount: const drift.Value(true),
              ),
            );

        // Verify historical entry is 100% IMMUTABLE
        final reVerifiedLines = await (accDb.select(
          accDb.journalLines,
        )..where((tbl) => tbl.entryId.equals(entryId))).get();
        expect(reVerifiedLines.length, equals(2));
        final reVerifiedLineUuids = reVerifiedLines
            .map((l) => l.accountId)
            .toSet();

        expect(
          reVerifiedLineUuids.contains(accInvV1Uuid),
          isTrue,
          reason: 'Historical posted line MUST retain original account UUID',
        );
        expect(
          reVerifiedLineUuids.contains(accInvV2Uuid),
          isFalse,
          reason:
              'Historical posted line MUST NOT change to new default account',
        );
      },
    );
  });
}
