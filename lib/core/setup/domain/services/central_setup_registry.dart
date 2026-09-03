import '../entities/package_setup_definition.dart';
import 'package_setup_definition_validator.dart';

/// Central registry for discovering, storing, and ordering package setup definitions.
///
/// Business packages register their setup definitions with this registry.
/// The registry enforces duplicate protection and valid setup structures without
/// containing any package-specific business rules.
class CentralSetupRegistry {
  CentralSetupRegistry({
    PackageSetupDefinitionValidator? validator,
  }) : _validator = validator ?? const PackageSetupDefinitionValidator();

  final PackageSetupDefinitionValidator _validator;
  final Map<String, PackageSetupDefinition> _registry = {};

  /// Registers a package setup definition.
  ///
  /// Throws [PackageSetupValidationException] if the definition is structurally
  /// invalid or if a setup for [definition.packageId] has already been registered.
  void register(PackageSetupDefinition definition) {
    _validator.validateDefinition(definition);

    final packageId = definition.packageId.trim();
    if (_registry.containsKey(packageId)) {
      throw PackageSetupValidationException(
        'Package setup definition for packageId "$packageId" is already registered.',
      );
    }

    _registry[packageId] = definition;
  }

  /// Retrieves a registered package setup definition by its [packageId].
  ///
  /// Returns `null` if no setup is registered for [packageId].
  PackageSetupDefinition? get(String packageId) {
    return _registry[packageId.trim()];
  }

  /// Alias for [get].
  PackageSetupDefinition? findByPackageId(String packageId) => get(packageId);

  /// Returns true if a setup definition is registered for [packageId].
  bool isRegistered(String packageId) {
    return _registry.containsKey(packageId.trim());
  }

  /// Returns an unmodifiable list of all registered package setup definitions,
  /// ordered deterministically by [PackageSetupDefinition.sortOrder] ascending.
  List<PackageSetupDefinition> getAll() {
    final list = _registry.values.toList(growable: false)
      ..sort((a, b) {
        final orderCompare = a.sortOrder.compareTo(b.sortOrder);
        if (orderCompare != 0) {
          return orderCompare;
        }
        return a.packageId.compareTo(b.packageId);
      });
    return List.unmodifiable(list);
  }

  /// Unregisters a package setup definition by its [packageId].
  ///
  /// Useful for dynamic package unmounting or testing.
  void unregister(String packageId) {
    _registry.remove(packageId.trim());
  }

  /// Clears all registered package setup definitions.
  void clear() {
    _registry.clear();
  }
}
