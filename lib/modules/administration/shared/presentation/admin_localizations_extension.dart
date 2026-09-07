import 'package:stock_count/app/localization/app_localizations.dart';

extension AdminLocalizationsExtension on AppLocalizations {
  String get adminCompaniesTitle =>
      localeName.startsWith('ar') ? 'إدارة الشركات' : 'Company Administration';
  String get adminCompaniesSearchHint =>
      localeName.startsWith('ar') ? 'البحث عن شركة...' : 'Search companies...';
  String get adminCompaniesEmptyTitle =>
      localeName.startsWith('ar') ? 'لا توجد شركات' : 'No Companies Found';
  String get adminCompaniesEmptyMessage => localeName.startsWith('ar')
      ? 'قم بإنشاء شركة جديدة لبدء العمل.'
      : 'Create a new company to get started.';
  String get adminCreateCompany =>
      localeName.startsWith('ar') ? 'شركة جديدة' : 'New Company';
  String get adminEditCompany =>
      localeName.startsWith('ar') ? 'تعديل بيانات الشركة' : 'Edit Company';
  String get activateCompany =>
      localeName.startsWith('ar') ? 'تفعيل الشركة' : 'Activate Company';
  String get deactivateCompany =>
      localeName.startsWith('ar') ? 'تعطيل الشركة' : 'Deactivate Company';
  String get statusActive => localeName.startsWith('ar') ? 'نشط' : 'Active';
  String get statusInactive =>
      localeName.startsWith('ar') ? 'غير نشط' : 'Inactive';
  String get companyNameLabel =>
      localeName.startsWith('ar') ? 'اسم الشركة' : 'Company Name';
  String get legalNameLabel =>
      localeName.startsWith('ar') ? 'الاسم القانوني' : 'Legal Name';
  String get taxNumberLabel =>
      localeName.startsWith('ar') ? 'الرقم الضريبي' : 'Tax Number';
  String get save => localeName.startsWith('ar') ? 'حفظ' : 'Save';
  String get fieldRequired => localeName.startsWith('ar')
      ? 'هذا الحقل مطلوب'
      : 'This field is required';

  String get adminBranchesTitle => localeName.startsWith('ar')
      ? 'الفروع والإدارات'
      : 'Branches & Organizational Structure';
  String get adminBranchesSearchHint =>
      localeName.startsWith('ar') ? 'البحث عن فرع...' : 'Search branches...';
  String get adminBranchesEmptyTitle =>
      localeName.startsWith('ar') ? 'لا توجد فروع' : 'No Branches Found';
  String get adminBranchesEmptyMessage => localeName.startsWith('ar')
      ? 'أنشئ فرعاً تنظيمياً جديداً للشركة.'
      : 'Create an administrative branch for your company.';
  String get adminCreateBranch =>
      localeName.startsWith('ar') ? 'فرع جديد' : 'New Branch';
  String get adminEditBranch =>
      localeName.startsWith('ar') ? 'تعديل بيانات الفرع' : 'Edit Branch';
  String get branchNameLabel =>
      localeName.startsWith('ar') ? 'اسم الفرع' : 'Branch Name';
  String get branchCodeLabel =>
      localeName.startsWith('ar') ? 'رمز الفرع' : 'Branch Code';
  String get activateBranch =>
      localeName.startsWith('ar') ? 'تفعيل الفرع' : 'Activate Branch';
  String get deactivateBranch =>
      localeName.startsWith('ar') ? 'تعطيل الفرع' : 'Deactivate Branch';
}
