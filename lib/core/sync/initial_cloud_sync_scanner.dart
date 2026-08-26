import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../modules/accounting/presentation/providers/account_providers.dart';
import '../../modules/accounting/presentation/providers/journal_providers.dart';
import '../../modules/customers/presentation/providers/customer_providers.dart';
import '../../modules/inventory/presentation/providers/product_providers.dart';
import '../../modules/sales/presentation/providers/sale_providers.dart';
import '../../modules/receipts_payments/presentation/providers/rp_providers.dart';
import 'sync_providers.dart';

import '../../modules/sales/domain/entities/discount_type.dart';
import '../../modules/sales/domain/entities/payment_method.dart';
import '../../modules/sales/domain/entities/payment_status.dart';
import '../../modules/sales/domain/entities/sale_settlement_type.dart';
import '../../modules/sales/domain/entities/sale_status.dart';
import '../../modules/customers/domain/entities/customer_data_source.dart';
import '../../modules/receipts_payments/domain/entities/rp_payment_method.dart';
import '../../modules/receipts_payments/domain/entities/transaction_status.dart';
import '../../modules/receipts_payments/domain/entities/transaction_source.dart';
import '../../modules/receipts_payments/domain/entities/transaction_type.dart';

import '../network/remote_sync_api.dart';
import 'sync_operation.dart';
import 'sync_queue.dart';
import 'sync_status.dart';

enum MigrationStatus {
  notStarted,
  scanning,
  uploading,
  verifying,
  completed,
  failedRetryable,
  failedPermanent,
}

class MigrationProgress {
  const MigrationProgress({
    required this.status,
    required this.processedCount,
    required this.totalCount,
    this.errorMessage,
  });

  final MigrationStatus status;
  final int processedCount;
  final int totalCount;
  final String? errorMessage;
}

class InitialCloudSyncScanner {
  InitialCloudSyncScanner(this._ref, {RemoteSyncApi Function()? remoteProvider})
      : _remoteProvider = remoteProvider;

  final Ref _ref;
  final RemoteSyncApi Function()? _remoteProvider;

  final _controller = StreamController<MigrationProgress>.broadcast();
  Stream<MigrationProgress> get progress => _controller.stream;

  RemoteSyncApi get _remote => _remoteProvider?.call() ?? _ref.read(remoteSyncApiProvider);

  Future<void> runMigration({
    required String companyId,
    required String deviceId,
    required SyncQueue queue,
  }) async {
    _controller.add(const MigrationProgress(
      status: MigrationStatus.scanning,
      processedCount: 0,
      totalCount: 0,
    ));

    try {
      final accountsDb = _ref.read(accountingDatabaseProvider);
      final inventoryDb = _ref.read(inventoryDatabaseProvider);
      final customersDb = _ref.read(customersDatabaseProvider);
      final salesDb = _ref.read(salesDatabaseProvider);
      final receiptsDb = _ref.read(receiptsPaymentsDatabaseProvider);

      // Gather all entity IDs for this company
      final accounts = await (accountsDb.select(accountsDb.accounts)
            ..where((t) => t.companyId.equals(companyId)))
          .get();

      final journalEntries = await (accountsDb.select(accountsDb.journalEntries)
            ..where((t) => t.companyId.equals(companyId)))
          .get();

      final products = await (inventoryDb.select(inventoryDb.products)
            ..where((t) => t.companyId.equals(companyId)))
          .get();

      final customers = await (customersDb.select(customersDb.customers)
            ..where((t) => t.companyId.equals(companyId)))
          .get();

      final sales = await (salesDb.select(salesDb.sales)
            ..where((t) => t.companyId.equals(companyId)))
          .get();

      final financialTxns = await (receiptsDb.select(receiptsDb.financialTransactions)
            ..where((t) => t.companyId.equals(companyId)))
          .get();

      final totalItems = accounts.length +
          journalEntries.length +
          products.length +
          customers.length +
          sales.length +
          financialTxns.length;

      _controller.add(MigrationProgress(
        status: MigrationStatus.uploading,
        processedCount: 0,
        totalCount: totalItems,
      ));

      var processed = 0;

      // Helper to process a record
      Future<void> processRecord({
        required String entityType,
        required String entityId,
        required Map<String, dynamic> payload,
        required int version,
      }) async {
        // Idempotency check: see if remote server has it
        final meta = await _remote.getMeta(entityType: entityType, entityId: entityId);
        if (meta == null) {
          // Server doesn't have it, enqueue a create operation
          final op = SyncOperation.create(
            entityType: entityType,
            entityId: entityId,
            type: SyncOperationType.create,
            payload: payload,
            baseVersion: version,
            companyId: companyId,
            deviceId: deviceId,
          );
          await queue.enqueue(op);
        }
        processed++;
        _controller.add(MigrationProgress(
          status: MigrationStatus.uploading,
          processedCount: processed,
          totalCount: totalItems,
        ));
      }

      // Priority ordering (topological dependencies)
      // Category 1: Accounts, Customers, Products
      for (final row in accounts) {
        final acc = await _ref.read(accountRepositoryProvider).getByUuid(row.uuid);
        if (acc != null) {
          String? parentAccountCode;
          if (acc.parentId != null) {
            final p = await _ref.read(accountRepositoryProvider).getByUuid(acc.parentId!);
            parentAccountCode = p?.accountCode;
          }
          await processRecord(
            entityType: 'account',
            entityId: acc.uuid,
            version: acc.version,
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
          );
        }
      }

      for (final row in customers) {
        final cust = await _ref.read(customerRepositoryProvider).getByUuid(row.uuid);
        if (cust != null) {
          await processRecord(
            entityType: 'customer',
            entityId: cust.uuid,
            version: cust.version,
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
          );
        }
      }

      for (final row in products) {
        final prod = await _ref.read(productRepositoryProvider).getByUuid(row.uuid);
        if (prod != null) {
          await processRecord(
            entityType: 'product',
            entityId: prod.uuid,
            version: prod.version,
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
          );
        }
      }

      // Category 2: Sales, Financial Transactions
      for (final row in sales) {
        final s = await _ref.read(saleRepositoryProvider).getByUuid(row.uuid);
        if (s != null) {
          await processRecord(
            entityType: 'sale',
            entityId: s.uuid,
            version: s.version,
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
          );
        }
      }

      for (final row in financialTxns) {
        final tx = await _ref.read(financialTransactionRepositoryProvider).getByUuid(row.uuid);
        if (tx != null) {
          await processRecord(
            entityType: 'financial_transaction',
            entityId: tx.uuid,
            version: tx.version,
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
          );
        }
      }

      // Category 3: Journal Entries (Accounting Ledger)
      for (final row in journalEntries) {
        final entry = await _ref.read(journalRepositoryProvider).getByUuid(row.uuid);
        if (entry != null) {
          final linesPayload = <Map<String, dynamic>>[];
          for (final line in entry.lines) {
            final account = await _ref.read(accountRepositoryProvider).getByUuid(line.accountUuid);
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
          await processRecord(
            entityType: 'journal_entry',
            entityId: entry.uuid,
            version: entry.version,
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
          );
        }
      }

      _controller.add(MigrationProgress(
        status: MigrationStatus.completed,
        processedCount: processed,
        totalCount: totalItems,
      ));
    } catch (e) {
      _controller.add(MigrationProgress(
        status: MigrationStatus.failedRetryable,
        processedCount: 0,
        totalCount: 0,
        errorMessage: e.toString(),
      ));
    }
  }

  void dispose() {
    _controller.close();
  }
}
