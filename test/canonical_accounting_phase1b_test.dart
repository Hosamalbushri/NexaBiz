import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/core/errors/unconfigured_integration_exception.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/normal_balance.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_failure.dart';
import 'package:stock_count/modules/accounting/domain/resolvers/authoritative_account_resolver_impl.dart';
import 'package:stock_count/modules/purchases/domain/entities/supplier.dart';
import 'package:stock_count/modules/receipts_payments/shared/domain/services/rp_ledger_posting_port.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/financial_transaction.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/rp_payment_method.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_source.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_status.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/discount_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/payment_method.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/payment_status.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_data_source.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_settlement_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_status.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_ledger_posting_port.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_accounting_config.dart';
import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';

class _FakeAccountRepository implements AccountRepository {
  final Map<String, Account> _byUuid = {};

  void addAccount(Account acc) {
    _byUuid[acc.uuid] = acc;
  }

  @override
  Future<Account?> getByUuid(String uuid) async => _byUuid[uuid];

  @override
  Future<Account> createAccount(Account account) async => account;

  @override
  Future<List<Account>> getAccounts({String? companyId, bool? isActive}) async =>
      _byUuid.values.toList();

  @override
  Future<Account?> getByCode(String accountCode, {String? companyId}) async =>
      null;

  @override
  Future<List<Account>> getChildAccounts(String parentUuid) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeInitRepository implements CompanyInitializationRepository {
  _FakeInitRepository(this.config);

  CompanyAccountingConfig? config;

  @override
  Future<CompanyAccountingConfig?> getAccountingConfig([String? companyId]) async => config;

  @override
  Future<void> saveAccountingConfig(CompanyAccountingConfig config) async {
    this.config = config;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Phase 1B — Canonical Accounting Authority & Fail-Closed Enforcement', () {
    late _FakeAccountRepository accountRepo;
    late _FakeInitRepository initRepo;
    late AuthoritativeAccountResolver resolver;

    const companyId = 'comp-1001';
    final now = DateTime.now();

    setUp(() {
      accountRepo = _FakeAccountRepository();

      accountRepo.addAccount(
        Account(
          id: 1,
          uuid: 'uuid-cash-001',
          accountCode: '1211',
          name: 'Cash Box',
          accountType: AccountType.asset,
          normalBalance: NormalBalance.debit,
          level: 1,
          isGroup: false,
          isActive: true,
          isSystemAccount: false,
          createdAt: now,
          updatedAt: now,
          companyId: companyId,
        ),
      );

      accountRepo.addAccount(
        Account(
          id: 2,
          uuid: 'uuid-ar-001',
          accountCode: '1220',
          name: 'Accounts Receivable',
          accountType: AccountType.asset,
          normalBalance: NormalBalance.debit,
          level: 1,
          isGroup: false,
          isActive: true,
          isSystemAccount: false,
          createdAt: now,
          updatedAt: now,
          companyId: companyId,
        ),
      );

      accountRepo.addAccount(
        Account(
          id: 3,
          uuid: 'uuid-ap-001',
          accountCode: '2110',
          name: 'Accounts Payable',
          accountType: AccountType.liability,
          normalBalance: NormalBalance.credit,
          level: 1,
          isGroup: false,
          isActive: true,
          isSystemAccount: false,
          createdAt: now,
          updatedAt: now,
          companyId: companyId,
        ),
      );

      accountRepo.addAccount(
        Account(
          id: 4,
          uuid: 'uuid-inv-001',
          accountCode: '1230',
          name: 'Inventory Asset',
          accountType: AccountType.asset,
          normalBalance: NormalBalance.debit,
          level: 1,
          isGroup: false,
          isActive: true,
          isSystemAccount: false,
          createdAt: now,
          updatedAt: now,
          companyId: companyId,
        ),
      );

      accountRepo.addAccount(
        Account(
          id: 5,
          uuid: 'uuid-rev-001',
          accountCode: '4100',
          name: 'Sales Revenue',
          accountType: AccountType.revenue,
          normalBalance: NormalBalance.credit,
          level: 1,
          isGroup: false,
          isActive: true,
          isSystemAccount: false,
          createdAt: now,
          updatedAt: now,
          companyId: companyId,
        ),
      );

      accountRepo.addAccount(
        Account(
          id: 6,
          uuid: 'uuid-cogs-001',
          accountCode: '5100',
          name: 'Cost of Goods Sold',
          accountType: AccountType.expense,
          normalBalance: NormalBalance.debit,
          level: 1,
          isGroup: false,
          isActive: true,
          isSystemAccount: false,
          createdAt: now,
          updatedAt: now,
          companyId: companyId,
        ),
      );

      final config = CompanyAccountingConfig(
        companyId: companyId,
        accountMappings: const {
          AccountRole.cash: 'uuid-cash-001',
          AccountRole.receivable: 'uuid-ar-001',
          AccountRole.payable: 'uuid-ap-001',
          AccountRole.inventory: 'uuid-inv-001',
          AccountRole.revenue: 'uuid-rev-001',
          AccountRole.cogs: 'uuid-cogs-001',
        },
      );

      initRepo = _FakeInitRepository(config);
      resolver = AuthoritativeAccountResolver(
        accountRepository: accountRepo,
        initRepository: initRepo,
      );
    });

    test('Test A — Cash role resolves via canonical resolver', () async {
      final acc = await resolver.resolveAccount(
        companyId: companyId,
        role: AccountRole.cash,
      );
      expect(acc.uuid, equals('uuid-cash-001'));
      expect(acc.accountCode, equals('1211'));
    });

    test('Test B — Receivable role resolves via canonical resolver', () async {
      final acc = await resolver.resolveAccount(
        companyId: companyId,
        role: AccountRole.receivable,
      );
      expect(acc.uuid, equals('uuid-ar-001'));
    });

    test('Test C — Payable role resolves via canonical resolver', () async {
      final acc = await resolver.resolveAccount(
        companyId: companyId,
        role: AccountRole.payable,
      );
      expect(acc.uuid, equals('uuid-ap-001'));
    });

    test('Test D — Inventory role resolves via canonical resolver', () async {
      final acc = await resolver.resolveAccount(
        companyId: companyId,
        role: AccountRole.inventory,
      );
      expect(acc.uuid, equals('uuid-inv-001'));
    });

    test('Test E — Revenue role resolves via canonical resolver', () async {
      final acc = await resolver.resolveAccount(
        companyId: companyId,
        role: AccountRole.revenue,
      );
      expect(acc.uuid, equals('uuid-rev-001'));
    });

    test('Test F — COGS role resolves via canonical resolver', () async {
      final acc = await resolver.resolveAccount(
        companyId: companyId,
        role: AccountRole.cogs,
      );
      expect(acc.uuid, equals('uuid-cogs-001'));
    });

    test('Test G — Missing AccountRole fails closed without fallback', () async {
      expect(
        () => resolver.resolveAccount(
          companyId: companyId,
          role: AccountRole.discount,
        ),
        throwsA(isA<InvalidAccountingEffectFailure>()),
      );
    });

    test('Test H — Target numeric integer ID rejected by resolver', () async {
      expect(
        () => resolver.resolveAccount(
          companyId: companyId,
          role: AccountRole.cash,
          overrideAccountUuid: '1211',
        ),
        throwsA(isA<InvalidSourceReferenceFailure>()),
      );
    });

    test('Test I — Integrated Mode NoOp RP port throws UnconfiguredIntegrationException', () async {
      const port = NoOpRpLedgerPostingPort(isIntegratedMode: true);
      final dummyTxn = FinancialTransaction(
        id: 1,
        uuid: 'txn-1',
        transactionNumber: 'REC-001',
        transactionType: TransactionType.receipt,
        source: TransactionSource.manualReceipt,
        transactionDate: now,
        amount: 100.0,
        currencyCode: 'SAR',
        baseCurrencyCode: 'SAR',
        exchangeRate: 1.0,
        counterAmount: 100.0,
        counterCurrencyCode: 'SAR',
        counterExchangeRate: 1.0,
        cashAccountId: 'uuid-cash-001',
        counterAccountId: 'uuid-ar-001',
        paymentMethod: RpPaymentMethod.cash,
        documentStatus: TransactionStatus.posted,
        createdAt: now,
        updatedAt: now,
      );

      expect(
        () => port.syncTransaction(dummyTxn),
        throwsA(isA<UnconfiguredIntegrationException>()),
      );
    });

    test('Test J — Integrated Mode NoOp Sale port throws UnconfiguredIntegrationException', () async {
      const port = NoOpSaleLedgerPostingPort(isIntegratedMode: true);
      final dummySale = Sale(
        id: 1,
        uuid: 'sale-1',
        companyId: companyId,
        saleNumber: 'INV-001',
        saleDate: now,
        settlementType: SaleSettlementType.cash,
        currencyCode: 'SAR',
        baseCurrencyCode: 'SAR',
        exchangeRate: 1.0,
        items: const [],
        payments: const [],
        subtotal: 100.0,
        itemDiscountTotal: 0.0,
        discountType: DiscountType.fixed,
        discountValue: 0.0,
        discountAmount: 0.0,
        taxRate: 0.0,
        taxAmount: 0.0,
        total: 100.0,
        paidAmount: 100.0,
        remainingAmount: 0.0,
        paymentStatus: PaymentStatus.paid,
        paymentMethod: PaymentMethod.cash,
        saleStatus: SaleStatus.posted,
        dataSource: SaleDataSource.local,
        createdAt: now,
        updatedAt: now,
      );

      expect(
        () => port.syncSale(dummySale),
        throwsA(isA<UnconfiguredIntegrationException>()),
      );
    });

    test('Test K — Supplier currentBalance entity default is non-authoritative', () {
      final supplier = Supplier(
        id: 'sup-1',
        companyId: companyId,
        nameAr: 'مورد اختبار',
        nameEn: 'Test Supplier',
        createdAt: now,
        updatedAt: now,
      );
      expect(supplier.currentBalance, equals(0.0));
    });
  });
}
