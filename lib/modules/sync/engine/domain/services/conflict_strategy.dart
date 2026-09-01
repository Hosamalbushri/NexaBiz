/// Conflict strategies for domain-aware synchronization.
enum ConflictStrategy {
  /// Reject incoming mutation if version mismatch occurs.
  reject,

  /// Server payload takes precedence over local changes.
  serverWins,

  /// Client payload takes precedence over server changes.
  clientWins,

  /// Field-level deterministic 3-way merge for non-overlapping fields.
  fieldMerge,

  /// Immutable append-only events (e.g. inventory movements).
  appendOnly,

  /// Domain-specific calculation/reconciliation (e.g. derived stock snapshot).
  domainReconcile,

  /// Immutable transaction protection (e.g. posted journal entries).
  immutableReject,
}

/// Defines domain rules for merging fields of a specific entity type.
class EntityConflictPolicy {
  const EntityConflictPolicy({
    required this.entityType,
    required this.strategy,
    this.mergeableFields = const {},
    this.domainSensitiveFields = const {},
    this.neverMergeFields = const {},
  });

  final String entityType;
  final ConflictStrategy strategy;
  final Set<String> mergeableFields;
  final Set<String> domainSensitiveFields;
  final Set<String> neverMergeFields;

  /// Default predefined policies for known domain entities.
  static final Map<String, EntityConflictPolicy> _policies = {
    'customer': const EntityConflictPolicy(
      entityType: 'customer',
      strategy: ConflictStrategy.fieldMerge,
      mergeableFields: {'name', 'phone', 'email', 'address', 'customerCode', 'isActive'},
      domainSensitiveFields: {'accountId', 'account_id'},
      neverMergeFields: {'balance', 'currentBalance', 'current_balance'},
    ),
    'supplier': const EntityConflictPolicy(
      entityType: 'supplier',
      strategy: ConflictStrategy.fieldMerge,
      mergeableFields: {'name', 'phone', 'email', 'address', 'supplierCode', 'isActive'},
      domainSensitiveFields: {'accountId', 'account_id'},
      neverMergeFields: {'balance', 'currentBalance', 'current_balance'},
    ),
    'product': const EntityConflictPolicy(
      entityType: 'product',
      strategy: ConflictStrategy.fieldMerge,
      mergeableFields: {'name', 'description', 'itemName', 'itemCode', 'packSize'},
      domainSensitiveFields: {'barcode', 'price', 'cost', 'unitCost'},
      neverMergeFields: {'stock', 'onHandQty', 'on_hand_qty', 'systemQuantity', 'actualQuantity'},
    ),
    'account': const EntityConflictPolicy(
      entityType: 'account',
      strategy: ConflictStrategy.fieldMerge,
      mergeableFields: {'name', 'description', 'accountCode'},
      domainSensitiveFields: {'parentId', 'parent_id', 'accountType', 'account_type'},
      neverMergeFields: {'balance', 'currentBalance', 'current_balance'},
    ),
    'company_profile': const EntityConflictPolicy(
      entityType: 'company_profile',
      strategy: ConflictStrategy.fieldMerge,
      mergeableFields: {'name', 'taxNumber', 'phone', 'email', 'address', 'logoUrl'},
      domainSensitiveFields: {'currencyCode', 'fiscalYearStart'},
    ),
    'currency_rate': const EntityConflictPolicy(
      entityType: 'currency_rate',
      strategy: ConflictStrategy.fieldMerge,
      mergeableFields: {'rate', 'inverseRate', 'updatedAt'},
    ),
    'fiscal_year': const EntityConflictPolicy(
      entityType: 'fiscal_year',
      strategy: ConflictStrategy.fieldMerge,
      mergeableFields: {'name', 'startDate', 'endDate'},
      domainSensitiveFields: {'isClosed', 'status'},
    ),
    'journal_entry': const EntityConflictPolicy(
      entityType: 'journal_entry',
      strategy: ConflictStrategy.immutableReject,
    ),
    'stock_receipt': const EntityConflictPolicy(
      entityType: 'stock_receipt',
      strategy: ConflictStrategy.immutableReject,
    ),
    'stock_issue': const EntityConflictPolicy(
      entityType: 'stock_issue',
      strategy: ConflictStrategy.immutableReject,
    ),
    'stock_transfer': const EntityConflictPolicy(
      entityType: 'stock_transfer',
      strategy: ConflictStrategy.immutableReject,
    ),
    'stock_return': const EntityConflictPolicy(
      entityType: 'stock_return',
      strategy: ConflictStrategy.immutableReject,
    ),
    'sales_invoice': const EntityConflictPolicy(
      entityType: 'sales_invoice',
      strategy: ConflictStrategy.immutableReject,
    ),
    'inventory_reversal': const EntityConflictPolicy(
      entityType: 'inventory_reversal',
      strategy: ConflictStrategy.immutableReject,
    ),
    'inventory_movement': const EntityConflictPolicy(
      entityType: 'inventory_movement',
      strategy: ConflictStrategy.appendOnly,
    ),
    'inventory_item': const EntityConflictPolicy(
      entityType: 'inventory_item',
      strategy: ConflictStrategy.domainReconcile,
    ),
  };

  static EntityConflictPolicy getForEntity(String entityType) {
    return _policies[entityType] ??
        EntityConflictPolicy(
          entityType: entityType,
          strategy: ConflictStrategy.fieldMerge,
        );
  }
}
