import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/modules/accounting/presentation/providers/account_providers.dart';
import 'package:stock_count/modules/accounting/presentation/providers/journal_providers.dart';
import 'package:stock_count/modules/customers/presentation/providers/customer_providers.dart';
import 'package:stock_count/modules/inventory/presentation/providers/product_providers.dart';
import 'package:stock_count/modules/receipts_payments/presentation/providers/rp_providers.dart';
import 'package:stock_count/modules/sales/presentation/providers/sale_providers.dart';

import 'package:stock_count/modules/sales/domain/entities/discount_type.dart';
import 'package:stock_count/modules/sales/domain/entities/payment_method.dart';
import 'package:stock_count/modules/sales/domain/entities/payment_status.dart';
import 'package:stock_count/modules/sales/domain/entities/sale_settlement_type.dart';
import 'package:stock_count/modules/sales/domain/entities/sale_status.dart';
import 'package:stock_count/modules/customers/domain/entities/customer_data_source.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/rp_payment_method.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/transaction_status.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/transaction_source.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/transaction_type.dart';

import 'package:stock_count/modules/sync/sync.dart';

/// Counter implementations for LocalDatasetInspector
class AccountingRecordCounter implements LocalDatasetRecordCounter {
  const AccountingRecordCounter(this.ref);
  final Ref ref;

  @override
  Future<int> countRecords() async {
    var cnt = 0;
    try {
      final db = ref.read(accountingDatabaseProvider);
      final r1 = await db.customSelect('SELECT COUNT(*) as cnt FROM accounts WHERE deleted_at IS NULL').getSingleOrNull();
      cnt += (r1?.read<num>('cnt') ?? 0).toInt();
      final r2 = await db.customSelect('SELECT COUNT(*) as cnt FROM journal_entries WHERE deleted_at IS NULL').getSingleOrNull();
      cnt += (r2?.read<num>('cnt') ?? 0).toInt();
    } catch (_) {}
    return cnt;
  }
}

class InventoryRecordCounter implements LocalDatasetRecordCounter {
  const InventoryRecordCounter(this.ref);
  final Ref ref;

  @override
  Future<int> countRecords() async {
    var cnt = 0;
    try {
      final db = ref.read(inventoryDatabaseProvider);
      final r1 = await db.customSelect('SELECT COUNT(*) as cnt FROM products WHERE deleted_at IS NULL').getSingleOrNull();
      cnt += (r1?.read<num>('cnt') ?? 0).toInt();
      final r2 = await db.customSelect('SELECT COUNT(*) as cnt FROM inventory_items WHERE deleted_at IS NULL').getSingleOrNull();
      cnt += (r2?.read<num>('cnt') ?? 0).toInt();
    } catch (_) {}
    return cnt;
  }
}

class CustomerRecordCounter implements LocalDatasetRecordCounter {
  const CustomerRecordCounter(this.ref);
  final Ref ref;

  @override
  Future<int> countRecords() async {
    var cnt = 0;
    try {
      final db = ref.read(customersDatabaseProvider);
      final r1 = await db.customSelect('SELECT COUNT(*) as cnt FROM customers WHERE deleted_at IS NULL').getSingleOrNull();
      cnt += (r1?.read<num>('cnt') ?? 0).toInt();
      final r2 = await db.customSelect('SELECT COUNT(*) as cnt FROM suppliers WHERE deleted_at IS NULL').getSingleOrNull();
      cnt += (r2?.read<num>('cnt') ?? 0).toInt();
    } catch (_) {}
    return cnt;
  }
}

class SaleRecordCounter implements LocalDatasetRecordCounter {
  const SaleRecordCounter(this.ref);
  final Ref ref;

  @override
  Future<int> countRecords() async {
    var cnt = 0;
    try {
      final db = ref.read(salesDatabaseProvider);
      final r1 = await db.customSelect('SELECT COUNT(*) as cnt FROM sales WHERE deleted_at IS NULL').getSingleOrNull();
      cnt += (r1?.read<num>('cnt') ?? 0).toInt();
      final r2 = await db.customSelect('SELECT COUNT(*) as cnt FROM purchases WHERE deleted_at IS NULL').getSingleOrNull();
      cnt += (r2?.read<num>('cnt') ?? 0).toInt();
    } catch (_) {}
    return cnt;
  }
}

class RpRecordCounter implements LocalDatasetRecordCounter {
  const RpRecordCounter(this.ref);
  final Ref ref;

  @override
  Future<int> countRecords() async {
    var cnt = 0;
    try {
      final db = ref.read(receiptsPaymentsDatabaseProvider);
      final r1 = await db.customSelect('SELECT COUNT(*) as cnt FROM financial_transactions WHERE deleted_at IS NULL').getSingleOrNull();
      cnt += (r1?.read<num>('cnt') ?? 0).toInt();
    } catch (_) {}
    return cnt;
  }
}

/// Initial Cloud Entity Scanners
class AccountInitialCloudScanner implements InitialCloudEntityScanner {
  @override
  String get entityType => 'account';
  @override
  int get priorityOrder => 1;

  @override
  Future<List<SyncOperation>> scanInitialOperations({
    required Ref ref,
    required String companyId,
    required String deviceId,
  }) async {
    final db = ref.read(accountingDatabaseProvider);
    final rows = await (db.select(db.accounts)..where((t) => t.companyId.equals(companyId))).get();
    final ops = <SyncOperation>[];
    final repo = ref.read(accountRepositoryProvider);

    for (final row in rows) {
      final acc = await repo.getByUuid(row.uuid);
      if (acc != null) {
        String? parentAccountCode;
        if (acc.parentId != null) {
          final p = await repo.getByUuid(acc.parentId!);
          parentAccountCode = p?.accountCode;
        }
        ops.add(SyncOperation.create(
          entityType: 'account',
          entityId: acc.uuid,
          type: SyncOperationType.create,
          payload: {
            'uuid': acc.uuid,
            'parentId': acc.parentId,
            'parentAccountCode': parentAccountCode,
            'accountCode': acc.accountCode,
            'name': acc.name,
            'description': acc.description,
            'accountType': acc.accountType.storageValue,
            'normalBalance': acc.normalBalance.storageValue,
            'level': acc.level,
            'isGroup': acc.isGroup,
            'isActive': acc.isActive,
            'isSystemAccount': acc.isSystemAccount,
            'version': acc.version,
            'updatedAt': acc.updatedAt.toUtc().millisecondsSinceEpoch,
            'deletedAt': acc.deletedAt?.toUtc().millisecondsSinceEpoch,
          },
          baseVersion: acc.version,
          companyId: companyId,
          deviceId: deviceId,
        ));
      }
    }
    return ops;
  }
}

class CustomerInitialCloudScanner implements InitialCloudEntityScanner {
  @override
  String get entityType => 'customer';
  @override
  int get priorityOrder => 1;

  @override
  Future<List<SyncOperation>> scanInitialOperations({
    required Ref ref,
    required String companyId,
    required String deviceId,
  }) async {
    final db = ref.read(customersDatabaseProvider);
    final rows = await (db.select(db.customers)..where((t) => t.companyId.equals(companyId))).get();
    final ops = <SyncOperation>[];
    final repo = ref.read(customerRepositoryProvider);

    for (final row in rows) {
      final cust = await repo.getByUuid(row.uuid);
      if (cust != null) {
        ops.add(SyncOperation.create(
          entityType: 'customer',
          entityId: cust.uuid,
          type: SyncOperationType.create,
          payload: {
            'uuid': cust.uuid,
            'customerCode': cust.customerCode,
            'name': cust.name,
            'phone': cust.phone,
            'email': cust.email,
            'address': cust.address,
            'notes': cust.notes,
            'isActive': cust.isActive,
            'accountId': cust.accountId,
            'externalId': cust.externalId,
            'dataSource': cust.dataSource.storageValue,
            'version': cust.version,
            'updatedAt': cust.updatedAt.toUtc().millisecondsSinceEpoch,
            'deletedAt': cust.deletedAt?.toUtc().millisecondsSinceEpoch,
          },
          baseVersion: cust.version,
          companyId: companyId,
          deviceId: deviceId,
        ));
      }
    }
    return ops;
  }
}

class ProductInitialCloudScanner implements InitialCloudEntityScanner {
  @override
  String get entityType => 'product';
  @override
  int get priorityOrder => 1;

  @override
  Future<List<SyncOperation>> scanInitialOperations({
    required Ref ref,
    required String companyId,
    required String deviceId,
  }) async {
    final db = ref.read(inventoryDatabaseProvider);
    final rows = await (db.select(db.products)..where((t) => t.companyId.equals(companyId))).get();
    final ops = <SyncOperation>[];
    final repo = ref.read(productRepositoryProvider);

    for (final row in rows) {
      final prod = await repo.getByUuid(row.uuid);
      if (prod != null) {
        ops.add(SyncOperation.create(
          entityType: 'product',
          entityId: prod.uuid,
          type: SyncOperationType.create,
          payload: {
            'uuid': prod.uuid,
            'itemCode': prod.itemCode,
            'name': prod.name,
            'barcode': prod.barcode,
            'packSize': prod.packSize,
            'price': prod.price,
            'onHandQty': prod.onHandQty,
            'unitCost': prod.unitCost,
            'version': prod.version,
            'updatedAt': prod.updatedAt.toUtc().millisecondsSinceEpoch,
            'deletedAt': prod.deletedAt?.toUtc().millisecondsSinceEpoch,
          },
          baseVersion: prod.version,
          companyId: companyId,
          deviceId: deviceId,
        ));
      }
    }
    return ops;
  }
}

class SaleInitialCloudScanner implements InitialCloudEntityScanner {
  @override
  String get entityType => 'sale';
  @override
  int get priorityOrder => 2;

  @override
  Future<List<SyncOperation>> scanInitialOperations({
    required Ref ref,
    required String companyId,
    required String deviceId,
  }) async {
    final db = ref.read(salesDatabaseProvider);
    final rows = await (db.select(db.sales)..where((t) => t.companyId.equals(companyId))).get();
    final ops = <SyncOperation>[];
    final repo = ref.read(saleRepositoryProvider);

    for (final row in rows) {
      final s = await repo.getByUuid(row.uuid);
      if (s != null) {
        ops.add(SyncOperation.create(
          entityType: 'sale',
          entityId: s.uuid,
          type: SyncOperationType.create,
          payload: {
            'uuid': s.uuid,
            'saleNumber': s.saleNumber,
            'saleDate': s.saleDate.toUtc().millisecondsSinceEpoch,
            'settlementType': s.settlementType.storageValue,
            'voucherBookId': s.voucherBookId,
            'customerId': s.customerId,
            'customerCode': s.customerCode,
            'customerName': s.customerName,
            'customerAccountId': s.customerAccountId,
            'cashAccountId': s.cashAccountId,
            'currencyCode': s.currencyCode,
            'baseCurrencyCode': s.baseCurrencyCode,
            'exchangeRate': s.exchangeRate,
            'subtotal': s.subtotal,
            'itemDiscountTotal': s.itemDiscountTotal,
            'discountType': s.discountType.storageValue,
            'discountValue': s.discountValue,
            'discountAmount': s.discountAmount,
            'taxRate': s.taxRate,
            'taxAmount': s.taxAmount,
            'total': s.total,
            'paidAmount': s.paidAmount,
            'remainingAmount': s.remainingAmount,
            'paymentStatus': s.paymentStatus.storageValue,
            'paymentMethod': s.paymentMethod.storageValue,
            'saleStatus': s.saleStatus.storageValue,
            'notes': s.notes,
            'createdAt': s.createdAt.toUtc().millisecondsSinceEpoch,
            'updatedAt': s.updatedAt.toUtc().millisecondsSinceEpoch,
            'version': s.version,
            'items': [
              for (final item in s.items)
                {
                  'uuid': item.uuid,
                  'productId': item.productId,
                  'productName': item.productName,
                  'productCode': item.productCode,
                  'barcode': item.barcode,
                  'quantity': item.quantity,
                  'mainQuantity': item.mainQuantity,
                  'subQuantity': item.subQuantity,
                  'packSize': item.packSize,
                  'unitPrice': item.unitPrice,
                  'baseUnitPrice': item.baseUnitPrice,
                  'discountType': item.discountType.storageValue,
                  'discountValue': item.discountValue,
                  'discountAmount': item.discountAmount,
                  'taxAmount': item.taxAmount,
                  'subtotal': item.subtotal,
                  'total': item.total,
                  'lineOrder': item.lineOrder,
                }
            ],
            'payments': [
              for (final payment in s.payments)
                {
                  'uuid': payment.uuid,
                  'amount': payment.amount,
                  'method': payment.method.storageValue,
                  'paidAt': payment.paidAt.toUtc().millisecondsSinceEpoch,
                  'createdAt': payment.createdAt.toUtc().millisecondsSinceEpoch,
                  'notes': payment.notes,
                  'externalId': payment.externalId,
                },
            ],
          },
          baseVersion: s.version,
          companyId: companyId,
          deviceId: deviceId,
        ));
      }
    }
    return ops;
  }
}

class FinancialTransactionInitialCloudScanner implements InitialCloudEntityScanner {
  @override
  String get entityType => 'financial_transaction';
  @override
  int get priorityOrder => 2;

  @override
  Future<List<SyncOperation>> scanInitialOperations({
    required Ref ref,
    required String companyId,
    required String deviceId,
  }) async {
    final db = ref.read(receiptsPaymentsDatabaseProvider);
    final rows = await (db.select(db.financialTransactions)..where((t) => t.companyId.equals(companyId))).get();
    final ops = <SyncOperation>[];
    final repo = ref.read(financialTransactionRepositoryProvider);

    for (final row in rows) {
      final tx = await repo.getByUuid(row.uuid);
      if (tx != null) {
        ops.add(SyncOperation.create(
          entityType: 'financial_transaction',
          entityId: tx.uuid,
          type: SyncOperationType.create,
          payload: {
            'uuid': tx.uuid,
            'transactionNumber': tx.transactionNumber,
            'transactionType': tx.transactionType.storageValue,
            'source': tx.source.storageValue,
            'transactionDate': tx.transactionDate.toUtc().millisecondsSinceEpoch,
            'amount': tx.amount,
            'currencyCode': tx.currencyCode,
            'baseCurrencyCode': tx.baseCurrencyCode,
            'exchangeRate': tx.exchangeRate,
            'counterAmount': tx.counterAmount,
            'counterCurrencyCode': tx.counterCurrencyCode,
            'counterExchangeRate': tx.counterExchangeRate,
            'voucherBookId': tx.voucherBookId,
            'cashAccountId': tx.cashAccountId,
            'cashAccountCode': tx.cashAccountCode,
            'cashAccountName': tx.cashAccountName,
            'counterAccountId': tx.counterAccountId,
            'counterAccountCode': tx.counterAccountCode,
            'counterAccountName': tx.counterAccountName,
            'customerId': tx.customerId,
            'customerCode': tx.customerCode,
            'customerName': tx.customerName,
            'partyName': tx.partyName,
            'reference': tx.reference,
            'description': tx.description,
            'paymentMethod': tx.paymentMethod.storageValue,
            'documentStatus': tx.documentStatus.storageValue,
            'relatedDocumentId': tx.relatedDocumentId,
            'relatedDocumentType': tx.relatedDocumentType,
            'cancelledAt': tx.cancelledAt?.toUtc().millisecondsSinceEpoch,
            'version': tx.version,
            'updatedAt': tx.updatedAt.toUtc().millisecondsSinceEpoch,
            'lines': [for (final line in tx.resolvedLines) line.toJson()],
          },
          baseVersion: tx.version,
          companyId: companyId,
          deviceId: deviceId,
        ));
      }
    }
    return ops;
  }
}

class JournalEntryInitialCloudScanner implements InitialCloudEntityScanner {
  @override
  String get entityType => 'journal_entry';
  @override
  int get priorityOrder => 3;

  @override
  Future<List<SyncOperation>> scanInitialOperations({
    required Ref ref,
    required String companyId,
    required String deviceId,
  }) async {
    final db = ref.read(accountingDatabaseProvider);
    final rows = await (db.select(db.journalEntries)..where((t) => t.companyId.equals(companyId))).get();
    final ops = <SyncOperation>[];
    final repo = ref.read(journalRepositoryProvider);
    final accRepo = ref.read(accountRepositoryProvider);

    for (final row in rows) {
      final entry = await repo.getByUuid(row.uuid);
      if (entry != null) {
        final linesPayload = <Map<String, dynamic>>[];
        for (final line in entry.lines) {
          final account = await accRepo.getByUuid(line.accountUuid);
          linesPayload.add({
            'uuid': line.uuid,
            'accountUuid': line.accountUuid,
            'accountCode': account?.accountCode,
            'debit': line.debit,
            'credit': line.credit,
            'exchangeRateToBase': line.exchangeRateToBase,
            'baseDebit': line.baseDebit,
            'baseCredit': line.baseCredit,
            'currencyCode': line.currencyCode,
            'lineDescription': line.lineDescription,
            'sortOrder': line.sortOrder,
          });
        }
        ops.add(SyncOperation.create(
          entityType: 'journal_entry',
          entityId: entry.uuid,
          type: SyncOperationType.create,
          payload: {
            'uuid': entry.uuid,
            'entryDate': entry.entryDate.toUtc().millisecondsSinceEpoch,
            'voucherNumber': entry.voucherNumber,
            'voucherType': entry.voucherType,
            'description': entry.description,
            'currencyCode': entry.currencyCode,
            'isPosted': entry.isPosted,
            'sourceType': entry.sourceType,
            'sourceId': entry.sourceId,
            'lines': linesPayload,
            'version': entry.version,
            'updatedAt': entry.updatedAt.toUtc().millisecondsSinceEpoch,
            'createdAt': entry.createdAt.toUtc().millisecondsSinceEpoch,
            'deletedAt': entry.deletedAt?.toUtc().millisecondsSinceEpoch,
          },
          baseVersion: entry.version,
          companyId: companyId,
          deviceId: deviceId,
        ));
      }
    }
    return ops;
  }
}
