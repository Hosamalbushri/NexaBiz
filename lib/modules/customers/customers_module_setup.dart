import '../../core/domain/entities/account_role.dart';
import '../../core/domain/ports/setup_account_lookup_port.dart';
import '../../core/setup/setup.dart';

/// Declarative account requirements for the Customers package.
const arAccountRequirement = AccountRequirement(
  packageId: 'customers',
  requirementKey: 'ar_account',
  role: AccountRole.receivable,
  labelAr: 'حساب الذمم المدينة / العملاء الرئيسي (أصول)',
  labelEn: 'Accounts Receivable Parent Account',
  isRequired: true,
  bindingMode: AccountBindingMode.parent,
  expectedAccountType: SetupAccountType.asset,
);

/// Central setup definition contributed by the Customers business package.
final customersPackageSetupDefinition = PackageSetupDefinition(
  packageId: 'customers',
  displayNameAr: 'إعدادات العملاء',
  displayNameEn: 'Customers Setup',
  sortOrder: 40,
  sections: const [
    SetupSection(
      id: 'policies',
      packageId: 'customers',
      titleAr: 'سياسات وقواعد العملاء',
      titleEn: 'Customers Policies & Defaults',
      descriptionAr: 'حد الائتمان الافتراضي والربط التلقائي بالحسابات والضوابط',
      descriptionEn: 'Default credit limits, auto sub-account creation, and tax ID validation',
      fields: [
        SetupField(
          id: 'defaultCreditLimit',
          sectionId: 'policies',
          key: 'defaultCreditLimit',
          labelAr: 'الحد الائتماني الافتراضي للعميل الجديد',
          labelEn: 'Default Credit Limit for New Customers',
          fieldType: SetupFieldType.number,
          defaultValue: 0.0,
        ),
        SetupField(
          id: 'autoLinkAccounts',
          sectionId: 'policies',
          key: 'autoLinkAccounts',
          labelAr: 'إنشاء حساب فرعي تلقائياً في دليل الحسابات عند إضافة عميل',
          labelEn: 'Auto-create Sub-account in COA upon Customer Creation',
          fieldType: SetupFieldType.boolean,
          defaultValue: true,
        ),
        SetupField(
          id: 'requireTaxNumber',
          sectionId: 'policies',
          key: 'requireTaxNumber',
          labelAr: 'اشتراط الرقم الضريبي للعميل التجاري',
          labelEn: 'Require Tax ID for Commercial Customers',
          fieldType: SetupFieldType.boolean,
          defaultValue: false,
        ),
      ],
    ),
    SetupSection(
      id: 'account_requirements',
      packageId: 'customers',
      titleAr: 'ربط حسابات العملاء الرئيسية',
      titleEn: 'Accounts Receivable Parent Account',
      descriptionAr: 'تحديد الحساب الرئيسي للذمم المدينة في دليل الحسابات',
      descriptionEn: 'Bind Accounts Receivable parent account from Chart of Accounts',
      fields: [
        SetupField(
          id: 'ar_account',
          sectionId: 'account_requirements',
          key: 'ar_account',
          labelAr: 'حساب الذمم المدينة / العملاء الرئيسي',
          labelEn: 'Accounts Receivable Account',
          fieldType: SetupFieldType.reference,
          isRequired: true,
        ),
      ],
    ),
  ],
);

/// Registers Customers setup definition into [registry].
void registerCustomersSetup(CentralSetupRegistry registry) {
  registry.register(customersPackageSetupDefinition);
}
