import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/core/domain/entities/document_ref.dart';
import 'package:stock_count/core/domain/ports/posting_port.dart';
import 'account_mapping_resolver.dart';
import 'account_validation_service.dart';

import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';

class AccountingEntryBuilder {
  AccountingEntryBuilder({
    required this._mappingResolver,
    required this._validationService,
    this._initRepository,
  });

  final AccountMappingResolver _mappingResolver;
  final AccountValidationService _validationService;
  final CompanyInitializationRepository? _initRepository;

  Future<JournalEntryDraft> buildDraftFromInventoryDocument({
    required InventoryDocumentRef document,
    required double totalAmount,
    String? offsetAccountId,
    bool isPosted = true,
    bool useBaseCurrencyForCogs = false,
  }) async {
    if (totalAmount <= 0) {
      throw ArgumentError(
        'مبلغ المستند يجب أن يكون أكبر من صفر لبناء القيد المحاسبي',
      );
    }

    final isReceipt =
        document.documentType == InventoryDocumentType.stockReceipt;
    final voucherTypeStr = isReceipt ? 'أمر توريد' : 'أمر صرف';

    final overrides = <AccountRole, String>{};
    if (offsetAccountId != null && offsetAccountId.trim().isNotEmpty) {
      overrides[isReceipt ? AccountRole.payable : AccountRole.cogs] =
          offsetAccountId.trim();
    }

    final mapping = await _mappingResolver.resolveForDocument(
      documentType: document.documentType.storageValue,
      overrides: overrides,
    );

    final inventoryRef = mapping.getRole(AccountRole.inventory);
    if (inventoryRef == null) {
      throw StateError(
        'خطأ محاسبي: لم يتم تحديد حساب المخزون في الدليل المحاسبي',
      );
    }

    final offsetRef =
        mapping.getRole(isReceipt ? AccountRole.payable : AccountRole.cogs) ??
        mapping.getRole(AccountRole.cash);

    if (offsetRef == null) {
      throw StateError(
        'خطأ محاسبي: لم يتم تحديد الحساب المقابل للمستند ($voucherTypeStr)',
      );
    }

    // Validate both accounts
    await _validationService.assertCanPost(inventoryRef.accountUuid);
    await _validationService.assertCanPost(offsetRef.accountUuid);

    final debitUuid = isReceipt
        ? inventoryRef.accountUuid
        : offsetRef.accountUuid;
    final creditUuid = isReceipt
        ? offsetRef.accountUuid
        : inventoryRef.accountUuid;

    final companyInventoryConfig = await _initRepository?.getInventoryConfig();
    final baseCurrency =
        (companyInventoryConfig?.inventoryBaseCurrencyId.trim().isNotEmpty ==
            true)
        ? companyInventoryConfig!.inventoryBaseCurrencyId.trim().toUpperCase()
        : 'YER';

    final String effectiveCurrency = useBaseCurrencyForCogs
        ? baseCurrency
        : document.currencyCode;
    final double effectiveRate = useBaseCurrencyForCogs
        ? 1.0
        : document.exchangeRate;

    return JournalEntryDraft(
      entryDate: document.documentDate,
      voucherNumber: document.documentNumber,
      voucherType: voucherTypeStr,
      currencyCode: effectiveCurrency,
      description:
          'قيد تلقائي للمستند $voucherTypeStr: ${document.documentNumber}',
      isPosted: isPosted,
      sourceType: document.documentType.storageValue,
      sourceId: document.documentId,
      lines: [
        JournalLineDraft(
          accountUuid: debitUuid,
          debit: totalAmount,
          credit: 0.0,
          currencyCode: effectiveCurrency,
          exchangeRateToBase: effectiveRate,
          lineDescription: 'مخزون - ${document.documentNumber}',
          sortOrder: 1,
        ),
        JournalLineDraft(
          accountUuid: creditUuid,
          debit: 0.0,
          credit: totalAmount,
          currencyCode: effectiveCurrency,
          exchangeRateToBase: effectiveRate,
          lineDescription: 'مخزون - ${document.documentNumber}',
          sortOrder: 2,
        ),
      ],
    );
  }

  Future<List<JournalEntryDraft>> buildDraftsFromSaleInvoice({
    required SaleInvoicePostingData sale,
    required double calculatedCogsCost,
    bool isPosted = true,
  }) async {
    final drafts = <JournalEntryDraft>[];

    // 1. Sales Revenue Journal Entry
    final netAmount = sale.total;
    final discountAmount = (sale.itemDiscountTotal + sale.discountAmount);

    if (netAmount > 0 || discountAmount > 0) {
      final overrides = <AccountRole, String>{};
      final debitAccountId = sale.settlementType == PostingSettlementType.credit
          ? sale.customerAccountId?.trim()
          : sale.cashAccountId?.trim();

      if (debitAccountId != null && debitAccountId.isNotEmpty) {
        overrides[sale.settlementType == PostingSettlementType.credit
                ? AccountRole.receivable
                : AccountRole.cash] =
            debitAccountId;
      }

      final mapping = await _mappingResolver.resolveForDocument(
        documentType: 'sale',
        overrides: overrides,
      );

      final debitRef = mapping.getRole(
        sale.settlementType == PostingSettlementType.credit
            ? AccountRole.receivable
            : AccountRole.cash,
      );
      final revenueRef = mapping.getRole(AccountRole.revenue);

      if (debitRef == null) {
        final roleLabel = sale.settlementType == PostingSettlementType.credit
            ? 'العملاء (الحسابات المدينة)'
            : 'الصندوق / النقدية';
        throw StateError(
          'تعذر تحديد حساب $roleLabel المحاسبي. يرجى التأكد من اختيار الحساب بشكل صحيح.',
        );
      }
      if (revenueRef == null) {
        throw StateError(
          'تعذر تحديد حساب إيراد المبيعات الرئيسي في دليل الحسابات.',
        );
      }

      await _validationService.assertCanPost(debitRef.accountUuid);
      await _validationService.assertCanPost(revenueRef.accountUuid);

      final rate = sale.exchangeRate <= 0 ? 1.0 : sale.exchangeRate;
      final lines = <JournalLineDraft>[];
      int sortOrder = 1;

      if (netAmount > 0) {
        lines.add(
          JournalLineDraft(
            accountUuid: debitRef.accountUuid,
            debit: netAmount,
            credit: 0.0,
            currencyCode: sale.currencyCode,
            exchangeRateToBase: rate,
            lineDescription: 'مبيعات فاتورة ${sale.saleNumber}',
            sortOrder: sortOrder++,
          ),
        );
      }

      if (discountAmount > 0) {
        final discountRef = mapping.getRole(AccountRole.cogs);
        if (discountRef != null) {
          lines.add(
            JournalLineDraft(
              accountUuid: discountRef.accountUuid,
              debit: discountAmount,
              credit: 0.0,
              currencyCode: sale.currencyCode,
              exchangeRateToBase: rate,
              lineDescription: 'خصم مبيعات فاتورة ${sale.saleNumber}',
              sortOrder: sortOrder++,
            ),
          );
        }
      }

      final grossRevenue =
          netAmount + (discountAmount > 0 ? discountAmount : 0.0);
      lines.add(
        JournalLineDraft(
          accountUuid: revenueRef.accountUuid,
          debit: 0.0,
          credit: grossRevenue,
          currencyCode: sale.currencyCode,
          exchangeRateToBase: rate,
          lineDescription: 'إيراد مبيعات فاتورة ${sale.saleNumber}',
          sortOrder: sortOrder++,
        ),
      );

      final isCredit = sale.settlementType == PostingSettlementType.credit;
      drafts.add(
        JournalEntryDraft(
          entryDate: sale.saleDate,
          voucherNumber: sale.saleNumber,
          voucherType: isCredit ? 'بيع آجل' : 'بيع نقدي',
          currencyCode: sale.currencyCode,
          baseCurrencyCode: sale.baseCurrencyCode,
          description: 'قيد مبيعات ${sale.saleNumber}',
          isPosted: isPosted,
          sourceType: 'sale',
          sourceId: sale.uuid,
          lines: lines,
        ),
      );
    }

    // 2. COGS Journal Entry
    if (calculatedCogsCost > 0) {
      final mapping = await _mappingResolver.resolveForDocument(
        documentType: 'sale_cogs',
      );

      final cogsRef = mapping.getRole(AccountRole.cogs);
      final inventoryRef = mapping.getRole(AccountRole.inventory);

      if (cogsRef == null || inventoryRef == null) {
        throw StateError(
          'تعذر تحديد حساب تكلفة البضاعة المباعة أو حساب المخزون الرئيسي في دليل الحسابات.',
        );
      }

      await _validationService.assertCanPost(cogsRef.accountUuid);
      await _validationService.assertCanPost(inventoryRef.accountUuid);

      final baseCurrency = sale.baseCurrencyCode.trim().isNotEmpty
          ? sale.baseCurrencyCode.trim().toUpperCase()
          : sale.currencyCode.trim().toUpperCase();

      drafts.add(
        JournalEntryDraft(
          entryDate: sale.saleDate,
          voucherNumber: sale.saleNumber,
          voucherType: 'تكلفة مبيعات',
          currencyCode: baseCurrency,
          baseCurrencyCode: baseCurrency,
          description: 'تكلفة مبيعات فاتورة ${sale.saleNumber}',
          isPosted: isPosted,
          sourceType: 'sale_cogs',
          sourceId: sale.uuid,
          lines: [
            JournalLineDraft(
              accountUuid: cogsRef.accountUuid,
              debit: calculatedCogsCost,
              credit: 0.0,
              currencyCode: baseCurrency,
              exchangeRateToBase: 1.0,
              lineDescription: 'تكلفة بضاعة مباعة - ${sale.saleNumber}',
              sortOrder: 1,
            ),
            JournalLineDraft(
              accountUuid: inventoryRef.accountUuid,
              debit: 0.0,
              credit: calculatedCogsCost,
              currencyCode: baseCurrency,
              exchangeRateToBase: 1.0,
              lineDescription: 'مخزون - ${sale.saleNumber}',
              sortOrder: 2,
            ),
          ],
        ),
      );
    }

    return drafts;
  }
}
