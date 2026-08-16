import '../entities/financial_transaction.dart';
import '../entities/transaction_status.dart';
import '../models/financial_transaction_exception.dart';

class FinancialTransactionWorkflow {
  const FinancialTransactionWorkflow();

  void assertCanEdit(FinancialTransaction txn) {
    if (txn.isCancelled || !txn.documentStatus.isEditable) {
      throw const FinancialTransactionException(
        FinancialTransactionException.notEditable,
      );
    }
  }

  void assertCanPost(FinancialTransaction txn) {
    if (txn.isCancelled || !txn.documentStatus.canPost) {
      throw const FinancialTransactionException(
        FinancialTransactionException.cannotPost,
      );
    }
  }

  void assertCanCancel(FinancialTransaction txn) {
    if (txn.isCancelled) {
      throw const FinancialTransactionException(
        FinancialTransactionException.alreadyCancelled,
      );
    }
    if (!txn.documentStatus.canCancel) {
      throw const FinancialTransactionException(
        FinancialTransactionException.cannotCancel,
      );
    }
  }
}
