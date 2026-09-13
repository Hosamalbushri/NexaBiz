import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/repositories/journal_repository.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import '../repositories/cash_register_repository.dart';
import 'cash_register_posting_resolver_service.dart';

/// Result of an inter-register transfer operation.
class CashMovementTransferResult {
  const CashMovementTransferResult({
    required this.isSuccess,
    this.journalEntry,
    this.errorCode,
    this.message,
  });

  final bool isSuccess;
  final JournalEntry? journalEntry;
  final String? errorCode;
  final String? message;
}

/// Domain service providing authoritative ledger balance calculation,
/// atomic inter-register transfers, negative balance validation, and reversal integrity.
class CashRegisterMovementService {
  const CashRegisterMovementService({
    required this.cashRegisterRepository,
    required this.accountRepository,
    required this.journalRepository,
    required this.postingResolver,
    required this.journalPostingService,
  });

  final CashRegisterRepository cashRegisterRepository;
  final AccountRepository accountRepository;
  final JournalRepository journalRepository;
  final CashRegisterPostingResolverService postingResolver;
  final JournalPostingService journalPostingService;

  /// Authoritatively resolves current cash balance from Chart of Accounts.
  /// Dynamic ledger derivation guarantees zero drift between Cash Registers and GL.
  Future<double> getLedgerBalance({
    required String registerId,
    required String companyId,
  }) async {
    final register = await cashRegisterRepository.getCashRegisterById(
      registerId.trim(),
    );
    if (register == null ||
        !register.isActive ||
        !register.isLinked ||
        register.companyId != companyId.trim()) {
      return 0.0;
    }

    final accountId = register.accountingAccountId!;
    final account =
        await accountRepository.getByUuid(accountId) ??
        await accountRepository.getByAccountCode(accountId);
    if (account == null || !account.isActive || account.isDeleted) {
      return 0.0;
    }

    // Dynamic ledger calculation: query movements from JournalRepository
    final movements = await journalRepository.listMovementsForAccount(
      accountUuid: account.id,
    );

    double totalDebit = 0.0;
    double totalCredit = 0.0;

    for (final mov in movements) {
      if (mov.isPosted) {
        totalDebit += mov.debit;
        totalCredit += mov.credit;
      }
    }

    // Cash asset account: balance = debit - credit
    return totalDebit - totalCredit;
  }

  /// Executes an atomic inter-register cash transfer.
  /// Guarantees that source credit and destination debit are posted in a single
  /// balanced journal entry, avoiding partial transfers.
  Future<CashMovementTransferResult> executeTransfer({
    required String companyId,
    required String sourceRegisterId,
    required String destinationRegisterId,
    required double amount,
    required String referenceId,
    String? description,
    String currencyCode = 'YER',
    bool allowNegativeBalance = false,
  }) async {
    final trimmedCompany = companyId.trim();
    if (trimmedCompany.isEmpty) {
      return const CashMovementTransferResult(
        isSuccess: false,
        errorCode: 'INVALID_COMPANY',
        message: 'Company ID cannot be empty',
      );
    }

    if (sourceRegisterId.trim() == destinationRegisterId.trim()) {
      return const CashMovementTransferResult(
        isSuccess: false,
        errorCode: 'SAME_REGISTER_TRANSFER',
        message: 'Source and destination registers must be different',
      );
    }

    if (amount <= 0) {
      return const CashMovementTransferResult(
        isSuccess: false,
        errorCode: 'INVALID_AMOUNT',
        message: 'Transfer amount must be positive',
      );
    }

    // Resolve source register & account
    final sourceRes = await postingResolver.resolveAccountForPosting(
      companyId: trimmedCompany,
      registerId: sourceRegisterId,
    );
    if (!sourceRes.isSuccess ||
        sourceRes.account == null ||
        sourceRes.register == null) {
      return CashMovementTransferResult(
        isSuccess: false,
        errorCode: 'SOURCE_${sourceRes.errorCode}',
        message: 'Source register error: ${sourceRes.message}',
      );
    }

    // Resolve destination register & account
    final destRes = await postingResolver.resolveAccountForPosting(
      companyId: trimmedCompany,
      registerId: destinationRegisterId,
    );
    if (!destRes.isSuccess ||
        destRes.account == null ||
        destRes.register == null) {
      return CashMovementTransferResult(
        isSuccess: false,
        errorCode: 'DEST_${destRes.errorCode}',
        message: 'Destination register error: ${destRes.message}',
      );
    }

    // Negative balance check (if forbidden)
    if (!allowNegativeBalance) {
      final currentBalance = await getLedgerBalance(
        registerId: sourceRegisterId,
        companyId: trimmedCompany,
      );
      if (currentBalance < amount) {
        return CashMovementTransferResult(
          isSuccess: false,
          errorCode: 'INSUFFICIENT_BALANCE',
          message:
              'Insufficient balance ($currentBalance) for transfer amount $amount',
        );
      }
    }

    // Build single atomic balanced journal entry
    final transferDescription = description?.trim().isNotEmpty == true
        ? description!.trim()
        : 'تحويل نقدي من ${sourceRes.register!.name} إلى ${destRes.register!.name}';

    final draft = JournalEntryDraft(
      entryDate: DateTime.now(),
      voucherNumber: 'TRF-$referenceId',
      voucherType: 'CASH_TRANSFER',
      currencyCode: currencyCode.trim().toUpperCase(),
      description: transferDescription,
      sourceType: 'cash_transfer',
      sourceId: referenceId.trim(),
      isPosted: true,
      lines: [
        // Destination Debit (Increase destination cash box)
        JournalLineDraft(
          accountUuid: destRes.account!.id,
          debit: amount,
          credit: 0.0,
          currencyCode: currencyCode.trim().toUpperCase(),
          lineDescription: 'استلام تحويل نقدي من ${sourceRes.register!.name}',
          sortOrder: 1,
        ),
        // Source Credit (Decrease source cash box)
        JournalLineDraft(
          accountUuid: sourceRes.account!.id,
          debit: 0.0,
          credit: amount,
          currencyCode: currencyCode.trim().toUpperCase(),
          lineDescription: 'تحويل نقدي إلى ${destRes.register!.name}',
          sortOrder: 2,
        ),
      ],
    );

    try {
      final entry = await journalPostingService.post(draft);
      return CashMovementTransferResult(isSuccess: true, journalEntry: entry);
    } catch (e) {
      return CashMovementTransferResult(
        isSuccess: false,
        errorCode: 'POSTING_FAILED',
        message: 'Failed to post transfer journal entry: $e',
      );
    }
  }

  /// Reverses an existing posted cash movement by creating an explicit offsetting journal entry.
  Future<bool> reverseMovement({
    required String sourceType,
    required String sourceId,
  }) async {
    try {
      await journalPostingService.voidBySource(
        sourceType: sourceType.trim(),
        sourceId: sourceId.trim(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
