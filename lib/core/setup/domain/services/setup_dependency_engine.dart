import '../entities/package_setup_definition.dart';
import '../entities/setup_dependency.dart';
import '../entities/setup_dependency_exceptions.dart';
import '../entities/setup_status.dart';
import 'central_setup_registry.dart';

/// Result object describing dependency status evaluation for a package.
class SetupDependencyStatusResult {
  const SetupDependencyStatusResult({
    required this.isSatisfied,
    required this.missingDependencies,
    required this.unconfiguredDependencies,
  });

  /// True if all required dependencies are registered and fully configured.
  final bool isSatisfied;

  /// List of target package IDs that are required but missing from registry.
  final List<String> missingDependencies;

  /// List of target package IDs that are registered but not yet fully configured.
  final List<String> unconfiguredDependencies;
}

/// Domain engine responsible for resolving setup dependency ordering,
/// detecting circular dependency graphs, and validating prerequisite dependencies.
class SetupDependencyEngine {
  const SetupDependencyEngine();

  /// Validates that all declared required dependencies in [registry] exist.
  ///
  /// Throws [MissingSetupDependencyException] if a target package is not registered.
  void validateDependencies(CentralSetupRegistry registry) {
    final allDefinitions = registry.getAll();
    final registeredIds = {for (final d in allDefinitions) d.packageId};

    for (final def in allDefinitions) {
      for (final dep in def.dependencies) {
        if (dep.dependencyType == SetupDependencyType.required) {
          if (!registeredIds.contains(dep.targetPackageId)) {
            throw MissingSetupDependencyException(
              packageId: def.packageId,
              targetPackageId: dep.targetPackageId,
              reason: dep.reasonEn,
            );
          }
        }
      }
    }
  }

  /// Detects circular setup dependencies among [definitions].
  ///
  /// Throws [CircularSetupDependencyException] with the cycle path if a loop is found.
  void detectCycles(List<PackageSetupDefinition> definitions) {
    final graph = <String, Set<String>>{};
    final defMap = <String, PackageSetupDefinition>{};

    for (final def in definitions) {
      defMap[def.packageId] = def;
      graph[def.packageId] = {};
    }

    for (final def in definitions) {
      for (final dep in def.dependencies) {
        if (dep.dependencyType == SetupDependencyType.required) {
          // If target is registered in the list, add directed edge: dependent -> target
          if (graph.containsKey(dep.targetPackageId)) {
            graph[def.packageId]!.add(dep.targetPackageId);
          }
        }
      }
    }

    // DFS Cycle Detection (0 = unvisited, 1 = visiting, 2 = visited)
    final state = <String, int>{for (final id in graph.keys) id: 0};
    final pathStack = <String>[];

    void dfs(String node) {
      state[node] = 1;
      pathStack.add(node);

      final neighbors = graph[node] ?? {};
      for (final neighbor in neighbors) {
        if (state[neighbor] == 1) {
          // Cycle found! Extract cycle path from stack
          final cycleStart = pathStack.indexOf(neighbor);
          final cyclePath = [...pathStack.sublist(cycleStart), neighbor];
          throw CircularSetupDependencyException(cyclePath);
        } else if (state[neighbor] == 0) {
          dfs(neighbor);
        }
      }

      pathStack.removeLast();
      state[node] = 2;
    }

    for (final node in graph.keys) {
      if (state[node] == 0) {
        dfs(node);
      }
    }
  }

  /// Computes a deterministic topological sort execution order for [definitions].
  ///
  /// Prerequisite packages appear before dependent packages in the returned list.
  /// Secondary sorting respects [PackageSetupDefinition.sortOrder] ascending.
  /// Throws [CircularSetupDependencyException] if a circular dependency is detected.
  List<PackageSetupDefinition> getExecutionOrder(List<PackageSetupDefinition> definitions) {
    if (definitions.isEmpty) return const [];

    // Ensure graph has no cycles
    detectCycles(definitions);

    final defMap = {for (final d in definitions) d.packageId: d};

    // Graph mapping: targetPrerequisite -> Set<dependentPackageIds>
    final inDegree = <String, int>{for (final d in definitions) d.packageId: 0};
    final dependents = <String, Set<String>>{for (final d in definitions) d.packageId: {}};

    for (final def in definitions) {
      for (final dep in def.dependencies) {
        if (dep.dependencyType == SetupDependencyType.required && defMap.containsKey(dep.targetPackageId)) {
          dependents[dep.targetPackageId]!.add(def.packageId);
          inDegree[def.packageId] = (inDegree[def.packageId] ?? 0) + 1;
        }
      }
    }

    // Kahn's algorithm with priority queue (sortOrder ascending, then packageId)
    final available = definitions.where((d) => inDegree[d.packageId] == 0).toList();

    void sortAvailable() {
      available.sort((a, b) {
        final orderCompare = a.sortOrder.compareTo(b.sortOrder);
        if (orderCompare != 0) return orderCompare;
        return a.packageId.compareTo(b.packageId);
      });
    }

    sortAvailable();

    final result = <PackageSetupDefinition>[];

    while (available.isNotEmpty) {
      final current = available.removeAt(0);
      result.add(current);

      final nextDependents = dependents[current.packageId] ?? {};
      for (final depId in nextDependents) {
        inDegree[depId] = (inDegree[depId] ?? 1) - 1;
        if (inDegree[depId] == 0 && defMap.containsKey(depId)) {
          available.add(defMap[depId]!);
        }
      }
      sortAvailable();
    }

    if (result.length != definitions.length) {
      // Fallback in case of unmatched nodes
      final missing = definitions.where((d) => !result.contains(d));
      result.addAll(missing);
    }

    return List.unmodifiable(result);
  }

  /// Evaluates whether all required setup dependencies for [packageDef] are satisfied.
  SetupDependencyStatusResult checkDependencyStatus(
    PackageSetupDefinition packageDef,
    CentralSetupRegistry registry,
    Map<String, SetupStatus> packageStatuses,
  ) {
    final missing = <String>[];
    final unconfigured = <String>[];

    for (final dep in packageDef.dependencies) {
      if (dep.dependencyType == SetupDependencyType.required) {
        if (!registry.isRegistered(dep.targetPackageId)) {
          missing.add(dep.targetPackageId);
        } else {
          final targetStatus = packageStatuses[dep.targetPackageId] ?? SetupStatus.notConfigured;
          if (targetStatus != SetupStatus.configured) {
            unconfigured.add(dep.targetPackageId);
          }
        }
      }
    }

    final isSatisfied = missing.isEmpty && unconfigured.isEmpty;

    return SetupDependencyStatusResult(
      isSatisfied: isSatisfied,
      missingDependencies: missing,
      unconfiguredDependencies: unconfigured,
    );
  }
}
