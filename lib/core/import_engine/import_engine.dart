library;

// Domain Entities
export 'domain/entities/import_assignment.dart';
export 'domain/entities/import_configuration.dart';
export 'domain/entities/import_context.dart';
export 'domain/entities/import_error.dart';
export 'domain/entities/import_execution_mode.dart';
export 'domain/entities/import_field.dart';
export 'domain/entities/import_job.dart';
export 'domain/entities/import_job_status.dart';
export 'domain/entities/import_parse_error.dart';
export 'domain/entities/import_policy.dart';
export 'domain/entities/import_profile.dart';
export 'domain/entities/import_relation.dart';
export 'domain/entities/import_result.dart';
export 'domain/entities/import_row.dart';
export 'domain/entities/import_status.dart';
export 'domain/entities/import_sync_mode.dart';
export 'domain/entities/import_value.dart';
export 'sync/import_sync_bridge.dart';
export 'domain/entities/parsed_cell.dart';
export 'domain/entities/parsed_document.dart';
export 'domain/entities/parsed_row.dart';
export 'domain/entities/parsed_sheet.dart';

// Exceptions
export 'domain/exceptions/import_engine_exception.dart';
export 'domain/exceptions/tenant_isolation_exception.dart';

// Ports & Repositories
export 'domain/ports/import_job_repository.dart';
export 'domain/ports/import_source.dart';
export 'repository/in_memory_import_job_repository.dart';
export 'sources/bytes_import_source.dart';
export 'sources/string_import_source.dart';

// Parsers
export 'parser/csv_import_parser.dart';
export 'parser/import_parser.dart';
export 'parser/json_import_parser.dart';
export 'parser/universal_parser_factory.dart';
export 'parser/xlsx_import_parser.dart';

// Detectors
export 'detector/detected_column.dart';
export 'detector/detected_schema.dart';
export 'detector/header_normalizer.dart';
export 'detector/inferred_primitive_type.dart';
export 'detector/schema_detector.dart';
export 'detector/type_inferrer.dart';

// Mapping
export 'mapping/auto_mapper.dart';
export 'mapping/field_mapping_result.dart';
export 'mapping/mapping_engine.dart';
export 'mapping/mapping_enums.dart';
export 'mapping/mapping_profile.dart';
export 'mapping/mapping_report.dart';

// Normalizers
export 'normalizer/boolean_normalizer.dart';
export 'normalizer/code_normalizer.dart';
export 'normalizer/date_normalizer.dart';
export 'normalizer/datetime_normalizer.dart';
export 'normalizer/decimal_normalizer.dart';
export 'normalizer/normalization_engine.dart';
export 'normalizer/normalized_value.dart';
export 'normalizer/null_normalizer.dart';
export 'normalizer/number_normalizer.dart';
export 'normalizer/string_normalizer.dart';

// Validators
export 'validator/validation_engine.dart';
export 'validator/validation_issue.dart';
export 'validator/validation_report.dart';
export 'validator/validation_rule.dart';
export 'validator/validation_severity.dart';

// Relations
export 'relation/relation_definition.dart';
export 'relation/relation_resolver.dart';
export 'relation/resolution_result.dart';
export 'relation/resolution_status.dart';
export 'relation/resolution_strategy.dart';

// Assignments
export 'assignment/assignment_engine.dart';
export 'assignment/assignment_policy.dart';
export 'assignment/assignment_result.dart';
export 'assignment/assignment_rule.dart';
export 'assignment/assignment_strategy.dart';

// Pipeline Contracts & Chunked Engine
export 'pipeline/chunked_execution_engine.dart';
export 'pipeline/import_pipeline_contracts.dart';

// Checkpoints
export 'checkpoint/import_checkpoint.dart';
export 'checkpoint/import_checkpoint_repository.dart';

// Persistence & Transactions
export 'persistence/import_persistence_handler.dart';
export 'persistence/import_persistence_mode.dart';
export 'persistence/import_transaction_runner.dart';
export 'persistence/persistence_execution_engine.dart';

// Worker & Background Execution
export 'worker/import_background_worker.dart';

// Preview & Dry-Run
export 'preview/import_preview_engine.dart';
export 'preview/import_preview_row.dart';
export 'preview/import_preview_summary.dart';
export 'preview/import_row_action.dart';

// Reporting & Audit
export 'report/import_audit_record.dart';
export 'report/import_error_report.dart';
export 'report/import_report.dart';
export 'report/import_report_repository.dart';
export 'report/import_row_result.dart';

// Notifications
export 'notification/import_notification_bridge.dart';

// Templates
export 'template/import_template.dart';
export 'template/import_template_repository.dart';

// Registry
export 'registry/import_profile_registry.dart';

// Presentation & UI
export 'presentation/providers/import_ui_providers.dart';
export 'presentation/widgets/step_dynamic_assignments.dart';
export 'presentation/pages/universal_import_page.dart';
export 'presentation/pages/import_jobs_list_page.dart';

export 'presentation/pages/import_job_details_page.dart';
export 'presentation/pages/import_report_page.dart';
export 'presentation/pages/import_profiles_overview_page.dart';
export 'presentation/routes/import_engine_routes.dart';
export 'import_engine_module.dart';
