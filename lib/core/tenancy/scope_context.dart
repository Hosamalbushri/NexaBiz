import 'package:flutter/foundation.dart';

/// Immutable scope abstraction distinguishing operational tenancy boundaries.
@immutable
sealed class ScopeContext {
  const ScopeContext();

  /// Whether this scope represents system-level administration or global state.
  bool get isSystem => this is SystemScope;

  /// Whether this scope represents a specific company workspace.
  bool get isCompany => this is CompanyScope;

  /// Whether this scope represents shared reference / master reference data.
  bool get isGlobal => this is GlobalScope;

  /// Returns active company ID if [isCompany], otherwise null.
  String? get companyIdOrNull => switch (this) {
        CompanyScope(:final companyId) => companyId,
        _ => null,
      };
}

/// System-level scope (user accounts, system permissions, system setup).
final class SystemScope extends ScopeContext {
  const SystemScope();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SystemScope;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'ScopeContext.system';
}

/// Company-level scope strictly bound to [companyId].
final class CompanyScope extends ScopeContext {
  const CompanyScope(this.companyId)
      : assert(
          companyId.length > 0,
          'CompanyScope requires a non-empty companyId',
        );

  /// Unique company identifier.
  final String companyId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanyScope &&
          runtimeType == other.runtimeType &&
          companyId == other.companyId;

  @override
  int get hashCode => companyId.hashCode;

  @override
  String toString() => 'ScopeContext.company($companyId)';
}

/// Global / shared reference scope (e.g. system currency definitions).
final class GlobalScope extends ScopeContext {
  const GlobalScope();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is GlobalScope;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'ScopeContext.global';
}

/// Contextual scope dynamically resolved at execution time.
final class ContextualScope extends ScopeContext {
  const ContextualScope(this.name);

  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContextualScope &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'ScopeContext.contextual($name)';
}
