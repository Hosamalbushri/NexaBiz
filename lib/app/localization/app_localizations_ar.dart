// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'منصة الأعمال';

  @override
  String get servicesTitle => 'الخدمات';

  @override
  String get servicesSubtitle => 'اختر وحدة أعمال للبدء.';

  @override
  String get moduleInventory => 'المخزون';

  @override
  String get moduleInventoryDescription => 'العدّ والاستيراد وتقارير المخزون.';

  @override
  String get modulePlaceholderMessage =>
      'تم تسجيل هذه الوحدة وهي جاهزة. ستُضاف الميزات في المراحل التالية.';

  @override
  String get inventoryOverview => 'نظرة عامة';

  @override
  String get inventoryCountTitle => 'عدّ المخزون';

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
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get exitAppTitle => 'الخروج من التطبيق؟';

  @override
  String get exitAppMessage => 'هل تريد إغلاق التطبيق الآن؟';

  @override
  String get exitAppConfirm => 'خروج';

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
}
