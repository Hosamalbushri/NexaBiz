import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:stock_count/app/receipts_payments/accounting_rp_voucher_book_adapter.dart';
import 'package:stock_count/modules/accounting/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/data/repositories/voucher_book_repository_impl.dart';
import 'package:stock_count/modules/receipts_payments/data/database/receipts_payments_database.dart';
import 'package:stock_count/modules/receipts_payments/data/repositories/financial_transaction_repository_impl.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/financial_transaction.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/financial_transaction_line.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/rp_payment_method.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/transaction_source.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/transaction_type.dart';
import 'package:stock_count/modules/receipts_payments/domain/services/rp_ledger_posting_port.dart';
import 'package:stock_count/modules/receipts_payments/domain/usecases/financial_transaction_usecases.dart';
import 'package:stock_count/modules/sales/data/sale_number_block_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('payment after receipt can share device-lane sequence per book', () async {
    final dir = await Directory.systemTemp.createTemp('rp_number_collision');
    Hive.init(dir.path);
    final box = await Hive.openBox<dynamic>('settings_rp_number_collision');
    await box.clear();

    final accountingDb = AccountingDatabase.memory();
    final voucherBooks = VoucherBookRepositoryImpl(accountingDb);
    await voucherBooks.ensureDefaultSections();
    final books = AccountingRpVoucherBookAdapter(
      voucherBooks,
      deviceId: '00000000-0000-4000-8000-0000000000a1',
      blockStore: SaleNumberBlockStore(box: box),
    );

    final rpDb = ReceiptsPaymentsDatabase.memory();
    final repo = FinancialTransactionRepositoryImpl(rpDb);
    final create = CreateFinancialTransaction(
      repository: repo,
      voucherBookPort: books,
      ledgerPosting: const NoOpRpLedgerPostingPort(),
    );

    final receiptBooks = await books.listActiveBooks(TransactionType.receipt);
    final paymentBooks = await books.listActiveBooks(TransactionType.payment);
    expect(receiptBooks, isNotEmpty);
    expect(paymentBooks, isNotEmpty);

    FinancialTransactionDraft draft({
      required TransactionType type,
      required String bookId,
    }) {
      return FinancialTransactionDraft(
        transactionType: type,
        source: type.isReceipt
            ? TransactionSource.manualReceipt
            : TransactionSource.manualPayment,
        transactionDate: DateTime.utc(2026, 8, 16),
        amount: 100,
        currencyCode: 'SAR',
        baseCurrencyCode: 'SAR',
        exchangeRate: 1,
        counterAmount: 100,
        counterCurrencyCode: 'SAR',
        counterExchangeRate: 1,
        voucherBookId: bookId,
        cashAccountId: '11111111-1111-4111-8111-111111111111',
        cashAccountCode: '1211',
        cashAccountName: 'Cash',
        counterAccountId: '22222222-2222-4222-8222-222222222222',
        counterAccountCode: '5100',
        counterAccountName: 'Expense',
        paymentMethod: RpPaymentMethod.cash,
        description: 'test',
        lines: const [
          FinancialTransactionLine(
            accountId: '22222222-2222-4222-8222-222222222222',
            accountCode: '5100',
            accountName: 'Expense',
            amount: 100,
            currencyCode: 'SAR',
            exchangeRate: 1,
            lineOrder: 0,
          ),
        ],
      );
    }

    final receipt = await create(
      draft(type: TransactionType.receipt, bookId: receiptBooks.first.bookId),
    );

    final payment = await create(
      draft(type: TransactionType.payment, bookId: paymentBooks.first.bookId),
    );

    // Same device lane + first sequence in each book → same absolute number.
    expect(payment.transactionNumber, receipt.transactionNumber);

    await rpDb.close();
    await accountingDb.close();
    await box.close();
    await dir.delete(recursive: true);
  });
}
