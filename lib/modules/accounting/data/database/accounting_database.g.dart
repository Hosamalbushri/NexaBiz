// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accounting_database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts
    with TableInfo<$AccountsTable, AccountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountCodeMeta = const VerificationMeta(
    'accountCode',
  );
  @override
  late final GeneratedColumn<String> accountCode = GeneratedColumn<String>(
    'account_code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 32,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 512,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountTypeMeta = const VerificationMeta(
    'accountType',
  );
  @override
  late final GeneratedColumn<String> accountType = GeneratedColumn<String>(
    'account_type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 32,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalBalanceMeta = const VerificationMeta(
    'normalBalance',
  );
  @override
  late final GeneratedColumn<String> normalBalance = GeneratedColumn<String>(
    'normal_balance',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 16,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isGroupMeta = const VerificationMeta(
    'isGroup',
  );
  @override
  late final GeneratedColumn<bool> isGroup = GeneratedColumn<bool>(
    'is_group',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_group" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isSystemAccountMeta = const VerificationMeta(
    'isSystemAccount',
  );
  @override
  late final GeneratedColumn<bool> isSystemAccount = GeneratedColumn<bool>(
    'is_system_account',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_system_account" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<int> lastSyncedAt = GeneratedColumn<int>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    parentId,
    accountCode,
    name,
    description,
    accountType,
    normalBalance,
    level,
    isGroup,
    isActive,
    isSystemAccount,
    createdAt,
    updatedAt,
    syncStatus,
    lastSyncedAt,
    version,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('account_code')) {
      context.handle(
        _accountCodeMeta,
        accountCode.isAcceptableOrUnknown(
          data['account_code']!,
          _accountCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountCodeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('account_type')) {
      context.handle(
        _accountTypeMeta,
        accountType.isAcceptableOrUnknown(
          data['account_type']!,
          _accountTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountTypeMeta);
    }
    if (data.containsKey('normal_balance')) {
      context.handle(
        _normalBalanceMeta,
        normalBalance.isAcceptableOrUnknown(
          data['normal_balance']!,
          _normalBalanceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalBalanceMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    }
    if (data.containsKey('is_group')) {
      context.handle(
        _isGroupMeta,
        isGroup.isAcceptableOrUnknown(data['is_group']!, _isGroupMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('is_system_account')) {
      context.handle(
        _isSystemAccountMeta,
        isSystemAccount.isAcceptableOrUnknown(
          data['is_system_account']!,
          _isSystemAccountMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      accountCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      accountType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_type'],
      )!,
      normalBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normal_balance'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      isGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_group'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      isSystemAccount: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_system_account'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_synced_at'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class AccountRow extends DataClass implements Insertable<AccountRow> {
  final int id;

  /// Client-generated UUID for offline-safe identity / sync / future FKs.
  final String uuid;

  /// Parent account UUID; null for roots.
  final String? parentId;
  final String accountCode;
  final String name;
  final String? description;

  /// [AccountType.name]
  final String accountType;

  /// [NormalBalance.name]
  final String normalBalance;
  final int level;
  final bool isGroup;
  final bool isActive;
  final bool isSystemAccount;
  final int createdAt;
  final int updatedAt;

  /// [SyncStatus.name]
  final String syncStatus;
  final int? lastSyncedAt;
  final int version;

  /// Soft-delete tombstone (UTC epoch ms). Null = not deleted.
  final int? deletedAt;
  const AccountRow({
    required this.id,
    required this.uuid,
    this.parentId,
    required this.accountCode,
    required this.name,
    this.description,
    required this.accountType,
    required this.normalBalance,
    required this.level,
    required this.isGroup,
    required this.isActive,
    required this.isSystemAccount,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.lastSyncedAt,
    required this.version,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['account_code'] = Variable<String>(accountCode);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['account_type'] = Variable<String>(accountType);
    map['normal_balance'] = Variable<String>(normalBalance);
    map['level'] = Variable<int>(level);
    map['is_group'] = Variable<bool>(isGroup);
    map['is_active'] = Variable<bool>(isActive);
    map['is_system_account'] = Variable<bool>(isSystemAccount);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt);
    }
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      accountCode: Value(accountCode),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      accountType: Value(accountType),
      normalBalance: Value(normalBalance),
      level: Value(level),
      isGroup: Value(isGroup),
      isActive: Value(isActive),
      isSystemAccount: Value(isSystemAccount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory AccountRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      accountCode: serializer.fromJson<String>(json['accountCode']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      accountType: serializer.fromJson<String>(json['accountType']),
      normalBalance: serializer.fromJson<String>(json['normalBalance']),
      level: serializer.fromJson<int>(json['level']),
      isGroup: serializer.fromJson<bool>(json['isGroup']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      isSystemAccount: serializer.fromJson<bool>(json['isSystemAccount']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      lastSyncedAt: serializer.fromJson<int?>(json['lastSyncedAt']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'parentId': serializer.toJson<String?>(parentId),
      'accountCode': serializer.toJson<String>(accountCode),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'accountType': serializer.toJson<String>(accountType),
      'normalBalance': serializer.toJson<String>(normalBalance),
      'level': serializer.toJson<int>(level),
      'isGroup': serializer.toJson<bool>(isGroup),
      'isActive': serializer.toJson<bool>(isActive),
      'isSystemAccount': serializer.toJson<bool>(isSystemAccount),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'lastSyncedAt': serializer.toJson<int?>(lastSyncedAt),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  AccountRow copyWith({
    int? id,
    String? uuid,
    Value<String?> parentId = const Value.absent(),
    String? accountCode,
    String? name,
    Value<String?> description = const Value.absent(),
    String? accountType,
    String? normalBalance,
    int? level,
    bool? isGroup,
    bool? isActive,
    bool? isSystemAccount,
    int? createdAt,
    int? updatedAt,
    String? syncStatus,
    Value<int?> lastSyncedAt = const Value.absent(),
    int? version,
    Value<int?> deletedAt = const Value.absent(),
  }) => AccountRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    parentId: parentId.present ? parentId.value : this.parentId,
    accountCode: accountCode ?? this.accountCode,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    accountType: accountType ?? this.accountType,
    normalBalance: normalBalance ?? this.normalBalance,
    level: level ?? this.level,
    isGroup: isGroup ?? this.isGroup,
    isActive: isActive ?? this.isActive,
    isSystemAccount: isSystemAccount ?? this.isSystemAccount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  AccountRow copyWithCompanion(AccountsCompanion data) {
    return AccountRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      accountCode: data.accountCode.present
          ? data.accountCode.value
          : this.accountCode,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      accountType: data.accountType.present
          ? data.accountType.value
          : this.accountType,
      normalBalance: data.normalBalance.present
          ? data.normalBalance.value
          : this.normalBalance,
      level: data.level.present ? data.level.value : this.level,
      isGroup: data.isGroup.present ? data.isGroup.value : this.isGroup,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      isSystemAccount: data.isSystemAccount.present
          ? data.isSystemAccount.value
          : this.isSystemAccount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('parentId: $parentId, ')
          ..write('accountCode: $accountCode, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('accountType: $accountType, ')
          ..write('normalBalance: $normalBalance, ')
          ..write('level: $level, ')
          ..write('isGroup: $isGroup, ')
          ..write('isActive: $isActive, ')
          ..write('isSystemAccount: $isSystemAccount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    parentId,
    accountCode,
    name,
    description,
    accountType,
    normalBalance,
    level,
    isGroup,
    isActive,
    isSystemAccount,
    createdAt,
    updatedAt,
    syncStatus,
    lastSyncedAt,
    version,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.parentId == this.parentId &&
          other.accountCode == this.accountCode &&
          other.name == this.name &&
          other.description == this.description &&
          other.accountType == this.accountType &&
          other.normalBalance == this.normalBalance &&
          other.level == this.level &&
          other.isGroup == this.isGroup &&
          other.isActive == this.isActive &&
          other.isSystemAccount == this.isSystemAccount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt);
}

class AccountsCompanion extends UpdateCompanion<AccountRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String?> parentId;
  final Value<String> accountCode;
  final Value<String> name;
  final Value<String?> description;
  final Value<String> accountType;
  final Value<String> normalBalance;
  final Value<int> level;
  final Value<bool> isGroup;
  final Value<bool> isActive;
  final Value<bool> isSystemAccount;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> syncStatus;
  final Value<int?> lastSyncedAt;
  final Value<int> version;
  final Value<int?> deletedAt;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.parentId = const Value.absent(),
    this.accountCode = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.accountType = const Value.absent(),
    this.normalBalance = const Value.absent(),
    this.level = const Value.absent(),
    this.isGroup = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isSystemAccount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    this.parentId = const Value.absent(),
    required String accountCode,
    required String name,
    this.description = const Value.absent(),
    required String accountType,
    required String normalBalance,
    this.level = const Value.absent(),
    this.isGroup = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isSystemAccount = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : uuid = Value(uuid),
       accountCode = Value(accountCode),
       name = Value(name),
       accountType = Value(accountType),
       normalBalance = Value(normalBalance),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AccountRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? parentId,
    Expression<String>? accountCode,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? accountType,
    Expression<String>? normalBalance,
    Expression<int>? level,
    Expression<bool>? isGroup,
    Expression<bool>? isActive,
    Expression<bool>? isSystemAccount,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? syncStatus,
    Expression<int>? lastSyncedAt,
    Expression<int>? version,
    Expression<int>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (parentId != null) 'parent_id': parentId,
      if (accountCode != null) 'account_code': accountCode,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (accountType != null) 'account_type': accountType,
      if (normalBalance != null) 'normal_balance': normalBalance,
      if (level != null) 'level': level,
      if (isGroup != null) 'is_group': isGroup,
      if (isActive != null) 'is_active': isActive,
      if (isSystemAccount != null) 'is_system_account': isSystemAccount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  AccountsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String?>? parentId,
    Value<String>? accountCode,
    Value<String>? name,
    Value<String?>? description,
    Value<String>? accountType,
    Value<String>? normalBalance,
    Value<int>? level,
    Value<bool>? isGroup,
    Value<bool>? isActive,
    Value<bool>? isSystemAccount,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? syncStatus,
    Value<int?>? lastSyncedAt,
    Value<int>? version,
    Value<int?>? deletedAt,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      parentId: parentId ?? this.parentId,
      accountCode: accountCode ?? this.accountCode,
      name: name ?? this.name,
      description: description ?? this.description,
      accountType: accountType ?? this.accountType,
      normalBalance: normalBalance ?? this.normalBalance,
      level: level ?? this.level,
      isGroup: isGroup ?? this.isGroup,
      isActive: isActive ?? this.isActive,
      isSystemAccount: isSystemAccount ?? this.isSystemAccount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (accountCode.present) {
      map['account_code'] = Variable<String>(accountCode.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (accountType.present) {
      map['account_type'] = Variable<String>(accountType.value);
    }
    if (normalBalance.present) {
      map['normal_balance'] = Variable<String>(normalBalance.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (isGroup.present) {
      map['is_group'] = Variable<bool>(isGroup.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (isSystemAccount.present) {
      map['is_system_account'] = Variable<bool>(isSystemAccount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('parentId: $parentId, ')
          ..write('accountCode: $accountCode, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('accountType: $accountType, ')
          ..write('normalBalance: $normalBalance, ')
          ..write('level: $level, ')
          ..write('isGroup: $isGroup, ')
          ..write('isActive: $isActive, ')
          ..write('isSystemAccount: $isSystemAccount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $CurrencyRatesTable extends CurrencyRates
    with TableInfo<$CurrencyRatesTable, CurrencyRateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CurrencyRatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 8,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _rateToBaseMeta = const VerificationMeta(
    'rateToBase',
  );
  @override
  late final GeneratedColumn<double> rateToBase = GeneratedColumn<double>(
    'rate_to_base',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    currencyCode,
    rateToBase,
    updatedAt,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'currency_rates';
  @override
  VerificationContext validateIntegrity(
    Insertable<CurrencyRateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('rate_to_base')) {
      context.handle(
        _rateToBaseMeta,
        rateToBase.isAcceptableOrUnknown(
          data['rate_to_base']!,
          _rateToBaseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rateToBaseMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CurrencyRateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CurrencyRateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      rateToBase: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rate_to_base'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $CurrencyRatesTable createAlias(String alias) {
    return $CurrencyRatesTable(attachedDatabase, alias);
  }
}

class CurrencyRateRow extends DataClass implements Insertable<CurrencyRateRow> {
  final int id;

  /// ISO-like currency code (e.g. `USD`). Unique.
  final String currencyCode;

  /// Units of **base** currency for 1 unit of [currencyCode].
  /// Example: base SAR, USD rate `3.75` means 1 USD = 3.75 SAR.
  final double rateToBase;
  final int updatedAt;
  final String? notes;
  const CurrencyRateRow({
    required this.id,
    required this.currencyCode,
    required this.rateToBase,
    required this.updatedAt,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['currency_code'] = Variable<String>(currencyCode);
    map['rate_to_base'] = Variable<double>(rateToBase);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  CurrencyRatesCompanion toCompanion(bool nullToAbsent) {
    return CurrencyRatesCompanion(
      id: Value(id),
      currencyCode: Value(currencyCode),
      rateToBase: Value(rateToBase),
      updatedAt: Value(updatedAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory CurrencyRateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CurrencyRateRow(
      id: serializer.fromJson<int>(json['id']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      rateToBase: serializer.fromJson<double>(json['rateToBase']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'rateToBase': serializer.toJson<double>(rateToBase),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  CurrencyRateRow copyWith({
    int? id,
    String? currencyCode,
    double? rateToBase,
    int? updatedAt,
    Value<String?> notes = const Value.absent(),
  }) => CurrencyRateRow(
    id: id ?? this.id,
    currencyCode: currencyCode ?? this.currencyCode,
    rateToBase: rateToBase ?? this.rateToBase,
    updatedAt: updatedAt ?? this.updatedAt,
    notes: notes.present ? notes.value : this.notes,
  );
  CurrencyRateRow copyWithCompanion(CurrencyRatesCompanion data) {
    return CurrencyRateRow(
      id: data.id.present ? data.id.value : this.id,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      rateToBase: data.rateToBase.present
          ? data.rateToBase.value
          : this.rateToBase,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CurrencyRateRow(')
          ..write('id: $id, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('rateToBase: $rateToBase, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, currencyCode, rateToBase, updatedAt, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CurrencyRateRow &&
          other.id == this.id &&
          other.currencyCode == this.currencyCode &&
          other.rateToBase == this.rateToBase &&
          other.updatedAt == this.updatedAt &&
          other.notes == this.notes);
}

class CurrencyRatesCompanion extends UpdateCompanion<CurrencyRateRow> {
  final Value<int> id;
  final Value<String> currencyCode;
  final Value<double> rateToBase;
  final Value<int> updatedAt;
  final Value<String?> notes;
  const CurrencyRatesCompanion({
    this.id = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.rateToBase = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.notes = const Value.absent(),
  });
  CurrencyRatesCompanion.insert({
    this.id = const Value.absent(),
    required String currencyCode,
    required double rateToBase,
    required int updatedAt,
    this.notes = const Value.absent(),
  }) : currencyCode = Value(currencyCode),
       rateToBase = Value(rateToBase),
       updatedAt = Value(updatedAt);
  static Insertable<CurrencyRateRow> custom({
    Expression<int>? id,
    Expression<String>? currencyCode,
    Expression<double>? rateToBase,
    Expression<int>? updatedAt,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (rateToBase != null) 'rate_to_base': rateToBase,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (notes != null) 'notes': notes,
    });
  }

  CurrencyRatesCompanion copyWith({
    Value<int>? id,
    Value<String>? currencyCode,
    Value<double>? rateToBase,
    Value<int>? updatedAt,
    Value<String?>? notes,
  }) {
    return CurrencyRatesCompanion(
      id: id ?? this.id,
      currencyCode: currencyCode ?? this.currencyCode,
      rateToBase: rateToBase ?? this.rateToBase,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (rateToBase.present) {
      map['rate_to_base'] = Variable<double>(rateToBase.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CurrencyRatesCompanion(')
          ..write('id: $id, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('rateToBase: $rateToBase, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $VoucherBooksTable extends VoucherBooks
    with TableInfo<$VoucherBooksTable, VoucherBookRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VoucherBooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookTypeMeta = const VerificationMeta(
    'bookType',
  );
  @override
  late final GeneratedColumn<String> bookType = GeneratedColumn<String>(
    'book_type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 32,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isGroupMeta = const VerificationMeta(
    'isGroup',
  );
  @override
  late final GeneratedColumn<bool> isGroup = GeneratedColumn<bool>(
    'is_group',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_group" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _nextNumberMeta = const VerificationMeta(
    'nextNumber',
  );
  @override
  late final GeneratedColumn<int> nextNumber = GeneratedColumn<int>(
    'next_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _endNumberMeta = const VerificationMeta(
    'endNumber',
  );
  @override
  late final GeneratedColumn<int> endNumber = GeneratedColumn<int>(
    'end_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(9999),
  );
  static const VerificationMeta _padLengthMeta = const VerificationMeta(
    'padLength',
  );
  @override
  late final GeneratedColumn<int> padLength = GeneratedColumn<int>(
    'pad_length',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(4),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    parentId,
    name,
    bookType,
    isGroup,
    nextNumber,
    endNumber,
    padLength,
    isActive,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'voucher_books';
  @override
  VerificationContext validateIntegrity(
    Insertable<VoucherBookRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('book_type')) {
      context.handle(
        _bookTypeMeta,
        bookType.isAcceptableOrUnknown(data['book_type']!, _bookTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_bookTypeMeta);
    }
    if (data.containsKey('is_group')) {
      context.handle(
        _isGroupMeta,
        isGroup.isAcceptableOrUnknown(data['is_group']!, _isGroupMeta),
      );
    }
    if (data.containsKey('next_number')) {
      context.handle(
        _nextNumberMeta,
        nextNumber.isAcceptableOrUnknown(data['next_number']!, _nextNumberMeta),
      );
    }
    if (data.containsKey('end_number')) {
      context.handle(
        _endNumberMeta,
        endNumber.isAcceptableOrUnknown(data['end_number']!, _endNumberMeta),
      );
    }
    if (data.containsKey('pad_length')) {
      context.handle(
        _padLengthMeta,
        padLength.isAcceptableOrUnknown(data['pad_length']!, _padLengthMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VoucherBookRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VoucherBookRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      bookType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_type'],
      )!,
      isGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_group'],
      )!,
      nextNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_number'],
      )!,
      endNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_number'],
      )!,
      padLength: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pad_length'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $VoucherBooksTable createAlias(String alias) {
    return $VoucherBooksTable(attachedDatabase, alias);
  }
}

class VoucherBookRow extends DataClass implements Insertable<VoucherBookRow> {
  final int id;
  final String uuid;

  /// Parent group uuid; null for section roots.
  final String? parentId;
  final String name;

  /// Storage key — section or leaf kind (see [VoucherBookType]).
  final String bookType;

  /// Section folder (no numbering) vs leaf numbering book.
  final bool isGroup;

  /// Current number in the book (next value to allocate). Stored as `next_number`.
  final int nextNumber;

  /// Last number available in this book (≥ current).
  final int endNumber;

  /// Legacy unused column (older installs); ignored by the app.
  final int padLength;
  final bool isActive;
  final String? notes;
  final int createdAt;
  final int updatedAt;
  const VoucherBookRow({
    required this.id,
    required this.uuid,
    this.parentId,
    required this.name,
    required this.bookType,
    required this.isGroup,
    required this.nextNumber,
    required this.endNumber,
    required this.padLength,
    required this.isActive,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['name'] = Variable<String>(name);
    map['book_type'] = Variable<String>(bookType);
    map['is_group'] = Variable<bool>(isGroup);
    map['next_number'] = Variable<int>(nextNumber);
    map['end_number'] = Variable<int>(endNumber);
    map['pad_length'] = Variable<int>(padLength);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  VoucherBooksCompanion toCompanion(bool nullToAbsent) {
    return VoucherBooksCompanion(
      id: Value(id),
      uuid: Value(uuid),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      name: Value(name),
      bookType: Value(bookType),
      isGroup: Value(isGroup),
      nextNumber: Value(nextNumber),
      endNumber: Value(endNumber),
      padLength: Value(padLength),
      isActive: Value(isActive),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory VoucherBookRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VoucherBookRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      name: serializer.fromJson<String>(json['name']),
      bookType: serializer.fromJson<String>(json['bookType']),
      isGroup: serializer.fromJson<bool>(json['isGroup']),
      nextNumber: serializer.fromJson<int>(json['nextNumber']),
      endNumber: serializer.fromJson<int>(json['endNumber']),
      padLength: serializer.fromJson<int>(json['padLength']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'parentId': serializer.toJson<String?>(parentId),
      'name': serializer.toJson<String>(name),
      'bookType': serializer.toJson<String>(bookType),
      'isGroup': serializer.toJson<bool>(isGroup),
      'nextNumber': serializer.toJson<int>(nextNumber),
      'endNumber': serializer.toJson<int>(endNumber),
      'padLength': serializer.toJson<int>(padLength),
      'isActive': serializer.toJson<bool>(isActive),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  VoucherBookRow copyWith({
    int? id,
    String? uuid,
    Value<String?> parentId = const Value.absent(),
    String? name,
    String? bookType,
    bool? isGroup,
    int? nextNumber,
    int? endNumber,
    int? padLength,
    bool? isActive,
    Value<String?> notes = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => VoucherBookRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    parentId: parentId.present ? parentId.value : this.parentId,
    name: name ?? this.name,
    bookType: bookType ?? this.bookType,
    isGroup: isGroup ?? this.isGroup,
    nextNumber: nextNumber ?? this.nextNumber,
    endNumber: endNumber ?? this.endNumber,
    padLength: padLength ?? this.padLength,
    isActive: isActive ?? this.isActive,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  VoucherBookRow copyWithCompanion(VoucherBooksCompanion data) {
    return VoucherBookRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      name: data.name.present ? data.name.value : this.name,
      bookType: data.bookType.present ? data.bookType.value : this.bookType,
      isGroup: data.isGroup.present ? data.isGroup.value : this.isGroup,
      nextNumber: data.nextNumber.present
          ? data.nextNumber.value
          : this.nextNumber,
      endNumber: data.endNumber.present ? data.endNumber.value : this.endNumber,
      padLength: data.padLength.present ? data.padLength.value : this.padLength,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VoucherBookRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('bookType: $bookType, ')
          ..write('isGroup: $isGroup, ')
          ..write('nextNumber: $nextNumber, ')
          ..write('endNumber: $endNumber, ')
          ..write('padLength: $padLength, ')
          ..write('isActive: $isActive, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    parentId,
    name,
    bookType,
    isGroup,
    nextNumber,
    endNumber,
    padLength,
    isActive,
    notes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VoucherBookRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.parentId == this.parentId &&
          other.name == this.name &&
          other.bookType == this.bookType &&
          other.isGroup == this.isGroup &&
          other.nextNumber == this.nextNumber &&
          other.endNumber == this.endNumber &&
          other.padLength == this.padLength &&
          other.isActive == this.isActive &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class VoucherBooksCompanion extends UpdateCompanion<VoucherBookRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String?> parentId;
  final Value<String> name;
  final Value<String> bookType;
  final Value<bool> isGroup;
  final Value<int> nextNumber;
  final Value<int> endNumber;
  final Value<int> padLength;
  final Value<bool> isActive;
  final Value<String?> notes;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const VoucherBooksCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.parentId = const Value.absent(),
    this.name = const Value.absent(),
    this.bookType = const Value.absent(),
    this.isGroup = const Value.absent(),
    this.nextNumber = const Value.absent(),
    this.endNumber = const Value.absent(),
    this.padLength = const Value.absent(),
    this.isActive = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  VoucherBooksCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    this.parentId = const Value.absent(),
    required String name,
    required String bookType,
    this.isGroup = const Value.absent(),
    this.nextNumber = const Value.absent(),
    this.endNumber = const Value.absent(),
    this.padLength = const Value.absent(),
    this.isActive = const Value.absent(),
    this.notes = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : uuid = Value(uuid),
       name = Value(name),
       bookType = Value(bookType),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<VoucherBookRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? parentId,
    Expression<String>? name,
    Expression<String>? bookType,
    Expression<bool>? isGroup,
    Expression<int>? nextNumber,
    Expression<int>? endNumber,
    Expression<int>? padLength,
    Expression<bool>? isActive,
    Expression<String>? notes,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (parentId != null) 'parent_id': parentId,
      if (name != null) 'name': name,
      if (bookType != null) 'book_type': bookType,
      if (isGroup != null) 'is_group': isGroup,
      if (nextNumber != null) 'next_number': nextNumber,
      if (endNumber != null) 'end_number': endNumber,
      if (padLength != null) 'pad_length': padLength,
      if (isActive != null) 'is_active': isActive,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  VoucherBooksCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String?>? parentId,
    Value<String>? name,
    Value<String>? bookType,
    Value<bool>? isGroup,
    Value<int>? nextNumber,
    Value<int>? endNumber,
    Value<int>? padLength,
    Value<bool>? isActive,
    Value<String?>? notes,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return VoucherBooksCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      bookType: bookType ?? this.bookType,
      isGroup: isGroup ?? this.isGroup,
      nextNumber: nextNumber ?? this.nextNumber,
      endNumber: endNumber ?? this.endNumber,
      padLength: padLength ?? this.padLength,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (bookType.present) {
      map['book_type'] = Variable<String>(bookType.value);
    }
    if (isGroup.present) {
      map['is_group'] = Variable<bool>(isGroup.value);
    }
    if (nextNumber.present) {
      map['next_number'] = Variable<int>(nextNumber.value);
    }
    if (endNumber.present) {
      map['end_number'] = Variable<int>(endNumber.value);
    }
    if (padLength.present) {
      map['pad_length'] = Variable<int>(padLength.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VoucherBooksCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('bookType: $bookType, ')
          ..write('isGroup: $isGroup, ')
          ..write('nextNumber: $nextNumber, ')
          ..write('endNumber: $endNumber, ')
          ..write('padLength: $padLength, ')
          ..write('isActive: $isActive, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AccountingDatabase extends GeneratedDatabase {
  _$AccountingDatabase(QueryExecutor e) : super(e);
  $AccountingDatabaseManager get managers => $AccountingDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $CurrencyRatesTable currencyRates = $CurrencyRatesTable(this);
  late final $VoucherBooksTable voucherBooks = $VoucherBooksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accounts,
    currencyRates,
    voucherBooks,
  ];
}

typedef $$AccountsTableCreateCompanionBuilder =
    AccountsCompanion Function({
      Value<int> id,
      required String uuid,
      Value<String?> parentId,
      required String accountCode,
      required String name,
      Value<String?> description,
      required String accountType,
      required String normalBalance,
      Value<int> level,
      Value<bool> isGroup,
      Value<bool> isActive,
      Value<bool> isSystemAccount,
      required int createdAt,
      required int updatedAt,
      Value<String> syncStatus,
      Value<int?> lastSyncedAt,
      Value<int> version,
      Value<int?> deletedAt,
    });
typedef $$AccountsTableUpdateCompanionBuilder =
    AccountsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String?> parentId,
      Value<String> accountCode,
      Value<String> name,
      Value<String?> description,
      Value<String> accountType,
      Value<String> normalBalance,
      Value<int> level,
      Value<bool> isGroup,
      Value<bool> isActive,
      Value<bool> isSystemAccount,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<String> syncStatus,
      Value<int?> lastSyncedAt,
      Value<int> version,
      Value<int?> deletedAt,
    });

class $$AccountsTableFilterComposer
    extends Composer<_$AccountingDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountCode => $composableBuilder(
    column: $table.accountCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalBalance => $composableBuilder(
    column: $table.normalBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isGroup => $composableBuilder(
    column: $table.isGroup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSystemAccount => $composableBuilder(
    column: $table.isSystemAccount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AccountingDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountCode => $composableBuilder(
    column: $table.accountCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalBalance => $composableBuilder(
    column: $table.normalBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isGroup => $composableBuilder(
    column: $table.isGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSystemAccount => $composableBuilder(
    column: $table.isSystemAccount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AccountingDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get accountCode => $composableBuilder(
    column: $table.accountCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get normalBalance => $composableBuilder(
    column: $table.normalBalance,
    builder: (column) => column,
  );

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<bool> get isGroup =>
      $composableBuilder(column: $table.isGroup, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<bool> get isSystemAccount => $composableBuilder(
    column: $table.isSystemAccount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AccountingDatabase,
          $AccountsTable,
          AccountRow,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (
            AccountRow,
            BaseReferences<_$AccountingDatabase, $AccountsTable, AccountRow>,
          ),
          AccountRow,
          PrefetchHooks Function()
        > {
  $$AccountsTableTableManager(_$AccountingDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String> accountCode = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> accountType = const Value.absent(),
                Value<String> normalBalance = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<bool> isGroup = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<bool> isSystemAccount = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                uuid: uuid,
                parentId: parentId,
                accountCode: accountCode,
                name: name,
                description: description,
                accountType: accountType,
                normalBalance: normalBalance,
                level: level,
                isGroup: isGroup,
                isActive: isActive,
                isSystemAccount: isSystemAccount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                version: version,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                Value<String?> parentId = const Value.absent(),
                required String accountCode,
                required String name,
                Value<String?> description = const Value.absent(),
                required String accountType,
                required String normalBalance,
                Value<int> level = const Value.absent(),
                Value<bool> isGroup = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<bool> isSystemAccount = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<String> syncStatus = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                uuid: uuid,
                parentId: parentId,
                accountCode: accountCode,
                name: name,
                description: description,
                accountType: accountType,
                normalBalance: normalBalance,
                level: level,
                isGroup: isGroup,
                isActive: isActive,
                isSystemAccount: isSystemAccount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                version: version,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AccountingDatabase,
      $AccountsTable,
      AccountRow,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (
        AccountRow,
        BaseReferences<_$AccountingDatabase, $AccountsTable, AccountRow>,
      ),
      AccountRow,
      PrefetchHooks Function()
    >;
typedef $$CurrencyRatesTableCreateCompanionBuilder =
    CurrencyRatesCompanion Function({
      Value<int> id,
      required String currencyCode,
      required double rateToBase,
      required int updatedAt,
      Value<String?> notes,
    });
typedef $$CurrencyRatesTableUpdateCompanionBuilder =
    CurrencyRatesCompanion Function({
      Value<int> id,
      Value<String> currencyCode,
      Value<double> rateToBase,
      Value<int> updatedAt,
      Value<String?> notes,
    });

class $$CurrencyRatesTableFilterComposer
    extends Composer<_$AccountingDatabase, $CurrencyRatesTable> {
  $$CurrencyRatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rateToBase => $composableBuilder(
    column: $table.rateToBase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CurrencyRatesTableOrderingComposer
    extends Composer<_$AccountingDatabase, $CurrencyRatesTable> {
  $$CurrencyRatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rateToBase => $composableBuilder(
    column: $table.rateToBase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CurrencyRatesTableAnnotationComposer
    extends Composer<_$AccountingDatabase, $CurrencyRatesTable> {
  $$CurrencyRatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rateToBase => $composableBuilder(
    column: $table.rateToBase,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$CurrencyRatesTableTableManager
    extends
        RootTableManager<
          _$AccountingDatabase,
          $CurrencyRatesTable,
          CurrencyRateRow,
          $$CurrencyRatesTableFilterComposer,
          $$CurrencyRatesTableOrderingComposer,
          $$CurrencyRatesTableAnnotationComposer,
          $$CurrencyRatesTableCreateCompanionBuilder,
          $$CurrencyRatesTableUpdateCompanionBuilder,
          (
            CurrencyRateRow,
            BaseReferences<
              _$AccountingDatabase,
              $CurrencyRatesTable,
              CurrencyRateRow
            >,
          ),
          CurrencyRateRow,
          PrefetchHooks Function()
        > {
  $$CurrencyRatesTableTableManager(
    _$AccountingDatabase db,
    $CurrencyRatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CurrencyRatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CurrencyRatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CurrencyRatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<double> rateToBase = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => CurrencyRatesCompanion(
                id: id,
                currencyCode: currencyCode,
                rateToBase: rateToBase,
                updatedAt: updatedAt,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String currencyCode,
                required double rateToBase,
                required int updatedAt,
                Value<String?> notes = const Value.absent(),
              }) => CurrencyRatesCompanion.insert(
                id: id,
                currencyCode: currencyCode,
                rateToBase: rateToBase,
                updatedAt: updatedAt,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CurrencyRatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AccountingDatabase,
      $CurrencyRatesTable,
      CurrencyRateRow,
      $$CurrencyRatesTableFilterComposer,
      $$CurrencyRatesTableOrderingComposer,
      $$CurrencyRatesTableAnnotationComposer,
      $$CurrencyRatesTableCreateCompanionBuilder,
      $$CurrencyRatesTableUpdateCompanionBuilder,
      (
        CurrencyRateRow,
        BaseReferences<
          _$AccountingDatabase,
          $CurrencyRatesTable,
          CurrencyRateRow
        >,
      ),
      CurrencyRateRow,
      PrefetchHooks Function()
    >;
typedef $$VoucherBooksTableCreateCompanionBuilder =
    VoucherBooksCompanion Function({
      Value<int> id,
      required String uuid,
      Value<String?> parentId,
      required String name,
      required String bookType,
      Value<bool> isGroup,
      Value<int> nextNumber,
      Value<int> endNumber,
      Value<int> padLength,
      Value<bool> isActive,
      Value<String?> notes,
      required int createdAt,
      required int updatedAt,
    });
typedef $$VoucherBooksTableUpdateCompanionBuilder =
    VoucherBooksCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String?> parentId,
      Value<String> name,
      Value<String> bookType,
      Value<bool> isGroup,
      Value<int> nextNumber,
      Value<int> endNumber,
      Value<int> padLength,
      Value<bool> isActive,
      Value<String?> notes,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

class $$VoucherBooksTableFilterComposer
    extends Composer<_$AccountingDatabase, $VoucherBooksTable> {
  $$VoucherBooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookType => $composableBuilder(
    column: $table.bookType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isGroup => $composableBuilder(
    column: $table.isGroup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextNumber => $composableBuilder(
    column: $table.nextNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endNumber => $composableBuilder(
    column: $table.endNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get padLength => $composableBuilder(
    column: $table.padLength,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VoucherBooksTableOrderingComposer
    extends Composer<_$AccountingDatabase, $VoucherBooksTable> {
  $$VoucherBooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookType => $composableBuilder(
    column: $table.bookType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isGroup => $composableBuilder(
    column: $table.isGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextNumber => $composableBuilder(
    column: $table.nextNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endNumber => $composableBuilder(
    column: $table.endNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get padLength => $composableBuilder(
    column: $table.padLength,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VoucherBooksTableAnnotationComposer
    extends Composer<_$AccountingDatabase, $VoucherBooksTable> {
  $$VoucherBooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get bookType =>
      $composableBuilder(column: $table.bookType, builder: (column) => column);

  GeneratedColumn<bool> get isGroup =>
      $composableBuilder(column: $table.isGroup, builder: (column) => column);

  GeneratedColumn<int> get nextNumber => $composableBuilder(
    column: $table.nextNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endNumber =>
      $composableBuilder(column: $table.endNumber, builder: (column) => column);

  GeneratedColumn<int> get padLength =>
      $composableBuilder(column: $table.padLength, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$VoucherBooksTableTableManager
    extends
        RootTableManager<
          _$AccountingDatabase,
          $VoucherBooksTable,
          VoucherBookRow,
          $$VoucherBooksTableFilterComposer,
          $$VoucherBooksTableOrderingComposer,
          $$VoucherBooksTableAnnotationComposer,
          $$VoucherBooksTableCreateCompanionBuilder,
          $$VoucherBooksTableUpdateCompanionBuilder,
          (
            VoucherBookRow,
            BaseReferences<
              _$AccountingDatabase,
              $VoucherBooksTable,
              VoucherBookRow
            >,
          ),
          VoucherBookRow,
          PrefetchHooks Function()
        > {
  $$VoucherBooksTableTableManager(
    _$AccountingDatabase db,
    $VoucherBooksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VoucherBooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VoucherBooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VoucherBooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> bookType = const Value.absent(),
                Value<bool> isGroup = const Value.absent(),
                Value<int> nextNumber = const Value.absent(),
                Value<int> endNumber = const Value.absent(),
                Value<int> padLength = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => VoucherBooksCompanion(
                id: id,
                uuid: uuid,
                parentId: parentId,
                name: name,
                bookType: bookType,
                isGroup: isGroup,
                nextNumber: nextNumber,
                endNumber: endNumber,
                padLength: padLength,
                isActive: isActive,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                Value<String?> parentId = const Value.absent(),
                required String name,
                required String bookType,
                Value<bool> isGroup = const Value.absent(),
                Value<int> nextNumber = const Value.absent(),
                Value<int> endNumber = const Value.absent(),
                Value<int> padLength = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => VoucherBooksCompanion.insert(
                id: id,
                uuid: uuid,
                parentId: parentId,
                name: name,
                bookType: bookType,
                isGroup: isGroup,
                nextNumber: nextNumber,
                endNumber: endNumber,
                padLength: padLength,
                isActive: isActive,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VoucherBooksTableProcessedTableManager =
    ProcessedTableManager<
      _$AccountingDatabase,
      $VoucherBooksTable,
      VoucherBookRow,
      $$VoucherBooksTableFilterComposer,
      $$VoucherBooksTableOrderingComposer,
      $$VoucherBooksTableAnnotationComposer,
      $$VoucherBooksTableCreateCompanionBuilder,
      $$VoucherBooksTableUpdateCompanionBuilder,
      (
        VoucherBookRow,
        BaseReferences<
          _$AccountingDatabase,
          $VoucherBooksTable,
          VoucherBookRow
        >,
      ),
      VoucherBookRow,
      PrefetchHooks Function()
    >;

class $AccountingDatabaseManager {
  final _$AccountingDatabase _db;
  $AccountingDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$CurrencyRatesTableTableManager get currencyRates =>
      $$CurrencyRatesTableTableManager(_db, _db.currencyRates);
  $$VoucherBooksTableTableManager get voucherBooks =>
      $$VoucherBooksTableTableManager(_db, _db.voucherBooks);
}
