import 'entities/entitlement.dart';

class PackageDefinition {
  const PackageDefinition({
    required this.code,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.currency,
    required this.capabilities,
    this.dependencies = const [],
    this.requiredPlan = 'starter',
  });

  final String code;
  final String name;
  final String category;
  final String description;
  final double price;
  final String currency;
  final List<EntitlementCapability> capabilities;
  final List<String> dependencies;
  final String requiredPlan;
}

class PackageRegistry {
  const PackageRegistry._();

  static const List<PackageDefinition> allPackages = [
    PackageDefinition(
      code: 'cloud_sync',
      name: 'Cloud Data Synchronization',
      category: 'core',
      description: 'Real-time multi-device cloud synchronization and offline queue processing.',
      price: 29.0,
      currency: 'USD',
      capabilities: [EntitlementCapability.sync, EntitlementCapability.cloudBackup],
      dependencies: [],
      requiredPlan: 'starter',
    ),
    PackageDefinition(
      code: 'multi_device',
      name: 'Multi-Device Access',
      category: 'add_on',
      description: 'Connect multiple active terminal devices to your company catalog.',
      price: 15.0,
      currency: 'USD',
      capabilities: [EntitlementCapability.multiDevice],
      dependencies: ['cloud_sync'],
      requiredPlan: 'starter',
    ),
    PackageDefinition(
      code: 'multi_branch',
      name: 'Multi-Branch Management',
      category: 'add_on',
      description: 'Manage multiple physical branches and consolidated reports.',
      price: 49.0,
      currency: 'USD',
      capabilities: [EntitlementCapability.multiBranch],
      dependencies: ['cloud_sync'],
      requiredPlan: 'business',
    ),
  ];

  static PackageDefinition? findByCode(String code) {
    for (final pkg in allPackages) {
      if (pkg.code == code) return pkg;
    }
    return null;
  }
}
