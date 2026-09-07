import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_breakpoints.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_account_search_picker.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../modules/accounting/chart_of_accounts/domain/entities/account.dart';
import '../../domain/entities/import_job_status.dart';
import '../../domain/entities/import_profile.dart';
import '../../registry/import_profile_registry.dart';
import '../providers/import_ui_providers.dart';
import '../widgets/step_dynamic_assignments.dart';

/// Strategy for resolving parent account in Chart of Accounts import.
enum ParentAccountStrategy {
  /// Put all imported accounts directly under the selected parent account.
  underSelectedParent,

  /// Use parent account specified in the imported file.
  fromFile,

  /// Use parent account from file, fallback to selected parent if unresolved.
  fromFileWithFallback,
}

/// Progressive, single-page Universal Import Page for NexaBiz ERP.
///
/// Dynamically reveals sections 01 to 06 on one continuous page based on user choices.
class UniversalImportPage extends ConsumerStatefulWidget {
  const UniversalImportPage({super.key, this.initialProfileId});

  final String? initialProfileId;

  @override
  ConsumerState<UniversalImportPage> createState() =>
      _UniversalImportPageState();
}

class _UniversalImportPageState extends ConsumerState<UniversalImportPage> {
  // Selected Profile & Strategy state
  ImportProfile? _selectedProfile;
  ParentAccountStrategy _parentStrategy =
      ParentAccountStrategy.fromFileWithFallback;
  Account? _selectedParentAccount;

  // Search & File state
  final TextEditingController _profileSearchController =
      TextEditingController();
  bool _isPickingFile = false;

  @override
  void initState() {
    super.initState();
    final profiles = ImportProfileRegistry.allProfiles;
    if (widget.initialProfileId != null) {
      _selectedProfile = ImportProfileRegistry.getProfile(
        widget.initialProfileId!,
      );
    }
    _selectedProfile ??= profiles.firstWhere(
      (p) => p.profileId == 'PROF-ACCOUNTING-COA',
      orElse: () => profiles.first,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedProfile != null) {
        ref
            .read(importWizardNotifierProvider.notifier)
            .selectProfile(_selectedProfile!);
      }
    });
  }

  @override
  void dispose() {
    _profileSearchController.dispose();
    super.dispose();
  }

  void _onSelectProfile(ImportProfile profile) {
    setState(() {
      _selectedProfile = profile;
    });
    ref.read(importWizardNotifierProvider.notifier).selectProfile(profile);
  }

  Future<void> _pickFile() async {
    setState(() => _isPickingFile = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls', 'json', 'txt'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      String textContent = '';
      if (file.bytes != null) {
        textContent = utf8.decode(file.bytes!, allowMalformed: true);
      }

      final ext = file.extension?.toLowerCase() ?? 'csv';
      var sourceType = 'csv';
      if (ext == 'xlsx' || ext == 'xls') sourceType = 'xlsx';
      if (ext == 'json') sourceType = 'json';

      final wizard = ref.read(importWizardNotifierProvider.notifier);
      wizard.updateSourceType(sourceType);
      wizard.updateRawSourceText(textContent);
      await wizard.parseSource();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تحميل الملف بنجاح: ${file.name} (${(file.size / 1024).toStringAsFixed(1)} KB)',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ أثناء قراءة الملف: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wizardState = ref.watch(importWizardNotifierProvider);
    final activeJobState = wizardState.activeJob;
    final isJobActive =
        activeJobState != null &&
        (activeJobState.status == ImportJobStatus.queued ||
            activeJobState.status == ImportJobStatus.preparing ||
            activeJobState.status == ImportJobStatus.processing);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.system_update_alt_rounded, size: 22),
            SizedBox(width: AppSpacing.sm),
            Text('استيراد البيانات العام | Universal Data Import'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'إعادة ضبط | Reset',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(importWizardNotifierProvider.notifier).reset();
              if (_selectedProfile != null) {
                ref
                    .read(importWizardNotifierProvider.notifier)
                    .selectProfile(_selectedProfile!);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          AppBreakpoints.isMobile(MediaQuery.of(context).size.width)
              ? AppSpacing.md
              : AppSpacing.lg,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Hero Banner
                _buildHeroBanner(theme),
                const SizedBox(height: AppSpacing.lg),

                // Active Job Monitoring Banner (If Job is Running or Done)
                if (activeJobState != null) ...[
                  _buildJobProgressCard(theme, activeJobState),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // SECTION 01: Choose Import Type
                _buildSectionHeader(
                  theme,
                  number: '01',
                  title: 'اختر نوع البيانات المستوردة | Choose Import Type',
                  subtitle:
                      'اختر كيان النظام المراد استيراد بياناته إلى الشركة الحالية',
                ),
                const SizedBox(height: AppSpacing.md),
                _buildProfileSelectionGrid(theme),
                const SizedBox(height: AppSpacing.xl),

                // SECTION 02: Dynamic Configuration
                if (_selectedProfile != null) ...[
                  _buildSectionHeader(
                    theme,
                    number: '02',
                    title: 'إعدادات الاستيراد التكيفية | Import Configuration',
                    subtitle:
                        'تكوين الخيارات والسياسات الخاصة بـ ${_selectedProfile!.label}',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildDynamicConfigurationCard(theme, wizardState),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // SECTION 03: Select File
                if (_selectedProfile != null) ...[
                  _buildSectionHeader(
                    theme,
                    number: '03',
                    title: 'اختيار وتحميل الملف | Select File',
                    subtitle: 'رفع ملف Excel (XLSX/XLS) أو CSV أو JSON المعالج',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildFileSelectionCard(theme, wizardState),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // SECTION 04: Column Mapping
                if (wizardState.parsedDocument != null) ...[
                  _buildSectionHeader(
                    theme,
                    number: '04',
                    title: 'مطابقة الأعمدة | Column Mapping',
                    subtitle: 'ربط أعمدة الملف الخارجي مع حقول النظام المعرفية',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildColumnMappingCard(theme, wizardState),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // SECTION 05: Preview & Validation Engine
                if (wizardState.previewSummary != null) ...[
                  _buildSectionHeader(
                    theme,
                    number: '05',
                    title:
                        'المعاينة والتحقق الخالي من التغيير | Preview & Dry-Run (0 Mutations)',
                    subtitle:
                        'مراجعة نتيجة المعاينة ومؤشرات الصحة قبل الاعتماد المالي',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildPreviewAndValidationCard(theme, wizardState),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // SECTION 06: Pre-flight & Start Import Action
                if (wizardState.parsedDocument != null && !isJobActive) ...[
                  _buildSectionHeader(
                    theme,
                    number: '06',
                    title: 'بدء الاستيراد في الخلفية | Start Background Import',
                    subtitle:
                        'مراجعة ملخص العمل وتفويض المعالج الخلفي بالتنفيذ المستقل',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildStartImportCard(theme, wizardState),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(ThemeData theme) {
    return AppCard(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: theme.colorScheme.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'محرك الاستيراد الشامل | Universal Import Engine',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'واجهة موحدة آمنة تدعم التدفق المتدرج للبيانات مع ضمان العزل التام واستقلال معالج الخلفية.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme, {
    required String number,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            number,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSelectionGrid(ThemeData theme) {
    final profiles = ImportProfileRegistry.allProfiles;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: profiles.map((profile) {
        final isSelected = _selectedProfile?.profileId == profile.profileId;
        final icon = _getProfileIcon(profile.entityType);

        return InkWell(
          key: Key('profile_card_${profile.profileId}'),
          onTap: () => _onSelectProfile(profile),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            width: AppBreakpoints.isMobile(MediaQuery.of(context).size.width)
                ? double.infinity
                : 240,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Entity: ${profile.entityType}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDynamicConfigurationCard(
    ThemeData theme,
    ImportWizardState wizardState,
  ) {
    final isCOA = _selectedProfile?.profileId == 'PROF-ACCOUNTING-COA';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'خيارات الاستيراد لـ ${_selectedProfile?.label}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg),

          if (isCOA) ...[
            // Chart of Accounts Parent Strategy Selector
            Text(
              'استراتيجية ربط الحساب الأب (Parent Account Strategy):',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            RadioListTile<ParentAccountStrategy>(
              title: const Text(
                'أقحام كافة الحسابات تحت حساب أب محدد (Under Selected Parent)',
              ),
              subtitle: const Text(
                'سيتم تعيين الحساب المختار أدناه كـ أب مباشر لكافة الحسابات المستوردة.',
              ),
              value: ParentAccountStrategy.underSelectedParent,
              groupValue: _parentStrategy,
              onChanged: (val) => setState(() => _parentStrategy = val!),
            ),
            RadioListTile<ParentAccountStrategy>(
              title: const Text(
                'قراءة الحساب الأب من الملف المرفوع (From File)',
              ),
              subtitle: const Text(
                'سيتم البحث عن كود الحساب الأب من العمود المحدد بالملف.',
              ),
              value: ParentAccountStrategy.fromFile,
              groupValue: _parentStrategy,
              onChanged: (val) => setState(() => _parentStrategy = val!),
            ),
            RadioListTile<ParentAccountStrategy>(
              title: const Text(
                'قراءة الأب من الملف + استخدام حساب احتياطي (File + Fallback Parent)',
              ),
              subtitle: const Text(
                'إذا تعذر العثور على الحساب الأب في الملف، يتم التراجع واستخدام الحساب الاحتياطي.',
              ),
              value: ParentAccountStrategy.fromFileWithFallback,
              groupValue: _parentStrategy,
              onChanged: (val) => setState(() => _parentStrategy = val!),
            ),

            if (_parentStrategy != ParentAccountStrategy.fromFile) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.4,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _parentStrategy ==
                                  ParentAccountStrategy.underSelectedParent
                              ? 'الحساب الأب المستهدف *:'
                              : 'الحساب الأب الاحتياطي (Fallback Parent) *:',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        if (_selectedParentAccount != null)
                          Chip(
                            label: Text(
                              '${_selectedParentAccount!.accountCode} - ${_selectedParentAccount!.name}',
                            ),
                            onDeleted: () =>
                                setState(() => _selectedParentAccount = null),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final account = await showAppAccountPicker(
                          context,
                          title: 'اختر الحساب الأب الرئيسي',
                          postingOnlyDefault: false,
                        );
                        if (account != null) {
                          setState(() => _selectedParentAccount = account);
                          ref
                              .read(importWizardNotifierProvider.notifier)
                              .updateAssignment(
                                'parentAccount',
                                account.accountCode,
                              );
                        }
                      },
                      icon: const Icon(Icons.account_tree_outlined, size: 18),
                      label: Text(
                        _selectedParentAccount == null
                            ? 'البحث واختيار حساب من الدليل'
                            : 'تغيير الحساب الأب',
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
          ],

          // Generic Dynamic Assignments
          if (_selectedProfile?.relations != null &&
              _selectedProfile!.relations.isNotEmpty)
            StepDynamicAssignments(
              profile: _selectedProfile!,
              assignments: wizardState.dynamicAssignments,
              onAssignmentChanged: (key, val) {
                ref
                    .read(importWizardNotifierProvider.notifier)
                    .updateAssignment(key, val);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFileSelectionCard(
    ThemeData theme,
    ImportWizardState wizardState,
  ) {
    final doc = wizardState.parsedDocument;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ملف البيانات الخارجي | Data Source File',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isPickingFile)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          InkWell(
            onTap: _isPickingFile ? null : _pickFile,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.xl,
                horizontal: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 42,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'انقر هنا لاختيار ملف البيانات (Excel / CSV / JSON)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'يدعم صيغ .xlsx, .xls, .csv, .json حتى 100,000 صف',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    key: const Key('pick_file_button'),
                    label: 'Browse Files / اختيار ملف',
                    icon: Icons.folder_open_rounded,
                    onPressed: _isPickingFile ? null : _pickFile,
                  ),
                ],
              ),
            ),
          ),

          if (doc != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.2,
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تم تحليل هيكل الملف بنجاح (File Analyzed Successfully)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                        Text(
                          'عدد الصفوف الكلي: ${doc.activeSheet?.totalRows ?? 0} | عدد الأعمدة المكتشفة: ${doc.activeSheet?.headers.length ?? 0}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildColumnMappingCard(
    ThemeData theme,
    ImportWizardState wizardState,
  ) {
    final doc = wizardState.parsedDocument;
    final sourceCols = doc?.activeSheet?.headers ?? [];
    final fields = _selectedProfile?.fields ?? [];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'جدول مطابقة الأعمدة (Column Mapping Matrix)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  ref
                      .read(importWizardNotifierProvider.notifier)
                      .autoMapColumns();
                },
                icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                label: const Text('إعادة المطابقة التلقائية'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('حقل النظام (Target Field)')),
                DataColumn(label: Text('نوع الحقل')),
                DataColumn(label: Text('عمود الملف المستورد (Source Column)')),
                DataColumn(label: Text('حالة المطابقة')),
              ],
              rows: fields.map((field) {
                final currentMappedSource =
                    wizardState.columnMappings[field.key];
                final isMatched =
                    currentMappedSource != null &&
                    currentMappedSource.isNotEmpty;

                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            field.label,
                            style: TextStyle(
                              fontWeight: field.isRequired
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          if (field.isRequired)
                            const Text(
                              ' *',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                    DataCell(Text(field.dataType.name)),
                    DataCell(
                      DropdownButton<String>(
                        value: sourceCols.contains(currentMappedSource)
                            ? currentMappedSource
                            : null,
                        hint: const Text('-- غير مرتبط (Ignored) --'),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('-- تجاهل العمود --'),
                          ),
                          ...sourceCols.map(
                            (col) =>
                                DropdownMenuItem(value: col, child: Text(col)),
                          ),
                        ],
                        onChanged: (val) {
                          ref
                              .read(importWizardNotifierProvider.notifier)
                              .updateMapping(field.key, val ?? '');
                        },
                      ),
                    ),
                    DataCell(
                      AppStatusBadge(
                        label: isMatched
                            ? 'مربوط (Matched)'
                            : (field.isRequired ? 'مطلوب!' : 'اختياري'),
                        tone: isMatched
                            ? AppStatusTone.success
                            : (field.isRequired
                                  ? AppStatusTone.error
                                  : AppStatusTone.neutral),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewAndValidationCard(
    ThemeData theme,
    ImportWizardState wizardState,
  ) {
    final summary = wizardState.previewSummary;
    if (summary == null) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مؤشرات نتيجة المعاينة (Preview Metrics)',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _buildMetricChip(
                theme,
                'إجمالي الصفوف',
                summary.totalRows.toString(),
                Colors.blue,
              ),
              _buildMetricChip(
                theme,
                'صفوف صالحة',
                summary.validRows.toString(),
                AppColors.success,
              ),
              _buildMetricChip(
                theme,
                'تحذيرات',
                summary.warnings.toString(),
                Colors.orange,
              ),
              _buildMetricChip(
                theme,
                'أخطاء',
                summary.errors.toString(),
                Theme.of(context).colorScheme.error,
              ),
              _buildMetricChip(
                theme,
                'إنشاء جديد',
                summary.creates.toString(),
                Colors.teal,
              ),
              _buildMetricChip(
                theme,
                'تحديث',
                summary.updates.toString(),
                Colors.indigo,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'عينات الصفوف والمعاينة الحية:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.separated(
              itemCount: (wizardState.previewSummary?.rows ?? [])
                  .take(5)
                  .length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final row = wizardState.previewSummary!.rows[idx];
                return ListTile(
                  dense: true,
                  leading: Text(
                    '#${row.rowIndex}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  title: Text('Action: ${row.action.name.toUpperCase()}'),
                  subtitle: row.issues.isNotEmpty
                      ? Text(
                          'Issues: ${row.issues.map((i) => i.message).join(', ')}',
                          style: TextStyle(color: theme.colorScheme.error),
                        )
                      : const Text('جاهز للاستيراد السليم'),
                  trailing: AppStatusBadge(
                    label: row.action.name,
                    tone: row.issues.isEmpty
                        ? AppStatusTone.success
                        : AppStatusTone.error,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(
    ThemeData theme,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartImportCard(ThemeData theme, ImportWizardState wizardState) {
    return AppCard(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'جاهز لبدء العملية في الخلفية',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'سيتم تحويل المهمة إلى مشغل الخلفية (Background Worker) فورياً للحفاظ على استجابة النظام.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          AppButton(
            key: const Key('start_import_button'),
            label: 'بدء الاستيراد | Start Import',
            icon: Icons.play_arrow_rounded,
            onPressed: () async {
              await ref
                  .read(importWizardNotifierProvider.notifier)
                  .startImport(companyId: 'SYSTEM', userId: 'USER');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم تشغيل وظيفة الاستيراد بنجاح في الخلفية!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildJobProgressCard(ThemeData theme, activeJobState) {
    final progress = activeJobState.totalRows > 0
        ? (activeJobState.processedRows / activeJobState.totalRows)
        : 0.0;

    return AppCard(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'مهمة استيراد نشطة: ${activeJobState.jobId}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              AppStatusBadge(
                label: activeJobState.status.name.toUpperCase(),
                tone: AppStatusTone.info,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'التقدم: ${(progress * 100).toStringAsFixed(1)}% (${activeJobState.processedRows} / ${activeJobState.totalRows} صفوف)',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'ناجح: ${activeJobState.successfulRows} | أخطاء: ${activeJobState.failedRows}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getProfileIcon(String entityType) {
    switch (entityType.toLowerCase()) {
      case 'account':
        return Icons.account_tree_rounded;
      case 'product':
        return Icons.inventory_2_rounded;
      case 'customer':
        return Icons.people_alt_rounded;
      case 'supplier':
        return Icons.local_shipping_rounded;
      case 'employee':
        return Icons.badge_rounded;
      case 'warehouse':
        return Icons.store_rounded;
      default:
        return Icons.table_chart_rounded;
    }
  }
}
