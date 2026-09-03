import '../../../../../core/import_engine/import_engine.dart';

/// Factory and profile definition for Chart of Accounts import.
class AccountImportProfile {
  AccountImportProfile._();

  static const String profileId = 'PROF-ACCOUNTING-COA';
  static const String entityType = 'Account';
  static const String label = 'Chart of Accounts Import';

  /// Creates a standard, fully configured [ImportProfile] for Chart of Accounts.
  static ImportProfile createProfile({
    ImportPolicy? defaultPolicy,
    String? requiredPermission,
    List<ImportRelation>? customRelations,
  }) {
    return ImportProfile(
      profileId: profileId,
      entityType: entityType,
      label: label,
      requiredPermission: requiredPermission ?? 'accounting.coa.import',
      defaultPolicy: defaultPolicy ??
          const ImportPolicy(
            duplicateResolution: DuplicateResolutionStrategy.overwrite,
            createMissingRelations: false,
          ),
      fields: const [
        // Account Code (Required & Unique)
        ImportField(
          key: 'accountCode',
          label: 'Account Code',
          dataType: ImportDataType.text,
          isRequired: true,
          isUnique: true,
          aliases: ['Code', 'Account Code', 'Account Number', 'كود الحساب', 'رمز الحساب', 'رقم الحساب'],
        ),
        // Account Name (Required)
        ImportField(
          key: 'name',
          label: 'Account Name',
          dataType: ImportDataType.text,
          isRequired: true,
          aliases: ['Name', 'Account Name', 'Title', 'اسم الحساب', 'عنوان الحساب', 'الاسم'],
        ),
        // Parent Account Code / Name / UUID (Optional relation)
        ImportField(
          key: 'parentAccount',
          label: 'Parent Account',
          dataType: ImportDataType.text,
          aliases: ['Parent', 'Parent Code', 'Parent Name', 'Parent Account', 'Main Account', 'الحساب الرئيسي', 'الأب'],
        ),
        // Account Type (Required: asset, liability, equity, revenue, expense)
        ImportField(
          key: 'accountType',
          label: 'Account Type',
          dataType: ImportDataType.text,
          isRequired: true,
          aliases: ['Type', 'Account Type', 'Category', 'نوع الحساب', 'النوع'],
        ),
        // Is Group / Header Account (Optional, boolean/text)
        ImportField(
          key: 'isGroup',
          label: 'Is Group Account',
          dataType: ImportDataType.boolean,
          aliases: ['Is Group', 'Group', 'Header Account', 'Is Header', 'حساب رئيسي', 'مجموعة'],
        ),
        // Debit Opening Balance (Optional, non-negative)
        ImportField(
          key: 'debitOpening',
          label: 'Debit Opening Balance',
          dataType: ImportDataType.number,
          aliases: ['Opening Debit', 'Debit', 'Debit Balance', 'رصيد افتتاح مدين', 'مدين'],
        ),
        // Credit Opening Balance (Optional, non-negative)
        ImportField(
          key: 'creditOpening',
          label: 'Credit Opening Balance',
          dataType: ImportDataType.number,
          aliases: ['Opening Credit', 'Credit', 'Credit Balance', 'رصيد افتتاح دائن', 'دائن'],
        ),
        // Currency Code (Optional, e.g. USD, SAR)
        ImportField(
          key: 'currency',
          label: 'Currency Code',
          dataType: ImportDataType.text,
          aliases: ['Currency', 'Currency Code', 'العملة', 'رمز العملة'],
        ),
        // Description / Notes (Optional)
        ImportField(
          key: 'description',
          label: 'Description',
          dataType: ImportDataType.text,
          aliases: ['Description', 'Notes', 'Memo', 'الوصف', 'ملاحظات'],
        ),
        // Is Active (Optional, boolean/text, default true)
        ImportField(
          key: 'isActive',
          label: 'Is Active',
          dataType: ImportDataType.boolean,
          aliases: ['Is Active', 'Active', 'Status', 'نشط', 'الحالة'],
        ),
      ],
      relations: customRelations ??
          const [
            ImportRelation(
              relationKey: 'parentAccount',
              targetEntityType: 'Account',
              lookupFieldKey: 'accountCode',
              isRequired: false,
              autoCreateMissing: false,
            ),
          ],
    );
  }
}
