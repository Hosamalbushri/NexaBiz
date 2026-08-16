/// Global initialization status for System Setup.
enum SystemSetupStatus {
  notStarted,
  inProgress,
  ready;

  static SystemSetupStatus fromStorage(String? raw) {
    return switch (raw) {
      'inProgress' => SystemSetupStatus.inProgress,
      'ready' => SystemSetupStatus.ready,
      _ => SystemSetupStatus.notStarted,
    };
  }

  String get storageValue => name;
}

/// Lifecycle of a single setup step.
enum SetupStepStatus {
  pending,
  inProgress,
  completed,
  failed,
  skipped;

  static SetupStepStatus fromStorage(String? raw) {
    return switch (raw) {
      'inProgress' => SetupStepStatus.inProgress,
      'completed' => SetupStepStatus.completed,
      'failed' => SetupStepStatus.failed,
      'skipped' => SetupStepStatus.skipped,
      _ => SetupStepStatus.pending,
    };
  }

  String get storageValue => name;

  bool get isTerminalSuccess =>
      this == SetupStepStatus.completed || this == SetupStepStatus.skipped;
}

/// Stable ids for System Setup steps.
enum SetupStepId {
  locale,
  primaryCurrency,
  companyProfile,
  seedLocal;

  static const requiredIds = <SetupStepId>[
    SetupStepId.locale,
    SetupStepId.primaryCurrency,
    SetupStepId.companyProfile,
    SetupStepId.seedLocal,
  ];

  static const allIds = requiredIds;

  String get storageKey => name;

  static SetupStepId? tryParse(String raw) {
    for (final id in SetupStepId.values) {
      if (id.storageKey == raw || id.name == raw) {
        return id;
      }
    }
    return null;
  }
}

/// Persisted state for one setup step.
class SetupStepState {
  const SetupStepState({
    required this.id,
    required this.status,
    this.updatedAt,
    this.errorMessage,
  });

  final SetupStepId id;
  final SetupStepStatus status;
  final DateTime? updatedAt;
  final String? errorMessage;

  SetupStepState copyWith({
    SetupStepStatus? status,
    DateTime? updatedAt,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SetupStepState(
      id: id,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  Map<String, Object?> toMap() => {
    'status': status.storageValue,
    'updatedAt': updatedAt?.toUtc().millisecondsSinceEpoch,
    'errorMessage': errorMessage,
  };

  factory SetupStepState.fromMap(SetupStepId id, Map<dynamic, dynamic> map) {
    final updatedRaw = map['updatedAt'];
    return SetupStepState(
      id: id,
      status: SetupStepStatus.fromStorage(map['status'] as String?),
      updatedAt: updatedRaw is int
          ? DateTime.fromMillisecondsSinceEpoch(updatedRaw, isUtc: true)
          : null,
      errorMessage: map['errorMessage'] as String?,
    );
  }
}

/// Snapshot of setup progress used by UI and gate checks.
class SetupProgress {
  const SetupProgress({
    required this.schemaVersion,
    required this.status,
    required this.steps,
    this.lastUpdated,
  });

  final int schemaVersion;
  final SystemSetupStatus status;
  final Map<SetupStepId, SetupStepState> steps;
  final DateTime? lastUpdated;

  bool get isReady => status == SystemSetupStatus.ready;

  int get requiredTotal => SetupStepId.requiredIds.length;

  int get requiredDone => SetupStepId.requiredIds
      .where((id) => steps[id]?.status.isTerminalSuccess ?? false)
      .length;

  /// 0–100 based on required steps only.
  int get percentComplete {
    if (requiredTotal == 0) {
      return 100;
    }
    return ((requiredDone / requiredTotal) * 100).round().clamp(0, 100);
  }

  bool get allRequiredComplete => requiredDone >= requiredTotal;

  SetupStepId? get currentStep {
    for (final id in SetupStepId.allIds) {
      final state = steps[id];
      if (state == null || !state.status.isTerminalSuccess) {
        return id;
      }
    }
    return null;
  }

  SetupStepState stateFor(SetupStepId id) {
    return steps[id] ??
        SetupStepState(id: id, status: SetupStepStatus.pending);
  }
}

/// Versioned schema for System Setup persistence.
class SystemSetupSchema {
  const SystemSetupSchema._();

  /// v2: locale → primary currency (locked) ordering + currency lock flag.
  static const int currentVersion = 2;
}
