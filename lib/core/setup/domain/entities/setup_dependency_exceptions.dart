/// Exception thrown when a circular dependency chain is detected between setup packages.
class CircularSetupDependencyException implements Exception {
  const CircularSetupDependencyException(this.cyclePath);

  /// The sequence of package IDs involved in the circular dependency cycle.
  final List<String> cyclePath;

  @override
  String toString() {
    final pathStr = cyclePath.join(' -> ');
    return 'CircularSetupDependencyException: Circular setup dependency cycle detected: $pathStr';
  }
}

/// Exception thrown when a required setup dependency package is not registered.
class MissingSetupDependencyException implements Exception {
  const MissingSetupDependencyException({
    required this.packageId,
    required this.targetPackageId,
    this.reason,
  });

  final String packageId;
  final String targetPackageId;
  final String? reason;

  @override
  String toString() {
    final reasonStr = reason != null ? ' Reason: $reason' : '';
    return 'MissingSetupDependencyException: Package "$packageId" requires unregistered setup package "$targetPackageId".$reasonStr';
  }
}

/// Exception thrown when a financial or inventory transaction is blocked due to unconfigured setup.
class TransactionSetupConfigurationException implements Exception {
  const TransactionSetupConfigurationException({
    required this.packageId,
    required this.requirementKey,
    required this.message,
  });

  final String packageId;
  final String requirementKey;
  final String message;

  @override
  String toString() {
    return 'TransactionSetupConfigurationException [$packageId:$requirementKey]: $message';
  }
}
