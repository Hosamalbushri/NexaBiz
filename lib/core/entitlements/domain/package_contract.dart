import 'entities/entitlement.dart';

enum BuildFlavor {
  free,
  premium,
  enterprise,
}

abstract class PackageContract {
  String get code;
  String get name;
  String get category;
  String get description;
  double get price;
  String get currency;
  List<EntitlementCapability> get capabilities;
  List<String> get dependencies;
  String get requiredPlan;

  bool isIncludedInBuildTarget(BuildFlavor flavor);
}

class StandardPackageContract implements PackageContract {
  const StandardPackageContract({
    required this.code,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.currency,
    required this.capabilities,
    this.dependencies = const [],
    this.requiredPlan = 'starter',
    this.isAddonBuildOnly = true,
  });

  @override
  final String code;

  @override
  final String name;

  @override
  final String category;

  @override
  final String description;

  @override
  final double price;

  @override
  final String currency;

  @override
  final List<EntitlementCapability> capabilities;

  @override
  final List<String> dependencies;

  @override
  final String requiredPlan;

  final bool isAddonBuildOnly;

  @override
  bool isIncludedInBuildTarget(BuildFlavor flavor) {
    if (flavor == BuildFlavor.free && isAddonBuildOnly) {
      return false;
    }
    return true;
  }
}
