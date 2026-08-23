// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'NexaBiz';

  @override
  String get servicesTitle => 'الخدمات';

  @override
  String get servicesSubtitle => 'اختر وحدة أعمال للبدء.';

  @override
  String get moduleInventory => 'المخزون';

  @override
  String get moduleInventoryDescription =>
      'خدمات المخزون بما فيها الجرد، والمزيد لاحقاً.';

  @override
  String get moduleAccounting => 'المحاسبة';

  @override
  String get moduleAccountingDescription =>
      'الدليل المحاسبي وأساس القيود والتقارير المستقبلية.';

  @override
  String get moduleCustomers => 'العملاء';

  @override
  String get moduleCustomersDescription =>
      'بيانات العملاء مع ربط اختياري بالدليل المحاسبي ومعرّفات الأنظمة الخارجية.';

  @override
  String get moduleSales => 'المبيعات';

  @override
  String get moduleSalesDescription =>
      'إنشاء وإدارة المبيعات دون اتصال، مع ربط اختياري بالمحاسبة والمخزون.';

  @override
  String get moduleReceiptsPayments => 'المقبوضات والمدفوعات';

  @override
  String get moduleReceiptsPaymentsDescription =>
      'تسجيل المقبوضات والمدفوعات النقدية والبنكية مع الترحيل المحاسبي والمزامنة دون اتصال.';

  @override
  String get moduleReports => 'التقارير';

  @override
  String get moduleReportsDescription =>
      'إنشاء ومعاينة وطباعة ومشاركة تقارير PDF احترافية.';

  @override
  String get rpListTitle => 'الحركات';

  @override
  String get rpListTitleReceipts => 'المقبوضات';

  @override
  String get rpListTitlePayments => 'المدفوعات';

  @override
  String get rpListTitleTransfers => 'النقل بين الصناديق';

  @override
  String get rpListTitleExchanges => 'مصارفة العملات';

  @override
  String get rpListCardSubtitle => 'بحث وتصفية المقبوضات والمدفوعات';

  @override
  String get rpActionViewAll => 'كل الحركات';

  @override
  String get rpActionNewReceipt => 'قبض جديد';

  @override
  String get rpActionNewPayment => 'صرف جديد';

  @override
  String get rpActionNewTransfer => 'نقل جديد';

  @override
  String get rpActionNewExchange => 'مصارفة جديدة';

  @override
  String get rpCreateReceiptSubtitle => 'تحصيل نقدي أو بنكي إلى الخزينة';

  @override
  String get rpCreatePaymentSubtitle => 'صرف من الصندوق أو البنك';

  @override
  String get rpCreateTransferSubtitle => 'نقل مبلغ بين صناديق النقد';

  @override
  String get rpCreateExchangeSubtitle => 'تبديل عملة إلى أخرى في نفس الصندوق';

  @override
  String get rpServiceReceiptsTitle => 'المقبوضات';

  @override
  String get rpServiceReceiptsSubtitle => 'عرض سندات القبض أو إنشاء سند جديد';

  @override
  String get rpServicePaymentsTitle => 'المدفوعات';

  @override
  String get rpServicePaymentsSubtitle => 'عرض سندات الصرف أو إنشاء سند جديد';

  @override
  String get rpServiceTransfersTitle => 'النقل بين الصناديق';

  @override
  String get rpServiceTransfersSubtitle => 'عرض سندات النقل أو إنشاء سند جديد';

  @override
  String get rpServiceExchangesTitle => 'مصارفة العملات';

  @override
  String get rpServiceExchangesSubtitle =>
      'عرض سندات المصارفة أو إنشاء سند جديد';

  @override
  String get rpServiceViewReceipts => 'جميع المقبوضات';

  @override
  String get rpServiceViewReceiptsSubtitle => 'تصفح وتصفية سندات القبض';

  @override
  String get rpServiceViewPayments => 'جميع المدفوعات';

  @override
  String get rpServiceViewPaymentsSubtitle => 'تصفح وتصفية سندات الصرف';

  @override
  String get rpServiceViewTransfers => 'جميع سندات النقل';

  @override
  String get rpServiceViewTransfersSubtitle =>
      'تصفح وتصفية سندات النقل بين الصناديق';

  @override
  String get rpServiceViewExchanges => 'جميع سندات المصارفة';

  @override
  String get rpServiceViewExchangesSubtitle =>
      'تصفح وتصفية سندات مصارفة العملات';

  @override
  String get rpServiceCreateReceipt => 'إنشاء سند قبض';

  @override
  String get rpServiceCreatePayment => 'إنشاء سند صرف';

  @override
  String get rpServiceCreateTransfer => 'إنشاء سند نقل';

  @override
  String get rpServiceCreateExchange => 'إنشاء سند مصارفة';

  @override
  String get rpFormTitleReceipt => 'سند قبض جديد';

  @override
  String get rpFormTitlePayment => 'سند صرف جديد';

  @override
  String get rpFormTitleTransfer => 'سند نقل بين الصناديق';

  @override
  String get rpFormTitleTransferEdit => 'تعديل سند النقل';

  @override
  String get rpFormTitleExchange => 'سند مصارفة عملات';

  @override
  String get rpFormTitleExchangeEdit => 'تعديل سند المصارفة';

  @override
  String get rpTransferFromAccount => 'من صندوق';

  @override
  String get rpTransferToAccount => 'إلى صندوق';

  @override
  String get rpExchangeCashAccount => 'الصندوق';

  @override
  String get rpExchangeFromCurrency => 'من عملة';

  @override
  String get rpExchangeToCurrency => 'إلى عملة';

  @override
  String get rpExchangeFromAmount => 'المبلغ المُعطى';

  @override
  String get rpExchangeToAmount => 'المبلغ المستلم';

  @override
  String get rpEmptyTitleTransfers => 'لا توجد سندات نقل';

  @override
  String get rpEmptyMessageTransfers => 'أنشئ سند نقل بين الصناديق للبدء.';

  @override
  String get rpEmptyTitleExchanges => 'لا توجد سندات مصارفة';

  @override
  String get rpEmptyMessageExchanges => 'أنشئ سند مصارفة عملات للبدء.';

  @override
  String get rpDetailsTitleTransfer => 'تفاصيل سند النقل';

  @override
  String get rpDetailsTitleExchange => 'تفاصيل سند المصارفة';

  @override
  String get rpDashboardTodayReceipts => 'مقبوضات اليوم';

  @override
  String get rpDashboardTodayPayments => 'مدفوعات اليوم';

  @override
  String get rpDashboardPeriodReceipts => 'مقبوضات الفترة';

  @override
  String get rpDashboardPeriodPayments => 'مدفوعات الفترة';

  @override
  String get rpDashboardNetMovement => 'صافي الحركة';

  @override
  String get rpDashboardCashMovement => 'حركة الصندوق';

  @override
  String get rpDashboardBankMovement => 'حركة البنك';

  @override
  String get rpDashboardPendingSync => 'بانتظار المزامنة';

  @override
  String get rpDashboardFailedSync => 'فشل المزامنة';

  @override
  String get rpFormSectionDocument => 'المستند';

  @override
  String get rpFormSectionAccounts => 'الحسابات والمبلغ';

  @override
  String get rpFormSectionParty => 'الطرف';

  @override
  String get rpFormSectionNotes => 'المرجع والملاحظات';

  @override
  String get rpFormSectionLines => 'بنود القيد';

  @override
  String get rpGeneralDescription => 'البيان العام للسند';

  @override
  String get rpDefaultGeneralDescription => 'دفعة من الحساب';

  @override
  String rpDefaultPaymentDescription(String date) {
    return 'خارج--$date';
  }

  @override
  String rpDefaultTransferDescription(String date) {
    return 'نقل--$date';
  }

  @override
  String rpDefaultExchangeDescription(String date) {
    return 'مصارفة--$date';
  }

  @override
  String get rpManualExchangeRate => 'سعر الصرف';

  @override
  String rpManualExchangeRateHint(String cash, String party) {
    return '1 $cash = ؟ $party';
  }

  @override
  String get rpLineDescription => 'بيان السطر';

  @override
  String get rpCurrency => 'العملة';

  @override
  String get rpCurrencyEquivalent => 'المعادل';

  @override
  String get rpExchangeRate => 'سعر الصرف';

  @override
  String get rpBaseCurrency => 'العملة الأساسية';

  @override
  String get rpLinesEmpty => 'لم تُضف حسابات.';

  @override
  String get rpAddAccountLine => 'إضافة حساب';

  @override
  String get rpAddAnotherAccountLine => 'إضافة صف';

  @override
  String get rpChangeAccount => 'تغيير الحساب';

  @override
  String get rpEditTitle => 'تعديل الحركة';

  @override
  String get rpDetailsTitle => 'تفاصيل الحركة';

  @override
  String get rpSave => 'حفظ';

  @override
  String get rpSaved => 'تم حفظ الحركة';

  @override
  String get rpSaving => 'جارٍ الحفظ…';

  @override
  String get rpPost => 'ترحيل';

  @override
  String get rpPosting => 'جارٍ الترحيل…';

  @override
  String get rpPosted => 'تم ترحيل الحركة';

  @override
  String get rpUnpost => 'إلغاء الترحيل';

  @override
  String get rpUnposting => 'جارٍ إلغاء الترحيل…';

  @override
  String get rpUnposted => 'تم إلغاء ترحيل الحركة';

  @override
  String get rpPostingServiceTitle => 'الترحيل وإلغاء الترحيل';

  @override
  String get rpPostingServiceHubSubtitle =>
      'ترحيل أو إلغاء ترحيل السندات حسب النوع والتاريخ أو الرقم';

  @override
  String get rpPostingServiceSubtitle =>
      'اختر نوع السند ونوع العملية، ثم ابحث من تاريخ إلى تاريخ أو من رقم إلى رقم. يمكنك الترحيل لسند محدد أو للكل.';

  @override
  String get rpPostingServiceDocumentType => 'نوع السند';

  @override
  String get rpPostingServiceOperation => 'نوع العملية';

  @override
  String get rpPostingServiceLookup => 'البحث بواسطة';

  @override
  String get rpPostingServicePickDate => 'اختر التاريخ';

  @override
  String get rpPostingServiceFromDate => 'من تاريخ';

  @override
  String get rpPostingServiceToDate => 'إلى تاريخ';

  @override
  String get rpPostingServiceFromNumber => 'من رقم';

  @override
  String get rpPostingServiceToNumber => 'إلى رقم';

  @override
  String get rpPostingServiceNumberHint => 'مثال: 1';

  @override
  String get rpPostingServiceDateRequired => 'حدد من تاريخ وإلى تاريخ';

  @override
  String get rpPostingServiceDateRangeInvalid =>
      'تاريخ البداية يجب أن يكون قبل أو يساوي تاريخ النهاية';

  @override
  String get rpPostingServiceNumberRequired => 'أدخل من رقم وإلى رقم';

  @override
  String get rpPostingServiceNumberRangeInvalid =>
      'رقم البداية يجب أن يكون أصغر من أو يساوي رقم النهاية';

  @override
  String get rpPostingServiceSearch => 'عرض السندات';

  @override
  String rpPostingServiceResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سندات',
      one: 'سند واحد',
      zero: 'لا سندات',
    );
    return '$_temp0';
  }

  @override
  String get rpPostingServiceEmpty => 'لا توجد سندات مطابقة لهذا الفلتر.';

  @override
  String get rpPostingServiceSelectOne => 'حدد سنداً أولاً';

  @override
  String get rpPostingServiceApplySelectedPost => 'ترحيل المحدد';

  @override
  String get rpPostingServiceApplySelectedUnpost => 'إلغاء ترحيل المحدد';

  @override
  String rpPostingServiceApplyAllPost(int count) {
    return 'ترحيل الكل ($count)';
  }

  @override
  String rpPostingServiceApplyAllUnpost(int count) {
    return 'إلغاء ترحيل الكل ($count)';
  }

  @override
  String rpPostingServiceConfirmOnePost(String number) {
    return 'ترحيل السند $number؟';
  }

  @override
  String rpPostingServiceConfirmOneUnpost(String number) {
    return 'إلغاء ترحيل السند $number؟';
  }

  @override
  String rpPostingServiceConfirmAllPost(int count) {
    return 'ترحيل كل السندات المعروضة ($count)؟';
  }

  @override
  String rpPostingServiceConfirmAllUnpost(int count) {
    return 'إلغاء ترحيل كل السندات المعروضة ($count)؟';
  }

  @override
  String rpPostingServiceSuccessPost(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم ترحيل $count سندات',
      one: 'تم ترحيل سند واحد',
    );
    return '$_temp0';
  }

  @override
  String rpPostingServiceSuccessUnpost(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم إلغاء ترحيل $count سندات',
      one: 'تم إلغاء ترحيل سند واحد',
    );
    return '$_temp0';
  }

  @override
  String rpPostingServicePartial(int success, int failed) {
    return 'نجح $success وفشل $failed';
  }

  @override
  String get rpPostingServiceNoPermission =>
      'ليس لديك صلاحية ترحيل أو إلغاء ترحيل السندات.';

  @override
  String get rpCancelTitle => 'إلغاء الحركة';

  @override
  String rpCancelMessage(String number) {
    return 'إلغاء $number؟ سيتم إبطال القيد المحاسبي المرتبط.';
  }

  @override
  String get rpCancelAction => 'إلغاء الحركة';

  @override
  String get rpCancelled => 'تم إلغاء الحركة';

  @override
  String get rpLoading => 'جارٍ التحميل…';

  @override
  String get rpNotFound => 'الحركة غير موجودة';

  @override
  String get rpEmptyTitle => 'لا توجد حركات';

  @override
  String get rpEmptyMessage => 'أنشئ قبضاً أو صرفاً للبدء.';

  @override
  String get rpEmptyTitleReceipts => 'لا توجد مقبوضات';

  @override
  String get rpEmptyMessageReceipts => 'أنشئ سند قبض للبدء.';

  @override
  String get rpEmptyTitlePayments => 'لا توجد مدفوعات';

  @override
  String get rpEmptyMessagePayments => 'أنشئ سند صرف للبدء.';

  @override
  String get rpDetailsTitleReceipt => 'تفاصيل سند القبض';

  @override
  String get rpDetailsTitlePayment => 'تفاصيل سند الصرف';

  @override
  String get rpSearchHint => 'ابحث بالرقم أو الطرف أو المرجع…';

  @override
  String get rpTypeAll => 'الكل';

  @override
  String get rpTypeLabel => 'النوع';

  @override
  String get rpTypeReceipt => 'قبض';

  @override
  String get rpTypePayment => 'صرف';

  @override
  String get rpTypeTransfer => 'نقل';

  @override
  String get rpTypeExchange => 'مصارفة';

  @override
  String get rpStatusUnposted => 'غير مرحّل';

  @override
  String get rpStatusPosted => 'مرحّل';

  @override
  String get rpSource => 'المصدر';

  @override
  String get rpSourceManualReceipt => 'قبض يدوي';

  @override
  String get rpSourceManualPayment => 'صرف يدوي';

  @override
  String get rpSourceCustomerReceipt => 'قبض عميل';

  @override
  String get rpSourceExpensePayment => 'صرف مصروف';

  @override
  String get rpSourceOtherReceipt => 'قبض أخرى';

  @override
  String get rpSourceOtherPayment => 'صرف أخرى';

  @override
  String get rpSourceSalesRelatedReceipt => 'قبض مرتبط بالمبيعات';

  @override
  String get rpSourcePurchaseRelatedPayment => 'صرف مرتبط بالمشتريات';

  @override
  String get rpSourceCashBoxTransfer => 'نقل بين الصناديق';

  @override
  String get rpSourceCurrencyExchange => 'مصارفة عملات';

  @override
  String get rpDate => 'التاريخ';

  @override
  String get rpAmount => 'المبلغ';

  @override
  String get rpLineAmountCredit => 'المبلغ (دائن)';

  @override
  String get rpLineAmountDebit => 'المبلغ (مدين)';

  @override
  String get rpTotalsDebit => 'إجمالي المدين';

  @override
  String get rpTotalsCredit => 'إجمالي الدائن';

  @override
  String get rpTotalsDifference => 'الفارق';

  @override
  String get rpCashAmount => 'مبلغ الصندوق';

  @override
  String get rpCashAccount => 'حساب الصندوق / البنك';

  @override
  String get rpCounterAccount => 'الحساب المقابل';

  @override
  String get rpCustomer => 'العميل';

  @override
  String get rpPartyName => 'اسم الطرف';

  @override
  String get rpNoParty => 'بدون طرف';

  @override
  String get rpReference => 'المرجع';

  @override
  String get rpDescription => 'الوصف';

  @override
  String get rpPaymentMethod => 'طريقة الدفع';

  @override
  String get rpPaymentCash => 'نقداً';

  @override
  String get rpPaymentCard => 'بطاقة';

  @override
  String get rpPaymentBankTransfer => 'تحويل بنكي';

  @override
  String get rpPaymentOther => 'أخرى';

  @override
  String get rpVoucherBook => 'دفتر السندات';

  @override
  String get rpVoucherBookEmpty => 'لا توجد دفاتر سندات';

  @override
  String get rpTransactionNumber => 'الرقم';

  @override
  String get rpSearchAccountHint => 'ابحث في الحسابات';

  @override
  String get rpSearchCustomerHint => 'ابحث في العملاء';

  @override
  String get rpCustomerNotFound => 'لا يوجد عملاء';

  @override
  String get rpAutocompleteSearchFailed => 'فشل البحث';

  @override
  String get rpErrorAmountMustBePositive => 'يجب أن يكون المبلغ أكبر من صفر';

  @override
  String get rpErrorCounterAmountMustBePositive =>
      'يجب أن يكون مبلغ الطرف أكبر من صفر';

  @override
  String get rpErrorCashAccountRequired => 'حساب الصندوق أو البنك مطلوب';

  @override
  String get rpErrorCounterAccountRequired => 'الحساب المقابل مطلوب';

  @override
  String get rpErrorCustomerRequired => 'العميل مطلوب لهذا المصدر';

  @override
  String get rpErrorSameAccounts =>
      'يجب أن يختلف حساب الصندوق عن الحساب المقابل';

  @override
  String get rpErrorCurrenciesMustDiffer =>
      'يجب أن تختلف عملة المصدر عن عملة الهدف';

  @override
  String get rpErrorVoucherBookRequired => 'اختر دفتر سندات';

  @override
  String get rpErrorNotEditable => 'لا يمكن تعديل الحركات المرحّلة';

  @override
  String get rpErrorCannotPost => 'لا يمكن ترحيل هذه الحركة';

  @override
  String get rpErrorCannotUnpost => 'لا يمكن إلغاء ترحيل هذه الحركة';

  @override
  String get rpErrorCannotCancel => 'لا يمكن إلغاء هذه الحركة';

  @override
  String get rpErrorAlreadyCancelled => 'الحركة ملغاة مسبقاً';

  @override
  String get rpErrorCurrencyRequired => 'العملة مطلوبة';

  @override
  String get rpErrorUnbalanced =>
      'لا يمكن الحفظ مع وجود فارق بين المدين والدائن';

  @override
  String get rpErrorSavingInProgress => 'الحفظ قيد التنفيذ';

  @override
  String get rpErrorLedgerPostingFailed => 'فشل الترحيل المحاسبي';

  @override
  String get adminPermPackageReceiptsPaymentsHint =>
      'المقبوضات والمدفوعات والتقارير والمزامنة';

  @override
  String get adminPermServiceReceipts => 'المقبوضات';

  @override
  String get adminPermServiceReceiptsHint => 'المقبوضات النقدية والبنكية';

  @override
  String get adminPermServicePayments => 'المدفوعات';

  @override
  String get adminPermServicePaymentsHint => 'المدفوعات النقدية والبنكية';

  @override
  String get adminPermServiceTransfers => 'النقل بين الصناديق';

  @override
  String get adminPermServiceTransfersHint => 'التحويلات بين حسابات الصناديق';

  @override
  String get adminPermServiceExchanges => 'مصارفة العملات';

  @override
  String get adminPermServiceExchangesHint => 'تبديل العملات داخل الصندوق';

  @override
  String get adminPermServiceRpReports => 'التقارير';

  @override
  String get adminPermServiceRpReportsHint => 'تقارير المقبوضات والمدفوعات';

  @override
  String get adminPermServiceRpSync => 'المزامنة';

  @override
  String get adminPermServiceRpSyncHint => 'مزامنة المقبوضات والمدفوعات';

  @override
  String get adminPermActionSync => 'مزامنة';

  @override
  String get reportsRpReceiptsTitle => 'تقرير المقبوضات';

  @override
  String get reportsRpReceiptsSubtitle =>
      'المقبوضات خلال فترة مع إجماليات من قاعدة البيانات.';

  @override
  String get reportsRpPaymentsTitle => 'تقرير المدفوعات';

  @override
  String get reportsRpPaymentsSubtitle =>
      'المدفوعات خلال فترة مع إجماليات من قاعدة البيانات.';

  @override
  String get reportsRpCashMovementTitle => 'حركة الصندوق';

  @override
  String get reportsRpCashMovementSubtitle =>
      'مقبوضات ومدفوعات الصندوق خلال فترة.';

  @override
  String get reportsRpBankMovementTitle => 'حركة البنك';

  @override
  String get reportsRpBankMovementSubtitle =>
      'مقبوضات ومدفوعات البنك خلال فترة.';

  @override
  String get reportsRpCustomerReceiptsTitle => 'مقبوضات العملاء';

  @override
  String get reportsRpCustomerReceiptsSubtitle =>
      'المقبوضات المرتبطة بالعملاء.';

  @override
  String get reportsRpDailySummaryTitle => 'ملخص يومي';

  @override
  String get reportsRpDailySummarySubtitle => 'المقبوضات والمدفوعات ليوم واحد.';

  @override
  String get reportsRpPeriodSummaryTitle => 'ملخص الفترة';

  @override
  String get reportsRpPeriodSummarySubtitle =>
      'إجماليات المقبوضات والمدفوعات لفترة.';

  @override
  String get reportsRpColNumber => 'الرقم';

  @override
  String get reportsRpColDate => 'التاريخ';

  @override
  String get reportsRpColType => 'النوع';

  @override
  String get reportsRpColParty => 'الطرف';

  @override
  String get reportsRpColAmount => 'المبلغ';

  @override
  String get reportsRpColStatus => 'الحالة';

  @override
  String get reportsRpTotal => 'الإجمالي';

  @override
  String get reportsRpCount => 'العدد';

  @override
  String get reportsSalesPeriodTitle => 'المبيعات حسب الفترة';

  @override
  String get reportsSalesPeriodSubtitle =>
      'اعرض المبيعات ضمن فترة وحالة ثم عاينها كملف PDF.';

  @override
  String get reportsAccountStatementTitle => 'كشف حساب';

  @override
  String get reportsAccountStatementSubtitle =>
      'اطبع كشف حساب تراكمي بعملة الحساب وفق النموذج المحاسبي الكلاسيكي.';

  @override
  String get reportsTrialBalanceTitle => 'ميزان المراجعة';

  @override
  String get reportsTrialBalanceSubtitle =>
      'إجمالي المدين والدائن لكل حساب بالعملة الأساسية ضمن فترة.';

  @override
  String get reportsTrialBalanceColCode => 'الرمز';

  @override
  String get reportsTrialBalanceColName => 'الحساب';

  @override
  String get reportsTrialBalanceColDebit => 'مدين';

  @override
  String get reportsTrialBalanceColCredit => 'دائن';

  @override
  String get reportsTrialBalanceTotals => 'الإجماليات';

  @override
  String get reportsTrialBalanceBalanced => 'متوازن';

  @override
  String get reportsTrialBalanceUnbalanced => 'غير متوازن';

  @override
  String get reportsTrialBalanceEmpty =>
      'لا توجد حركة دفترية للمعايير المحددة.';

  @override
  String get reportsTrialBalancePostedOnly => 'القيود المرحلة فقط';

  @override
  String get reportsJournalBookTitle => 'دفتر اليومية';

  @override
  String get reportsJournalBookSubtitle =>
      'قيود اليومية مرتبة زمنياً بالعملة الأساسية ضمن فترة.';

  @override
  String get reportsJournalBookColDate => 'التاريخ';

  @override
  String get reportsJournalBookColVoucher => 'رقم السند';

  @override
  String get reportsJournalBookColType => 'النوع';

  @override
  String get reportsJournalBookColDescription => 'البيان';

  @override
  String get reportsJournalBookColAccount => 'الحساب';

  @override
  String get reportsJournalBookColDebit => 'مدين';

  @override
  String get reportsJournalBookColCredit => 'دائن';

  @override
  String get reportsJournalBookTotals => 'الإجماليات';

  @override
  String get reportsJournalBookEmpty => 'لا توجد قيود للمعايير المحددة.';

  @override
  String get reportsJournalBookPostedOnly => 'القيود المرحلة فقط';

  @override
  String get reportsAccountStatementFilters => 'معايير الكشف';

  @override
  String get reportsAccountStatementAccount => 'الحساب';

  @override
  String get reportsAccountStatementAccountHint => 'اختر الحساب';

  @override
  String get reportsAccountStatementAccountSearch => 'ابحث بالرمز أو الاسم';

  @override
  String get reportsAccountStatementAccountEmpty => 'لا توجد حسابات ترحيل.';

  @override
  String get reportsAccountStatementAccountRequired => 'اختر الحساب أولاً.';

  @override
  String get reportsAccountStatementAccountName => 'إسم الحساب';

  @override
  String get reportsAccountStatementAccountNumber => 'رقم الحساب';

  @override
  String get reportsAccountStatementCurrency => 'العملة';

  @override
  String get reportsAccountStatementCurrencyAll => 'كل العملات';

  @override
  String get reportsAccountStatementType => 'نوع الكشف';

  @override
  String get reportsAccountStatementTypeCumulative =>
      'كشف حساب تراكمي بعملة الحساب';

  @override
  String get reportsAccountStatementTypeDetailed => 'كشف تفصيلي';

  @override
  String get reportsAccountStatementTypeSummary => 'كشف إجمالي';

  @override
  String get reportsAccountStatementPostingStatus => 'حالة الترحيل';

  @override
  String get reportsAccountStatementPostingAll => 'الكل';

  @override
  String get reportsAccountStatementPostingPosted => 'مرحل';

  @override
  String get reportsAccountStatementPostingUnposted => 'غير مرحل';

  @override
  String get reportsAccountStatementFromDate => 'من تاريخ';

  @override
  String get reportsAccountStatementToDate => 'إلى تاريخ';

  @override
  String get reportsAccountStatementColSide => 'م/د';

  @override
  String get reportsAccountStatementColVoucherType => 'نوع السند';

  @override
  String get reportsAccountStatementColVoucherNumber => 'الرقم';

  @override
  String get reportsAccountStatementColDescription => 'التفاصيل';

  @override
  String get reportsAccountStatementColDebit => 'المدين';

  @override
  String get reportsAccountStatementColCredit => 'الدائن';

  @override
  String get reportsAccountStatementColBalance => 'الرصيد';

  @override
  String get reportsAccountStatementColCurrency => 'العملة';

  @override
  String get reportsAccountStatementColInCurrency => 'بالعملة';

  @override
  String get reportsAccountStatementTotalsDebit => 'مدين';

  @override
  String get reportsAccountStatementTotalsCredit => 'دائن';

  @override
  String get reportsAccountStatementFinalBalanceByCurrency =>
      'الرصيد النهائي على مستوى العملة';

  @override
  String get reportsAccountStatementDisclaimer =>
      'يعتبر كشف الحساب هذا صحيحاً ما لم يردنا عليه أي اعتراض خلال فترة أسبوعين من تاريخه .';

  @override
  String get reportsAccountStatementAccountant => 'المحاسب';

  @override
  String get reportsAccountStatementReviewer => 'المراجع';

  @override
  String get reportsAccountStatementFinanceManager => 'المدير المالي:';

  @override
  String get reportsAccountStatementPrintedBy => 'NexaBiz';

  @override
  String get reportsAccountStatementEmpty =>
      'لا توجد حركات دفترية لهذا الحساب بعد. ستظهر القيود اليومية هنا عند توفرها.';

  @override
  String get reportsCatalogTitle => 'كل تقارير PDF';

  @override
  String get reportsCatalogSubtitle =>
      'افتح كتالوج التقارير لإنشاء ومعاينة ملفات PDF.';

  @override
  String get reportsPreviewTitle => 'معاينة التقرير';

  @override
  String get reportsPreviewMissing =>
      'لا يوجد تقرير جاهز للمعاينة. أنشئ تقريراً أولاً.';

  @override
  String get reportsActionPrint => 'طباعة';

  @override
  String get reportsActionShare => 'مشاركة';

  @override
  String get reportsGeneratePreview => 'إنشاء ومعاينة';

  @override
  String get reportsGenerating => 'جاري إنشاء التقرير…';

  @override
  String get reportsGeneratedAt => 'تاريخ الإنشاء';

  @override
  String get reportsPeriod => 'الفترة';

  @override
  String get reportsPeriodAll => 'كل التواريخ';

  @override
  String get reportsFromDate => 'من تاريخ';

  @override
  String get reportsToDate => 'إلى تاريخ';

  @override
  String get reportsDateAny => 'أي';

  @override
  String get reportsStatusAll => 'كل الحالات';

  @override
  String get reportsGrandTotal => 'الإجمالي';

  @override
  String get reportsRowCount => 'الصفوف';

  @override
  String get reportsColSaleNumber => 'الرقم';

  @override
  String get reportsColDate => 'التاريخ';

  @override
  String get reportsColCustomer => 'العميل';

  @override
  String get reportsColSettlement => 'التسوية';

  @override
  String get reportsColStatus => 'الحالة';

  @override
  String get reportsColCurrency => 'العملة';

  @override
  String get reportsColTotal => 'المبلغ';

  @override
  String get reportsEmptySales => 'لا توجد مبيعات مطابقة للفلاتر المحددة.';

  @override
  String get reportsErrorGeneric => 'تعذر إنشاء التقرير.';

  @override
  String get reportsErrorPrint => 'فشلت الطباعة.';

  @override
  String get reportsErrorShare => 'فشلت المشاركة.';

  @override
  String get reportsErrorFile => 'تعذر حفظ ملف PDF.';

  @override
  String get reportsErrorFont => 'تعذر تحميل خطوط التقرير.';

  @override
  String get salesListTitle => 'المبيعات';

  @override
  String get salesListCardSubtitle => 'استعرض وابحث وأدر مستندات المبيعات.';

  @override
  String get salesCreateTitle => 'فاتورة جديدة';

  @override
  String get salesCreateCardSubtitle =>
      'ابدأ عملية بيع سريعة مع المنتجات والدفع.';

  @override
  String get salesEditTitle => 'تعديل الفاتورة';

  @override
  String get salesDetailsTitle => 'فاتورة';

  @override
  String get salesSearchHint => 'ابحث برقم الفاتورة أو العميل أو المنتج';

  @override
  String get salesSearchCustomerHint => 'ابحث عن عميل';

  @override
  String get salesSearchProductHint => 'اكتب اسم المنتج';

  @override
  String get salesEmptyTitle => 'لا توجد مبيعات بعد';

  @override
  String get salesEmptyMessage => 'أنشئ أول فاتورة للبدء.';

  @override
  String get salesCustomer => 'العميل';

  @override
  String get salesSelectCustomer => 'اختر العميل';

  @override
  String get salesCashCustomerHint => 'أدخل اسماً أو اختر عميلاً';

  @override
  String get salesWalkInCustomer => 'عميل عابر';

  @override
  String get salesCustomerEmpty => 'لا يوجد عملاء.';

  @override
  String get salesCustomerNotFound => 'العميل غير موجود.';

  @override
  String get salesProducts => 'المنتجات';

  @override
  String get salesProductName => 'المنتج';

  @override
  String get salesAddProduct => 'إضافة منتج';

  @override
  String get salesAddRow => 'إضافة صف';

  @override
  String get salesProductsEmpty => 'لم تُضف منتجات.';

  @override
  String get salesProductNotFound => 'المنتج غير موجود.';

  @override
  String get salesAutocompleteSearchFailed =>
      'تعذر تحميل النتائج. حاول مرة أخرى.';

  @override
  String get salesRemoveItem => 'إزالة الصنف';

  @override
  String get salesScanProduct => 'مسح منتج';

  @override
  String get salesScanHint => 'أدخل الباركود أو رمز QR';

  @override
  String get salesUnitPrice => 'سعر الوحدة';

  @override
  String get salesSubtotal => 'المجموع الفرعي';

  @override
  String get salesDiscount => 'الخصم';

  @override
  String get salesItemDiscount => 'خصومات الأصناف';

  @override
  String get salesDiscountType => 'نوع الخصم';

  @override
  String get salesDiscountFixed => 'مبلغ ثابت';

  @override
  String get salesDiscountPercent => 'نسبة مئوية';

  @override
  String get salesTax => 'الضريبة';

  @override
  String get salesTaxRate => 'نسبة الضريبة (%)';

  @override
  String get salesTotal => 'الإجمالي';

  @override
  String get salesPaid => 'المدفوع';

  @override
  String get salesRemaining => 'المتبقي';

  @override
  String get salesPayFull => 'دفع المبلغ كاملاً';

  @override
  String get salesPayment => 'الدفع';

  @override
  String get salesPaymentMethod => 'طريقة الدفع';

  @override
  String get salesPaymentStatus => 'حالة الدفع';

  @override
  String get salesPaymentCash => 'نقداً';

  @override
  String get salesPaymentCard => 'بطاقة';

  @override
  String get salesPaymentBankTransfer => 'تحويل بنكي';

  @override
  String get salesPaymentCredit => 'آجل';

  @override
  String get salesPaymentOther => 'أخرى';

  @override
  String get salesDate => 'التاريخ';

  @override
  String get salesSettlementType => 'نوع الفاتورة';

  @override
  String get salesSettlementCash => 'نقداً';

  @override
  String get salesSettlementCredit => 'آجل';

  @override
  String get salesSettlementCashHint => 'تحصيل فوري عبر الصندوق';

  @override
  String get salesSettlementCreditHint => 'تقييد على حساب العميل';

  @override
  String get salesVoucherBook => 'دفتر المبيعات';

  @override
  String get salesSelectVoucherBook => 'اختر دفتر المبيعات';

  @override
  String get salesVoucherBookEmpty =>
      'لا توجد دفاتر مبيعات. أنشئ دفتراً من المحاسبة.';

  @override
  String get salesInvoiceNumber => 'رقم الفاتورة';

  @override
  String salesInvoiceReference(String number) {
    return 'مرجع $number';
  }

  @override
  String get salesCashAccount => 'حساب الصندوق';

  @override
  String get salesSelectCashAccount => 'اختر حساب الصندوق';

  @override
  String get salesCashAccountEmpty => 'لا توجد حسابات صناديق.';

  @override
  String get salesCustomerAccount => 'حساب العميل';

  @override
  String get salesCustomerAccountMissing => 'العميل غير مرتبط بحساب محاسبي.';

  @override
  String get salesClearCustomer => 'إزالة العميل';

  @override
  String get salesCurrency => 'العملة';

  @override
  String get salesBaseCurrency => 'الأساسية';

  @override
  String salesExchangeRateHint(String currency, String rate, String base) {
    return '1 $currency = $rate $base';
  }

  @override
  String get salesCreditHint =>
      'فاتورة آجلة — يُقيَّد المبلغ على حساب العميل ويتبقى الرصيد مستحقاً.';

  @override
  String get salesSearchOrScanProduct => 'ابحث أو امسح منتجاً';

  @override
  String get salesInvoiceOptions => 'خيارات الفاتورة';

  @override
  String get salesItemMore => 'المزيد';

  @override
  String get salesAddCustomer => 'إضافة عميل';

  @override
  String get salesAdd => 'إضافة';

  @override
  String get salesIncreaseQty => 'زيادة الكمية';

  @override
  String get salesDecreaseQty => 'إنقاص الكمية';

  @override
  String get salesErrorCustomerRequired => 'اختر عميلاً للفواتير الآجلة.';

  @override
  String get salesErrorCustomerAccountRequired =>
      'اربط العميل بحساب محاسبي أولاً.';

  @override
  String get salesErrorCashAccountRequired => 'اختر حساب الصندوق.';

  @override
  String get salesErrorVoucherBookRequired => 'اختر دفتر المبيعات.';

  @override
  String get salesErrorCurrencyRequired => 'اختر عملة صالحة.';

  @override
  String get salesPaymentUnpaid => 'غير مدفوع';

  @override
  String get salesPaymentPartiallyPaid => 'مدفوع جزئياً';

  @override
  String get salesPaymentPaid => 'مدفوع';

  @override
  String get salesStatus => 'حالة الفاتورة';

  @override
  String get salesStatusUnposted => 'غير مرحل';

  @override
  String get salesStatusPosted => 'مرحل';

  @override
  String get salesStatusDraft => 'غير مرحل';

  @override
  String get salesStatusPending => 'غير مرحل';

  @override
  String get salesStatusConfirmed => 'مرحل';

  @override
  String get salesStatusCompleted => 'مرحل';

  @override
  String get salesStatusCancelled => 'ملغاة';

  @override
  String get salesStatusRejected => 'مرفوضة';

  @override
  String get salesNotes => 'ملاحظات';

  @override
  String get salesSave => 'حفظ الفاتورة';

  @override
  String get salesSaveAndConfirm => 'حفظ وترحيل';

  @override
  String get salesSaving => 'جاري حفظ الفاتورة…';

  @override
  String get salesLoadingInvoice => 'جاري تحميل الفاتورة…';

  @override
  String get salesConfirming => 'جاري ترحيل الفاتورة…';

  @override
  String get salesPosting => 'جاري الترحيل…';

  @override
  String get salesSaved => 'تم حفظ الفاتورة';

  @override
  String get salesConfirmed => 'تم ترحيل الفاتورة';

  @override
  String get salesPosted => 'تم ترحيل الفاتورة';

  @override
  String get salesCompleted => 'اكتملت الفاتورة';

  @override
  String get salesCancelled => 'تم إلغاء الفاتورة';

  @override
  String get salesDuplicated => 'تم تكرار الفاتورة';

  @override
  String get salesConfirmSale => 'ترحيل';

  @override
  String get salesPostSale => 'ترحيل';

  @override
  String get salesPostRequiresInventory =>
      'الترحيل غير متاح حتى يتم إضافة تتبع المخزون.';

  @override
  String get salesCompleteSale => 'تعليم كمكتملة';

  @override
  String get salesCancelSale => 'إلغاء الفاتورة';

  @override
  String get salesCancelTitle => 'إلغاء الفاتورة؟';

  @override
  String salesCancelMessage(String saleNumber) {
    return 'إلغاء $saleNumber؟ سيتم عكس أثر المخزون عند الحاجة.';
  }

  @override
  String get salesDuplicate => 'تكرار';

  @override
  String get salesPrintInvoice => 'طباعة';

  @override
  String get salesPreviewInvoice => 'معاينة وطباعة';

  @override
  String get salesPrintingInvoice => 'جاري تجهيز معاينة الفاتورة…';

  @override
  String get salesPrintFailed => 'تعذر طباعة الفاتورة.';

  @override
  String get salesShareInvoice => 'مشاركة';

  @override
  String get salesSharingInvoice => 'جاري تجهيز المشاركة…';

  @override
  String get salesShareFailed => 'تعذر مشاركة الفاتورة.';

  @override
  String get salesInvoiceSaved => 'تم حفظ الفاتورة في مجلد الفواتير.';

  @override
  String get salesNotFound => 'الفاتورة غير موجودة';

  @override
  String get salesFiltersTitle => 'عوامل التصفية';

  @override
  String get salesFilterAll => 'الكل';

  @override
  String get salesApplyFilters => 'تطبيق التصفية';

  @override
  String get salesClearFilters => 'مسح التصفية';

  @override
  String get salesSyncStatus => 'حالة المزامنة';

  @override
  String get salesExternalId => 'المعرّف الخارجي';

  @override
  String get salesExternalNumber => 'رقم المستند الخارجي';

  @override
  String get salesErrorEmptyItems => 'أضف منتجاً واحداً على الأقل.';

  @override
  String get salesErrorInvalidQuantity => 'يجب أن تكون الكمية أكبر من صفر.';

  @override
  String get salesErrorInvalidPrice => 'لا يمكن أن يكون السعر سالباً.';

  @override
  String get salesErrorPriceBelowCatalog =>
      'لا يمكن أن يكون سعر الوحدة أقل من السعر الافتراضي للمنتج.';

  @override
  String get salesPriceBelowCatalogHint => 'أقل من السعر الافتراضي';

  @override
  String get salesErrorInvalidDiscount => 'الخصم غير صالح.';

  @override
  String get salesErrorInvalidTax => 'يجب أن تكون نسبة الضريبة بين 0 و 100.';

  @override
  String get salesErrorInvalidPayment => 'المبلغ المدفوع غير صالح.';

  @override
  String get salesErrorInvalidStatus => 'هذا الإجراء غير مسموح للحالة الحالية.';

  @override
  String get customersListTitle => 'العملاء';

  @override
  String get customersListCardSubtitle => 'استعرض وأنشئ وأدر العملاء.';

  @override
  String get customersAccountsTitle => 'حسابات العملاء';

  @override
  String get customersAccountsCardSubtitle =>
      'عرض حسابات الدليل تحت أصل العملاء كما في شجرة الدليل.';

  @override
  String customersAccountsUnderParent(String code, String name) {
    return 'تحت $code · $name';
  }

  @override
  String get customersAccountsEmptyTitle => 'لا توجد حسابات بعد';

  @override
  String get customersAccountsEmptyMessage =>
      'عند إنشاء عميل مع الربط التلقائي يظهر حسابه هنا وتحت الدليل المحاسبي.';

  @override
  String get customersAccountGroupBadge => 'مجموعة';

  @override
  String get customersAccountNonPostingBadge => 'غير ترحيلي';

  @override
  String get customersAccountMissingInChart => 'الحساب غير موجود في الدليل';

  @override
  String get customersCreateTitle => 'عميل جديد';

  @override
  String get customersEditTitle => 'تعديل العميل';

  @override
  String get customersDetailsTitle => 'تفاصيل العميل';

  @override
  String get customersSearchHint => 'ابحث بالرمز أو الاسم أو الهاتف أو البريد';

  @override
  String get customersEmptyTitle => 'لا يوجد عملاء بعد';

  @override
  String get customersEmptyMessage =>
      'أضف عميلاً أو استورد قائمة Excel لبدء بناء قائمة العملاء.';

  @override
  String get customersFieldCode => 'رمز العميل';

  @override
  String get customersFieldCodeHelper =>
      'رمز متسلسل من حساب أصل العملاء في الدليل (مثل 12210001). تلقائي أو مستورد أو يدوي.';

  @override
  String get customersGenerateCode => 'توليد الرمز';

  @override
  String get customersFieldName => 'الاسم';

  @override
  String get customersFieldPhone => 'الهاتف';

  @override
  String get customersFieldEmail => 'البريد الإلكتروني';

  @override
  String get customersFieldAddress => 'العنوان';

  @override
  String get customersFieldNotes => 'ملاحظات';

  @override
  String get customersFieldActive => 'نشط';

  @override
  String get customersFieldAccount => 'الحساب المحاسبي';

  @override
  String get customersFieldAccountHelper =>
      'اختياري. اتركه فارغاً لإنشاء الحساب تلقائياً تحت أصل العملاء عند تفعيل الربط التلقائي، أو أدخل رمز حساب ترحيل موجود.';

  @override
  String get customersFieldAccountHelperAuto =>
      'اتركه فارغاً لإنشاء حساب في الدليل المحاسبي تلقائياً تحت أصل العملاء (بنفس رمز العميل).';

  @override
  String customersAccountLinked(String code, String name) {
    return 'مرتبط: $code · $name';
  }

  @override
  String get customersAccountLinkInvalid =>
      'لا يوجد حساب ترحيل مطابق لهذا الرمز.';

  @override
  String get customersAccountAutoLinkFailed =>
      'تعذر إنشاء أو ربط حساب الدليل المحاسبي لهذا العميل.';

  @override
  String customersAccountMustBeUnderParent(String code, String name) {
    return 'يجب أن يكون الحساب المرتبط تحت الأصل $code · $name.';
  }

  @override
  String get customersSettingsTitle => 'إعدادات العملاء';

  @override
  String get customersSettingsSubtitle =>
      'ضبط الربط بالدليل المحاسبي وخيارات العملاء الأخرى.';

  @override
  String get customersSettingsCardSubtitle =>
      'حساب الأصل، الربط التلقائي، والمزيد';

  @override
  String get customersAutoLinkSectionTitle => 'ربط تلقائي بالدليل المحاسبي';

  @override
  String get customersAutoLinkSectionSubtitle =>
      'عند التفعيل، حفظ عميل بلا حساب ينشئ حساب ترحيل تحت مجموعة أصل العملاء.';

  @override
  String get customersAutoLinkToggle => 'إنشاء حساب الدليل تلقائياً';

  @override
  String get customersLinkMissingAccountsTitle => 'ربط العملاء الحاليين';

  @override
  String get customersLinkMissingAccountsSubtitle =>
      'إنشاء حسابات في الدليل المحاسبي للعملاء المستوردين أو المحفوظين بلا ربط.';

  @override
  String get customersLinkMissingAccountsAction => 'ربط الحسابات الناقصة الآن';

  @override
  String customersLinkMissingAccountsDone(int count) {
    return 'تم ربط $count عميل/عملاء بالدليل المحاسبي.';
  }

  @override
  String get customersParentAccountSectionTitle => 'حساب أصل العملاء';

  @override
  String get customersParentAccountSectionSubtitle =>
      'اختر مجموعة الدليل المحاسبي التي تندرج تحتها حسابات العملاء (الافتراضي: العملاء 1221).';

  @override
  String customersParentAccountCurrent(String code, String name) {
    return 'الأصل: $code · $name';
  }

  @override
  String get customersParentAccountNotSet =>
      'لم يُحدد حساب الأصل. اضبطه من إعدادات العملاء.';

  @override
  String get customersParentAccountField => 'رمز حساب الأصل';

  @override
  String get customersParentAccountFieldHelper =>
      'أدخل رمز حساب مجموعة من الدليل المحاسبي (مثل 1221).';

  @override
  String get customersParentAccountUseDefault => 'استخدام الافتراضي';

  @override
  String get customersParentAccountSaved => 'تم حفظ حساب أصل العملاء.';

  @override
  String get customersParentAccountInvalid =>
      'لا يوجد حساب مجموعة مطابق لهذا الرمز.';

  @override
  String get customersFieldDataSource => 'مصدر البيانات';

  @override
  String get customersDataSourceLocal => 'محلي';

  @override
  String get customersDataSourceLocalHint => 'أُنشئ ويُدار داخل هذا التطبيق.';

  @override
  String get customersDataSourceExternal => 'خارجي';

  @override
  String get customersDataSourceExternalHint =>
      'مستورد أو مُدار من نظام محاسبة/ERP خارجي.';

  @override
  String get customersFieldExternalId => 'المعرّف الخارجي';

  @override
  String get customersFieldExternalIdHelper =>
      'مطلوب عندما يكون مصدر البيانات خارجياً.';

  @override
  String get customersStatusActive => 'نشط';

  @override
  String get customersStatusInactive => 'غير نشط';

  @override
  String get customersCreated => 'تم إنشاء العميل.';

  @override
  String get customersUpdated => 'تم تحديث العميل.';

  @override
  String get customersDelete => 'حذف';

  @override
  String get customersDeleteTitle => 'حذف العميل؟';

  @override
  String customersDeleteMessage(String name) {
    return 'إزالة $name من قائمة العملاء؟';
  }

  @override
  String get customersDeleted => 'تم حذف العميل.';

  @override
  String get customersErrorDuplicateCode => 'يوجد عميل بهذا الرمز مسبقاً.';

  @override
  String get customersErrorDuplicateExternalId =>
      'يوجد عميل بهذا المعرّف الخارجي مسبقاً.';

  @override
  String get customersErrorInvalidCode => 'رمز العميل مطلوب.';

  @override
  String get customersErrorInvalidName => 'اسم العميل مطلوب.';

  @override
  String get customersErrorInvalidEmail => 'أدخل بريداً إلكترونياً صالحاً.';

  @override
  String get customersErrorExternalIdRequired =>
      'المعرّف الخارجي مطلوب للعملاء الخارجيين.';

  @override
  String get customersImportTitle => 'استيراد العملاء';

  @override
  String get customersImportSubtitle => 'استورد صفوف العملاء من ملف Excel.';

  @override
  String get customersImportPageTitle => 'استيراد العملاء';

  @override
  String get customersImportFormatHintTitle => 'تخطيط Excel للعملاء';

  @override
  String get customersImportFormatHintIntro =>
      'الصف الأول = عناوين. المطلوب: الرمز والاسم. استخدم .xlsx أو .xls.';

  @override
  String get customersImportFormatColCodeAliases =>
      'Customer Code · Code · رمز العميل';

  @override
  String get customersImportFormatColNameAliases =>
      'Customer Name · Name · اسم العميل';

  @override
  String get customersImportFormatColPhoneAliases => 'Phone · Mobile · الهاتف';

  @override
  String get customersImportFormatColEmailAliases => 'Email · البريد';

  @override
  String get customersImportFormatColAddressAliases => 'Address · العنوان';

  @override
  String get customersImportFormatColNotesAliases => 'Notes · ملاحظات';

  @override
  String get customersImportFormatColExternalIdAliases =>
      'External ID · المعرف الخارجي';

  @override
  String get customersImportFormatSampleNote =>
      'بدون عناوين تُقرأ الأعمدة كـ: الرمز، الاسم. الصفوف المطابقة تُحدَّث حسب رمز العميل (أو المعرّف الخارجي إن وُجد).';

  @override
  String customersImportInsertedCount(int count) {
    return 'تم إدراج $count عميل';
  }

  @override
  String customersImportUpdatedCount(int count) {
    return 'تم تحديث $count عميل';
  }

  @override
  String get customersImportBackgroundHint =>
      'يمكنك مغادرة هذه الصفحة ومتابعة استخدام التطبيق أثناء تشغيل الاستيراد في الخلفية.';

  @override
  String get importBackgroundHint =>
      'يمكنك مغادرة هذه الصفحة ومتابعة استخدام التطبيق أثناء تشغيل الاستيراد في الخلفية.';

  @override
  String get customersNoValidRows => 'لم يُعثر على صفوف عملاء صالحة في الملف.';

  @override
  String get loadingImportingCustomers => 'جاري استيراد العملاء…';

  @override
  String get accountingModeSectionTitle => 'وضع المحاسبة';

  @override
  String get accountingModeSectionSubtitle =>
      'اختر ما إذا كان التطبيق يملك المحاسبة محلياً أو يكمل نظام محاسبة/ERP خارجياً.';

  @override
  String get accountingModeStandalone => 'مستقل';

  @override
  String get accountingModeStandaloneDescription =>
      'التطبيق يملك الدليل المحاسبي وميزات المحاسبة المحلية المستقبلية.';

  @override
  String get accountingModeIntegrated => 'متكامل';

  @override
  String get accountingModeIntegratedDescription =>
      'التطبيق واجهة تشغيلية بجانب نظام محاسبة/ERP قائم.';

  @override
  String get accountingModeStandaloneHint =>
      'البيانات المحاسبية المحلية هي المرجع. فواتير البيع في الوضع المستقل تنشئ قيوداً يومية محلية عند الحفظ/الترحيل.';

  @override
  String get accountingModeIntegratedHint =>
      'يمكن تجهيز المستندات التشغيلية هنا وترحيلها لاحقاً في النظام الخارجي. لا تُنشأ قيود يومية محلية تلقائياً.';

  @override
  String get accountingModeSavedSuccess => 'تم حفظ وضع المحاسبة.';

  @override
  String get accountingFiscalClosedSectionTitle => 'الفترة المالية المغلقة';

  @override
  String get accountingFiscalClosedSectionSubtitle =>
      'لا يمكن ترحيل أو تعديل قيود يومية في أو قبل هذا التاريخ.';

  @override
  String get accountingFiscalClosedThroughLabel => 'مغلقة حتى';

  @override
  String get accountingFiscalClosedNone => 'لا توجد فترة مغلقة';

  @override
  String get accountingFiscalClosedSavedSuccess =>
      'تم حفظ الفترة المالية المغلقة.';

  @override
  String get accountingFiscalClosedClear => 'مسح';

  @override
  String get accountingJournalsTitle => 'القيود اليومية';

  @override
  String get accountingJournalsSubtitle => 'استعرض وأنشئ وراجع سندات القيود.';

  @override
  String get accountingJournalsEmptyTitle => 'لا توجد قيود بعد';

  @override
  String get accountingJournalsEmptyMessage =>
      'أنشئ قيداً يدوياً أو رحّل فاتورة بيع في الوضع المستقل.';

  @override
  String get accountingJournalsSearchHint => 'ابحث برقم السند أو الوصف';

  @override
  String get accountingJournalAdd => 'قيد جديد';

  @override
  String get accountingJournalDetails => 'تفاصيل القيد';

  @override
  String get accountingJournalEdit => 'تعديل القيد';

  @override
  String get accountingJournalSave => 'حفظ القيد';

  @override
  String get accountingJournalSavedSuccess => 'تم حفظ القيد.';

  @override
  String get accountingJournalVoid => 'عكس / إلغاء القيد';

  @override
  String get accountingJournalVoidConfirmTitle => 'عكس هذا القيد؟';

  @override
  String get accountingJournalVoidConfirmMessage =>
      'سيتم إنشاء قيد عكسي متوازن. القيد الأصلي يبقى في الدفاتر للمراجعة.';

  @override
  String get accountingJournalVoidedSuccess => 'تم عكس القيد.';

  @override
  String get accountingJournalNotFound => 'القيد غير موجود.';

  @override
  String get accountingJournalFieldDate => 'التاريخ';

  @override
  String get accountingJournalFieldVoucherNumber => 'رقم السند';

  @override
  String get accountingJournalFieldVoucherType => 'نوع السند';

  @override
  String get accountingJournalFieldDescription => 'الوصف';

  @override
  String get accountingJournalFieldCurrency => 'العملة';

  @override
  String get accountingJournalFieldStatus => 'الحالة';

  @override
  String get accountingJournalPosted => 'مرحّل';

  @override
  String get accountingJournalUnposted => 'غير مرحّل';

  @override
  String accountingJournalSourceLinked(String source) {
    return 'مرتبط بـ $source';
  }

  @override
  String get accountingJournalLines => 'الأسطر';

  @override
  String get accountingJournalAddLine => 'إضافة سطر';

  @override
  String get accountingJournalAccount => 'الحساب';

  @override
  String get accountingJournalDebit => 'مدين';

  @override
  String get accountingJournalCredit => 'دائن';

  @override
  String get accountingJournalTotals => 'الإجماليات';

  @override
  String get accountingJournalPickAccount => 'اختر حساباً';

  @override
  String get accountingJournalErrorUnbalanced =>
      'يجب أن يتساوى إجمالي المدين مع إجمالي الدائن.';

  @override
  String get accountingJournalErrorPeriodClosed =>
      'هذا التاريخ ليس ضمن فترة محاسبية مفتوحة. يرجى فتح الفترة.';

  @override
  String get accountingJournalErrorOutsideFiscalYear =>
      'هذا التاريخ خارج أي سنة مالية مُعرّفة.';

  @override
  String get accountingJournalErrorPostedImmutable =>
      'لا يمكن حذف قيد مرحّل. استخدم العكس المحاسبي.';

  @override
  String get accountingJournalErrorAlreadyReversed =>
      'تم عكس هذا القيد مسبقاً.';

  @override
  String get accountingJournalErrorDebitAccountMissing =>
      'حساب المدين (العميل أو الصندوق) مطلوب قبل الترحيل المحاسبي.';

  @override
  String get accountingFiscalYearsTitle => 'السنوات المالية';

  @override
  String get accountingFiscalYearsSubtitle =>
      'إنشاء السنوات المالية وفتح وإغلاق الفترات المحاسبية.';

  @override
  String get accountingFiscalYearsEmptyTitle => 'لا توجد سنوات مالية بعد';

  @override
  String get accountingFiscalYearsEmptyMessage =>
      'أنشئ سنة مالية للتحكم في الفترات التي تقبل الترحيل.';

  @override
  String get accountingFiscalYearsAdd => 'سنة مالية جديدة';

  @override
  String get accountingFiscalYearDetails => 'السنة المالية';

  @override
  String get accountingFiscalYearCreateTitle => 'إنشاء سنة مالية';

  @override
  String get accountingFiscalYearCode => 'الرمز';

  @override
  String get accountingFiscalYearName => 'الاسم';

  @override
  String get accountingFiscalYearStart => 'تاريخ البداية';

  @override
  String get accountingFiscalYearEnd => 'تاريخ النهاية';

  @override
  String get accountingFiscalYearPeriods => 'عدد الفترات';

  @override
  String get accountingFiscalYearFxEnabled => 'إعادة تقييم العملات الأجنبية';

  @override
  String get accountingFiscalYearFxGainAccount => 'حساب أرباح فروقات العملة';

  @override
  String get accountingFiscalYearFxLossAccount => 'حساب خسائر فروقات العملة';

  @override
  String get accountingFiscalYearPreview => 'معاينة الفترات';

  @override
  String get accountingFiscalYearCreated =>
      'تم إنشاء السنة المالية. افتح فترة قبل الترحيل.';

  @override
  String accountingFiscalYearOpenPeriods(int count) {
    return 'الفترات المفتوحة: $count';
  }

  @override
  String accountingFiscalYearClosedPeriods(int count) {
    return 'الفترات المغلقة: $count';
  }

  @override
  String get accountingFiscalYearFxSummary => 'إعادة تقييم العملات الأجنبية';

  @override
  String get accountingFiscalYearFxGains => 'أرباح فروقات العملة';

  @override
  String get accountingFiscalYearFxLosses => 'خسائر فروقات العملة';

  @override
  String get accountingFiscalYearFxNet => 'صافي فرق العملة';

  @override
  String get accountingFiscalYearFxDeferredHint =>
      'قيود إعادة التقييم الآلية مؤجلة حتى تُخزَّن مبالغ الأساس على بنود القيود.';

  @override
  String get accountingPeriodColumnNumber => '#';

  @override
  String get accountingPeriodColumnName => 'الفترة';

  @override
  String get accountingPeriodColumnRange => 'المدى الزمني';

  @override
  String get accountingPeriodColumnStatus => 'الحالة';

  @override
  String get accountingPeriodColumnActions => 'إجراءات';

  @override
  String get accountingPeriodStatusClosed => 'مغلقة';

  @override
  String get accountingPeriodStatusOpen => 'مفتوحة';

  @override
  String get accountingPeriodStatusClosing => 'جاري الإغلاق';

  @override
  String get accountingPeriodStatusReopened => 'أُعيد فتحها';

  @override
  String get accountingPeriodOpen => 'فتح';

  @override
  String get accountingPeriodClose => 'إغلاق';

  @override
  String get accountingPeriodReopen => 'إعادة فتح';

  @override
  String accountingPeriodOpenConfirmTitle(String name) {
    return 'فتح $name؟';
  }

  @override
  String accountingPeriodOpenConfirmMessage(String start, String end) {
    return 'ستصبح العمليات بتاريخ بين $start و$end متاحة للترحيل المحاسبي.';
  }

  @override
  String accountingPeriodCloseTitle(String name) {
    return 'إغلاق $name';
  }

  @override
  String accountingPeriodCloseUnposted(int count) {
    return 'قيود غير مرحلة: $count';
  }

  @override
  String accountingPeriodCloseMissingRates(String codes) {
    return 'أسعار صرف ناقصة: $codes';
  }

  @override
  String get accountingPeriodCloseBlocked => 'عالج المشكلات أعلاه قبل الإغلاق.';

  @override
  String get accountingPeriodCloseSuccess => 'تم إغلاق الفترة.';

  @override
  String get accountingPeriodOpenSuccess => 'تم فتح الفترة.';

  @override
  String accountingPeriodReopenTitle(String name) {
    return 'إعادة فتح $name؟';
  }

  @override
  String get accountingPeriodReopenReason => 'السبب';

  @override
  String get accountingPeriodReopenSuccess => 'أُعيد فتح الفترة.';

  @override
  String get accountingFiscalWizardStepYear => 'السنة المالية';

  @override
  String get accountingFiscalWizardStepPeriods => 'الفترات';

  @override
  String get accountingFiscalWizardStepFx => 'العملة';

  @override
  String get accountingFiscalWizardStepPreview => 'معاينة';

  @override
  String get accountingFiscalWizardNext => 'التالي';

  @override
  String get accountingFiscalWizardBack => 'رجوع';

  @override
  String get accountingFiscalWizardCreate => 'إنشاء السنة المالية';

  @override
  String get accountingJournalErrorLines => 'أضف سطرين متوازنين على الأقل.';

  @override
  String get accountingJournalManualType => 'قيد يدوي';

  @override
  String get accountingChartOfAccounts => 'الدليل المحاسبي';

  @override
  String get accountingChartOfAccountsDescription =>
      'استعرض وأدر الهيكل الهرمي للحسابات.';

  @override
  String get accountingReportsTitle => 'التقارير المحاسبية';

  @override
  String get accountingReportsSubtitle =>
      'كشوفات وتقارير مالية مبنية على الدليل المحاسبي.';

  @override
  String get accountingReportTrialBalanceTitle => 'ميزان المراجعة';

  @override
  String get accountingReportJournalTitle => 'اليومية';

  @override
  String get accountingReportComingSoonSubtitle => 'ستتوفر في إصدار لاحق.';

  @override
  String get accountingReportComingSoonBadge => 'قريباً';

  @override
  String get accountingCurrencyRatesTitle => 'أسعار العملات';

  @override
  String get accountingCurrencyRatesCardSubtitle =>
      'أضف فقط العملات التي تحتاجها وحدّد أسعارها.';

  @override
  String get accountingCurrencyRatesSubtitle =>
      'أضف العملات عند الحاجة فقط. تظهر هنا العملات المفعّلة مع العملة الأساسية — وستُستخدم لاحقاً لأرصدة الحسابات متعددة العملات.';

  @override
  String accountingCurrencyRatesBase(String code, String name) {
    return 'العملة الأساسية: $code · $name';
  }

  @override
  String get accountingCurrencyRatesBaseBadge => 'أساسية';

  @override
  String get accountingCurrencyRatesBaseHint =>
      'عملة الشركة الأساسية — السعر دائماً 1.';

  @override
  String get accountingCurrencyRatesNotSet => 'السعر غير محدد — اضغط للإدخال.';

  @override
  String accountingCurrencyRatesEquals(String from, String rate, String to) {
    return '1 $from = $rate $to';
  }

  @override
  String accountingCurrencyRatesUpdated(String when) {
    return 'آخر تحديث $when';
  }

  @override
  String get accountingCurrencyRatesEmptyTitle => 'لا توجد عملات مفعّلة';

  @override
  String get accountingCurrencyRatesEmptyMessage =>
      'اضغط «إضافة عملة» لتفعيل عملة وإدخال سعرها.';

  @override
  String get accountingCurrencyRatesAdd => 'إضافة عملة';

  @override
  String get accountingCurrencyRatesAddTitle => 'تفعيل عملة';

  @override
  String get accountingCurrencyRatesAddHint =>
      'اختر العملة التي تحتاجها للنشاط وأدخل سعرها مقابل العملة الأساسية.';

  @override
  String get accountingCurrencyRatesCurrencyField => 'العملة';

  @override
  String get accountingCurrencyRatesRemove => 'إزالة';

  @override
  String get accountingCurrencyRatesRemoveTitle => 'إزالة العملة؟';

  @override
  String accountingCurrencyRatesRemoveMessage(String name, String code) {
    return 'إزالة $name ($code)؟ لن تكون متاحة لأرصدة متعددة العملات حتى تضيفها مجدداً.';
  }

  @override
  String get accountingCurrencyRatesRemoved => 'تمت إزالة العملة.';

  @override
  String accountingCurrencyRatesEditTitle(String code) {
    return 'تعديل سعر $code';
  }

  @override
  String accountingCurrencyRatesEditHint(String currency, String base) {
    return 'كم من $base يساوي وحدة واحدة من $currency؟';
  }

  @override
  String get accountingCurrencyRatesRateField => 'السعر مقابل الأساسية';

  @override
  String accountingCurrencyRatesRateHelper(String base) {
    return 'مثال: إذا كانت الأساسية $base، أدخل كم من $base يساوي وحدة واحدة من هذه العملة.';
  }

  @override
  String get accountingCurrencyRatesInvalid => 'أدخل سعراً موجباً صالحاً.';

  @override
  String get accountingCurrencyRatesSaved => 'تم حفظ سعر العملة.';

  @override
  String get accountingVoucherBooksTitle => 'دفاتر السندات';

  @override
  String get accountingVoucherBooksCardSubtitle =>
      'تهيئة دفاتر الترقيم للمبيعات والمقبوضات وغيرها.';

  @override
  String get accountingVoucherBooksSubtitle =>
      'افتح قسماً ثم اختر نوع الدفتر من القائمة (مثل المقبوضات أو النقل). لكل نوع قائمة دفاتر وزر إضافة خاص به.';

  @override
  String get accountingVoucherBooksEmptyTitle => 'لا توجد دفاتر';

  @override
  String get accountingVoucherBooksEmptyMessage =>
      'أضف دفتراً تحت قسم لتهيئة أرقام السندات المتسلسلة.';

  @override
  String get accountingVoucherBooksAdd => 'إضافة دفتر';

  @override
  String accountingVoucherBooksAddOfType(String type) {
    return 'إضافة $type';
  }

  @override
  String get accountingVoucherBooksAddUnderSection => 'إضافة دفتر في هذا القسم';

  @override
  String accountingVoucherBooksSectionKinds(int kinds, int books) {
    return '$kinds أنواع · $books دفاتر';
  }

  @override
  String accountingVoucherBooksTypeEmptyTitle(String type) {
    return 'لا دفاتر $type';
  }

  @override
  String get accountingVoucherBooksTypeEmptyMessage =>
      'اضغط إضافة لإنشاء دفتر ترقيم لهذا النوع.';

  @override
  String get accountingVoucherBooksEdit => 'تعديل الدفتر';

  @override
  String get accountingVoucherBooksSave => 'حفظ الدفتر';

  @override
  String get accountingVoucherBooksName => 'اسم الدفتر';

  @override
  String get accountingVoucherBooksNameHint =>
      'مثال: مبيعات رئيسي / مردود مبيعات فرع أ';

  @override
  String get accountingVoucherBooksParentSection => 'القسم';

  @override
  String get accountingVoucherBooksType => 'نوع الدفتر';

  @override
  String get accountingVoucherBooksCurrentNumber => 'الرقم الحالي';

  @override
  String get accountingVoucherBooksCurrentNumberHelper =>
      'رقم السند التالي الذي سيُصدر من هذا الدفتر.';

  @override
  String get accountingVoucherBooksEndNumber => 'نهاية الرقم';

  @override
  String get accountingVoucherBooksEndNumberHelper =>
      'آخر رقم متاح في هذا الدفتر.';

  @override
  String accountingVoucherBooksRangePreview(String current, String end) {
    return 'الحالي $current · ينتهي عند $end';
  }

  @override
  String accountingVoucherBooksSectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دفاتر',
      one: 'دفتر واحد',
      zero: 'لا دفاتر بعد',
    );
    return '$_temp0';
  }

  @override
  String get accountingVoucherBooksSectionEmpty =>
      'لا توجد دفاتر في هذا القسم بعد. أضف مبيعات أو مردود أو سلاسل أخرى حسب الحاجة.';

  @override
  String get accountingVoucherBooksNotes => 'ملاحظات';

  @override
  String get accountingVoucherBooksActive => 'نشط';

  @override
  String get accountingVoucherBooksInactive => 'موقوف';

  @override
  String get accountingVoucherBooksDelete => 'حذف';

  @override
  String get accountingVoucherBooksDeleteTitle => 'حذف دفتر السندات؟';

  @override
  String accountingVoucherBooksDeleteMessage(String name) {
    return 'حذف «$name»؟ لا يمكن التراجع عن ذلك.';
  }

  @override
  String get accountingVoucherBooksDeleted => 'تم حذف دفتر السندات.';

  @override
  String get accountingVoucherBooksSaved => 'تم حفظ دفتر السندات.';

  @override
  String get accountingVoucherBooksErrorName => 'أدخل اسم الدفتر.';

  @override
  String get accountingVoucherBooksErrorParent => 'اختر القسم الأب.';

  @override
  String get accountingVoucherBooksErrorCurrentNumber =>
      'الرقم الحالي يجب أن يكون 1 على الأقل.';

  @override
  String get accountingVoucherBooksErrorEndNumber =>
      'نهاية الرقم يجب أن تكون 1 على الأقل.';

  @override
  String get accountingVoucherBooksErrorEndBeforeCurrent =>
      'نهاية الرقم يجب أن تكون أكبر من أو تساوي الرقم الحالي.';

  @override
  String get accountingVoucherBookTypeSales => 'مبيعات';

  @override
  String get accountingVoucherBookTypeSalesReturns => 'مردود المبيعات';

  @override
  String get accountingVoucherBookTypeReceipts => 'مقبوضات';

  @override
  String get accountingVoucherBookTypePayments => 'مدفوعات';

  @override
  String get accountingVoucherBookTypeTransfers => 'النقل بين الصناديق';

  @override
  String get accountingVoucherBookTypeExchanges => 'مصارفة العملات';

  @override
  String get accountingVoucherBookTypeReceiptsPayments =>
      'المقبوضات والمصروفات';

  @override
  String get accountingVoucherBookTypePurchases => 'مشتريات';

  @override
  String get accountingVoucherBookTypePurchaseReturns => 'مردود المشتريات';

  @override
  String get accountingVoucherBookTypeJournal => 'قيود يومية';

  @override
  String get accountingAddAccount => 'إضافة حساب';

  @override
  String get accountingEditAccount => 'تعديل الحساب';

  @override
  String get accountingSaveAccount => 'حفظ الحساب';

  @override
  String get accountingAccountDetails => 'تفاصيل الحساب';

  @override
  String get accountingSearchHint => 'ابحث بالاسم أو الرمز';

  @override
  String get accountingEmptyTitle => 'لا توجد حسابات بعد';

  @override
  String get accountingEmptyMessage =>
      'ستظهر الحسابات الافتراضية عند أول فتح، أو أضف حساباتك.';

  @override
  String get accountingNoSearchResults => 'لا توجد حسابات مطابقة';

  @override
  String get accountingNoSearchResultsMessage => 'جرّب اسماً أو رمزاً مختلفاً.';

  @override
  String get accountingExpandAll => 'توسيع الكل';

  @override
  String get accountingCollapseAll => 'طي الكل';

  @override
  String get accountingShowInactive => 'إظهار غير النشطة';

  @override
  String get accountingHideInactive => 'إخفاء غير النشطة';

  @override
  String get accountingFieldName => 'اسم الحساب';

  @override
  String get accountingFieldCode => 'رمز الحساب';

  @override
  String get accountingFieldCodeHelper =>
      'عند اختيار حساب أب يُولَّد الرقم التالي تلقائياً بعد أعلى رقم موجود (مثال: 1213 ← 1214).';

  @override
  String get accountingGenerateCode => 'توليد الرمز';

  @override
  String get accountingAddChildAccount => 'إضافة حساب فرعي';

  @override
  String get accountingImportTitle => 'استيراد الحسابات';

  @override
  String get accountingImportPageTitle => 'استيراد دليل الحسابات';

  @override
  String get accountingImportSubtitle =>
      'اختر حساباً أباً (مجموعة)، ثم ارفع Excel أو أضف صفوفاً يدوياً، واحفظ مع أرصدة افتتاحية اختيارية.';

  @override
  String get accountingImportParent => 'الحساب الأب (مجموعة)';

  @override
  String get accountingImportOpeningDebit => 'مدين افتتاحي';

  @override
  String get accountingImportOpeningCredit => 'دائن افتتاحي';

  @override
  String get accountingImportCurrency => 'العملة';

  @override
  String get accountingImportRowsTitle => 'الحسابات المراد استيرادها';

  @override
  String get accountingImportAddRow => 'إضافة صف';

  @override
  String get accountingImportRemoveRow => 'حذف الصف';

  @override
  String get accountingImportEmptyRows =>
      'لا توجد صفوف بعد. اختر ملف Excel أو أضف صفاً.';

  @override
  String get accountingImportFormatHintTitle => 'تخطيط Excel للحسابات';

  @override
  String get accountingImportFormatHintIntro =>
      'الصف الأول = عناوين. المطلوب: الاسم. استخدم .xlsx أو .xls. كل الصفوف تُنشأ تحت الحساب الأب المختار.';

  @override
  String get accountingImportFormatColCodeAliases =>
      'Account Code · Code · رمز الحساب';

  @override
  String get accountingImportFormatColNameAliases =>
      'Account Name · Name · اسم الحساب';

  @override
  String get accountingImportFormatColDebitAliases =>
      'Opening Debit · Debit · مدين افتتاحي';

  @override
  String get accountingImportFormatColCreditAliases =>
      'Opening Credit · Credit · دائن افتتاحي';

  @override
  String get accountingImportFormatColCurrencyAliases =>
      'Currency · Currency Code · عملة';

  @override
  String get accountingImportFormatSampleNote =>
      'بدون عناوين تُقرأ الأعمدة كـ: الرمز، الاسم، مدين افتتاحي، دائن افتتاحي، العملة. الرموز المكررة تُتخطى. الأرصدة الافتتاحية تُرحَّل بقيد واحد مقابل رأس المال (3100) مع موازنة لكل عملة.';

  @override
  String accountingImportInsertedCount(int count) {
    return 'تم إدراج $count حساب';
  }

  @override
  String accountingImportSkippedCount(int count) {
    return 'تم تخطي $count مكرر';
  }

  @override
  String get accountingImportOpeningPosted =>
      'تم ترحيل قيد الأرصدة الافتتاحية مقابل رأس المال.';

  @override
  String get accountingImportOpeningVoucherType => 'افتتاحي';

  @override
  String get accountingImportOpeningJournalDescription =>
      'أرصدة افتتاحية من استيراد الحسابات';

  @override
  String get accountingImportErrorParentRequired =>
      'اختر حساباً أباً من نوع مجموعة.';

  @override
  String get accountingImportErrorParentNotGroup =>
      'يجب أن يكون الحساب الأب مجموعة.';

  @override
  String get accountingImportErrorNoRows =>
      'أضف حساباً واحداً على الأقل مع اسم.';

  @override
  String get accountingImportErrorBothSides =>
      'لا يمكن أن يحتوي الصف على مدين ودائن افتتاحيين معاً.';

  @override
  String get accountingImportErrorCapitalMissing =>
      'حساب رأس المال (3100) غير موجود.';

  @override
  String get accountingOpeningSetupTitle =>
      'مركز الاستيراد والأرصدة الافتتاحية';

  @override
  String get accountingOpeningSetupSubtitle =>
      'استورد الحسابات، عيّن أرصدة افتتاحية متعددة العملات لأي حساب ترحيل، ثم رحّل قيداً واحداً مقابل رأس المال (3100).';

  @override
  String get accountingOpeningSetupStepImport => 'استيراد';

  @override
  String get accountingOpeningSetupStepBalances => 'أرصدة';

  @override
  String get accountingOpeningSetupStepReview => 'مراجعة';

  @override
  String get accountingOpeningSetupStepImportHint =>
      'أنشئ حسابات ترحيل تحت حساب أب مجموعة. المبالغ الافتتاحية تُدخل في الخطوة التالية.';

  @override
  String get accountingOpeningSetupStepBalancesHint =>
      'أضف حسابات ترحيل وأدخل سطراً لكل عملة مهيأة (مدين أو دائن). تظهر فقط العملات المفعّلة في أسعار الصرف.';

  @override
  String get accountingOpeningSetupStepReviewHint =>
      'راجع المجاميع لكل عملة، ثم رحّل قيد الافتتاح مقابل رأس المال.';

  @override
  String get accountingOpeningSetupImportFormatIntro =>
      'الصف الأول = عناوين. المطلوب: الاسم. استخدم .xlsx أو .xls. كل الصفوف تُنشأ تحت الحساب الأب المختار.';

  @override
  String get accountingOpeningSetupImportFormatNote =>
      'بدون عناوين تُقرأ الأعمدة كـ: الرمز، الاسم. الرموز المكررة تُتخطى. الأرصدة تُعيَّن في الخطوة 2.';

  @override
  String get accountingOpeningSetupAddAccount => 'إضافة حساب ترحيل';

  @override
  String get accountingOpeningSetupRemoveAccount => 'إزالة الحساب';

  @override
  String get accountingOpeningSetupAddCurrencyLine => 'إضافة سطر عملة';

  @override
  String get accountingOpeningSetupImportBalancesExcel =>
      'استيراد أرصدة من Excel';

  @override
  String get accountingOpeningSetupEmptyBalances =>
      'لا توجد أسطر رصيد بعد. أضف صفاً أو استورد أرصدة من Excel.';

  @override
  String get accountingOpeningSetupContinueToReview => 'متابعة إلى المراجعة';

  @override
  String get accountingOpeningSetupBalancesRowsTitle =>
      'أسطر الأرصدة الافتتاحية';

  @override
  String get accountingOpeningSetupBalancesFormatTitle =>
      'تخطيط Excel للأرصدة الافتتاحية';

  @override
  String get accountingOpeningSetupBalancesFormatNote =>
      'الأعمدة: الرمز أو معرف الحساب، العملة، مدين، دائن. يجب أن تكون العملة مفعّلة مسبقاً في أسعار الصرف. نفس الحساب مرة واحدة لكل عملة. الصفوف تُدمج مع القائمة الحالية.';

  @override
  String accountingOpeningSetupErrorCurrencyNotConfigured(String code) {
    return 'العملة غير مهيأة في النظام: $code';
  }

  @override
  String get accountingOpeningSetupErrorAccountRequired =>
      'اختر حساباً لكل سطر رصيد.';

  @override
  String get accountingOpeningSetupReviewSummaryTitle => 'ملخص حسب العملة';

  @override
  String accountingOpeningSetupCapitalOffset(String code) {
    return 'حساب المقاصة: رأس المال ($code)';
  }

  @override
  String accountingOpeningSetupNetVsCapital(String amount, String side) {
    return 'مقابل رأس المال: $amount ($side)';
  }

  @override
  String accountingOpeningSetupLinesCount(int count) {
    return '$count أسطر رصيد بمبالغ';
  }

  @override
  String get accountingOpeningSetupNoAmountsToPost =>
      'أدخل مبلغ مدين أو دائن واحداً على الأقل قبل الترحيل.';

  @override
  String get accountingOpeningSetupPostJournal => 'ترحيل قيد الافتتاح';

  @override
  String get accountingOpeningSetupPosting => 'جاري ترحيل قيد الافتتاح…';

  @override
  String get accountingOpeningSetupPostSuccess =>
      'تم ترحيل قيد الافتتاح بنجاح مقابل رأس المال.';

  @override
  String get accountingOpeningSetupJournalDescription => 'أرصدة افتتاحية';

  @override
  String get accountingOpeningSetupReset => 'إعادة تعيين الجلسة';

  @override
  String get accountingOpeningSetupCardTitle => 'الاستيراد والأرصدة الافتتاحية';

  @override
  String get accountingOpeningSetupCardSubtitle =>
      'استيراد دليل الحسابات وترحيل أرصدة افتتاحية متعددة العملات.';

  @override
  String accountingOpeningSetupErrorDuplicateCurrency(String name) {
    return 'تكرار عملة لنفس الحساب: $name';
  }

  @override
  String accountingOpeningSetupErrorAccountNotFound(String code) {
    return 'الحساب غير موجود: $code';
  }

  @override
  String get accountingOpeningSetupErrorNoBalanceRows =>
      'لا توجد صفوف أرصدة صالحة في الملف.';

  @override
  String get accountingFieldParent => 'الحساب الأب';

  @override
  String get accountingFieldType => 'نوع الحساب';

  @override
  String get accountingFieldDescription => 'الوصف';

  @override
  String get accountingFieldNormalBalance => 'الرصيد الطبيعي';

  @override
  String get accountingFieldLevel => 'المستوى';

  @override
  String get accountingFieldKind => 'التصنيف';

  @override
  String get accountingFieldStatus => 'الحالة';

  @override
  String get accountingFieldSystem => 'حساب نظام';

  @override
  String get accountingFieldCreatedAt => 'تاريخ الإنشاء';

  @override
  String get accountingFieldUpdatedAt => 'آخر تحديث';

  @override
  String get accountingRootAccount => 'بدون أب (جذر)';

  @override
  String get accountingTypeAsset => 'الأصول';

  @override
  String get accountingTypeLiability => 'الخصوم';

  @override
  String get accountingTypeEquity => 'حقوق الملكية';

  @override
  String get accountingTypeRevenue => 'الإيرادات';

  @override
  String get accountingTypeExpense => 'المصروفات';

  @override
  String get accountingTypeInheritedHint => 'يُورَّث النوع من الحساب الأب.';

  @override
  String get accountingNormalDebit => 'مدين';

  @override
  String get accountingNormalCredit => 'دائن';

  @override
  String get accountingAccountGroup => 'حساب مجموعة';

  @override
  String get accountingAccountGroupHint =>
      'حسابات المجموعة تنظّم الشجرة ولا تُستخدم للترحيل.';

  @override
  String get accountingAccountPosting => 'حساب ترحيل';

  @override
  String get accountingAccountActive => 'نشط';

  @override
  String get accountingAccountInactive => 'غير نشط';

  @override
  String get accountingSystemAccount => 'نظام';

  @override
  String get accountingSystemAccountHint =>
      'حسابات النظام محمية من تغيير الرمز والنوع.';

  @override
  String get accountingYes => 'نعم';

  @override
  String get accountingNo => 'لا';

  @override
  String get accountingComingSoonSection => 'قريباً';

  @override
  String get accountingComingSoonHint => 'متاح بعد تنفيذ القيود اليومية.';

  @override
  String get accountingCurrentBalance => 'الرصيد الحالي';

  @override
  String get accountingTransactions => 'الحركات';

  @override
  String get accountingLedger => 'دفتر الأستاذ';

  @override
  String get accountingDeactivate => 'تعطيل';

  @override
  String get accountingSoftDelete => 'إزالة الحساب';

  @override
  String get accountingDeactivateConfirmTitle => 'تعطيل الحساب؟';

  @override
  String get accountingDeactivateConfirmMessage =>
      'يبقى الحساب في السجل التاريخي لكن لن يُختار للنشاط الجديد.';

  @override
  String get accountingDeleteConfirmTitle => 'إزالة الحساب؟';

  @override
  String get accountingDeleteConfirmMessage =>
      'هذا حذف ناعم. حسابات النظام والحسابات ذات الأبناء لا يمكن إزالتها.';

  @override
  String get accountingSavedSuccess => 'تم حفظ الحساب بنجاح.';

  @override
  String get accountingDeactivatedSuccess => 'تم تعطيل الحساب.';

  @override
  String get accountingDeletedSuccess => 'تمت إزالة الحساب.';

  @override
  String get accountingAccountNotFound => 'الحساب غير موجود.';

  @override
  String get accountingErrorNameRequired => 'اسم الحساب مطلوب.';

  @override
  String get accountingErrorCodeRequired => 'رمز الحساب مطلوب.';

  @override
  String get accountingErrorDuplicateCode => 'يوجد حساب بهذا الرمز مسبقاً.';

  @override
  String get accountingErrorTypeMismatch =>
      'يجب أن يطابق نوع الحساب نوع الحساب الأب.';

  @override
  String get accountingErrorInvalidParent => 'الحساب الأب غير صالح أو غير نشط.';

  @override
  String get accountingErrorCircularParent => 'لا يمكن وضع الحساب تحت نفسه.';

  @override
  String get accountingErrorParentMustBeGroup =>
      'فقط حسابات المجموعة يمكن أن يكون لها أبناء.';

  @override
  String get accountingErrorSystemProtected =>
      'حسابات النظام لا يمكن تعديلها بهذه الطريقة.';

  @override
  String get accountingErrorHasChildren =>
      'أزل أو انقل الحسابات الفرعية أولاً.';

  @override
  String get accountingErrorInUse =>
      'هذا الحساب مستخدم في حركات ولا يمكن إزالته.';

  @override
  String accountingAccountsCount(int count) {
    return '$count حساباً';
  }

  @override
  String accountingSectionChildrenCount(int count) {
    return '$count حساباً';
  }

  @override
  String get accountingFilterAll => 'الكل';

  @override
  String get accountingFilterByType => 'تصفية حسب النوع';

  @override
  String get accountingToolbarActions => 'إجراءات الشجرة';

  @override
  String get accountingAccountAssets => 'الأصول';

  @override
  String get accountingAccountCurrentAssets => 'الأصول المتداولة';

  @override
  String get accountingAccountCashBoxes => 'الصناديق';

  @override
  String get accountingAccountCash => 'الصندوق الرئيسي';

  @override
  String get accountingAccountBank => 'البنك';

  @override
  String get accountingAccountPettyCash => 'العهدة النقدية';

  @override
  String get accountingAccountAccountsReceivable => 'الذمم المدينة';

  @override
  String get accountingAccountCustomers => 'العملاء';

  @override
  String get accountingAccountInventory => 'المخزون';

  @override
  String get accountingAccountInventoryInTransit => 'بضاعة بالطريق';

  @override
  String get accountingAccountVatInput => 'ضريبة مدخلات';

  @override
  String get accountingAccountPrepaidExpenses => 'مصروفات مدفوعة مقدماً';

  @override
  String get accountingAccountOtherCurrentAssets => 'أصول متداولة أخرى';

  @override
  String get accountingAccountFixedAssets => 'الأصول الثابتة';

  @override
  String get accountingAccountBuildings => 'المباني';

  @override
  String get accountingAccountVehicles => 'المركبات';

  @override
  String get accountingAccountEquipment => 'المعدات';

  @override
  String get accountingAccountLiabilities => 'الخصوم';

  @override
  String get accountingAccountCurrentLiabilities => 'الخصوم المتداولة';

  @override
  String get accountingAccountAccountsPayable => 'الذمم الدائنة';

  @override
  String get accountingAccountSuppliers => 'الموردون';

  @override
  String get accountingAccountShortTermLoans => 'قروض قصيرة الأجل';

  @override
  String get accountingAccountVatOutput => 'ضريبة مخرجات مستحقة';

  @override
  String get accountingAccountAccruedExpenses => 'مصروفات مستحقة';

  @override
  String get accountingAccountCustomerAdvances => 'دفعات مقدمة من العملاء';

  @override
  String get accountingAccountLongTermLiabilities => 'الخصوم طويلة الأجل';

  @override
  String get accountingAccountLongTermLoans => 'قروض طويلة الأجل';

  @override
  String get accountingAccountEquity => 'حقوق الملكية';

  @override
  String get accountingAccountCapital => 'رأس المال';

  @override
  String get accountingAccountRetainedEarnings => 'الأرباح المحتجزة';

  @override
  String get accountingAccountRevenue => 'الإيرادات';

  @override
  String get accountingAccountSalesRevenue => 'إيرادات المبيعات';

  @override
  String get accountingAccountOtherRevenue => 'إيرادات أخرى';

  @override
  String get accountingAccountPurchaseDiscounts => 'خصم مكتسب على المشتريات';

  @override
  String get accountingAccountFxGain => 'أرباح فروق العملة';

  @override
  String get accountingAccountExpenses => 'المصروفات';

  @override
  String get accountingAccountCogs => 'تكلفة البضاعة المباعة';

  @override
  String get accountingAccountInventoryAdjustments => 'تسويات / عجز مخزون';

  @override
  String get accountingAccountSalesReturns => 'مردودات المبيعات';

  @override
  String get accountingAccountSalesDiscounts => 'خصم مسموح به للعملاء';

  @override
  String get accountingAccountSalaries => 'الرواتب';

  @override
  String get accountingAccountRent => 'الإيجار';

  @override
  String get accountingAccountUtilities => 'المرافق';

  @override
  String get accountingAccountBankCharges => 'عمولات ورسوم بنكية';

  @override
  String get accountingAccountDepreciation => 'إهلاك';

  @override
  String get accountingAccountAdvertising => 'دعاية وإعلان';

  @override
  String get accountingAccountShippingDelivery => 'نقل وتوصيل';

  @override
  String get accountingAccountMaintenance => 'صيانة';

  @override
  String get accountingAccountOtherExpenses => 'مصروفات أخرى';

  @override
  String get accountingAccountFxLoss => 'خسائر فروق العملة';

  @override
  String get inventoryStockCountService => 'الجرد';

  @override
  String get inventoryStockCountServiceDescription =>
      'عدّ الأصناف واستيراد قوائم المخزون وعرض تقارير الجرد.';

  @override
  String get inventoryProductsService => 'المنتجات';

  @override
  String get inventoryProductsServiceDescription =>
      'إدارة كتالوج المنتجات والأسعار وأحجام العبوة.';

  @override
  String get productsHubTitle => 'المنتجات';

  @override
  String get productsHubDescription =>
      'استعرض الكتالوج أو أدِر الباركود أو استورد من Excel.';

  @override
  String get productsListTitle => 'قائمة المنتجات';

  @override
  String get productsListSubtitle => 'ابحث وأضف وعدّل واحذف المنتجات.';

  @override
  String get productsImportTitle => 'استيراد المنتجات';

  @override
  String get productsImportSubtitle => 'استورد صفوف الكتالوج من ملف Excel.';

  @override
  String get productsBarcodeTitle => 'الباركود';

  @override
  String get productsBarcodeSubtitle =>
      'توليد ومسح ومعاينة وطباعة باركود المنتجات.';

  @override
  String get productsBarcodeSelectHint => 'ابحث أو امسح لاختيار منتج.';

  @override
  String productsBarcodeSearchResults(int count) {
    return '$count منتجاً';
  }

  @override
  String get productsBarcodeNoResults => 'لا توجد منتجات مطابقة للبحث.';

  @override
  String get productsBarcodeChangeProduct => 'تغيير';

  @override
  String get productsBarcodeHasCode => 'يوجد باركود';

  @override
  String get productsBarcodeNoCode => 'بدون باركود';

  @override
  String get productsBarcodeReplaceTitle => 'استبدال الباركود؟';

  @override
  String get productsBarcodeReplaceMessage =>
      'هذا المنتج لديه باركود بالفعل. هل تريد توليد باركود جديد وحفظه؟';

  @override
  String get productsBarcodeSavedSuccess => 'تم حفظ الباركود بنجاح.';

  @override
  String get productsBarcodeMissingForPrint =>
      'ولّد أو عيّن باركوداً قبل الطباعة.';

  @override
  String get productsBarcodePrint => 'طباعة';

  @override
  String get productsBarcodeShare => 'مشاركة';

  @override
  String get productsBarcodeThermalPrint => 'طابعة حرارية';

  @override
  String get productsBarcodeThermalComingSoon =>
      'الطباعة الحرارية ستتوفر في تحديث لاحق.';

  @override
  String get productsSearchHint => 'ابحث بالرمز أو الاسم أو الباركود';

  @override
  String get catalogSearchFieldAll => 'الكل';

  @override
  String get catalogSearchFieldName => 'الاسم';

  @override
  String get catalogSearchFieldCode => 'الرمز';

  @override
  String get catalogSearchFieldBarcode => 'الباركود';

  @override
  String get catalogSearchHintName => 'ابحث بالاسم';

  @override
  String get catalogSearchHintCode => 'ابحث بالرمز';

  @override
  String get catalogSearchHintBarcode => 'ابحث بالباركود';

  @override
  String get catalogSearchFilterLabel => 'البحث في';

  @override
  String get productsEmptyTitle => 'لا توجد منتجات بعد';

  @override
  String get productsEmptyMessage =>
      'أضف منتجاً يدوياً أو استورد كتالوج Excel.';

  @override
  String get productsGoToImport => 'الذهاب للاستيراد';

  @override
  String get productsAdd => 'إضافة منتج';

  @override
  String get productsViewList => 'قائمة';

  @override
  String get productsViewGrid => 'شبكة';

  @override
  String get productsViewModeTooltip => 'تغيير عرض المنتجات';

  @override
  String get productsEdit => 'تعديل منتج';

  @override
  String get productsDelete => 'حذف';

  @override
  String get productsDeleteConfirmTitle => 'حذف المنتج؟';

  @override
  String get productsDeleteConfirmMessage =>
      'سيُزال المنتج من الكتالوج. بيانات الجرد لن تتأثر.';

  @override
  String get productsSavedSuccess => 'تم حفظ المنتج بنجاح.';

  @override
  String get productsDeletedSuccess => 'تم حذف المنتج.';

  @override
  String get productsDuplicateCode => 'يوجد منتج بنفس رمز الصنف.';

  @override
  String get productsDuplicateBarcode => 'يوجد منتج بنفس الباركود.';

  @override
  String get productsInvalidForm =>
      'أدخل رمزاً واسماً وحجم عبوة وسعراً صالحاً.';

  @override
  String get productsItemCodeAutoHint => 'يُنشأ تلقائياً ولا يمكن تعديله.';

  @override
  String get productsFieldLockedHint => 'لا يمكن تعديل هذا الحقل.';

  @override
  String get price => 'السعر';

  @override
  String get priceRequiredHint => 'مثال: 12.50';

  @override
  String get productsImportPageTitle => 'استيراد المنتجات';

  @override
  String get productsImportFormatHintTitle => 'تخطيط Excel للمنتجات';

  @override
  String get productsImportFormatHintIntro =>
      'الصف الأول = عناوين. الأعمدة الأربعة إلزامية. استخدم .xlsx أو .xls.';

  @override
  String get productsImportFormatColPrice => 'السعر';

  @override
  String get productsImportFormatColPriceAliases =>
      'Price · Unit Price · السعر';

  @override
  String get productsImportFormatColPackAliases => 'Pack Size · Pack · العبوة';

  @override
  String get productsImportFormatSampleNote =>
      'بدون عناوين تُقرأ الأعمدة كـ: رمز، اسم، عبوة، سعر.';

  @override
  String get productsImportFormatSamplePriceHeader => 'السعر';

  @override
  String productsImportInsertedCount(int count) {
    return 'أُضيف $count منتجاً';
  }

  @override
  String productsImportUpdatedCount(int count) {
    return 'حُدّث $count منتجاً';
  }

  @override
  String get productsNoValidRows => 'لم يُعثر على صفوف منتجات صالحة في الملف.';

  @override
  String get productsScanBarcode => 'مسح باركود أو QR';

  @override
  String get productsScanAction => 'مسح';

  @override
  String get productsScannerAlignHint => 'وجّه الكاميرا نحو الباركود أو رمز QR';

  @override
  String get productsScannerScanning => 'جاري المسح...';

  @override
  String get productsScannerDetected => 'تم اكتشاف الرمز';

  @override
  String get productsScannerProcessing => 'جاري المعالجة...';

  @override
  String get productsScannerInvalid => 'رمز غير مدعوم';

  @override
  String get productsGenerateBarcode => 'توليد';

  @override
  String get productsGenerateBarcodeTooltip => 'توليد قيمة باركود فريدة';

  @override
  String get productsBarcodePreview => 'معاينة الباركود';

  @override
  String get productsBarcodeTypeLabel => 'نوع الباركود';

  @override
  String get productsBarcodeFormatBarcode => 'باركود';

  @override
  String get productsBarcodeFormatQr => 'رمز QR';

  @override
  String get productsQrCodePreview => 'معاينة رمز QR';

  @override
  String get productsGenerateQrCode => 'توليد رمز QR';

  @override
  String get productsSaveQrCode => 'حفظ رمز QR';

  @override
  String get productsShareQrCode => 'مشاركة رمز QR';

  @override
  String get productsInvalidProductData => 'بيانات المنتج غير صالحة';

  @override
  String get productsQrScanRecognized => 'تم تحميل المنتج من رمز QR';

  @override
  String get productsQrScanOfflineData =>
      'عرض بيانات المنتج من رمز QR (غير موجود في الكتالوج)';

  @override
  String get productsQrProductDetails => 'تفاصيل المنتج';

  @override
  String get productsCodesSection => 'أكواد المنتج';

  @override
  String get productsPrintBarcode => 'طباعة الباركود';

  @override
  String get productsPrintQr => 'طباعة رمز QR';

  @override
  String get productsBarcodeNotFound => 'لم يُعثر على منتج بهذا الباركود.';

  @override
  String get productsCameraPermissionDenied =>
      'يلزم إذن الكاميرا لمسح الباركود.';

  @override
  String get productsCameraUnavailable => 'الكاميرا غير متاحة على هذا الجهاز.';

  @override
  String get productsEnterBarcodeHint =>
      'أدخل الباركود يدوياً، أو استخدم المسح بالكاميرا على Android/iOS بعد إعادة تشغيل التطبيق بالكامل.';

  @override
  String get inventoryOpenStockCount => 'فتح الجرد';

  @override
  String get inventoryCustomizeServices => 'تخصيص';

  @override
  String get inventoryCustomizeServicesHint =>
      'اختر الخدمات التي تظهر، ثم اسحب لإعادة ترتيبها.';

  @override
  String get inventorySaveServices => 'حفظ';

  @override
  String get inventoryPinnedServices => 'الخدمات المثبتة';

  @override
  String get inventoryAvailableServices => 'الخدمات المتاحة';

  @override
  String get inventoryAddService => 'إضافة';

  @override
  String get inventoryRemoveService => 'إزالة';

  @override
  String get inventoryNoServicesTitle => 'لا توجد خدمات في المخزون';

  @override
  String get inventoryNoServicesMessage =>
      'خصّص لتثبيت خدمات المخزون التي تستخدمها أكثر.';

  @override
  String get inventoryNoServicesAvailable => 'لا توجد خدمات مخزون متاحة بعد.';

  @override
  String get modulePlaceholderMessage =>
      'تم تسجيل هذه الوحدة وهي جاهزة. ستُضاف الميزات في المراحل التالية.';

  @override
  String get inventoryOverview => 'نظرة عامة';

  @override
  String get inventoryCountTitle => 'الجرد';

  @override
  String get inventoryCountSubtitle =>
      'ابحث عن الأصناف وأدخل الكميات المعدودة.';

  @override
  String get searchItems => 'بحث الأصناف';

  @override
  String get searchItemsHint => 'ابحث بالاسم أو الرمز';

  @override
  String searchResultsCount(int count) {
    return '$count نتيجة';
  }

  @override
  String get search => 'بحث';

  @override
  String get refresh => 'تحديث';

  @override
  String get noItemSelected => 'لم يتم اختيار صنف';

  @override
  String get saveCount => 'حفظ العدّ';

  @override
  String get editCount => 'تعديل الجرد';

  @override
  String get editCountTitle => 'تعديل الجرد';

  @override
  String get editCountSubtitle => 'أدخل الكميات الجديدة للجرد.';

  @override
  String get countSavedSuccess => 'تم حفظ العدّ بنجاح.';

  @override
  String get negativeQuantityNotAllowed => 'الكميات السالبة غير مسموحة.';

  @override
  String get packSize => 'حجم العبوة';

  @override
  String get packSizeMissingWarning =>
      'هذا المنتج لا يحتوي على عبوة. أدخل حجم العبوة قبل بدء الجرد.';

  @override
  String get packSizeIncompleteMarkerWarning =>
      'اسم المنتج يحتوي على * بدون رقم عبوة. أدخل حجم العبوة للمتابعة.';

  @override
  String get packSizeInvalidWarning =>
      'قيمة العبوة في اسم المنتج غير صالحة. أدخل حجم عبوة صحيح.';

  @override
  String get packSizeRequiredHint => 'مثال: 24';

  @override
  String get savePackSize => 'حفظ العبوة';

  @override
  String get packSizeSavedSuccess => 'تم حفظ العبوة بنجاح.';

  @override
  String get packSizeRequiredBeforeCount =>
      'يجب إدخال حجم العبوة قبل إدخال الجرد.';

  @override
  String get invalidPackSize => 'أدخل حجم عبوة صحيح أكبر من صفر.';

  @override
  String get codeLabel => 'الرمز';

  @override
  String get barcode => 'الباركود';

  @override
  String get mainQuantity => 'الكمية الرئيسية';

  @override
  String get subQuantity => 'الكمية الفرعية';

  @override
  String get systemQuantity => 'الكمية النظامية';

  @override
  String get actualQuantity => 'الكمية الفعلية';

  @override
  String get difference => 'الفرق';

  @override
  String get countDetails => 'تفاصيل الجرد';

  @override
  String get shortageQuantity => 'كمية العجز';

  @override
  String get overageQuantity => 'كمية الزيادة';

  @override
  String get totalItems => 'إجمالي الأصناف';

  @override
  String get countedItems => 'الأصناف المعدودة';

  @override
  String get remainingItems => 'الأصناف المتبقية';

  @override
  String get matched => 'مطابق';

  @override
  String get shortage => 'عجز';

  @override
  String get overage => 'زيادة';

  @override
  String get matchedStatus => 'مطابق';

  @override
  String get shortageStatus => 'عجز';

  @override
  String get overageStatus => 'زيادة';

  @override
  String get notCountedStatus => 'غير معدود';

  @override
  String get allItems => 'كل الأصناف';

  @override
  String get matchedItems => 'الأصناف المطابقة';

  @override
  String get shortageItems => 'أصناف العجز';

  @override
  String get overageItems => 'أصناف الزيادة';

  @override
  String get notCountedItems => 'الأصناف غير المعدودة';

  @override
  String get emptyStateTitle => 'لا توجد أصناف';

  @override
  String get emptyStateSubtitle => 'جرّب بحثًا آخر أو استورد الأصناف أولًا.';

  @override
  String get inventoryEmptyNeedsImportTitle => 'لا توجد أصناف في المخزون بعد';

  @override
  String get inventoryEmptyNeedsImportMessage =>
      'استورد قائمة Excel للبدء في العدّ وعرض التقارير.';

  @override
  String get inventoryGoToImport => 'الانتقال إلى الاستيراد';

  @override
  String get importPageTitle => 'استيراد المخزون';

  @override
  String get selectExcelFile => 'اختر ملف Excel';

  @override
  String get selectedFileName => 'الملف المحدد';

  @override
  String get noFileSelected => 'لم يتم اختيار ملف';

  @override
  String get importButton => 'استيراد';

  @override
  String get importFormatHintTitle => 'شكل ملف Excel';

  @override
  String get importFormatHintIntro =>
      'الصف الأول = عناوين الأعمدة. الصيغة ‎.xlsx أو ‎.xls.';

  @override
  String get importFormatRequired => 'مطلوب';

  @override
  String get importFormatOptional => 'اختياري';

  @override
  String get importFormatColCode => 'رمز الصنف';

  @override
  String get importFormatColCodeAliases => 'Item Code · Code · رقم السلعة';

  @override
  String get importFormatColName => 'اسم الصنف';

  @override
  String get importFormatColNameAliases => 'Item Name · Name · اسم السلعة';

  @override
  String get importFormatColMainQty => 'الكمية الرئيسية';

  @override
  String get importFormatColMainQtyAliases => 'Main Quantity · الكمية الرئيسية';

  @override
  String get importFormatColSubQty => 'الكمية الفرعية';

  @override
  String get importFormatColSubQtyAliases => 'Sub Quantity · الكمية الفرعية';

  @override
  String get importFormatColBarcode => 'الباركود';

  @override
  String get importFormatColBarcodeAliases => 'Barcode · الباركود';

  @override
  String get importFormatColPack => 'حجم العبوة';

  @override
  String get importFormatColPackAliases => 'Pack Size · حجم العبوة';

  @override
  String get importFormatSampleTitle => 'مثال';

  @override
  String get importFormatSampleNote =>
      'بدون عناوين تُقرأ الأعمدة: الرمز، الاسم، كمية رئيسية، كمية فرعية.';

  @override
  String get importFormatSampleCodeHeader => 'رمز الصنف';

  @override
  String get importFormatSampleNameHeader => 'اسم الصنف';

  @override
  String get importFormatSampleMainHeader => 'رئيسي';

  @override
  String get importFormatSampleSubHeader => 'فرعي';

  @override
  String get importFormatSamplePackHeader => 'العبوة';

  @override
  String get importing => 'جاري الاستيراد...';

  @override
  String get importSuccess => 'تم الاستيراد بنجاح.';

  @override
  String get importFailed => 'فشل الاستيراد.';

  @override
  String importedItemsCount(int count) {
    return 'تم استيراد $count صنف';
  }

  @override
  String ignoredRowsCount(int count) {
    return 'تم تجاهل $count صف';
  }

  @override
  String get invalidFile => 'الملف المحدد ليس ملف Excel صالحًا.';

  @override
  String get fileSelectedPrompt => 'يرجى اختيار ملف Excel للمتابعة.';

  @override
  String get reportsTitle => 'التقارير';

  @override
  String get exportReport => 'تصدير التقرير';

  @override
  String get exportSuccess => 'تم تصدير التقرير بنجاح.';

  @override
  String get exportFailed => 'فشل تصدير التقرير.';

  @override
  String get exportNoItems => 'لا توجد أصناف للطباعة وفق التصفية الحالية.';

  @override
  String get exportDataNotReady =>
      'بيانات المخزون غير جاهزة بعد. يرجى الانتظار ثم المحاولة.';

  @override
  String get inventoryReportTitle => 'تقرير جرد المخزون';

  @override
  String get systemMainQuantity => 'كمية نظامية رئيسية';

  @override
  String get systemSubQuantity => 'كمية نظامية فرعية';

  @override
  String get countedMainQuantity => 'كمية جرد رئيسية';

  @override
  String get countedSubQuantity => 'كمية جرد فرعية';

  @override
  String get varianceQuantity => 'العجز / الزيادة';

  @override
  String get varianceMainQuantity => 'عجز/زيادة رئيسية';

  @override
  String get varianceSubQuantity => 'عجز/زيادة فرعية';

  @override
  String get reportSection => 'القسم';

  @override
  String get generatedAt => 'تاريخ الإنشاء';

  @override
  String get inventorySheetName => 'المخزون';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get setupSettingsTitle => 'إعدادات التهيئة';

  @override
  String get setupSettingsSubtitle =>
      'اضبط هوية الشركة وشعارها والعملة الافتراضية والبيانات المرتبطة بها.';

  @override
  String get setupSettingsCardSubtitle =>
      'اسم الشركة والشعار والعملة والبيانات القانونية.';

  @override
  String get moduleSystemSetup => 'الإعدادات';

  @override
  String get moduleSystemSetupDescription =>
      'الشركة والوحدات واللغة والعملة وتهيئة النظام.';

  @override
  String get systemSettingsHubSubtitle =>
      'إدارة بيانات الشركة وإعدادات كل وحدات العمل.';

  @override
  String get systemSetupInitializationSection => 'تهيئة النظام';

  @override
  String get systemSetupReviewSteps => 'مراجعة خطوات التهيئة';

  @override
  String get systemSetupTitle => 'الإعدادات';

  @override
  String get systemSetupSubtitle =>
      'اضبط بيئة عملك. يمكنك المتابعة لاحقاً من حيث توقفت.';

  @override
  String get systemSetupProgressLabel => 'تقدم التهيئة';

  @override
  String systemSetupPercent(int percent) {
    return 'اكتمل $percent%';
  }

  @override
  String get systemSetupRequiredSection => 'خطوات مطلوبة';

  @override
  String get systemSetupOptionalSection => 'خطوات اختيارية';

  @override
  String get systemSetupContinue => 'متابعة';

  @override
  String get systemSetupRetry => 'إعادة المحاولة';

  @override
  String get systemSetupSkip => 'تخطي الآن';

  @override
  String get systemSetupFinish => 'الانتقال للتطبيق';

  @override
  String get systemSetupEditCompany => 'بيانات الشركة';

  @override
  String get systemSetupOpenFromSettings => 'تهيئة النظام';

  @override
  String get systemSetupOpenFromSettingsSubtitle =>
      'راجع تقدم التهيئة أو أعد تشغيل خطوات الإعداد.';

  @override
  String get systemSetupStepWelcome => 'وضع التشغيل';

  @override
  String get systemSetupStepWelcomeHint =>
      'اختر محاسبة محلية مستقلة أو الربط بنظام خارجي.';

  @override
  String get systemSetupStepCompany => 'ملف الشركة';

  @override
  String get systemSetupStepCompanyHint => 'اسم الشركة وبداية السنة المالية.';

  @override
  String get systemSetupStepLocale => 'اللغة';

  @override
  String get systemSetupStepLocaleHint =>
      'اختر لغة التطبيق أو أبقِ لغة الجهاز.';

  @override
  String get systemSetupStepPrimaryCurrency => 'العملة الرئيسية';

  @override
  String get systemSetupStepPrimaryCurrencyHint =>
      'اختر العملة الأساسية للنظام. لا يمكن تغييرها لاحقاً.';

  @override
  String get systemSetupCurrencyLocked =>
      'العملة الرئيسية مقفلة ولا يمكن تغييرها.';

  @override
  String get systemSetupStepSeed => 'دليل الحسابات';

  @override
  String get systemSetupStepSeedHint =>
      'أنشئ الدليل على هذا الجهاز (الجهاز الأول) أو زامنه من خادم الشركة (جهاز منضم).';

  @override
  String get systemSetupStepExternal => 'الاتصال الخارجي';

  @override
  String get systemSetupStepExternalHint =>
      'إعداد اتصال ERP عند استخدام الوضع المتكامل.';

  @override
  String get systemSetupStepSync => 'المزامنة الأولية';

  @override
  String get systemSetupStepSyncHint => 'تشغيل مزامنة عند توفر خادم بعيد.';

  @override
  String get systemSetupModeStandalone => 'مستقل';

  @override
  String get systemSetupModeStandaloneHint =>
      'يملك التطبيق بيانات المحاسبة والقيود محلياً.';

  @override
  String get systemSetupModeIntegrated => 'متكامل';

  @override
  String get systemSetupModeIntegratedHint =>
      'يعمل بجانب نظام محاسبة/ERP قائم.';

  @override
  String get systemSetupLocaleSystem => 'استخدام لغة الجهاز';

  @override
  String get systemSetupLocaleEnglish => 'الإنجليزية';

  @override
  String get systemSetupLocaleArabic => 'العربية';

  @override
  String get systemSetupSeedRunning => 'جارٍ تجهيز البيانات الافتراضية…';

  @override
  String get systemSetupSeedDone => 'دليل الحسابات ودفاتر السندات جاهزة.';

  @override
  String get systemSetupSeedCreateLocalTitle => 'إنشاء محلياً';

  @override
  String get systemSetupSeedCreateLocalSubtitle =>
      'إنشاء دليل الحسابات الافتراضي على هذا الجهاز. للجهاز الأول أو عند العمل دون اتصال.';

  @override
  String get systemSetupSeedSyncTitle => 'مزامنة من الخادم';

  @override
  String get systemSetupSeedSyncSubtitle =>
      'سجّل الدخول وادخل التطبيق. يُنزَّل دليل الشركة في الخلفية حتى لا يُنشأ دليل مكرر.';

  @override
  String get systemSetupSeedSyncRunning => 'جارٍ تنزيل دليل الحسابات…';

  @override
  String get systemSetupSeedSyncDone =>
      'يمكنك الدخول الآن. مزامنة الدليل تُكمل في الخلفية.';

  @override
  String get systemSetupSeedSignInToSync => 'تسجيل الدخول للمزامنة';

  @override
  String get systemSetupSeedErrorSyncRequired =>
      'فعّل المزامنة وسجّل الدخول ثم أعد المحاولة.';

  @override
  String get systemSetupSeedErrorAuth =>
      'سجّل الدخول إلى خادم الشركة ثم أعد المحاولة.';

  @override
  String get systemSetupSeedErrorOffline =>
      'اتصل بالإنترنت لمزامنة دليل الحسابات.';

  @override
  String get systemSetupSeedErrorEmpty =>
      'لا يوجد دليل حسابات على الخادم بعد. أنشئه محلياً على الجهاز الأول وزامنه، ثم أعد المحاولة هنا.';

  @override
  String get systemSetupSeedErrorPull =>
      'تعذر تنزيل دليل الحسابات. حاول مرة أخرى.';

  @override
  String get systemSetupExternalPlaceholder =>
      'محولات ERP تُسجَّل من طبقة التطبيق. يمكنك التخطي والربط لاحقاً من الإعدادات.';

  @override
  String get systemSetupSyncRunning => 'جارٍ المزامنة…';

  @override
  String get systemSetupSyncDone => 'اكتملت المزامنة.';

  @override
  String get systemSetupSyncSkippedHint =>
      'يمكنك المزامنة في أي وقت من الإعدادات.';

  @override
  String get systemSetupStatusPending => 'قيد الانتظار';

  @override
  String get systemSetupStatusInProgress => 'قيد التنفيذ';

  @override
  String get systemSetupStatusCompleted => 'مكتمل';

  @override
  String get systemSetupStatusFailed => 'فشل';

  @override
  String get systemSetupStatusSkipped => 'تم التخطي';

  @override
  String get systemSetupReadyTitle => 'أصبحت جاهزاً';

  @override
  String get systemSetupReadyMessage =>
      'اكتملت الخطوات المطلوبة. يمكن إكمال الاختيارية لاحقاً.';

  @override
  String get systemSetupErrorGeneric =>
      'فشلت هذه الخطوة. عالج المشكلة ثم أعد المحاولة.';

  @override
  String get setupCompanyIdentitySection => 'هوية الشركة';

  @override
  String get setupCompanyName => 'اسم الشركة';

  @override
  String get setupCompanyNameRequired => 'اسم الشركة مطلوب.';

  @override
  String get setupLegalName => 'الاسم القانوني';

  @override
  String get setupLegalNameHelper =>
      'الاسم الرسمي المسجل إن اختلف عن اسم العرض.';

  @override
  String get setupPickLogo => 'اختيار الشعار';

  @override
  String get setupRemoveLogo => 'إزالة الشعار';

  @override
  String get setupLogoUpdated => 'تم تحديث شعار الشركة.';

  @override
  String get setupLogoRemoved => 'تم إزالة شعار الشركة.';

  @override
  String get setupLogoFailed => 'تعذر تحديث الشعار. جرّب صورة أخرى.';

  @override
  String get setupCurrencySection => 'العملة والسنة المالية';

  @override
  String get setupCurrencySectionSubtitle =>
      'تُستخدم افتراضياً للمبالغ والفواتير والتقارير.';

  @override
  String get setupDefaultCurrency => 'العملة الافتراضية';

  @override
  String get setupFiscalYearStart => 'بداية السنة المالية';

  @override
  String get setupFiscalYearStartHelper => 'أول شهر في سنتك المحاسبية.';

  @override
  String get setupLegalSection => 'المعرّفات القانونية';

  @override
  String get setupTaxNumber => 'الرقم الضريبي / VAT';

  @override
  String get setupCommercialRegister => 'السجل التجاري';

  @override
  String get setupContactSection => 'التواصل والعنوان';

  @override
  String get setupPhone => 'الهاتف';

  @override
  String get setupEmail => 'البريد الإلكتروني';

  @override
  String get setupWebsite => 'الموقع الإلكتروني';

  @override
  String get setupAddress => 'العنوان';

  @override
  String get setupCity => 'المدينة';

  @override
  String get setupCountry => 'الدولة';

  @override
  String get setupInvoiceHeaderSection => 'رأس فاتورة البيع';

  @override
  String get setupInvoiceHeaderSectionSubtitle =>
      'نص العمودين الأيمن والأيسر حول شعار الشركة في رأس الفاتورة المطبوعة.';

  @override
  String get setupInvoiceHeaderRight => 'نص العمود الأيمن';

  @override
  String get setupInvoiceHeaderLeft => 'نص العمود الأيسر';

  @override
  String get setupInvoiceHeaderHelper =>
      'يمكن كتابة عدة أسطر (مثل العنوان أو الهاتف).';

  @override
  String get setupSavedSuccess => 'تم حفظ إعدادات التهيئة.';

  @override
  String get settingsGeneralSection => 'عام';

  @override
  String get settingsGeneralSectionSubtitle => 'المظهر واللغة للتطبيق بالكامل.';

  @override
  String get settingsDataSection => 'البيانات والمزامنة';

  @override
  String get settingsDataSectionSubtitle => 'حالة الاتصال والمزامنة اليدوية.';

  @override
  String get settingsModulesSection => 'الوحدات';

  @override
  String get settingsModulesSectionSubtitle => 'إعدادات تملكها كل وحدة أعمال.';

  @override
  String get settingsAboutSectionSubtitle => 'هوية التطبيق والصيانة.';

  @override
  String get settingsResetHint =>
      'استعادة المظهر واللغة وإعدادات الوحدات إلى الافتراضي.';

  @override
  String get appearance => 'المظهر';

  @override
  String get lightTheme => 'الوضع الفاتح';

  @override
  String get darkTheme => 'الوضع الداكن';

  @override
  String get systemTheme => 'حسب النظام';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'الإنجليزية';

  @override
  String get arabic => 'العربية';

  @override
  String get about => 'حول التطبيق';

  @override
  String get applicationName => 'اسم التطبيق';

  @override
  String get version => 'الإصدار';

  @override
  String get buildNumber => 'رقم البناء';

  @override
  String get resetApplication => 'إعادة ضبط الإعدادات';

  @override
  String get resetApplicationConfirmationTitle => 'إعادة ضبط الإعدادات؟';

  @override
  String get resetApplicationConfirmationMessage =>
      'ستُعاد تفضيلات المظهر واللغة إلى القيم الافتراضية.';

  @override
  String get success => 'نجاح';

  @override
  String get failure => 'فشل';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsEmptyTitle => 'لا توجد إشعارات';

  @override
  String get notificationsEmptyMessage => 'أنت على اطلاع بكل جديد.';

  @override
  String get notificationsMarkAllRead => 'تعليم الكل كمقروء';

  @override
  String get notificationsTooltip => 'الإشعارات';

  @override
  String get notificationsUnreadBadge => 'غير مقروء';

  @override
  String notificationsSummaryTotal(int count) {
    return '$count إشعارات';
  }

  @override
  String notificationsSummaryUnread(int count) {
    return '$count غير مقروء';
  }

  @override
  String get notificationsSummaryAllRead => 'الكل مقروء';

  @override
  String get notificationsTimeJustNow => 'الآن';

  @override
  String notificationsTimeMinutes(int count) {
    return 'منذ $count د';
  }

  @override
  String notificationsTimeHours(int count) {
    return 'منذ $count س';
  }

  @override
  String notificationsTimeDays(int count) {
    return 'منذ $count ي';
  }

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get exitAppTitle => 'هل تريد الخروج؟';

  @override
  String get exitAppMessage => 'هل أنت متأكد من أنك تريد الخروج من التطبيق؟';

  @override
  String get exitAppConfirm => 'خروج';

  @override
  String get unsavedChangesTitle => 'تغييرات غير محفوظة';

  @override
  String get unsavedChangesMessage =>
      'لديك تغييرات غير محفوظة. هل أنت متأكد أنك تريد المغادرة؟';

  @override
  String get leave => 'مغادرة';

  @override
  String get splashSubtitle => 'منصة إدارة الأعمال';

  @override
  String get splashInitErrorTitle => 'تعذر تشغيل التطبيق';

  @override
  String get splashInitErrorMessage => 'حدث خطأ أثناء تهيئة التطبيق.';

  @override
  String get appLockTitle => 'التطبيق مقفل';

  @override
  String get appLockSubtitle =>
      'أدخل رمز PIN للمتابعة. هذا يحمي التطبيق على هذا الجهاز — جلستك ما زالت نشطة.';

  @override
  String get appLockPinLabel => 'رمز PIN';

  @override
  String get appLockConfirmPinLabel => 'تأكيد الرمز';

  @override
  String get appLockCurrentPinLabel => 'الرمز الحالي';

  @override
  String get appLockNewPinLabel => 'الرمز الجديد';

  @override
  String get appLockUnlockAction => 'فتح القفل';

  @override
  String get appLockShowPin => 'إظهار الرمز';

  @override
  String get appLockHidePin => 'إخفاء الرمز';

  @override
  String get appLockErrorInvalid => 'رمز غير صحيح. حاول مرة أخرى.';

  @override
  String get appLockErrorLockout =>
      'محاولات كثيرة. انتظر قليلاً ثم حاول مجدداً.';

  @override
  String get appLockErrorLength => 'يجب أن يكون الرمز من 4 إلى 6 أرقام.';

  @override
  String get appLockErrorDigits => 'الرمز يجب أن يحتوي أرقاماً فقط.';

  @override
  String get appLockErrorMismatch => 'تأكيد الرمز غير متطابق.';

  @override
  String get appLockSettingsSection => 'الأمان';

  @override
  String get appLockSettingsTitle => 'قفل التطبيق';

  @override
  String get appLockSettingsEnabledHint =>
      'يُطلب الرمز عند العودة إلى التطبيق.';

  @override
  String get appLockSettingsDisabledHint => 'أضف رمزاً لحماية التطبيق محلياً.';

  @override
  String get appLockEnableTitle => 'تفعيل قفل التطبيق';

  @override
  String get appLockEnableMessage =>
      'اختر رمزاً من 4 إلى 6 أرقام. ستحتاجه كلما أُقفل التطبيق.';

  @override
  String get appLockDisableTitle => 'إيقاف قفل التطبيق';

  @override
  String get appLockDisableMessage => 'أدخل الرمز الحالي لإيقاف قفل التطبيق.';

  @override
  String get appLockChangePin => 'تغيير الرمز';

  @override
  String get appLockChangePinHint => 'حدّث رمز PIN الحالي.';

  @override
  String get appLockBiometricTitle => 'الفتح بالبصمة';

  @override
  String get appLockBiometricHint =>
      'استخدم البصمة أو المقاييس الحيوية للجهاز للفتح.';

  @override
  String get appLockBiometricUnavailable =>
      'المقاييس الحيوية غير متاحة على هذا الجهاز.';

  @override
  String get appLockBiometricPrompt => 'صادِق لفتح NexaBiz';

  @override
  String get appLockBiometricEnabledSuccess => 'تم تفعيل الفتح بالبصمة.';

  @override
  String get appLockBiometricUnlockAction => 'استخدم البصمة';

  @override
  String get appLockPolicyLabel => 'متى يُقفل';

  @override
  String get appLockPolicyDisabled => 'معطّل';

  @override
  String get appLockPolicyOnResume => 'عند العودة من الخلفية';

  @override
  String get appLockPolicyOnResumeHint =>
      'يطلب الرمز بعد وضع التطبيق في الخلفية.';

  @override
  String get appLockPolicyColdStart => 'عند إعادة فتح التطبيق فقط';

  @override
  String get appLockPolicyColdStartHint =>
      'يطلب الرمز بعد إغلاق التطبيق بالكامل.';

  @override
  String get appLockEnabledSuccess => 'تم تفعيل قفل التطبيق.';

  @override
  String get appLockDisabledSuccess => 'تم إيقاف قفل التطبيق.';

  @override
  String get appLockPinChangedSuccess => 'تم تحديث الرمز.';

  @override
  String get onboardingSkip => 'تخطي';

  @override
  String get onboardingNext => 'التالي';

  @override
  String get onboardingStart => 'ابدأ الآن';

  @override
  String get onboardingPage1Title => 'مرحباً بك في NexaBiz';

  @override
  String get onboardingPage1Body =>
      'منصتك للعمل دون اتصال لإدارة المخزون والمبيعات والعملاء والمحاسبة في مكان واحد.';

  @override
  String get onboardingPage2Title => 'يعمل بالكامل دون اتصال';

  @override
  String get onboardingPage2Body =>
      'استخدم المخزون والمبيعات والمحاسبة على هذا الجهاز دون شبكة. المزامنة اختيارية — فعّلها لاحقاً من الإعدادات فقط إذا احتجت مزامنة بين الأجهزة.';

  @override
  String get onboardingPage3Title => 'هيّئ شركتك';

  @override
  String get onboardingPage3Body =>
      'في الخطوة التالية ستضبط بيانات الشركة والعملة وطريقة عمل النظام بما يناسب نشاطك.';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get somethingWentWrong => 'حدث خطأ ما';

  @override
  String get permissionDenied => 'ليست لديك صلاحية لتنفيذ هذا الإجراء.';

  @override
  String get errorStateSubtitle =>
      'حاول مرة أخرى. إذا استمرت المشكلة، تحقق من البيانات ثم عد لاحقاً.';

  @override
  String get moduleComingSoon => 'قريباً';

  @override
  String get navigationHome => 'الرئيسية';

  @override
  String get navigationDashboard => 'لوحة التحكم';

  @override
  String get navigationServices => 'الخدمات';

  @override
  String get navigationReports => 'التقارير';

  @override
  String get quickActionsTitle => 'عمليات سريعة';

  @override
  String get quickActionsSubtitle =>
      'اختصاراتك المثبتة. خصّص للإضافة أو إعادة الترتيب.';

  @override
  String get quickActionsCreateProduct => 'إنشاء منتج';

  @override
  String get quickActionsCreateProductSubtitle => 'فتح نموذج منتج جديد.';

  @override
  String get quickActionsScanBarcode => 'مسح باركود أو QR';

  @override
  String get quickActionsScanBarcodeSubtitle =>
      'امسح باركود أو QR واعرض المنتج.';

  @override
  String get quickActionsCustomize => 'تخصيص';

  @override
  String get quickActionsCustomizeTitle => 'تخصيص العمليات السريعة';

  @override
  String get quickActionsCustomizeHint =>
      'اختر العمليات التي تظهر، ثم اسحب لإعادة ترتيبها.';

  @override
  String get quickActionsPinned => 'العمليات المثبتة';

  @override
  String get quickActionsAvailable => 'العمليات المتاحة';

  @override
  String get quickActionsAdd => 'إضافة';

  @override
  String get quickActionsRemove => 'إزالة';

  @override
  String get quickActionsSave => 'حفظ';

  @override
  String quickActionsPinnedCount(int count, int max) {
    return '$count / $max مثبتة';
  }

  @override
  String quickActionsMaxReached(int max) {
    return 'يمكنك تثبيت حتى $max عمليات سريعة.';
  }

  @override
  String get quickActionsEmptyPinned =>
      'لا توجد اختصارات مثبتة بعد. اضغط تخصيص لإضافتها.';

  @override
  String get quickActionsEmptyMessage =>
      'ثبّت اختصارات هنا للوصول الأسرع. ستتمكن من تخصيصها لاحقاً.';

  @override
  String get quickActionsAddLabel => 'إضافة عملية';

  @override
  String get quickActionsComingSoon => 'تخصيص العمليات السريعة قريباً.';

  @override
  String get dashboardTitle => 'لوحة التحكم';

  @override
  String get dashboardSubtitle => 'نظرة عامة على منصة إدارة أعمالك.';

  @override
  String get dashboardOpenServices => 'تصفح كل الخدمات';

  @override
  String get dashboardOpenSettings => 'فتح الإعدادات';

  @override
  String get dashboardMyServices => 'خدماتي';

  @override
  String get dashboardCustomizeServices => 'تخصيص';

  @override
  String get dashboardCustomizeTitle => 'تخصيص خدمات لوحة التحكم';

  @override
  String get dashboardCustomizeServicesHint =>
      'اختر الخدمات التي تظهر في لوحة التحكم، ثم اسحب لإعادة ترتيبها.';

  @override
  String get dashboardPinnedServices => 'الخدمات المثبتة';

  @override
  String get dashboardAvailableServices => 'الخدمات المتاحة';

  @override
  String get dashboardAddService => 'إضافة';

  @override
  String get dashboardRemoveService => 'إزالة';

  @override
  String get dashboardSaveServices => 'حفظ';

  @override
  String dashboardPinnedCount(int count, int max) {
    return '$count / $max مثبتة';
  }

  @override
  String dashboardServicesMaxReached(int max) {
    return 'يمكنك تثبيت حتى $max خدمات في لوحة التحكم.';
  }

  @override
  String get dashboardNoServicesTitle => 'لا توجد خدمات في لوحة التحكم';

  @override
  String get dashboardNoServicesMessage =>
      'خصّص لوحة التحكم لإضافة الخدمات التي تستخدمها أكثر.';

  @override
  String get dashboardNoModulesAvailable => 'لا توجد خدمات متاحة حالياً.';

  @override
  String get dashboardStatsComingSoon => 'قريباً';

  @override
  String get dashboardStatsSlideOverviewTitle => 'المخزون';

  @override
  String get dashboardStatsSlideOverviewSubtitle =>
      'مؤشرات الأداء اليومية ستظهر هنا.';

  @override
  String get dashboardStatsSlideSalesTitle => 'المبيعات';

  @override
  String get dashboardStatsSlideSalesSubtitle =>
      'ملخص المبيعات والفترات سيُضاف لاحقاً.';

  @override
  String get dashboardStatsSlideBalanceTitle => 'المتحصلات';

  @override
  String get dashboardStatsSlideBalanceSubtitle =>
      'أرصدة العملاء والصناديق قادمة قريباً.';

  @override
  String get dashboardStatsPeriodToday => 'اليوم';

  @override
  String get dashboardStatsPeriodWeek => 'هذا الأسبوع';

  @override
  String get dashboardStatsPeriodMonth => 'هذا الشهر';

  @override
  String get dashboardStatsCurrencyHint => 'ر.ي';

  @override
  String get dashboardStatsItemsLabel => 'صنف';

  @override
  String get dashboardStatsInvoicesLabel => 'الفواتير';

  @override
  String get dashboardStatsCustomersLabel => 'عملاء نشطون';

  @override
  String get dashboardStatsLowStockLabel => 'أصناف منخفضة';

  @override
  String get dashboardRecentOperations => 'العمليات الأخيرة';

  @override
  String get dashboardRecentOperationsEmpty => 'لا توجد عمليات بيع حديثة بعد.';

  @override
  String get dashboardRecentOperationsViewAll => 'عرض الكل';

  @override
  String get dashboardRecentSaleInvoice => 'فاتورة بيع';

  @override
  String dashboardRecentSaleInvoiceLine(String type, String number) {
    return 'فاتورة بيع $type برقم $number';
  }

  @override
  String get platformReportsTitle => 'التقارير';

  @override
  String get platformReportsSubtitle => 'اختر وحدة لاستعراض تقارير خدماتها.';

  @override
  String get platformReportsInventory => 'تقارير المخزون';

  @override
  String get platformReportsInventorySubtitle => 'تقارير الجرد والمنتجات.';

  @override
  String get platformReportsBusiness => 'تقارير الأعمال PDF';

  @override
  String get platformReportsBusinessSubtitle =>
      'تقارير المبيعات والتقارير المشتركة مع معاينة PDF.';

  @override
  String get platformReportsComingSoon =>
      'ستتوفر التقارير متعددة الوحدات في إصدار لاحق.';

  @override
  String get platformReportsStockCountTitle => 'تقرير الجرد';

  @override
  String get platformReportsStockCountSubtitle =>
      'ملخص الجرد والفروقات والتصدير.';

  @override
  String get platformReportsProductsTitle => 'تقرير المنتجات';

  @override
  String get platformReportsServiceComingSoon => 'تقارير هذه الخدمة قريباً.';

  @override
  String get notFoundTitle => 'الصفحة غير موجودة';

  @override
  String get notFoundMessage => 'الصفحة التي تبحث عنها غير موجودة.';

  @override
  String get goToDashboard => 'الذهاب إلى لوحة التحكم';

  @override
  String get availableQuantity => 'الكمية المتاحة';

  @override
  String get statusBreakdown => 'توزيع الحالات';

  @override
  String get itemName => 'اسم الصنف';

  @override
  String get status => 'الحالة';

  @override
  String get exportAs => 'تصدير كـ';

  @override
  String get exportExcel => 'Excel (.xlsx)';

  @override
  String get exportPdf => 'PDF (.pdf)';

  @override
  String exportPath(String path) {
    return 'تم الحفظ في: $path';
  }

  @override
  String get shareExport => 'مشاركة';

  @override
  String get previousPage => 'الصفحة السابقة';

  @override
  String get nextPage => 'الصفحة التالية';

  @override
  String paginationPage(int current, int total) {
    return 'صفحة $current من $total';
  }

  @override
  String paginationRange(int from, int to, int total) {
    return '$from-$to من $total';
  }

  @override
  String get paginationItemsPerPage => 'عدد العناصر في الصفحة';

  @override
  String get importParsing => 'جاري تحليل ملف Excel...';

  @override
  String get importSaving => 'جاري حفظ الأصناف...';

  @override
  String get importLinking => 'جاري ربط الدليل المحاسبي…';

  @override
  String get emptyWorkbook => 'ملف Excel فارغ أو لا يحتوي على أوراق.';

  @override
  String get noValidRows => 'لم يتم العثور على صفوف مخزون صالحة في الملف.';

  @override
  String duplicateRowsCount(int count) {
    return 'تم استبدال $count رموز مكررة';
  }

  @override
  String get syncSectionTitle => 'المزامنة';

  @override
  String get syncEnabledTitle => 'تفعيل المزامنة';

  @override
  String get syncEnabledSubtitle =>
      'اختيارية. أبقِ البيانات على هذا الجهاز فقط، أو سجّل الدخول للخادم للمزامنة بين الأجهزة.';

  @override
  String get syncDisabledMessage =>
      'المزامنة معطّلة. تبقى البيانات المحلية على هذا الجهاز.';

  @override
  String get syncAuthRequiredHint =>
      'سجّل الدخول بحساب الخادم. تبقى المزامنة معطّلة حتى نجاح المصادقة.';

  @override
  String get syncAuthCancelled => 'لم يتم تفعيل المزامنة. المصادقة مطلوبة.';

  @override
  String get syncPermissionRequired =>
      'هذا الحساب لا يملك صلاحية المزامنة. اطلب من المسؤول منح sync.view أو sync.execute للدور.';

  @override
  String get syncSessionAuthenticated => 'جلسة مزامنة مصادَق عليها نشطة.';

  @override
  String syncSessionAsUser(String email) {
    return 'مسجّل الدخول كـ $email';
  }

  @override
  String get syncSessionExpired =>
      'انتهت الجلسة. سجّل الدخول مجدداً لمتابعة المزامنة.';

  @override
  String get syncAutoTitle => 'مزامنة تلقائية';

  @override
  String get syncAutoSubtitle =>
      'تعمل في الخلفية دون إعاقة استخدام التطبيق. يمكنك أيضاً المزامنة يدوياً في أي وقت.';

  @override
  String get syncAutoIntervalLabel => 'التكرار';

  @override
  String get syncAutoIntervalOnChange => 'عند وجود تغييرات معلّقة';

  @override
  String syncAutoIntervalMinutes(int minutes) {
    return 'كل $minutes دقيقة';
  }

  @override
  String get syncDisableRequestSent =>
      'تم إرسال طلب للمدير. تبقى المزامنة مفعّلة حتى يوافق.';

  @override
  String get syncDisableRequestFailed =>
      'تعذّر إبلاغ المدير. تحقق من الاتصال ثم أعد المحاولة.';

  @override
  String get syncDisableNeedsAdminOnline =>
      'إلغاء المزامنة يحتاج موافقة المدير. اتصل وسجّل الدخول لإرسال الطلب.';

  @override
  String get adminDevicesTitle => 'الأجهزة';

  @override
  String get adminDevicesSubtitle => 'الأجهزة المسجّلة وطلبات إلغاء المزامنة';

  @override
  String adminDevicesPendingCount(int count) {
    return '$count طلبات إلغاء معلّقة';
  }

  @override
  String get adminDevicesListIntro =>
      'عرض كل الأجهزة المرتبطة بهذه الشركة. إلغاء جهاز ينهي جلساته ويمنع المزامنة.';

  @override
  String get adminDevicesListSection => 'الأجهزة المسجّلة';

  @override
  String get adminDevicesRequestsSection => 'طلبات إلغاء المزامنة';

  @override
  String get adminDevicesListEmptyTitle => 'لا أجهزة بعد';

  @override
  String get adminDevicesListEmptyMessage =>
      'تظهر الأجهزة هنا بعد تسجيل الدخول للمزامنة.';

  @override
  String get adminDevicesListLoadError => 'تعذّر تحميل الأجهزة';

  @override
  String get adminDevicesUntitled => 'جهاز بدون اسم';

  @override
  String get adminDevicesStatusActive => 'نشط';

  @override
  String get adminDevicesStatusRevoked => 'ملغى';

  @override
  String get adminDevicesStatusBlocked => 'محظور';

  @override
  String get adminDevicesLastSeenNever => 'آخر ظهور: لم يُرَ بعد';

  @override
  String adminDevicesLastSeen(String when) {
    return 'آخر ظهور: $when';
  }

  @override
  String get adminDevicesRevokeAction => 'إلغاء الجهاز';

  @override
  String get adminDevicesRevokeCancel => 'إلغاء';

  @override
  String get adminDevicesRevokeConfirmTitle => 'إلغاء هذا الجهاز؟';

  @override
  String get adminDevicesRevokeConfirmMessage =>
      'سيفقد الجهاز صلاحية المزامنة فوراً. يحتاج المستخدم لتسجيل الدخول من جديد.';

  @override
  String get adminDevicesRevokeSuccess => 'تم إلغاء الجهاز.';

  @override
  String get adminDevicesDisableRequestsIntro =>
      'المستخدم غير المدير لا يستطيع إيقاف المزامنة بنفسه. وافق لإيقافها على جهازه، أو ارفض لإبقائها مفعّلة.';

  @override
  String get adminDevicesDisableRequestHint =>
      'طلب هذا المستخدم إلغاء المزامنة على جهازه.';

  @override
  String get adminDevicesApproveAction => 'إيقاف على الجهاز';

  @override
  String get adminDevicesRejectAction => 'إبقاء المزامنة';

  @override
  String get adminDevicesApproveSuccess => 'سيتم إيقاف مزامنة الجهاز.';

  @override
  String get adminDevicesRejectSuccess => 'تم رفض الطلب. المزامنة تبقى مفعّلة.';

  @override
  String get adminDevicesEmptyTitle => 'لا طلبات معلّقة';

  @override
  String get adminDevicesEmptyMessage =>
      'عند طلب مستخدم إلغاء المزامنة يظهر الطلب هنا.';

  @override
  String get adminDevicesLoadError => 'تعذّر تحميل طلبات الأجهزة';

  @override
  String get adminDevicesRefresh => 'تحديث';

  @override
  String get adminDevicesUnknownUser => 'مستخدم غير معروف';

  @override
  String get syncServerSectionTitle => 'خادم المزامنة';

  @override
  String get syncServerUrlLabel => 'عنوان الخادم';

  @override
  String get syncServerUrlHint => 'http://192.168.1.10:8000';

  @override
  String get syncServerUrlRequired => 'أدخل عنوان خادم المزامنة أولاً.';

  @override
  String get syncServerUrlInvalid =>
      'أدخل عنواناً صالحاً يبدأ بـ http:// أو https://.';

  @override
  String get syncServerTokenLabel => 'رمز API (اختياري)';

  @override
  String get syncServerTokenHint => 'اتركه فارغاً للإبقاء على الرمز الحالي';

  @override
  String get syncServerSaveAction => 'حفظ الخادم';

  @override
  String get syncServerSaved => 'تم حفظ إعدادات الخادم.';

  @override
  String get syncBackendLabel => 'خادم المزامنة';

  @override
  String get syncConnectionLabel => 'الاتصال';

  @override
  String get syncConnectionOnline => 'متصل';

  @override
  String get syncConnectionOffline => 'غير متصل';

  @override
  String get syncLastSyncLabel => 'آخر مزامنة';

  @override
  String get syncLastSyncNever => 'لم تتم بعد';

  @override
  String syncLastPassMetrics(int uploaded, int downloaded, int ms) {
    return 'آخر تمريرة: ↑$uploaded ↓$downloaded · $ms مللي ثانية';
  }

  @override
  String get syncPendingChangesLabel => 'تغييرات معلّقة';

  @override
  String get syncFailedChangesLabel => 'تغييرات فشلت';

  @override
  String get syncNowAction => 'مزامنة الآن';

  @override
  String get syncCheckIncomingAction => 'جلب تغييرات الخادم';

  @override
  String get syncCheckingIncoming => 'جاري الطلب من الخادم…';

  @override
  String get syncOfflineMessage =>
      'أنت غير متصل. اتصل بالإنترنت ثم اضغط «مزامنة الآن».';

  @override
  String get syncStatusSynced => 'تمت المزامنة';

  @override
  String get syncStatusSyncing => 'جاري المزامنة…';

  @override
  String get syncStatusPending => 'معلّق';

  @override
  String get syncStatusFailed => 'فشلت المزامنة';

  @override
  String get syncStatusConflict => 'تعارض';

  @override
  String get syncStatusRejected => 'غير مصرّح';

  @override
  String get syncStatusOffline => 'غير متصل';

  @override
  String get syncCompletedTitle => 'اكتملت المزامنة';

  @override
  String get syncCompletedMessage => 'تمت مزامنة جميع التغييرات.';

  @override
  String get syncIncomingNone => 'لا توجد تغييرات جديدة من الخادم.';

  @override
  String syncIncomingCount(int count) {
    return 'تم استلام $count تغييرات من الخادم';
  }

  @override
  String syncIncomingSummary(int count, String details) {
    return '$count من الخادم: $details';
  }

  @override
  String syncIncomingEntityCount(String label, int count) {
    return '$label $count';
  }

  @override
  String get syncIncomingFromServerTitle => 'قادم من الخادم';

  @override
  String get syncEntityProduct => 'منتجات';

  @override
  String get syncEntityInventoryItem => 'عناصر مخزون';

  @override
  String get syncEntityCustomer => 'عملاء';

  @override
  String get syncEntityAccount => 'حسابات';

  @override
  String get syncEntityJournalEntry => 'قيود يومية';

  @override
  String get syncEntitySale => 'مبيعات';

  @override
  String get syncPartialTitle => 'تعذّرت مزامنة بعض التغييرات';

  @override
  String get syncFailedTitle => 'فشلت المزامنة';

  @override
  String get syncFailedMessage => 'يرجى المحاولة لاحقاً.';

  @override
  String get loadingPleaseWait => 'يرجى الانتظار…';

  @override
  String get loadingProcessing => 'جاري المعالجة…';

  @override
  String get loadingSaving => 'جاري الحفظ…';

  @override
  String get loadingDeleting => 'جاري الحذف…';

  @override
  String get loadingImportingProducts => 'جاري استيراد المنتجات…';

  @override
  String get loadingImportingInventory => 'جاري استيراد المخزون…';

  @override
  String get loadingSavingInventory => 'جاري حفظ الجرد…';

  @override
  String get loadingSynchronizing => 'جاري المزامنة…';

  @override
  String get loadingExportingReport => 'جاري إعداد التقرير…';

  @override
  String get authLoginTitle => 'تسجيل الدخول';

  @override
  String get authLoginSubtitle => 'سجّل الدخول للمزامنة الآمنة عبر أجهزتك.';

  @override
  String get authLoginLocalHint =>
      'سجّل الدخول بحسابك المحلي دون إنترنت. يجب تغيير كلمة مرور الأدمن الافتراضية قبل استخدام التطبيق.';

  @override
  String get authEmailLabel => 'البريد الإلكتروني';

  @override
  String get authPasswordLabel => 'كلمة المرور';

  @override
  String get authSignIn => 'دخول';

  @override
  String get authSigningIn => 'جاري الدخول…';

  @override
  String get authChangePasswordTitle => 'تغيير كلمة المرور';

  @override
  String get authChangePasswordHint =>
      'لا يمكن استخدام كلمة مرور الأدمن الافتراضية في الإنتاج. اختر كلمة مرور جديدة من 8 أحرف على الأقل.';

  @override
  String get authCurrentPasswordLabel => 'كلمة المرور الحالية';

  @override
  String get authNewPasswordLabel => 'كلمة المرور الجديدة';

  @override
  String get authConfirmPasswordLabel => 'تأكيد كلمة المرور الجديدة';

  @override
  String get authChangePasswordAction => 'حفظ كلمة المرور';

  @override
  String get authChangingPassword => 'جاري الحفظ…';

  @override
  String get authPasswordMismatch => 'كلمتا المرور غير متطابقتين.';

  @override
  String get authPasswordWrongCurrent => 'كلمة المرور الحالية غير صحيحة.';

  @override
  String get authPasswordSameAsDefault =>
      'اختر كلمة مرور مختلفة عن كلمة المرور الافتراضية.';

  @override
  String get authBiometricSignIn => 'الدخول بالبصمة';

  @override
  String get authBiometricPrompt => 'صادِق للدخول إلى المزامنة';

  @override
  String get authBiometricSaveForNext => 'استخدم البصمة في المرة القادمة';

  @override
  String get authBiometricUnavailable => 'البصمة غير متاحة على هذا الجهاز.';

  @override
  String get authBiometricRequiredFirst =>
      'يرجى تسجيل الدخول باسم المستخدم وكلمة المرور لتفعيل البصمة.';

  @override
  String get authBiometricPromptReason =>
      'تأكيد الهوية لتسجيل الدخول السريع عبر البصمة';

  @override
  String get authBiometricFailed =>
      'فشل التحقق بالبصمة. حاول مرة أخرى أو استخدم كلمة المرور.';

  @override
  String get authLoginFailed => 'البريد أو كلمة المرور غير صحيحة.';

  @override
  String get authNetworkError =>
      'تعذّر الوصول للخادم. تحقق من الشبكة وعنوان الـ API.';

  @override
  String get authLoginGenericError => 'فشل تسجيل الدخول. حاول مرة أخرى.';

  @override
  String get authSelectCompanyTitle => 'اختر الشركة';

  @override
  String get authLogoutAction => 'تسجيل الخروج';

  @override
  String get authSessionExpired => 'انتهت الجلسة. يرجى تسجيل الدخول مجدداً.';

  @override
  String get moduleAdministration => 'الإدارة';

  @override
  String get moduleAdministrationDescription =>
      'المستخدمون والأدوار والتحكم بالوصول';

  @override
  String get adminRequiresOnlineTitle => 'مطلوب اتصال';

  @override
  String get adminRequiresOnlineMessage =>
      'إدارة المستخدمين تتطلب جلسة مزامنة مصادَق عليها واتصالاً بالشبكة.';

  @override
  String get adminUsersTitle => 'المستخدمون';

  @override
  String get adminUsersSubtitle => 'إنشاء وإدارة مستخدمي التطبيق';

  @override
  String get adminRolesTitle => 'الأدوار والصلاحيات';

  @override
  String get adminRolesSubtitle => 'أنشئ أدواراً وعيّن الصلاحيات كما تريد';

  @override
  String get adminRolesHubSubtitle =>
      'ابنِ أدواراً مخصصة وتحكّم بما يستطيع كل دور فعله';

  @override
  String get adminAccessControlSection => 'التحكم بالوصول';

  @override
  String get adminAccessControlIntro =>
      'أدر من يستخدم التطبيق وما يمكنه رؤيته أو تعديله. الدور يجمع الصلاحيات، والمستخدم يحصل على دور.';

  @override
  String get adminAccessControlTip =>
      'نصيحة: أنشئ الدور أولاً واختر الصلاحيات بعناية (خصوصاً المحاسبة)، ثم عيّن الدور عند إنشاء المستخدم.';

  @override
  String get adminPermissionsCatalogTitle => 'كتالوج الصلاحيات';

  @override
  String get adminPermissionsCatalogSubtitle =>
      'استعرض كل الصلاحيات حسب الوحدة';

  @override
  String get adminPermissionsCatalogIntro =>
      'هذه لبنات التحكم بالوصول. اربطها بالأدوار — ولا تثبتها داخل الشاشات.';

  @override
  String get adminRolesPageIntro =>
      'الأدوار المخصصة قابلة للتعديل بالكامل. أدوار النظام تأتي من الخادم ومحمية.';

  @override
  String get adminRolesSearchHint => 'ابحث عن دور بالاسم';

  @override
  String get adminRolesFilterAll => 'الكل';

  @override
  String get adminRolesFilterCustom => 'مخصص';

  @override
  String get adminRolesFilterSystem => 'نظام';

  @override
  String get adminRolesStatTotal => 'الإجمالي';

  @override
  String get adminSystemRoleHint => 'دور مدمج يديره الخادم';

  @override
  String get adminCustomRoleHint => 'دورك — عدّل الاسم والصلاحيات في أي وقت';

  @override
  String get adminTapToConfigure => 'اضغط للضبط';

  @override
  String get adminUsersSearchHint => 'بحث بالاسم أو البريد';

  @override
  String get adminUsersLoadError => 'تعذّر تحميل المستخدمين';

  @override
  String get adminUsersEmptyTitle => 'لا يوجد مستخدمون';

  @override
  String get adminUsersEmptyMessage => 'أنشئ مستخدماً لمنح صلاحية الوصول.';

  @override
  String get adminCreateUser => 'إنشاء مستخدم';

  @override
  String get adminEditUser => 'تعديل مستخدم';

  @override
  String get adminSuspendUser => 'تعليق';

  @override
  String get adminActivateUser => 'تفعيل';

  @override
  String get adminDeactivateUser => 'إلغاء التفعيل';

  @override
  String get adminUserUpdated => 'تم تحديث المستخدم';

  @override
  String get adminUserNameLabel => 'الاسم';

  @override
  String get adminUserPhoneLabel => 'الهاتف';

  @override
  String get adminUserStatusLabel => 'الحالة';

  @override
  String get adminUserRoleLabel => 'الدور';

  @override
  String get adminStatusActive => 'نشط';

  @override
  String get adminStatusInactive => 'غير نشط';

  @override
  String get adminStatusSuspended => 'معلّق';

  @override
  String get adminNewPasswordOptional => 'كلمة مرور جديدة (اختياري)';

  @override
  String get adminConfirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get adminUserValidationError => 'الاسم والبريد مطلوبان.';

  @override
  String get adminPasswordTooShort =>
      'يجب أن تكون كلمة المرور 8 أحرف على الأقل.';

  @override
  String get adminPasswordMismatch => 'كلمتا المرور غير متطابقتين.';

  @override
  String get adminRolesLoadError => 'تعذّر تحميل الأدوار';

  @override
  String get adminRolesEmptyTitle => 'لا توجد أدوار';

  @override
  String get adminRolesEmptyMessage => 'أنشئ دوراً مخصصاً واختر صلاحياته.';

  @override
  String get adminSystemRole => 'دور نظام';

  @override
  String get adminCustomRole => 'دور مخصص';

  @override
  String get adminCreateRole => 'إنشاء دور';

  @override
  String get adminEditRole => 'تعديل الدور';

  @override
  String get adminDeleteRole => 'حذف الدور';

  @override
  String adminDeleteRoleConfirm(String name) {
    return 'حذف الدور \"$name\"؟ يبقى حساب المستخدم لكن يفقد هذه الصلاحيات حتى يُعاد تعيين دور.';
  }

  @override
  String get adminRoleDeleted => 'تم حذف الدور';

  @override
  String get adminRoleNameLabel => 'اسم الدور';

  @override
  String get adminRoleNameHint => 'مثال: موظف مبيعات';

  @override
  String get adminRoleDescriptionLabel => 'الوصف';

  @override
  String get adminRoleDescriptionHint => 'الغرض من هذا الدور';

  @override
  String get adminRoleBasicsSection => 'تفاصيل الدور';

  @override
  String get adminRoleBasicsHint =>
      'اختر اسماً واضحاً ليسهل تعيينه للمستخدمين.';

  @override
  String get adminRoleCapabilitiesSection => 'ما يمكن لهذا الدور فتحه';

  @override
  String get adminRoleCapabilitiesHint =>
      'يتحدّث مباشرة أثناء تفعيل الصلاحيات أدناه.';

  @override
  String get adminRolePermissionsSection => 'الصلاحيات';

  @override
  String get adminRoleVisibleModules => 'الوحدات التي يفتحها هذا الدور';

  @override
  String get adminRoleNoModulesYet =>
      'لا وحدات بعد — اختر صلاحية عرض واحدة على الأقل.';

  @override
  String get adminSelectAllPermissions => 'تحديد الكل';

  @override
  String get adminClearPermissions => 'مسح';

  @override
  String get adminRoleNameRequired => 'اسم الدور مطلوب.';

  @override
  String get adminRolePermissionsRequired => 'اختر صلاحية واحدة على الأقل.';

  @override
  String get adminPermissionsSearchHint => 'بحث بالاسم أو الإجراء أو الرمز';

  @override
  String get adminPermissionsLoadError => 'تعذّر تحميل الصلاحيات';

  @override
  String get adminPermissionsEmptyTitle => 'لا نتائج';

  @override
  String get adminPermissionsEmptyMessage =>
      'جرّب بحثاً آخر أو ألغِ فلتر الوحدة.';

  @override
  String adminPermissionCount(int count) {
    return '$count صلاحيات';
  }

  @override
  String adminSelectedPermissionsCount(int count) {
    return '$count محددة';
  }

  @override
  String adminGroupPermissionSummary(int selected, int total) {
    return '$selected من $total';
  }

  @override
  String get adminSystemRoleReadOnly =>
      'أدوار النظام محمية. قد تكون تعديلات الصلاحيات مقيدة.';

  @override
  String get adminPermActionView => 'عرض';

  @override
  String get adminPermActionCreate => 'إنشاء';

  @override
  String get adminPermActionUpdate => 'تعديل';

  @override
  String get adminPermActionDelete => 'حذف';

  @override
  String get adminPermActionManage => 'إدارة';

  @override
  String get adminPermActionAdjust => 'تسوية';

  @override
  String get adminPermActionPost => 'ترحيل';

  @override
  String get adminPermActionCancel => 'إلغاء';

  @override
  String get adminPermActionExecute => 'تنفيذ';

  @override
  String get adminPermActionRevoke => 'إبطال';

  @override
  String get adminPermResourceAccounts => 'الحسابات';

  @override
  String get adminPermResourceJournals => 'القيود';

  @override
  String get adminPermResourceDevices => 'الأجهزة';

  @override
  String get adminPermResourceCompanies => 'الشركات';

  @override
  String get adminPermGroupSalesHint => 'مستندات المبيعات والترحيل';

  @override
  String get adminPermGroupCustomersHint => 'بيانات العملاء';

  @override
  String get adminPermGroupInventoryHint => 'المنتجات والمخزون';

  @override
  String get adminPermGroupAccountingHint => 'وصول مالي حسّاس';

  @override
  String get adminPermGroupReportsHint => 'التقارير والتصدير';

  @override
  String get adminPermGroupAdminHint => 'المستخدمون والأدوار والتحكم';

  @override
  String get adminPermGroupSettingsHint => 'إعدادات التطبيق';

  @override
  String get adminPermGroupSyncHint => 'إجراءات المزامنة';

  @override
  String get adminPermGroupOtherHint => 'صلاحيات أخرى';

  @override
  String get adminPermTreeHint =>
      'منظمة مثل التطبيق: حزمة ← خدمة ← عملية. مثال: المخزون ← الجرد ← استيراد.';

  @override
  String get adminPermTreeCatalogIntro =>
      'خريطة كاملة للحزم وخدماتها وكل عملية يمكن منحها لدور.';

  @override
  String get adminPermPackagePlatform => 'المنصة';

  @override
  String get adminPermPackageInventoryHint => 'خدمات الجرد والمنتجات';

  @override
  String get adminPermPackageSalesHint => 'مستندات المبيعات والفواتير';

  @override
  String get adminPermPackageCustomersHint => 'العملاء والحسابات والإعدادات';

  @override
  String get adminPermPackageAccountingHint =>
      'الحسابات والقيود والأسعار ودفاتر السندات';

  @override
  String get adminPermPackageReportsHint => 'التقارير التشغيلية والمالية';

  @override
  String get adminPermPackageAdminHint => 'المستخدمون والأدوار والصلاحيات';

  @override
  String get adminPermPackagePlatformHint =>
      'الإعدادات والمزامنة والأجهزة والشركات';

  @override
  String adminPermPackageSummary(int services, int selected, int total) {
    return '$services خدمات · $selected/$total عمليات';
  }

  @override
  String get adminPermServiceSalesDocuments => 'مستندات المبيعات';

  @override
  String get adminPermServiceSalesDocumentsHint =>
      'عرض وإنشاء وترحيل وإلغاء وطباعة الفواتير';

  @override
  String get adminPermServiceCustomersMaster => 'قائمة العملاء';

  @override
  String get adminPermServiceCustomersMasterHint => 'إنشاء وإدارة العملاء';

  @override
  String get adminPermServiceCustomersAccounts => 'حسابات العملاء';

  @override
  String get adminPermServiceCustomersAccountsHint =>
      'استعراض دليل الحسابات المرتبط';

  @override
  String get adminPermServiceCustomersSettings => 'إعدادات العملاء';

  @override
  String get adminPermServiceCustomersSettingsHint =>
      'الحساب الأب والربط التلقائي';

  @override
  String get adminPermServiceChartOfAccounts => 'دليل الحسابات';

  @override
  String get adminPermServiceChartOfAccountsHint => 'إنشاء وصيانة الحسابات';

  @override
  String get adminPermServiceJournals => 'القيود اليومية';

  @override
  String get adminPermServiceJournalsHint => 'إنشاء وإدارة القيود';

  @override
  String get adminPermServiceCurrencyRates => 'أسعار العملات';

  @override
  String get adminPermServiceCurrencyRatesHint => 'صيانة أسعار الصرف';

  @override
  String get adminPermServiceVoucherBooks => 'دفاتر السندات';

  @override
  String get adminPermServiceVoucherBooksHint =>
      'دفاتر الترقيم حسب نوع المستند';

  @override
  String get adminPermServiceFiscalYears => 'السنوات المالية';

  @override
  String get adminPermServiceFiscalYearsHint =>
      'السنوات المالية والفترات المحاسبية';

  @override
  String get adminPermActionOpenPeriod => 'فتح فترة';

  @override
  String get adminPermActionClosePeriod => 'إغلاق فترة';

  @override
  String get adminPermActionReopenPeriod => 'إعادة فتح فترة';

  @override
  String get adminPermActionConfigureFx => 'إعداد إعادة تقييم العملة';

  @override
  String get adminPermServiceAccountingReports => 'تقارير المحاسبة';

  @override
  String get adminPermServiceAccountingReportsHint => 'مركز تقارير المحاسبة';

  @override
  String get adminPermServiceSalesPeriod => 'تقرير فترة المبيعات';

  @override
  String get adminPermServiceSalesPeriodHint => 'مبيعات الفترة مع التصدير';

  @override
  String get adminPermServiceAccountStatement => 'كشف حساب';

  @override
  String get adminPermServiceAccountStatementHint =>
      'كشف حساب عميل/حساب مع التصدير';

  @override
  String get adminPermServiceTrialBalance => 'ميزان المراجعة';

  @override
  String get adminPermServiceTrialBalanceHint =>
      'تقرير ميزان المراجعة مع التصدير';

  @override
  String get adminPermServiceJournalBook => 'دفتر اليومية';

  @override
  String get adminPermServiceJournalBookHint => 'تقرير دفتر اليومية مع التصدير';

  @override
  String get adminPermServiceDevicesHint => 'أجهزة المزامنة المسجّلة';

  @override
  String get adminPermServiceCompaniesHint =>
      'ملف الشركة وأدوات الشركات على المنصة';

  @override
  String get adminPermOpStockCount => 'تنفيذ الجرد';

  @override
  String get adminPermOpImport => 'استيراد';

  @override
  String get adminPermOpExport => 'تصدير';

  @override
  String get adminPermOpReportsExport => 'عرض / تصدير التقارير';

  @override
  String get adminPermOpClear => 'مسح البيانات';

  @override
  String get adminPermOpBarcode => 'الباركود والملصقات';

  @override
  String get adminPermOpDuplicate => 'تكرار';

  @override
  String get adminPermOpInvoiceExport => 'طباعة / مشاركة الفاتورة';

  @override
  String get adminPermOpPlatformCompanies => 'إدارة الشركات (منصة)';

  @override
  String get adminPermOpPlatformUsers => 'إدارة المستخدمين (منصة)';

  @override
  String get setupChoiceTitle => 'كيف تريد الإعداد؟';

  @override
  String get setupChoiceSubtitle => 'اختر كيفية إدارة nexabiz لبيانات أعمالك';

  @override
  String get setupChoiceServerTitle => 'الاتصال بالخادم';

  @override
  String get setupChoiceServerSubtitle =>
      'مزامنة البيانات عبر أجهزة متعددة مع خادم مركزي';

  @override
  String get setupChoiceLocalTitle => 'الاستخدام المحلي';

  @override
  String get setupChoiceLocalSubtitle =>
      'تشغيل كل شيء على هذا الجهاز، لا يتطلب اتصال بالإنترنت';

  @override
  String get serverSetupTitle => 'الاتصال بالخادم';

  @override
  String get serverSetupSubtitle => 'أدخل عنوان خادم المزامنة للبدء';

  @override
  String get serverSetupUrlLabel => 'عنوان الخادم';

  @override
  String get serverSetupUrlHint => 'http://192.168.1.10:8000';

  @override
  String get serverSetupValidate => 'فحص الاتصال';

  @override
  String get serverSetupValidating => 'جاري فحص اتصال الخادم...';

  @override
  String get serverSetupValidSuccess => 'تم الاتصال بالخادم بنجاح';

  @override
  String get serverSetupValidFailed => 'تعذر الاتصال بالخادم';

  @override
  String get serverSetupContinueToSignIn => 'المتابعة لتسجيل الدخول';

  @override
  String get serverSetupBackToChoice => 'العودة لخيارات الإعداد';

  @override
  String get onboardingWelcomeTitle => 'مرحباً بك في NexaBiz';

  @override
  String get onboardingWelcomeSubtitle =>
      'منصتك المتكاملة لإدارة الأعمال. دعنا نقوم بإعدادك في بضع خطوات فقط.';

  @override
  String get onboardingGetStarted => 'ابدأ الآن';

  @override
  String get authServerUrlRequired => 'يرجى إدخال عنوان السيرفر';

  @override
  String authServerVerificationFailed(int statusCode) {
    return 'تعذر التحقق من السيرفر (رمز الاستجابة: $statusCode)';
  }

  @override
  String get authServerConnectionError =>
      'تعذر الاتصال بالسيرفر. يرجى التأكد من صحة العنوان والاتصال بالشبكة.';

  @override
  String get authSyncModeLabel => 'وضع المزامنة';

  @override
  String get authLocalModeLabel => 'الوضع المحلي';

  @override
  String get authSwitchToLocalMode => 'التبديل إلى الوضع المحلي (Offline)';

  @override
  String get authSwitchToSyncMode => 'التبديل إلى وضع المزامنة (Server Sync)';

  @override
  String get authServerSetupTitle => 'إعداد عنوان السيرفر';

  @override
  String get authServerSetupSubtitle =>
      'أدخل عنوان السيرفر واضغط للتحقق من الاتصال قبل الدخول.';

  @override
  String get authServerUrlLabel => 'عنوان السيرفر';

  @override
  String get authServerVerifying => 'جاري التحقق من السيرفر...';

  @override
  String get authServerVerifyAndNext => 'التحقق من السيرفر والتالي';

  @override
  String get authChangeServer => 'تغيير السيرفر';

  @override
  String get authAppSubtitle => 'نظام إدارة الأعمال والحسابات الذكي';

  @override
  String get authSecurityFooter =>
      'اتصال مشفّر وآمن وفق أعلى المعايير القياسية';

  @override
  String get syncSummaryTitle => 'تفاصيل صندوق الصادر';

  @override
  String get syncSummaryPending => 'في انتظار الرفع';

  @override
  String get syncSummaryConflicts => 'تعارضات التزامن';

  @override
  String get syncSummaryFailed => 'محاولات فاشلة';

  @override
  String get syncDiagnosticsTitle => 'صحة الخادم والاتصال';

  @override
  String get syncDiagnosticsServerConnected => 'متصل';

  @override
  String get syncDiagnosticsServerDisconnected => 'غير متصل';

  @override
  String get syncDiagnosticsResponse => 'الحالة';

  @override
  String get syncDiagnosticsLatency => 'الاستجابة';

  @override
  String get syncInspectorTitle => 'مفتش صندوق الصادر';

  @override
  String syncInspectAction(int count) {
    return 'استعراض صندوق الصادر ($count)';
  }

  @override
  String get syncHistoryTitle => 'سجل المزامنة الأخير';

  @override
  String get syncHistoryEmpty => 'لا توجد عمليات مزامنة سابقة مسجلة.';

  @override
  String syncHistoryPassItem(
    String time,
    int uploaded,
    int downloaded,
    int ms,
  ) {
    return 'مزامنة $time: ↑$uploaded ↓$downloaded ($msمللي ثانية)';
  }

  @override
  String syncRetryFailedAction(int count) {
    return 'إعادة محاولة الفاشلة ($count)';
  }

  @override
  String get syncOfflineHint =>
      'أنت حالياً غير متصل بالإنترنت. التغييرات المحلية محفوظة بأمان وستتم مزامنتها تلقائياً عند عودة الاتصال.';

  @override
  String get syncOutboxInspectorTooltip => 'مفتش صندوق الصادر';

  @override
  String syncPassCompletedSuccess(int uploaded, int downloaded) {
    return 'اكتملت المزامنة: $uploaded تم رفعه، $downloaded تم تنزيله.';
  }

  @override
  String syncPassCompletedWarnings(int failed, int conflicts) {
    return 'اكتملت المزامنة مع $failed عملية فاشلة و $conflicts تعارض.';
  }

  @override
  String get syncPassUpToDate => 'المزامنة محدّثة بالكامل.';

  @override
  String syncOutboxTitle(int count) {
    return 'مفتش صندوق الصادر ($count)';
  }

  @override
  String get syncOutboxEmpty => 'لا توجد عمليات في صندوق الصادر';

  @override
  String syncOutboxTabAll(int count) {
    return 'الكل ($count)';
  }

  @override
  String syncOutboxTabIssues(int count) {
    return 'مشاكل ($count)';
  }

  @override
  String syncOutboxTabPending(int count) {
    return 'معلّق ($count)';
  }

  @override
  String get syncOutboxPurge => 'مسح العملية';

  @override
  String get syncOutboxRetryNow => 'إعادة المحاولة الآن';

  @override
  String get syncOutboxDetailsTitle => 'تفاصيل العملية';
}
