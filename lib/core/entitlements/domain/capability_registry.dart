import 'entities/entitlement.dart';
import 'package_registry.dart';

class CapabilityMetadata {
  const CapabilityMetadata({
    required this.capability,
    required this.displayName,
    required this.description,
    required this.requiredPackageCode,
    required this.requiredPermission,
    required this.iconName,
  });

  final EntitlementCapability capability;
  final String displayName;
  final String description;
  final String requiredPackageCode;
  final String requiredPermission;
  final String iconName;

  PackageDefinition? get requiredPackage => PackageRegistry.findByCode(requiredPackageCode);
}

class CapabilityRegistry {
  const CapabilityRegistry._();

  static const Map<EntitlementCapability, CapabilityMetadata> _registry = {
    EntitlementCapability.sync: CapabilityMetadata(
      capability: EntitlementCapability.sync,
      displayName: 'Cloud Data Synchronization',
      description: 'Synchronize your business data seamlessly across all your devices and branches.',
      requiredPackageCode: 'cloud_sync',
      requiredPermission: 'sync.execute',
      iconName: 'cloud_sync',
    ),
    EntitlementCapability.multiDevice: CapabilityMetadata(
      capability: EntitlementCapability.multiDevice,
      displayName: 'Multi-Device Access',
      description: 'Connect and synchronize multiple active terminal devices simultaneously.',
      requiredPackageCode: 'multi_device',
      requiredPermission: 'devices.manage',
      iconName: 'devices',
    ),
    EntitlementCapability.multiBranch: CapabilityMetadata(
      capability: EntitlementCapability.multiBranch,
      displayName: 'Multi-Branch Management',
      description: 'Manage inventory, transfers, and sales across multiple physical branch locations.',
      requiredPackageCode: 'multi_branch',
      requiredPermission: 'branches.view',
      iconName: 'store',
    ),
    EntitlementCapability.cloudBackup: CapabilityMetadata(
      capability: EntitlementCapability.cloudBackup,
      displayName: 'Automated Cloud Backup',
      description: 'Automatic encrypted cloud snapshot backups for complete business peace of mind.',
      requiredPackageCode: 'cloud_sync',
      requiredPermission: 'backup.execute',
      iconName: 'cloud_done',
    ),
  };

  static CapabilityMetadata? getMetadata(EntitlementCapability capability) {
    return _registry[capability];
  }
}
