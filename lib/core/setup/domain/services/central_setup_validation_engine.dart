// ignore_for_file: prefer_initializing_formals

import 'package:stock_count/core/domain/ports/setup_account_lookup_port.dart';
import '../entities/account_binding_status.dart';
import '../entities/account_requirement.dart';
import '../entities/package_setup_definition.dart';
import '../entities/setup_field.dart';
import '../entities/setup_status.dart';
import '../repositories/account_binding_repository.dart';
import 'account_binding_resolver.dart';
import 'central_setup_registry.dart';
import 'setup_dependency_engine.dart';

/// Comprehensive setup evaluation engine that validates package field values,
/// account bindings, tenant company scoping, and prerequisite package setup states.
class CentralSetupValidationEngine {
  const CentralSetupValidationEngine({
    required SetupAccountLookupPort accountLookupPort,
    required AccountBindingRepository bindingRepository,
    SetupDependencyEngine? dependencyEngine,
  })  : _accountLookupPort = accountLookupPort,
        _bindingRepository = bindingRepository,
        _dependencyEngine = dependencyEngine ?? const SetupDependencyEngine();

  final SetupAccountLookupPort _accountLookupPort;
  final AccountBindingRepository _bindingRepository;
  final SetupDependencyEngine _dependencyEngine;

  /// Evaluates the complete [SetupStatus] for [packageDef] under active tenant [companyId].
  ///
  /// Guarantees:
  /// - Package Loading is NEVER blocked by missing accounts or incomplete setup.
  /// - Cross-company account bindings evaluate as [SetupStatus.invalid].
  /// - Stale account bindings (deleted/deactivated accounts) evaluate as [SetupStatus.invalid] or [SetupStatus.partiallyConfigured].
  Future<SetupStatus> evaluatePackageStatus({
    required String companyId,
    required PackageSetupDefinition packageDef,
    required Map<String, dynamic> fieldValues,
    required CentralSetupRegistry registry,
    required Map<String, SetupStatus> allPackageStatuses,
    List<AccountRequirement> accountRequirements = const [],
  }) async {
    // 1. Evaluate Prerequisite Dependency Status
    final depResult = _dependencyEngine.checkDependencyStatus(
      packageDef,
      registry,
      allPackageStatuses,
    );

    if (!depResult.isSatisfied) {
      // Missing or unconfigured required dependencies cap maximum status at partiallyConfigured or notConfigured
      if (depResult.missingDependencies.isNotEmpty) {
        return SetupStatus.invalid;
      }
      return SetupStatus.partiallyConfigured;
    }

    int requiredCount = 0;
    int satisfiedCount = 0;
    bool hasInvalid = false;

    // 2. Evaluate Field Values
    for (final section in packageDef.sections) {
      for (final field in section.fields) {
        if (field.fieldType == SetupFieldType.reference) {
          // Handled via account binding requirements below
          continue;
        }

        if (field.isRequired) {
          requiredCount++;
          final val = fieldValues[field.key] ?? field.defaultValue;
          final isFieldValid = _validateFieldValue(field, val);

          if (isFieldValid) {
            satisfiedCount++;
          } else if (val != null) {
            hasInvalid = true;
          }
        }
      }
    }

    // 3. Evaluate Package Specific Domain Rules
    if (packageDef.packageId == 'inventory') {
      final costing = fieldValues['costing_method']?.toString() ?? 'FIFO';
      const validCostingMethods = {'FIFO', 'LIFO', 'AVERAGE', 'WEIGHTED_AVERAGE'};
      if (!validCostingMethods.contains(costing.toUpperCase())) {
        hasInvalid = true;
      }
    }

    // 4. Evaluate Account Requirements
    final resolver = AccountBindingResolver(
      accountLookupPort: _accountLookupPort,
      bindingRepository: _bindingRepository,
    );

    for (final req in accountRequirements) {
      if (req.packageId == packageDef.packageId) {
        if (req.isRequired) {
          requiredCount++;
        }

        final resolution = await resolver.resolveRequirement(
          companyId: companyId,
          requirement: req,
        );

        if (resolution.isBound) {
          if (req.isRequired) {
            satisfiedCount++;
          }
        } else if (resolution.status == AccountBindingStatus.invalidStale) {
          hasInvalid = true;
        }
      }
    }

    if (hasInvalid) {
      return SetupStatus.invalid;
    }

    if (requiredCount == 0) {
      return SetupStatus.configured;
    }

    if (satisfiedCount == requiredCount) {
      return SetupStatus.configured;
    }

    if (satisfiedCount > 0) {
      return SetupStatus.partiallyConfigured;
    }

    return SetupStatus.notConfigured;
  }

  bool _validateFieldValue(SetupField field, dynamic val) {
    if (val == null) return false;
    if (val is String && val.trim().isEmpty) return false;

    if (field.fieldType == SetupFieldType.number) {
      if (val is! num && num.tryParse(val.toString()) == null) {
        return false;
      }
    }

    if (field.fieldType == SetupFieldType.select && field.allowedValues != null) {
      final allowedStr = field.allowedValues!.map((e) => e.toString()).toSet();
      if (!allowedStr.contains(val.toString())) {
        return false;
      }
    }

    return true;
  }
}
