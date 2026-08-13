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
  String get salesStatusDraft => 'مسودة';

  @override
  String get salesStatusPending => 'بانتظار المحاسبة';

  @override
  String get salesStatusConfirmed => 'مؤكدة';

  @override
  String get salesStatusCompleted => 'مكتملة';

  @override
  String get salesStatusCancelled => 'ملغاة';

  @override
  String get salesStatusRejected => 'مرفوضة';

  @override
  String get salesNotes => 'ملاحظات';

  @override
  String get salesSave => 'حفظ الفاتورة';

  @override
  String get salesSaveAndConfirm => 'حفظ وتأكيد';

  @override
  String get salesSaving => 'جاري حفظ الفاتورة…';

  @override
  String get salesLoadingInvoice => 'جاري تحميل الفاتورة…';

  @override
  String get salesConfirming => 'جاري تأكيد الفاتورة…';

  @override
  String get salesSaved => 'تم حفظ الفاتورة';

  @override
  String get salesConfirmed => 'تم تأكيد الفاتورة';

  @override
  String get salesCompleted => 'اكتملت الفاتورة';

  @override
  String get salesCancelled => 'تم إلغاء الفاتورة';

  @override
  String get salesDuplicated => 'تم تكرار الفاتورة';

  @override
  String get salesConfirmSale => 'تأكيد الفاتورة';

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
      'أدخل حساب ترحيل موجوداً تحت حساب أصل العملاء المُعدّ. لا يُنشأ حساب تلقائياً.';

  @override
  String customersAccountLinked(String code, String name) {
    return 'مرتبط: $code · $name';
  }

  @override
  String get customersAccountLinkInvalid =>
      'لا يوجد حساب ترحيل مطابق لهذا الرمز.';

  @override
  String customersAccountMustBeUnderParent(String code, String name) {
    return 'يجب أن يكون الحساب المرتبط تحت الأصل $code · $name.';
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
      'لم يُحدد حساب الأصل. اضبطه من الإعدادات.';

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
      'البيانات المحاسبية المحلية هي المرجع. لا تُنشأ قيود يومية تلقائياً من المستندات التشغيلية.';

  @override
  String get accountingModeIntegratedHint =>
      'يمكن تجهيز المستندات التشغيلية هنا وترحيلها لاحقاً في النظام الخارجي. لا تُنشأ قيود يومية تلقائياً.';

  @override
  String get accountingModeSavedSuccess => 'تم حفظ وضع المحاسبة.';

  @override
  String get accountingChartOfAccounts => 'الدليل المحاسبي';

  @override
  String get accountingChartOfAccountsDescription =>
      'استعرض وأدر الهيكل الهرمي للحسابات.';

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
      'افتح قسماً ثم استخدم التبويبات لكل نوع (مثل المبيعات ومردود المبيعات). لكل نوع قائمة وزر إضافة خاص به.';

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
  String get accountingAccountCash => 'الصندوق / النقدية';

  @override
  String get accountingAccountBank => 'البنك';

  @override
  String get accountingAccountAccountsReceivable => 'الذمم المدينة';

  @override
  String get accountingAccountCustomers => 'العملاء';

  @override
  String get accountingAccountInventory => 'المخزون';

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
  String get accountingAccountShortTermLoans => 'قروض قصيرة الأجل';

  @override
  String get accountingAccountLongTermLiabilities => 'الخصوم طويلة الأجل';

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
  String get accountingAccountExpenses => 'المصروفات';

  @override
  String get accountingAccountCogs => 'تكلفة البضاعة المباعة';

  @override
  String get accountingAccountSalaries => 'الرواتب';

  @override
  String get accountingAccountRent => 'الإيجار';

  @override
  String get accountingAccountUtilities => 'المرافق';

  @override
  String get accountingAccountOtherExpenses => 'مصروفات أخرى';

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
  String get splashSubtitle => 'منصة إدارة الأعمال';

  @override
  String get splashInitErrorTitle => 'تعذر تشغيل التطبيق';

  @override
  String get splashInitErrorMessage => 'حدث خطأ أثناء تهيئة التطبيق.';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get somethingWentWrong => 'حدث خطأ ما';

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
  String get dashboardNoServicesTitle => 'لا توجد خدمات في لوحة التحكم';

  @override
  String get dashboardNoServicesMessage =>
      'خصّص لوحة التحكم لإضافة الخدمات التي تستخدمها أكثر.';

  @override
  String get dashboardNoModulesAvailable => 'لا توجد خدمات متاحة حالياً.';

  @override
  String get platformReportsTitle => 'التقارير';

  @override
  String get platformReportsSubtitle => 'اختر وحدة لاستعراض تقارير خدماتها.';

  @override
  String get platformReportsInventory => 'تقارير المخزون';

  @override
  String get platformReportsInventorySubtitle => 'تقارير الجرد والمنتجات.';

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
  String get syncPendingChangesLabel => 'تغييرات معلّقة';

  @override
  String get syncFailedChangesLabel => 'تغييرات فشلت';

  @override
  String get syncNowAction => 'مزامنة الآن';

  @override
  String get syncOfflineMessage =>
      'أنت غير متصل. ستتم مزامنة التغييرات تلقائياً عند توفر الإنترنت.';

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
  String get syncStatusOffline => 'غير متصل';

  @override
  String get syncCompletedTitle => 'اكتملت المزامنة';

  @override
  String get syncCompletedMessage => 'تمت مزامنة جميع التغييرات.';

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
}
