import '../entities/journal_entry.dart';
import '../models/journal_exception.dart';
import '../repositories/journal_repository.dart';
import 'package:stock_count/core/audit/domain/services/audit_trail_service.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/accounting_period_validator.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/modules/accounting/permissions/accounting_permissions.dart';


/// Application entry point for posting / voiding journals.
///
/// Period checks also run inside [JournalRepository.post]; this service adds
/// reverse-on-void for posted entries so product features never soft-delete
/// posted ledgers.
class JournalPostingService {
  const JournalPostingService({
    required JournalRepository journals,
    required AccountingPeriodValidator periodValidator,
    PermissionGuard permissionGuard = const AllowAllPermissionGuard(),
    AuditTrailService? auditService,
  })  : _journals = journals,
        _periodValidator = periodValidator,
        _permissionGuard = permissionGuard,
        _auditService = auditService;

  /// Source type for reversing journals (`sourceId` = original entry UUID).
  static const reverseSourceType = 'journal_reverse';

  final JournalRepository _journals;
  final AccountingPeriodValidator _periodValidator;
  final PermissionGuard _permissionGuard;
  final AuditTrailService? _auditService;

  Future<JournalEntry?> findBySource({
    required String sourceType,
    required String sourceId,
  }) =>
      _journals.findBySource(
        sourceType: sourceType,
        sourceId: sourceId,
      );

  Future<JournalEntry> post(JournalEntryDraft draft, {String? userId}) async {
    try {
      _permissionGuard.requireAny(AccountingPermissions.journalsPost);
    } on PermissionDeniedException catch (e) {
      await _auditService?.recordEvent(
        documentId: draft.uuid ?? draft.voucherNumber,
        documentType: 'journal_entry',
        eventType: 'unauthorized_attempt',
        userId: userId,
        notes: 'مرفوض: لا تملك صلاحية ترحيل القيود',
        metadata: {
          'operation': 'post',
          'voucherNumber': draft.voucherNumber,
          'errorReason': e.toString(),
        },
      );
      rethrow;
    }

    try {
      await _periodValidator.assertEntryAllowed(draft.entryDate);
    } on JournalException catch (e) {
      await _auditService?.recordEvent(
        documentId: draft.uuid ?? draft.voucherNumber,
        documentType: 'journal_entry',
        eventType: 'unauthorized_attempt',
        userId: userId,
        notes: 'الفترة المحاسبية مغلقة للقيد (${e.message})',
        metadata: {
          'operation': 'post',
          'voucherNumber': draft.voucherNumber,
          'errorReason': e.message,
          'attemptedDate': draft.entryDate.toIso8601String(),
        },
      );
      rethrow;
    }


    final posted = await _journals.post(draft);

    await _auditService?.recordEvent(
      documentId: posted.uuid,
      documentType: 'journal_entry',
      eventType: draft.sourceType == reverseSourceType ? 'reverse' : 'post',
      userId: userId,
      metadata: {
        'voucherNumber': posted.voucherNumber,
        'voucherType': posted.voucherType,
        'isPosted': posted.isPosted,
        'lineCount': posted.lines.length,
        'before': {'status': 'draft'},
        'after': {'status': 'posted'},
      },
    );

    return posted;
  }

  /// Voids a journal: tombstones draft entries; reverses posted entries via offsetting entry.
  Future<void> voidByUuid(String uuid) async {
    final existing = await _journals.getByUuid(uuid);
    if (existing == null) {
      return;
    }
    await _periodValidator.assertEntryAllowed(existing.entryDate);
    if (!existing.isPosted) {
      await _journals.softDeleteByUuid(uuid);
      return;
    }
    await reverseByUuid(existing.uuid);
  }

  /// Voids the active journal for a business document (sale, R&P, …).
  Future<void> voidBySource({
    required String sourceType,
    required String sourceId,
  }) async {
    final existing = await _journals.findBySource(
      sourceType: sourceType,
      sourceId: sourceId,
    );
    if (existing == null) {
      return;
    }
    await _periodValidator.assertEntryAllowed(existing.entryDate);
    if (!existing.isPosted) {
      await _journals.softDeleteBySource(
        sourceType: sourceType,
        sourceId: sourceId,
      );
      return;
    }
    await reverseByUuid(existing.uuid);
  }

  /// Posts a reversing entry for a posted journal (swap debit/credit).
  Future<JournalEntry> reverseByUuid(
    String uuid, {
    DateTime? reverseDate,
  }) async {
    _permissionGuard.requireAny(AccountingPermissions.journalsReverse);

    final existing = await _journals.getByUuid(uuid.trim());
    if (existing == null) {
      throw const JournalException(JournalException.notFound);
    }
    if (!existing.isPosted) {
      throw const JournalException(JournalException.notPosted);
    }


    final already = await _journals.findBySource(
      sourceType: reverseSourceType,
      sourceId: existing.uuid,
    );
    if (already != null) {
      return already;
    }

    final entryDate = reverseDate ?? existing.entryDate;
    try {
      await _periodValidator.assertMutationAllowed(
        entryDate: entryDate,
        originalDate: existing.entryDate,
      );
    } on JournalException catch (e) {
      await _auditService?.recordEvent(
        documentId: existing.uuid,
        documentType: 'journal_entry',
        eventType: 'unauthorized_attempt',
        notes: 'عكس القيد مرفوض بسبب الفترة المحاسبية (${e.message})',
        metadata: {
          'operation': 'reverse',
          'originalTransactionId': existing.uuid,
          'errorReason': e.message,
          'attemptedDate': entryDate.toIso8601String(),
        },
      );
      rethrow;
    }

    final description = existing.description?.trim();
    final reverseDescription = (description == null || description.isEmpty)
        ? 'عكس قيد ${existing.voucherNumber}'
        : 'عكس: $description';

    final reversal = await _journals.post(
      JournalEntryDraft(
        entryDate: entryDate,
        voucherNumber: '${existing.voucherNumber}-R',
        voucherType: existing.voucherType,
        currencyCode: existing.currencyCode,
        baseCurrencyCode: existing.currencyCode,
        description: reverseDescription,
        isPosted: true,
        sourceType: reverseSourceType,
        sourceId: existing.uuid,
        lines: [
          for (final line in existing.lines)
            JournalLineDraft(
              accountUuid: line.accountUuid,
              debit: line.credit,
              credit: line.debit,
              currencyCode: line.currencyCode,
              exchangeRateToBase: line.exchangeRateToBase,
              baseDebit: line.baseCredit,
              baseCredit: line.baseDebit,
              lineDescription: line.lineDescription,
              sortOrder: line.sortOrder,
            ),
        ],
      ),
    );

    await _auditService?.recordEvent(
      documentId: reversal.uuid,
      documentType: 'journal_entry',
      eventType: 'reverse',
      notes: reverseDescription,
      metadata: {
        'originalTransactionId': existing.uuid,
        'reversalTransactionId': reversal.uuid,
        'originalVoucher': existing.voucherNumber,
        'reversalVoucher': reversal.voucherNumber,
        'before': {'status': 'posted', 'voucherNumber': existing.voucherNumber},
        'after': {'status': 'posted', 'voucherNumber': reversal.voucherNumber},
      },
    );

    return reversal;
  }

  @Deprecated('Use voidBySource — soft-delete of posted journals is blocked')
  Future<void> softDeleteBySource({
    required String sourceType,
    required String sourceId,
  }) =>
      voidBySource(sourceType: sourceType, sourceId: sourceId);

  @Deprecated('Use voidByUuid — soft-delete of posted journals is blocked')
  Future<void> softDeleteByUuid(String uuid) => voidByUuid(uuid);
}
