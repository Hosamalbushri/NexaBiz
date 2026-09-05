import 'package:stock_count/modules/sync/sync.dart';
import 'customer_data_source.dart';
import 'customer_status.dart';

export 'customer_status.dart';

/// Customer (business partner) master record.
///
/// [accountId] is an opaque Chart of Accounts identity (Account.uuid).
/// This module does not import Accounting — App wires resolution via
/// [CustomerAccountLinkPort].
class Customer {
  const Customer({
    required this.id,
    required this.uuid,
    required this.companyId,
    required this.customerCode,
    required this.name,
    required this.dataSource,
    required this.createdAt,
    required this.updatedAt,
    this.status = CustomerStatus.active,
    this.phone,
    this.email,
    this.address,
    this.notes,
    this.accountId,
    this.externalId,
    this.creditLimit,
    this.currencyCode,
    this.taxNumber,
    this.syncStatus = SyncStatus.synced,
    this.lastSyncedAt,
    this.version = 1,
    this.deletedAt,
  });

  final int id;

  /// Offline-safe identity used for sync and future FKs.
  final String uuid;

  /// Company / Tenant owner ID.
  final String companyId;

  /// Business code (e.g. `CUS-0001`). Not the database [id].
  final String customerCode;

  final String name;
  final CustomerStatus status;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;

  bool get isActive => status == CustomerStatus.active;
  bool get isBlocked => status == CustomerStatus.blocked;

  /// Opaque Account.uuid when linked to Chart of Accounts.
  ///
  /// When auto-link is enabled in settings, App creates a posting account under
  /// the customers parent group on save if this is null.
  final String? accountId;

  /// External ERP/accounting system id when [dataSource] is external.
  final String? externalId;

  final double? creditLimit;
  final String? currencyCode;
  final String? taxNumber;

  final CustomerDataSource dataSource;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final DateTime? lastSyncedAt;
  final int version;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  bool get isExternal => dataSource == CustomerDataSource.external;

  Customer copyWith({
    int? id,
    String? uuid,
    String? companyId,
    String? customerCode,
    String? name,
    CustomerStatus? status,
    String? phone,
    bool clearPhone = false,
    String? email,
    bool clearEmail = false,
    String? address,
    bool clearAddress = false,
    String? notes,
    bool clearNotes = false,
    String? accountId,
    bool clearAccountId = false,
    String? externalId,
    bool clearExternalId = false,
    double? creditLimit,
    bool clearCreditLimit = false,
    String? currencyCode,
    bool clearCurrencyCode = false,
    String? taxNumber,
    bool clearTaxNumber = false,
    CustomerDataSource? dataSource,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    DateTime? lastSyncedAt,
    bool clearLastSyncedAt = false,
    int? version,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Customer(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      companyId: companyId ?? this.companyId,
      customerCode: customerCode ?? this.customerCode,
      name: name ?? this.name,
      status: status ?? this.status,
      phone: clearPhone ? null : (phone ?? this.phone),
      email: clearEmail ? null : (email ?? this.email),
      address: clearAddress ? null : (address ?? this.address),
      notes: clearNotes ? null : (notes ?? this.notes),
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
      externalId: clearExternalId ? null : (externalId ?? this.externalId),
      creditLimit: clearCreditLimit ? null : (creditLimit ?? this.creditLimit),
      currencyCode:
          clearCurrencyCode ? null : (currencyCode ?? this.currencyCode),
      taxNumber: clearTaxNumber ? null : (taxNumber ?? this.taxNumber),
      dataSource: dataSource ?? this.dataSource,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: clearLastSyncedAt
          ? null
          : (lastSyncedAt ?? this.lastSyncedAt),
      version: version ?? this.version,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  CustomerDraft toDraft() => CustomerDraft(
        customerCode: customerCode,
        name: name,
        status: status,
        phone: phone,
        email: email,
        address: address,
        notes: notes,
        isActive: isActive,
        accountId: accountId,
        externalId: externalId,
        creditLimit: creditLimit,
        currencyCode: currencyCode,
        taxNumber: taxNumber,
        dataSource: dataSource,
      );
}


/// Payload for create / update (no id / timestamps required).
class CustomerDraft {
  const CustomerDraft({
    required this.customerCode,
    required this.name,
    this.status = CustomerStatus.active,
    this.phone,
    this.email,
    this.address,
    this.notes,
    this.isActive = true,
    this.accountId,
    this.externalId,
    this.creditLimit,
    this.currencyCode,
    this.taxNumber,
    this.dataSource = CustomerDataSource.local,
  });

  final String customerCode;
  final String name;
  final CustomerStatus status;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
  final bool isActive;
  final String? accountId;
  final String? externalId;
  final double? creditLimit;
  final String? currencyCode;
  final String? taxNumber;
  final CustomerDataSource dataSource;

  CustomerDraft copyWith({
    String? customerCode,
    String? name,
    CustomerStatus? status,
    String? phone,
    String? email,
    String? address,
    String? notes,
    bool? isActive,
    String? accountId,
    bool clearAccountId = false,
    String? externalId,
    double? creditLimit,
    bool clearCreditLimit = false,
    String? currencyCode,
    bool clearCurrencyCode = false,
    String? taxNumber,
    bool clearTaxNumber = false,
    CustomerDataSource? dataSource,
  }) {
    return CustomerDraft(
      customerCode: customerCode ?? this.customerCode,
      name: name ?? this.name,
      status: status ?? (isActive != null ? (isActive ? CustomerStatus.active : CustomerStatus.inactive) : this.status),
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      isActive: isActive ?? (status != null ? status == CustomerStatus.active : this.isActive),
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
      externalId: externalId ?? this.externalId,
      creditLimit: clearCreditLimit ? null : (creditLimit ?? this.creditLimit),
      currencyCode:
          clearCurrencyCode ? null : (currencyCode ?? this.currencyCode),
      taxNumber: clearTaxNumber ? null : (taxNumber ?? this.taxNumber),
      dataSource: dataSource ?? this.dataSource,
    );
  }
}

