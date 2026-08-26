import 'package:stock_count/modules/sync/sync.dart';
import 'account_type.dart';
import 'normal_balance.dart';

/// Chart of Accounts node — group or posting account.
///
/// Future journal lines will reference [uuid] (stable offline id), not [id].
class Account {
  const Account({
    required this.id,
    required this.uuid,
    required this.accountCode,
    required this.name,
    required this.accountType,
    required this.normalBalance,
    required this.level,
    required this.isGroup,
    required this.isActive,
    required this.isSystemAccount,
    required this.createdAt,
    required this.updatedAt,
    this.parentId,
    this.description,
    this.syncStatus = SyncStatus.synced,
    this.lastSyncedAt,
    this.version = 1,
    this.deletedAt,
  });

  final int id;

  /// Client-generated UUID for offline-safe identity / sync / future FKs.
  final String uuid;

  /// Parent account UUID; null for root accounts.
  final String? parentId;

  /// Human / accounting code (e.g. `1111`). Unique among non-deleted rows.
  final String accountCode;

  final String name;
  final String? description;
  final AccountType accountType;
  final NormalBalance normalBalance;

  /// Depth in the tree (roots = 0).
  final int level;

  /// When true, this is a group (header) account — not for journal posting.
  final bool isGroup;

  final bool isActive;
  final bool isSystemAccount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final DateTime? lastSyncedAt;
  final int version;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  /// Posting accounts may appear on journal entry lines (groups may not).
  bool get isPostingAccount => !isGroup;

  bool get canPost => isPostingAccount && isActive && !isDeleted;

  Account copyWith({
    int? id,
    String? uuid,
    String? parentId,
    bool clearParentId = false,
    String? accountCode,
    String? name,
    String? description,
    bool clearDescription = false,
    AccountType? accountType,
    NormalBalance? normalBalance,
    int? level,
    bool? isGroup,
    bool? isActive,
    bool? isSystemAccount,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    DateTime? lastSyncedAt,
    bool clearLastSyncedAt = false,
    int? version,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Account(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      parentId: clearParentId ? null : (parentId ?? this.parentId),
      accountCode: accountCode ?? this.accountCode,
      name: name ?? this.name,
      description: clearDescription
          ? null
          : (description ?? this.description),
      accountType: accountType ?? this.accountType,
      normalBalance: normalBalance ?? this.normalBalance,
      level: level ?? this.level,
      isGroup: isGroup ?? this.isGroup,
      isActive: isActive ?? this.isActive,
      isSystemAccount: isSystemAccount ?? this.isSystemAccount,
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
}

/// Create / update payload (no local id / timestamps required).
class AccountDraft {
  const AccountDraft({
    required this.accountCode,
    required this.name,
    required this.accountType,
    required this.isGroup,
    this.parentId,
    this.description,
    this.isActive = true,
    this.isSystemAccount = false,
  });

  final String? parentId;
  final String accountCode;
  final String name;
  final String? description;
  final AccountType accountType;
  final bool isGroup;
  final bool isActive;
  final bool isSystemAccount;

  NormalBalance get normalBalance => accountType.normalBalance;
}
