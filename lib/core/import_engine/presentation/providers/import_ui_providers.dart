import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../import_engine.dart';

/// State object for the 11-step Universal Import Wizard UI.
class ImportWizardState {
  const ImportWizardState({
    this.activeStep = 0,
    this.rawSourceText = '',
    this.sourceType = 'csv',
    this.parsedDocument,
    this.selectedProfileId,
    this.selectedProfile,
    this.detectedSchema,
    this.columnMappings = const {},
    this.ignoredColumns = const {},
    this.duplicateResolution = DuplicateResolutionStrategy.skip,
    this.chunkSize = 500,
    this.persistenceMode = ImportPersistenceMode.allOrNothing,
    this.dynamicAssignments = const {},
    this.validationReport,
    this.previewSummary,
    this.activeJob,
    this.isProcessing = false,
    this.errorMessage,
  });

  final int activeStep;
  final String rawSourceText;
  final String sourceType;
  final ParsedDocument? parsedDocument;
  final String? selectedProfileId;
  final ImportProfile? selectedProfile;
  final DetectedSchema? detectedSchema;
  final Map<String, String> columnMappings; // sourceHeader -> targetFieldKey
  final Set<String> ignoredColumns;
  final DuplicateResolutionStrategy duplicateResolution;
  final int chunkSize;
  final ImportPersistenceMode persistenceMode;
  final Map<String, dynamic> dynamicAssignments;
  final ValidationReport? validationReport;
  final ImportPreviewSummary? previewSummary;
  final ImportJob? activeJob;
  final bool isProcessing;
  final String? errorMessage;

  ImportWizardState copyWith({
    int? activeStep,
    String? rawSourceText,
    String? sourceType,
    ParsedDocument? parsedDocument,
    String? selectedProfileId,
    ImportProfile? selectedProfile,
    DetectedSchema? detectedSchema,
    Map<String, String>? columnMappings,
    Set<String>? ignoredColumns,
    DuplicateResolutionStrategy? duplicateResolution,
    int? chunkSize,
    ImportPersistenceMode? persistenceMode,
    Map<String, dynamic>? dynamicAssignments,
    ValidationReport? validationReport,
    ImportPreviewSummary? previewSummary,
    ImportJob? activeJob,
    bool? isProcessing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ImportWizardState(
      activeStep: activeStep ?? this.activeStep,
      rawSourceText: rawSourceText ?? this.rawSourceText,
      sourceType: sourceType ?? this.sourceType,
      parsedDocument: parsedDocument ?? this.parsedDocument,
      selectedProfileId: selectedProfileId ?? this.selectedProfileId,
      selectedProfile: selectedProfile ?? this.selectedProfile,
      detectedSchema: detectedSchema ?? this.detectedSchema,
      columnMappings: columnMappings ?? this.columnMappings,
      ignoredColumns: ignoredColumns ?? this.ignoredColumns,
      duplicateResolution: duplicateResolution ?? this.duplicateResolution,
      chunkSize: chunkSize ?? this.chunkSize,
      persistenceMode: persistenceMode ?? this.persistenceMode,
      dynamicAssignments: dynamicAssignments ?? this.dynamicAssignments,
      validationReport: validationReport ?? this.validationReport,
      previewSummary: previewSummary ?? this.previewSummary,
      activeJob: activeJob ?? this.activeJob,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// State notifier managing wizard interactions across all 11 import steps.
class ImportWizardNotifier extends StateNotifier<ImportWizardState> {
  ImportWizardNotifier({
    required this.jobRepository,
    required this.worker,
  }) : super(const ImportWizardState());

  final ImportJobRepository jobRepository;
  final ImportBackgroundWorker worker;

  void setRawSourceText(String text, {String sourceType = 'csv'}) {
    state = state.copyWith(
      rawSourceText: text,
      sourceType: sourceType,
      clearError: true,
    );
  }

  void updateSourceType(String sourceType) {
    state = state.copyWith(sourceType: sourceType);
  }

  void updateRawSourceText(String text) {
    state = state.copyWith(rawSourceText: text);
  }

  void selectProfile(ImportProfile profile) {
    state = state.copyWith(
      selectedProfileId: profile.profileId,
      selectedProfile: profile,
      clearError: true,
    );
  }

  void setStep(int step) {
    if (step >= 0 && step <= 10) {
      state = state.copyWith(activeStep: step);
    }
  }

  void nextStep() {
    if (state.activeStep < 10) {
      setStep(state.activeStep + 1);
    }
  }

  void previousStep() {
    if (state.activeStep > 0) {
      setStep(state.activeStep - 1);
    }
  }

  /// Step 3: Detect Structure & Parse Document
  Future<void> parseSource() => detectStructure();

  Future<void> detectStructure() async {
    if (state.rawSourceText.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Source content cannot be empty.');
      return;
    }

    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final source = StringImportSource(
        sourceId: 'SOURCE-RAW-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Raw Content Payload',
        content: state.rawSourceText,
      );

      final format = state.sourceType == 'json'
          ? ImportFileFormat.json
          : state.sourceType == 'xlsx'
              ? ImportFileFormat.xlsx
              : ImportFileFormat.csv;

      final parser = UniversalParserFactory.forFormat(format);
      final doc = await parser.parseDocument(source);

      final detector = const SchemaDetector();
      final schema = detector.detectDocument(doc);

      final headers = schema.columns.map((c) => c.rawHeader).toList();

      // Auto-map if profile is selected
      Map<String, String> autoMapped = {};
      if (state.selectedProfile != null && headers.isNotEmpty) {
        final autoMapper = const AutoMapper();
        final mappingResults = autoMapper.mapColumns(
          columns: schema.columns,
          targetFields: state.selectedProfile!.fields,
        );
        for (final res in mappingResults) {
          if (res.isMapped && res.targetField != null) {
            autoMapped[res.sourceColumnHeader] = res.targetField!.key;
          }
        }
      }

      state = state.copyWith(
        parsedDocument: doc,
        detectedSchema: schema,
        columnMappings: autoMapped,
        isProcessing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Structure detection failed: $e',
      );
    }
  }

  void autoMapColumns() {
    final schema = state.detectedSchema;
    final profile = state.selectedProfile;
    if (schema != null && profile != null) {
      final autoMapper = const AutoMapper();
      final mappingResults = autoMapper.mapColumns(
        columns: schema.columns,
        targetFields: profile.fields,
      );
      Map<String, String> autoMapped = {};
      for (final res in mappingResults) {
        if (res.isMapped && res.targetField != null) {
          autoMapped[res.sourceColumnHeader] = res.targetField!.key;
        }
      }
      state = state.copyWith(columnMappings: autoMapped);
    }
  }

  /// Step 4: Update Column Mapping
  void updateMapping(String sourceHeader, String targetFieldKey) {
    final updated = Map<String, String>.from(state.columnMappings);
    if (targetFieldKey.isEmpty || targetFieldKey == '__IGNORE__') {
      updated.remove(sourceHeader);
    } else {
      updated[sourceHeader] = targetFieldKey;
    }
    state = state.copyWith(columnMappings: updated);
  }

  void toggleIgnoreColumn(String sourceHeader) {
    final ignored = Set<String>.from(state.ignoredColumns);
    if (ignored.contains(sourceHeader)) {
      ignored.remove(sourceHeader);
    } else {
      ignored.add(sourceHeader);
    }
    state = state.copyWith(ignoredColumns: ignored);
  }

  /// Step 5: Configuration Settings
  void updateConfiguration({
    DuplicateResolutionStrategy? duplicateResolution,
    int? chunkSize,
    ImportPersistenceMode? persistenceMode,
  }) {
    state = state.copyWith(
      duplicateResolution: duplicateResolution ?? state.duplicateResolution,
      chunkSize: chunkSize ?? state.chunkSize,
      persistenceMode: persistenceMode ?? state.persistenceMode,
    );
  }

  /// Step 6: Dynamic Assignment Value Update
  void updateAssignment(String key, dynamic value) {
    final updated = Map<String, dynamic>.from(state.dynamicAssignments);
    if (value == null) {
      updated.remove(key);
    } else {
      updated[key] = value;
    }
    state = state.copyWith(dynamicAssignments: updated);
  }

  /// Step 7: Run Validation
  Future<void> runValidation() async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final rows = state.parsedDocument?.sheets.first.rows ?? [];
      final issues = <ValidationIssue>[];

      if (state.selectedProfile != null) {
        for (int i = 0; i < rows.length; i++) {
          final rowCells = rows[i].cells;
          for (final field in state.selectedProfile!.fields) {
            if (field.isRequired) {
              final mappedHeader = state.columnMappings.entries
                  .firstWhere((e) => e.value == field.key, orElse: () => const MapEntry('', ''))
                  .key;

              final cell = rowCells.firstWhere(
                (c) => c.headerName == mappedHeader,
                orElse: () => ParsedCell.empty(0),
              );

              if (cell.isEmpty) {
                issues.add(ValidationIssue(
                  row: i + 1,
                  field: field.key,
                  code: 'REQUIRED_FIELD_MISSING',
                  severity: ValidationSeverity.error,
                  message: 'Required field ${field.label} (${field.key}) is missing or empty.',
                ));
              }
            }
          }
        }
      }

      final report = ValidationReport(
        issues: issues,
        totalProcessedRows: rows.length,
      );

      state = state.copyWith(
        validationReport: report,
        isProcessing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Validation error: $e',
      );
    }
  }

  /// Step 8: Run Preview Engine
  Future<void> runPreview() async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final doc = state.parsedDocument;
      if (doc == null || state.selectedProfile == null) {
        state = state.copyWith(
          isProcessing: false,
          errorMessage: 'Document or target profile is missing for preview.',
        );
        return;
      }

      final rawRows = doc.sheets.first.rows;
      final targetFields = state.selectedProfile!.fields;

      final mappings = state.columnMappings.entries.map((e) {
        final field = targetFields.firstWhere((f) => f.key == e.value);
        return FieldMappingResult(
          sourceColumnIndex: 0,
          sourceColumnHeader: e.key,
          normalizedSourceHeader: e.key,
          targetField: field,
          matchStrategy: MappingMatchStrategy.manual,
        );
      }).toList();

      final previewEngine = const ImportPreviewEngine();
      final summary = await previewEngine.generatePreview(
        rawRows: rawRows,
        targetFields: targetFields,
        mappings: mappings,
        fixedAssignments: state.dynamicAssignments,
      );

      state = state.copyWith(
        previewSummary: summary,
        isProcessing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Preview generation failed: $e',
      );
    }
  }

  /// Step 9 & 10: Start Import & Detach
  Future<ImportJob?> startImport({
    required String companyId,
    required String userId,
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final totalRows = state.parsedDocument?.sheets.first.rows.length ?? 0;
      final profile = state.selectedProfile;
      final profileId = profile?.profileId ?? 'PROF-GENERIC';

      final List<ImportAssignment> assignments = state.dynamicAssignments.entries.map((e) {
        return ImportAssignment(
          targetFieldKey: e.key,
          staticValue: e.value,
        );
      }).toList();

      final job = ImportJob(
        jobId: 'JOB-${DateTime.now().millisecondsSinceEpoch}',
        companyId: companyId,
        userId: userId,
        source: 'RAW_SOURCE',
        profile: profile,
        status: ImportJobStatus.queued,
        createdAt: DateTime.now().toUtc(),
        totalRows: totalRows,
        configuration: ImportConfiguration(
          profileId: profileId,
          assignments: assignments,
          policy: ImportPolicy(
            duplicateResolution: state.duplicateResolution,
          ),
        ),
      );

      await jobRepository.save(job);
      await worker.enqueue(job);

      state = state.copyWith(
        activeJob: job,
        isProcessing: false,
      );

      return job;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Failed to start import: $e',
      );
      return null;
    }
  }

  void reset() {
    state = const ImportWizardState();
  }
}

// Global Providers
final importJobRepositoryProvider = Provider<ImportJobRepository>((ref) {
  return InMemoryImportJobRepository();
});

final importBackgroundWorkerProvider = Provider<ImportBackgroundWorker>((ref) {
  final repo = ref.watch(importJobRepositoryProvider);
  return ImportBackgroundWorker(repository: repo);
});

final importWizardProvider =
    StateNotifierProvider<ImportWizardNotifier, ImportWizardState>((ref) {
  final repo = ref.watch(importJobRepositoryProvider);
  final worker = ref.watch(importBackgroundWorkerProvider);
  return ImportWizardNotifier(jobRepository: repo, worker: worker);
});

final importWizardNotifierProvider = importWizardProvider;

final importReportRepositoryProvider = Provider<ImportReportRepository>((ref) {
  return InMemoryImportReportRepository();
});

final importTemplateRepositoryProvider = Provider<ImportTemplateRepository>((ref) {
  return InMemoryImportTemplateRepository();
});
