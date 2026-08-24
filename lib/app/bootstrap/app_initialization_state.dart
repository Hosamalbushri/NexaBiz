import '../../core/errors/app_error_domain.dart';

/// Individual stages in the initialization pipeline.
enum InitializationStage {
  none,
  coreBootstrap,
  localStorage,
  database,
  configuration,
  selectingMode,
  localInitialization,
  validatingServer,
  authenticating,
  checkingRemoteInitialization,
  downloadingInitialization,
  initializingLocalDatabase,
  synchronization,
  applicationReady,
}

/// Explicit high-level initialization status.
enum InitializationStatus {
  notStarted,
  uninitialized,
  selectingMode,
  initializing,
  validatingServer,
  authenticating,
  checkingRemoteInitialization,
  serverNoData,
  downloadingInitialization,
  initializingLocalDatabase,
  synchronizing,
  bootstrapCompleted,
  ready,
  setupRequired,
  degraded,
  failed,
  retrying,
}

/// Operating mode chosen by the user during setup.
enum ApplicationOperatingMode {
  none,
  local,
  server,
}

/// Represents the explicit state of application initialization.
class InitializationState {
  const InitializationState({
    required this.status,
    this.stage = InitializationStage.none,
    this.operatingMode = ApplicationOperatingMode.none,
    this.error,
    this.isFirstLaunch = false,
    this.startedAt,
    this.completedAt,
    this.stageDetails = '',
    this.currentStep = 0,
    this.totalSteps = 0,
    this.progressPercentage = 0.0,
    this.currentEntityType = '',
    this.downloadedCount = 0,
    this.totalToDownload = 0,
  });

  const InitializationState.notStarted()
      : this(status: InitializationStatus.notStarted);

  final InitializationStatus status;
  final InitializationStage stage;
  final ApplicationOperatingMode operatingMode;
  final AppError? error;
  final bool isFirstLaunch;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String stageDetails;
  final int currentStep;
  final int totalSteps;
  final double progressPercentage;
  final String currentEntityType;
  final int downloadedCount;
  final int totalToDownload;

  bool get isNotStarted => status == InitializationStatus.notStarted;
  bool get isUninitialized => status == InitializationStatus.uninitialized;
  bool get isSelectingMode => status == InitializationStatus.selectingMode;
  bool get isInitializing => status == InitializationStatus.initializing;
  bool get isValidatingServer => status == InitializationStatus.validatingServer;
  bool get isAuthenticating => status == InitializationStatus.authenticating;
  bool get isCheckingRemote => status == InitializationStatus.checkingRemoteInitialization;
  bool get isServerNoData => status == InitializationStatus.serverNoData;
  bool get isDownloading => status == InitializationStatus.downloadingInitialization;
  bool get isWritingDatabase => status == InitializationStatus.initializingLocalDatabase;
  bool get isSynchronizing => status == InitializationStatus.synchronizing;
  bool get isBootstrapCompleted => status == InitializationStatus.bootstrapCompleted;
  bool get isReady => status == InitializationStatus.ready;
  bool get isSetupRequired => status == InitializationStatus.setupRequired;
  bool get isDegraded => status == InitializationStatus.degraded;
  bool get isFailed => status == InitializationStatus.failed;
  bool get isRetrying => status == InitializationStatus.retrying;

  /// Whether the app is functional enough for user interaction (either ready, degraded, setup required, or selecting mode).
  bool get canOperate => isReady || isDegraded || isSetupRequired || isSelectingMode;

  InitializationState copyWith({
    InitializationStatus? status,
    InitializationStage? stage,
    ApplicationOperatingMode? operatingMode,
    AppError? error,
    bool clearError = false,
    bool? isFirstLaunch,
    DateTime? startedAt,
    DateTime? completedAt,
    String? stageDetails,
    int? currentStep,
    int? totalSteps,
    double? progressPercentage,
    String? currentEntityType,
    int? downloadedCount,
    int? totalToDownload,
  }) {
    return InitializationState(
      status: status ?? this.status,
      stage: stage ?? this.stage,
      operatingMode: operatingMode ?? this.operatingMode,
      error: clearError ? null : (error ?? this.error),
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      stageDetails: stageDetails ?? this.stageDetails,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      currentEntityType: currentEntityType ?? this.currentEntityType,
      downloadedCount: downloadedCount ?? this.downloadedCount,
      totalToDownload: totalToDownload ?? this.totalToDownload,
    );
  }

  @override
  String toString() =>
      'InitializationState(status: $status, stage: $stage, mode: $operatingMode, isFirstLaunch: $isFirstLaunch, error: $error)';
}
