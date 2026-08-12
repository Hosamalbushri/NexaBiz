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
