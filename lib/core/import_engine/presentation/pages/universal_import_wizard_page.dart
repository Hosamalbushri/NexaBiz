import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../import_engine.dart';

/// Production-grade 11-step Universal Import Engine Wizard UI screen.
class UniversalImportWizardPage extends ConsumerWidget {
  const UniversalImportWizardPage({
    super.key,
    required this.companyId,
    required this.userId,
    this.registeredProfiles = const [],
    this.onImportStarted,
  });

  final String companyId;
  final String userId;
  final List<ImportProfile> registeredProfiles;
  final VoidCallback? onImportStarted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(importWizardProvider);
    final notifier = ref.read(importWizardProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final List<ImportProfile> availableProfiles = registeredProfiles.isNotEmpty
        ? registeredProfiles
        : [
            ImportProfile(
              profileId: 'PROF-GENERIC',
              label: 'Generic Entity Profile',
              entityType: 'Generic',
              fields: const [
                ImportField(key: 'code', label: 'Code / SKU', isRequired: true),
                ImportField(key: 'name', label: 'Name', isRequired: true),
                ImportField(key: 'description', label: 'Description'),
              ],
            ),
          ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Universal Import Wizard (Step ${state.activeStep + 1} of 11)',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset Wizard',
            onPressed: () => notifier.reset(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Step progress indicator bar
          _buildHorizontalStepperHeader(context, state.activeStep),
          if (state.errorMessage != null) ...[
            Container(
              margin: const EdgeInsets.all(12.0),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => notifier.previousStep(),
                  ),
                ],
              ),
            ),
          ],
          Expanded(
            child: _buildStepContent(
              context,
              ref,
              state,
              notifier,
              availableProfiles,
            ),
          ),
          // Bottom control action bar
          _buildBottomNavigationBar(context, ref, state, notifier),
        ],
      ),
    );
  }

  Widget _buildHorizontalStepperHeader(BuildContext context, int currentStep) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = (currentStep + 1) / 11;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            child: Row(
              children: List.generate(11, (idx) {
                final isCompleted = idx < currentStep;
                final isCurrent = idx == currentStep;
                final stepColor = isCurrent
                    ? colorScheme.primary
                    : isCompleted
                    ? colorScheme.primary.withValues(alpha: 0.8)
                    : colorScheme.outlineVariant;

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 6.0,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? colorScheme.primaryContainer
                            : isCompleted
                            ? colorScheme.surfaceContainerHighest
                            : colorScheme.surface,
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(
                          color: isCurrent
                              ? colorScheme.primary
                              : colorScheme.outlineVariant.withValues(
                                  alpha: 0.6,
                                ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: stepColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: isCompleted
                                  ? Icon(
                                      Icons.check_rounded,
                                      size: 12,
                                      color: colorScheme.onPrimary,
                                    )
                                  : Text(
                                      '${idx + 1}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isCurrent
                                            ? colorScheme.onPrimary
                                            : colorScheme.onSurface,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            _getStepShortTitle(idx),
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isCurrent
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (idx < 10)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(
    BuildContext context,
    WidgetRef ref,
    ImportWizardState state,
    ImportWizardNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            key: const Key('wizard_back_button'),
            onPressed: state.activeStep > 0
                ? () => notifier.previousStep()
                : null,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Back'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 18.0,
                vertical: 12.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getStepTitle(state.activeStep),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Step ${state.activeStep + 1} of 11',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          FilledButton.icon(
            key: const Key('wizard_next_button'),
            onPressed: state.isProcessing
                ? null
                : () => _handleNext(context, ref, state, notifier),
            icon: state.isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    state.activeStep == 9
                        ? Icons.rocket_launch_rounded
                        : Icons.arrow_forward_rounded,
                    size: 18,
                  ),
            label: Text(state.activeStep == 9 ? 'Start Import' : 'Next'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 22.0,
                vertical: 12.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStepShortTitle(int step) {
    switch (step) {
      case 0:
        return 'Source';
      case 1:
        return 'Profile';
      case 2:
        return 'Structure';
      case 3:
        return 'Mapping';
      case 4:
        return 'Config';
      case 5:
        return 'Assign';
      case 6:
        return 'Validate';
      case 7:
        return 'Preview';
      case 8:
        return 'Confirm';
      case 9:
        return 'Execute';
      case 10:
        return 'Report';
      default:
        return 'Import';
    }
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return '1. Select Source Data Format';
      case 1:
        return '2. Select Target Import Profile';
      case 2:
        return '3. Schema & Structure Detection';
      case 3:
        return '4. Column Mapping Matrix';
      case 4:
        return '5. Execution Policy & Config';
      case 5:
        return '6. Dynamic Relations & Fallbacks';
      case 6:
        return '7. Validation & Rule Enforcement';
      case 7:
        return '8. Import Simulation Preview';
      case 8:
        return '9. Pre-flight Job Confirmation';
      case 9:
        return '10. Background Worker Execution';
      case 10:
        return '11. Job Status & Audit Report';
      default:
        return 'Universal Import Engine';
    }
  }

  Widget _buildStepContent(
    BuildContext context,
    WidgetRef ref,
    ImportWizardState state,
    ImportWizardNotifier notifier,
    List<ImportProfile> availableProfiles,
  ) {
    switch (state.activeStep) {
      case 0:
        return _buildStep1Source(context, state, notifier);
      case 1:
        return _buildStep2Profile(context, state, notifier, availableProfiles);
      case 2:
        return _buildStep3Structure(context, state, notifier);
      case 3:
        return _buildStep4Mapping(context, state, notifier);
      case 4:
        return _buildStep5Configuration(context, state, notifier);
      case 5:
        return _buildStep6Assignments(context, state, notifier);
      case 6:
        return _buildStep7Validation(context, state, notifier);
      case 7:
        return _buildStep8Preview(context, state, notifier);
      case 8:
        return _buildStep9Confirm(context, state, notifier);
      case 9:
        return _buildStep10StartDetach(context, state, notifier);
      case 10:
        return _buildStep11ReportHub(context, state, notifier);
      default:
        return const Center(child: Text('Unknown step'));
    }
  }

  Widget _buildStep1Source(
    BuildContext context,
    ImportWizardState state,
    ImportWizardNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 1: Select Import Source',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8.0),
          Text(
            'Supported formats: CSV, Excel (XLSX/XLS), or JSON file',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16.0),

          // Primary File Upload Action Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 48,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 12.0),
                Text(
                  'Upload Import File',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Select a CSV, Excel (.xlsx/.xls), or JSON file from your device',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                FilledButton.icon(
                  key: const Key('pick_file_button'),
                  onPressed: () => _pickSourceFile(context, notifier),
                  icon: const Icon(Icons.folder_open_rounded, size: 20),
                  label: const Text('Browse Files / اختيار ملف'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 14.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20.0),

          DropdownButtonFormField<String>(
            initialValue: state.sourceType,
            decoration: InputDecoration(
              labelText: 'Source Format',
              prefixIcon: const Icon(Icons.dataset_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'csv',
                child: Text('CSV (Comma Separated)'),
              ),
              DropdownMenuItem(value: 'json', child: Text('JSON Format')),
              DropdownMenuItem(value: 'xlsx', child: Text('Excel (XLSX)')),
            ],
            onChanged: (val) => notifier.setRawSourceText(
              state.rawSourceText,
              sourceType: val ?? 'csv',
            ),
          ),
          const SizedBox(height: 16.0),

          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Paste Raw Data Content / Edit',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        final sample =
                            'code,name,price,description\nP001,Sample Product A,150.00,Default Item A\nP002,Sample Product B,280.00,Default Item B';
                        notifier.setRawSourceText(
                          sample,
                          sourceType: state.sourceType,
                        );
                      },
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: const Text('Insert Sample CSV'),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                SizedBox(
                  height: 180,
                  child: TextField(
                    key: const Key('source_raw_text_input'),
                    maxLines: null,
                    expands: true,
                    controller: TextEditingController(text: state.rawSourceText)
                      ..selection = TextSelection.collapsed(
                        offset: state.rawSourceText.length,
                      ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'code,name,price\nP001,Product 1,100.00\nP002,Product 2,250.00',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                    ),
                    onChanged: (text) => notifier.setRawSourceText(
                      text,
                      sourceType: state.sourceType,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickSourceFile(
    BuildContext context,
    ImportWizardNotifier notifier,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv', 'xlsx', 'xls', 'json', 'txt'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final extension = (file.extension ?? '').toLowerCase();
      String detectedType = 'csv';
      if (extension == 'json') {
        detectedType = 'json';
      } else if (extension == 'xlsx' || extension == 'xls') {
        detectedType = 'xlsx';
      }

      String content = '';
      if (file.bytes != null && file.bytes!.isNotEmpty) {
        try {
          content = utf8.decode(file.bytes!);
        } catch (_) {
          content = String.fromCharCodes(file.bytes!);
        }
      }

      notifier.setRawSourceText(content, sourceType: detectedType);

      if (context.mounted) {
        final sizeKb = (file.size / 1024).toStringAsFixed(1);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File loaded: ${file.name} ($sizeKb KB)'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('File selection failed: $e')));
      }
    }
  }

  Widget _buildStep2Profile(
    BuildContext context,
    ImportWizardState state,
    ImportWizardNotifier notifier,
    List<ImportProfile> profiles,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 2: Select Target Import Profile',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8.0),
          Text(
            'Choose the entity blueprint for mapping & normalization rules',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16.0),
          DropdownButtonFormField<String>(
            key: const Key('profile_selection_dropdown'),
            initialValue: state.selectedProfileId,
            decoration: InputDecoration(
              labelText: 'Target Profile',
              prefixIcon: const Icon(Icons.layers_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            items: profiles.map((p) {
              return DropdownMenuItem(
                value: p.profileId,
                child: Text('${p.label} (${p.entityType})'),
              );
            }).toList(),
            onChanged: (id) {
              final selected = profiles.firstWhere((p) => p.profileId == id);
              notifier.selectProfile(selected);
            },
          ),
          const SizedBox(height: 16.0),
          if (state.selectedProfile != null) ...[
            Card(
              child: ListTile(
                title: Text(state.selectedProfile!.label),
                subtitle: Text(
                  'Entity: ${state.selectedProfile!.entityType} | Fields: ${state.selectedProfile!.fields.length} | Relations: ${state.selectedProfile!.relations.length}',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep3Structure(
    BuildContext context,
    ImportWizardState state,
    ImportWizardNotifier notifier,
  ) {
    final schema = state.detectedSchema;
    final headers = schema?.columns.map((c) => c.rawHeader).toList() ?? [];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 3: Detected Structure',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8.0),
          Text(
            'Headers (${headers.length}): ${headers.join(', ')}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            'Total Rows Detected: ${state.parsedDocument?.sheets.first.rows.length ?? 0}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16.0),
          if (schema == null)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else ...[
            Expanded(
              child: ListView.builder(
                itemCount: schema.columns.length,
                itemBuilder: (context, idx) {
                  final col = schema.columns[idx];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        col.rawHeader,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Inferred Type: ${col.inferredType.name}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep4Mapping(
    BuildContext context,
    ImportWizardState state,
    ImportWizardNotifier notifier,
  ) {
    final headers =
        state.detectedSchema?.columns.map((c) => c.rawHeader).toList() ?? [];
    final profileFields = state.selectedProfile?.fields ?? [];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 4: Column Mapping', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8.0),
          Text(
            'Map source file headers to target profile field attributes',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16.0),
          Expanded(
            child: ListView.builder(
              itemCount: headers.length,
              itemBuilder: (context, idx) {
                final header = headers[idx];
                final currentTarget =
                    state.columnMappings[header] ?? '__IGNORE__';
                final isIgnored = state.ignoredColumns.contains(header);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10.0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: isIgnored
                          ? colorScheme.outlineVariant.withValues(alpha: 0.4)
                          : colorScheme.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.table_chart_outlined,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                'Column: $header',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: colorScheme.onSurfaceVariant,
                          size: 18,
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            key: Key('mapping_dropdown_$header'),
                            value: isIgnored ? '__IGNORE__' : currentTarget,
                            items: [
                              const DropdownMenuItem(
                                value: '__IGNORE__',
                                child: Text(
                                  '-- Ignore Column --',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              ...profileFields.map(
                                (f) => DropdownMenuItem(
                                  value: f.key,
                                  child: Text(
                                    '${f.label} (${f.key})${f.isRequired ? ' *' : ''}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                notifier.updateMapping(header, val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep5Configuration(
    BuildContext context,
    ImportWizardState state,
    ImportWizardNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 5: Execution Configuration',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8.0),
          Text(
            'Configure duplicate handling, transactional persistence, and memory chunks',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20.0),
          DropdownButtonFormField<DuplicateResolutionStrategy>(
            key: const Key('config_duplicate_strategy_dropdown'),
            initialValue: state.duplicateResolution,
            decoration: InputDecoration(
              labelText: 'Duplicate Policy',
              prefixIcon: const Icon(Icons.copy_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: DuplicateResolutionStrategy.skip,
                child: Text('Skip Duplicates'),
              ),
              DropdownMenuItem(
                value: DuplicateResolutionStrategy.overwrite,
                child: Text('Overwrite / Update Duplicates'),
              ),
              DropdownMenuItem(
                value: DuplicateResolutionStrategy.error,
                child: Text('Raise Error on Duplicate'),
              ),
            ],
            onChanged: (val) =>
                notifier.updateConfiguration(duplicateResolution: val),
          ),
          const SizedBox(height: 16.0),
          DropdownButtonFormField<ImportPersistenceMode>(
            key: const Key('config_persistence_mode_dropdown'),
            initialValue: state.persistenceMode,
            decoration: InputDecoration(
              labelText: 'Persistence Scoping Mode',
              prefixIcon: const Icon(Icons.security_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: ImportPersistenceMode.allOrNothing,
                child: Text('ALL OR NOTHING (Roll back whole job on failure)'),
              ),
              DropdownMenuItem(
                value: ImportPersistenceMode.perChunk,
                child: Text('PER CHUNK (Commit per chunk)'),
              ),
              DropdownMenuItem(
                value: ImportPersistenceMode.perRow,
                child: Text('PER ROW (Commit per row)'),
              ),
              DropdownMenuItem(
                value: ImportPersistenceMode.bestEffort,
                child: Text('BEST EFFORT (Log errors & commit valid)'),
              ),
            ],
            onChanged: (val) =>
                notifier.updateConfiguration(persistenceMode: val),
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            key: const Key('config_chunk_size_input'),
            initialValue: state.chunkSize.toString(),
            decoration: InputDecoration(
              labelText: 'Chunk Size (Bounded Memory)',
              prefixIcon: const Icon(Icons.memory_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (val) {
              final size = int.tryParse(val);
              if (size != null && size > 0) {
                notifier.updateConfiguration(chunkSize: size);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep6Assignments(
    BuildContext context,
    ImportWizardState state,
    ImportWizardNotifier notifier,
  ) {
    if (state.selectedProfile == null) {
      return const Center(
        child: Text(
          'No target profile selected. Please select a profile in Step 2.',
        ),
      );
    }

    return StepDynamicAssignments(
      profile: state.selectedProfile!,
      assignments: state.dynamicAssignments,
      onAssignmentChanged: (key, val) => notifier.updateAssignment(key, val),
    );
  }

  Widget _buildStep7Validation(
    BuildContext context,
    ImportWizardState state,
    ImportWizardNotifier notifier,
  ) {
    final report = state.validationReport;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 7: Validation Summary',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8.0),
          Text(
            'Dry-run validation issues and rule enforcement report',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16.0),
          if (report == null)
            const Expanded(
              child: Center(
                child: Text(
                  'Click Next or Run Validation to execute dry-run checks.',
                ),
              ),
            )
          else ...[
            Text('Validation Issues Found: ${report.issues.length}'),
            const SizedBox(height: 12.0),
            Expanded(
              child: ListView.builder(
                itemCount: report.issues.length,
                itemBuilder: (context, idx) {
                  final issue = report.issues[idx];
                  return Card(
                    color: issue.severity == ValidationSeverity.error
                        ? colorScheme.errorContainer
                        : colorScheme.tertiaryContainer,
                    child: ListTile(
                      title: Text('Row ${issue.row}: ${issue.code}'),
                      subtitle: Text(issue.message),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep8Preview(
    BuildContext context,
    ImportWizardState state,
    ImportWizardNotifier notifier,
  ) {
    final summary = state.previewSummary;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 8: Import Preview Engine',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8.0),
          Text(
            'Dry-run evaluation of row-level actions prior to committing',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16.0),
          if (summary == null)
            const Expanded(
              child: Center(child: Text('Generating preview summary...')),
            )
          else ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSummaryBadge(
                    context,
                    'Total',
                    '${summary.totalRows}',
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildSummaryBadge(
                    context,
                    'Creates',
                    '${summary.creates}',
                    Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _buildSummaryBadge(
                    context,
                    'Updates',
                    '${summary.updates}',
                    Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _buildSummaryBadge(
                    context,
                    'Skips',
                    '${summary.skips}',
                    Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  _buildSummaryBadge(
                    context,
                    'Errors',
                    '${summary.errors}',
                    Colors.red,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: summary.rows.length,
                itemBuilder: (context, idx) {
                  final row = summary.rows[idx];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${row.rowIndex + 1}')),
                      title: Text(
                        'Action: ${row.action.name.toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(row.explanation),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryBadge(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStep9Confirm(
    BuildContext context,
    ImportWizardState state,
    ImportWizardNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 80,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16.0),
              Text(
                'Ready to Start Import Job',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8.0),
              Text(
                'Profile: ${state.selectedProfile?.label ?? "Generic"} | Target Company: $companyId',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6.0),
              Text(
                'Total Rows: ${state.parsedDocument?.sheets.first.rows.length ?? 0}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20.0),
              Text(
                'Click "Start Import" to submit the job to background execution.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep10StartDetach(
    BuildContext context,
    ImportWizardState state,
    ImportWizardNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rocket_launch_outlined,
              size: 80,
              color: Colors.green.shade600,
            ),
            const SizedBox(height: 16.0),
            Text(
              'Import Started Successfully!',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8.0),
            Chip(
              label: Text('Job ID: ${state.activeJob?.jobId ?? "JOB-QUEUED"}'),
              backgroundColor: colorScheme.primaryContainer,
            ),
            const SizedBox(height: 16.0),
            Text(
              'The import job is executing independently in the background.',
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              'You may safely navigate away or close this wizard.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep11ReportHub(
    BuildContext context,
    ImportWizardState state,
    ImportWizardNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assessment_outlined,
              size: 80,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16.0),
            Text('Import Job Status Hub', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8.0),
            Chip(
              label: Text(
                'Job Status: ${state.activeJob?.status.name.toUpperCase() ?? "QUEUED"}',
              ),
              backgroundColor: Colors.green.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 24.0),
            FilledButton.icon(
              onPressed: () => notifier.reset(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Start Another Import'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 12.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNext(
    BuildContext context,
    WidgetRef ref,
    ImportWizardState state,
    ImportWizardNotifier notifier,
  ) async {
    switch (state.activeStep) {
      case 0:
        if (state.rawSourceText.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter raw data content.')),
          );
          return;
        }
        notifier.nextStep();
        break;
      case 1:
        if (state.selectedProfileId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a target profile.')),
          );
          return;
        }
        notifier.nextStep();
        await notifier.detectStructure();
        break;
      case 2:
      case 3:
      case 4:
      case 5:
        notifier.nextStep();
        if (state.activeStep == 5) {
          await notifier.runValidation();
        }
        break;
      case 6:
        notifier.nextStep();
        await notifier.runPreview();
        break;
      case 7:
      case 8:
        if (state.activeStep == 8) {
          final job = await notifier.startImport(
            companyId: companyId,
            userId: userId,
          );
          if (job != null) {
            onImportStarted?.call();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Import started (${job.jobId})')),
              );
            }
          }
        }
        notifier.nextStep();
        break;
      case 9:
      case 10:
        notifier.nextStep();
        break;
    }
  }
}
