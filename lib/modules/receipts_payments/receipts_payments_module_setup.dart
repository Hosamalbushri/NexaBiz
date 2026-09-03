import '../../core/domain/entities/account_role.dart';
import '../../core/domain/ports/setup_account_lookup_port.dart';
import '../../core/setup/setup.dart';

/// Declarative account requirements for the Receipts & Payments (Treasuries) package.
const rpCashAccountRequirement = AccountRequirement(
  packageId: 'receipts_payments',
  requirementKey: 'cash_account',
  role: AccountRole.cash,
  labelAr: 'حساب الخزينة/الصندوق الرئيسي (أصول)',
  labelEn: 'Primary Cash/Treasury Parent Account',
  isRequired: true,
  bindingMode: AccountBindingMode.parent,
  expectedAccountType: SetupAccountType.asset,
);

const rpBankAccountRequirement = AccountRequirement(
  packageId: 'receipts_payments',
  requirementKey: 'bank_account',
  role: AccountRole.cash,
  labelAr: 'حساب البنك الرئيسي (أصول)',
  labelEn: 'Primary Bank Parent Account',
  isRequired: false,
  bindingMode: AccountBindingMode.parent,
  expectedAccountType: SetupAccountType.asset,
);

/// Central setup definition contributed by the Receipts & Payments business package.
final receiptsPaymentsPackageSetupDefinition = PackageSetupDefinition(
  packageId: 'receipts_payments',
  displayNameAr: 'إعدادات السندات والخزينة',
  displayNameEn: 'Receipts & Payments Setup',
  sortOrder: 50,
  sections: const [
    SetupSection(
      id: 'treasury_defaults',
      packageId: 'receipts_payments',
      titleAr: 'إعدادات وقواعد المقبوضات والمقبوضات',
      titleEn: 'Treasury & Transaction Controls',
      descriptionAr: 'اشتراط أرقام الشيكات، التحكم بالسحب المكشوف، وقواعد الصرف',
      descriptionEn: 'Check number requirement, negative treasury balance policy, and disbursement rules',
      fields: [
        SetupField(
          id: 'requireCheckNumber',
          sectionId: 'treasury_defaults',
          key: 'requireCheckNumber',
          labelAr: 'اشتراط رقم الشيك لسندات الصرف والقبض البنكية',
          labelEn: 'Require Check Number for Bank Transactions',
          fieldType: SetupFieldType.boolean,
          defaultValue: false,
        ),
        SetupField(
          id: 'allowNegativeTreasuryBalance',
          sectionId: 'treasury_defaults',
          key: 'allowNegativeTreasuryBalance',
          labelAr: 'السماح بالرصيد السالب في الخزينة/الصندوق',
          labelEn: 'Allow Negative Treasury/Cash Balance',
          fieldType: SetupFieldType.boolean,
          defaultValue: false,
        ),
      ],
    ),
    SetupSection(
      id: 'account_requirements',
      packageId: 'receipts_payments',
      titleAr: 'ربط حسابات الخزينة والبنك',
      titleEn: 'Cash & Bank Account Bindings',
      descriptionAr: 'ربط حسابات الصندوق والبنك الافتراضية من دليل الحسابات',
      descriptionEn: 'Bind default cash and bank accounts from Chart of Accounts',
      fields: [
        SetupField(
          id: 'cash_account',
          sectionId: 'account_requirements',
          key: 'cash_account',
          labelAr: 'حساب الخزينة/الصندوق الرئيسي',
          labelEn: 'Primary Cash Account',
          fieldType: SetupFieldType.reference,
          isRequired: true,
        ),
        SetupField(
          id: 'bank_account',
          sectionId: 'account_requirements',
          key: 'bank_account',
          labelAr: 'حساب البنك الرئيسي',
          labelEn: 'Primary Bank Account',
          fieldType: SetupFieldType.reference,
          isRequired: false,
        ),
      ],
    ),
  ],
);

/// Registers ReceiptsPayments setup definition into [registry].
void registerReceiptsPaymentsSetup(CentralSetupRegistry registry) {
  registry.register(receiptsPaymentsPackageSetupDefinition);
}
