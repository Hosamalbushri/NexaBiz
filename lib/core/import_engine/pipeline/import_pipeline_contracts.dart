import '../domain/entities/import_assignment.dart';
import '../domain/entities/import_configuration.dart';
import '../domain/entities/import_context.dart';
import '../domain/entities/import_profile.dart';
import '../domain/entities/import_result.dart';
import '../domain/entities/import_row.dart';
import '../domain/ports/import_source.dart';

/// Pipeline Stage 1: Parse raw input source into raw row records.
abstract class ImportParserContract {
  Stream<ImportRow> parse(ImportSource source);
}

/// Pipeline Stage 2: Detect header columns and suggest field assignments.
abstract class ImportHeaderDetectorContract {
  Future<List<ImportAssignment>> detectAssignments({
    required List<String> sourceHeaders,
    required ImportProfile profile,
  });
}

/// Pipeline Stage 3: Map source headers to profile target fields.
abstract class ImportMapperContract {
  ImportRow mapRow({
    required ImportRow rawRow,
    required ImportConfiguration configuration,
    required ImportProfile profile,
  });
}

/// Pipeline Stage 4: Normalize raw value types according to schema definitions.
abstract class ImportNormalizerContract {
  ImportRow normalizeRow({
    required ImportRow mappedRow,
    required ImportProfile profile,
  });
}

/// Pipeline Stage 5: Validate row rules, constraints, and business logic.
abstract class ImportValidatorContract {
  ImportRow validateRow({
    required ImportRow normalizedRow,
    required ImportProfile profile,
    required ImportContext context,
  });
}

/// Pipeline Stage 6: Resolve cross-entity relations (e.g. category code -> UUID).
abstract class ImportRelationResolverContract {
  Future<ImportRow> resolveRelations({
    required ImportRow validatedRow,
    required ImportProfile profile,
    required ImportContext context,
  });
}

/// Pipeline Stage 7: Assign final entity creation payload/draft.
abstract class ImportAssignerContract<T> {
  T assignPayload({
    required ImportRow resolvedRow,
    required ImportProfile profile,
    required ImportContext context,
  });
}

/// Pipeline Stage 8: Generate dry-run preview of dataset before persistence.
abstract class ImportPreviewerContract {
  Future<List<ImportRow>> generatePreview({
    required List<ImportRow> rows,
    required ImportProfile profile,
    int previewLimit = 10,
  });
}

/// Pipeline Stage 9: Persist validated entity payloads to database & outbox.
abstract class ImportPersisterContract<T> {
  Future<ImportResult> persistBatch({
    required List<T> payloads,
    required ImportProfile profile,
    required ImportContext context,
    required ImportConfiguration configuration,
  });
}

/// Pipeline Stage 10: Generate structured execution summary report.
abstract class ImportReporterContract {
  ImportResult generateReport({
    required String jobId,
    required List<ImportRow> processedRows,
    required Duration duration,
  });
}
