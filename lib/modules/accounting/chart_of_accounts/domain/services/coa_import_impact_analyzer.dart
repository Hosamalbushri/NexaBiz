import '../../../../../core/domain/entities/account_role.dart';
import '../../../../system_setup/domain/entities/company_accounting_config.dart';
import '../entities/account.dart';

/// Comprehensive pre-import impact analysis report for Chart of Accounts (COA) operations.
class CoaImportImpactReport {
  const CoaImportImpactReport({
    required this.accountsRemoved,
    required this.accountsAdded,
    required this.accountCodesChanged,
    required this.accountNamesChanged,
    required this.accountTypesChanged,
    required this.accountParentsChanged,
    required this.accountUuidsChanged,
    required this.systemRolesLost,
    required this.configurationsBroken,
    required this.historicalJournalImpact,
    required this.blockingReasons,
  });

  final List<Account> accountsRemoved;
  final List<Account> accountsAdded;
  final List<String> accountCodesChanged;
  final List<String> accountNamesChanged;
  final List<String> accountTypesChanged;
  final List<String> accountParentsChanged;
  final List<String> accountUuidsChanged;
  final List<AccountRole> systemRolesLost;
  final List<String> configurationsBroken;
  final List<String> historicalJournalImpact;
  final List<String> blockingReasons;

  bool get isSafeToImport => blockingReasons.isEmpty;

  @override
  String toString() {
    return 'CoaImportImpactReport(safe: $isSafeToImport, added: ${accountsAdded.length}, removed: ${accountsRemoved.length}, blocking: ${blockingReasons.length})';
  }
}

/// Service that analyzes proposed imported accounts against existing COA records & system bindings.
class CoaImportImpactAnalyzer {
  CoaImportImpactReport analyzeImpact({
    required String companyId,
    required List<Account> existingAccounts,
    required List<Account> candidateAccounts,
    CompanyAccountingConfig? activeConfig,
    Map<String, int> postedUsageCounts = const {},
  }) {
    final Map<String, Account> existingByUuid = {
      for (final a in existingAccounts) a.id: a,
    };
    final Map<String, Account> candidateByUuid = {
      for (final a in candidateAccounts) a.id: a,
    };
    final Map<String, Account> existingByCode = {
      for (final a in existingAccounts) a.accountCode: a,
    };

    final List<Account> accountsAdded = [];
    final List<Account> accountsRemoved = [];
    final List<String> accountCodesChanged = [];
    final List<String> accountNamesChanged = [];
    final List<String> accountTypesChanged = [];
    final List<String> accountParentsChanged = [];
    final List<String> accountUuidsChanged = [];
    final List<AccountRole> systemRolesLost = [];
    final List<String> configurationsBroken = [];
    final List<String> historicalJournalImpact = [];
    final List<String> blockingReasons = [];

    // Tenant boundary validation
    for (final cand in candidateAccounts) {
      if (cand.companyId != companyId) {
        blockingReasons.add(
          'خطأ أمان: الحساب (${cand.accountCode} - ${cand.name}) يتبع شركة أخرى (${cand.companyId}).',
        );
      }
    }

    // Identify Added Accounts
    for (final cand in candidateAccounts) {
      if (!existingByUuid.containsKey(cand.id)) {
        accountsAdded.add(cand);
      }
    }

    // Analyze Existing Accounts against Import Set
    for (final existing in existingAccounts) {
      final cand = candidateByUuid[existing.id];

      if (cand == null) {
        // Account was removed in candidate import set
        accountsRemoved.add(existing);

        // Check if removed account has posted usage
        final usage = postedUsageCounts[existing.id] ?? 0;
        if (usage > 0) {
          historicalJournalImpact.add(
            'حذف الحساب (${existing.accountCode} - ${existing.name}) تؤثر على $usage قيود مالية مرحلة.',
          );
          blockingReasons.add(
            'يمنع حذف الحساب (${existing.accountCode} - ${existing.name}) لاستخدامه في $usage قيود مالية رحلت سابقاً.',
          );
        }

        // Check if removed account is bound in active configuration
        if (activeConfig != null) {
          activeConfig.accountMappings.forEach((role, boundUuid) {
            if (boundUuid == existing.id) {
              systemRolesLost.add(role);
              configurationsBroken.add(
                'الدور المحاسبي (${role.name}) مرتبطة بالحساب المحذوف (${existing.accountCode}).',
              );
              blockingReasons.add(
                'يمنع حذف الحساب (${existing.accountCode}) المرتبط بالدور المحاسبي (${role.name}).',
              );
            }
          });
        }
      } else {
        // Account exists by ID: check for modifications
        if (cand.accountCode != existing.accountCode) {
          accountCodesChanged.add(
            'تغيير رمز الحساب (${existing.id}): من ${existing.accountCode} إلى ${cand.accountCode}',
          );
        }

        if (cand.name != existing.name) {
          accountNamesChanged.add(
            'تغيير اسم الحساب (${existing.accountCode}): من "${existing.name}" إلى "${cand.name}"',
          );
        }

        if (cand.accountType != existing.accountType) {
          accountTypesChanged.add(
            'تغيير نوع الحساب (${existing.accountCode}): من ${existing.accountType.name} إلى ${cand.accountType.name}',
          );

          // Check if changing type affects posted transactions or configuration role
          final usage = postedUsageCounts[existing.id] ?? 0;
          if (usage > 0) {
            historicalJournalImpact.add(
              'تغيير نوع الحساب (${existing.accountCode}) يؤثر على المعنى المحاسبي لـ $usage قيود مرحلة.',
            );
            blockingReasons.add(
              'يمنع تغيير تصنيف الحساب (${existing.accountCode}) من (${existing.accountType.name}) إلى (${cand.accountType.name}) بسبب وجود قيود مرحلة.',
            );
          }
        }

        if (cand.parentId != existing.parentId) {
          accountParentsChanged.add(
            'تغيير الحساب الأب للحساب (${existing.accountCode})',
          );
        }
      }
    }

    // Check for ID Replacements for Same Code
    for (final cand in candidateAccounts) {
      final existingCodeMatch = existingByCode[cand.accountCode];
      if (existingCodeMatch != null && existingCodeMatch.id != cand.id) {
        accountUuidsChanged.add(
          'تغيير المعرف الفريد ID للرمز (${cand.accountCode}): من ${existingCodeMatch.id} إلى ${cand.id}',
        );

        final usage = postedUsageCounts[existingCodeMatch.id] ?? 0;
        if (usage > 0) {
          blockingReasons.add(
            'يمنع استبدال المعرف الفريد ID للحساب (${cand.accountCode}) الذي يمتلك قيوداً مرحلة.',
          );
        }
      }
    }

    return CoaImportImpactReport(
      accountsRemoved: accountsRemoved,
      accountsAdded: accountsAdded,
      accountCodesChanged: accountCodesChanged,
      accountNamesChanged: accountNamesChanged,
      accountTypesChanged: accountTypesChanged,
      accountParentsChanged: accountParentsChanged,
      accountUuidsChanged: accountUuidsChanged,
      systemRolesLost: systemRolesLost,
      configurationsBroken: configurationsBroken,
      historicalJournalImpact: historicalJournalImpact,
      blockingReasons: blockingReasons,
    );
  }
}
