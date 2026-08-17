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

class $CurrencyRateHistoryTable extends CurrencyRateHistory
    with TableInfo<$CurrencyRateHistoryTable, CurrencyRateHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CurrencyRateHistoryTable(this.attachedDatabase, [this._alias]);
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
  );
  static const VerificationMeta _asOfDateMeta = const VerificationMeta(
    'asOfDate',
  );
  @override
  late final GeneratedColumn<int> asOfDate = GeneratedColumn<int>(
    'as_of_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
    asOfDate,
    rateToBase,
    createdAt,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'currency_rate_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<CurrencyRateHistoryRow> instance, {
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
    if (data.containsKey('as_of_date')) {
      context.handle(
        _asOfDateMeta,
        asOfDate.isAcceptableOrUnknown(data['as_of_date']!, _asOfDateMeta),
      );
    } else if (isInserting) {
      context.missing(_asOfDateMeta);
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
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {currencyCode, asOfDate},
  ];
  @override
  CurrencyRateHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CurrencyRateHistoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      asOfDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}as_of_date'],
      )!,
      rateToBase: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rate_to_base'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $CurrencyRateHistoryTable createAlias(String alias) {
    return $CurrencyRateHistoryTable(attachedDatabase, alias);
  }
}

class CurrencyRateHistoryRow extends DataClass
    implements Insertable<CurrencyRateHistoryRow> {
  final int id;
  final String currencyCode;

  /// UTC midnight of the rate day (milliseconds since epoch).
  final int asOfDate;

  /// Units of base currency for 1 unit of [currencyCode].
  final double rateToBase;
  final int createdAt;
  final String? notes;
  const CurrencyRateHistoryRow({
    required this.id,
    required this.currencyCode,
    required this.asOfDate,
    required this.rateToBase,
    required this.createdAt,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['currency_code'] = Variable<String>(currencyCode);
    map['as_of_date'] = Variable<int>(asOfDate);
    map['rate_to_base'] = Variable<double>(rateToBase);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  CurrencyRateHistoryCompanion toCompanion(bool nullToAbsent) {
    return CurrencyRateHistoryCompanion(
      id: Value(id),
      currencyCode: Value(currencyCode),
      asOfDate: Value(asOfDate),
      rateToBase: Value(rateToBase),
      createdAt: Value(createdAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory CurrencyRateHistoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CurrencyRateHistoryRow(
      id: serializer.fromJson<int>(json['id']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      asOfDate: serializer.fromJson<int>(json['asOfDate']),
      rateToBase: serializer.fromJson<double>(json['rateToBase']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'asOfDate': serializer.toJson<int>(asOfDate),
      'rateToBase': serializer.toJson<double>(rateToBase),
      'createdAt': serializer.toJson<int>(createdAt),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  CurrencyRateHistoryRow copyWith({
    int? id,
    String? currencyCode,
    int? asOfDate,
    double? rateToBase,
    int? createdAt,
    Value<String?> notes = const Value.absent(),
  }) => CurrencyRateHistoryRow(
    id: id ?? this.id,
    currencyCode: currencyCode ?? this.currencyCode,
    asOfDate: asOfDate ?? this.asOfDate,
    rateToBase: rateToBase ?? this.rateToBase,
    createdAt: createdAt ?? this.createdAt,
    notes: notes.present ? notes.value : this.notes,
  );
  CurrencyRateHistoryRow copyWithCompanion(CurrencyRateHistoryCompanion data) {
    return CurrencyRateHistoryRow(
      id: data.id.present ? data.id.value : this.id,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      asOfDate: data.asOfDate.present ? data.asOfDate.value : this.asOfDate,
      rateToBase: data.rateToBase.present
          ? data.rateToBase.value
          : this.rateToBase,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CurrencyRateHistoryRow(')
          ..write('id: $id, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('asOfDate: $asOfDate, ')
          ..write('rateToBase: $rateToBase, ')
          ..write('createdAt: $createdAt, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, currencyCode, asOfDate, rateToBase, createdAt, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CurrencyRateHistoryRow &&
          other.id == this.id &&
          other.currencyCode == this.currencyCode &&
          other.asOfDate == this.asOfDate &&
          other.rateToBase == this.rateToBase &&
          other.createdAt == this.createdAt &&
          other.notes == this.notes);
}

class CurrencyRateHistoryCompanion
    extends UpdateCompanion<CurrencyRateHistoryRow> {
  final Value<int> id;
  final Value<String> currencyCode;
  final Value<int> asOfDate;
  final Value<double> rateToBase;
  final Value<int> createdAt;
  final Value<String?> notes;
  const CurrencyRateHistoryCompanion({
    this.id = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.asOfDate = const Value.absent(),
    this.rateToBase = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.notes = const Value.absent(),
  });
  CurrencyRateHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String currencyCode,
    required int asOfDate,
    required double rateToBase,
    required int createdAt,
    this.notes = const Value.absent(),
  }) : currencyCode = Value(currencyCode),
       asOfDate = Value(asOfDate),
       rateToBase = Value(rateToBase),
       createdAt = Value(createdAt);
  static Insertable<CurrencyRateHistoryRow> custom({
    Expression<int>? id,
    Expression<String>? currencyCode,
    Expression<int>? asOfDate,
    Expression<double>? rateToBase,
    Expression<int>? createdAt,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (asOfDate != null) 'as_of_date': asOfDate,
      if (rateToBase != null) 'rate_to_base': rateToBase,
      if (createdAt != null) 'created_at': createdAt,
      if (notes != null) 'notes': notes,
    });
  }

  CurrencyRateHistoryCompanion copyWith({
    Value<int>? id,
    Value<String>? currencyCode,
    Value<int>? asOfDate,
    Value<double>? rateToBase,
    Value<int>? createdAt,
    Value<String?>? notes,
  }) {
    return CurrencyRateHistoryCompanion(
      id: id ?? this.id,
      currencyCode: currencyCode ?? this.currencyCode,
      asOfDate: asOfDate ?? this.asOfDate,
      rateToBase: rateToBase ?? this.rateToBase,
      createdAt: createdAt ?? this.createdAt,
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
    if (asOfDate.present) {
      map['as_of_date'] = Variable<int>(asOfDate.value);
    }
    if (rateToBase.present) {
      map['rate_to_base'] = Variable<double>(rateToBase.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CurrencyRateHistoryCompanion(')
          ..write('id: $id, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('asOfDate: $asOfDate, ')
          ..write('rateToBase: $rateToBase, ')
          ..write('createdAt: $createdAt, ')
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

class $JournalEntriesTable extends JournalEntries
    with TableInfo<$JournalEntriesTable, JournalEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalEntriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _entryDateMeta = const VerificationMeta(
    'entryDate',
  );
  @override
  late final GeneratedColumn<int> entryDate = GeneratedColumn<int>(
    'entry_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _voucherNumberMeta = const VerificationMeta(
    'voucherNumber',
  );
  @override
  late final GeneratedColumn<String> voucherNumber = GeneratedColumn<String>(
    'voucher_number',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _voucherTypeMeta = const VerificationMeta(
    'voucherType',
  );
  @override
  late final GeneratedColumn<String> voucherType = GeneratedColumn<String>(
    'voucher_type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
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
  );
  static const VerificationMeta _isPostedMeta = const VerificationMeta(
    'isPosted',
  );
  @override
  late final GeneratedColumn<bool> isPosted = GeneratedColumn<bool>(
    'is_posted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_posted" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
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
    entryDate,
    voucherNumber,
    voucherType,
    description,
    currencyCode,
    isPosted,
    sourceType,
    sourceId,
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
  static const String $name = 'journal_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<JournalEntryRow> instance, {
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
    if (data.containsKey('entry_date')) {
      context.handle(
        _entryDateMeta,
        entryDate.isAcceptableOrUnknown(data['entry_date']!, _entryDateMeta),
      );
    } else if (isInserting) {
      context.missing(_entryDateMeta);
    }
    if (data.containsKey('voucher_number')) {
      context.handle(
        _voucherNumberMeta,
        voucherNumber.isAcceptableOrUnknown(
          data['voucher_number']!,
          _voucherNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_voucherNumberMeta);
    }
    if (data.containsKey('voucher_type')) {
      context.handle(
        _voucherTypeMeta,
        voucherType.isAcceptableOrUnknown(
          data['voucher_type']!,
          _voucherTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_voucherTypeMeta);
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
    if (data.containsKey('is_posted')) {
      context.handle(
        _isPostedMeta,
        isPosted.isAcceptableOrUnknown(data['is_posted']!, _isPostedMeta),
      );
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
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
  JournalEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      entryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entry_date'],
      )!,
      voucherNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voucher_number'],
      )!,
      voucherType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voucher_type'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      isPosted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_posted'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      ),
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
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
  $JournalEntriesTable createAlias(String alias) {
    return $JournalEntriesTable(attachedDatabase, alias);
  }
}

class JournalEntryRow extends DataClass implements Insertable<JournalEntryRow> {
  final int id;
  final String uuid;

  /// Business date (UTC epoch ms, date portion).
  final int entryDate;
  final String voucherNumber;

  /// Display type e.g. بيع آجل
  final String voucherType;
  final String? description;
  final String currencyCode;
  final bool isPosted;

  /// Origin module document type (`sale`, …).
  final String? sourceType;

  /// Origin document UUID.
  final String? sourceId;
  final int createdAt;
  final int updatedAt;

  /// [SyncStatus.name]
  final String syncStatus;
  final int? lastSyncedAt;
  final int version;
  final int? deletedAt;
  const JournalEntryRow({
    required this.id,
    required this.uuid,
    required this.entryDate,
    required this.voucherNumber,
    required this.voucherType,
    this.description,
    required this.currencyCode,
    required this.isPosted,
    this.sourceType,
    this.sourceId,
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
    map['entry_date'] = Variable<int>(entryDate);
    map['voucher_number'] = Variable<String>(voucherNumber);
    map['voucher_type'] = Variable<String>(voucherType);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['currency_code'] = Variable<String>(currencyCode);
    map['is_posted'] = Variable<bool>(isPosted);
    if (!nullToAbsent || sourceType != null) {
      map['source_type'] = Variable<String>(sourceType);
    }
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
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

  JournalEntriesCompanion toCompanion(bool nullToAbsent) {
    return JournalEntriesCompanion(
      id: Value(id),
      uuid: Value(uuid),
      entryDate: Value(entryDate),
      voucherNumber: Value(voucherNumber),
      voucherType: Value(voucherType),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      currencyCode: Value(currencyCode),
      isPosted: Value(isPosted),
      sourceType: sourceType == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceType),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
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

  factory JournalEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalEntryRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      entryDate: serializer.fromJson<int>(json['entryDate']),
      voucherNumber: serializer.fromJson<String>(json['voucherNumber']),
      voucherType: serializer.fromJson<String>(json['voucherType']),
      description: serializer.fromJson<String?>(json['description']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      isPosted: serializer.fromJson<bool>(json['isPosted']),
      sourceType: serializer.fromJson<String?>(json['sourceType']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
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
      'entryDate': serializer.toJson<int>(entryDate),
      'voucherNumber': serializer.toJson<String>(voucherNumber),
      'voucherType': serializer.toJson<String>(voucherType),
      'description': serializer.toJson<String?>(description),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'isPosted': serializer.toJson<bool>(isPosted),
      'sourceType': serializer.toJson<String?>(sourceType),
      'sourceId': serializer.toJson<String?>(sourceId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'lastSyncedAt': serializer.toJson<int?>(lastSyncedAt),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  JournalEntryRow copyWith({
    int? id,
    String? uuid,
    int? entryDate,
    String? voucherNumber,
    String? voucherType,
    Value<String?> description = const Value.absent(),
    String? currencyCode,
    bool? isPosted,
    Value<String?> sourceType = const Value.absent(),
    Value<String?> sourceId = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    String? syncStatus,
    Value<int?> lastSyncedAt = const Value.absent(),
    int? version,
    Value<int?> deletedAt = const Value.absent(),
  }) => JournalEntryRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    entryDate: entryDate ?? this.entryDate,
    voucherNumber: voucherNumber ?? this.voucherNumber,
    voucherType: voucherType ?? this.voucherType,
    description: description.present ? description.value : this.description,
    currencyCode: currencyCode ?? this.currencyCode,
    isPosted: isPosted ?? this.isPosted,
    sourceType: sourceType.present ? sourceType.value : this.sourceType,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  JournalEntryRow copyWithCompanion(JournalEntriesCompanion data) {
    return JournalEntryRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      entryDate: data.entryDate.present ? data.entryDate.value : this.entryDate,
      voucherNumber: data.voucherNumber.present
          ? data.voucherNumber.value
          : this.voucherNumber,
      voucherType: data.voucherType.present
          ? data.voucherType.value
          : this.voucherType,
      description: data.description.present
          ? data.description.value
          : this.description,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      isPosted: data.isPosted.present ? data.isPosted.value : this.isPosted,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
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
    return (StringBuffer('JournalEntryRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('entryDate: $entryDate, ')
          ..write('voucherNumber: $voucherNumber, ')
          ..write('voucherType: $voucherType, ')
          ..write('description: $description, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('isPosted: $isPosted, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
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
    entryDate,
    voucherNumber,
    voucherType,
    description,
    currencyCode,
    isPosted,
    sourceType,
    sourceId,
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
      (other is JournalEntryRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.entryDate == this.entryDate &&
          other.voucherNumber == this.voucherNumber &&
          other.voucherType == this.voucherType &&
          other.description == this.description &&
          other.currencyCode == this.currencyCode &&
          other.isPosted == this.isPosted &&
          other.sourceType == this.sourceType &&
          other.sourceId == this.sourceId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt);
}

class JournalEntriesCompanion extends UpdateCompanion<JournalEntryRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> entryDate;
  final Value<String> voucherNumber;
  final Value<String> voucherType;
  final Value<String?> description;
  final Value<String> currencyCode;
  final Value<bool> isPosted;
  final Value<String?> sourceType;
  final Value<String?> sourceId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> syncStatus;
  final Value<int?> lastSyncedAt;
  final Value<int> version;
  final Value<int?> deletedAt;
  const JournalEntriesCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.entryDate = const Value.absent(),
    this.voucherNumber = const Value.absent(),
    this.voucherType = const Value.absent(),
    this.description = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.isPosted = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  JournalEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required int entryDate,
    required String voucherNumber,
    required String voucherType,
    this.description = const Value.absent(),
    required String currencyCode,
    this.isPosted = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceId = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : uuid = Value(uuid),
       entryDate = Value(entryDate),
       voucherNumber = Value(voucherNumber),
       voucherType = Value(voucherType),
       currencyCode = Value(currencyCode),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<JournalEntryRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? entryDate,
    Expression<String>? voucherNumber,
    Expression<String>? voucherType,
    Expression<String>? description,
    Expression<String>? currencyCode,
    Expression<bool>? isPosted,
    Expression<String>? sourceType,
    Expression<String>? sourceId,
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
      if (entryDate != null) 'entry_date': entryDate,
      if (voucherNumber != null) 'voucher_number': voucherNumber,
      if (voucherType != null) 'voucher_type': voucherType,
      if (description != null) 'description': description,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (isPosted != null) 'is_posted': isPosted,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceId != null) 'source_id': sourceId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  JournalEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<int>? entryDate,
    Value<String>? voucherNumber,
    Value<String>? voucherType,
    Value<String?>? description,
    Value<String>? currencyCode,
    Value<bool>? isPosted,
    Value<String?>? sourceType,
    Value<String?>? sourceId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? syncStatus,
    Value<int?>? lastSyncedAt,
    Value<int>? version,
    Value<int?>? deletedAt,
  }) {
    return JournalEntriesCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      entryDate: entryDate ?? this.entryDate,
      voucherNumber: voucherNumber ?? this.voucherNumber,
      voucherType: voucherType ?? this.voucherType,
      description: description ?? this.description,
      currencyCode: currencyCode ?? this.currencyCode,
      isPosted: isPosted ?? this.isPosted,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
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
    if (entryDate.present) {
      map['entry_date'] = Variable<int>(entryDate.value);
    }
    if (voucherNumber.present) {
      map['voucher_number'] = Variable<String>(voucherNumber.value);
    }
    if (voucherType.present) {
      map['voucher_type'] = Variable<String>(voucherType.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (isPosted.present) {
      map['is_posted'] = Variable<bool>(isPosted.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
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
    return (StringBuffer('JournalEntriesCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('entryDate: $entryDate, ')
          ..write('voucherNumber: $voucherNumber, ')
          ..write('voucherType: $voucherType, ')
          ..write('description: $description, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('isPosted: $isPosted, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
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

class $JournalLinesTable extends JournalLines
    with TableInfo<$JournalLinesTable, JournalLineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalLinesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _entryUuidMeta = const VerificationMeta(
    'entryUuid',
  );
  @override
  late final GeneratedColumn<String> entryUuid = GeneratedColumn<String>(
    'entry_uuid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountUuidMeta = const VerificationMeta(
    'accountUuid',
  );
  @override
  late final GeneratedColumn<String> accountUuid = GeneratedColumn<String>(
    'account_uuid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _debitMeta = const VerificationMeta('debit');
  @override
  late final GeneratedColumn<double> debit = GeneratedColumn<double>(
    'debit',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _creditMeta = const VerificationMeta('credit');
  @override
  late final GeneratedColumn<double> credit = GeneratedColumn<double>(
    'credit',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _exchangeRateToBaseMeta =
      const VerificationMeta('exchangeRateToBase');
  @override
  late final GeneratedColumn<double> exchangeRateToBase =
      GeneratedColumn<double>(
        'exchange_rate_to_base',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(1),
      );
  static const VerificationMeta _baseDebitMeta = const VerificationMeta(
    'baseDebit',
  );
  @override
  late final GeneratedColumn<double> baseDebit = GeneratedColumn<double>(
    'base_debit',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _baseCreditMeta = const VerificationMeta(
    'baseCredit',
  );
  @override
  late final GeneratedColumn<double> baseCredit = GeneratedColumn<double>(
    'base_credit',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lineDescriptionMeta = const VerificationMeta(
    'lineDescription',
  );
  @override
  late final GeneratedColumn<String> lineDescription = GeneratedColumn<String>(
    'line_description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    entryUuid,
    accountUuid,
    debit,
    credit,
    exchangeRateToBase,
    baseDebit,
    baseCredit,
    lineDescription,
    currencyCode,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<JournalLineRow> instance, {
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
    if (data.containsKey('entry_uuid')) {
      context.handle(
        _entryUuidMeta,
        entryUuid.isAcceptableOrUnknown(data['entry_uuid']!, _entryUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_entryUuidMeta);
    }
    if (data.containsKey('account_uuid')) {
      context.handle(
        _accountUuidMeta,
        accountUuid.isAcceptableOrUnknown(
          data['account_uuid']!,
          _accountUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountUuidMeta);
    }
    if (data.containsKey('debit')) {
      context.handle(
        _debitMeta,
        debit.isAcceptableOrUnknown(data['debit']!, _debitMeta),
      );
    }
    if (data.containsKey('credit')) {
      context.handle(
        _creditMeta,
        credit.isAcceptableOrUnknown(data['credit']!, _creditMeta),
      );
    }
    if (data.containsKey('exchange_rate_to_base')) {
      context.handle(
        _exchangeRateToBaseMeta,
        exchangeRateToBase.isAcceptableOrUnknown(
          data['exchange_rate_to_base']!,
          _exchangeRateToBaseMeta,
        ),
      );
    }
    if (data.containsKey('base_debit')) {
      context.handle(
        _baseDebitMeta,
        baseDebit.isAcceptableOrUnknown(data['base_debit']!, _baseDebitMeta),
      );
    }
    if (data.containsKey('base_credit')) {
      context.handle(
        _baseCreditMeta,
        baseCredit.isAcceptableOrUnknown(data['base_credit']!, _baseCreditMeta),
      );
    }
    if (data.containsKey('line_description')) {
      context.handle(
        _lineDescriptionMeta,
        lineDescription.isAcceptableOrUnknown(
          data['line_description']!,
          _lineDescriptionMeta,
        ),
      );
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
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JournalLineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalLineRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      entryUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_uuid'],
      )!,
      accountUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_uuid'],
      )!,
      debit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}debit'],
      )!,
      credit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}credit'],
      )!,
      exchangeRateToBase: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}exchange_rate_to_base'],
      )!,
      baseDebit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}base_debit'],
      )!,
      baseCredit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}base_credit'],
      )!,
      lineDescription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}line_description'],
      ),
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $JournalLinesTable createAlias(String alias) {
    return $JournalLinesTable(attachedDatabase, alias);
  }
}

class JournalLineRow extends DataClass implements Insertable<JournalLineRow> {
  final int id;
  final String uuid;

  /// Parent [JournalEntries.uuid].
  final String entryUuid;

  /// Posting account UUID ([Accounts.uuid]).
  final String accountUuid;
  final double debit;
  final double credit;

  /// Units of company base currency per 1 unit of [currencyCode] at booking.
  final double exchangeRateToBase;

  /// Debit amount in company base currency.
  final double baseDebit;

  /// Credit amount in company base currency.
  final double baseCredit;
  final String? lineDescription;
  final String currencyCode;
  final int sortOrder;
  const JournalLineRow({
    required this.id,
    required this.uuid,
    required this.entryUuid,
    required this.accountUuid,
    required this.debit,
    required this.credit,
    required this.exchangeRateToBase,
    required this.baseDebit,
    required this.baseCredit,
    this.lineDescription,
    required this.currencyCode,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['entry_uuid'] = Variable<String>(entryUuid);
    map['account_uuid'] = Variable<String>(accountUuid);
    map['debit'] = Variable<double>(debit);
    map['credit'] = Variable<double>(credit);
    map['exchange_rate_to_base'] = Variable<double>(exchangeRateToBase);
    map['base_debit'] = Variable<double>(baseDebit);
    map['base_credit'] = Variable<double>(baseCredit);
    if (!nullToAbsent || lineDescription != null) {
      map['line_description'] = Variable<String>(lineDescription);
    }
    map['currency_code'] = Variable<String>(currencyCode);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  JournalLinesCompanion toCompanion(bool nullToAbsent) {
    return JournalLinesCompanion(
      id: Value(id),
      uuid: Value(uuid),
      entryUuid: Value(entryUuid),
      accountUuid: Value(accountUuid),
      debit: Value(debit),
      credit: Value(credit),
      exchangeRateToBase: Value(exchangeRateToBase),
      baseDebit: Value(baseDebit),
      baseCredit: Value(baseCredit),
      lineDescription: lineDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(lineDescription),
      currencyCode: Value(currencyCode),
      sortOrder: Value(sortOrder),
    );
  }

  factory JournalLineRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalLineRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      entryUuid: serializer.fromJson<String>(json['entryUuid']),
      accountUuid: serializer.fromJson<String>(json['accountUuid']),
      debit: serializer.fromJson<double>(json['debit']),
      credit: serializer.fromJson<double>(json['credit']),
      exchangeRateToBase: serializer.fromJson<double>(
        json['exchangeRateToBase'],
      ),
      baseDebit: serializer.fromJson<double>(json['baseDebit']),
      baseCredit: serializer.fromJson<double>(json['baseCredit']),
      lineDescription: serializer.fromJson<String?>(json['lineDescription']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'entryUuid': serializer.toJson<String>(entryUuid),
      'accountUuid': serializer.toJson<String>(accountUuid),
      'debit': serializer.toJson<double>(debit),
      'credit': serializer.toJson<double>(credit),
      'exchangeRateToBase': serializer.toJson<double>(exchangeRateToBase),
      'baseDebit': serializer.toJson<double>(baseDebit),
      'baseCredit': serializer.toJson<double>(baseCredit),
      'lineDescription': serializer.toJson<String?>(lineDescription),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  JournalLineRow copyWith({
    int? id,
    String? uuid,
    String? entryUuid,
    String? accountUuid,
    double? debit,
    double? credit,
    double? exchangeRateToBase,
    double? baseDebit,
    double? baseCredit,
    Value<String?> lineDescription = const Value.absent(),
    String? currencyCode,
    int? sortOrder,
  }) => JournalLineRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    entryUuid: entryUuid ?? this.entryUuid,
    accountUuid: accountUuid ?? this.accountUuid,
    debit: debit ?? this.debit,
    credit: credit ?? this.credit,
    exchangeRateToBase: exchangeRateToBase ?? this.exchangeRateToBase,
    baseDebit: baseDebit ?? this.baseDebit,
    baseCredit: baseCredit ?? this.baseCredit,
    lineDescription: lineDescription.present
        ? lineDescription.value
        : this.lineDescription,
    currencyCode: currencyCode ?? this.currencyCode,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  JournalLineRow copyWithCompanion(JournalLinesCompanion data) {
    return JournalLineRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      entryUuid: data.entryUuid.present ? data.entryUuid.value : this.entryUuid,
      accountUuid: data.accountUuid.present
          ? data.accountUuid.value
          : this.accountUuid,
      debit: data.debit.present ? data.debit.value : this.debit,
      credit: data.credit.present ? data.credit.value : this.credit,
      exchangeRateToBase: data.exchangeRateToBase.present
          ? data.exchangeRateToBase.value
          : this.exchangeRateToBase,
      baseDebit: data.baseDebit.present ? data.baseDebit.value : this.baseDebit,
      baseCredit: data.baseCredit.present
          ? data.baseCredit.value
          : this.baseCredit,
      lineDescription: data.lineDescription.present
          ? data.lineDescription.value
          : this.lineDescription,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JournalLineRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('entryUuid: $entryUuid, ')
          ..write('accountUuid: $accountUuid, ')
          ..write('debit: $debit, ')
          ..write('credit: $credit, ')
          ..write('exchangeRateToBase: $exchangeRateToBase, ')
          ..write('baseDebit: $baseDebit, ')
          ..write('baseCredit: $baseCredit, ')
          ..write('lineDescription: $lineDescription, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    entryUuid,
    accountUuid,
    debit,
    credit,
    exchangeRateToBase,
    baseDebit,
    baseCredit,
    lineDescription,
    currencyCode,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalLineRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.entryUuid == this.entryUuid &&
          other.accountUuid == this.accountUuid &&
          other.debit == this.debit &&
          other.credit == this.credit &&
          other.exchangeRateToBase == this.exchangeRateToBase &&
          other.baseDebit == this.baseDebit &&
          other.baseCredit == this.baseCredit &&
          other.lineDescription == this.lineDescription &&
          other.currencyCode == this.currencyCode &&
          other.sortOrder == this.sortOrder);
}

class JournalLinesCompanion extends UpdateCompanion<JournalLineRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> entryUuid;
  final Value<String> accountUuid;
  final Value<double> debit;
  final Value<double> credit;
  final Value<double> exchangeRateToBase;
  final Value<double> baseDebit;
  final Value<double> baseCredit;
  final Value<String?> lineDescription;
  final Value<String> currencyCode;
  final Value<int> sortOrder;
  const JournalLinesCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.entryUuid = const Value.absent(),
    this.accountUuid = const Value.absent(),
    this.debit = const Value.absent(),
    this.credit = const Value.absent(),
    this.exchangeRateToBase = const Value.absent(),
    this.baseDebit = const Value.absent(),
    this.baseCredit = const Value.absent(),
    this.lineDescription = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  JournalLinesCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String entryUuid,
    required String accountUuid,
    this.debit = const Value.absent(),
    this.credit = const Value.absent(),
    this.exchangeRateToBase = const Value.absent(),
    this.baseDebit = const Value.absent(),
    this.baseCredit = const Value.absent(),
    this.lineDescription = const Value.absent(),
    required String currencyCode,
    this.sortOrder = const Value.absent(),
  }) : uuid = Value(uuid),
       entryUuid = Value(entryUuid),
       accountUuid = Value(accountUuid),
       currencyCode = Value(currencyCode);
  static Insertable<JournalLineRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? entryUuid,
    Expression<String>? accountUuid,
    Expression<double>? debit,
    Expression<double>? credit,
    Expression<double>? exchangeRateToBase,
    Expression<double>? baseDebit,
    Expression<double>? baseCredit,
    Expression<String>? lineDescription,
    Expression<String>? currencyCode,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (entryUuid != null) 'entry_uuid': entryUuid,
      if (accountUuid != null) 'account_uuid': accountUuid,
      if (debit != null) 'debit': debit,
      if (credit != null) 'credit': credit,
      if (exchangeRateToBase != null)
        'exchange_rate_to_base': exchangeRateToBase,
      if (baseDebit != null) 'base_debit': baseDebit,
      if (baseCredit != null) 'base_credit': baseCredit,
      if (lineDescription != null) 'line_description': lineDescription,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  JournalLinesCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? entryUuid,
    Value<String>? accountUuid,
    Value<double>? debit,
    Value<double>? credit,
    Value<double>? exchangeRateToBase,
    Value<double>? baseDebit,
    Value<double>? baseCredit,
    Value<String?>? lineDescription,
    Value<String>? currencyCode,
    Value<int>? sortOrder,
  }) {
    return JournalLinesCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      entryUuid: entryUuid ?? this.entryUuid,
      accountUuid: accountUuid ?? this.accountUuid,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
      exchangeRateToBase: exchangeRateToBase ?? this.exchangeRateToBase,
      baseDebit: baseDebit ?? this.baseDebit,
      baseCredit: baseCredit ?? this.baseCredit,
      lineDescription: lineDescription ?? this.lineDescription,
      currencyCode: currencyCode ?? this.currencyCode,
      sortOrder: sortOrder ?? this.sortOrder,
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
    if (entryUuid.present) {
      map['entry_uuid'] = Variable<String>(entryUuid.value);
    }
    if (accountUuid.present) {
      map['account_uuid'] = Variable<String>(accountUuid.value);
    }
    if (debit.present) {
      map['debit'] = Variable<double>(debit.value);
    }
    if (credit.present) {
      map['credit'] = Variable<double>(credit.value);
    }
    if (exchangeRateToBase.present) {
      map['exchange_rate_to_base'] = Variable<double>(exchangeRateToBase.value);
    }
    if (baseDebit.present) {
      map['base_debit'] = Variable<double>(baseDebit.value);
    }
    if (baseCredit.present) {
      map['base_credit'] = Variable<double>(baseCredit.value);
    }
    if (lineDescription.present) {
      map['line_description'] = Variable<String>(lineDescription.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalLinesCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('entryUuid: $entryUuid, ')
          ..write('accountUuid: $accountUuid, ')
          ..write('debit: $debit, ')
          ..write('credit: $credit, ')
          ..write('exchangeRateToBase: $exchangeRateToBase, ')
          ..write('baseDebit: $baseDebit, ')
          ..write('baseCredit: $baseCredit, ')
          ..write('lineDescription: $lineDescription, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $FiscalYearsTable extends FiscalYears
    with TableInfo<$FiscalYearsTable, FiscalYearRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FiscalYearsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 32,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 128,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<int> startDate = GeneratedColumn<int>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<int> endDate = GeneratedColumn<int>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 16,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseCurrencyCodeMeta = const VerificationMeta(
    'baseCurrencyCode',
  );
  @override
  late final GeneratedColumn<String> baseCurrencyCode = GeneratedColumn<String>(
    'base_currency_code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 8,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodCountMeta = const VerificationMeta(
    'periodCount',
  );
  @override
  late final GeneratedColumn<int> periodCount = GeneratedColumn<int>(
    'period_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodFrequencyMeta = const VerificationMeta(
    'periodFrequency',
  );
  @override
  late final GeneratedColumn<String> periodFrequency = GeneratedColumn<String>(
    'period_frequency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('monthly'),
  );
  static const VerificationMeta _fxRevaluationEnabledMeta =
      const VerificationMeta('fxRevaluationEnabled');
  @override
  late final GeneratedColumn<bool> fxRevaluationEnabled = GeneratedColumn<bool>(
    'fx_revaluation_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("fx_revaluation_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _fxGainAccountUuidMeta = const VerificationMeta(
    'fxGainAccountUuid',
  );
  @override
  late final GeneratedColumn<String> fxGainAccountUuid =
      GeneratedColumn<String>(
        'fx_gain_account_uuid',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _fxLossAccountUuidMeta = const VerificationMeta(
    'fxLossAccountUuid',
  );
  @override
  late final GeneratedColumn<String> fxLossAccountUuid =
      GeneratedColumn<String>(
        'fx_loss_account_uuid',
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
  static const VerificationMeta _closedAtMeta = const VerificationMeta(
    'closedAt',
  );
  @override
  late final GeneratedColumn<int> closedAt = GeneratedColumn<int>(
    'closed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _closedByMeta = const VerificationMeta(
    'closedBy',
  );
  @override
  late final GeneratedColumn<String> closedBy = GeneratedColumn<String>(
    'closed_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    code,
    name,
    startDate,
    endDate,
    status,
    baseCurrencyCode,
    periodCount,
    periodFrequency,
    fxRevaluationEnabled,
    fxGainAccountUuid,
    fxLossAccountUuid,
    createdAt,
    updatedAt,
    closedAt,
    createdBy,
    closedBy,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fiscal_years';
  @override
  VerificationContext validateIntegrity(
    Insertable<FiscalYearRow> instance, {
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
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('base_currency_code')) {
      context.handle(
        _baseCurrencyCodeMeta,
        baseCurrencyCode.isAcceptableOrUnknown(
          data['base_currency_code']!,
          _baseCurrencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_baseCurrencyCodeMeta);
    }
    if (data.containsKey('period_count')) {
      context.handle(
        _periodCountMeta,
        periodCount.isAcceptableOrUnknown(
          data['period_count']!,
          _periodCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_periodCountMeta);
    }
    if (data.containsKey('period_frequency')) {
      context.handle(
        _periodFrequencyMeta,
        periodFrequency.isAcceptableOrUnknown(
          data['period_frequency']!,
          _periodFrequencyMeta,
        ),
      );
    }
    if (data.containsKey('fx_revaluation_enabled')) {
      context.handle(
        _fxRevaluationEnabledMeta,
        fxRevaluationEnabled.isAcceptableOrUnknown(
          data['fx_revaluation_enabled']!,
          _fxRevaluationEnabledMeta,
        ),
      );
    }
    if (data.containsKey('fx_gain_account_uuid')) {
      context.handle(
        _fxGainAccountUuidMeta,
        fxGainAccountUuid.isAcceptableOrUnknown(
          data['fx_gain_account_uuid']!,
          _fxGainAccountUuidMeta,
        ),
      );
    }
    if (data.containsKey('fx_loss_account_uuid')) {
      context.handle(
        _fxLossAccountUuidMeta,
        fxLossAccountUuid.isAcceptableOrUnknown(
          data['fx_loss_account_uuid']!,
          _fxLossAccountUuidMeta,
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
    if (data.containsKey('closed_at')) {
      context.handle(
        _closedAtMeta,
        closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('closed_by')) {
      context.handle(
        _closedByMeta,
        closedBy.isAcceptableOrUnknown(data['closed_by']!, _closedByMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FiscalYearRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FiscalYearRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      baseCurrencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_currency_code'],
      )!,
      periodCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}period_count'],
      )!,
      periodFrequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}period_frequency'],
      )!,
      fxRevaluationEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}fx_revaluation_enabled'],
      )!,
      fxGainAccountUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fx_gain_account_uuid'],
      ),
      fxLossAccountUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fx_loss_account_uuid'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      closedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}closed_at'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      closedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}closed_by'],
      ),
    );
  }

  @override
  $FiscalYearsTable createAlias(String alias) {
    return $FiscalYearsTable(attachedDatabase, alias);
  }
}

class FiscalYearRow extends DataClass implements Insertable<FiscalYearRow> {
  final int id;
  final String uuid;
  final String code;
  final String name;

  /// Inclusive start (UTC day epoch ms).
  final int startDate;

  /// Inclusive end (UTC day epoch ms).
  final int endDate;

  /// `open` | `closed`
  final String status;
  final String baseCurrencyCode;
  final int periodCount;

  /// `monthly` (extensible).
  final String periodFrequency;
  final bool fxRevaluationEnabled;
  final String? fxGainAccountUuid;
  final String? fxLossAccountUuid;
  final int createdAt;
  final int updatedAt;
  final int? closedAt;
  final String? createdBy;
  final String? closedBy;
  const FiscalYearRow({
    required this.id,
    required this.uuid,
    required this.code,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.baseCurrencyCode,
    required this.periodCount,
    required this.periodFrequency,
    required this.fxRevaluationEnabled,
    this.fxGainAccountUuid,
    this.fxLossAccountUuid,
    required this.createdAt,
    required this.updatedAt,
    this.closedAt,
    this.createdBy,
    this.closedBy,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['start_date'] = Variable<int>(startDate);
    map['end_date'] = Variable<int>(endDate);
    map['status'] = Variable<String>(status);
    map['base_currency_code'] = Variable<String>(baseCurrencyCode);
    map['period_count'] = Variable<int>(periodCount);
    map['period_frequency'] = Variable<String>(periodFrequency);
    map['fx_revaluation_enabled'] = Variable<bool>(fxRevaluationEnabled);
    if (!nullToAbsent || fxGainAccountUuid != null) {
      map['fx_gain_account_uuid'] = Variable<String>(fxGainAccountUuid);
    }
    if (!nullToAbsent || fxLossAccountUuid != null) {
      map['fx_loss_account_uuid'] = Variable<String>(fxLossAccountUuid);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<int>(closedAt);
    }
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    if (!nullToAbsent || closedBy != null) {
      map['closed_by'] = Variable<String>(closedBy);
    }
    return map;
  }

  FiscalYearsCompanion toCompanion(bool nullToAbsent) {
    return FiscalYearsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      code: Value(code),
      name: Value(name),
      startDate: Value(startDate),
      endDate: Value(endDate),
      status: Value(status),
      baseCurrencyCode: Value(baseCurrencyCode),
      periodCount: Value(periodCount),
      periodFrequency: Value(periodFrequency),
      fxRevaluationEnabled: Value(fxRevaluationEnabled),
      fxGainAccountUuid: fxGainAccountUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(fxGainAccountUuid),
      fxLossAccountUuid: fxLossAccountUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(fxLossAccountUuid),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      closedBy: closedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(closedBy),
    );
  }

  factory FiscalYearRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FiscalYearRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      startDate: serializer.fromJson<int>(json['startDate']),
      endDate: serializer.fromJson<int>(json['endDate']),
      status: serializer.fromJson<String>(json['status']),
      baseCurrencyCode: serializer.fromJson<String>(json['baseCurrencyCode']),
      periodCount: serializer.fromJson<int>(json['periodCount']),
      periodFrequency: serializer.fromJson<String>(json['periodFrequency']),
      fxRevaluationEnabled: serializer.fromJson<bool>(
        json['fxRevaluationEnabled'],
      ),
      fxGainAccountUuid: serializer.fromJson<String?>(
        json['fxGainAccountUuid'],
      ),
      fxLossAccountUuid: serializer.fromJson<String?>(
        json['fxLossAccountUuid'],
      ),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      closedAt: serializer.fromJson<int?>(json['closedAt']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      closedBy: serializer.fromJson<String?>(json['closedBy']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'startDate': serializer.toJson<int>(startDate),
      'endDate': serializer.toJson<int>(endDate),
      'status': serializer.toJson<String>(status),
      'baseCurrencyCode': serializer.toJson<String>(baseCurrencyCode),
      'periodCount': serializer.toJson<int>(periodCount),
      'periodFrequency': serializer.toJson<String>(periodFrequency),
      'fxRevaluationEnabled': serializer.toJson<bool>(fxRevaluationEnabled),
      'fxGainAccountUuid': serializer.toJson<String?>(fxGainAccountUuid),
      'fxLossAccountUuid': serializer.toJson<String?>(fxLossAccountUuid),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'closedAt': serializer.toJson<int?>(closedAt),
      'createdBy': serializer.toJson<String?>(createdBy),
      'closedBy': serializer.toJson<String?>(closedBy),
    };
  }

  FiscalYearRow copyWith({
    int? id,
    String? uuid,
    String? code,
    String? name,
    int? startDate,
    int? endDate,
    String? status,
    String? baseCurrencyCode,
    int? periodCount,
    String? periodFrequency,
    bool? fxRevaluationEnabled,
    Value<String?> fxGainAccountUuid = const Value.absent(),
    Value<String?> fxLossAccountUuid = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    Value<int?> closedAt = const Value.absent(),
    Value<String?> createdBy = const Value.absent(),
    Value<String?> closedBy = const Value.absent(),
  }) => FiscalYearRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    code: code ?? this.code,
    name: name ?? this.name,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    status: status ?? this.status,
    baseCurrencyCode: baseCurrencyCode ?? this.baseCurrencyCode,
    periodCount: periodCount ?? this.periodCount,
    periodFrequency: periodFrequency ?? this.periodFrequency,
    fxRevaluationEnabled: fxRevaluationEnabled ?? this.fxRevaluationEnabled,
    fxGainAccountUuid: fxGainAccountUuid.present
        ? fxGainAccountUuid.value
        : this.fxGainAccountUuid,
    fxLossAccountUuid: fxLossAccountUuid.present
        ? fxLossAccountUuid.value
        : this.fxLossAccountUuid,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    closedAt: closedAt.present ? closedAt.value : this.closedAt,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    closedBy: closedBy.present ? closedBy.value : this.closedBy,
  );
  FiscalYearRow copyWithCompanion(FiscalYearsCompanion data) {
    return FiscalYearRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      status: data.status.present ? data.status.value : this.status,
      baseCurrencyCode: data.baseCurrencyCode.present
          ? data.baseCurrencyCode.value
          : this.baseCurrencyCode,
      periodCount: data.periodCount.present
          ? data.periodCount.value
          : this.periodCount,
      periodFrequency: data.periodFrequency.present
          ? data.periodFrequency.value
          : this.periodFrequency,
      fxRevaluationEnabled: data.fxRevaluationEnabled.present
          ? data.fxRevaluationEnabled.value
          : this.fxRevaluationEnabled,
      fxGainAccountUuid: data.fxGainAccountUuid.present
          ? data.fxGainAccountUuid.value
          : this.fxGainAccountUuid,
      fxLossAccountUuid: data.fxLossAccountUuid.present
          ? data.fxLossAccountUuid.value
          : this.fxLossAccountUuid,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      closedBy: data.closedBy.present ? data.closedBy.value : this.closedBy,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FiscalYearRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('status: $status, ')
          ..write('baseCurrencyCode: $baseCurrencyCode, ')
          ..write('periodCount: $periodCount, ')
          ..write('periodFrequency: $periodFrequency, ')
          ..write('fxRevaluationEnabled: $fxRevaluationEnabled, ')
          ..write('fxGainAccountUuid: $fxGainAccountUuid, ')
          ..write('fxLossAccountUuid: $fxLossAccountUuid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('closedBy: $closedBy')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    code,
    name,
    startDate,
    endDate,
    status,
    baseCurrencyCode,
    periodCount,
    periodFrequency,
    fxRevaluationEnabled,
    fxGainAccountUuid,
    fxLossAccountUuid,
    createdAt,
    updatedAt,
    closedAt,
    createdBy,
    closedBy,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FiscalYearRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.code == this.code &&
          other.name == this.name &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.status == this.status &&
          other.baseCurrencyCode == this.baseCurrencyCode &&
          other.periodCount == this.periodCount &&
          other.periodFrequency == this.periodFrequency &&
          other.fxRevaluationEnabled == this.fxRevaluationEnabled &&
          other.fxGainAccountUuid == this.fxGainAccountUuid &&
          other.fxLossAccountUuid == this.fxLossAccountUuid &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.closedAt == this.closedAt &&
          other.createdBy == this.createdBy &&
          other.closedBy == this.closedBy);
}

class FiscalYearsCompanion extends UpdateCompanion<FiscalYearRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> code;
  final Value<String> name;
  final Value<int> startDate;
  final Value<int> endDate;
  final Value<String> status;
  final Value<String> baseCurrencyCode;
  final Value<int> periodCount;
  final Value<String> periodFrequency;
  final Value<bool> fxRevaluationEnabled;
  final Value<String?> fxGainAccountUuid;
  final Value<String?> fxLossAccountUuid;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> closedAt;
  final Value<String?> createdBy;
  final Value<String?> closedBy;
  const FiscalYearsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.status = const Value.absent(),
    this.baseCurrencyCode = const Value.absent(),
    this.periodCount = const Value.absent(),
    this.periodFrequency = const Value.absent(),
    this.fxRevaluationEnabled = const Value.absent(),
    this.fxGainAccountUuid = const Value.absent(),
    this.fxLossAccountUuid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.closedBy = const Value.absent(),
  });
  FiscalYearsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String code,
    required String name,
    required int startDate,
    required int endDate,
    required String status,
    required String baseCurrencyCode,
    required int periodCount,
    this.periodFrequency = const Value.absent(),
    this.fxRevaluationEnabled = const Value.absent(),
    this.fxGainAccountUuid = const Value.absent(),
    this.fxLossAccountUuid = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.closedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.closedBy = const Value.absent(),
  }) : uuid = Value(uuid),
       code = Value(code),
       name = Value(name),
       startDate = Value(startDate),
       endDate = Value(endDate),
       status = Value(status),
       baseCurrencyCode = Value(baseCurrencyCode),
       periodCount = Value(periodCount),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<FiscalYearRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? code,
    Expression<String>? name,
    Expression<int>? startDate,
    Expression<int>? endDate,
    Expression<String>? status,
    Expression<String>? baseCurrencyCode,
    Expression<int>? periodCount,
    Expression<String>? periodFrequency,
    Expression<bool>? fxRevaluationEnabled,
    Expression<String>? fxGainAccountUuid,
    Expression<String>? fxLossAccountUuid,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? closedAt,
    Expression<String>? createdBy,
    Expression<String>? closedBy,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (status != null) 'status': status,
      if (baseCurrencyCode != null) 'base_currency_code': baseCurrencyCode,
      if (periodCount != null) 'period_count': periodCount,
      if (periodFrequency != null) 'period_frequency': periodFrequency,
      if (fxRevaluationEnabled != null)
        'fx_revaluation_enabled': fxRevaluationEnabled,
      if (fxGainAccountUuid != null) 'fx_gain_account_uuid': fxGainAccountUuid,
      if (fxLossAccountUuid != null) 'fx_loss_account_uuid': fxLossAccountUuid,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (closedAt != null) 'closed_at': closedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (closedBy != null) 'closed_by': closedBy,
    });
  }

  FiscalYearsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? code,
    Value<String>? name,
    Value<int>? startDate,
    Value<int>? endDate,
    Value<String>? status,
    Value<String>? baseCurrencyCode,
    Value<int>? periodCount,
    Value<String>? periodFrequency,
    Value<bool>? fxRevaluationEnabled,
    Value<String?>? fxGainAccountUuid,
    Value<String?>? fxLossAccountUuid,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? closedAt,
    Value<String?>? createdBy,
    Value<String?>? closedBy,
  }) {
    return FiscalYearsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      code: code ?? this.code,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      baseCurrencyCode: baseCurrencyCode ?? this.baseCurrencyCode,
      periodCount: periodCount ?? this.periodCount,
      periodFrequency: periodFrequency ?? this.periodFrequency,
      fxRevaluationEnabled: fxRevaluationEnabled ?? this.fxRevaluationEnabled,
      fxGainAccountUuid: fxGainAccountUuid ?? this.fxGainAccountUuid,
      fxLossAccountUuid: fxLossAccountUuid ?? this.fxLossAccountUuid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      closedAt: closedAt ?? this.closedAt,
      createdBy: createdBy ?? this.createdBy,
      closedBy: closedBy ?? this.closedBy,
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
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<int>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<int>(endDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (baseCurrencyCode.present) {
      map['base_currency_code'] = Variable<String>(baseCurrencyCode.value);
    }
    if (periodCount.present) {
      map['period_count'] = Variable<int>(periodCount.value);
    }
    if (periodFrequency.present) {
      map['period_frequency'] = Variable<String>(periodFrequency.value);
    }
    if (fxRevaluationEnabled.present) {
      map['fx_revaluation_enabled'] = Variable<bool>(
        fxRevaluationEnabled.value,
      );
    }
    if (fxGainAccountUuid.present) {
      map['fx_gain_account_uuid'] = Variable<String>(fxGainAccountUuid.value);
    }
    if (fxLossAccountUuid.present) {
      map['fx_loss_account_uuid'] = Variable<String>(fxLossAccountUuid.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<int>(closedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (closedBy.present) {
      map['closed_by'] = Variable<String>(closedBy.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FiscalYearsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('status: $status, ')
          ..write('baseCurrencyCode: $baseCurrencyCode, ')
          ..write('periodCount: $periodCount, ')
          ..write('periodFrequency: $periodFrequency, ')
          ..write('fxRevaluationEnabled: $fxRevaluationEnabled, ')
          ..write('fxGainAccountUuid: $fxGainAccountUuid, ')
          ..write('fxLossAccountUuid: $fxLossAccountUuid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('closedBy: $closedBy')
          ..write(')'))
        .toString();
  }
}

class $AccountingPeriodsTable extends AccountingPeriods
    with TableInfo<$AccountingPeriodsTable, AccountingPeriodRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountingPeriodsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _fiscalYearUuidMeta = const VerificationMeta(
    'fiscalYearUuid',
  );
  @override
  late final GeneratedColumn<String> fiscalYearUuid = GeneratedColumn<String>(
    'fiscal_year_uuid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodNumberMeta = const VerificationMeta(
    'periodNumber',
  );
  @override
  late final GeneratedColumn<int> periodNumber = GeneratedColumn<int>(
    'period_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<int> startDate = GeneratedColumn<int>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<int> endDate = GeneratedColumn<int>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 16,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openedAtMeta = const VerificationMeta(
    'openedAt',
  );
  @override
  late final GeneratedColumn<int> openedAt = GeneratedColumn<int>(
    'opened_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _openedByMeta = const VerificationMeta(
    'openedBy',
  );
  @override
  late final GeneratedColumn<String> openedBy = GeneratedColumn<String>(
    'opened_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _closedAtMeta = const VerificationMeta(
    'closedAt',
  );
  @override
  late final GeneratedColumn<int> closedAt = GeneratedColumn<int>(
    'closed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _closedByMeta = const VerificationMeta(
    'closedBy',
  );
  @override
  late final GeneratedColumn<String> closedBy = GeneratedColumn<String>(
    'closed_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reopenedAtMeta = const VerificationMeta(
    'reopenedAt',
  );
  @override
  late final GeneratedColumn<int> reopenedAt = GeneratedColumn<int>(
    'reopened_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reopenedByMeta = const VerificationMeta(
    'reopenedBy',
  );
  @override
  late final GeneratedColumn<String> reopenedBy = GeneratedColumn<String>(
    'reopened_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reopenReasonMeta = const VerificationMeta(
    'reopenReason',
  );
  @override
  late final GeneratedColumn<String> reopenReason = GeneratedColumn<String>(
    'reopen_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    fiscalYearUuid,
    periodNumber,
    name,
    startDate,
    endDate,
    status,
    openedAt,
    openedBy,
    closedAt,
    closedBy,
    reopenedAt,
    reopenedBy,
    reopenReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounting_periods';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountingPeriodRow> instance, {
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
    if (data.containsKey('fiscal_year_uuid')) {
      context.handle(
        _fiscalYearUuidMeta,
        fiscalYearUuid.isAcceptableOrUnknown(
          data['fiscal_year_uuid']!,
          _fiscalYearUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fiscalYearUuidMeta);
    }
    if (data.containsKey('period_number')) {
      context.handle(
        _periodNumberMeta,
        periodNumber.isAcceptableOrUnknown(
          data['period_number']!,
          _periodNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_periodNumberMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    }
    if (data.containsKey('opened_by')) {
      context.handle(
        _openedByMeta,
        openedBy.isAcceptableOrUnknown(data['opened_by']!, _openedByMeta),
      );
    }
    if (data.containsKey('closed_at')) {
      context.handle(
        _closedAtMeta,
        closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta),
      );
    }
    if (data.containsKey('closed_by')) {
      context.handle(
        _closedByMeta,
        closedBy.isAcceptableOrUnknown(data['closed_by']!, _closedByMeta),
      );
    }
    if (data.containsKey('reopened_at')) {
      context.handle(
        _reopenedAtMeta,
        reopenedAt.isAcceptableOrUnknown(data['reopened_at']!, _reopenedAtMeta),
      );
    }
    if (data.containsKey('reopened_by')) {
      context.handle(
        _reopenedByMeta,
        reopenedBy.isAcceptableOrUnknown(data['reopened_by']!, _reopenedByMeta),
      );
    }
    if (data.containsKey('reopen_reason')) {
      context.handle(
        _reopenReasonMeta,
        reopenReason.isAcceptableOrUnknown(
          data['reopen_reason']!,
          _reopenReasonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {fiscalYearUuid, periodNumber},
  ];
  @override
  AccountingPeriodRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountingPeriodRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      fiscalYearUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fiscal_year_uuid'],
      )!,
      periodNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}period_number'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      openedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opened_at'],
      ),
      openedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}opened_by'],
      ),
      closedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}closed_at'],
      ),
      closedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}closed_by'],
      ),
      reopenedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reopened_at'],
      ),
      reopenedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reopened_by'],
      ),
      reopenReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reopen_reason'],
      ),
    );
  }

  @override
  $AccountingPeriodsTable createAlias(String alias) {
    return $AccountingPeriodsTable(attachedDatabase, alias);
  }
}

class AccountingPeriodRow extends DataClass
    implements Insertable<AccountingPeriodRow> {
  final int id;
  final String uuid;
  final String fiscalYearUuid;
  final int periodNumber;
  final String name;

  /// Inclusive start (UTC day epoch ms).
  final int startDate;

  /// Inclusive end (UTC day epoch ms).
  final int endDate;

  /// `closed` | `open` | `closing` | `reopened`
  final String status;
  final int? openedAt;
  final String? openedBy;
  final int? closedAt;
  final String? closedBy;
  final int? reopenedAt;
  final String? reopenedBy;
  final String? reopenReason;
  const AccountingPeriodRow({
    required this.id,
    required this.uuid,
    required this.fiscalYearUuid,
    required this.periodNumber,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.openedAt,
    this.openedBy,
    this.closedAt,
    this.closedBy,
    this.reopenedAt,
    this.reopenedBy,
    this.reopenReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['fiscal_year_uuid'] = Variable<String>(fiscalYearUuid);
    map['period_number'] = Variable<int>(periodNumber);
    map['name'] = Variable<String>(name);
    map['start_date'] = Variable<int>(startDate);
    map['end_date'] = Variable<int>(endDate);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || openedAt != null) {
      map['opened_at'] = Variable<int>(openedAt);
    }
    if (!nullToAbsent || openedBy != null) {
      map['opened_by'] = Variable<String>(openedBy);
    }
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<int>(closedAt);
    }
    if (!nullToAbsent || closedBy != null) {
      map['closed_by'] = Variable<String>(closedBy);
    }
    if (!nullToAbsent || reopenedAt != null) {
      map['reopened_at'] = Variable<int>(reopenedAt);
    }
    if (!nullToAbsent || reopenedBy != null) {
      map['reopened_by'] = Variable<String>(reopenedBy);
    }
    if (!nullToAbsent || reopenReason != null) {
      map['reopen_reason'] = Variable<String>(reopenReason);
    }
    return map;
  }

  AccountingPeriodsCompanion toCompanion(bool nullToAbsent) {
    return AccountingPeriodsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      fiscalYearUuid: Value(fiscalYearUuid),
      periodNumber: Value(periodNumber),
      name: Value(name),
      startDate: Value(startDate),
      endDate: Value(endDate),
      status: Value(status),
      openedAt: openedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(openedAt),
      openedBy: openedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(openedBy),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
      closedBy: closedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(closedBy),
      reopenedAt: reopenedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reopenedAt),
      reopenedBy: reopenedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(reopenedBy),
      reopenReason: reopenReason == null && nullToAbsent
          ? const Value.absent()
          : Value(reopenReason),
    );
  }

  factory AccountingPeriodRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountingPeriodRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      fiscalYearUuid: serializer.fromJson<String>(json['fiscalYearUuid']),
      periodNumber: serializer.fromJson<int>(json['periodNumber']),
      name: serializer.fromJson<String>(json['name']),
      startDate: serializer.fromJson<int>(json['startDate']),
      endDate: serializer.fromJson<int>(json['endDate']),
      status: serializer.fromJson<String>(json['status']),
      openedAt: serializer.fromJson<int?>(json['openedAt']),
      openedBy: serializer.fromJson<String?>(json['openedBy']),
      closedAt: serializer.fromJson<int?>(json['closedAt']),
      closedBy: serializer.fromJson<String?>(json['closedBy']),
      reopenedAt: serializer.fromJson<int?>(json['reopenedAt']),
      reopenedBy: serializer.fromJson<String?>(json['reopenedBy']),
      reopenReason: serializer.fromJson<String?>(json['reopenReason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'fiscalYearUuid': serializer.toJson<String>(fiscalYearUuid),
      'periodNumber': serializer.toJson<int>(periodNumber),
      'name': serializer.toJson<String>(name),
      'startDate': serializer.toJson<int>(startDate),
      'endDate': serializer.toJson<int>(endDate),
      'status': serializer.toJson<String>(status),
      'openedAt': serializer.toJson<int?>(openedAt),
      'openedBy': serializer.toJson<String?>(openedBy),
      'closedAt': serializer.toJson<int?>(closedAt),
      'closedBy': serializer.toJson<String?>(closedBy),
      'reopenedAt': serializer.toJson<int?>(reopenedAt),
      'reopenedBy': serializer.toJson<String?>(reopenedBy),
      'reopenReason': serializer.toJson<String?>(reopenReason),
    };
  }

  AccountingPeriodRow copyWith({
    int? id,
    String? uuid,
    String? fiscalYearUuid,
    int? periodNumber,
    String? name,
    int? startDate,
    int? endDate,
    String? status,
    Value<int?> openedAt = const Value.absent(),
    Value<String?> openedBy = const Value.absent(),
    Value<int?> closedAt = const Value.absent(),
    Value<String?> closedBy = const Value.absent(),
    Value<int?> reopenedAt = const Value.absent(),
    Value<String?> reopenedBy = const Value.absent(),
    Value<String?> reopenReason = const Value.absent(),
  }) => AccountingPeriodRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    fiscalYearUuid: fiscalYearUuid ?? this.fiscalYearUuid,
    periodNumber: periodNumber ?? this.periodNumber,
    name: name ?? this.name,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    status: status ?? this.status,
    openedAt: openedAt.present ? openedAt.value : this.openedAt,
    openedBy: openedBy.present ? openedBy.value : this.openedBy,
    closedAt: closedAt.present ? closedAt.value : this.closedAt,
    closedBy: closedBy.present ? closedBy.value : this.closedBy,
    reopenedAt: reopenedAt.present ? reopenedAt.value : this.reopenedAt,
    reopenedBy: reopenedBy.present ? reopenedBy.value : this.reopenedBy,
    reopenReason: reopenReason.present ? reopenReason.value : this.reopenReason,
  );
  AccountingPeriodRow copyWithCompanion(AccountingPeriodsCompanion data) {
    return AccountingPeriodRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      fiscalYearUuid: data.fiscalYearUuid.present
          ? data.fiscalYearUuid.value
          : this.fiscalYearUuid,
      periodNumber: data.periodNumber.present
          ? data.periodNumber.value
          : this.periodNumber,
      name: data.name.present ? data.name.value : this.name,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      status: data.status.present ? data.status.value : this.status,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      openedBy: data.openedBy.present ? data.openedBy.value : this.openedBy,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      closedBy: data.closedBy.present ? data.closedBy.value : this.closedBy,
      reopenedAt: data.reopenedAt.present
          ? data.reopenedAt.value
          : this.reopenedAt,
      reopenedBy: data.reopenedBy.present
          ? data.reopenedBy.value
          : this.reopenedBy,
      reopenReason: data.reopenReason.present
          ? data.reopenReason.value
          : this.reopenReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountingPeriodRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('fiscalYearUuid: $fiscalYearUuid, ')
          ..write('periodNumber: $periodNumber, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('status: $status, ')
          ..write('openedAt: $openedAt, ')
          ..write('openedBy: $openedBy, ')
          ..write('closedAt: $closedAt, ')
          ..write('closedBy: $closedBy, ')
          ..write('reopenedAt: $reopenedAt, ')
          ..write('reopenedBy: $reopenedBy, ')
          ..write('reopenReason: $reopenReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    fiscalYearUuid,
    periodNumber,
    name,
    startDate,
    endDate,
    status,
    openedAt,
    openedBy,
    closedAt,
    closedBy,
    reopenedAt,
    reopenedBy,
    reopenReason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountingPeriodRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.fiscalYearUuid == this.fiscalYearUuid &&
          other.periodNumber == this.periodNumber &&
          other.name == this.name &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.status == this.status &&
          other.openedAt == this.openedAt &&
          other.openedBy == this.openedBy &&
          other.closedAt == this.closedAt &&
          other.closedBy == this.closedBy &&
          other.reopenedAt == this.reopenedAt &&
          other.reopenedBy == this.reopenedBy &&
          other.reopenReason == this.reopenReason);
}

class AccountingPeriodsCompanion extends UpdateCompanion<AccountingPeriodRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> fiscalYearUuid;
  final Value<int> periodNumber;
  final Value<String> name;
  final Value<int> startDate;
  final Value<int> endDate;
  final Value<String> status;
  final Value<int?> openedAt;
  final Value<String?> openedBy;
  final Value<int?> closedAt;
  final Value<String?> closedBy;
  final Value<int?> reopenedAt;
  final Value<String?> reopenedBy;
  final Value<String?> reopenReason;
  const AccountingPeriodsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.fiscalYearUuid = const Value.absent(),
    this.periodNumber = const Value.absent(),
    this.name = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.status = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.openedBy = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.closedBy = const Value.absent(),
    this.reopenedAt = const Value.absent(),
    this.reopenedBy = const Value.absent(),
    this.reopenReason = const Value.absent(),
  });
  AccountingPeriodsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String fiscalYearUuid,
    required int periodNumber,
    required String name,
    required int startDate,
    required int endDate,
    required String status,
    this.openedAt = const Value.absent(),
    this.openedBy = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.closedBy = const Value.absent(),
    this.reopenedAt = const Value.absent(),
    this.reopenedBy = const Value.absent(),
    this.reopenReason = const Value.absent(),
  }) : uuid = Value(uuid),
       fiscalYearUuid = Value(fiscalYearUuid),
       periodNumber = Value(periodNumber),
       name = Value(name),
       startDate = Value(startDate),
       endDate = Value(endDate),
       status = Value(status);
  static Insertable<AccountingPeriodRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? fiscalYearUuid,
    Expression<int>? periodNumber,
    Expression<String>? name,
    Expression<int>? startDate,
    Expression<int>? endDate,
    Expression<String>? status,
    Expression<int>? openedAt,
    Expression<String>? openedBy,
    Expression<int>? closedAt,
    Expression<String>? closedBy,
    Expression<int>? reopenedAt,
    Expression<String>? reopenedBy,
    Expression<String>? reopenReason,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (fiscalYearUuid != null) 'fiscal_year_uuid': fiscalYearUuid,
      if (periodNumber != null) 'period_number': periodNumber,
      if (name != null) 'name': name,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (status != null) 'status': status,
      if (openedAt != null) 'opened_at': openedAt,
      if (openedBy != null) 'opened_by': openedBy,
      if (closedAt != null) 'closed_at': closedAt,
      if (closedBy != null) 'closed_by': closedBy,
      if (reopenedAt != null) 'reopened_at': reopenedAt,
      if (reopenedBy != null) 'reopened_by': reopenedBy,
      if (reopenReason != null) 'reopen_reason': reopenReason,
    });
  }

  AccountingPeriodsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? fiscalYearUuid,
    Value<int>? periodNumber,
    Value<String>? name,
    Value<int>? startDate,
    Value<int>? endDate,
    Value<String>? status,
    Value<int?>? openedAt,
    Value<String?>? openedBy,
    Value<int?>? closedAt,
    Value<String?>? closedBy,
    Value<int?>? reopenedAt,
    Value<String?>? reopenedBy,
    Value<String?>? reopenReason,
  }) {
    return AccountingPeriodsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      fiscalYearUuid: fiscalYearUuid ?? this.fiscalYearUuid,
      periodNumber: periodNumber ?? this.periodNumber,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      openedAt: openedAt ?? this.openedAt,
      openedBy: openedBy ?? this.openedBy,
      closedAt: closedAt ?? this.closedAt,
      closedBy: closedBy ?? this.closedBy,
      reopenedAt: reopenedAt ?? this.reopenedAt,
      reopenedBy: reopenedBy ?? this.reopenedBy,
      reopenReason: reopenReason ?? this.reopenReason,
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
    if (fiscalYearUuid.present) {
      map['fiscal_year_uuid'] = Variable<String>(fiscalYearUuid.value);
    }
    if (periodNumber.present) {
      map['period_number'] = Variable<int>(periodNumber.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<int>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<int>(endDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<int>(openedAt.value);
    }
    if (openedBy.present) {
      map['opened_by'] = Variable<String>(openedBy.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<int>(closedAt.value);
    }
    if (closedBy.present) {
      map['closed_by'] = Variable<String>(closedBy.value);
    }
    if (reopenedAt.present) {
      map['reopened_at'] = Variable<int>(reopenedAt.value);
    }
    if (reopenedBy.present) {
      map['reopened_by'] = Variable<String>(reopenedBy.value);
    }
    if (reopenReason.present) {
      map['reopen_reason'] = Variable<String>(reopenReason.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountingPeriodsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('fiscalYearUuid: $fiscalYearUuid, ')
          ..write('periodNumber: $periodNumber, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('status: $status, ')
          ..write('openedAt: $openedAt, ')
          ..write('openedBy: $openedBy, ')
          ..write('closedAt: $closedAt, ')
          ..write('closedBy: $closedBy, ')
          ..write('reopenedAt: $reopenedAt, ')
          ..write('reopenedBy: $reopenedBy, ')
          ..write('reopenReason: $reopenReason')
          ..write(')'))
        .toString();
  }
}

class $PeriodClosingRecordsTable extends PeriodClosingRecords
    with TableInfo<$PeriodClosingRecordsTable, PeriodClosingRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeriodClosingRecordsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _fiscalYearUuidMeta = const VerificationMeta(
    'fiscalYearUuid',
  );
  @override
  late final GeneratedColumn<String> fiscalYearUuid = GeneratedColumn<String>(
    'fiscal_year_uuid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodUuidMeta = const VerificationMeta(
    'periodUuid',
  );
  @override
  late final GeneratedColumn<String> periodUuid = GeneratedColumn<String>(
    'period_uuid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closingDateMeta = const VerificationMeta(
    'closingDate',
  );
  @override
  late final GeneratedColumn<int> closingDate = GeneratedColumn<int>(
    'closing_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 16,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fxRevaluationEnabledMeta =
      const VerificationMeta('fxRevaluationEnabled');
  @override
  late final GeneratedColumn<bool> fxRevaluationEnabled = GeneratedColumn<bool>(
    'fx_revaluation_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("fx_revaluation_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _fxRevaluationExecutedMeta =
      const VerificationMeta('fxRevaluationExecuted');
  @override
  late final GeneratedColumn<bool> fxRevaluationExecuted =
      GeneratedColumn<bool>(
        'fx_revaluation_executed',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("fx_revaluation_executed" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _fxSkipReasonMeta = const VerificationMeta(
    'fxSkipReason',
  );
  @override
  late final GeneratedColumn<String> fxSkipReason = GeneratedColumn<String>(
    'fx_skip_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fxGainMeta = const VerificationMeta('fxGain');
  @override
  late final GeneratedColumn<double> fxGain = GeneratedColumn<double>(
    'fx_gain',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fxLossMeta = const VerificationMeta('fxLoss');
  @override
  late final GeneratedColumn<double> fxLoss = GeneratedColumn<double>(
    'fx_loss',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _netFxDifferenceMeta = const VerificationMeta(
    'netFxDifference',
  );
  @override
  late final GeneratedColumn<double> netFxDifference = GeneratedColumn<double>(
    'net_fx_difference',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _journalEntryUuidMeta = const VerificationMeta(
    'journalEntryUuid',
  );
  @override
  late final GeneratedColumn<String> journalEntryUuid = GeneratedColumn<String>(
    'journal_entry_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    fiscalYearUuid,
    periodUuid,
    closingDate,
    status,
    fxRevaluationEnabled,
    fxRevaluationExecuted,
    fxSkipReason,
    fxGain,
    fxLoss,
    netFxDifference,
    journalEntryUuid,
    createdBy,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'period_closing_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<PeriodClosingRecordRow> instance, {
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
    if (data.containsKey('fiscal_year_uuid')) {
      context.handle(
        _fiscalYearUuidMeta,
        fiscalYearUuid.isAcceptableOrUnknown(
          data['fiscal_year_uuid']!,
          _fiscalYearUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fiscalYearUuidMeta);
    }
    if (data.containsKey('period_uuid')) {
      context.handle(
        _periodUuidMeta,
        periodUuid.isAcceptableOrUnknown(data['period_uuid']!, _periodUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_periodUuidMeta);
    }
    if (data.containsKey('closing_date')) {
      context.handle(
        _closingDateMeta,
        closingDate.isAcceptableOrUnknown(
          data['closing_date']!,
          _closingDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_closingDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('fx_revaluation_enabled')) {
      context.handle(
        _fxRevaluationEnabledMeta,
        fxRevaluationEnabled.isAcceptableOrUnknown(
          data['fx_revaluation_enabled']!,
          _fxRevaluationEnabledMeta,
        ),
      );
    }
    if (data.containsKey('fx_revaluation_executed')) {
      context.handle(
        _fxRevaluationExecutedMeta,
        fxRevaluationExecuted.isAcceptableOrUnknown(
          data['fx_revaluation_executed']!,
          _fxRevaluationExecutedMeta,
        ),
      );
    }
    if (data.containsKey('fx_skip_reason')) {
      context.handle(
        _fxSkipReasonMeta,
        fxSkipReason.isAcceptableOrUnknown(
          data['fx_skip_reason']!,
          _fxSkipReasonMeta,
        ),
      );
    }
    if (data.containsKey('fx_gain')) {
      context.handle(
        _fxGainMeta,
        fxGain.isAcceptableOrUnknown(data['fx_gain']!, _fxGainMeta),
      );
    }
    if (data.containsKey('fx_loss')) {
      context.handle(
        _fxLossMeta,
        fxLoss.isAcceptableOrUnknown(data['fx_loss']!, _fxLossMeta),
      );
    }
    if (data.containsKey('net_fx_difference')) {
      context.handle(
        _netFxDifferenceMeta,
        netFxDifference.isAcceptableOrUnknown(
          data['net_fx_difference']!,
          _netFxDifferenceMeta,
        ),
      );
    }
    if (data.containsKey('journal_entry_uuid')) {
      context.handle(
        _journalEntryUuidMeta,
        journalEntryUuid.isAcceptableOrUnknown(
          data['journal_entry_uuid']!,
          _journalEntryUuidMeta,
        ),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PeriodClosingRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PeriodClosingRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      fiscalYearUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fiscal_year_uuid'],
      )!,
      periodUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}period_uuid'],
      )!,
      closingDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}closing_date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      fxRevaluationEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}fx_revaluation_enabled'],
      )!,
      fxRevaluationExecuted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}fx_revaluation_executed'],
      )!,
      fxSkipReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fx_skip_reason'],
      ),
      fxGain: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fx_gain'],
      )!,
      fxLoss: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fx_loss'],
      )!,
      netFxDifference: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}net_fx_difference'],
      )!,
      journalEntryUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}journal_entry_uuid'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PeriodClosingRecordsTable createAlias(String alias) {
    return $PeriodClosingRecordsTable(attachedDatabase, alias);
  }
}

class PeriodClosingRecordRow extends DataClass
    implements Insertable<PeriodClosingRecordRow> {
  final int id;
  final String uuid;
  final String fiscalYearUuid;
  final String periodUuid;
  final int closingDate;

  /// `completed` | `failed`
  final String status;
  final bool fxRevaluationEnabled;
  final bool fxRevaluationExecuted;
  final String? fxSkipReason;
  final double fxGain;
  final double fxLoss;
  final double netFxDifference;
  final String? journalEntryUuid;
  final String? createdBy;
  final int createdAt;
  const PeriodClosingRecordRow({
    required this.id,
    required this.uuid,
    required this.fiscalYearUuid,
    required this.periodUuid,
    required this.closingDate,
    required this.status,
    required this.fxRevaluationEnabled,
    required this.fxRevaluationExecuted,
    this.fxSkipReason,
    required this.fxGain,
    required this.fxLoss,
    required this.netFxDifference,
    this.journalEntryUuid,
    this.createdBy,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['fiscal_year_uuid'] = Variable<String>(fiscalYearUuid);
    map['period_uuid'] = Variable<String>(periodUuid);
    map['closing_date'] = Variable<int>(closingDate);
    map['status'] = Variable<String>(status);
    map['fx_revaluation_enabled'] = Variable<bool>(fxRevaluationEnabled);
    map['fx_revaluation_executed'] = Variable<bool>(fxRevaluationExecuted);
    if (!nullToAbsent || fxSkipReason != null) {
      map['fx_skip_reason'] = Variable<String>(fxSkipReason);
    }
    map['fx_gain'] = Variable<double>(fxGain);
    map['fx_loss'] = Variable<double>(fxLoss);
    map['net_fx_difference'] = Variable<double>(netFxDifference);
    if (!nullToAbsent || journalEntryUuid != null) {
      map['journal_entry_uuid'] = Variable<String>(journalEntryUuid);
    }
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  PeriodClosingRecordsCompanion toCompanion(bool nullToAbsent) {
    return PeriodClosingRecordsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      fiscalYearUuid: Value(fiscalYearUuid),
      periodUuid: Value(periodUuid),
      closingDate: Value(closingDate),
      status: Value(status),
      fxRevaluationEnabled: Value(fxRevaluationEnabled),
      fxRevaluationExecuted: Value(fxRevaluationExecuted),
      fxSkipReason: fxSkipReason == null && nullToAbsent
          ? const Value.absent()
          : Value(fxSkipReason),
      fxGain: Value(fxGain),
      fxLoss: Value(fxLoss),
      netFxDifference: Value(netFxDifference),
      journalEntryUuid: journalEntryUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(journalEntryUuid),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      createdAt: Value(createdAt),
    );
  }

  factory PeriodClosingRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeriodClosingRecordRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      fiscalYearUuid: serializer.fromJson<String>(json['fiscalYearUuid']),
      periodUuid: serializer.fromJson<String>(json['periodUuid']),
      closingDate: serializer.fromJson<int>(json['closingDate']),
      status: serializer.fromJson<String>(json['status']),
      fxRevaluationEnabled: serializer.fromJson<bool>(
        json['fxRevaluationEnabled'],
      ),
      fxRevaluationExecuted: serializer.fromJson<bool>(
        json['fxRevaluationExecuted'],
      ),
      fxSkipReason: serializer.fromJson<String?>(json['fxSkipReason']),
      fxGain: serializer.fromJson<double>(json['fxGain']),
      fxLoss: serializer.fromJson<double>(json['fxLoss']),
      netFxDifference: serializer.fromJson<double>(json['netFxDifference']),
      journalEntryUuid: serializer.fromJson<String?>(json['journalEntryUuid']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'fiscalYearUuid': serializer.toJson<String>(fiscalYearUuid),
      'periodUuid': serializer.toJson<String>(periodUuid),
      'closingDate': serializer.toJson<int>(closingDate),
      'status': serializer.toJson<String>(status),
      'fxRevaluationEnabled': serializer.toJson<bool>(fxRevaluationEnabled),
      'fxRevaluationExecuted': serializer.toJson<bool>(fxRevaluationExecuted),
      'fxSkipReason': serializer.toJson<String?>(fxSkipReason),
      'fxGain': serializer.toJson<double>(fxGain),
      'fxLoss': serializer.toJson<double>(fxLoss),
      'netFxDifference': serializer.toJson<double>(netFxDifference),
      'journalEntryUuid': serializer.toJson<String?>(journalEntryUuid),
      'createdBy': serializer.toJson<String?>(createdBy),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  PeriodClosingRecordRow copyWith({
    int? id,
    String? uuid,
    String? fiscalYearUuid,
    String? periodUuid,
    int? closingDate,
    String? status,
    bool? fxRevaluationEnabled,
    bool? fxRevaluationExecuted,
    Value<String?> fxSkipReason = const Value.absent(),
    double? fxGain,
    double? fxLoss,
    double? netFxDifference,
    Value<String?> journalEntryUuid = const Value.absent(),
    Value<String?> createdBy = const Value.absent(),
    int? createdAt,
  }) => PeriodClosingRecordRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    fiscalYearUuid: fiscalYearUuid ?? this.fiscalYearUuid,
    periodUuid: periodUuid ?? this.periodUuid,
    closingDate: closingDate ?? this.closingDate,
    status: status ?? this.status,
    fxRevaluationEnabled: fxRevaluationEnabled ?? this.fxRevaluationEnabled,
    fxRevaluationExecuted: fxRevaluationExecuted ?? this.fxRevaluationExecuted,
    fxSkipReason: fxSkipReason.present ? fxSkipReason.value : this.fxSkipReason,
    fxGain: fxGain ?? this.fxGain,
    fxLoss: fxLoss ?? this.fxLoss,
    netFxDifference: netFxDifference ?? this.netFxDifference,
    journalEntryUuid: journalEntryUuid.present
        ? journalEntryUuid.value
        : this.journalEntryUuid,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    createdAt: createdAt ?? this.createdAt,
  );
  PeriodClosingRecordRow copyWithCompanion(PeriodClosingRecordsCompanion data) {
    return PeriodClosingRecordRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      fiscalYearUuid: data.fiscalYearUuid.present
          ? data.fiscalYearUuid.value
          : this.fiscalYearUuid,
      periodUuid: data.periodUuid.present
          ? data.periodUuid.value
          : this.periodUuid,
      closingDate: data.closingDate.present
          ? data.closingDate.value
          : this.closingDate,
      status: data.status.present ? data.status.value : this.status,
      fxRevaluationEnabled: data.fxRevaluationEnabled.present
          ? data.fxRevaluationEnabled.value
          : this.fxRevaluationEnabled,
      fxRevaluationExecuted: data.fxRevaluationExecuted.present
          ? data.fxRevaluationExecuted.value
          : this.fxRevaluationExecuted,
      fxSkipReason: data.fxSkipReason.present
          ? data.fxSkipReason.value
          : this.fxSkipReason,
      fxGain: data.fxGain.present ? data.fxGain.value : this.fxGain,
      fxLoss: data.fxLoss.present ? data.fxLoss.value : this.fxLoss,
      netFxDifference: data.netFxDifference.present
          ? data.netFxDifference.value
          : this.netFxDifference,
      journalEntryUuid: data.journalEntryUuid.present
          ? data.journalEntryUuid.value
          : this.journalEntryUuid,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeriodClosingRecordRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('fiscalYearUuid: $fiscalYearUuid, ')
          ..write('periodUuid: $periodUuid, ')
          ..write('closingDate: $closingDate, ')
          ..write('status: $status, ')
          ..write('fxRevaluationEnabled: $fxRevaluationEnabled, ')
          ..write('fxRevaluationExecuted: $fxRevaluationExecuted, ')
          ..write('fxSkipReason: $fxSkipReason, ')
          ..write('fxGain: $fxGain, ')
          ..write('fxLoss: $fxLoss, ')
          ..write('netFxDifference: $netFxDifference, ')
          ..write('journalEntryUuid: $journalEntryUuid, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    fiscalYearUuid,
    periodUuid,
    closingDate,
    status,
    fxRevaluationEnabled,
    fxRevaluationExecuted,
    fxSkipReason,
    fxGain,
    fxLoss,
    netFxDifference,
    journalEntryUuid,
    createdBy,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeriodClosingRecordRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.fiscalYearUuid == this.fiscalYearUuid &&
          other.periodUuid == this.periodUuid &&
          other.closingDate == this.closingDate &&
          other.status == this.status &&
          other.fxRevaluationEnabled == this.fxRevaluationEnabled &&
          other.fxRevaluationExecuted == this.fxRevaluationExecuted &&
          other.fxSkipReason == this.fxSkipReason &&
          other.fxGain == this.fxGain &&
          other.fxLoss == this.fxLoss &&
          other.netFxDifference == this.netFxDifference &&
          other.journalEntryUuid == this.journalEntryUuid &&
          other.createdBy == this.createdBy &&
          other.createdAt == this.createdAt);
}

class PeriodClosingRecordsCompanion
    extends UpdateCompanion<PeriodClosingRecordRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> fiscalYearUuid;
  final Value<String> periodUuid;
  final Value<int> closingDate;
  final Value<String> status;
  final Value<bool> fxRevaluationEnabled;
  final Value<bool> fxRevaluationExecuted;
  final Value<String?> fxSkipReason;
  final Value<double> fxGain;
  final Value<double> fxLoss;
  final Value<double> netFxDifference;
  final Value<String?> journalEntryUuid;
  final Value<String?> createdBy;
  final Value<int> createdAt;
  const PeriodClosingRecordsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.fiscalYearUuid = const Value.absent(),
    this.periodUuid = const Value.absent(),
    this.closingDate = const Value.absent(),
    this.status = const Value.absent(),
    this.fxRevaluationEnabled = const Value.absent(),
    this.fxRevaluationExecuted = const Value.absent(),
    this.fxSkipReason = const Value.absent(),
    this.fxGain = const Value.absent(),
    this.fxLoss = const Value.absent(),
    this.netFxDifference = const Value.absent(),
    this.journalEntryUuid = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PeriodClosingRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String fiscalYearUuid,
    required String periodUuid,
    required int closingDate,
    required String status,
    this.fxRevaluationEnabled = const Value.absent(),
    this.fxRevaluationExecuted = const Value.absent(),
    this.fxSkipReason = const Value.absent(),
    this.fxGain = const Value.absent(),
    this.fxLoss = const Value.absent(),
    this.netFxDifference = const Value.absent(),
    this.journalEntryUuid = const Value.absent(),
    this.createdBy = const Value.absent(),
    required int createdAt,
  }) : uuid = Value(uuid),
       fiscalYearUuid = Value(fiscalYearUuid),
       periodUuid = Value(periodUuid),
       closingDate = Value(closingDate),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<PeriodClosingRecordRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? fiscalYearUuid,
    Expression<String>? periodUuid,
    Expression<int>? closingDate,
    Expression<String>? status,
    Expression<bool>? fxRevaluationEnabled,
    Expression<bool>? fxRevaluationExecuted,
    Expression<String>? fxSkipReason,
    Expression<double>? fxGain,
    Expression<double>? fxLoss,
    Expression<double>? netFxDifference,
    Expression<String>? journalEntryUuid,
    Expression<String>? createdBy,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (fiscalYearUuid != null) 'fiscal_year_uuid': fiscalYearUuid,
      if (periodUuid != null) 'period_uuid': periodUuid,
      if (closingDate != null) 'closing_date': closingDate,
      if (status != null) 'status': status,
      if (fxRevaluationEnabled != null)
        'fx_revaluation_enabled': fxRevaluationEnabled,
      if (fxRevaluationExecuted != null)
        'fx_revaluation_executed': fxRevaluationExecuted,
      if (fxSkipReason != null) 'fx_skip_reason': fxSkipReason,
      if (fxGain != null) 'fx_gain': fxGain,
      if (fxLoss != null) 'fx_loss': fxLoss,
      if (netFxDifference != null) 'net_fx_difference': netFxDifference,
      if (journalEntryUuid != null) 'journal_entry_uuid': journalEntryUuid,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PeriodClosingRecordsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? fiscalYearUuid,
    Value<String>? periodUuid,
    Value<int>? closingDate,
    Value<String>? status,
    Value<bool>? fxRevaluationEnabled,
    Value<bool>? fxRevaluationExecuted,
    Value<String?>? fxSkipReason,
    Value<double>? fxGain,
    Value<double>? fxLoss,
    Value<double>? netFxDifference,
    Value<String?>? journalEntryUuid,
    Value<String?>? createdBy,
    Value<int>? createdAt,
  }) {
    return PeriodClosingRecordsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      fiscalYearUuid: fiscalYearUuid ?? this.fiscalYearUuid,
      periodUuid: periodUuid ?? this.periodUuid,
      closingDate: closingDate ?? this.closingDate,
      status: status ?? this.status,
      fxRevaluationEnabled: fxRevaluationEnabled ?? this.fxRevaluationEnabled,
      fxRevaluationExecuted:
          fxRevaluationExecuted ?? this.fxRevaluationExecuted,
      fxSkipReason: fxSkipReason ?? this.fxSkipReason,
      fxGain: fxGain ?? this.fxGain,
      fxLoss: fxLoss ?? this.fxLoss,
      netFxDifference: netFxDifference ?? this.netFxDifference,
      journalEntryUuid: journalEntryUuid ?? this.journalEntryUuid,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
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
    if (fiscalYearUuid.present) {
      map['fiscal_year_uuid'] = Variable<String>(fiscalYearUuid.value);
    }
    if (periodUuid.present) {
      map['period_uuid'] = Variable<String>(periodUuid.value);
    }
    if (closingDate.present) {
      map['closing_date'] = Variable<int>(closingDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (fxRevaluationEnabled.present) {
      map['fx_revaluation_enabled'] = Variable<bool>(
        fxRevaluationEnabled.value,
      );
    }
    if (fxRevaluationExecuted.present) {
      map['fx_revaluation_executed'] = Variable<bool>(
        fxRevaluationExecuted.value,
      );
    }
    if (fxSkipReason.present) {
      map['fx_skip_reason'] = Variable<String>(fxSkipReason.value);
    }
    if (fxGain.present) {
      map['fx_gain'] = Variable<double>(fxGain.value);
    }
    if (fxLoss.present) {
      map['fx_loss'] = Variable<double>(fxLoss.value);
    }
    if (netFxDifference.present) {
      map['net_fx_difference'] = Variable<double>(netFxDifference.value);
    }
    if (journalEntryUuid.present) {
      map['journal_entry_uuid'] = Variable<String>(journalEntryUuid.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeriodClosingRecordsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('fiscalYearUuid: $fiscalYearUuid, ')
          ..write('periodUuid: $periodUuid, ')
          ..write('closingDate: $closingDate, ')
          ..write('status: $status, ')
          ..write('fxRevaluationEnabled: $fxRevaluationEnabled, ')
          ..write('fxRevaluationExecuted: $fxRevaluationExecuted, ')
          ..write('fxSkipReason: $fxSkipReason, ')
          ..write('fxGain: $fxGain, ')
          ..write('fxLoss: $fxLoss, ')
          ..write('netFxDifference: $netFxDifference, ')
          ..write('journalEntryUuid: $journalEntryUuid, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AccountingDatabase extends GeneratedDatabase {
  _$AccountingDatabase(QueryExecutor e) : super(e);
  $AccountingDatabaseManager get managers => $AccountingDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $CurrencyRatesTable currencyRates = $CurrencyRatesTable(this);
  late final $CurrencyRateHistoryTable currencyRateHistory =
      $CurrencyRateHistoryTable(this);
  late final $VoucherBooksTable voucherBooks = $VoucherBooksTable(this);
  late final $JournalEntriesTable journalEntries = $JournalEntriesTable(this);
  late final $JournalLinesTable journalLines = $JournalLinesTable(this);
  late final $FiscalYearsTable fiscalYears = $FiscalYearsTable(this);
  late final $AccountingPeriodsTable accountingPeriods =
      $AccountingPeriodsTable(this);
  late final $PeriodClosingRecordsTable periodClosingRecords =
      $PeriodClosingRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accounts,
    currencyRates,
    currencyRateHistory,
    voucherBooks,
    journalEntries,
    journalLines,
    fiscalYears,
    accountingPeriods,
    periodClosingRecords,
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
typedef $$CurrencyRateHistoryTableCreateCompanionBuilder =
    CurrencyRateHistoryCompanion Function({
      Value<int> id,
      required String currencyCode,
      required int asOfDate,
      required double rateToBase,
      required int createdAt,
      Value<String?> notes,
    });
typedef $$CurrencyRateHistoryTableUpdateCompanionBuilder =
    CurrencyRateHistoryCompanion Function({
      Value<int> id,
      Value<String> currencyCode,
      Value<int> asOfDate,
      Value<double> rateToBase,
      Value<int> createdAt,
      Value<String?> notes,
    });

class $$CurrencyRateHistoryTableFilterComposer
    extends Composer<_$AccountingDatabase, $CurrencyRateHistoryTable> {
  $$CurrencyRateHistoryTableFilterComposer({
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

  ColumnFilters<int> get asOfDate => $composableBuilder(
    column: $table.asOfDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rateToBase => $composableBuilder(
    column: $table.rateToBase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CurrencyRateHistoryTableOrderingComposer
    extends Composer<_$AccountingDatabase, $CurrencyRateHistoryTable> {
  $$CurrencyRateHistoryTableOrderingComposer({
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

  ColumnOrderings<int> get asOfDate => $composableBuilder(
    column: $table.asOfDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rateToBase => $composableBuilder(
    column: $table.rateToBase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CurrencyRateHistoryTableAnnotationComposer
    extends Composer<_$AccountingDatabase, $CurrencyRateHistoryTable> {
  $$CurrencyRateHistoryTableAnnotationComposer({
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

  GeneratedColumn<int> get asOfDate =>
      $composableBuilder(column: $table.asOfDate, builder: (column) => column);

  GeneratedColumn<double> get rateToBase => $composableBuilder(
    column: $table.rateToBase,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$CurrencyRateHistoryTableTableManager
    extends
        RootTableManager<
          _$AccountingDatabase,
          $CurrencyRateHistoryTable,
          CurrencyRateHistoryRow,
          $$CurrencyRateHistoryTableFilterComposer,
          $$CurrencyRateHistoryTableOrderingComposer,
          $$CurrencyRateHistoryTableAnnotationComposer,
          $$CurrencyRateHistoryTableCreateCompanionBuilder,
          $$CurrencyRateHistoryTableUpdateCompanionBuilder,
          (
            CurrencyRateHistoryRow,
            BaseReferences<
              _$AccountingDatabase,
              $CurrencyRateHistoryTable,
              CurrencyRateHistoryRow
            >,
          ),
          CurrencyRateHistoryRow,
          PrefetchHooks Function()
        > {
  $$CurrencyRateHistoryTableTableManager(
    _$AccountingDatabase db,
    $CurrencyRateHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CurrencyRateHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CurrencyRateHistoryTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CurrencyRateHistoryTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<int> asOfDate = const Value.absent(),
                Value<double> rateToBase = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => CurrencyRateHistoryCompanion(
                id: id,
                currencyCode: currencyCode,
                asOfDate: asOfDate,
                rateToBase: rateToBase,
                createdAt: createdAt,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String currencyCode,
                required int asOfDate,
                required double rateToBase,
                required int createdAt,
                Value<String?> notes = const Value.absent(),
              }) => CurrencyRateHistoryCompanion.insert(
                id: id,
                currencyCode: currencyCode,
                asOfDate: asOfDate,
                rateToBase: rateToBase,
                createdAt: createdAt,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CurrencyRateHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AccountingDatabase,
      $CurrencyRateHistoryTable,
      CurrencyRateHistoryRow,
      $$CurrencyRateHistoryTableFilterComposer,
      $$CurrencyRateHistoryTableOrderingComposer,
      $$CurrencyRateHistoryTableAnnotationComposer,
      $$CurrencyRateHistoryTableCreateCompanionBuilder,
      $$CurrencyRateHistoryTableUpdateCompanionBuilder,
      (
        CurrencyRateHistoryRow,
        BaseReferences<
          _$AccountingDatabase,
          $CurrencyRateHistoryTable,
          CurrencyRateHistoryRow
        >,
      ),
      CurrencyRateHistoryRow,
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
typedef $$JournalEntriesTableCreateCompanionBuilder =
    JournalEntriesCompanion Function({
      Value<int> id,
      required String uuid,
      required int entryDate,
      required String voucherNumber,
      required String voucherType,
      Value<String?> description,
      required String currencyCode,
      Value<bool> isPosted,
      Value<String?> sourceType,
      Value<String?> sourceId,
      required int createdAt,
      required int updatedAt,
      Value<String> syncStatus,
      Value<int?> lastSyncedAt,
      Value<int> version,
      Value<int?> deletedAt,
    });
typedef $$JournalEntriesTableUpdateCompanionBuilder =
    JournalEntriesCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<int> entryDate,
      Value<String> voucherNumber,
      Value<String> voucherType,
      Value<String?> description,
      Value<String> currencyCode,
      Value<bool> isPosted,
      Value<String?> sourceType,
      Value<String?> sourceId,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<String> syncStatus,
      Value<int?> lastSyncedAt,
      Value<int> version,
      Value<int?> deletedAt,
    });

class $$JournalEntriesTableFilterComposer
    extends Composer<_$AccountingDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableFilterComposer({
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

  ColumnFilters<int> get entryDate => $composableBuilder(
    column: $table.entryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voucherNumber => $composableBuilder(
    column: $table.voucherNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voucherType => $composableBuilder(
    column: $table.voucherType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPosted => $composableBuilder(
    column: $table.isPosted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
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

class $$JournalEntriesTableOrderingComposer
    extends Composer<_$AccountingDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableOrderingComposer({
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

  ColumnOrderings<int> get entryDate => $composableBuilder(
    column: $table.entryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voucherNumber => $composableBuilder(
    column: $table.voucherNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voucherType => $composableBuilder(
    column: $table.voucherType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPosted => $composableBuilder(
    column: $table.isPosted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
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

class $$JournalEntriesTableAnnotationComposer
    extends Composer<_$AccountingDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableAnnotationComposer({
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

  GeneratedColumn<int> get entryDate =>
      $composableBuilder(column: $table.entryDate, builder: (column) => column);

  GeneratedColumn<String> get voucherNumber => $composableBuilder(
    column: $table.voucherNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get voucherType => $composableBuilder(
    column: $table.voucherType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPosted =>
      $composableBuilder(column: $table.isPosted, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

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

class $$JournalEntriesTableTableManager
    extends
        RootTableManager<
          _$AccountingDatabase,
          $JournalEntriesTable,
          JournalEntryRow,
          $$JournalEntriesTableFilterComposer,
          $$JournalEntriesTableOrderingComposer,
          $$JournalEntriesTableAnnotationComposer,
          $$JournalEntriesTableCreateCompanionBuilder,
          $$JournalEntriesTableUpdateCompanionBuilder,
          (
            JournalEntryRow,
            BaseReferences<
              _$AccountingDatabase,
              $JournalEntriesTable,
              JournalEntryRow
            >,
          ),
          JournalEntryRow,
          PrefetchHooks Function()
        > {
  $$JournalEntriesTableTableManager(
    _$AccountingDatabase db,
    $JournalEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JournalEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> entryDate = const Value.absent(),
                Value<String> voucherNumber = const Value.absent(),
                Value<String> voucherType = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<bool> isPosted = const Value.absent(),
                Value<String?> sourceType = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => JournalEntriesCompanion(
                id: id,
                uuid: uuid,
                entryDate: entryDate,
                voucherNumber: voucherNumber,
                voucherType: voucherType,
                description: description,
                currencyCode: currencyCode,
                isPosted: isPosted,
                sourceType: sourceType,
                sourceId: sourceId,
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
                required int entryDate,
                required String voucherNumber,
                required String voucherType,
                Value<String?> description = const Value.absent(),
                required String currencyCode,
                Value<bool> isPosted = const Value.absent(),
                Value<String?> sourceType = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<String> syncStatus = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => JournalEntriesCompanion.insert(
                id: id,
                uuid: uuid,
                entryDate: entryDate,
                voucherNumber: voucherNumber,
                voucherType: voucherType,
                description: description,
                currencyCode: currencyCode,
                isPosted: isPosted,
                sourceType: sourceType,
                sourceId: sourceId,
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

typedef $$JournalEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AccountingDatabase,
      $JournalEntriesTable,
      JournalEntryRow,
      $$JournalEntriesTableFilterComposer,
      $$JournalEntriesTableOrderingComposer,
      $$JournalEntriesTableAnnotationComposer,
      $$JournalEntriesTableCreateCompanionBuilder,
      $$JournalEntriesTableUpdateCompanionBuilder,
      (
        JournalEntryRow,
        BaseReferences<
          _$AccountingDatabase,
          $JournalEntriesTable,
          JournalEntryRow
        >,
      ),
      JournalEntryRow,
      PrefetchHooks Function()
    >;
typedef $$JournalLinesTableCreateCompanionBuilder =
    JournalLinesCompanion Function({
      Value<int> id,
      required String uuid,
      required String entryUuid,
      required String accountUuid,
      Value<double> debit,
      Value<double> credit,
      Value<double> exchangeRateToBase,
      Value<double> baseDebit,
      Value<double> baseCredit,
      Value<String?> lineDescription,
      required String currencyCode,
      Value<int> sortOrder,
    });
typedef $$JournalLinesTableUpdateCompanionBuilder =
    JournalLinesCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String> entryUuid,
      Value<String> accountUuid,
      Value<double> debit,
      Value<double> credit,
      Value<double> exchangeRateToBase,
      Value<double> baseDebit,
      Value<double> baseCredit,
      Value<String?> lineDescription,
      Value<String> currencyCode,
      Value<int> sortOrder,
    });

class $$JournalLinesTableFilterComposer
    extends Composer<_$AccountingDatabase, $JournalLinesTable> {
  $$JournalLinesTableFilterComposer({
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

  ColumnFilters<String> get entryUuid => $composableBuilder(
    column: $table.entryUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountUuid => $composableBuilder(
    column: $table.accountUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get debit => $composableBuilder(
    column: $table.debit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get credit => $composableBuilder(
    column: $table.credit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get exchangeRateToBase => $composableBuilder(
    column: $table.exchangeRateToBase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get baseDebit => $composableBuilder(
    column: $table.baseDebit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get baseCredit => $composableBuilder(
    column: $table.baseCredit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lineDescription => $composableBuilder(
    column: $table.lineDescription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JournalLinesTableOrderingComposer
    extends Composer<_$AccountingDatabase, $JournalLinesTable> {
  $$JournalLinesTableOrderingComposer({
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

  ColumnOrderings<String> get entryUuid => $composableBuilder(
    column: $table.entryUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountUuid => $composableBuilder(
    column: $table.accountUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get debit => $composableBuilder(
    column: $table.debit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get credit => $composableBuilder(
    column: $table.credit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get exchangeRateToBase => $composableBuilder(
    column: $table.exchangeRateToBase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get baseDebit => $composableBuilder(
    column: $table.baseDebit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get baseCredit => $composableBuilder(
    column: $table.baseCredit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lineDescription => $composableBuilder(
    column: $table.lineDescription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JournalLinesTableAnnotationComposer
    extends Composer<_$AccountingDatabase, $JournalLinesTable> {
  $$JournalLinesTableAnnotationComposer({
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

  GeneratedColumn<String> get entryUuid =>
      $composableBuilder(column: $table.entryUuid, builder: (column) => column);

  GeneratedColumn<String> get accountUuid => $composableBuilder(
    column: $table.accountUuid,
    builder: (column) => column,
  );

  GeneratedColumn<double> get debit =>
      $composableBuilder(column: $table.debit, builder: (column) => column);

  GeneratedColumn<double> get credit =>
      $composableBuilder(column: $table.credit, builder: (column) => column);

  GeneratedColumn<double> get exchangeRateToBase => $composableBuilder(
    column: $table.exchangeRateToBase,
    builder: (column) => column,
  );

  GeneratedColumn<double> get baseDebit =>
      $composableBuilder(column: $table.baseDebit, builder: (column) => column);

  GeneratedColumn<double> get baseCredit => $composableBuilder(
    column: $table.baseCredit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lineDescription => $composableBuilder(
    column: $table.lineDescription,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$JournalLinesTableTableManager
    extends
        RootTableManager<
          _$AccountingDatabase,
          $JournalLinesTable,
          JournalLineRow,
          $$JournalLinesTableFilterComposer,
          $$JournalLinesTableOrderingComposer,
          $$JournalLinesTableAnnotationComposer,
          $$JournalLinesTableCreateCompanionBuilder,
          $$JournalLinesTableUpdateCompanionBuilder,
          (
            JournalLineRow,
            BaseReferences<
              _$AccountingDatabase,
              $JournalLinesTable,
              JournalLineRow
            >,
          ),
          JournalLineRow,
          PrefetchHooks Function()
        > {
  $$JournalLinesTableTableManager(
    _$AccountingDatabase db,
    $JournalLinesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JournalLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> entryUuid = const Value.absent(),
                Value<String> accountUuid = const Value.absent(),
                Value<double> debit = const Value.absent(),
                Value<double> credit = const Value.absent(),
                Value<double> exchangeRateToBase = const Value.absent(),
                Value<double> baseDebit = const Value.absent(),
                Value<double> baseCredit = const Value.absent(),
                Value<String?> lineDescription = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => JournalLinesCompanion(
                id: id,
                uuid: uuid,
                entryUuid: entryUuid,
                accountUuid: accountUuid,
                debit: debit,
                credit: credit,
                exchangeRateToBase: exchangeRateToBase,
                baseDebit: baseDebit,
                baseCredit: baseCredit,
                lineDescription: lineDescription,
                currencyCode: currencyCode,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required String entryUuid,
                required String accountUuid,
                Value<double> debit = const Value.absent(),
                Value<double> credit = const Value.absent(),
                Value<double> exchangeRateToBase = const Value.absent(),
                Value<double> baseDebit = const Value.absent(),
                Value<double> baseCredit = const Value.absent(),
                Value<String?> lineDescription = const Value.absent(),
                required String currencyCode,
                Value<int> sortOrder = const Value.absent(),
              }) => JournalLinesCompanion.insert(
                id: id,
                uuid: uuid,
                entryUuid: entryUuid,
                accountUuid: accountUuid,
                debit: debit,
                credit: credit,
                exchangeRateToBase: exchangeRateToBase,
                baseDebit: baseDebit,
                baseCredit: baseCredit,
                lineDescription: lineDescription,
                currencyCode: currencyCode,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JournalLinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AccountingDatabase,
      $JournalLinesTable,
      JournalLineRow,
      $$JournalLinesTableFilterComposer,
      $$JournalLinesTableOrderingComposer,
      $$JournalLinesTableAnnotationComposer,
      $$JournalLinesTableCreateCompanionBuilder,
      $$JournalLinesTableUpdateCompanionBuilder,
      (
        JournalLineRow,
        BaseReferences<
          _$AccountingDatabase,
          $JournalLinesTable,
          JournalLineRow
        >,
      ),
      JournalLineRow,
      PrefetchHooks Function()
    >;
typedef $$FiscalYearsTableCreateCompanionBuilder =
    FiscalYearsCompanion Function({
      Value<int> id,
      required String uuid,
      required String code,
      required String name,
      required int startDate,
      required int endDate,
      required String status,
      required String baseCurrencyCode,
      required int periodCount,
      Value<String> periodFrequency,
      Value<bool> fxRevaluationEnabled,
      Value<String?> fxGainAccountUuid,
      Value<String?> fxLossAccountUuid,
      required int createdAt,
      required int updatedAt,
      Value<int?> closedAt,
      Value<String?> createdBy,
      Value<String?> closedBy,
    });
typedef $$FiscalYearsTableUpdateCompanionBuilder =
    FiscalYearsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String> code,
      Value<String> name,
      Value<int> startDate,
      Value<int> endDate,
      Value<String> status,
      Value<String> baseCurrencyCode,
      Value<int> periodCount,
      Value<String> periodFrequency,
      Value<bool> fxRevaluationEnabled,
      Value<String?> fxGainAccountUuid,
      Value<String?> fxLossAccountUuid,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> closedAt,
      Value<String?> createdBy,
      Value<String?> closedBy,
    });

class $$FiscalYearsTableFilterComposer
    extends Composer<_$AccountingDatabase, $FiscalYearsTable> {
  $$FiscalYearsTableFilterComposer({
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

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseCurrencyCode => $composableBuilder(
    column: $table.baseCurrencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get periodCount => $composableBuilder(
    column: $table.periodCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get periodFrequency => $composableBuilder(
    column: $table.periodFrequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get fxRevaluationEnabled => $composableBuilder(
    column: $table.fxRevaluationEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fxGainAccountUuid => $composableBuilder(
    column: $table.fxGainAccountUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fxLossAccountUuid => $composableBuilder(
    column: $table.fxLossAccountUuid,
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

  ColumnFilters<int> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get closedBy => $composableBuilder(
    column: $table.closedBy,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FiscalYearsTableOrderingComposer
    extends Composer<_$AccountingDatabase, $FiscalYearsTable> {
  $$FiscalYearsTableOrderingComposer({
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

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseCurrencyCode => $composableBuilder(
    column: $table.baseCurrencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get periodCount => $composableBuilder(
    column: $table.periodCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get periodFrequency => $composableBuilder(
    column: $table.periodFrequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get fxRevaluationEnabled => $composableBuilder(
    column: $table.fxRevaluationEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fxGainAccountUuid => $composableBuilder(
    column: $table.fxGainAccountUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fxLossAccountUuid => $composableBuilder(
    column: $table.fxLossAccountUuid,
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

  ColumnOrderings<int> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get closedBy => $composableBuilder(
    column: $table.closedBy,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FiscalYearsTableAnnotationComposer
    extends Composer<_$AccountingDatabase, $FiscalYearsTable> {
  $$FiscalYearsTableAnnotationComposer({
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

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<int> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get baseCurrencyCode => $composableBuilder(
    column: $table.baseCurrencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get periodCount => $composableBuilder(
    column: $table.periodCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get periodFrequency => $composableBuilder(
    column: $table.periodFrequency,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get fxRevaluationEnabled => $composableBuilder(
    column: $table.fxRevaluationEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fxGainAccountUuid => $composableBuilder(
    column: $table.fxGainAccountUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fxLossAccountUuid => $composableBuilder(
    column: $table.fxLossAccountUuid,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get closedBy =>
      $composableBuilder(column: $table.closedBy, builder: (column) => column);
}

class $$FiscalYearsTableTableManager
    extends
        RootTableManager<
          _$AccountingDatabase,
          $FiscalYearsTable,
          FiscalYearRow,
          $$FiscalYearsTableFilterComposer,
          $$FiscalYearsTableOrderingComposer,
          $$FiscalYearsTableAnnotationComposer,
          $$FiscalYearsTableCreateCompanionBuilder,
          $$FiscalYearsTableUpdateCompanionBuilder,
          (
            FiscalYearRow,
            BaseReferences<
              _$AccountingDatabase,
              $FiscalYearsTable,
              FiscalYearRow
            >,
          ),
          FiscalYearRow,
          PrefetchHooks Function()
        > {
  $$FiscalYearsTableTableManager(
    _$AccountingDatabase db,
    $FiscalYearsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FiscalYearsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FiscalYearsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FiscalYearsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> startDate = const Value.absent(),
                Value<int> endDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> baseCurrencyCode = const Value.absent(),
                Value<int> periodCount = const Value.absent(),
                Value<String> periodFrequency = const Value.absent(),
                Value<bool> fxRevaluationEnabled = const Value.absent(),
                Value<String?> fxGainAccountUuid = const Value.absent(),
                Value<String?> fxLossAccountUuid = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> closedAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<String?> closedBy = const Value.absent(),
              }) => FiscalYearsCompanion(
                id: id,
                uuid: uuid,
                code: code,
                name: name,
                startDate: startDate,
                endDate: endDate,
                status: status,
                baseCurrencyCode: baseCurrencyCode,
                periodCount: periodCount,
                periodFrequency: periodFrequency,
                fxRevaluationEnabled: fxRevaluationEnabled,
                fxGainAccountUuid: fxGainAccountUuid,
                fxLossAccountUuid: fxLossAccountUuid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                closedAt: closedAt,
                createdBy: createdBy,
                closedBy: closedBy,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required String code,
                required String name,
                required int startDate,
                required int endDate,
                required String status,
                required String baseCurrencyCode,
                required int periodCount,
                Value<String> periodFrequency = const Value.absent(),
                Value<bool> fxRevaluationEnabled = const Value.absent(),
                Value<String?> fxGainAccountUuid = const Value.absent(),
                Value<String?> fxLossAccountUuid = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> closedAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<String?> closedBy = const Value.absent(),
              }) => FiscalYearsCompanion.insert(
                id: id,
                uuid: uuid,
                code: code,
                name: name,
                startDate: startDate,
                endDate: endDate,
                status: status,
                baseCurrencyCode: baseCurrencyCode,
                periodCount: periodCount,
                periodFrequency: periodFrequency,
                fxRevaluationEnabled: fxRevaluationEnabled,
                fxGainAccountUuid: fxGainAccountUuid,
                fxLossAccountUuid: fxLossAccountUuid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                closedAt: closedAt,
                createdBy: createdBy,
                closedBy: closedBy,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FiscalYearsTableProcessedTableManager =
    ProcessedTableManager<
      _$AccountingDatabase,
      $FiscalYearsTable,
      FiscalYearRow,
      $$FiscalYearsTableFilterComposer,
      $$FiscalYearsTableOrderingComposer,
      $$FiscalYearsTableAnnotationComposer,
      $$FiscalYearsTableCreateCompanionBuilder,
      $$FiscalYearsTableUpdateCompanionBuilder,
      (
        FiscalYearRow,
        BaseReferences<_$AccountingDatabase, $FiscalYearsTable, FiscalYearRow>,
      ),
      FiscalYearRow,
      PrefetchHooks Function()
    >;
typedef $$AccountingPeriodsTableCreateCompanionBuilder =
    AccountingPeriodsCompanion Function({
      Value<int> id,
      required String uuid,
      required String fiscalYearUuid,
      required int periodNumber,
      required String name,
      required int startDate,
      required int endDate,
      required String status,
      Value<int?> openedAt,
      Value<String?> openedBy,
      Value<int?> closedAt,
      Value<String?> closedBy,
      Value<int?> reopenedAt,
      Value<String?> reopenedBy,
      Value<String?> reopenReason,
    });
typedef $$AccountingPeriodsTableUpdateCompanionBuilder =
    AccountingPeriodsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String> fiscalYearUuid,
      Value<int> periodNumber,
      Value<String> name,
      Value<int> startDate,
      Value<int> endDate,
      Value<String> status,
      Value<int?> openedAt,
      Value<String?> openedBy,
      Value<int?> closedAt,
      Value<String?> closedBy,
      Value<int?> reopenedAt,
      Value<String?> reopenedBy,
      Value<String?> reopenReason,
    });

class $$AccountingPeriodsTableFilterComposer
    extends Composer<_$AccountingDatabase, $AccountingPeriodsTable> {
  $$AccountingPeriodsTableFilterComposer({
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

  ColumnFilters<String> get fiscalYearUuid => $composableBuilder(
    column: $table.fiscalYearUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get periodNumber => $composableBuilder(
    column: $table.periodNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get openedBy => $composableBuilder(
    column: $table.openedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get closedBy => $composableBuilder(
    column: $table.closedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reopenedAt => $composableBuilder(
    column: $table.reopenedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reopenedBy => $composableBuilder(
    column: $table.reopenedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reopenReason => $composableBuilder(
    column: $table.reopenReason,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AccountingPeriodsTableOrderingComposer
    extends Composer<_$AccountingDatabase, $AccountingPeriodsTable> {
  $$AccountingPeriodsTableOrderingComposer({
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

  ColumnOrderings<String> get fiscalYearUuid => $composableBuilder(
    column: $table.fiscalYearUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get periodNumber => $composableBuilder(
    column: $table.periodNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get openedBy => $composableBuilder(
    column: $table.openedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get closedBy => $composableBuilder(
    column: $table.closedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reopenedAt => $composableBuilder(
    column: $table.reopenedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reopenedBy => $composableBuilder(
    column: $table.reopenedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reopenReason => $composableBuilder(
    column: $table.reopenReason,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountingPeriodsTableAnnotationComposer
    extends Composer<_$AccountingDatabase, $AccountingPeriodsTable> {
  $$AccountingPeriodsTableAnnotationComposer({
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

  GeneratedColumn<String> get fiscalYearUuid => $composableBuilder(
    column: $table.fiscalYearUuid,
    builder: (column) => column,
  );

  GeneratedColumn<int> get periodNumber => $composableBuilder(
    column: $table.periodNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<int> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<String> get openedBy =>
      $composableBuilder(column: $table.openedBy, builder: (column) => column);

  GeneratedColumn<int> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  GeneratedColumn<String> get closedBy =>
      $composableBuilder(column: $table.closedBy, builder: (column) => column);

  GeneratedColumn<int> get reopenedAt => $composableBuilder(
    column: $table.reopenedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reopenedBy => $composableBuilder(
    column: $table.reopenedBy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reopenReason => $composableBuilder(
    column: $table.reopenReason,
    builder: (column) => column,
  );
}

class $$AccountingPeriodsTableTableManager
    extends
        RootTableManager<
          _$AccountingDatabase,
          $AccountingPeriodsTable,
          AccountingPeriodRow,
          $$AccountingPeriodsTableFilterComposer,
          $$AccountingPeriodsTableOrderingComposer,
          $$AccountingPeriodsTableAnnotationComposer,
          $$AccountingPeriodsTableCreateCompanionBuilder,
          $$AccountingPeriodsTableUpdateCompanionBuilder,
          (
            AccountingPeriodRow,
            BaseReferences<
              _$AccountingDatabase,
              $AccountingPeriodsTable,
              AccountingPeriodRow
            >,
          ),
          AccountingPeriodRow,
          PrefetchHooks Function()
        > {
  $$AccountingPeriodsTableTableManager(
    _$AccountingDatabase db,
    $AccountingPeriodsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountingPeriodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountingPeriodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountingPeriodsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> fiscalYearUuid = const Value.absent(),
                Value<int> periodNumber = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> startDate = const Value.absent(),
                Value<int> endDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> openedAt = const Value.absent(),
                Value<String?> openedBy = const Value.absent(),
                Value<int?> closedAt = const Value.absent(),
                Value<String?> closedBy = const Value.absent(),
                Value<int?> reopenedAt = const Value.absent(),
                Value<String?> reopenedBy = const Value.absent(),
                Value<String?> reopenReason = const Value.absent(),
              }) => AccountingPeriodsCompanion(
                id: id,
                uuid: uuid,
                fiscalYearUuid: fiscalYearUuid,
                periodNumber: periodNumber,
                name: name,
                startDate: startDate,
                endDate: endDate,
                status: status,
                openedAt: openedAt,
                openedBy: openedBy,
                closedAt: closedAt,
                closedBy: closedBy,
                reopenedAt: reopenedAt,
                reopenedBy: reopenedBy,
                reopenReason: reopenReason,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required String fiscalYearUuid,
                required int periodNumber,
                required String name,
                required int startDate,
                required int endDate,
                required String status,
                Value<int?> openedAt = const Value.absent(),
                Value<String?> openedBy = const Value.absent(),
                Value<int?> closedAt = const Value.absent(),
                Value<String?> closedBy = const Value.absent(),
                Value<int?> reopenedAt = const Value.absent(),
                Value<String?> reopenedBy = const Value.absent(),
                Value<String?> reopenReason = const Value.absent(),
              }) => AccountingPeriodsCompanion.insert(
                id: id,
                uuid: uuid,
                fiscalYearUuid: fiscalYearUuid,
                periodNumber: periodNumber,
                name: name,
                startDate: startDate,
                endDate: endDate,
                status: status,
                openedAt: openedAt,
                openedBy: openedBy,
                closedAt: closedAt,
                closedBy: closedBy,
                reopenedAt: reopenedAt,
                reopenedBy: reopenedBy,
                reopenReason: reopenReason,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AccountingPeriodsTableProcessedTableManager =
    ProcessedTableManager<
      _$AccountingDatabase,
      $AccountingPeriodsTable,
      AccountingPeriodRow,
      $$AccountingPeriodsTableFilterComposer,
      $$AccountingPeriodsTableOrderingComposer,
      $$AccountingPeriodsTableAnnotationComposer,
      $$AccountingPeriodsTableCreateCompanionBuilder,
      $$AccountingPeriodsTableUpdateCompanionBuilder,
      (
        AccountingPeriodRow,
        BaseReferences<
          _$AccountingDatabase,
          $AccountingPeriodsTable,
          AccountingPeriodRow
        >,
      ),
      AccountingPeriodRow,
      PrefetchHooks Function()
    >;
typedef $$PeriodClosingRecordsTableCreateCompanionBuilder =
    PeriodClosingRecordsCompanion Function({
      Value<int> id,
      required String uuid,
      required String fiscalYearUuid,
      required String periodUuid,
      required int closingDate,
      required String status,
      Value<bool> fxRevaluationEnabled,
      Value<bool> fxRevaluationExecuted,
      Value<String?> fxSkipReason,
      Value<double> fxGain,
      Value<double> fxLoss,
      Value<double> netFxDifference,
      Value<String?> journalEntryUuid,
      Value<String?> createdBy,
      required int createdAt,
    });
typedef $$PeriodClosingRecordsTableUpdateCompanionBuilder =
    PeriodClosingRecordsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String> fiscalYearUuid,
      Value<String> periodUuid,
      Value<int> closingDate,
      Value<String> status,
      Value<bool> fxRevaluationEnabled,
      Value<bool> fxRevaluationExecuted,
      Value<String?> fxSkipReason,
      Value<double> fxGain,
      Value<double> fxLoss,
      Value<double> netFxDifference,
      Value<String?> journalEntryUuid,
      Value<String?> createdBy,
      Value<int> createdAt,
    });

class $$PeriodClosingRecordsTableFilterComposer
    extends Composer<_$AccountingDatabase, $PeriodClosingRecordsTable> {
  $$PeriodClosingRecordsTableFilterComposer({
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

  ColumnFilters<String> get fiscalYearUuid => $composableBuilder(
    column: $table.fiscalYearUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get periodUuid => $composableBuilder(
    column: $table.periodUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get closingDate => $composableBuilder(
    column: $table.closingDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get fxRevaluationEnabled => $composableBuilder(
    column: $table.fxRevaluationEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get fxRevaluationExecuted => $composableBuilder(
    column: $table.fxRevaluationExecuted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fxSkipReason => $composableBuilder(
    column: $table.fxSkipReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fxGain => $composableBuilder(
    column: $table.fxGain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fxLoss => $composableBuilder(
    column: $table.fxLoss,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get netFxDifference => $composableBuilder(
    column: $table.netFxDifference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get journalEntryUuid => $composableBuilder(
    column: $table.journalEntryUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PeriodClosingRecordsTableOrderingComposer
    extends Composer<_$AccountingDatabase, $PeriodClosingRecordsTable> {
  $$PeriodClosingRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get fiscalYearUuid => $composableBuilder(
    column: $table.fiscalYearUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get periodUuid => $composableBuilder(
    column: $table.periodUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get closingDate => $composableBuilder(
    column: $table.closingDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get fxRevaluationEnabled => $composableBuilder(
    column: $table.fxRevaluationEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get fxRevaluationExecuted => $composableBuilder(
    column: $table.fxRevaluationExecuted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fxSkipReason => $composableBuilder(
    column: $table.fxSkipReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fxGain => $composableBuilder(
    column: $table.fxGain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fxLoss => $composableBuilder(
    column: $table.fxLoss,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get netFxDifference => $composableBuilder(
    column: $table.netFxDifference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get journalEntryUuid => $composableBuilder(
    column: $table.journalEntryUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PeriodClosingRecordsTableAnnotationComposer
    extends Composer<_$AccountingDatabase, $PeriodClosingRecordsTable> {
  $$PeriodClosingRecordsTableAnnotationComposer({
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

  GeneratedColumn<String> get fiscalYearUuid => $composableBuilder(
    column: $table.fiscalYearUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get periodUuid => $composableBuilder(
    column: $table.periodUuid,
    builder: (column) => column,
  );

  GeneratedColumn<int> get closingDate => $composableBuilder(
    column: $table.closingDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get fxRevaluationEnabled => $composableBuilder(
    column: $table.fxRevaluationEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get fxRevaluationExecuted => $composableBuilder(
    column: $table.fxRevaluationExecuted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fxSkipReason => $composableBuilder(
    column: $table.fxSkipReason,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fxGain =>
      $composableBuilder(column: $table.fxGain, builder: (column) => column);

  GeneratedColumn<double> get fxLoss =>
      $composableBuilder(column: $table.fxLoss, builder: (column) => column);

  GeneratedColumn<double> get netFxDifference => $composableBuilder(
    column: $table.netFxDifference,
    builder: (column) => column,
  );

  GeneratedColumn<String> get journalEntryUuid => $composableBuilder(
    column: $table.journalEntryUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PeriodClosingRecordsTableTableManager
    extends
        RootTableManager<
          _$AccountingDatabase,
          $PeriodClosingRecordsTable,
          PeriodClosingRecordRow,
          $$PeriodClosingRecordsTableFilterComposer,
          $$PeriodClosingRecordsTableOrderingComposer,
          $$PeriodClosingRecordsTableAnnotationComposer,
          $$PeriodClosingRecordsTableCreateCompanionBuilder,
          $$PeriodClosingRecordsTableUpdateCompanionBuilder,
          (
            PeriodClosingRecordRow,
            BaseReferences<
              _$AccountingDatabase,
              $PeriodClosingRecordsTable,
              PeriodClosingRecordRow
            >,
          ),
          PeriodClosingRecordRow,
          PrefetchHooks Function()
        > {
  $$PeriodClosingRecordsTableTableManager(
    _$AccountingDatabase db,
    $PeriodClosingRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeriodClosingRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeriodClosingRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PeriodClosingRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> fiscalYearUuid = const Value.absent(),
                Value<String> periodUuid = const Value.absent(),
                Value<int> closingDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> fxRevaluationEnabled = const Value.absent(),
                Value<bool> fxRevaluationExecuted = const Value.absent(),
                Value<String?> fxSkipReason = const Value.absent(),
                Value<double> fxGain = const Value.absent(),
                Value<double> fxLoss = const Value.absent(),
                Value<double> netFxDifference = const Value.absent(),
                Value<String?> journalEntryUuid = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => PeriodClosingRecordsCompanion(
                id: id,
                uuid: uuid,
                fiscalYearUuid: fiscalYearUuid,
                periodUuid: periodUuid,
                closingDate: closingDate,
                status: status,
                fxRevaluationEnabled: fxRevaluationEnabled,
                fxRevaluationExecuted: fxRevaluationExecuted,
                fxSkipReason: fxSkipReason,
                fxGain: fxGain,
                fxLoss: fxLoss,
                netFxDifference: netFxDifference,
                journalEntryUuid: journalEntryUuid,
                createdBy: createdBy,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required String fiscalYearUuid,
                required String periodUuid,
                required int closingDate,
                required String status,
                Value<bool> fxRevaluationEnabled = const Value.absent(),
                Value<bool> fxRevaluationExecuted = const Value.absent(),
                Value<String?> fxSkipReason = const Value.absent(),
                Value<double> fxGain = const Value.absent(),
                Value<double> fxLoss = const Value.absent(),
                Value<double> netFxDifference = const Value.absent(),
                Value<String?> journalEntryUuid = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                required int createdAt,
              }) => PeriodClosingRecordsCompanion.insert(
                id: id,
                uuid: uuid,
                fiscalYearUuid: fiscalYearUuid,
                periodUuid: periodUuid,
                closingDate: closingDate,
                status: status,
                fxRevaluationEnabled: fxRevaluationEnabled,
                fxRevaluationExecuted: fxRevaluationExecuted,
                fxSkipReason: fxSkipReason,
                fxGain: fxGain,
                fxLoss: fxLoss,
                netFxDifference: netFxDifference,
                journalEntryUuid: journalEntryUuid,
                createdBy: createdBy,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PeriodClosingRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AccountingDatabase,
      $PeriodClosingRecordsTable,
      PeriodClosingRecordRow,
      $$PeriodClosingRecordsTableFilterComposer,
      $$PeriodClosingRecordsTableOrderingComposer,
      $$PeriodClosingRecordsTableAnnotationComposer,
      $$PeriodClosingRecordsTableCreateCompanionBuilder,
      $$PeriodClosingRecordsTableUpdateCompanionBuilder,
      (
        PeriodClosingRecordRow,
        BaseReferences<
          _$AccountingDatabase,
          $PeriodClosingRecordsTable,
          PeriodClosingRecordRow
        >,
      ),
      PeriodClosingRecordRow,
      PrefetchHooks Function()
    >;

class $AccountingDatabaseManager {
  final _$AccountingDatabase _db;
  $AccountingDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$CurrencyRatesTableTableManager get currencyRates =>
      $$CurrencyRatesTableTableManager(_db, _db.currencyRates);
  $$CurrencyRateHistoryTableTableManager get currencyRateHistory =>
      $$CurrencyRateHistoryTableTableManager(_db, _db.currencyRateHistory);
  $$VoucherBooksTableTableManager get voucherBooks =>
      $$VoucherBooksTableTableManager(_db, _db.voucherBooks);
  $$JournalEntriesTableTableManager get journalEntries =>
      $$JournalEntriesTableTableManager(_db, _db.journalEntries);
  $$JournalLinesTableTableManager get journalLines =>
      $$JournalLinesTableTableManager(_db, _db.journalLines);
  $$FiscalYearsTableTableManager get fiscalYears =>
      $$FiscalYearsTableTableManager(_db, _db.fiscalYears);
  $$AccountingPeriodsTableTableManager get accountingPeriods =>
      $$AccountingPeriodsTableTableManager(_db, _db.accountingPeriods);
  $$PeriodClosingRecordsTableTableManager get periodClosingRecords =>
      $$PeriodClosingRecordsTableTableManager(_db, _db.periodClosingRecords);
}
