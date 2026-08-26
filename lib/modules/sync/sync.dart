library;

// Data stores
export 'engine/data/stores/sync_cursor_store.dart';
export 'engine/data/stores/sync_metrics_store.dart';
export 'engine/data/stores/sync_operation_adapter.dart';
export 'engine/data/stores/sync_os_background_bridge.dart';
export 'engine/data/stores/sync_os_wake_signal.dart';

// Domain entities
export 'engine/domain/entities/dataset_sync_state.dart';
export 'engine/domain/entities/sync_conflict_record.dart';
export 'engine/domain/entities/sync_error_code.dart';
export 'engine/domain/entities/sync_error_detail.dart';
export 'engine/domain/entities/sync_operation.dart';
export 'engine/domain/entities/sync_overview.dart';
export 'engine/domain/entities/sync_status.dart';

// Domain services
export 'engine/domain/services/conflict_resolver.dart';
export 'engine/domain/services/conflict_strategy.dart';
export 'engine/domain/services/initial_cloud_sync_scanner.dart';
export 'engine/domain/services/local_dataset_inspector.dart';
export 'engine/domain/services/sync_conflict_store.dart';
export 'engine/domain/services/sync_entity_handler.dart';
export 'engine/domain/services/sync_error_classifier.dart';
export 'engine/domain/services/sync_manager.dart';
export 'engine/domain/services/sync_queue.dart';
export 'engine/domain/services/sync_queue_recovery_service.dart';
export 'engine/domain/services/sync_request_context.dart';
export 'engine/domain/services/three_way_merger.dart';

// Presentation providers
export 'engine/presentation/providers/sync_providers.dart';

// Module definition
export 'package:stock_count/modules/sync/sync_module.dart';
