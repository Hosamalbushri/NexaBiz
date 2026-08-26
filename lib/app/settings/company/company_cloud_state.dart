enum CompanyCloudStatus {
  localOnly,
  provisioning,
  cloudCompanyCreated,
  cloudAdminLinked,
  subscriptionPending,
  subscriptionActive,
  linked,
  initialSyncing,
  cloudReady,
  provisioningFailed;

  static CompanyCloudStatus fromString(String? value) {
    if (value == null) return CompanyCloudStatus.localOnly;
    final clean = value.trim().toUpperCase();
    switch (clean) {
      case 'LOCAL_ONLY':
      case 'LOCALONLY':
        return CompanyCloudStatus.localOnly;
      case 'PROVISIONING':
        return CompanyCloudStatus.provisioning;
      case 'CLOUD_COMPANY_CREATED':
        return CompanyCloudStatus.cloudCompanyCreated;
      case 'CLOUD_ADMIN_LINKED':
        return CompanyCloudStatus.cloudAdminLinked;
      case 'SUBSCRIPTION_PENDING':
        return CompanyCloudStatus.subscriptionPending;
      case 'SUBSCRIPTION_ACTIVE':
        return CompanyCloudStatus.subscriptionActive;
      case 'LINKED':
        return CompanyCloudStatus.linked;
      case 'INITIAL_SYNCING':
        return CompanyCloudStatus.initialSyncing;
      case 'CLOUD_READY':
        return CompanyCloudStatus.cloudReady;
      case 'PROVISIONING_FAILED':
        return CompanyCloudStatus.provisioningFailed;
      default:
        return CompanyCloudStatus.localOnly;
    }
  }

  String toDbString() {
    switch (this) {
      case CompanyCloudStatus.localOnly:
        return 'LOCAL_ONLY';
      case CompanyCloudStatus.provisioning:
        return 'PROVISIONING';
      case CompanyCloudStatus.cloudCompanyCreated:
        return 'CLOUD_COMPANY_CREATED';
      case CompanyCloudStatus.cloudAdminLinked:
        return 'CLOUD_ADMIN_LINKED';
      case CompanyCloudStatus.subscriptionPending:
        return 'SUBSCRIPTION_PENDING';
      case CompanyCloudStatus.subscriptionActive:
        return 'SUBSCRIPTION_ACTIVE';
      case CompanyCloudStatus.linked:
        return 'LINKED';
      case CompanyCloudStatus.initialSyncing:
        return 'INITIAL_SYNCING';
      case CompanyCloudStatus.cloudReady:
        return 'CLOUD_READY';
      case CompanyCloudStatus.provisioningFailed:
        return 'PROVISIONING_FAILED';
    }
  }
}

/// Durable local record representing cloud provisioning and subscription status for a local company.
class CompanyCloudState {
  const CompanyCloudState({
    required this.localCompanyId,
    this.serverCompanyId,
    this.cloudStatus = CompanyCloudStatus.localOnly,
    this.cloudProvisioningId,
    this.subscriptionId,
    this.planId,
    this.cloudLinkedAt,
    this.lastProvisioningError,
  });

  final String localCompanyId;
  final String? serverCompanyId;
  final CompanyCloudStatus cloudStatus;
  final String? cloudProvisioningId;
  final String? subscriptionId;
  final String? planId;
  final DateTime? cloudLinkedAt;
  final String? lastProvisioningError;

  bool get isLocalOnly => cloudStatus == CompanyCloudStatus.localOnly;
  bool get isCloudReady => cloudStatus == CompanyCloudStatus.cloudReady;
  bool get isCloudLinked =>
      serverCompanyId != null &&
      serverCompanyId!.isNotEmpty &&
      (cloudStatus == CompanyCloudStatus.linked ||
          cloudStatus == CompanyCloudStatus.initialSyncing ||
          cloudStatus == CompanyCloudStatus.cloudReady ||
          cloudStatus == CompanyCloudStatus.subscriptionActive);

  factory CompanyCloudState.localDefault(String localCompanyId) {
    return CompanyCloudState(
      localCompanyId: localCompanyId,
      cloudStatus: CompanyCloudStatus.localOnly,
    );
  }

  CompanyCloudState copyWith({
    String? localCompanyId,
    String? serverCompanyId,
    bool clearServerCompanyId = false,
    CompanyCloudStatus? cloudStatus,
    String? cloudProvisioningId,
    bool clearCloudProvisioningId = false,
    String? subscriptionId,
    bool clearSubscriptionId = false,
    String? planId,
    bool clearPlanId = false,
    DateTime? cloudLinkedAt,
    bool clearCloudLinkedAt = false,
    String? lastProvisioningError,
    bool clearLastProvisioningError = false,
  }) {
    return CompanyCloudState(
      localCompanyId: localCompanyId ?? this.localCompanyId,
      serverCompanyId: clearServerCompanyId
          ? null
          : (serverCompanyId ?? this.serverCompanyId),
      cloudStatus: cloudStatus ?? this.cloudStatus,
      cloudProvisioningId: clearCloudProvisioningId
          ? null
          : (cloudProvisioningId ?? this.cloudProvisioningId),
      subscriptionId: clearSubscriptionId
          ? null
          : (subscriptionId ?? this.subscriptionId),
      planId: clearPlanId ? null : (planId ?? this.planId),
      cloudLinkedAt:
          clearCloudLinkedAt ? null : (cloudLinkedAt ?? this.cloudLinkedAt),
      lastProvisioningError: clearLastProvisioningError
          ? null
          : (lastProvisioningError ?? this.lastProvisioningError),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'localCompanyId': localCompanyId,
      'serverCompanyId': serverCompanyId,
      'cloudStatus': cloudStatus.toDbString(),
      'cloudProvisioningId': cloudProvisioningId,
      'subscriptionId': subscriptionId,
      'planId': planId,
      'cloudLinkedAt': cloudLinkedAt?.toIso8601String(),
      'lastProvisioningError': lastProvisioningError,
    };
  }

  factory CompanyCloudState.fromMap(Map<dynamic, dynamic>? map, String fallbackLocalCompanyId) {
    if (map == null || map.isEmpty) {
      return CompanyCloudState.localDefault(fallbackLocalCompanyId);
    }
    final statusStr = map['cloudStatus'] as String?;
    final linkedAtStr = map['cloudLinkedAt'] as String?;
    return CompanyCloudState(
      localCompanyId: (map['localCompanyId'] as String?) ?? fallbackLocalCompanyId,
      serverCompanyId: map['serverCompanyId'] as String?,
      cloudStatus: CompanyCloudStatus.fromString(statusStr),
      cloudProvisioningId: map['cloudProvisioningId'] as String?,
      subscriptionId: map['subscriptionId'] as String?,
      planId: map['planId'] as String?,
      cloudLinkedAt: linkedAtStr != null ? DateTime.tryParse(linkedAtStr) : null,
      lastProvisioningError: map['lastProvisioningError'] as String?,
    );
  }
}
