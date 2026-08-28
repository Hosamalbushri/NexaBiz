// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_database.dart';

// ignore_for_file: type=lint
class $ProductsTable extends Products
    with TableInfo<$ProductsTable, ProductRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _itemCodeMeta = const VerificationMeta(
    'itemCode',
  );
  @override
  late final GeneratedColumn<String> itemCode = GeneratedColumn<String>(
    'item_code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 128,
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
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _packSizeMeta = const VerificationMeta(
    'packSize',
  );
  @override
  late final GeneratedColumn<int> packSize = GeneratedColumn<int>(
    'pack_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _onHandQtyMeta = const VerificationMeta(
    'onHandQty',
  );
  @override
  late final GeneratedColumn<double> onHandQty = GeneratedColumn<double>(
    'on_hand_qty',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _unitCostMeta = const VerificationMeta(
    'unitCost',
  );
  @override
  late final GeneratedColumn<double> unitCost = GeneratedColumn<double>(
    'unit_cost',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    itemCode,
    name,
    barcode,
    packSize,
    price,
    onHandQty,
    unitCost,
    createdAt,
    updatedAt,
    syncStatus,
    lastSyncedAt,
    version,
    companyId,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductRow> instance, {
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
    if (data.containsKey('item_code')) {
      context.handle(
        _itemCodeMeta,
        itemCode.isAcceptableOrUnknown(data['item_code']!, _itemCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_itemCodeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('pack_size')) {
      context.handle(
        _packSizeMeta,
        packSize.isAcceptableOrUnknown(data['pack_size']!, _packSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_packSizeMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('on_hand_qty')) {
      context.handle(
        _onHandQtyMeta,
        onHandQty.isAcceptableOrUnknown(data['on_hand_qty']!, _onHandQtyMeta),
      );
    }
    if (data.containsKey('unit_cost')) {
      context.handle(
        _unitCostMeta,
        unitCost.isAcceptableOrUnknown(data['unit_cost']!, _unitCostMeta),
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
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
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
  ProductRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      itemCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      packSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pack_size'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      )!,
      onHandQty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}on_hand_qty'],
      )!,
      unitCost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_cost'],
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
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class ProductRow extends DataClass implements Insertable<ProductRow> {
  final int id;

  /// Client-generated UUID for offline-safe identity / sync.
  final String uuid;
  final String itemCode;
  final String name;
  final String? barcode;
  final int packSize;
  final double price;

  /// Perpetual inventory: sellable quantity on hand (main-unit equivalents).
  final double onHandQty;

  /// Unit cost for COGS (company base currency per main unit).
  final double unitCost;
  final int createdAt;
  final int updatedAt;

  /// [SyncStatus.name] string.
  final String syncStatus;
  final int? lastSyncedAt;
  final int version;

  /// Company / Tenant owner ID for local multi-tenant data isolation.
  final String? companyId;

  /// Soft-delete tombstone (UTC epoch ms). Null = active.
  final int? deletedAt;
  const ProductRow({
    required this.id,
    required this.uuid,
    required this.itemCode,
    required this.name,
    this.barcode,
    required this.packSize,
    required this.price,
    required this.onHandQty,
    required this.unitCost,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.lastSyncedAt,
    required this.version,
    this.companyId,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['item_code'] = Variable<String>(itemCode);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['pack_size'] = Variable<int>(packSize);
    map['price'] = Variable<double>(price);
    map['on_hand_qty'] = Variable<double>(onHandQty);
    map['unit_cost'] = Variable<double>(unitCost);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt);
    }
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || companyId != null) {
      map['company_id'] = Variable<String>(companyId);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      itemCode: Value(itemCode),
      name: Value(name),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      packSize: Value(packSize),
      price: Value(price),
      onHandQty: Value(onHandQty),
      unitCost: Value(unitCost),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      version: Value(version),
      companyId: companyId == null && nullToAbsent
          ? const Value.absent()
          : Value(companyId),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory ProductRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      itemCode: serializer.fromJson<String>(json['itemCode']),
      name: serializer.fromJson<String>(json['name']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      packSize: serializer.fromJson<int>(json['packSize']),
      price: serializer.fromJson<double>(json['price']),
      onHandQty: serializer.fromJson<double>(json['onHandQty']),
      unitCost: serializer.fromJson<double>(json['unitCost']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      lastSyncedAt: serializer.fromJson<int?>(json['lastSyncedAt']),
      version: serializer.fromJson<int>(json['version']),
      companyId: serializer.fromJson<String?>(json['companyId']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'itemCode': serializer.toJson<String>(itemCode),
      'name': serializer.toJson<String>(name),
      'barcode': serializer.toJson<String?>(barcode),
      'packSize': serializer.toJson<int>(packSize),
      'price': serializer.toJson<double>(price),
      'onHandQty': serializer.toJson<double>(onHandQty),
      'unitCost': serializer.toJson<double>(unitCost),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'lastSyncedAt': serializer.toJson<int?>(lastSyncedAt),
      'version': serializer.toJson<int>(version),
      'companyId': serializer.toJson<String?>(companyId),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  ProductRow copyWith({
    int? id,
    String? uuid,
    String? itemCode,
    String? name,
    Value<String?> barcode = const Value.absent(),
    int? packSize,
    double? price,
    double? onHandQty,
    double? unitCost,
    int? createdAt,
    int? updatedAt,
    String? syncStatus,
    Value<int?> lastSyncedAt = const Value.absent(),
    int? version,
    Value<String?> companyId = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
  }) => ProductRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    itemCode: itemCode ?? this.itemCode,
    name: name ?? this.name,
    barcode: barcode.present ? barcode.value : this.barcode,
    packSize: packSize ?? this.packSize,
    price: price ?? this.price,
    onHandQty: onHandQty ?? this.onHandQty,
    unitCost: unitCost ?? this.unitCost,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    version: version ?? this.version,
    companyId: companyId.present ? companyId.value : this.companyId,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  ProductRow copyWithCompanion(ProductsCompanion data) {
    return ProductRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      itemCode: data.itemCode.present ? data.itemCode.value : this.itemCode,
      name: data.name.present ? data.name.value : this.name,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      packSize: data.packSize.present ? data.packSize.value : this.packSize,
      price: data.price.present ? data.price.value : this.price,
      onHandQty: data.onHandQty.present ? data.onHandQty.value : this.onHandQty,
      unitCost: data.unitCost.present ? data.unitCost.value : this.unitCost,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      version: data.version.present ? data.version.value : this.version,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('itemCode: $itemCode, ')
          ..write('name: $name, ')
          ..write('barcode: $barcode, ')
          ..write('packSize: $packSize, ')
          ..write('price: $price, ')
          ..write('onHandQty: $onHandQty, ')
          ..write('unitCost: $unitCost, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('version: $version, ')
          ..write('companyId: $companyId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    itemCode,
    name,
    barcode,
    packSize,
    price,
    onHandQty,
    unitCost,
    createdAt,
    updatedAt,
    syncStatus,
    lastSyncedAt,
    version,
    companyId,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.itemCode == this.itemCode &&
          other.name == this.name &&
          other.barcode == this.barcode &&
          other.packSize == this.packSize &&
          other.price == this.price &&
          other.onHandQty == this.onHandQty &&
          other.unitCost == this.unitCost &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.version == this.version &&
          other.companyId == this.companyId &&
          other.deletedAt == this.deletedAt);
}

class ProductsCompanion extends UpdateCompanion<ProductRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> itemCode;
  final Value<String> name;
  final Value<String?> barcode;
  final Value<int> packSize;
  final Value<double> price;
  final Value<double> onHandQty;
  final Value<double> unitCost;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> syncStatus;
  final Value<int?> lastSyncedAt;
  final Value<int> version;
  final Value<String?> companyId;
  final Value<int?> deletedAt;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.itemCode = const Value.absent(),
    this.name = const Value.absent(),
    this.barcode = const Value.absent(),
    this.packSize = const Value.absent(),
    this.price = const Value.absent(),
    this.onHandQty = const Value.absent(),
    this.unitCost = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.companyId = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  ProductsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String itemCode,
    required String name,
    this.barcode = const Value.absent(),
    required int packSize,
    required double price,
    this.onHandQty = const Value.absent(),
    this.unitCost = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.companyId = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : uuid = Value(uuid),
       itemCode = Value(itemCode),
       name = Value(name),
       packSize = Value(packSize),
       price = Value(price),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ProductRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? itemCode,
    Expression<String>? name,
    Expression<String>? barcode,
    Expression<int>? packSize,
    Expression<double>? price,
    Expression<double>? onHandQty,
    Expression<double>? unitCost,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? syncStatus,
    Expression<int>? lastSyncedAt,
    Expression<int>? version,
    Expression<String>? companyId,
    Expression<int>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (itemCode != null) 'item_code': itemCode,
      if (name != null) 'name': name,
      if (barcode != null) 'barcode': barcode,
      if (packSize != null) 'pack_size': packSize,
      if (price != null) 'price': price,
      if (onHandQty != null) 'on_hand_qty': onHandQty,
      if (unitCost != null) 'unit_cost': unitCost,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (version != null) 'version': version,
      if (companyId != null) 'company_id': companyId,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  ProductsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? itemCode,
    Value<String>? name,
    Value<String?>? barcode,
    Value<int>? packSize,
    Value<double>? price,
    Value<double>? onHandQty,
    Value<double>? unitCost,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? syncStatus,
    Value<int?>? lastSyncedAt,
    Value<int>? version,
    Value<String?>? companyId,
    Value<int?>? deletedAt,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      itemCode: itemCode ?? this.itemCode,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      packSize: packSize ?? this.packSize,
      price: price ?? this.price,
      onHandQty: onHandQty ?? this.onHandQty,
      unitCost: unitCost ?? this.unitCost,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      version: version ?? this.version,
      companyId: companyId ?? this.companyId,
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
    if (itemCode.present) {
      map['item_code'] = Variable<String>(itemCode.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (packSize.present) {
      map['pack_size'] = Variable<int>(packSize.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (onHandQty.present) {
      map['on_hand_qty'] = Variable<double>(onHandQty.value);
    }
    if (unitCost.present) {
      map['unit_cost'] = Variable<double>(unitCost.value);
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
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('itemCode: $itemCode, ')
          ..write('name: $name, ')
          ..write('barcode: $barcode, ')
          ..write('packSize: $packSize, ')
          ..write('price: $price, ')
          ..write('onHandQty: $onHandQty, ')
          ..write('unitCost: $unitCost, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('version: $version, ')
          ..write('companyId: $companyId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $StockReceiptsTable extends StockReceipts
    with TableInfo<$StockReceiptsTable, StockReceiptRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockReceiptsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _receiptNumberMeta = const VerificationMeta(
    'receiptNumber',
  );
  @override
  late final GeneratedColumn<String> receiptNumber = GeneratedColumn<String>(
    'receipt_number',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 128,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _supplierMeta = const VerificationMeta(
    'supplier',
  );
  @override
  late final GeneratedColumn<String> supplier = GeneratedColumn<String>(
    'supplier',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountNameMeta = const VerificationMeta(
    'accountName',
  );
  @override
  late final GeneratedColumn<String> accountName = GeneratedColumn<String>(
    'account_name',
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
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('YER'),
  );
  static const VerificationMeta _exchangeRateMeta = const VerificationMeta(
    'exchangeRate',
  );
  @override
  late final GeneratedColumn<double> exchangeRate = GeneratedColumn<double>(
    'exchange_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
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
  static const VerificationMeta _receiptDateMeta = const VerificationMeta(
    'receiptDate',
  );
  @override
  late final GeneratedColumn<int> receiptDate = GeneratedColumn<int>(
    'receipt_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
  );
  static const VerificationMeta _postedAtMeta = const VerificationMeta(
    'postedAt',
  );
  @override
  late final GeneratedColumn<int> postedAt = GeneratedColumn<int>(
    'posted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
    receiptNumber,
    supplier,
    accountId,
    accountName,
    currencyCode,
    exchangeRate,
    notes,
    receiptDate,
    createdAt,
    updatedAt,
    syncStatus,
    lastSyncedAt,
    version,
    companyId,
    status,
    postedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_receipts';
  @override
  VerificationContext validateIntegrity(
    Insertable<StockReceiptRow> instance, {
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
    if (data.containsKey('receipt_number')) {
      context.handle(
        _receiptNumberMeta,
        receiptNumber.isAcceptableOrUnknown(
          data['receipt_number']!,
          _receiptNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_receiptNumberMeta);
    }
    if (data.containsKey('supplier')) {
      context.handle(
        _supplierMeta,
        supplier.isAcceptableOrUnknown(data['supplier']!, _supplierMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('account_name')) {
      context.handle(
        _accountNameMeta,
        accountName.isAcceptableOrUnknown(
          data['account_name']!,
          _accountNameMeta,
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
    }
    if (data.containsKey('exchange_rate')) {
      context.handle(
        _exchangeRateMeta,
        exchangeRate.isAcceptableOrUnknown(
          data['exchange_rate']!,
          _exchangeRateMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('receipt_date')) {
      context.handle(
        _receiptDateMeta,
        receiptDate.isAcceptableOrUnknown(
          data['receipt_date']!,
          _receiptDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_receiptDateMeta);
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
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('posted_at')) {
      context.handle(
        _postedAtMeta,
        postedAt.isAcceptableOrUnknown(data['posted_at']!, _postedAtMeta),
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
  StockReceiptRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockReceiptRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      receiptNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_number'],
      )!,
      supplier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supplier'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      accountName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_name'],
      ),
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      exchangeRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}exchange_rate'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      receiptDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}receipt_date'],
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
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      postedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}posted_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $StockReceiptsTable createAlias(String alias) {
    return $StockReceiptsTable(attachedDatabase, alias);
  }
}

class StockReceiptRow extends DataClass implements Insertable<StockReceiptRow> {
  final int id;

  /// Client-generated UUID for offline-safe identity / sync.
  final String uuid;
  final String receiptNumber;
  final String? supplier;
  final String? accountId;
  final String? accountName;
  final String currencyCode;
  final double exchangeRate;
  final String? notes;
  final int receiptDate;
  final int createdAt;
  final int updatedAt;

  /// [SyncStatus.name] string.
  final String syncStatus;
  final int? lastSyncedAt;
  final int version;

  /// Company / Tenant owner ID for local multi-tenant data isolation.
  final String? companyId;

  /// Document posting status ('draft', 'posted', 'cancelled')
  final String status;

  /// Epoch UTC timestamp when the document was posted
  final int? postedAt;

  /// Soft-delete tombstone (UTC epoch ms). Null = active.
  final int? deletedAt;
  const StockReceiptRow({
    required this.id,
    required this.uuid,
    required this.receiptNumber,
    this.supplier,
    this.accountId,
    this.accountName,
    required this.currencyCode,
    required this.exchangeRate,
    this.notes,
    required this.receiptDate,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.lastSyncedAt,
    required this.version,
    this.companyId,
    required this.status,
    this.postedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['receipt_number'] = Variable<String>(receiptNumber);
    if (!nullToAbsent || supplier != null) {
      map['supplier'] = Variable<String>(supplier);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    if (!nullToAbsent || accountName != null) {
      map['account_name'] = Variable<String>(accountName);
    }
    map['currency_code'] = Variable<String>(currencyCode);
    map['exchange_rate'] = Variable<double>(exchangeRate);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['receipt_date'] = Variable<int>(receiptDate);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt);
    }
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || companyId != null) {
      map['company_id'] = Variable<String>(companyId);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || postedAt != null) {
      map['posted_at'] = Variable<int>(postedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  StockReceiptsCompanion toCompanion(bool nullToAbsent) {
    return StockReceiptsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      receiptNumber: Value(receiptNumber),
      supplier: supplier == null && nullToAbsent
          ? const Value.absent()
          : Value(supplier),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      accountName: accountName == null && nullToAbsent
          ? const Value.absent()
          : Value(accountName),
      currencyCode: Value(currencyCode),
      exchangeRate: Value(exchangeRate),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      receiptDate: Value(receiptDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      version: Value(version),
      companyId: companyId == null && nullToAbsent
          ? const Value.absent()
          : Value(companyId),
      status: Value(status),
      postedAt: postedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(postedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory StockReceiptRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockReceiptRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      receiptNumber: serializer.fromJson<String>(json['receiptNumber']),
      supplier: serializer.fromJson<String?>(json['supplier']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      accountName: serializer.fromJson<String?>(json['accountName']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      exchangeRate: serializer.fromJson<double>(json['exchangeRate']),
      notes: serializer.fromJson<String?>(json['notes']),
      receiptDate: serializer.fromJson<int>(json['receiptDate']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      lastSyncedAt: serializer.fromJson<int?>(json['lastSyncedAt']),
      version: serializer.fromJson<int>(json['version']),
      companyId: serializer.fromJson<String?>(json['companyId']),
      status: serializer.fromJson<String>(json['status']),
      postedAt: serializer.fromJson<int?>(json['postedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'receiptNumber': serializer.toJson<String>(receiptNumber),
      'supplier': serializer.toJson<String?>(supplier),
      'accountId': serializer.toJson<String?>(accountId),
      'accountName': serializer.toJson<String?>(accountName),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'exchangeRate': serializer.toJson<double>(exchangeRate),
      'notes': serializer.toJson<String?>(notes),
      'receiptDate': serializer.toJson<int>(receiptDate),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'lastSyncedAt': serializer.toJson<int?>(lastSyncedAt),
      'version': serializer.toJson<int>(version),
      'companyId': serializer.toJson<String?>(companyId),
      'status': serializer.toJson<String>(status),
      'postedAt': serializer.toJson<int?>(postedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  StockReceiptRow copyWith({
    int? id,
    String? uuid,
    String? receiptNumber,
    Value<String?> supplier = const Value.absent(),
    Value<String?> accountId = const Value.absent(),
    Value<String?> accountName = const Value.absent(),
    String? currencyCode,
    double? exchangeRate,
    Value<String?> notes = const Value.absent(),
    int? receiptDate,
    int? createdAt,
    int? updatedAt,
    String? syncStatus,
    Value<int?> lastSyncedAt = const Value.absent(),
    int? version,
    Value<String?> companyId = const Value.absent(),
    String? status,
    Value<int?> postedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
  }) => StockReceiptRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    receiptNumber: receiptNumber ?? this.receiptNumber,
    supplier: supplier.present ? supplier.value : this.supplier,
    accountId: accountId.present ? accountId.value : this.accountId,
    accountName: accountName.present ? accountName.value : this.accountName,
    currencyCode: currencyCode ?? this.currencyCode,
    exchangeRate: exchangeRate ?? this.exchangeRate,
    notes: notes.present ? notes.value : this.notes,
    receiptDate: receiptDate ?? this.receiptDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    version: version ?? this.version,
    companyId: companyId.present ? companyId.value : this.companyId,
    status: status ?? this.status,
    postedAt: postedAt.present ? postedAt.value : this.postedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  StockReceiptRow copyWithCompanion(StockReceiptsCompanion data) {
    return StockReceiptRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      receiptNumber: data.receiptNumber.present
          ? data.receiptNumber.value
          : this.receiptNumber,
      supplier: data.supplier.present ? data.supplier.value : this.supplier,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      accountName: data.accountName.present
          ? data.accountName.value
          : this.accountName,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      exchangeRate: data.exchangeRate.present
          ? data.exchangeRate.value
          : this.exchangeRate,
      notes: data.notes.present ? data.notes.value : this.notes,
      receiptDate: data.receiptDate.present
          ? data.receiptDate.value
          : this.receiptDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      version: data.version.present ? data.version.value : this.version,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      status: data.status.present ? data.status.value : this.status,
      postedAt: data.postedAt.present ? data.postedAt.value : this.postedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockReceiptRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('receiptNumber: $receiptNumber, ')
          ..write('supplier: $supplier, ')
          ..write('accountId: $accountId, ')
          ..write('accountName: $accountName, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('exchangeRate: $exchangeRate, ')
          ..write('notes: $notes, ')
          ..write('receiptDate: $receiptDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('version: $version, ')
          ..write('companyId: $companyId, ')
          ..write('status: $status, ')
          ..write('postedAt: $postedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    receiptNumber,
    supplier,
    accountId,
    accountName,
    currencyCode,
    exchangeRate,
    notes,
    receiptDate,
    createdAt,
    updatedAt,
    syncStatus,
    lastSyncedAt,
    version,
    companyId,
    status,
    postedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockReceiptRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.receiptNumber == this.receiptNumber &&
          other.supplier == this.supplier &&
          other.accountId == this.accountId &&
          other.accountName == this.accountName &&
          other.currencyCode == this.currencyCode &&
          other.exchangeRate == this.exchangeRate &&
          other.notes == this.notes &&
          other.receiptDate == this.receiptDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.version == this.version &&
          other.companyId == this.companyId &&
          other.status == this.status &&
          other.postedAt == this.postedAt &&
          other.deletedAt == this.deletedAt);
}

class StockReceiptsCompanion extends UpdateCompanion<StockReceiptRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> receiptNumber;
  final Value<String?> supplier;
  final Value<String?> accountId;
  final Value<String?> accountName;
  final Value<String> currencyCode;
  final Value<double> exchangeRate;
  final Value<String?> notes;
  final Value<int> receiptDate;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> syncStatus;
  final Value<int?> lastSyncedAt;
  final Value<int> version;
  final Value<String?> companyId;
  final Value<String> status;
  final Value<int?> postedAt;
  final Value<int?> deletedAt;
  const StockReceiptsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.receiptNumber = const Value.absent(),
    this.supplier = const Value.absent(),
    this.accountId = const Value.absent(),
    this.accountName = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.exchangeRate = const Value.absent(),
    this.notes = const Value.absent(),
    this.receiptDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.companyId = const Value.absent(),
    this.status = const Value.absent(),
    this.postedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  StockReceiptsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String receiptNumber,
    this.supplier = const Value.absent(),
    this.accountId = const Value.absent(),
    this.accountName = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.exchangeRate = const Value.absent(),
    this.notes = const Value.absent(),
    required int receiptDate,
    required int createdAt,
    required int updatedAt,
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.companyId = const Value.absent(),
    this.status = const Value.absent(),
    this.postedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : uuid = Value(uuid),
       receiptNumber = Value(receiptNumber),
       receiptDate = Value(receiptDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<StockReceiptRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? receiptNumber,
    Expression<String>? supplier,
    Expression<String>? accountId,
    Expression<String>? accountName,
    Expression<String>? currencyCode,
    Expression<double>? exchangeRate,
    Expression<String>? notes,
    Expression<int>? receiptDate,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? syncStatus,
    Expression<int>? lastSyncedAt,
    Expression<int>? version,
    Expression<String>? companyId,
    Expression<String>? status,
    Expression<int>? postedAt,
    Expression<int>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (receiptNumber != null) 'receipt_number': receiptNumber,
      if (supplier != null) 'supplier': supplier,
      if (accountId != null) 'account_id': accountId,
      if (accountName != null) 'account_name': accountName,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (exchangeRate != null) 'exchange_rate': exchangeRate,
      if (notes != null) 'notes': notes,
      if (receiptDate != null) 'receipt_date': receiptDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (version != null) 'version': version,
      if (companyId != null) 'company_id': companyId,
      if (status != null) 'status': status,
      if (postedAt != null) 'posted_at': postedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  StockReceiptsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? receiptNumber,
    Value<String?>? supplier,
    Value<String?>? accountId,
    Value<String?>? accountName,
    Value<String>? currencyCode,
    Value<double>? exchangeRate,
    Value<String?>? notes,
    Value<int>? receiptDate,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? syncStatus,
    Value<int?>? lastSyncedAt,
    Value<int>? version,
    Value<String?>? companyId,
    Value<String>? status,
    Value<int?>? postedAt,
    Value<int?>? deletedAt,
  }) {
    return StockReceiptsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      supplier: supplier ?? this.supplier,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      currencyCode: currencyCode ?? this.currencyCode,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      notes: notes ?? this.notes,
      receiptDate: receiptDate ?? this.receiptDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      version: version ?? this.version,
      companyId: companyId ?? this.companyId,
      status: status ?? this.status,
      postedAt: postedAt ?? this.postedAt,
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
    if (receiptNumber.present) {
      map['receipt_number'] = Variable<String>(receiptNumber.value);
    }
    if (supplier.present) {
      map['supplier'] = Variable<String>(supplier.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (accountName.present) {
      map['account_name'] = Variable<String>(accountName.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (exchangeRate.present) {
      map['exchange_rate'] = Variable<double>(exchangeRate.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (receiptDate.present) {
      map['receipt_date'] = Variable<int>(receiptDate.value);
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
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (postedAt.present) {
      map['posted_at'] = Variable<int>(postedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockReceiptsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('receiptNumber: $receiptNumber, ')
          ..write('supplier: $supplier, ')
          ..write('accountId: $accountId, ')
          ..write('accountName: $accountName, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('exchangeRate: $exchangeRate, ')
          ..write('notes: $notes, ')
          ..write('receiptDate: $receiptDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('version: $version, ')
          ..write('companyId: $companyId, ')
          ..write('status: $status, ')
          ..write('postedAt: $postedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $StockIssuesTable extends StockIssues
    with TableInfo<$StockIssuesTable, StockIssueRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockIssuesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _issueNumberMeta = const VerificationMeta(
    'issueNumber',
  );
  @override
  late final GeneratedColumn<String> issueNumber = GeneratedColumn<String>(
    'issue_number',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 128,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _destinationMeta = const VerificationMeta(
    'destination',
  );
  @override
  late final GeneratedColumn<String> destination = GeneratedColumn<String>(
    'destination',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountNameMeta = const VerificationMeta(
    'accountName',
  );
  @override
  late final GeneratedColumn<String> accountName = GeneratedColumn<String>(
    'account_name',
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
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('SAR'),
  );
  static const VerificationMeta _exchangeRateMeta = const VerificationMeta(
    'exchangeRate',
  );
  @override
  late final GeneratedColumn<double> exchangeRate = GeneratedColumn<double>(
    'exchange_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _voucherBookIdMeta = const VerificationMeta(
    'voucherBookId',
  );
  @override
  late final GeneratedColumn<int> voucherBookId = GeneratedColumn<int>(
    'voucher_book_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _warehouseMeta = const VerificationMeta(
    'warehouse',
  );
  @override
  late final GeneratedColumn<String> warehouse = GeneratedColumn<String>(
    'warehouse',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _issueDateMeta = const VerificationMeta(
    'issueDate',
  );
  @override
  late final GeneratedColumn<int> issueDate = GeneratedColumn<int>(
    'issue_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('posted'),
  );
  static const VerificationMeta _postedAtMeta = const VerificationMeta(
    'postedAt',
  );
  @override
  late final GeneratedColumn<int> postedAt = GeneratedColumn<int>(
    'posted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
    issueNumber,
    destination,
    accountId,
    accountName,
    currencyCode,
    exchangeRate,
    voucherBookId,
    warehouse,
    notes,
    issueDate,
    createdAt,
    updatedAt,
    syncStatus,
    lastSyncedAt,
    version,
    companyId,
    status,
    postedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_issues';
  @override
  VerificationContext validateIntegrity(
    Insertable<StockIssueRow> instance, {
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
    if (data.containsKey('issue_number')) {
      context.handle(
        _issueNumberMeta,
        issueNumber.isAcceptableOrUnknown(
          data['issue_number']!,
          _issueNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_issueNumberMeta);
    }
    if (data.containsKey('destination')) {
      context.handle(
        _destinationMeta,
        destination.isAcceptableOrUnknown(
          data['destination']!,
          _destinationMeta,
        ),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('account_name')) {
      context.handle(
        _accountNameMeta,
        accountName.isAcceptableOrUnknown(
          data['account_name']!,
          _accountNameMeta,
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
    }
    if (data.containsKey('exchange_rate')) {
      context.handle(
        _exchangeRateMeta,
        exchangeRate.isAcceptableOrUnknown(
          data['exchange_rate']!,
          _exchangeRateMeta,
        ),
      );
    }
    if (data.containsKey('voucher_book_id')) {
      context.handle(
        _voucherBookIdMeta,
        voucherBookId.isAcceptableOrUnknown(
          data['voucher_book_id']!,
          _voucherBookIdMeta,
        ),
      );
    }
    if (data.containsKey('warehouse')) {
      context.handle(
        _warehouseMeta,
        warehouse.isAcceptableOrUnknown(data['warehouse']!, _warehouseMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('issue_date')) {
      context.handle(
        _issueDateMeta,
        issueDate.isAcceptableOrUnknown(data['issue_date']!, _issueDateMeta),
      );
    } else if (isInserting) {
      context.missing(_issueDateMeta);
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
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('posted_at')) {
      context.handle(
        _postedAtMeta,
        postedAt.isAcceptableOrUnknown(data['posted_at']!, _postedAtMeta),
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
  StockIssueRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockIssueRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      issueNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issue_number'],
      )!,
      destination: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      accountName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_name'],
      ),
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      exchangeRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}exchange_rate'],
      )!,
      voucherBookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}voucher_book_id'],
      ),
      warehouse: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}warehouse'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      issueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}issue_date'],
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
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      postedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}posted_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $StockIssuesTable createAlias(String alias) {
    return $StockIssuesTable(attachedDatabase, alias);
  }
}

class StockIssueRow extends DataClass implements Insertable<StockIssueRow> {
  final int id;

  /// Client-generated UUID for offline-safe identity / sync.
  final String uuid;
  final String issueNumber;
  final String? destination;
  final String? accountId;
  final String? accountName;
  final String currencyCode;
  final double exchangeRate;
  final int? voucherBookId;
  final String? warehouse;
  final String? notes;
  final int issueDate;
  final int createdAt;
  final int updatedAt;

  /// [SyncStatus.name] string.
  final String syncStatus;
  final int? lastSyncedAt;
  final int version;

  /// Company / Tenant owner ID for local multi-tenant data isolation.
  final String? companyId;

  /// Document posting status ('draft', 'posted', 'cancelled')
  final String status;

  /// Epoch UTC timestamp when the document was posted
  final int? postedAt;

  /// Soft-delete tombstone (UTC epoch ms). Null = active.
  final int? deletedAt;
  const StockIssueRow({
    required this.id,
    required this.uuid,
    required this.issueNumber,
    this.destination,
    this.accountId,
    this.accountName,
    required this.currencyCode,
    required this.exchangeRate,
    this.voucherBookId,
    this.warehouse,
    this.notes,
    required this.issueDate,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.lastSyncedAt,
    required this.version,
    this.companyId,
    required this.status,
    this.postedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['issue_number'] = Variable<String>(issueNumber);
    if (!nullToAbsent || destination != null) {
      map['destination'] = Variable<String>(destination);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    if (!nullToAbsent || accountName != null) {
      map['account_name'] = Variable<String>(accountName);
    }
    map['currency_code'] = Variable<String>(currencyCode);
    map['exchange_rate'] = Variable<double>(exchangeRate);
    if (!nullToAbsent || voucherBookId != null) {
      map['voucher_book_id'] = Variable<int>(voucherBookId);
    }
    if (!nullToAbsent || warehouse != null) {
      map['warehouse'] = Variable<String>(warehouse);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['issue_date'] = Variable<int>(issueDate);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt);
    }
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || companyId != null) {
      map['company_id'] = Variable<String>(companyId);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || postedAt != null) {
      map['posted_at'] = Variable<int>(postedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  StockIssuesCompanion toCompanion(bool nullToAbsent) {
    return StockIssuesCompanion(
      id: Value(id),
      uuid: Value(uuid),
      issueNumber: Value(issueNumber),
      destination: destination == null && nullToAbsent
          ? const Value.absent()
          : Value(destination),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      accountName: accountName == null && nullToAbsent
          ? const Value.absent()
          : Value(accountName),
      currencyCode: Value(currencyCode),
      exchangeRate: Value(exchangeRate),
      voucherBookId: voucherBookId == null && nullToAbsent
          ? const Value.absent()
          : Value(voucherBookId),
      warehouse: warehouse == null && nullToAbsent
          ? const Value.absent()
          : Value(warehouse),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      issueDate: Value(issueDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      version: Value(version),
      companyId: companyId == null && nullToAbsent
          ? const Value.absent()
          : Value(companyId),
      status: Value(status),
      postedAt: postedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(postedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory StockIssueRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockIssueRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      issueNumber: serializer.fromJson<String>(json['issueNumber']),
      destination: serializer.fromJson<String?>(json['destination']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      accountName: serializer.fromJson<String?>(json['accountName']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      exchangeRate: serializer.fromJson<double>(json['exchangeRate']),
      voucherBookId: serializer.fromJson<int?>(json['voucherBookId']),
      warehouse: serializer.fromJson<String?>(json['warehouse']),
      notes: serializer.fromJson<String?>(json['notes']),
      issueDate: serializer.fromJson<int>(json['issueDate']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      lastSyncedAt: serializer.fromJson<int?>(json['lastSyncedAt']),
      version: serializer.fromJson<int>(json['version']),
      companyId: serializer.fromJson<String?>(json['companyId']),
      status: serializer.fromJson<String>(json['status']),
      postedAt: serializer.fromJson<int?>(json['postedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'issueNumber': serializer.toJson<String>(issueNumber),
      'destination': serializer.toJson<String?>(destination),
      'accountId': serializer.toJson<String?>(accountId),
      'accountName': serializer.toJson<String?>(accountName),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'exchangeRate': serializer.toJson<double>(exchangeRate),
      'voucherBookId': serializer.toJson<int?>(voucherBookId),
      'warehouse': serializer.toJson<String?>(warehouse),
      'notes': serializer.toJson<String?>(notes),
      'issueDate': serializer.toJson<int>(issueDate),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'lastSyncedAt': serializer.toJson<int?>(lastSyncedAt),
      'version': serializer.toJson<int>(version),
      'companyId': serializer.toJson<String?>(companyId),
      'status': serializer.toJson<String>(status),
      'postedAt': serializer.toJson<int?>(postedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  StockIssueRow copyWith({
    int? id,
    String? uuid,
    String? issueNumber,
    Value<String?> destination = const Value.absent(),
    Value<String?> accountId = const Value.absent(),
    Value<String?> accountName = const Value.absent(),
    String? currencyCode,
    double? exchangeRate,
    Value<int?> voucherBookId = const Value.absent(),
    Value<String?> warehouse = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    int? issueDate,
    int? createdAt,
    int? updatedAt,
    String? syncStatus,
    Value<int?> lastSyncedAt = const Value.absent(),
    int? version,
    Value<String?> companyId = const Value.absent(),
    String? status,
    Value<int?> postedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
  }) => StockIssueRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    issueNumber: issueNumber ?? this.issueNumber,
    destination: destination.present ? destination.value : this.destination,
    accountId: accountId.present ? accountId.value : this.accountId,
    accountName: accountName.present ? accountName.value : this.accountName,
    currencyCode: currencyCode ?? this.currencyCode,
    exchangeRate: exchangeRate ?? this.exchangeRate,
    voucherBookId: voucherBookId.present
        ? voucherBookId.value
        : this.voucherBookId,
    warehouse: warehouse.present ? warehouse.value : this.warehouse,
    notes: notes.present ? notes.value : this.notes,
    issueDate: issueDate ?? this.issueDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    version: version ?? this.version,
    companyId: companyId.present ? companyId.value : this.companyId,
    status: status ?? this.status,
    postedAt: postedAt.present ? postedAt.value : this.postedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  StockIssueRow copyWithCompanion(StockIssuesCompanion data) {
    return StockIssueRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      issueNumber: data.issueNumber.present
          ? data.issueNumber.value
          : this.issueNumber,
      destination: data.destination.present
          ? data.destination.value
          : this.destination,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      accountName: data.accountName.present
          ? data.accountName.value
          : this.accountName,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      exchangeRate: data.exchangeRate.present
          ? data.exchangeRate.value
          : this.exchangeRate,
      voucherBookId: data.voucherBookId.present
          ? data.voucherBookId.value
          : this.voucherBookId,
      warehouse: data.warehouse.present ? data.warehouse.value : this.warehouse,
      notes: data.notes.present ? data.notes.value : this.notes,
      issueDate: data.issueDate.present ? data.issueDate.value : this.issueDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      version: data.version.present ? data.version.value : this.version,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      status: data.status.present ? data.status.value : this.status,
      postedAt: data.postedAt.present ? data.postedAt.value : this.postedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockIssueRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('issueNumber: $issueNumber, ')
          ..write('destination: $destination, ')
          ..write('accountId: $accountId, ')
          ..write('accountName: $accountName, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('exchangeRate: $exchangeRate, ')
          ..write('voucherBookId: $voucherBookId, ')
          ..write('warehouse: $warehouse, ')
          ..write('notes: $notes, ')
          ..write('issueDate: $issueDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('version: $version, ')
          ..write('companyId: $companyId, ')
          ..write('status: $status, ')
          ..write('postedAt: $postedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    uuid,
    issueNumber,
    destination,
    accountId,
    accountName,
    currencyCode,
    exchangeRate,
    voucherBookId,
    warehouse,
    notes,
    issueDate,
    createdAt,
    updatedAt,
    syncStatus,
    lastSyncedAt,
    version,
    companyId,
    status,
    postedAt,
    deletedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockIssueRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.issueNumber == this.issueNumber &&
          other.destination == this.destination &&
          other.accountId == this.accountId &&
          other.accountName == this.accountName &&
          other.currencyCode == this.currencyCode &&
          other.exchangeRate == this.exchangeRate &&
          other.voucherBookId == this.voucherBookId &&
          other.warehouse == this.warehouse &&
          other.notes == this.notes &&
          other.issueDate == this.issueDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.version == this.version &&
          other.companyId == this.companyId &&
          other.status == this.status &&
          other.postedAt == this.postedAt &&
          other.deletedAt == this.deletedAt);
}

class StockIssuesCompanion extends UpdateCompanion<StockIssueRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> issueNumber;
  final Value<String?> destination;
  final Value<String?> accountId;
  final Value<String?> accountName;
  final Value<String> currencyCode;
  final Value<double> exchangeRate;
  final Value<int?> voucherBookId;
  final Value<String?> warehouse;
  final Value<String?> notes;
  final Value<int> issueDate;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> syncStatus;
  final Value<int?> lastSyncedAt;
  final Value<int> version;
  final Value<String?> companyId;
  final Value<String> status;
  final Value<int?> postedAt;
  final Value<int?> deletedAt;
  const StockIssuesCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.issueNumber = const Value.absent(),
    this.destination = const Value.absent(),
    this.accountId = const Value.absent(),
    this.accountName = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.exchangeRate = const Value.absent(),
    this.voucherBookId = const Value.absent(),
    this.warehouse = const Value.absent(),
    this.notes = const Value.absent(),
    this.issueDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.companyId = const Value.absent(),
    this.status = const Value.absent(),
    this.postedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  StockIssuesCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String issueNumber,
    this.destination = const Value.absent(),
    this.accountId = const Value.absent(),
    this.accountName = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.exchangeRate = const Value.absent(),
    this.voucherBookId = const Value.absent(),
    this.warehouse = const Value.absent(),
    this.notes = const Value.absent(),
    required int issueDate,
    required int createdAt,
    required int updatedAt,
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.companyId = const Value.absent(),
    this.status = const Value.absent(),
    this.postedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : uuid = Value(uuid),
       issueNumber = Value(issueNumber),
       issueDate = Value(issueDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<StockIssueRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? issueNumber,
    Expression<String>? destination,
    Expression<String>? accountId,
    Expression<String>? accountName,
    Expression<String>? currencyCode,
    Expression<double>? exchangeRate,
    Expression<int>? voucherBookId,
    Expression<String>? warehouse,
    Expression<String>? notes,
    Expression<int>? issueDate,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? syncStatus,
    Expression<int>? lastSyncedAt,
    Expression<int>? version,
    Expression<String>? companyId,
    Expression<String>? status,
    Expression<int>? postedAt,
    Expression<int>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (issueNumber != null) 'issue_number': issueNumber,
      if (destination != null) 'destination': destination,
      if (accountId != null) 'account_id': accountId,
      if (accountName != null) 'account_name': accountName,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (exchangeRate != null) 'exchange_rate': exchangeRate,
      if (voucherBookId != null) 'voucher_book_id': voucherBookId,
      if (warehouse != null) 'warehouse': warehouse,
      if (notes != null) 'notes': notes,
      if (issueDate != null) 'issue_date': issueDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (version != null) 'version': version,
      if (companyId != null) 'company_id': companyId,
      if (status != null) 'status': status,
      if (postedAt != null) 'posted_at': postedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  StockIssuesCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? issueNumber,
    Value<String?>? destination,
    Value<String?>? accountId,
    Value<String?>? accountName,
    Value<String>? currencyCode,
    Value<double>? exchangeRate,
    Value<int?>? voucherBookId,
    Value<String?>? warehouse,
    Value<String?>? notes,
    Value<int>? issueDate,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? syncStatus,
    Value<int?>? lastSyncedAt,
    Value<int>? version,
    Value<String?>? companyId,
    Value<String>? status,
    Value<int?>? postedAt,
    Value<int?>? deletedAt,
  }) {
    return StockIssuesCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      issueNumber: issueNumber ?? this.issueNumber,
      destination: destination ?? this.destination,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      currencyCode: currencyCode ?? this.currencyCode,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      voucherBookId: voucherBookId ?? this.voucherBookId,
      warehouse: warehouse ?? this.warehouse,
      notes: notes ?? this.notes,
      issueDate: issueDate ?? this.issueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      version: version ?? this.version,
      companyId: companyId ?? this.companyId,
      status: status ?? this.status,
      postedAt: postedAt ?? this.postedAt,
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
    if (issueNumber.present) {
      map['issue_number'] = Variable<String>(issueNumber.value);
    }
    if (destination.present) {
      map['destination'] = Variable<String>(destination.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (accountName.present) {
      map['account_name'] = Variable<String>(accountName.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (exchangeRate.present) {
      map['exchange_rate'] = Variable<double>(exchangeRate.value);
    }
    if (voucherBookId.present) {
      map['voucher_book_id'] = Variable<int>(voucherBookId.value);
    }
    if (warehouse.present) {
      map['warehouse'] = Variable<String>(warehouse.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (issueDate.present) {
      map['issue_date'] = Variable<int>(issueDate.value);
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
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (postedAt.present) {
      map['posted_at'] = Variable<int>(postedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockIssuesCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('issueNumber: $issueNumber, ')
          ..write('destination: $destination, ')
          ..write('accountId: $accountId, ')
          ..write('accountName: $accountName, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('exchangeRate: $exchangeRate, ')
          ..write('voucherBookId: $voucherBookId, ')
          ..write('warehouse: $warehouse, ')
          ..write('notes: $notes, ')
          ..write('issueDate: $issueDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('version: $version, ')
          ..write('companyId: $companyId, ')
          ..write('status: $status, ')
          ..write('postedAt: $postedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $StockMovementLinesTable extends StockMovementLines
    with TableInfo<$StockMovementLinesTable, StockMovementLineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockMovementLinesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _movementUuidMeta = const VerificationMeta(
    'movementUuid',
  );
  @override
  late final GeneratedColumn<String> movementUuid = GeneratedColumn<String>(
    'movement_uuid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _movementTypeMeta = const VerificationMeta(
    'movementType',
  );
  @override
  late final GeneratedColumn<String> movementType = GeneratedColumn<String>(
    'movement_type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 32,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemCodeMeta = const VerificationMeta(
    'itemCode',
  );
  @override
  late final GeneratedColumn<String> itemCode = GeneratedColumn<String>(
    'item_code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 128,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemNameMeta = const VerificationMeta(
    'itemName',
  );
  @override
  late final GeneratedColumn<String> itemName = GeneratedColumn<String>(
    'item_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 512,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mainQuantityMeta = const VerificationMeta(
    'mainQuantity',
  );
  @override
  late final GeneratedColumn<double> mainQuantity = GeneratedColumn<double>(
    'main_quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _subQuantityMeta = const VerificationMeta(
    'subQuantity',
  );
  @override
  late final GeneratedColumn<double> subQuantity = GeneratedColumn<double>(
    'sub_quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _unitCostMeta = const VerificationMeta(
    'unitCost',
  );
  @override
  late final GeneratedColumn<double> unitCost = GeneratedColumn<double>(
    'unit_cost',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalCostMeta = const VerificationMeta(
    'totalCost',
  );
  @override
  late final GeneratedColumn<double> totalCost = GeneratedColumn<double>(
    'total_cost',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _postedCostMeta = const VerificationMeta(
    'postedCost',
  );
  @override
  late final GeneratedColumn<double> postedCost = GeneratedColumn<double>(
    'posted_cost',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _postedAtMeta = const VerificationMeta(
    'postedAt',
  );
  @override
  late final GeneratedColumn<int> postedAt = GeneratedColumn<int>(
    'posted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    movementUuid,
    movementType,
    itemCode,
    itemName,
    mainQuantity,
    subQuantity,
    quantity,
    unitCost,
    totalCost,
    postedCost,
    postedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_movement_lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<StockMovementLineRow> instance, {
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
    if (data.containsKey('movement_uuid')) {
      context.handle(
        _movementUuidMeta,
        movementUuid.isAcceptableOrUnknown(
          data['movement_uuid']!,
          _movementUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_movementUuidMeta);
    }
    if (data.containsKey('movement_type')) {
      context.handle(
        _movementTypeMeta,
        movementType.isAcceptableOrUnknown(
          data['movement_type']!,
          _movementTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_movementTypeMeta);
    }
    if (data.containsKey('item_code')) {
      context.handle(
        _itemCodeMeta,
        itemCode.isAcceptableOrUnknown(data['item_code']!, _itemCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_itemCodeMeta);
    }
    if (data.containsKey('item_name')) {
      context.handle(
        _itemNameMeta,
        itemName.isAcceptableOrUnknown(data['item_name']!, _itemNameMeta),
      );
    } else if (isInserting) {
      context.missing(_itemNameMeta);
    }
    if (data.containsKey('main_quantity')) {
      context.handle(
        _mainQuantityMeta,
        mainQuantity.isAcceptableOrUnknown(
          data['main_quantity']!,
          _mainQuantityMeta,
        ),
      );
    }
    if (data.containsKey('sub_quantity')) {
      context.handle(
        _subQuantityMeta,
        subQuantity.isAcceptableOrUnknown(
          data['sub_quantity']!,
          _subQuantityMeta,
        ),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('unit_cost')) {
      context.handle(
        _unitCostMeta,
        unitCost.isAcceptableOrUnknown(data['unit_cost']!, _unitCostMeta),
      );
    }
    if (data.containsKey('total_cost')) {
      context.handle(
        _totalCostMeta,
        totalCost.isAcceptableOrUnknown(data['total_cost']!, _totalCostMeta),
      );
    }
    if (data.containsKey('posted_cost')) {
      context.handle(
        _postedCostMeta,
        postedCost.isAcceptableOrUnknown(data['posted_cost']!, _postedCostMeta),
      );
    }
    if (data.containsKey('posted_at')) {
      context.handle(
        _postedAtMeta,
        postedAt.isAcceptableOrUnknown(data['posted_at']!, _postedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StockMovementLineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockMovementLineRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      movementUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}movement_uuid'],
      )!,
      movementType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}movement_type'],
      )!,
      itemCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_code'],
      )!,
      itemName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_name'],
      )!,
      mainQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}main_quantity'],
      )!,
      subQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sub_quantity'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      unitCost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_cost'],
      )!,
      totalCost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_cost'],
      )!,
      postedCost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}posted_cost'],
      ),
      postedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}posted_at'],
      ),
    );
  }

  @override
  $StockMovementLinesTable createAlias(String alias) {
    return $StockMovementLinesTable(attachedDatabase, alias);
  }
}

class StockMovementLineRow extends DataClass
    implements Insertable<StockMovementLineRow> {
  final int id;

  /// UUID of line
  final String uuid;

  /// Associated header UUID (StockReceipt.uuid or StockIssue.uuid)
  final String movementUuid;

  /// 'receipt' or 'issue'
  final String movementType;
  final String itemCode;
  final String itemName;
  final double mainQuantity;
  final double subQuantity;
  final double quantity;
  final double unitCost;
  final double totalCost;

  /// Unit cost locked at post time
  final double? postedCost;

  /// Epoch UTC timestamp when line was posted
  final int? postedAt;
  const StockMovementLineRow({
    required this.id,
    required this.uuid,
    required this.movementUuid,
    required this.movementType,
    required this.itemCode,
    required this.itemName,
    required this.mainQuantity,
    required this.subQuantity,
    required this.quantity,
    required this.unitCost,
    required this.totalCost,
    this.postedCost,
    this.postedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['movement_uuid'] = Variable<String>(movementUuid);
    map['movement_type'] = Variable<String>(movementType);
    map['item_code'] = Variable<String>(itemCode);
    map['item_name'] = Variable<String>(itemName);
    map['main_quantity'] = Variable<double>(mainQuantity);
    map['sub_quantity'] = Variable<double>(subQuantity);
    map['quantity'] = Variable<double>(quantity);
    map['unit_cost'] = Variable<double>(unitCost);
    map['total_cost'] = Variable<double>(totalCost);
    if (!nullToAbsent || postedCost != null) {
      map['posted_cost'] = Variable<double>(postedCost);
    }
    if (!nullToAbsent || postedAt != null) {
      map['posted_at'] = Variable<int>(postedAt);
    }
    return map;
  }

  StockMovementLinesCompanion toCompanion(bool nullToAbsent) {
    return StockMovementLinesCompanion(
      id: Value(id),
      uuid: Value(uuid),
      movementUuid: Value(movementUuid),
      movementType: Value(movementType),
      itemCode: Value(itemCode),
      itemName: Value(itemName),
      mainQuantity: Value(mainQuantity),
      subQuantity: Value(subQuantity),
      quantity: Value(quantity),
      unitCost: Value(unitCost),
      totalCost: Value(totalCost),
      postedCost: postedCost == null && nullToAbsent
          ? const Value.absent()
          : Value(postedCost),
      postedAt: postedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(postedAt),
    );
  }

  factory StockMovementLineRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockMovementLineRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      movementUuid: serializer.fromJson<String>(json['movementUuid']),
      movementType: serializer.fromJson<String>(json['movementType']),
      itemCode: serializer.fromJson<String>(json['itemCode']),
      itemName: serializer.fromJson<String>(json['itemName']),
      mainQuantity: serializer.fromJson<double>(json['mainQuantity']),
      subQuantity: serializer.fromJson<double>(json['subQuantity']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unitCost: serializer.fromJson<double>(json['unitCost']),
      totalCost: serializer.fromJson<double>(json['totalCost']),
      postedCost: serializer.fromJson<double?>(json['postedCost']),
      postedAt: serializer.fromJson<int?>(json['postedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'movementUuid': serializer.toJson<String>(movementUuid),
      'movementType': serializer.toJson<String>(movementType),
      'itemCode': serializer.toJson<String>(itemCode),
      'itemName': serializer.toJson<String>(itemName),
      'mainQuantity': serializer.toJson<double>(mainQuantity),
      'subQuantity': serializer.toJson<double>(subQuantity),
      'quantity': serializer.toJson<double>(quantity),
      'unitCost': serializer.toJson<double>(unitCost),
      'totalCost': serializer.toJson<double>(totalCost),
      'postedCost': serializer.toJson<double?>(postedCost),
      'postedAt': serializer.toJson<int?>(postedAt),
    };
  }

  StockMovementLineRow copyWith({
    int? id,
    String? uuid,
    String? movementUuid,
    String? movementType,
    String? itemCode,
    String? itemName,
    double? mainQuantity,
    double? subQuantity,
    double? quantity,
    double? unitCost,
    double? totalCost,
    Value<double?> postedCost = const Value.absent(),
    Value<int?> postedAt = const Value.absent(),
  }) => StockMovementLineRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    movementUuid: movementUuid ?? this.movementUuid,
    movementType: movementType ?? this.movementType,
    itemCode: itemCode ?? this.itemCode,
    itemName: itemName ?? this.itemName,
    mainQuantity: mainQuantity ?? this.mainQuantity,
    subQuantity: subQuantity ?? this.subQuantity,
    quantity: quantity ?? this.quantity,
    unitCost: unitCost ?? this.unitCost,
    totalCost: totalCost ?? this.totalCost,
    postedCost: postedCost.present ? postedCost.value : this.postedCost,
    postedAt: postedAt.present ? postedAt.value : this.postedAt,
  );
  StockMovementLineRow copyWithCompanion(StockMovementLinesCompanion data) {
    return StockMovementLineRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      movementUuid: data.movementUuid.present
          ? data.movementUuid.value
          : this.movementUuid,
      movementType: data.movementType.present
          ? data.movementType.value
          : this.movementType,
      itemCode: data.itemCode.present ? data.itemCode.value : this.itemCode,
      itemName: data.itemName.present ? data.itemName.value : this.itemName,
      mainQuantity: data.mainQuantity.present
          ? data.mainQuantity.value
          : this.mainQuantity,
      subQuantity: data.subQuantity.present
          ? data.subQuantity.value
          : this.subQuantity,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitCost: data.unitCost.present ? data.unitCost.value : this.unitCost,
      totalCost: data.totalCost.present ? data.totalCost.value : this.totalCost,
      postedCost: data.postedCost.present
          ? data.postedCost.value
          : this.postedCost,
      postedAt: data.postedAt.present ? data.postedAt.value : this.postedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockMovementLineRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('movementUuid: $movementUuid, ')
          ..write('movementType: $movementType, ')
          ..write('itemCode: $itemCode, ')
          ..write('itemName: $itemName, ')
          ..write('mainQuantity: $mainQuantity, ')
          ..write('subQuantity: $subQuantity, ')
          ..write('quantity: $quantity, ')
          ..write('unitCost: $unitCost, ')
          ..write('totalCost: $totalCost, ')
          ..write('postedCost: $postedCost, ')
          ..write('postedAt: $postedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    movementUuid,
    movementType,
    itemCode,
    itemName,
    mainQuantity,
    subQuantity,
    quantity,
    unitCost,
    totalCost,
    postedCost,
    postedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockMovementLineRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.movementUuid == this.movementUuid &&
          other.movementType == this.movementType &&
          other.itemCode == this.itemCode &&
          other.itemName == this.itemName &&
          other.mainQuantity == this.mainQuantity &&
          other.subQuantity == this.subQuantity &&
          other.quantity == this.quantity &&
          other.unitCost == this.unitCost &&
          other.totalCost == this.totalCost &&
          other.postedCost == this.postedCost &&
          other.postedAt == this.postedAt);
}

class StockMovementLinesCompanion
    extends UpdateCompanion<StockMovementLineRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> movementUuid;
  final Value<String> movementType;
  final Value<String> itemCode;
  final Value<String> itemName;
  final Value<double> mainQuantity;
  final Value<double> subQuantity;
  final Value<double> quantity;
  final Value<double> unitCost;
  final Value<double> totalCost;
  final Value<double?> postedCost;
  final Value<int?> postedAt;
  const StockMovementLinesCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.movementUuid = const Value.absent(),
    this.movementType = const Value.absent(),
    this.itemCode = const Value.absent(),
    this.itemName = const Value.absent(),
    this.mainQuantity = const Value.absent(),
    this.subQuantity = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitCost = const Value.absent(),
    this.totalCost = const Value.absent(),
    this.postedCost = const Value.absent(),
    this.postedAt = const Value.absent(),
  });
  StockMovementLinesCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String movementUuid,
    required String movementType,
    required String itemCode,
    required String itemName,
    this.mainQuantity = const Value.absent(),
    this.subQuantity = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitCost = const Value.absent(),
    this.totalCost = const Value.absent(),
    this.postedCost = const Value.absent(),
    this.postedAt = const Value.absent(),
  }) : uuid = Value(uuid),
       movementUuid = Value(movementUuid),
       movementType = Value(movementType),
       itemCode = Value(itemCode),
       itemName = Value(itemName);
  static Insertable<StockMovementLineRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? movementUuid,
    Expression<String>? movementType,
    Expression<String>? itemCode,
    Expression<String>? itemName,
    Expression<double>? mainQuantity,
    Expression<double>? subQuantity,
    Expression<double>? quantity,
    Expression<double>? unitCost,
    Expression<double>? totalCost,
    Expression<double>? postedCost,
    Expression<int>? postedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (movementUuid != null) 'movement_uuid': movementUuid,
      if (movementType != null) 'movement_type': movementType,
      if (itemCode != null) 'item_code': itemCode,
      if (itemName != null) 'item_name': itemName,
      if (mainQuantity != null) 'main_quantity': mainQuantity,
      if (subQuantity != null) 'sub_quantity': subQuantity,
      if (quantity != null) 'quantity': quantity,
      if (unitCost != null) 'unit_cost': unitCost,
      if (totalCost != null) 'total_cost': totalCost,
      if (postedCost != null) 'posted_cost': postedCost,
      if (postedAt != null) 'posted_at': postedAt,
    });
  }

  StockMovementLinesCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? movementUuid,
    Value<String>? movementType,
    Value<String>? itemCode,
    Value<String>? itemName,
    Value<double>? mainQuantity,
    Value<double>? subQuantity,
    Value<double>? quantity,
    Value<double>? unitCost,
    Value<double>? totalCost,
    Value<double?>? postedCost,
    Value<int?>? postedAt,
  }) {
    return StockMovementLinesCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      movementUuid: movementUuid ?? this.movementUuid,
      movementType: movementType ?? this.movementType,
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      mainQuantity: mainQuantity ?? this.mainQuantity,
      subQuantity: subQuantity ?? this.subQuantity,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      totalCost: totalCost ?? this.totalCost,
      postedCost: postedCost ?? this.postedCost,
      postedAt: postedAt ?? this.postedAt,
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
    if (movementUuid.present) {
      map['movement_uuid'] = Variable<String>(movementUuid.value);
    }
    if (movementType.present) {
      map['movement_type'] = Variable<String>(movementType.value);
    }
    if (itemCode.present) {
      map['item_code'] = Variable<String>(itemCode.value);
    }
    if (itemName.present) {
      map['item_name'] = Variable<String>(itemName.value);
    }
    if (mainQuantity.present) {
      map['main_quantity'] = Variable<double>(mainQuantity.value);
    }
    if (subQuantity.present) {
      map['sub_quantity'] = Variable<double>(subQuantity.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unitCost.present) {
      map['unit_cost'] = Variable<double>(unitCost.value);
    }
    if (totalCost.present) {
      map['total_cost'] = Variable<double>(totalCost.value);
    }
    if (postedCost.present) {
      map['posted_cost'] = Variable<double>(postedCost.value);
    }
    if (postedAt.present) {
      map['posted_at'] = Variable<int>(postedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockMovementLinesCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('movementUuid: $movementUuid, ')
          ..write('movementType: $movementType, ')
          ..write('itemCode: $itemCode, ')
          ..write('itemName: $itemName, ')
          ..write('mainQuantity: $mainQuantity, ')
          ..write('subQuantity: $subQuantity, ')
          ..write('quantity: $quantity, ')
          ..write('unitCost: $unitCost, ')
          ..write('totalCost: $totalCost, ')
          ..write('postedCost: $postedCost, ')
          ..write('postedAt: $postedAt')
          ..write(')'))
        .toString();
  }
}

class $InventoryCostLayersTable extends InventoryCostLayers
    with TableInfo<$InventoryCostLayersTable, InventoryCostLayerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryCostLayersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _itemCodeMeta = const VerificationMeta(
    'itemCode',
  );
  @override
  late final GeneratedColumn<String> itemCode = GeneratedColumn<String>(
    'item_code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 128,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _warehouseIdMeta = const VerificationMeta(
    'warehouseId',
  );
  @override
  late final GeneratedColumn<String> warehouseId = GeneratedColumn<String>(
    'warehouse_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _movementUuidMeta = const VerificationMeta(
    'movementUuid',
  );
  @override
  late final GeneratedColumn<String> movementUuid = GeneratedColumn<String>(
    'movement_uuid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _movementTypeMeta = const VerificationMeta(
    'movementType',
  );
  @override
  late final GeneratedColumn<String> movementType = GeneratedColumn<String>(
    'movement_type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 32,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedDateMeta = const VerificationMeta(
    'receivedDate',
  );
  @override
  late final GeneratedColumn<int> receivedDate = GeneratedColumn<int>(
    'received_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedQtyMeta = const VerificationMeta(
    'receivedQty',
  );
  @override
  late final GeneratedColumn<double> receivedQty = GeneratedColumn<double>(
    'received_qty',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _remainingQtyMeta = const VerificationMeta(
    'remainingQty',
  );
  @override
  late final GeneratedColumn<double> remainingQty = GeneratedColumn<double>(
    'remaining_qty',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _unitCostMeta = const VerificationMeta(
    'unitCost',
  );
  @override
  late final GeneratedColumn<double> unitCost = GeneratedColumn<double>(
    'unit_cost',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalCostMeta = const VerificationMeta(
    'totalCost',
  );
  @override
  late final GeneratedColumn<double> totalCost = GeneratedColumn<double>(
    'total_cost',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _closedMeta = const VerificationMeta('closed');
  @override
  late final GeneratedColumn<int> closed = GeneratedColumn<int>(
    'closed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    itemCode,
    warehouseId,
    movementUuid,
    movementType,
    receivedDate,
    receivedQty,
    remainingQty,
    unitCost,
    totalCost,
    closed,
    createdAt,
    updatedAt,
    syncStatus,
    lastSyncedAt,
    version,
    companyId,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_cost_layers';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventoryCostLayerRow> instance, {
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
    if (data.containsKey('item_code')) {
      context.handle(
        _itemCodeMeta,
        itemCode.isAcceptableOrUnknown(data['item_code']!, _itemCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_itemCodeMeta);
    }
    if (data.containsKey('warehouse_id')) {
      context.handle(
        _warehouseIdMeta,
        warehouseId.isAcceptableOrUnknown(
          data['warehouse_id']!,
          _warehouseIdMeta,
        ),
      );
    }
    if (data.containsKey('movement_uuid')) {
      context.handle(
        _movementUuidMeta,
        movementUuid.isAcceptableOrUnknown(
          data['movement_uuid']!,
          _movementUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_movementUuidMeta);
    }
    if (data.containsKey('movement_type')) {
      context.handle(
        _movementTypeMeta,
        movementType.isAcceptableOrUnknown(
          data['movement_type']!,
          _movementTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_movementTypeMeta);
    }
    if (data.containsKey('received_date')) {
      context.handle(
        _receivedDateMeta,
        receivedDate.isAcceptableOrUnknown(
          data['received_date']!,
          _receivedDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_receivedDateMeta);
    }
    if (data.containsKey('received_qty')) {
      context.handle(
        _receivedQtyMeta,
        receivedQty.isAcceptableOrUnknown(
          data['received_qty']!,
          _receivedQtyMeta,
        ),
      );
    }
    if (data.containsKey('remaining_qty')) {
      context.handle(
        _remainingQtyMeta,
        remainingQty.isAcceptableOrUnknown(
          data['remaining_qty']!,
          _remainingQtyMeta,
        ),
      );
    }
    if (data.containsKey('unit_cost')) {
      context.handle(
        _unitCostMeta,
        unitCost.isAcceptableOrUnknown(data['unit_cost']!, _unitCostMeta),
      );
    }
    if (data.containsKey('total_cost')) {
      context.handle(
        _totalCostMeta,
        totalCost.isAcceptableOrUnknown(data['total_cost']!, _totalCostMeta),
      );
    }
    if (data.containsKey('closed')) {
      context.handle(
        _closedMeta,
        closed.isAcceptableOrUnknown(data['closed']!, _closedMeta),
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
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
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
  InventoryCostLayerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryCostLayerRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      itemCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_code'],
      )!,
      warehouseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}warehouse_id'],
      ),
      movementUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}movement_uuid'],
      )!,
      movementType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}movement_type'],
      )!,
      receivedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}received_date'],
      )!,
      receivedQty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}received_qty'],
      )!,
      remainingQty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}remaining_qty'],
      )!,
      unitCost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_cost'],
      )!,
      totalCost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_cost'],
      )!,
      closed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}closed'],
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
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $InventoryCostLayersTable createAlias(String alias) {
    return $InventoryCostLayersTable(attachedDatabase, alias);
  }
}

class InventoryCostLayerRow extends DataClass
    implements Insertable<InventoryCostLayerRow> {
  final int id;

  /// Client-generated UUID for offline-safe identity / sync.
  final String uuid;

  /// Product item code associated with this layer.
  final String itemCode;

  /// Warehouse identifier where this layer belongs.
  final String? warehouseId;

  /// Movement UUID that created this layer (e.g. StockReceipt.uuid).
  final String movementUuid;

  /// Type of movement ('receipt', 'return_receipt', 'adjustment', 'opening').
  final String movementType;

  /// Receipt/layer creation timestamp (epoch ms UTC).
  final int receivedDate;

  /// Original quantity received into this layer.
  final double receivedQty;

  /// Remaining quantity available in this layer (decremented on issue/sale).
  final double remainingQty;

  /// Unit cost for this layer in company base currency.
  final double unitCost;

  /// Total original cost (`receivedQty * unitCost`).
  final double totalCost;

  /// 0 = open (remainingQty > 0), 1 = fully consumed (remainingQty == 0).
  final int closed;

  /// Creation timestamp (UTC epoch ms).
  final int createdAt;

  /// Last updated timestamp (UTC epoch ms).
  final int updatedAt;

  /// Sync status ('synced', 'pending', etc.).
  final String syncStatus;

  /// Last synced timestamp (UTC epoch ms).
  final int? lastSyncedAt;

  /// Entity version for sync conflict resolution.
  final int version;

  /// Company / Tenant owner ID for local multi-tenant data isolation.
  final String? companyId;

  /// Soft-delete tombstone (UTC epoch ms). Null = active.
  final int? deletedAt;
  const InventoryCostLayerRow({
    required this.id,
    required this.uuid,
    required this.itemCode,
    this.warehouseId,
    required this.movementUuid,
    required this.movementType,
    required this.receivedDate,
    required this.receivedQty,
    required this.remainingQty,
    required this.unitCost,
    required this.totalCost,
    required this.closed,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.lastSyncedAt,
    required this.version,
    this.companyId,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['item_code'] = Variable<String>(itemCode);
    if (!nullToAbsent || warehouseId != null) {
      map['warehouse_id'] = Variable<String>(warehouseId);
    }
    map['movement_uuid'] = Variable<String>(movementUuid);
    map['movement_type'] = Variable<String>(movementType);
    map['received_date'] = Variable<int>(receivedDate);
    map['received_qty'] = Variable<double>(receivedQty);
    map['remaining_qty'] = Variable<double>(remainingQty);
    map['unit_cost'] = Variable<double>(unitCost);
    map['total_cost'] = Variable<double>(totalCost);
    map['closed'] = Variable<int>(closed);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt);
    }
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || companyId != null) {
      map['company_id'] = Variable<String>(companyId);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  InventoryCostLayersCompanion toCompanion(bool nullToAbsent) {
    return InventoryCostLayersCompanion(
      id: Value(id),
      uuid: Value(uuid),
      itemCode: Value(itemCode),
      warehouseId: warehouseId == null && nullToAbsent
          ? const Value.absent()
          : Value(warehouseId),
      movementUuid: Value(movementUuid),
      movementType: Value(movementType),
      receivedDate: Value(receivedDate),
      receivedQty: Value(receivedQty),
      remainingQty: Value(remainingQty),
      unitCost: Value(unitCost),
      totalCost: Value(totalCost),
      closed: Value(closed),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      version: Value(version),
      companyId: companyId == null && nullToAbsent
          ? const Value.absent()
          : Value(companyId),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory InventoryCostLayerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryCostLayerRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      itemCode: serializer.fromJson<String>(json['itemCode']),
      warehouseId: serializer.fromJson<String?>(json['warehouseId']),
      movementUuid: serializer.fromJson<String>(json['movementUuid']),
      movementType: serializer.fromJson<String>(json['movementType']),
      receivedDate: serializer.fromJson<int>(json['receivedDate']),
      receivedQty: serializer.fromJson<double>(json['receivedQty']),
      remainingQty: serializer.fromJson<double>(json['remainingQty']),
      unitCost: serializer.fromJson<double>(json['unitCost']),
      totalCost: serializer.fromJson<double>(json['totalCost']),
      closed: serializer.fromJson<int>(json['closed']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      lastSyncedAt: serializer.fromJson<int?>(json['lastSyncedAt']),
      version: serializer.fromJson<int>(json['version']),
      companyId: serializer.fromJson<String?>(json['companyId']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'itemCode': serializer.toJson<String>(itemCode),
      'warehouseId': serializer.toJson<String?>(warehouseId),
      'movementUuid': serializer.toJson<String>(movementUuid),
      'movementType': serializer.toJson<String>(movementType),
      'receivedDate': serializer.toJson<int>(receivedDate),
      'receivedQty': serializer.toJson<double>(receivedQty),
      'remainingQty': serializer.toJson<double>(remainingQty),
      'unitCost': serializer.toJson<double>(unitCost),
      'totalCost': serializer.toJson<double>(totalCost),
      'closed': serializer.toJson<int>(closed),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'lastSyncedAt': serializer.toJson<int?>(lastSyncedAt),
      'version': serializer.toJson<int>(version),
      'companyId': serializer.toJson<String?>(companyId),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  InventoryCostLayerRow copyWith({
    int? id,
    String? uuid,
    String? itemCode,
    Value<String?> warehouseId = const Value.absent(),
    String? movementUuid,
    String? movementType,
    int? receivedDate,
    double? receivedQty,
    double? remainingQty,
    double? unitCost,
    double? totalCost,
    int? closed,
    int? createdAt,
    int? updatedAt,
    String? syncStatus,
    Value<int?> lastSyncedAt = const Value.absent(),
    int? version,
    Value<String?> companyId = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
  }) => InventoryCostLayerRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    itemCode: itemCode ?? this.itemCode,
    warehouseId: warehouseId.present ? warehouseId.value : this.warehouseId,
    movementUuid: movementUuid ?? this.movementUuid,
    movementType: movementType ?? this.movementType,
    receivedDate: receivedDate ?? this.receivedDate,
    receivedQty: receivedQty ?? this.receivedQty,
    remainingQty: remainingQty ?? this.remainingQty,
    unitCost: unitCost ?? this.unitCost,
    totalCost: totalCost ?? this.totalCost,
    closed: closed ?? this.closed,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    version: version ?? this.version,
    companyId: companyId.present ? companyId.value : this.companyId,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  InventoryCostLayerRow copyWithCompanion(InventoryCostLayersCompanion data) {
    return InventoryCostLayerRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      itemCode: data.itemCode.present ? data.itemCode.value : this.itemCode,
      warehouseId: data.warehouseId.present
          ? data.warehouseId.value
          : this.warehouseId,
      movementUuid: data.movementUuid.present
          ? data.movementUuid.value
          : this.movementUuid,
      movementType: data.movementType.present
          ? data.movementType.value
          : this.movementType,
      receivedDate: data.receivedDate.present
          ? data.receivedDate.value
          : this.receivedDate,
      receivedQty: data.receivedQty.present
          ? data.receivedQty.value
          : this.receivedQty,
      remainingQty: data.remainingQty.present
          ? data.remainingQty.value
          : this.remainingQty,
      unitCost: data.unitCost.present ? data.unitCost.value : this.unitCost,
      totalCost: data.totalCost.present ? data.totalCost.value : this.totalCost,
      closed: data.closed.present ? data.closed.value : this.closed,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      version: data.version.present ? data.version.value : this.version,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryCostLayerRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('itemCode: $itemCode, ')
          ..write('warehouseId: $warehouseId, ')
          ..write('movementUuid: $movementUuid, ')
          ..write('movementType: $movementType, ')
          ..write('receivedDate: $receivedDate, ')
          ..write('receivedQty: $receivedQty, ')
          ..write('remainingQty: $remainingQty, ')
          ..write('unitCost: $unitCost, ')
          ..write('totalCost: $totalCost, ')
          ..write('closed: $closed, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('version: $version, ')
          ..write('companyId: $companyId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    itemCode,
    warehouseId,
    movementUuid,
    movementType,
    receivedDate,
    receivedQty,
    remainingQty,
    unitCost,
    totalCost,
    closed,
    createdAt,
    updatedAt,
    syncStatus,
    lastSyncedAt,
    version,
    companyId,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryCostLayerRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.itemCode == this.itemCode &&
          other.warehouseId == this.warehouseId &&
          other.movementUuid == this.movementUuid &&
          other.movementType == this.movementType &&
          other.receivedDate == this.receivedDate &&
          other.receivedQty == this.receivedQty &&
          other.remainingQty == this.remainingQty &&
          other.unitCost == this.unitCost &&
          other.totalCost == this.totalCost &&
          other.closed == this.closed &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.version == this.version &&
          other.companyId == this.companyId &&
          other.deletedAt == this.deletedAt);
}

class InventoryCostLayersCompanion
    extends UpdateCompanion<InventoryCostLayerRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> itemCode;
  final Value<String?> warehouseId;
  final Value<String> movementUuid;
  final Value<String> movementType;
  final Value<int> receivedDate;
  final Value<double> receivedQty;
  final Value<double> remainingQty;
  final Value<double> unitCost;
  final Value<double> totalCost;
  final Value<int> closed;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> syncStatus;
  final Value<int?> lastSyncedAt;
  final Value<int> version;
  final Value<String?> companyId;
  final Value<int?> deletedAt;
  const InventoryCostLayersCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.itemCode = const Value.absent(),
    this.warehouseId = const Value.absent(),
    this.movementUuid = const Value.absent(),
    this.movementType = const Value.absent(),
    this.receivedDate = const Value.absent(),
    this.receivedQty = const Value.absent(),
    this.remainingQty = const Value.absent(),
    this.unitCost = const Value.absent(),
    this.totalCost = const Value.absent(),
    this.closed = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.companyId = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  InventoryCostLayersCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String itemCode,
    this.warehouseId = const Value.absent(),
    required String movementUuid,
    required String movementType,
    required int receivedDate,
    this.receivedQty = const Value.absent(),
    this.remainingQty = const Value.absent(),
    this.unitCost = const Value.absent(),
    this.totalCost = const Value.absent(),
    this.closed = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.companyId = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : uuid = Value(uuid),
       itemCode = Value(itemCode),
       movementUuid = Value(movementUuid),
       movementType = Value(movementType),
       receivedDate = Value(receivedDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<InventoryCostLayerRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? itemCode,
    Expression<String>? warehouseId,
    Expression<String>? movementUuid,
    Expression<String>? movementType,
    Expression<int>? receivedDate,
    Expression<double>? receivedQty,
    Expression<double>? remainingQty,
    Expression<double>? unitCost,
    Expression<double>? totalCost,
    Expression<int>? closed,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? syncStatus,
    Expression<int>? lastSyncedAt,
    Expression<int>? version,
    Expression<String>? companyId,
    Expression<int>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (itemCode != null) 'item_code': itemCode,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      if (movementUuid != null) 'movement_uuid': movementUuid,
      if (movementType != null) 'movement_type': movementType,
      if (receivedDate != null) 'received_date': receivedDate,
      if (receivedQty != null) 'received_qty': receivedQty,
      if (remainingQty != null) 'remaining_qty': remainingQty,
      if (unitCost != null) 'unit_cost': unitCost,
      if (totalCost != null) 'total_cost': totalCost,
      if (closed != null) 'closed': closed,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (version != null) 'version': version,
      if (companyId != null) 'company_id': companyId,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  InventoryCostLayersCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? itemCode,
    Value<String?>? warehouseId,
    Value<String>? movementUuid,
    Value<String>? movementType,
    Value<int>? receivedDate,
    Value<double>? receivedQty,
    Value<double>? remainingQty,
    Value<double>? unitCost,
    Value<double>? totalCost,
    Value<int>? closed,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? syncStatus,
    Value<int?>? lastSyncedAt,
    Value<int>? version,
    Value<String?>? companyId,
    Value<int?>? deletedAt,
  }) {
    return InventoryCostLayersCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      itemCode: itemCode ?? this.itemCode,
      warehouseId: warehouseId ?? this.warehouseId,
      movementUuid: movementUuid ?? this.movementUuid,
      movementType: movementType ?? this.movementType,
      receivedDate: receivedDate ?? this.receivedDate,
      receivedQty: receivedQty ?? this.receivedQty,
      remainingQty: remainingQty ?? this.remainingQty,
      unitCost: unitCost ?? this.unitCost,
      totalCost: totalCost ?? this.totalCost,
      closed: closed ?? this.closed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      version: version ?? this.version,
      companyId: companyId ?? this.companyId,
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
    if (itemCode.present) {
      map['item_code'] = Variable<String>(itemCode.value);
    }
    if (warehouseId.present) {
      map['warehouse_id'] = Variable<String>(warehouseId.value);
    }
    if (movementUuid.present) {
      map['movement_uuid'] = Variable<String>(movementUuid.value);
    }
    if (movementType.present) {
      map['movement_type'] = Variable<String>(movementType.value);
    }
    if (receivedDate.present) {
      map['received_date'] = Variable<int>(receivedDate.value);
    }
    if (receivedQty.present) {
      map['received_qty'] = Variable<double>(receivedQty.value);
    }
    if (remainingQty.present) {
      map['remaining_qty'] = Variable<double>(remainingQty.value);
    }
    if (unitCost.present) {
      map['unit_cost'] = Variable<double>(unitCost.value);
    }
    if (totalCost.present) {
      map['total_cost'] = Variable<double>(totalCost.value);
    }
    if (closed.present) {
      map['closed'] = Variable<int>(closed.value);
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
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryCostLayersCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('itemCode: $itemCode, ')
          ..write('warehouseId: $warehouseId, ')
          ..write('movementUuid: $movementUuid, ')
          ..write('movementType: $movementType, ')
          ..write('receivedDate: $receivedDate, ')
          ..write('receivedQty: $receivedQty, ')
          ..write('remainingQty: $remainingQty, ')
          ..write('unitCost: $unitCost, ')
          ..write('totalCost: $totalCost, ')
          ..write('closed: $closed, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('version: $version, ')
          ..write('companyId: $companyId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $InventoryCostConsumptionsTable extends InventoryCostConsumptions
    with
        TableInfo<
          $InventoryCostConsumptionsTable,
          InventoryCostConsumptionRow
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryCostConsumptionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _layerUuidMeta = const VerificationMeta(
    'layerUuid',
  );
  @override
  late final GeneratedColumn<String> layerUuid = GeneratedColumn<String>(
    'layer_uuid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _issueLineUuidMeta = const VerificationMeta(
    'issueLineUuid',
  );
  @override
  late final GeneratedColumn<String> issueLineUuid = GeneratedColumn<String>(
    'issue_line_uuid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _movementTypeMeta = const VerificationMeta(
    'movementType',
  );
  @override
  late final GeneratedColumn<String> movementType = GeneratedColumn<String>(
    'movement_type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 32,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _consumedQtyMeta = const VerificationMeta(
    'consumedQty',
  );
  @override
  late final GeneratedColumn<double> consumedQty = GeneratedColumn<double>(
    'consumed_qty',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _unitCostMeta = const VerificationMeta(
    'unitCost',
  );
  @override
  late final GeneratedColumn<double> unitCost = GeneratedColumn<double>(
    'unit_cost',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalCostMeta = const VerificationMeta(
    'totalCost',
  );
  @override
  late final GeneratedColumn<double> totalCost = GeneratedColumn<double>(
    'total_cost',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    layerUuid,
    issueLineUuid,
    movementType,
    consumedQty,
    unitCost,
    totalCost,
    createdAt,
    companyId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_cost_consumptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventoryCostConsumptionRow> instance, {
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
    if (data.containsKey('layer_uuid')) {
      context.handle(
        _layerUuidMeta,
        layerUuid.isAcceptableOrUnknown(data['layer_uuid']!, _layerUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_layerUuidMeta);
    }
    if (data.containsKey('issue_line_uuid')) {
      context.handle(
        _issueLineUuidMeta,
        issueLineUuid.isAcceptableOrUnknown(
          data['issue_line_uuid']!,
          _issueLineUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_issueLineUuidMeta);
    }
    if (data.containsKey('movement_type')) {
      context.handle(
        _movementTypeMeta,
        movementType.isAcceptableOrUnknown(
          data['movement_type']!,
          _movementTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_movementTypeMeta);
    }
    if (data.containsKey('consumed_qty')) {
      context.handle(
        _consumedQtyMeta,
        consumedQty.isAcceptableOrUnknown(
          data['consumed_qty']!,
          _consumedQtyMeta,
        ),
      );
    }
    if (data.containsKey('unit_cost')) {
      context.handle(
        _unitCostMeta,
        unitCost.isAcceptableOrUnknown(data['unit_cost']!, _unitCostMeta),
      );
    }
    if (data.containsKey('total_cost')) {
      context.handle(
        _totalCostMeta,
        totalCost.isAcceptableOrUnknown(data['total_cost']!, _totalCostMeta),
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
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryCostConsumptionRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryCostConsumptionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      layerUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}layer_uuid'],
      )!,
      issueLineUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issue_line_uuid'],
      )!,
      movementType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}movement_type'],
      )!,
      consumedQty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}consumed_qty'],
      )!,
      unitCost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_cost'],
      )!,
      totalCost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_cost'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      ),
    );
  }

  @override
  $InventoryCostConsumptionsTable createAlias(String alias) {
    return $InventoryCostConsumptionsTable(attachedDatabase, alias);
  }
}

class InventoryCostConsumptionRow extends DataClass
    implements Insertable<InventoryCostConsumptionRow> {
  final int id;

  /// Client-generated UUID for offline-safe identity / sync.
  final String uuid;

  /// UUID of the consumed InventoryCostLayer.
  final String layerUuid;

  /// UUID of the outgoing movement line item (StockMovementLine.uuid or SaleLine.uuid).
  final String issueLineUuid;

  /// Movement type ('issue', 'sale', 'transfer_out', 'return_issue').
  final String movementType;

  /// Quantity consumed from this layer for the specified movement line.
  final double consumedQty;

  /// Snapshot of unit cost at consumption time.
  final double unitCost;

  /// Total cost consumed (`consumedQty * unitCost`).
  final double totalCost;

  /// Creation timestamp (UTC epoch ms).
  final int createdAt;

  /// Company / Tenant owner ID for local multi-tenant data isolation.
  final String? companyId;
  const InventoryCostConsumptionRow({
    required this.id,
    required this.uuid,
    required this.layerUuid,
    required this.issueLineUuid,
    required this.movementType,
    required this.consumedQty,
    required this.unitCost,
    required this.totalCost,
    required this.createdAt,
    this.companyId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['layer_uuid'] = Variable<String>(layerUuid);
    map['issue_line_uuid'] = Variable<String>(issueLineUuid);
    map['movement_type'] = Variable<String>(movementType);
    map['consumed_qty'] = Variable<double>(consumedQty);
    map['unit_cost'] = Variable<double>(unitCost);
    map['total_cost'] = Variable<double>(totalCost);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || companyId != null) {
      map['company_id'] = Variable<String>(companyId);
    }
    return map;
  }

  InventoryCostConsumptionsCompanion toCompanion(bool nullToAbsent) {
    return InventoryCostConsumptionsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      layerUuid: Value(layerUuid),
      issueLineUuid: Value(issueLineUuid),
      movementType: Value(movementType),
      consumedQty: Value(consumedQty),
      unitCost: Value(unitCost),
      totalCost: Value(totalCost),
      createdAt: Value(createdAt),
      companyId: companyId == null && nullToAbsent
          ? const Value.absent()
          : Value(companyId),
    );
  }

  factory InventoryCostConsumptionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryCostConsumptionRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      layerUuid: serializer.fromJson<String>(json['layerUuid']),
      issueLineUuid: serializer.fromJson<String>(json['issueLineUuid']),
      movementType: serializer.fromJson<String>(json['movementType']),
      consumedQty: serializer.fromJson<double>(json['consumedQty']),
      unitCost: serializer.fromJson<double>(json['unitCost']),
      totalCost: serializer.fromJson<double>(json['totalCost']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      companyId: serializer.fromJson<String?>(json['companyId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'layerUuid': serializer.toJson<String>(layerUuid),
      'issueLineUuid': serializer.toJson<String>(issueLineUuid),
      'movementType': serializer.toJson<String>(movementType),
      'consumedQty': serializer.toJson<double>(consumedQty),
      'unitCost': serializer.toJson<double>(unitCost),
      'totalCost': serializer.toJson<double>(totalCost),
      'createdAt': serializer.toJson<int>(createdAt),
      'companyId': serializer.toJson<String?>(companyId),
    };
  }

  InventoryCostConsumptionRow copyWith({
    int? id,
    String? uuid,
    String? layerUuid,
    String? issueLineUuid,
    String? movementType,
    double? consumedQty,
    double? unitCost,
    double? totalCost,
    int? createdAt,
    Value<String?> companyId = const Value.absent(),
  }) => InventoryCostConsumptionRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    layerUuid: layerUuid ?? this.layerUuid,
    issueLineUuid: issueLineUuid ?? this.issueLineUuid,
    movementType: movementType ?? this.movementType,
    consumedQty: consumedQty ?? this.consumedQty,
    unitCost: unitCost ?? this.unitCost,
    totalCost: totalCost ?? this.totalCost,
    createdAt: createdAt ?? this.createdAt,
    companyId: companyId.present ? companyId.value : this.companyId,
  );
  InventoryCostConsumptionRow copyWithCompanion(
    InventoryCostConsumptionsCompanion data,
  ) {
    return InventoryCostConsumptionRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      layerUuid: data.layerUuid.present ? data.layerUuid.value : this.layerUuid,
      issueLineUuid: data.issueLineUuid.present
          ? data.issueLineUuid.value
          : this.issueLineUuid,
      movementType: data.movementType.present
          ? data.movementType.value
          : this.movementType,
      consumedQty: data.consumedQty.present
          ? data.consumedQty.value
          : this.consumedQty,
      unitCost: data.unitCost.present ? data.unitCost.value : this.unitCost,
      totalCost: data.totalCost.present ? data.totalCost.value : this.totalCost,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryCostConsumptionRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('layerUuid: $layerUuid, ')
          ..write('issueLineUuid: $issueLineUuid, ')
          ..write('movementType: $movementType, ')
          ..write('consumedQty: $consumedQty, ')
          ..write('unitCost: $unitCost, ')
          ..write('totalCost: $totalCost, ')
          ..write('createdAt: $createdAt, ')
          ..write('companyId: $companyId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    layerUuid,
    issueLineUuid,
    movementType,
    consumedQty,
    unitCost,
    totalCost,
    createdAt,
    companyId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryCostConsumptionRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.layerUuid == this.layerUuid &&
          other.issueLineUuid == this.issueLineUuid &&
          other.movementType == this.movementType &&
          other.consumedQty == this.consumedQty &&
          other.unitCost == this.unitCost &&
          other.totalCost == this.totalCost &&
          other.createdAt == this.createdAt &&
          other.companyId == this.companyId);
}

class InventoryCostConsumptionsCompanion
    extends UpdateCompanion<InventoryCostConsumptionRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> layerUuid;
  final Value<String> issueLineUuid;
  final Value<String> movementType;
  final Value<double> consumedQty;
  final Value<double> unitCost;
  final Value<double> totalCost;
  final Value<int> createdAt;
  final Value<String?> companyId;
  const InventoryCostConsumptionsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.layerUuid = const Value.absent(),
    this.issueLineUuid = const Value.absent(),
    this.movementType = const Value.absent(),
    this.consumedQty = const Value.absent(),
    this.unitCost = const Value.absent(),
    this.totalCost = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.companyId = const Value.absent(),
  });
  InventoryCostConsumptionsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String layerUuid,
    required String issueLineUuid,
    required String movementType,
    this.consumedQty = const Value.absent(),
    this.unitCost = const Value.absent(),
    this.totalCost = const Value.absent(),
    required int createdAt,
    this.companyId = const Value.absent(),
  }) : uuid = Value(uuid),
       layerUuid = Value(layerUuid),
       issueLineUuid = Value(issueLineUuid),
       movementType = Value(movementType),
       createdAt = Value(createdAt);
  static Insertable<InventoryCostConsumptionRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? layerUuid,
    Expression<String>? issueLineUuid,
    Expression<String>? movementType,
    Expression<double>? consumedQty,
    Expression<double>? unitCost,
    Expression<double>? totalCost,
    Expression<int>? createdAt,
    Expression<String>? companyId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (layerUuid != null) 'layer_uuid': layerUuid,
      if (issueLineUuid != null) 'issue_line_uuid': issueLineUuid,
      if (movementType != null) 'movement_type': movementType,
      if (consumedQty != null) 'consumed_qty': consumedQty,
      if (unitCost != null) 'unit_cost': unitCost,
      if (totalCost != null) 'total_cost': totalCost,
      if (createdAt != null) 'created_at': createdAt,
      if (companyId != null) 'company_id': companyId,
    });
  }

  InventoryCostConsumptionsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? layerUuid,
    Value<String>? issueLineUuid,
    Value<String>? movementType,
    Value<double>? consumedQty,
    Value<double>? unitCost,
    Value<double>? totalCost,
    Value<int>? createdAt,
    Value<String?>? companyId,
  }) {
    return InventoryCostConsumptionsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      layerUuid: layerUuid ?? this.layerUuid,
      issueLineUuid: issueLineUuid ?? this.issueLineUuid,
      movementType: movementType ?? this.movementType,
      consumedQty: consumedQty ?? this.consumedQty,
      unitCost: unitCost ?? this.unitCost,
      totalCost: totalCost ?? this.totalCost,
      createdAt: createdAt ?? this.createdAt,
      companyId: companyId ?? this.companyId,
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
    if (layerUuid.present) {
      map['layer_uuid'] = Variable<String>(layerUuid.value);
    }
    if (issueLineUuid.present) {
      map['issue_line_uuid'] = Variable<String>(issueLineUuid.value);
    }
    if (movementType.present) {
      map['movement_type'] = Variable<String>(movementType.value);
    }
    if (consumedQty.present) {
      map['consumed_qty'] = Variable<double>(consumedQty.value);
    }
    if (unitCost.present) {
      map['unit_cost'] = Variable<double>(unitCost.value);
    }
    if (totalCost.present) {
      map['total_cost'] = Variable<double>(totalCost.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryCostConsumptionsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('layerUuid: $layerUuid, ')
          ..write('issueLineUuid: $issueLineUuid, ')
          ..write('movementType: $movementType, ')
          ..write('consumedQty: $consumedQty, ')
          ..write('unitCost: $unitCost, ')
          ..write('totalCost: $totalCost, ')
          ..write('createdAt: $createdAt, ')
          ..write('companyId: $companyId')
          ..write(')'))
        .toString();
  }
}

class $StockReturnsTable extends StockReturns
    with TableInfo<$StockReturnsTable, StockReturnRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockReturnsTable(this.attachedDatabase, [this._alias]);
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
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _returnNumberMeta = const VerificationMeta(
    'returnNumber',
  );
  @override
  late final GeneratedColumn<String> returnNumber = GeneratedColumn<String>(
    'return_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _returnTypeMeta = const VerificationMeta(
    'returnType',
  );
  @override
  late final GeneratedColumn<String> returnType = GeneratedColumn<String>(
    'return_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalMovementUuidMeta =
      const VerificationMeta('originalMovementUuid');
  @override
  late final GeneratedColumn<String> originalMovementUuid =
      GeneratedColumn<String>(
        'original_movement_uuid',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _partyNameMeta = const VerificationMeta(
    'partyName',
  );
  @override
  late final GeneratedColumn<String> partyName = GeneratedColumn<String>(
    'party_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _warehouseMeta = const VerificationMeta(
    'warehouse',
  );
  @override
  late final GeneratedColumn<String> warehouse = GeneratedColumn<String>(
    'warehouse',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _returnDateMeta = const VerificationMeta(
    'returnDate',
  );
  @override
  late final GeneratedColumn<int> returnDate = GeneratedColumn<int>(
    'return_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
    defaultValue: const Constant('pending'),
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
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
  );
  static const VerificationMeta _postedAtMeta = const VerificationMeta(
    'postedAt',
  );
  @override
  late final GeneratedColumn<int> postedAt = GeneratedColumn<int>(
    'posted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
    returnNumber,
    returnType,
    originalMovementUuid,
    partyName,
    warehouse,
    notes,
    returnDate,
    createdAt,
    updatedAt,
    syncStatus,
    lastSyncedAt,
    version,
    companyId,
    status,
    postedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_returns';
  @override
  VerificationContext validateIntegrity(
    Insertable<StockReturnRow> instance, {
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
    if (data.containsKey('return_number')) {
      context.handle(
        _returnNumberMeta,
        returnNumber.isAcceptableOrUnknown(
          data['return_number']!,
          _returnNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_returnNumberMeta);
    }
    if (data.containsKey('return_type')) {
      context.handle(
        _returnTypeMeta,
        returnType.isAcceptableOrUnknown(data['return_type']!, _returnTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_returnTypeMeta);
    }
    if (data.containsKey('original_movement_uuid')) {
      context.handle(
        _originalMovementUuidMeta,
        originalMovementUuid.isAcceptableOrUnknown(
          data['original_movement_uuid']!,
          _originalMovementUuidMeta,
        ),
      );
    }
    if (data.containsKey('party_name')) {
      context.handle(
        _partyNameMeta,
        partyName.isAcceptableOrUnknown(data['party_name']!, _partyNameMeta),
      );
    }
    if (data.containsKey('warehouse')) {
      context.handle(
        _warehouseMeta,
        warehouse.isAcceptableOrUnknown(data['warehouse']!, _warehouseMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('return_date')) {
      context.handle(
        _returnDateMeta,
        returnDate.isAcceptableOrUnknown(data['return_date']!, _returnDateMeta),
      );
    } else if (isInserting) {
      context.missing(_returnDateMeta);
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
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('posted_at')) {
      context.handle(
        _postedAtMeta,
        postedAt.isAcceptableOrUnknown(data['posted_at']!, _postedAtMeta),
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
  StockReturnRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockReturnRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      returnNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}return_number'],
      )!,
      returnType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}return_type'],
      )!,
      originalMovementUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_movement_uuid'],
      ),
      partyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}party_name'],
      ),
      warehouse: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}warehouse'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      returnDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}return_date'],
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
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      postedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}posted_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $StockReturnsTable createAlias(String alias) {
    return $StockReturnsTable(attachedDatabase, alias);
  }
}

class StockReturnRow extends DataClass implements Insertable<StockReturnRow> {
  final int id;
  final String uuid;
  final String returnNumber;
  final String returnType;
  final String? originalMovementUuid;
  final String? partyName;
  final String? warehouse;
  final String? notes;
  final int returnDate;
  final int createdAt;
  final int updatedAt;
  final String syncStatus;
  final int? lastSyncedAt;
  final int version;
  final String? companyId;

  /// Document posting status ('draft', 'posted', 'cancelled')
  final String status;

  /// Epoch UTC timestamp when the document was posted
  final int? postedAt;
  final int? deletedAt;
  const StockReturnRow({
    required this.id,
    required this.uuid,
    required this.returnNumber,
    required this.returnType,
    this.originalMovementUuid,
    this.partyName,
    this.warehouse,
    this.notes,
    required this.returnDate,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.lastSyncedAt,
    required this.version,
    this.companyId,
    required this.status,
    this.postedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['return_number'] = Variable<String>(returnNumber);
    map['return_type'] = Variable<String>(returnType);
    if (!nullToAbsent || originalMovementUuid != null) {
      map['original_movement_uuid'] = Variable<String>(originalMovementUuid);
    }
    if (!nullToAbsent || partyName != null) {
      map['party_name'] = Variable<String>(partyName);
    }
    if (!nullToAbsent || warehouse != null) {
      map['warehouse'] = Variable<String>(warehouse);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['return_date'] = Variable<int>(returnDate);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt);
    }
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || companyId != null) {
      map['company_id'] = Variable<String>(companyId);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || postedAt != null) {
      map['posted_at'] = Variable<int>(postedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  StockReturnsCompanion toCompanion(bool nullToAbsent) {
    return StockReturnsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      returnNumber: Value(returnNumber),
      returnType: Value(returnType),
      originalMovementUuid: originalMovementUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(originalMovementUuid),
      partyName: partyName == null && nullToAbsent
          ? const Value.absent()
          : Value(partyName),
      warehouse: warehouse == null && nullToAbsent
          ? const Value.absent()
          : Value(warehouse),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      returnDate: Value(returnDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      version: Value(version),
      companyId: companyId == null && nullToAbsent
          ? const Value.absent()
          : Value(companyId),
      status: Value(status),
      postedAt: postedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(postedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory StockReturnRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockReturnRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      returnNumber: serializer.fromJson<String>(json['returnNumber']),
      returnType: serializer.fromJson<String>(json['returnType']),
      originalMovementUuid: serializer.fromJson<String?>(
        json['originalMovementUuid'],
      ),
      partyName: serializer.fromJson<String?>(json['partyName']),
      warehouse: serializer.fromJson<String?>(json['warehouse']),
      notes: serializer.fromJson<String?>(json['notes']),
      returnDate: serializer.fromJson<int>(json['returnDate']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      lastSyncedAt: serializer.fromJson<int?>(json['lastSyncedAt']),
      version: serializer.fromJson<int>(json['version']),
      companyId: serializer.fromJson<String?>(json['companyId']),
      status: serializer.fromJson<String>(json['status']),
      postedAt: serializer.fromJson<int?>(json['postedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'returnNumber': serializer.toJson<String>(returnNumber),
      'returnType': serializer.toJson<String>(returnType),
      'originalMovementUuid': serializer.toJson<String?>(originalMovementUuid),
      'partyName': serializer.toJson<String?>(partyName),
      'warehouse': serializer.toJson<String?>(warehouse),
      'notes': serializer.toJson<String?>(notes),
      'returnDate': serializer.toJson<int>(returnDate),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'lastSyncedAt': serializer.toJson<int?>(lastSyncedAt),
      'version': serializer.toJson<int>(version),
      'companyId': serializer.toJson<String?>(companyId),
      'status': serializer.toJson<String>(status),
      'postedAt': serializer.toJson<int?>(postedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  StockReturnRow copyWith({
    int? id,
    String? uuid,
    String? returnNumber,
    String? returnType,
    Value<String?> originalMovementUuid = const Value.absent(),
    Value<String?> partyName = const Value.absent(),
    Value<String?> warehouse = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    int? returnDate,
    int? createdAt,
    int? updatedAt,
    String? syncStatus,
    Value<int?> lastSyncedAt = const Value.absent(),
    int? version,
    Value<String?> companyId = const Value.absent(),
    String? status,
    Value<int?> postedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
  }) => StockReturnRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    returnNumber: returnNumber ?? this.returnNumber,
    returnType: returnType ?? this.returnType,
    originalMovementUuid: originalMovementUuid.present
        ? originalMovementUuid.value
        : this.originalMovementUuid,
    partyName: partyName.present ? partyName.value : this.partyName,
    warehouse: warehouse.present ? warehouse.value : this.warehouse,
    notes: notes.present ? notes.value : this.notes,
    returnDate: returnDate ?? this.returnDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    version: version ?? this.version,
    companyId: companyId.present ? companyId.value : this.companyId,
    status: status ?? this.status,
    postedAt: postedAt.present ? postedAt.value : this.postedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  StockReturnRow copyWithCompanion(StockReturnsCompanion data) {
    return StockReturnRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      returnNumber: data.returnNumber.present
          ? data.returnNumber.value
          : this.returnNumber,
      returnType: data.returnType.present
          ? data.returnType.value
          : this.returnType,
      originalMovementUuid: data.originalMovementUuid.present
          ? data.originalMovementUuid.value
          : this.originalMovementUuid,
      partyName: data.partyName.present ? data.partyName.value : this.partyName,
      warehouse: data.warehouse.present ? data.warehouse.value : this.warehouse,
      notes: data.notes.present ? data.notes.value : this.notes,
      returnDate: data.returnDate.present
          ? data.returnDate.value
          : this.returnDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      version: data.version.present ? data.version.value : this.version,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      status: data.status.present ? data.status.value : this.status,
      postedAt: data.postedAt.present ? data.postedAt.value : this.postedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockReturnRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('returnNumber: $returnNumber, ')
          ..write('returnType: $returnType, ')
          ..write('originalMovementUuid: $originalMovementUuid, ')
          ..write('partyName: $partyName, ')
          ..write('warehouse: $warehouse, ')
          ..write('notes: $notes, ')
          ..write('returnDate: $returnDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('version: $version, ')
          ..write('companyId: $companyId, ')
          ..write('status: $status, ')
          ..write('postedAt: $postedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    returnNumber,
    returnType,
    originalMovementUuid,
    partyName,
    warehouse,
    notes,
    returnDate,
    createdAt,
    updatedAt,
    syncStatus,
    lastSyncedAt,
    version,
    companyId,
    status,
    postedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockReturnRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.returnNumber == this.returnNumber &&
          other.returnType == this.returnType &&
          other.originalMovementUuid == this.originalMovementUuid &&
          other.partyName == this.partyName &&
          other.warehouse == this.warehouse &&
          other.notes == this.notes &&
          other.returnDate == this.returnDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.version == this.version &&
          other.companyId == this.companyId &&
          other.status == this.status &&
          other.postedAt == this.postedAt &&
          other.deletedAt == this.deletedAt);
}

class StockReturnsCompanion extends UpdateCompanion<StockReturnRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> returnNumber;
  final Value<String> returnType;
  final Value<String?> originalMovementUuid;
  final Value<String?> partyName;
  final Value<String?> warehouse;
  final Value<String?> notes;
  final Value<int> returnDate;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> syncStatus;
  final Value<int?> lastSyncedAt;
  final Value<int> version;
  final Value<String?> companyId;
  final Value<String> status;
  final Value<int?> postedAt;
  final Value<int?> deletedAt;
  const StockReturnsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.returnNumber = const Value.absent(),
    this.returnType = const Value.absent(),
    this.originalMovementUuid = const Value.absent(),
    this.partyName = const Value.absent(),
    this.warehouse = const Value.absent(),
    this.notes = const Value.absent(),
    this.returnDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.companyId = const Value.absent(),
    this.status = const Value.absent(),
    this.postedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  StockReturnsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String returnNumber,
    required String returnType,
    this.originalMovementUuid = const Value.absent(),
    this.partyName = const Value.absent(),
    this.warehouse = const Value.absent(),
    this.notes = const Value.absent(),
    required int returnDate,
    required int createdAt,
    required int updatedAt,
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.companyId = const Value.absent(),
    this.status = const Value.absent(),
    this.postedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : uuid = Value(uuid),
       returnNumber = Value(returnNumber),
       returnType = Value(returnType),
       returnDate = Value(returnDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<StockReturnRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? returnNumber,
    Expression<String>? returnType,
    Expression<String>? originalMovementUuid,
    Expression<String>? partyName,
    Expression<String>? warehouse,
    Expression<String>? notes,
    Expression<int>? returnDate,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? syncStatus,
    Expression<int>? lastSyncedAt,
    Expression<int>? version,
    Expression<String>? companyId,
    Expression<String>? status,
    Expression<int>? postedAt,
    Expression<int>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (returnNumber != null) 'return_number': returnNumber,
      if (returnType != null) 'return_type': returnType,
      if (originalMovementUuid != null)
        'original_movement_uuid': originalMovementUuid,
      if (partyName != null) 'party_name': partyName,
      if (warehouse != null) 'warehouse': warehouse,
      if (notes != null) 'notes': notes,
      if (returnDate != null) 'return_date': returnDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (version != null) 'version': version,
      if (companyId != null) 'company_id': companyId,
      if (status != null) 'status': status,
      if (postedAt != null) 'posted_at': postedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  StockReturnsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? returnNumber,
    Value<String>? returnType,
    Value<String?>? originalMovementUuid,
    Value<String?>? partyName,
    Value<String?>? warehouse,
    Value<String?>? notes,
    Value<int>? returnDate,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? syncStatus,
    Value<int?>? lastSyncedAt,
    Value<int>? version,
    Value<String?>? companyId,
    Value<String>? status,
    Value<int?>? postedAt,
    Value<int?>? deletedAt,
  }) {
    return StockReturnsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      returnNumber: returnNumber ?? this.returnNumber,
      returnType: returnType ?? this.returnType,
      originalMovementUuid: originalMovementUuid ?? this.originalMovementUuid,
      partyName: partyName ?? this.partyName,
      warehouse: warehouse ?? this.warehouse,
      notes: notes ?? this.notes,
      returnDate: returnDate ?? this.returnDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      version: version ?? this.version,
      companyId: companyId ?? this.companyId,
      status: status ?? this.status,
      postedAt: postedAt ?? this.postedAt,
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
    if (returnNumber.present) {
      map['return_number'] = Variable<String>(returnNumber.value);
    }
    if (returnType.present) {
      map['return_type'] = Variable<String>(returnType.value);
    }
    if (originalMovementUuid.present) {
      map['original_movement_uuid'] = Variable<String>(
        originalMovementUuid.value,
      );
    }
    if (partyName.present) {
      map['party_name'] = Variable<String>(partyName.value);
    }
    if (warehouse.present) {
      map['warehouse'] = Variable<String>(warehouse.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (returnDate.present) {
      map['return_date'] = Variable<int>(returnDate.value);
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
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (postedAt.present) {
      map['posted_at'] = Variable<int>(postedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockReturnsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('returnNumber: $returnNumber, ')
          ..write('returnType: $returnType, ')
          ..write('originalMovementUuid: $originalMovementUuid, ')
          ..write('partyName: $partyName, ')
          ..write('warehouse: $warehouse, ')
          ..write('notes: $notes, ')
          ..write('returnDate: $returnDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('version: $version, ')
          ..write('companyId: $companyId, ')
          ..write('status: $status, ')
          ..write('postedAt: $postedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $WarehousesTable extends Warehouses
    with TableInfo<$WarehousesTable, WarehouseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WarehousesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
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
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
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
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _managerNameMeta = const VerificationMeta(
    'managerName',
  );
  @override
  late final GeneratedColumn<String> managerName = GeneratedColumn<String>(
    'manager_name',
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
    defaultValue: const Constant('pending'),
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
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    uuid,
    code,
    name,
    isDefault,
    isActive,
    address,
    phone,
    managerName,
    createdAt,
    updatedAt,
    syncStatus,
    version,
    companyId,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'warehouses';
  @override
  VerificationContext validateIntegrity(
    Insertable<WarehouseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
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
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('manager_name')) {
      context.handle(
        _managerNameMeta,
        managerName.isAcceptableOrUnknown(
          data['manager_name']!,
          _managerNameMeta,
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
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
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
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  WarehouseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WarehouseRow(
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
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      managerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manager_name'],
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
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $WarehousesTable createAlias(String alias) {
    return $WarehousesTable(attachedDatabase, alias);
  }
}

class WarehouseRow extends DataClass implements Insertable<WarehouseRow> {
  final String uuid;
  final String code;
  final String name;
  final bool isDefault;
  final bool isActive;
  final String? address;
  final String? phone;
  final String? managerName;
  final int createdAt;
  final int updatedAt;
  final String syncStatus;
  final int version;
  final String? companyId;
  final int? deletedAt;
  const WarehouseRow({
    required this.uuid,
    required this.code,
    required this.name,
    required this.isDefault,
    required this.isActive,
    this.address,
    this.phone,
    this.managerName,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    required this.version,
    this.companyId,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['is_default'] = Variable<bool>(isDefault);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || managerName != null) {
      map['manager_name'] = Variable<String>(managerName);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || companyId != null) {
      map['company_id'] = Variable<String>(companyId);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  WarehousesCompanion toCompanion(bool nullToAbsent) {
    return WarehousesCompanion(
      uuid: Value(uuid),
      code: Value(code),
      name: Value(name),
      isDefault: Value(isDefault),
      isActive: Value(isActive),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      managerName: managerName == null && nullToAbsent
          ? const Value.absent()
          : Value(managerName),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      version: Value(version),
      companyId: companyId == null && nullToAbsent
          ? const Value.absent()
          : Value(companyId),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory WarehouseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WarehouseRow(
      uuid: serializer.fromJson<String>(json['uuid']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      address: serializer.fromJson<String?>(json['address']),
      phone: serializer.fromJson<String?>(json['phone']),
      managerName: serializer.fromJson<String?>(json['managerName']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      version: serializer.fromJson<int>(json['version']),
      companyId: serializer.fromJson<String?>(json['companyId']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'isDefault': serializer.toJson<bool>(isDefault),
      'isActive': serializer.toJson<bool>(isActive),
      'address': serializer.toJson<String?>(address),
      'phone': serializer.toJson<String?>(phone),
      'managerName': serializer.toJson<String?>(managerName),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'version': serializer.toJson<int>(version),
      'companyId': serializer.toJson<String?>(companyId),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  WarehouseRow copyWith({
    String? uuid,
    String? code,
    String? name,
    bool? isDefault,
    bool? isActive,
    Value<String?> address = const Value.absent(),
    Value<String?> phone = const Value.absent(),
    Value<String?> managerName = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    String? syncStatus,
    int? version,
    Value<String?> companyId = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
  }) => WarehouseRow(
    uuid: uuid ?? this.uuid,
    code: code ?? this.code,
    name: name ?? this.name,
    isDefault: isDefault ?? this.isDefault,
    isActive: isActive ?? this.isActive,
    address: address.present ? address.value : this.address,
    phone: phone.present ? phone.value : this.phone,
    managerName: managerName.present ? managerName.value : this.managerName,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    version: version ?? this.version,
    companyId: companyId.present ? companyId.value : this.companyId,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  WarehouseRow copyWithCompanion(WarehousesCompanion data) {
    return WarehouseRow(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      address: data.address.present ? data.address.value : this.address,
      phone: data.phone.present ? data.phone.value : this.phone,
      managerName: data.managerName.present
          ? data.managerName.value
          : this.managerName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      version: data.version.present ? data.version.value : this.version,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WarehouseRow(')
          ..write('uuid: $uuid, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('isDefault: $isDefault, ')
          ..write('isActive: $isActive, ')
          ..write('address: $address, ')
          ..write('phone: $phone, ')
          ..write('managerName: $managerName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version, ')
          ..write('companyId: $companyId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    code,
    name,
    isDefault,
    isActive,
    address,
    phone,
    managerName,
    createdAt,
    updatedAt,
    syncStatus,
    version,
    companyId,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WarehouseRow &&
          other.uuid == this.uuid &&
          other.code == this.code &&
          other.name == this.name &&
          other.isDefault == this.isDefault &&
          other.isActive == this.isActive &&
          other.address == this.address &&
          other.phone == this.phone &&
          other.managerName == this.managerName &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.version == this.version &&
          other.companyId == this.companyId &&
          other.deletedAt == this.deletedAt);
}

class WarehousesCompanion extends UpdateCompanion<WarehouseRow> {
  final Value<String> uuid;
  final Value<String> code;
  final Value<String> name;
  final Value<bool> isDefault;
  final Value<bool> isActive;
  final Value<String?> address;
  final Value<String?> phone;
  final Value<String?> managerName;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> syncStatus;
  final Value<int> version;
  final Value<String?> companyId;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const WarehousesCompanion({
    this.uuid = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.isActive = const Value.absent(),
    this.address = const Value.absent(),
    this.phone = const Value.absent(),
    this.managerName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.companyId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WarehousesCompanion.insert({
    required String uuid,
    required String code,
    required String name,
    this.isDefault = const Value.absent(),
    this.isActive = const Value.absent(),
    this.address = const Value.absent(),
    this.phone = const Value.absent(),
    this.managerName = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.companyId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       code = Value(code),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<WarehouseRow> custom({
    Expression<String>? uuid,
    Expression<String>? code,
    Expression<String>? name,
    Expression<bool>? isDefault,
    Expression<bool>? isActive,
    Expression<String>? address,
    Expression<String>? phone,
    Expression<String>? managerName,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? syncStatus,
    Expression<int>? version,
    Expression<String>? companyId,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (isDefault != null) 'is_default': isDefault,
      if (isActive != null) 'is_active': isActive,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      if (managerName != null) 'manager_name': managerName,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (version != null) 'version': version,
      if (companyId != null) 'company_id': companyId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WarehousesCompanion copyWith({
    Value<String>? uuid,
    Value<String>? code,
    Value<String>? name,
    Value<bool>? isDefault,
    Value<bool>? isActive,
    Value<String?>? address,
    Value<String?>? phone,
    Value<String?>? managerName,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? syncStatus,
    Value<int>? version,
    Value<String?>? companyId,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return WarehousesCompanion(
      uuid: uuid ?? this.uuid,
      code: code ?? this.code,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      managerName: managerName ?? this.managerName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
      companyId: companyId ?? this.companyId,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (managerName.present) {
      map['manager_name'] = Variable<String>(managerName.value);
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
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WarehousesCompanion(')
          ..write('uuid: $uuid, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('isDefault: $isDefault, ')
          ..write('isActive: $isActive, ')
          ..write('address: $address, ')
          ..write('phone: $phone, ')
          ..write('managerName: $managerName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version, ')
          ..write('companyId: $companyId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductWarehouseStocksTable extends ProductWarehouseStocks
    with TableInfo<$ProductWarehouseStocksTable, ProductWarehouseStockRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductWarehouseStocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemCodeMeta = const VerificationMeta(
    'itemCode',
  );
  @override
  late final GeneratedColumn<String> itemCode = GeneratedColumn<String>(
    'item_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _warehouseIdMeta = const VerificationMeta(
    'warehouseId',
  );
  @override
  late final GeneratedColumn<String> warehouseId = GeneratedColumn<String>(
    'warehouse_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _onHandQtyMeta = const VerificationMeta(
    'onHandQty',
  );
  @override
  late final GeneratedColumn<double> onHandQty = GeneratedColumn<double>(
    'on_hand_qty',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _minReorderLevelMeta = const VerificationMeta(
    'minReorderLevel',
  );
  @override
  late final GeneratedColumn<double> minReorderLevel = GeneratedColumn<double>(
    'min_reorder_level',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _binLocationMeta = const VerificationMeta(
    'binLocation',
  );
  @override
  late final GeneratedColumn<String> binLocation = GeneratedColumn<String>(
    'bin_location',
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
    defaultValue: const Constant('pending'),
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
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    uuid,
    itemCode,
    warehouseId,
    onHandQty,
    minReorderLevel,
    binLocation,
    createdAt,
    updatedAt,
    syncStatus,
    version,
    companyId,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_warehouse_stocks';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductWarehouseStockRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('item_code')) {
      context.handle(
        _itemCodeMeta,
        itemCode.isAcceptableOrUnknown(data['item_code']!, _itemCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_itemCodeMeta);
    }
    if (data.containsKey('warehouse_id')) {
      context.handle(
        _warehouseIdMeta,
        warehouseId.isAcceptableOrUnknown(
          data['warehouse_id']!,
          _warehouseIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_warehouseIdMeta);
    }
    if (data.containsKey('on_hand_qty')) {
      context.handle(
        _onHandQtyMeta,
        onHandQty.isAcceptableOrUnknown(data['on_hand_qty']!, _onHandQtyMeta),
      );
    }
    if (data.containsKey('min_reorder_level')) {
      context.handle(
        _minReorderLevelMeta,
        minReorderLevel.isAcceptableOrUnknown(
          data['min_reorder_level']!,
          _minReorderLevelMeta,
        ),
      );
    }
    if (data.containsKey('bin_location')) {
      context.handle(
        _binLocationMeta,
        binLocation.isAcceptableOrUnknown(
          data['bin_location']!,
          _binLocationMeta,
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
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
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
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {itemCode, warehouseId},
  ];
  @override
  ProductWarehouseStockRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductWarehouseStockRow(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      itemCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_code'],
      )!,
      warehouseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}warehouse_id'],
      )!,
      onHandQty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}on_hand_qty'],
      )!,
      minReorderLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_reorder_level'],
      ),
      binLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bin_location'],
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
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $ProductWarehouseStocksTable createAlias(String alias) {
    return $ProductWarehouseStocksTable(attachedDatabase, alias);
  }
}

class ProductWarehouseStockRow extends DataClass
    implements Insertable<ProductWarehouseStockRow> {
  final String uuid;
  final String itemCode;
  final String warehouseId;
  final double onHandQty;
  final double? minReorderLevel;
  final String? binLocation;
  final int createdAt;
  final int updatedAt;
  final String syncStatus;
  final int version;
  final String? companyId;
  final int? deletedAt;
  const ProductWarehouseStockRow({
    required this.uuid,
    required this.itemCode,
    required this.warehouseId,
    required this.onHandQty,
    this.minReorderLevel,
    this.binLocation,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    required this.version,
    this.companyId,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['item_code'] = Variable<String>(itemCode);
    map['warehouse_id'] = Variable<String>(warehouseId);
    map['on_hand_qty'] = Variable<double>(onHandQty);
    if (!nullToAbsent || minReorderLevel != null) {
      map['min_reorder_level'] = Variable<double>(minReorderLevel);
    }
    if (!nullToAbsent || binLocation != null) {
      map['bin_location'] = Variable<String>(binLocation);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || companyId != null) {
      map['company_id'] = Variable<String>(companyId);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  ProductWarehouseStocksCompanion toCompanion(bool nullToAbsent) {
    return ProductWarehouseStocksCompanion(
      uuid: Value(uuid),
      itemCode: Value(itemCode),
      warehouseId: Value(warehouseId),
      onHandQty: Value(onHandQty),
      minReorderLevel: minReorderLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(minReorderLevel),
      binLocation: binLocation == null && nullToAbsent
          ? const Value.absent()
          : Value(binLocation),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      version: Value(version),
      companyId: companyId == null && nullToAbsent
          ? const Value.absent()
          : Value(companyId),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory ProductWarehouseStockRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductWarehouseStockRow(
      uuid: serializer.fromJson<String>(json['uuid']),
      itemCode: serializer.fromJson<String>(json['itemCode']),
      warehouseId: serializer.fromJson<String>(json['warehouseId']),
      onHandQty: serializer.fromJson<double>(json['onHandQty']),
      minReorderLevel: serializer.fromJson<double?>(json['minReorderLevel']),
      binLocation: serializer.fromJson<String?>(json['binLocation']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      version: serializer.fromJson<int>(json['version']),
      companyId: serializer.fromJson<String?>(json['companyId']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'itemCode': serializer.toJson<String>(itemCode),
      'warehouseId': serializer.toJson<String>(warehouseId),
      'onHandQty': serializer.toJson<double>(onHandQty),
      'minReorderLevel': serializer.toJson<double?>(minReorderLevel),
      'binLocation': serializer.toJson<String?>(binLocation),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'version': serializer.toJson<int>(version),
      'companyId': serializer.toJson<String?>(companyId),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  ProductWarehouseStockRow copyWith({
    String? uuid,
    String? itemCode,
    String? warehouseId,
    double? onHandQty,
    Value<double?> minReorderLevel = const Value.absent(),
    Value<String?> binLocation = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    String? syncStatus,
    int? version,
    Value<String?> companyId = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
  }) => ProductWarehouseStockRow(
    uuid: uuid ?? this.uuid,
    itemCode: itemCode ?? this.itemCode,
    warehouseId: warehouseId ?? this.warehouseId,
    onHandQty: onHandQty ?? this.onHandQty,
    minReorderLevel: minReorderLevel.present
        ? minReorderLevel.value
        : this.minReorderLevel,
    binLocation: binLocation.present ? binLocation.value : this.binLocation,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    version: version ?? this.version,
    companyId: companyId.present ? companyId.value : this.companyId,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  ProductWarehouseStockRow copyWithCompanion(
    ProductWarehouseStocksCompanion data,
  ) {
    return ProductWarehouseStockRow(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      itemCode: data.itemCode.present ? data.itemCode.value : this.itemCode,
      warehouseId: data.warehouseId.present
          ? data.warehouseId.value
          : this.warehouseId,
      onHandQty: data.onHandQty.present ? data.onHandQty.value : this.onHandQty,
      minReorderLevel: data.minReorderLevel.present
          ? data.minReorderLevel.value
          : this.minReorderLevel,
      binLocation: data.binLocation.present
          ? data.binLocation.value
          : this.binLocation,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      version: data.version.present ? data.version.value : this.version,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductWarehouseStockRow(')
          ..write('uuid: $uuid, ')
          ..write('itemCode: $itemCode, ')
          ..write('warehouseId: $warehouseId, ')
          ..write('onHandQty: $onHandQty, ')
          ..write('minReorderLevel: $minReorderLevel, ')
          ..write('binLocation: $binLocation, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version, ')
          ..write('companyId: $companyId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    itemCode,
    warehouseId,
    onHandQty,
    minReorderLevel,
    binLocation,
    createdAt,
    updatedAt,
    syncStatus,
    version,
    companyId,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductWarehouseStockRow &&
          other.uuid == this.uuid &&
          other.itemCode == this.itemCode &&
          other.warehouseId == this.warehouseId &&
          other.onHandQty == this.onHandQty &&
          other.minReorderLevel == this.minReorderLevel &&
          other.binLocation == this.binLocation &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.version == this.version &&
          other.companyId == this.companyId &&
          other.deletedAt == this.deletedAt);
}

class ProductWarehouseStocksCompanion
    extends UpdateCompanion<ProductWarehouseStockRow> {
  final Value<String> uuid;
  final Value<String> itemCode;
  final Value<String> warehouseId;
  final Value<double> onHandQty;
  final Value<double?> minReorderLevel;
  final Value<String?> binLocation;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> syncStatus;
  final Value<int> version;
  final Value<String?> companyId;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const ProductWarehouseStocksCompanion({
    this.uuid = const Value.absent(),
    this.itemCode = const Value.absent(),
    this.warehouseId = const Value.absent(),
    this.onHandQty = const Value.absent(),
    this.minReorderLevel = const Value.absent(),
    this.binLocation = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.companyId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductWarehouseStocksCompanion.insert({
    required String uuid,
    required String itemCode,
    required String warehouseId,
    this.onHandQty = const Value.absent(),
    this.minReorderLevel = const Value.absent(),
    this.binLocation = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.companyId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       itemCode = Value(itemCode),
       warehouseId = Value(warehouseId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ProductWarehouseStockRow> custom({
    Expression<String>? uuid,
    Expression<String>? itemCode,
    Expression<String>? warehouseId,
    Expression<double>? onHandQty,
    Expression<double>? minReorderLevel,
    Expression<String>? binLocation,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? syncStatus,
    Expression<int>? version,
    Expression<String>? companyId,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (itemCode != null) 'item_code': itemCode,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      if (onHandQty != null) 'on_hand_qty': onHandQty,
      if (minReorderLevel != null) 'min_reorder_level': minReorderLevel,
      if (binLocation != null) 'bin_location': binLocation,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (version != null) 'version': version,
      if (companyId != null) 'company_id': companyId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductWarehouseStocksCompanion copyWith({
    Value<String>? uuid,
    Value<String>? itemCode,
    Value<String>? warehouseId,
    Value<double>? onHandQty,
    Value<double?>? minReorderLevel,
    Value<String?>? binLocation,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? syncStatus,
    Value<int>? version,
    Value<String?>? companyId,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return ProductWarehouseStocksCompanion(
      uuid: uuid ?? this.uuid,
      itemCode: itemCode ?? this.itemCode,
      warehouseId: warehouseId ?? this.warehouseId,
      onHandQty: onHandQty ?? this.onHandQty,
      minReorderLevel: minReorderLevel ?? this.minReorderLevel,
      binLocation: binLocation ?? this.binLocation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
      companyId: companyId ?? this.companyId,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (itemCode.present) {
      map['item_code'] = Variable<String>(itemCode.value);
    }
    if (warehouseId.present) {
      map['warehouse_id'] = Variable<String>(warehouseId.value);
    }
    if (onHandQty.present) {
      map['on_hand_qty'] = Variable<double>(onHandQty.value);
    }
    if (minReorderLevel.present) {
      map['min_reorder_level'] = Variable<double>(minReorderLevel.value);
    }
    if (binLocation.present) {
      map['bin_location'] = Variable<String>(binLocation.value);
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
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductWarehouseStocksCompanion(')
          ..write('uuid: $uuid, ')
          ..write('itemCode: $itemCode, ')
          ..write('warehouseId: $warehouseId, ')
          ..write('onHandQty: $onHandQty, ')
          ..write('minReorderLevel: $minReorderLevel, ')
          ..write('binLocation: $binLocation, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version, ')
          ..write('companyId: $companyId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StockTransfersTable extends StockTransfers
    with TableInfo<$StockTransfersTable, StockTransferRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockTransfersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transferNumberMeta = const VerificationMeta(
    'transferNumber',
  );
  @override
  late final GeneratedColumn<String> transferNumber = GeneratedColumn<String>(
    'transfer_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _fromWarehouseIdMeta = const VerificationMeta(
    'fromWarehouseId',
  );
  @override
  late final GeneratedColumn<String> fromWarehouseId = GeneratedColumn<String>(
    'from_warehouse_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toWarehouseIdMeta = const VerificationMeta(
    'toWarehouseId',
  );
  @override
  late final GeneratedColumn<String> toWarehouseId = GeneratedColumn<String>(
    'to_warehouse_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transferDateMeta = const VerificationMeta(
    'transferDate',
  );
  @override
  late final GeneratedColumn<int> transferDate = GeneratedColumn<int>(
    'transfer_date',
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
    defaultValue: const Constant('pending'),
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
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
  );
  static const VerificationMeta _postedAtMeta = const VerificationMeta(
    'postedAt',
  );
  @override
  late final GeneratedColumn<int> postedAt = GeneratedColumn<int>(
    'posted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
    uuid,
    transferNumber,
    fromWarehouseId,
    toWarehouseId,
    transferDate,
    notes,
    createdAt,
    updatedAt,
    syncStatus,
    version,
    companyId,
    status,
    postedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_transfers';
  @override
  VerificationContext validateIntegrity(
    Insertable<StockTransferRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('transfer_number')) {
      context.handle(
        _transferNumberMeta,
        transferNumber.isAcceptableOrUnknown(
          data['transfer_number']!,
          _transferNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transferNumberMeta);
    }
    if (data.containsKey('from_warehouse_id')) {
      context.handle(
        _fromWarehouseIdMeta,
        fromWarehouseId.isAcceptableOrUnknown(
          data['from_warehouse_id']!,
          _fromWarehouseIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromWarehouseIdMeta);
    }
    if (data.containsKey('to_warehouse_id')) {
      context.handle(
        _toWarehouseIdMeta,
        toWarehouseId.isAcceptableOrUnknown(
          data['to_warehouse_id']!,
          _toWarehouseIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_toWarehouseIdMeta);
    }
    if (data.containsKey('transfer_date')) {
      context.handle(
        _transferDateMeta,
        transferDate.isAcceptableOrUnknown(
          data['transfer_date']!,
          _transferDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transferDateMeta);
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
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('posted_at')) {
      context.handle(
        _postedAtMeta,
        postedAt.isAcceptableOrUnknown(data['posted_at']!, _postedAtMeta),
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
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  StockTransferRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockTransferRow(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      transferNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transfer_number'],
      )!,
      fromWarehouseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_warehouse_id'],
      )!,
      toWarehouseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_warehouse_id'],
      )!,
      transferDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transfer_date'],
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
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      postedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}posted_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $StockTransfersTable createAlias(String alias) {
    return $StockTransfersTable(attachedDatabase, alias);
  }
}

class StockTransferRow extends DataClass
    implements Insertable<StockTransferRow> {
  final String uuid;
  final String transferNumber;
  final String fromWarehouseId;
  final String toWarehouseId;
  final int transferDate;
  final String? notes;
  final int createdAt;
  final int updatedAt;
  final String syncStatus;
  final int version;
  final String? companyId;

  /// Document posting status ('draft', 'posted', 'cancelled')
  final String status;

  /// Epoch UTC timestamp when the document was posted
  final int? postedAt;
  final int? deletedAt;
  const StockTransferRow({
    required this.uuid,
    required this.transferNumber,
    required this.fromWarehouseId,
    required this.toWarehouseId,
    required this.transferDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    required this.version,
    this.companyId,
    required this.status,
    this.postedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['transfer_number'] = Variable<String>(transferNumber);
    map['from_warehouse_id'] = Variable<String>(fromWarehouseId);
    map['to_warehouse_id'] = Variable<String>(toWarehouseId);
    map['transfer_date'] = Variable<int>(transferDate);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || companyId != null) {
      map['company_id'] = Variable<String>(companyId);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || postedAt != null) {
      map['posted_at'] = Variable<int>(postedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  StockTransfersCompanion toCompanion(bool nullToAbsent) {
    return StockTransfersCompanion(
      uuid: Value(uuid),
      transferNumber: Value(transferNumber),
      fromWarehouseId: Value(fromWarehouseId),
      toWarehouseId: Value(toWarehouseId),
      transferDate: Value(transferDate),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      version: Value(version),
      companyId: companyId == null && nullToAbsent
          ? const Value.absent()
          : Value(companyId),
      status: Value(status),
      postedAt: postedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(postedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory StockTransferRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockTransferRow(
      uuid: serializer.fromJson<String>(json['uuid']),
      transferNumber: serializer.fromJson<String>(json['transferNumber']),
      fromWarehouseId: serializer.fromJson<String>(json['fromWarehouseId']),
      toWarehouseId: serializer.fromJson<String>(json['toWarehouseId']),
      transferDate: serializer.fromJson<int>(json['transferDate']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      version: serializer.fromJson<int>(json['version']),
      companyId: serializer.fromJson<String?>(json['companyId']),
      status: serializer.fromJson<String>(json['status']),
      postedAt: serializer.fromJson<int?>(json['postedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'transferNumber': serializer.toJson<String>(transferNumber),
      'fromWarehouseId': serializer.toJson<String>(fromWarehouseId),
      'toWarehouseId': serializer.toJson<String>(toWarehouseId),
      'transferDate': serializer.toJson<int>(transferDate),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'version': serializer.toJson<int>(version),
      'companyId': serializer.toJson<String?>(companyId),
      'status': serializer.toJson<String>(status),
      'postedAt': serializer.toJson<int?>(postedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  StockTransferRow copyWith({
    String? uuid,
    String? transferNumber,
    String? fromWarehouseId,
    String? toWarehouseId,
    int? transferDate,
    Value<String?> notes = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    String? syncStatus,
    int? version,
    Value<String?> companyId = const Value.absent(),
    String? status,
    Value<int?> postedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
  }) => StockTransferRow(
    uuid: uuid ?? this.uuid,
    transferNumber: transferNumber ?? this.transferNumber,
    fromWarehouseId: fromWarehouseId ?? this.fromWarehouseId,
    toWarehouseId: toWarehouseId ?? this.toWarehouseId,
    transferDate: transferDate ?? this.transferDate,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    version: version ?? this.version,
    companyId: companyId.present ? companyId.value : this.companyId,
    status: status ?? this.status,
    postedAt: postedAt.present ? postedAt.value : this.postedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  StockTransferRow copyWithCompanion(StockTransfersCompanion data) {
    return StockTransferRow(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      transferNumber: data.transferNumber.present
          ? data.transferNumber.value
          : this.transferNumber,
      fromWarehouseId: data.fromWarehouseId.present
          ? data.fromWarehouseId.value
          : this.fromWarehouseId,
      toWarehouseId: data.toWarehouseId.present
          ? data.toWarehouseId.value
          : this.toWarehouseId,
      transferDate: data.transferDate.present
          ? data.transferDate.value
          : this.transferDate,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      version: data.version.present ? data.version.value : this.version,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      status: data.status.present ? data.status.value : this.status,
      postedAt: data.postedAt.present ? data.postedAt.value : this.postedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockTransferRow(')
          ..write('uuid: $uuid, ')
          ..write('transferNumber: $transferNumber, ')
          ..write('fromWarehouseId: $fromWarehouseId, ')
          ..write('toWarehouseId: $toWarehouseId, ')
          ..write('transferDate: $transferDate, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version, ')
          ..write('companyId: $companyId, ')
          ..write('status: $status, ')
          ..write('postedAt: $postedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    transferNumber,
    fromWarehouseId,
    toWarehouseId,
    transferDate,
    notes,
    createdAt,
    updatedAt,
    syncStatus,
    version,
    companyId,
    status,
    postedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockTransferRow &&
          other.uuid == this.uuid &&
          other.transferNumber == this.transferNumber &&
          other.fromWarehouseId == this.fromWarehouseId &&
          other.toWarehouseId == this.toWarehouseId &&
          other.transferDate == this.transferDate &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.version == this.version &&
          other.companyId == this.companyId &&
          other.status == this.status &&
          other.postedAt == this.postedAt &&
          other.deletedAt == this.deletedAt);
}

class StockTransfersCompanion extends UpdateCompanion<StockTransferRow> {
  final Value<String> uuid;
  final Value<String> transferNumber;
  final Value<String> fromWarehouseId;
  final Value<String> toWarehouseId;
  final Value<int> transferDate;
  final Value<String?> notes;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> syncStatus;
  final Value<int> version;
  final Value<String?> companyId;
  final Value<String> status;
  final Value<int?> postedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const StockTransfersCompanion({
    this.uuid = const Value.absent(),
    this.transferNumber = const Value.absent(),
    this.fromWarehouseId = const Value.absent(),
    this.toWarehouseId = const Value.absent(),
    this.transferDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.companyId = const Value.absent(),
    this.status = const Value.absent(),
    this.postedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StockTransfersCompanion.insert({
    required String uuid,
    required String transferNumber,
    required String fromWarehouseId,
    required String toWarehouseId,
    required int transferDate,
    this.notes = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.companyId = const Value.absent(),
    this.status = const Value.absent(),
    this.postedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       transferNumber = Value(transferNumber),
       fromWarehouseId = Value(fromWarehouseId),
       toWarehouseId = Value(toWarehouseId),
       transferDate = Value(transferDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<StockTransferRow> custom({
    Expression<String>? uuid,
    Expression<String>? transferNumber,
    Expression<String>? fromWarehouseId,
    Expression<String>? toWarehouseId,
    Expression<int>? transferDate,
    Expression<String>? notes,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? syncStatus,
    Expression<int>? version,
    Expression<String>? companyId,
    Expression<String>? status,
    Expression<int>? postedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (transferNumber != null) 'transfer_number': transferNumber,
      if (fromWarehouseId != null) 'from_warehouse_id': fromWarehouseId,
      if (toWarehouseId != null) 'to_warehouse_id': toWarehouseId,
      if (transferDate != null) 'transfer_date': transferDate,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (version != null) 'version': version,
      if (companyId != null) 'company_id': companyId,
      if (status != null) 'status': status,
      if (postedAt != null) 'posted_at': postedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StockTransfersCompanion copyWith({
    Value<String>? uuid,
    Value<String>? transferNumber,
    Value<String>? fromWarehouseId,
    Value<String>? toWarehouseId,
    Value<int>? transferDate,
    Value<String?>? notes,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? syncStatus,
    Value<int>? version,
    Value<String?>? companyId,
    Value<String>? status,
    Value<int?>? postedAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return StockTransfersCompanion(
      uuid: uuid ?? this.uuid,
      transferNumber: transferNumber ?? this.transferNumber,
      fromWarehouseId: fromWarehouseId ?? this.fromWarehouseId,
      toWarehouseId: toWarehouseId ?? this.toWarehouseId,
      transferDate: transferDate ?? this.transferDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
      companyId: companyId ?? this.companyId,
      status: status ?? this.status,
      postedAt: postedAt ?? this.postedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (transferNumber.present) {
      map['transfer_number'] = Variable<String>(transferNumber.value);
    }
    if (fromWarehouseId.present) {
      map['from_warehouse_id'] = Variable<String>(fromWarehouseId.value);
    }
    if (toWarehouseId.present) {
      map['to_warehouse_id'] = Variable<String>(toWarehouseId.value);
    }
    if (transferDate.present) {
      map['transfer_date'] = Variable<int>(transferDate.value);
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
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (postedAt.present) {
      map['posted_at'] = Variable<int>(postedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockTransfersCompanion(')
          ..write('uuid: $uuid, ')
          ..write('transferNumber: $transferNumber, ')
          ..write('fromWarehouseId: $fromWarehouseId, ')
          ..write('toWarehouseId: $toWarehouseId, ')
          ..write('transferDate: $transferDate, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version, ')
          ..write('companyId: $companyId, ')
          ..write('status: $status, ')
          ..write('postedAt: $postedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InventoryAuditTrailTable extends InventoryAuditTrail
    with TableInfo<$InventoryAuditTrailTable, InventoryAuditTrailRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryAuditTrailTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentTypeMeta = const VerificationMeta(
    'documentType',
  );
  @override
  late final GeneratedColumn<String> documentType = GeneratedColumn<String>(
    'document_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    documentId,
    documentType,
    eventType,
    userId,
    notes,
    timestamp,
    metadata,
    companyId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_audit_trail';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventoryAuditTrailRow> instance, {
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
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('document_type')) {
      context.handle(
        _documentTypeMeta,
        documentType.isAcceptableOrUnknown(
          data['document_type']!,
          _documentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_documentTypeMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryAuditTrailRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryAuditTrailRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      documentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_type'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp'],
      )!,
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      ),
    );
  }

  @override
  $InventoryAuditTrailTable createAlias(String alias) {
    return $InventoryAuditTrailTable(attachedDatabase, alias);
  }
}

class InventoryAuditTrailRow extends DataClass
    implements Insertable<InventoryAuditTrailRow> {
  final int id;

  /// UUID of the audit event.
  final String uuid;

  /// Associated document ID (uuid of receipt, issue, sale, return, transfer, etc.)
  final String documentId;

  /// Type of document ('stock_receipt', 'stock_issue', 'sale', 'stock_return', 'stock_transfer')
  final String documentType;

  /// Event type ('post', 'unpost', 'edit', 'delete')
  final String eventType;

  /// User ID who performed the action
  final String? userId;

  /// Timestamp of action in UTC milliseconds
  final String? notes;
  final int timestamp;

  /// Optional JSON metadata (e.g. reason for unpost, shortages)
  final String? metadata;
  final String? companyId;
  const InventoryAuditTrailRow({
    required this.id,
    required this.uuid,
    required this.documentId,
    required this.documentType,
    required this.eventType,
    this.userId,
    this.notes,
    required this.timestamp,
    this.metadata,
    this.companyId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['document_id'] = Variable<String>(documentId);
    map['document_type'] = Variable<String>(documentType);
    map['event_type'] = Variable<String>(eventType);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['timestamp'] = Variable<int>(timestamp);
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    if (!nullToAbsent || companyId != null) {
      map['company_id'] = Variable<String>(companyId);
    }
    return map;
  }

  InventoryAuditTrailCompanion toCompanion(bool nullToAbsent) {
    return InventoryAuditTrailCompanion(
      id: Value(id),
      uuid: Value(uuid),
      documentId: Value(documentId),
      documentType: Value(documentType),
      eventType: Value(eventType),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      timestamp: Value(timestamp),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      companyId: companyId == null && nullToAbsent
          ? const Value.absent()
          : Value(companyId),
    );
  }

  factory InventoryAuditTrailRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryAuditTrailRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      documentId: serializer.fromJson<String>(json['documentId']),
      documentType: serializer.fromJson<String>(json['documentType']),
      eventType: serializer.fromJson<String>(json['eventType']),
      userId: serializer.fromJson<String?>(json['userId']),
      notes: serializer.fromJson<String?>(json['notes']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      companyId: serializer.fromJson<String?>(json['companyId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'documentId': serializer.toJson<String>(documentId),
      'documentType': serializer.toJson<String>(documentType),
      'eventType': serializer.toJson<String>(eventType),
      'userId': serializer.toJson<String?>(userId),
      'notes': serializer.toJson<String?>(notes),
      'timestamp': serializer.toJson<int>(timestamp),
      'metadata': serializer.toJson<String?>(metadata),
      'companyId': serializer.toJson<String?>(companyId),
    };
  }

  InventoryAuditTrailRow copyWith({
    int? id,
    String? uuid,
    String? documentId,
    String? documentType,
    String? eventType,
    Value<String?> userId = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    int? timestamp,
    Value<String?> metadata = const Value.absent(),
    Value<String?> companyId = const Value.absent(),
  }) => InventoryAuditTrailRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    documentId: documentId ?? this.documentId,
    documentType: documentType ?? this.documentType,
    eventType: eventType ?? this.eventType,
    userId: userId.present ? userId.value : this.userId,
    notes: notes.present ? notes.value : this.notes,
    timestamp: timestamp ?? this.timestamp,
    metadata: metadata.present ? metadata.value : this.metadata,
    companyId: companyId.present ? companyId.value : this.companyId,
  );
  InventoryAuditTrailRow copyWithCompanion(InventoryAuditTrailCompanion data) {
    return InventoryAuditTrailRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      documentType: data.documentType.present
          ? data.documentType.value
          : this.documentType,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      userId: data.userId.present ? data.userId.value : this.userId,
      notes: data.notes.present ? data.notes.value : this.notes,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryAuditTrailRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('documentId: $documentId, ')
          ..write('documentType: $documentType, ')
          ..write('eventType: $eventType, ')
          ..write('userId: $userId, ')
          ..write('notes: $notes, ')
          ..write('timestamp: $timestamp, ')
          ..write('metadata: $metadata, ')
          ..write('companyId: $companyId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    documentId,
    documentType,
    eventType,
    userId,
    notes,
    timestamp,
    metadata,
    companyId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryAuditTrailRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.documentId == this.documentId &&
          other.documentType == this.documentType &&
          other.eventType == this.eventType &&
          other.userId == this.userId &&
          other.notes == this.notes &&
          other.timestamp == this.timestamp &&
          other.metadata == this.metadata &&
          other.companyId == this.companyId);
}

class InventoryAuditTrailCompanion
    extends UpdateCompanion<InventoryAuditTrailRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> documentId;
  final Value<String> documentType;
  final Value<String> eventType;
  final Value<String?> userId;
  final Value<String?> notes;
  final Value<int> timestamp;
  final Value<String?> metadata;
  final Value<String?> companyId;
  const InventoryAuditTrailCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.documentId = const Value.absent(),
    this.documentType = const Value.absent(),
    this.eventType = const Value.absent(),
    this.userId = const Value.absent(),
    this.notes = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.metadata = const Value.absent(),
    this.companyId = const Value.absent(),
  });
  InventoryAuditTrailCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String documentId,
    required String documentType,
    required String eventType,
    this.userId = const Value.absent(),
    this.notes = const Value.absent(),
    required int timestamp,
    this.metadata = const Value.absent(),
    this.companyId = const Value.absent(),
  }) : uuid = Value(uuid),
       documentId = Value(documentId),
       documentType = Value(documentType),
       eventType = Value(eventType),
       timestamp = Value(timestamp);
  static Insertable<InventoryAuditTrailRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? documentId,
    Expression<String>? documentType,
    Expression<String>? eventType,
    Expression<String>? userId,
    Expression<String>? notes,
    Expression<int>? timestamp,
    Expression<String>? metadata,
    Expression<String>? companyId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (documentId != null) 'document_id': documentId,
      if (documentType != null) 'document_type': documentType,
      if (eventType != null) 'event_type': eventType,
      if (userId != null) 'user_id': userId,
      if (notes != null) 'notes': notes,
      if (timestamp != null) 'timestamp': timestamp,
      if (metadata != null) 'metadata': metadata,
      if (companyId != null) 'company_id': companyId,
    });
  }

  InventoryAuditTrailCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? documentId,
    Value<String>? documentType,
    Value<String>? eventType,
    Value<String?>? userId,
    Value<String?>? notes,
    Value<int>? timestamp,
    Value<String?>? metadata,
    Value<String?>? companyId,
  }) {
    return InventoryAuditTrailCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      documentId: documentId ?? this.documentId,
      documentType: documentType ?? this.documentType,
      eventType: eventType ?? this.eventType,
      userId: userId ?? this.userId,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      companyId: companyId ?? this.companyId,
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
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (documentType.present) {
      map['document_type'] = Variable<String>(documentType.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryAuditTrailCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('documentId: $documentId, ')
          ..write('documentType: $documentType, ')
          ..write('eventType: $eventType, ')
          ..write('userId: $userId, ')
          ..write('notes: $notes, ')
          ..write('timestamp: $timestamp, ')
          ..write('metadata: $metadata, ')
          ..write('companyId: $companyId')
          ..write(')'))
        .toString();
  }
}

abstract class _$InventoryDatabase extends GeneratedDatabase {
  _$InventoryDatabase(QueryExecutor e) : super(e);
  $InventoryDatabaseManager get managers => $InventoryDatabaseManager(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $StockReceiptsTable stockReceipts = $StockReceiptsTable(this);
  late final $StockIssuesTable stockIssues = $StockIssuesTable(this);
  late final $StockMovementLinesTable stockMovementLines =
      $StockMovementLinesTable(this);
  late final $InventoryCostLayersTable inventoryCostLayers =
      $InventoryCostLayersTable(this);
  late final $InventoryCostConsumptionsTable inventoryCostConsumptions =
      $InventoryCostConsumptionsTable(this);
  late final $StockReturnsTable stockReturns = $StockReturnsTable(this);
  late final $WarehousesTable warehouses = $WarehousesTable(this);
  late final $ProductWarehouseStocksTable productWarehouseStocks =
      $ProductWarehouseStocksTable(this);
  late final $StockTransfersTable stockTransfers = $StockTransfersTable(this);
  late final $InventoryAuditTrailTable inventoryAuditTrail =
      $InventoryAuditTrailTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    products,
    stockReceipts,
    stockIssues,
    stockMovementLines,
    inventoryCostLayers,
    inventoryCostConsumptions,
    stockReturns,
    warehouses,
    productWarehouseStocks,
    stockTransfers,
    inventoryAuditTrail,
  ];
}

typedef $$ProductsTableCreateCompanionBuilder =
    ProductsCompanion Function({
      Value<int> id,
      required String uuid,
      required String itemCode,
      required String name,
      Value<String?> barcode,
      required int packSize,
      required double price,
      Value<double> onHandQty,
      Value<double> unitCost,
      required int createdAt,
      required int updatedAt,
      Value<String> syncStatus,
      Value<int?> lastSyncedAt,
      Value<int> version,
      Value<String?> companyId,
      Value<int?> deletedAt,
    });
typedef $$ProductsTableUpdateCompanionBuilder =
    ProductsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String> itemCode,
      Value<String> name,
      Value<String?> barcode,
      Value<int> packSize,
      Value<double> price,
      Value<double> onHandQty,
      Value<double> unitCost,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<String> syncStatus,
      Value<int?> lastSyncedAt,
      Value<int> version,
      Value<String?> companyId,
      Value<int?> deletedAt,
    });

class $$ProductsTableFilterComposer
    extends Composer<_$InventoryDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
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

  ColumnFilters<String> get itemCode => $composableBuilder(
    column: $table.itemCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get packSize => $composableBuilder(
    column: $table.packSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get onHandQty => $composableBuilder(
    column: $table.onHandQty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitCost => $composableBuilder(
    column: $table.unitCost,
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

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductsTableOrderingComposer
    extends Composer<_$InventoryDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
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

  ColumnOrderings<String> get itemCode => $composableBuilder(
    column: $table.itemCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get packSize => $composableBuilder(
    column: $table.packSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get onHandQty => $composableBuilder(
    column: $table.onHandQty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitCost => $composableBuilder(
    column: $table.unitCost,
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

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$InventoryDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
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

  GeneratedColumn<String> get itemCode =>
      $composableBuilder(column: $table.itemCode, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<int> get packSize =>
      $composableBuilder(column: $table.packSize, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<double> get onHandQty =>
      $composableBuilder(column: $table.onHandQty, builder: (column) => column);

  GeneratedColumn<double> get unitCost =>
      $composableBuilder(column: $table.unitCost, builder: (column) => column);

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

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$InventoryDatabase,
          $ProductsTable,
          ProductRow,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (
            ProductRow,
            BaseReferences<_$InventoryDatabase, $ProductsTable, ProductRow>,
          ),
          ProductRow,
          PrefetchHooks Function()
        > {
  $$ProductsTableTableManager(_$InventoryDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> itemCode = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<int> packSize = const Value.absent(),
                Value<double> price = const Value.absent(),
                Value<double> onHandQty = const Value.absent(),
                Value<double> unitCost = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> companyId = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                uuid: uuid,
                itemCode: itemCode,
                name: name,
                barcode: barcode,
                packSize: packSize,
                price: price,
                onHandQty: onHandQty,
                unitCost: unitCost,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                version: version,
                companyId: companyId,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required String itemCode,
                required String name,
                Value<String?> barcode = const Value.absent(),
                required int packSize,
                required double price,
                Value<double> onHandQty = const Value.absent(),
                Value<double> unitCost = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<String> syncStatus = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> companyId = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => ProductsCompanion.insert(
                id: id,
                uuid: uuid,
                itemCode: itemCode,
                name: name,
                barcode: barcode,
                packSize: packSize,
                price: price,
                onHandQty: onHandQty,
                unitCost: unitCost,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                version: version,
                companyId: companyId,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$InventoryDatabase,
      $ProductsTable,
      ProductRow,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (
        ProductRow,
        BaseReferences<_$InventoryDatabase, $ProductsTable, ProductRow>,
      ),
      ProductRow,
      PrefetchHooks Function()
    >;
typedef $$StockReceiptsTableCreateCompanionBuilder =
    StockReceiptsCompanion Function({
      Value<int> id,
      required String uuid,
      required String receiptNumber,
      Value<String?> supplier,
      Value<String?> accountId,
      Value<String?> accountName,
      Value<String> currencyCode,
      Value<double> exchangeRate,
      Value<String?> notes,
      required int receiptDate,
      required int createdAt,
      required int updatedAt,
      Value<String> syncStatus,
      Value<int?> lastSyncedAt,
      Value<int> version,
      Value<String?> companyId,
      Value<String> status,
      Value<int?> postedAt,
      Value<int?> deletedAt,
    });
typedef $$StockReceiptsTableUpdateCompanionBuilder =
    StockReceiptsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String> receiptNumber,
      Value<String?> supplier,
      Value<String?> accountId,
      Value<String?> accountName,
      Value<String> currencyCode,
      Value<double> exchangeRate,
      Value<String?> notes,
      Value<int> receiptDate,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<String> syncStatus,
      Value<int?> lastSyncedAt,
      Value<int> version,
      Value<String?> companyId,
      Value<String> status,
      Value<int?> postedAt,
      Value<int?> deletedAt,
    });

class $$StockReceiptsTableFilterComposer
    extends Composer<_$InventoryDatabase, $StockReceiptsTable> {
  $$StockReceiptsTableFilterComposer({
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

  ColumnFilters<String> get receiptNumber => $composableBuilder(
    column: $table.receiptNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supplier => $composableBuilder(
    column: $table.supplier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get receiptDate => $composableBuilder(
    column: $table.receiptDate,
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

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get postedAt => $composableBuilder(
    column: $table.postedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StockReceiptsTableOrderingComposer
    extends Composer<_$InventoryDatabase, $StockReceiptsTable> {
  $$StockReceiptsTableOrderingComposer({
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

  ColumnOrderings<String> get receiptNumber => $composableBuilder(
    column: $table.receiptNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supplier => $composableBuilder(
    column: $table.supplier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get receiptDate => $composableBuilder(
    column: $table.receiptDate,
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

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get postedAt => $composableBuilder(
    column: $table.postedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StockReceiptsTableAnnotationComposer
    extends Composer<_$InventoryDatabase, $StockReceiptsTable> {
  $$StockReceiptsTableAnnotationComposer({
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

  GeneratedColumn<String> get receiptNumber => $composableBuilder(
    column: $table.receiptNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get supplier =>
      $composableBuilder(column: $table.supplier, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get receiptDate => $composableBuilder(
    column: $table.receiptDate,
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

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get postedAt =>
      $composableBuilder(column: $table.postedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$StockReceiptsTableTableManager
    extends
        RootTableManager<
          _$InventoryDatabase,
          $StockReceiptsTable,
          StockReceiptRow,
          $$StockReceiptsTableFilterComposer,
          $$StockReceiptsTableOrderingComposer,
          $$StockReceiptsTableAnnotationComposer,
          $$StockReceiptsTableCreateCompanionBuilder,
          $$StockReceiptsTableUpdateCompanionBuilder,
          (
            StockReceiptRow,
            BaseReferences<
              _$InventoryDatabase,
              $StockReceiptsTable,
              StockReceiptRow
            >,
          ),
          StockReceiptRow,
          PrefetchHooks Function()
        > {
  $$StockReceiptsTableTableManager(
    _$InventoryDatabase db,
    $StockReceiptsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockReceiptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockReceiptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockReceiptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> receiptNumber = const Value.absent(),
                Value<String?> supplier = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String?> accountName = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<double> exchangeRate = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> receiptDate = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> companyId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> postedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => StockReceiptsCompanion(
                id: id,
                uuid: uuid,
                receiptNumber: receiptNumber,
                supplier: supplier,
                accountId: accountId,
                accountName: accountName,
                currencyCode: currencyCode,
                exchangeRate: exchangeRate,
                notes: notes,
                receiptDate: receiptDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                version: version,
                companyId: companyId,
                status: status,
                postedAt: postedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required String receiptNumber,
                Value<String?> supplier = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String?> accountName = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<double> exchangeRate = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required int receiptDate,
                required int createdAt,
                required int updatedAt,
                Value<String> syncStatus = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> companyId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> postedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => StockReceiptsCompanion.insert(
                id: id,
                uuid: uuid,
                receiptNumber: receiptNumber,
                supplier: supplier,
                accountId: accountId,
                accountName: accountName,
                currencyCode: currencyCode,
                exchangeRate: exchangeRate,
                notes: notes,
                receiptDate: receiptDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                version: version,
                companyId: companyId,
                status: status,
                postedAt: postedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StockReceiptsTableProcessedTableManager =
    ProcessedTableManager<
      _$InventoryDatabase,
      $StockReceiptsTable,
      StockReceiptRow,
      $$StockReceiptsTableFilterComposer,
      $$StockReceiptsTableOrderingComposer,
      $$StockReceiptsTableAnnotationComposer,
      $$StockReceiptsTableCreateCompanionBuilder,
      $$StockReceiptsTableUpdateCompanionBuilder,
      (
        StockReceiptRow,
        BaseReferences<
          _$InventoryDatabase,
          $StockReceiptsTable,
          StockReceiptRow
        >,
      ),
      StockReceiptRow,
      PrefetchHooks Function()
    >;
typedef $$StockIssuesTableCreateCompanionBuilder =
    StockIssuesCompanion Function({
      Value<int> id,
      required String uuid,
      required String issueNumber,
      Value<String?> destination,
      Value<String?> accountId,
      Value<String?> accountName,
      Value<String> currencyCode,
      Value<double> exchangeRate,
      Value<int?> voucherBookId,
      Value<String?> warehouse,
      Value<String?> notes,
      required int issueDate,
      required int createdAt,
      required int updatedAt,
      Value<String> syncStatus,
      Value<int?> lastSyncedAt,
      Value<int> version,
      Value<String?> companyId,
      Value<String> status,
      Value<int?> postedAt,
      Value<int?> deletedAt,
    });
typedef $$StockIssuesTableUpdateCompanionBuilder =
    StockIssuesCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String> issueNumber,
      Value<String?> destination,
      Value<String?> accountId,
      Value<String?> accountName,
      Value<String> currencyCode,
      Value<double> exchangeRate,
      Value<int?> voucherBookId,
      Value<String?> warehouse,
      Value<String?> notes,
      Value<int> issueDate,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<String> syncStatus,
      Value<int?> lastSyncedAt,
      Value<int> version,
      Value<String?> companyId,
      Value<String> status,
      Value<int?> postedAt,
      Value<int?> deletedAt,
    });

class $$StockIssuesTableFilterComposer
    extends Composer<_$InventoryDatabase, $StockIssuesTable> {
  $$StockIssuesTableFilterComposer({
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

  ColumnFilters<String> get issueNumber => $composableBuilder(
    column: $table.issueNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get voucherBookId => $composableBuilder(
    column: $table.voucherBookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get warehouse => $composableBuilder(
    column: $table.warehouse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get issueDate => $composableBuilder(
    column: $table.issueDate,
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

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get postedAt => $composableBuilder(
    column: $table.postedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StockIssuesTableOrderingComposer
    extends Composer<_$InventoryDatabase, $StockIssuesTable> {
  $$StockIssuesTableOrderingComposer({
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

  ColumnOrderings<String> get issueNumber => $composableBuilder(
    column: $table.issueNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get voucherBookId => $composableBuilder(
    column: $table.voucherBookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get warehouse => $composableBuilder(
    column: $table.warehouse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get issueDate => $composableBuilder(
    column: $table.issueDate,
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

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get postedAt => $composableBuilder(
    column: $table.postedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StockIssuesTableAnnotationComposer
    extends Composer<_$InventoryDatabase, $StockIssuesTable> {
  $$StockIssuesTableAnnotationComposer({
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

  GeneratedColumn<String> get issueNumber => $composableBuilder(
    column: $table.issueNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get voucherBookId => $composableBuilder(
    column: $table.voucherBookId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get warehouse =>
      $composableBuilder(column: $table.warehouse, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get issueDate =>
      $composableBuilder(column: $table.issueDate, builder: (column) => column);

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

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get postedAt =>
      $composableBuilder(column: $table.postedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$StockIssuesTableTableManager
    extends
        RootTableManager<
          _$InventoryDatabase,
          $StockIssuesTable,
          StockIssueRow,
          $$StockIssuesTableFilterComposer,
          $$StockIssuesTableOrderingComposer,
          $$StockIssuesTableAnnotationComposer,
          $$StockIssuesTableCreateCompanionBuilder,
          $$StockIssuesTableUpdateCompanionBuilder,
          (
            StockIssueRow,
            BaseReferences<
              _$InventoryDatabase,
              $StockIssuesTable,
              StockIssueRow
            >,
          ),
          StockIssueRow,
          PrefetchHooks Function()
        > {
  $$StockIssuesTableTableManager(
    _$InventoryDatabase db,
    $StockIssuesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockIssuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockIssuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockIssuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> issueNumber = const Value.absent(),
                Value<String?> destination = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String?> accountName = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<double> exchangeRate = const Value.absent(),
                Value<int?> voucherBookId = const Value.absent(),
                Value<String?> warehouse = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> issueDate = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> companyId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> postedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => StockIssuesCompanion(
                id: id,
                uuid: uuid,
                issueNumber: issueNumber,
                destination: destination,
                accountId: accountId,
                accountName: accountName,
                currencyCode: currencyCode,
                exchangeRate: exchangeRate,
                voucherBookId: voucherBookId,
                warehouse: warehouse,
                notes: notes,
                issueDate: issueDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                version: version,
                companyId: companyId,
                status: status,
                postedAt: postedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required String issueNumber,
                Value<String?> destination = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String?> accountName = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<double> exchangeRate = const Value.absent(),
                Value<int?> voucherBookId = const Value.absent(),
                Value<String?> warehouse = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required int issueDate,
                required int createdAt,
                required int updatedAt,
                Value<String> syncStatus = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> companyId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> postedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => StockIssuesCompanion.insert(
                id: id,
                uuid: uuid,
                issueNumber: issueNumber,
                destination: destination,
                accountId: accountId,
                accountName: accountName,
                currencyCode: currencyCode,
                exchangeRate: exchangeRate,
                voucherBookId: voucherBookId,
                warehouse: warehouse,
                notes: notes,
                issueDate: issueDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                version: version,
                companyId: companyId,
                status: status,
                postedAt: postedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StockIssuesTableProcessedTableManager =
    ProcessedTableManager<
      _$InventoryDatabase,
      $StockIssuesTable,
      StockIssueRow,
      $$StockIssuesTableFilterComposer,
      $$StockIssuesTableOrderingComposer,
      $$StockIssuesTableAnnotationComposer,
      $$StockIssuesTableCreateCompanionBuilder,
      $$StockIssuesTableUpdateCompanionBuilder,
      (
        StockIssueRow,
        BaseReferences<_$InventoryDatabase, $StockIssuesTable, StockIssueRow>,
      ),
      StockIssueRow,
      PrefetchHooks Function()
    >;
typedef $$StockMovementLinesTableCreateCompanionBuilder =
    StockMovementLinesCompanion Function({
      Value<int> id,
      required String uuid,
      required String movementUuid,
      required String movementType,
      required String itemCode,
      required String itemName,
      Value<double> mainQuantity,
      Value<double> subQuantity,
      Value<double> quantity,
      Value<double> unitCost,
      Value<double> totalCost,
      Value<double?> postedCost,
      Value<int?> postedAt,
    });
typedef $$StockMovementLinesTableUpdateCompanionBuilder =
    StockMovementLinesCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String> movementUuid,
      Value<String> movementType,
      Value<String> itemCode,
      Value<String> itemName,
      Value<double> mainQuantity,
      Value<double> subQuantity,
      Value<double> quantity,
      Value<double> unitCost,
      Value<double> totalCost,
      Value<double?> postedCost,
      Value<int?> postedAt,
    });

class $$StockMovementLinesTableFilterComposer
    extends Composer<_$InventoryDatabase, $StockMovementLinesTable> {
  $$StockMovementLinesTableFilterComposer({
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

  ColumnFilters<String> get movementUuid => $composableBuilder(
    column: $table.movementUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemCode => $composableBuilder(
    column: $table.itemCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get mainQuantity => $composableBuilder(
    column: $table.mainQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get subQuantity => $composableBuilder(
    column: $table.subQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitCost => $composableBuilder(
    column: $table.unitCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalCost => $composableBuilder(
    column: $table.totalCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get postedCost => $composableBuilder(
    column: $table.postedCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get postedAt => $composableBuilder(
    column: $table.postedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StockMovementLinesTableOrderingComposer
    extends Composer<_$InventoryDatabase, $StockMovementLinesTable> {
  $$StockMovementLinesTableOrderingComposer({
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

  ColumnOrderings<String> get movementUuid => $composableBuilder(
    column: $table.movementUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemCode => $composableBuilder(
    column: $table.itemCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get mainQuantity => $composableBuilder(
    column: $table.mainQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get subQuantity => $composableBuilder(
    column: $table.subQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitCost => $composableBuilder(
    column: $table.unitCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalCost => $composableBuilder(
    column: $table.totalCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get postedCost => $composableBuilder(
    column: $table.postedCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get postedAt => $composableBuilder(
    column: $table.postedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StockMovementLinesTableAnnotationComposer
    extends Composer<_$InventoryDatabase, $StockMovementLinesTable> {
  $$StockMovementLinesTableAnnotationComposer({
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

  GeneratedColumn<String> get movementUuid => $composableBuilder(
    column: $table.movementUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemCode =>
      $composableBuilder(column: $table.itemCode, builder: (column) => column);

  GeneratedColumn<String> get itemName =>
      $composableBuilder(column: $table.itemName, builder: (column) => column);

  GeneratedColumn<double> get mainQuantity => $composableBuilder(
    column: $table.mainQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<double> get subQuantity => $composableBuilder(
    column: $table.subQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get unitCost =>
      $composableBuilder(column: $table.unitCost, builder: (column) => column);

  GeneratedColumn<double> get totalCost =>
      $composableBuilder(column: $table.totalCost, builder: (column) => column);

  GeneratedColumn<double> get postedCost => $composableBuilder(
    column: $table.postedCost,
    builder: (column) => column,
  );

  GeneratedColumn<int> get postedAt =>
      $composableBuilder(column: $table.postedAt, builder: (column) => column);
}

class $$StockMovementLinesTableTableManager
    extends
        RootTableManager<
          _$InventoryDatabase,
          $StockMovementLinesTable,
          StockMovementLineRow,
          $$StockMovementLinesTableFilterComposer,
          $$StockMovementLinesTableOrderingComposer,
          $$StockMovementLinesTableAnnotationComposer,
          $$StockMovementLinesTableCreateCompanionBuilder,
          $$StockMovementLinesTableUpdateCompanionBuilder,
          (
            StockMovementLineRow,
            BaseReferences<
              _$InventoryDatabase,
              $StockMovementLinesTable,
              StockMovementLineRow
            >,
          ),
          StockMovementLineRow,
          PrefetchHooks Function()
        > {
  $$StockMovementLinesTableTableManager(
    _$InventoryDatabase db,
    $StockMovementLinesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockMovementLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockMovementLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockMovementLinesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> movementUuid = const Value.absent(),
                Value<String> movementType = const Value.absent(),
                Value<String> itemCode = const Value.absent(),
                Value<String> itemName = const Value.absent(),
                Value<double> mainQuantity = const Value.absent(),
                Value<double> subQuantity = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<double> unitCost = const Value.absent(),
                Value<double> totalCost = const Value.absent(),
                Value<double?> postedCost = const Value.absent(),
                Value<int?> postedAt = const Value.absent(),
              }) => StockMovementLinesCompanion(
                id: id,
                uuid: uuid,
                movementUuid: movementUuid,
                movementType: movementType,
                itemCode: itemCode,
                itemName: itemName,
                mainQuantity: mainQuantity,
                subQuantity: subQuantity,
                quantity: quantity,
                unitCost: unitCost,
                totalCost: totalCost,
                postedCost: postedCost,
                postedAt: postedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required String movementUuid,
                required String movementType,
                required String itemCode,
                required String itemName,
                Value<double> mainQuantity = const Value.absent(),
                Value<double> subQuantity = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<double> unitCost = const Value.absent(),
                Value<double> totalCost = const Value.absent(),
                Value<double?> postedCost = const Value.absent(),
                Value<int?> postedAt = const Value.absent(),
              }) => StockMovementLinesCompanion.insert(
                id: id,
                uuid: uuid,
                movementUuid: movementUuid,
                movementType: movementType,
                itemCode: itemCode,
                itemName: itemName,
                mainQuantity: mainQuantity,
                subQuantity: subQuantity,
                quantity: quantity,
                unitCost: unitCost,
                totalCost: totalCost,
                postedCost: postedCost,
                postedAt: postedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StockMovementLinesTableProcessedTableManager =
    ProcessedTableManager<
      _$InventoryDatabase,
      $StockMovementLinesTable,
      StockMovementLineRow,
      $$StockMovementLinesTableFilterComposer,
      $$StockMovementLinesTableOrderingComposer,
      $$StockMovementLinesTableAnnotationComposer,
      $$StockMovementLinesTableCreateCompanionBuilder,
      $$StockMovementLinesTableUpdateCompanionBuilder,
      (
        StockMovementLineRow,
        BaseReferences<
          _$InventoryDatabase,
          $StockMovementLinesTable,
          StockMovementLineRow
        >,
      ),
      StockMovementLineRow,
      PrefetchHooks Function()
    >;
typedef $$InventoryCostLayersTableCreateCompanionBuilder =
    InventoryCostLayersCompanion Function({
      Value<int> id,
      required String uuid,
      required String itemCode,
      Value<String?> warehouseId,
      required String movementUuid,
      required String movementType,
      required int receivedDate,
      Value<double> receivedQty,
      Value<double> remainingQty,
      Value<double> unitCost,
      Value<double> totalCost,
      Value<int> closed,
      required int createdAt,
      required int updatedAt,
      Value<String> syncStatus,
      Value<int?> lastSyncedAt,
      Value<int> version,
      Value<String?> companyId,
      Value<int?> deletedAt,
    });
typedef $$InventoryCostLayersTableUpdateCompanionBuilder =
    InventoryCostLayersCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String> itemCode,
      Value<String?> warehouseId,
      Value<String> movementUuid,
      Value<String> movementType,
      Value<int> receivedDate,
      Value<double> receivedQty,
      Value<double> remainingQty,
      Value<double> unitCost,
      Value<double> totalCost,
      Value<int> closed,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<String> syncStatus,
      Value<int?> lastSyncedAt,
      Value<int> version,
      Value<String?> companyId,
      Value<int?> deletedAt,
    });

class $$InventoryCostLayersTableFilterComposer
    extends Composer<_$InventoryDatabase, $InventoryCostLayersTable> {
  $$InventoryCostLayersTableFilterComposer({
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

  ColumnFilters<String> get itemCode => $composableBuilder(
    column: $table.itemCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get warehouseId => $composableBuilder(
    column: $table.warehouseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get movementUuid => $composableBuilder(
    column: $table.movementUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get receivedDate => $composableBuilder(
    column: $table.receivedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get receivedQty => $composableBuilder(
    column: $table.receivedQty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get remainingQty => $composableBuilder(
    column: $table.remainingQty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitCost => $composableBuilder(
    column: $table.unitCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalCost => $composableBuilder(
    column: $table.totalCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get closed => $composableBuilder(
    column: $table.closed,
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

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InventoryCostLayersTableOrderingComposer
    extends Composer<_$InventoryDatabase, $InventoryCostLayersTable> {
  $$InventoryCostLayersTableOrderingComposer({
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

  ColumnOrderings<String> get itemCode => $composableBuilder(
    column: $table.itemCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get warehouseId => $composableBuilder(
    column: $table.warehouseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get movementUuid => $composableBuilder(
    column: $table.movementUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get receivedDate => $composableBuilder(
    column: $table.receivedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get receivedQty => $composableBuilder(
    column: $table.receivedQty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get remainingQty => $composableBuilder(
    column: $table.remainingQty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitCost => $composableBuilder(
    column: $table.unitCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalCost => $composableBuilder(
    column: $table.totalCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get closed => $composableBuilder(
    column: $table.closed,
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

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InventoryCostLayersTableAnnotationComposer
    extends Composer<_$InventoryDatabase, $InventoryCostLayersTable> {
  $$InventoryCostLayersTableAnnotationComposer({
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

  GeneratedColumn<String> get itemCode =>
      $composableBuilder(column: $table.itemCode, builder: (column) => column);

  GeneratedColumn<String> get warehouseId => $composableBuilder(
    column: $table.warehouseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get movementUuid => $composableBuilder(
    column: $table.movementUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get receivedDate => $composableBuilder(
    column: $table.receivedDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get receivedQty => $composableBuilder(
    column: $table.receivedQty,
    builder: (column) => column,
  );

  GeneratedColumn<double> get remainingQty => $composableBuilder(
    column: $table.remainingQty,
    builder: (column) => column,
  );

  GeneratedColumn<double> get unitCost =>
      $composableBuilder(column: $table.unitCost, builder: (column) => column);

  GeneratedColumn<double> get totalCost =>
      $composableBuilder(column: $table.totalCost, builder: (column) => column);

  GeneratedColumn<int> get closed =>
      $composableBuilder(column: $table.closed, builder: (column) => column);

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

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$InventoryCostLayersTableTableManager
    extends
        RootTableManager<
          _$InventoryDatabase,
          $InventoryCostLayersTable,
          InventoryCostLayerRow,
          $$InventoryCostLayersTableFilterComposer,
          $$InventoryCostLayersTableOrderingComposer,
          $$InventoryCostLayersTableAnnotationComposer,
          $$InventoryCostLayersTableCreateCompanionBuilder,
          $$InventoryCostLayersTableUpdateCompanionBuilder,
          (
            InventoryCostLayerRow,
            BaseReferences<
              _$InventoryDatabase,
              $InventoryCostLayersTable,
              InventoryCostLayerRow
            >,
          ),
          InventoryCostLayerRow,
          PrefetchHooks Function()
        > {
  $$InventoryCostLayersTableTableManager(
    _$InventoryDatabase db,
    $InventoryCostLayersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryCostLayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryCostLayersTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$InventoryCostLayersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> itemCode = const Value.absent(),
                Value<String?> warehouseId = const Value.absent(),
                Value<String> movementUuid = const Value.absent(),
                Value<String> movementType = const Value.absent(),
                Value<int> receivedDate = const Value.absent(),
                Value<double> receivedQty = const Value.absent(),
                Value<double> remainingQty = const Value.absent(),
                Value<double> unitCost = const Value.absent(),
                Value<double> totalCost = const Value.absent(),
                Value<int> closed = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> companyId = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => InventoryCostLayersCompanion(
                id: id,
                uuid: uuid,
                itemCode: itemCode,
                warehouseId: warehouseId,
                movementUuid: movementUuid,
                movementType: movementType,
                receivedDate: receivedDate,
                receivedQty: receivedQty,
                remainingQty: remainingQty,
                unitCost: unitCost,
                totalCost: totalCost,
                closed: closed,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                version: version,
                companyId: companyId,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required String itemCode,
                Value<String?> warehouseId = const Value.absent(),
                required String movementUuid,
                required String movementType,
                required int receivedDate,
                Value<double> receivedQty = const Value.absent(),
                Value<double> remainingQty = const Value.absent(),
                Value<double> unitCost = const Value.absent(),
                Value<double> totalCost = const Value.absent(),
                Value<int> closed = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<String> syncStatus = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> companyId = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => InventoryCostLayersCompanion.insert(
                id: id,
                uuid: uuid,
                itemCode: itemCode,
                warehouseId: warehouseId,
                movementUuid: movementUuid,
                movementType: movementType,
                receivedDate: receivedDate,
                receivedQty: receivedQty,
                remainingQty: remainingQty,
                unitCost: unitCost,
                totalCost: totalCost,
                closed: closed,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                version: version,
                companyId: companyId,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InventoryCostLayersTableProcessedTableManager =
    ProcessedTableManager<
      _$InventoryDatabase,
      $InventoryCostLayersTable,
      InventoryCostLayerRow,
      $$InventoryCostLayersTableFilterComposer,
      $$InventoryCostLayersTableOrderingComposer,
      $$InventoryCostLayersTableAnnotationComposer,
      $$InventoryCostLayersTableCreateCompanionBuilder,
      $$InventoryCostLayersTableUpdateCompanionBuilder,
      (
        InventoryCostLayerRow,
        BaseReferences<
          _$InventoryDatabase,
          $InventoryCostLayersTable,
          InventoryCostLayerRow
        >,
      ),
      InventoryCostLayerRow,
      PrefetchHooks Function()
    >;
typedef $$InventoryCostConsumptionsTableCreateCompanionBuilder =
    InventoryCostConsumptionsCompanion Function({
      Value<int> id,
      required String uuid,
      required String layerUuid,
      required String issueLineUuid,
      required String movementType,
      Value<double> consumedQty,
      Value<double> unitCost,
      Value<double> totalCost,
      required int createdAt,
      Value<String?> companyId,
    });
typedef $$InventoryCostConsumptionsTableUpdateCompanionBuilder =
    InventoryCostConsumptionsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String> layerUuid,
      Value<String> issueLineUuid,
      Value<String> movementType,
      Value<double> consumedQty,
      Value<double> unitCost,
      Value<double> totalCost,
      Value<int> createdAt,
      Value<String?> companyId,
    });

class $$InventoryCostConsumptionsTableFilterComposer
    extends Composer<_$InventoryDatabase, $InventoryCostConsumptionsTable> {
  $$InventoryCostConsumptionsTableFilterComposer({
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

  ColumnFilters<String> get layerUuid => $composableBuilder(
    column: $table.layerUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get issueLineUuid => $composableBuilder(
    column: $table.issueLineUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get consumedQty => $composableBuilder(
    column: $table.consumedQty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitCost => $composableBuilder(
    column: $table.unitCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalCost => $composableBuilder(
    column: $table.totalCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InventoryCostConsumptionsTableOrderingComposer
    extends Composer<_$InventoryDatabase, $InventoryCostConsumptionsTable> {
  $$InventoryCostConsumptionsTableOrderingComposer({
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

  ColumnOrderings<String> get layerUuid => $composableBuilder(
    column: $table.layerUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get issueLineUuid => $composableBuilder(
    column: $table.issueLineUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get consumedQty => $composableBuilder(
    column: $table.consumedQty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitCost => $composableBuilder(
    column: $table.unitCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalCost => $composableBuilder(
    column: $table.totalCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InventoryCostConsumptionsTableAnnotationComposer
    extends Composer<_$InventoryDatabase, $InventoryCostConsumptionsTable> {
  $$InventoryCostConsumptionsTableAnnotationComposer({
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

  GeneratedColumn<String> get layerUuid =>
      $composableBuilder(column: $table.layerUuid, builder: (column) => column);

  GeneratedColumn<String> get issueLineUuid => $composableBuilder(
    column: $table.issueLineUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get consumedQty => $composableBuilder(
    column: $table.consumedQty,
    builder: (column) => column,
  );

  GeneratedColumn<double> get unitCost =>
      $composableBuilder(column: $table.unitCost, builder: (column) => column);

  GeneratedColumn<double> get totalCost =>
      $composableBuilder(column: $table.totalCost, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);
}

class $$InventoryCostConsumptionsTableTableManager
    extends
        RootTableManager<
          _$InventoryDatabase,
          $InventoryCostConsumptionsTable,
          InventoryCostConsumptionRow,
          $$InventoryCostConsumptionsTableFilterComposer,
          $$InventoryCostConsumptionsTableOrderingComposer,
          $$InventoryCostConsumptionsTableAnnotationComposer,
          $$InventoryCostConsumptionsTableCreateCompanionBuilder,
          $$InventoryCostConsumptionsTableUpdateCompanionBuilder,
          (
            InventoryCostConsumptionRow,
            BaseReferences<
              _$InventoryDatabase,
              $InventoryCostConsumptionsTable,
              InventoryCostConsumptionRow
            >,
          ),
          InventoryCostConsumptionRow,
          PrefetchHooks Function()
        > {
  $$InventoryCostConsumptionsTableTableManager(
    _$InventoryDatabase db,
    $InventoryCostConsumptionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryCostConsumptionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$InventoryCostConsumptionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$InventoryCostConsumptionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> layerUuid = const Value.absent(),
                Value<String> issueLineUuid = const Value.absent(),
                Value<String> movementType = const Value.absent(),
                Value<double> consumedQty = const Value.absent(),
                Value<double> unitCost = const Value.absent(),
                Value<double> totalCost = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String?> companyId = const Value.absent(),
              }) => InventoryCostConsumptionsCompanion(
                id: id,
                uuid: uuid,
                layerUuid: layerUuid,
                issueLineUuid: issueLineUuid,
                movementType: movementType,
                consumedQty: consumedQty,
                unitCost: unitCost,
                totalCost: totalCost,
                createdAt: createdAt,
                companyId: companyId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required String layerUuid,
                required String issueLineUuid,
                required String movementType,
                Value<double> consumedQty = const Value.absent(),
                Value<double> unitCost = const Value.absent(),
                Value<double> totalCost = const Value.absent(),
                required int createdAt,
                Value<String?> companyId = const Value.absent(),
              }) => InventoryCostConsumptionsCompanion.insert(
                id: id,
                uuid: uuid,
                layerUuid: layerUuid,
                issueLineUuid: issueLineUuid,
                movementType: movementType,
                consumedQty: consumedQty,
                unitCost: unitCost,
                totalCost: totalCost,
                createdAt: createdAt,
                companyId: companyId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InventoryCostConsumptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$InventoryDatabase,
      $InventoryCostConsumptionsTable,
      InventoryCostConsumptionRow,
      $$InventoryCostConsumptionsTableFilterComposer,
      $$InventoryCostConsumptionsTableOrderingComposer,
      $$InventoryCostConsumptionsTableAnnotationComposer,
      $$InventoryCostConsumptionsTableCreateCompanionBuilder,
      $$InventoryCostConsumptionsTableUpdateCompanionBuilder,
      (
        InventoryCostConsumptionRow,
        BaseReferences<
          _$InventoryDatabase,
          $InventoryCostConsumptionsTable,
          InventoryCostConsumptionRow
        >,
      ),
      InventoryCostConsumptionRow,
      PrefetchHooks Function()
    >;
typedef $$StockReturnsTableCreateCompanionBuilder =
    StockReturnsCompanion Function({
      Value<int> id,
      required String uuid,
      required String returnNumber,
      required String returnType,
      Value<String?> originalMovementUuid,
      Value<String?> partyName,
      Value<String?> warehouse,
      Value<String?> notes,
      required int returnDate,
      required int createdAt,
      required int updatedAt,
      Value<String> syncStatus,
      Value<int?> lastSyncedAt,
      Value<int> version,
      Value<String?> companyId,
      Value<String> status,
      Value<int?> postedAt,
      Value<int?> deletedAt,
    });
typedef $$StockReturnsTableUpdateCompanionBuilder =
    StockReturnsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String> returnNumber,
      Value<String> returnType,
      Value<String?> originalMovementUuid,
      Value<String?> partyName,
      Value<String?> warehouse,
      Value<String?> notes,
      Value<int> returnDate,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<String> syncStatus,
      Value<int?> lastSyncedAt,
      Value<int> version,
      Value<String?> companyId,
      Value<String> status,
      Value<int?> postedAt,
      Value<int?> deletedAt,
    });

class $$StockReturnsTableFilterComposer
    extends Composer<_$InventoryDatabase, $StockReturnsTable> {
  $$StockReturnsTableFilterComposer({
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

  ColumnFilters<String> get returnNumber => $composableBuilder(
    column: $table.returnNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get returnType => $composableBuilder(
    column: $table.returnType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalMovementUuid => $composableBuilder(
    column: $table.originalMovementUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partyName => $composableBuilder(
    column: $table.partyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get warehouse => $composableBuilder(
    column: $table.warehouse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get returnDate => $composableBuilder(
    column: $table.returnDate,
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

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get postedAt => $composableBuilder(
    column: $table.postedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StockReturnsTableOrderingComposer
    extends Composer<_$InventoryDatabase, $StockReturnsTable> {
  $$StockReturnsTableOrderingComposer({
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

  ColumnOrderings<String> get returnNumber => $composableBuilder(
    column: $table.returnNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get returnType => $composableBuilder(
    column: $table.returnType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalMovementUuid => $composableBuilder(
    column: $table.originalMovementUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partyName => $composableBuilder(
    column: $table.partyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get warehouse => $composableBuilder(
    column: $table.warehouse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get returnDate => $composableBuilder(
    column: $table.returnDate,
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

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get postedAt => $composableBuilder(
    column: $table.postedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StockReturnsTableAnnotationComposer
    extends Composer<_$InventoryDatabase, $StockReturnsTable> {
  $$StockReturnsTableAnnotationComposer({
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

  GeneratedColumn<String> get returnNumber => $composableBuilder(
    column: $table.returnNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get returnType => $composableBuilder(
    column: $table.returnType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originalMovementUuid => $composableBuilder(
    column: $table.originalMovementUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get partyName =>
      $composableBuilder(column: $table.partyName, builder: (column) => column);

  GeneratedColumn<String> get warehouse =>
      $composableBuilder(column: $table.warehouse, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get returnDate => $composableBuilder(
    column: $table.returnDate,
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

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get postedAt =>
      $composableBuilder(column: $table.postedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$StockReturnsTableTableManager
    extends
        RootTableManager<
          _$InventoryDatabase,
          $StockReturnsTable,
          StockReturnRow,
          $$StockReturnsTableFilterComposer,
          $$StockReturnsTableOrderingComposer,
          $$StockReturnsTableAnnotationComposer,
          $$StockReturnsTableCreateCompanionBuilder,
          $$StockReturnsTableUpdateCompanionBuilder,
          (
            StockReturnRow,
            BaseReferences<
              _$InventoryDatabase,
              $StockReturnsTable,
              StockReturnRow
            >,
          ),
          StockReturnRow,
          PrefetchHooks Function()
        > {
  $$StockReturnsTableTableManager(
    _$InventoryDatabase db,
    $StockReturnsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockReturnsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockReturnsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockReturnsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> returnNumber = const Value.absent(),
                Value<String> returnType = const Value.absent(),
                Value<String?> originalMovementUuid = const Value.absent(),
                Value<String?> partyName = const Value.absent(),
                Value<String?> warehouse = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> returnDate = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> companyId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> postedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => StockReturnsCompanion(
                id: id,
                uuid: uuid,
                returnNumber: returnNumber,
                returnType: returnType,
                originalMovementUuid: originalMovementUuid,
                partyName: partyName,
                warehouse: warehouse,
                notes: notes,
                returnDate: returnDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                version: version,
                companyId: companyId,
                status: status,
                postedAt: postedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required String returnNumber,
                required String returnType,
                Value<String?> originalMovementUuid = const Value.absent(),
                Value<String?> partyName = const Value.absent(),
                Value<String?> warehouse = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required int returnDate,
                required int createdAt,
                required int updatedAt,
                Value<String> syncStatus = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> companyId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> postedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => StockReturnsCompanion.insert(
                id: id,
                uuid: uuid,
                returnNumber: returnNumber,
                returnType: returnType,
                originalMovementUuid: originalMovementUuid,
                partyName: partyName,
                warehouse: warehouse,
                notes: notes,
                returnDate: returnDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                version: version,
                companyId: companyId,
                status: status,
                postedAt: postedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StockReturnsTableProcessedTableManager =
    ProcessedTableManager<
      _$InventoryDatabase,
      $StockReturnsTable,
      StockReturnRow,
      $$StockReturnsTableFilterComposer,
      $$StockReturnsTableOrderingComposer,
      $$StockReturnsTableAnnotationComposer,
      $$StockReturnsTableCreateCompanionBuilder,
      $$StockReturnsTableUpdateCompanionBuilder,
      (
        StockReturnRow,
        BaseReferences<_$InventoryDatabase, $StockReturnsTable, StockReturnRow>,
      ),
      StockReturnRow,
      PrefetchHooks Function()
    >;
typedef $$WarehousesTableCreateCompanionBuilder =
    WarehousesCompanion Function({
      required String uuid,
      required String code,
      required String name,
      Value<bool> isDefault,
      Value<bool> isActive,
      Value<String?> address,
      Value<String?> phone,
      Value<String?> managerName,
      required int createdAt,
      required int updatedAt,
      Value<String> syncStatus,
      Value<int> version,
      Value<String?> companyId,
      Value<int?> deletedAt,
      Value<int> rowid,
    });
typedef $$WarehousesTableUpdateCompanionBuilder =
    WarehousesCompanion Function({
      Value<String> uuid,
      Value<String> code,
      Value<String> name,
      Value<bool> isDefault,
      Value<bool> isActive,
      Value<String?> address,
      Value<String?> phone,
      Value<String?> managerName,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<String> syncStatus,
      Value<int> version,
      Value<String?> companyId,
      Value<int?> deletedAt,
      Value<int> rowid,
    });

class $$WarehousesTableFilterComposer
    extends Composer<_$InventoryDatabase, $WarehousesTable> {
  $$WarehousesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
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

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get managerName => $composableBuilder(
    column: $table.managerName,
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

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WarehousesTableOrderingComposer
    extends Composer<_$InventoryDatabase, $WarehousesTable> {
  $$WarehousesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
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

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get managerName => $composableBuilder(
    column: $table.managerName,
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

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WarehousesTableAnnotationComposer
    extends Composer<_$InventoryDatabase, $WarehousesTable> {
  $$WarehousesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get managerName => $composableBuilder(
    column: $table.managerName,
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

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$WarehousesTableTableManager
    extends
        RootTableManager<
          _$InventoryDatabase,
          $WarehousesTable,
          WarehouseRow,
          $$WarehousesTableFilterComposer,
          $$WarehousesTableOrderingComposer,
          $$WarehousesTableAnnotationComposer,
          $$WarehousesTableCreateCompanionBuilder,
          $$WarehousesTableUpdateCompanionBuilder,
          (
            WarehouseRow,
            BaseReferences<_$InventoryDatabase, $WarehousesTable, WarehouseRow>,
          ),
          WarehouseRow,
          PrefetchHooks Function()
        > {
  $$WarehousesTableTableManager(_$InventoryDatabase db, $WarehousesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WarehousesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WarehousesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WarehousesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> managerName = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> companyId = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WarehousesCompanion(
                uuid: uuid,
                code: code,
                name: name,
                isDefault: isDefault,
                isActive: isActive,
                address: address,
                phone: phone,
                managerName: managerName,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                version: version,
                companyId: companyId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uuid,
                required String code,
                required String name,
                Value<bool> isDefault = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> managerName = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> companyId = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WarehousesCompanion.insert(
                uuid: uuid,
                code: code,
                name: name,
                isDefault: isDefault,
                isActive: isActive,
                address: address,
                phone: phone,
                managerName: managerName,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                version: version,
                companyId: companyId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WarehousesTableProcessedTableManager =
    ProcessedTableManager<
      _$InventoryDatabase,
      $WarehousesTable,
      WarehouseRow,
      $$WarehousesTableFilterComposer,
      $$WarehousesTableOrderingComposer,
      $$WarehousesTableAnnotationComposer,
      $$WarehousesTableCreateCompanionBuilder,
      $$WarehousesTableUpdateCompanionBuilder,
      (
        WarehouseRow,
        BaseReferences<_$InventoryDatabase, $WarehousesTable, WarehouseRow>,
      ),
      WarehouseRow,
      PrefetchHooks Function()
    >;
typedef $$ProductWarehouseStocksTableCreateCompanionBuilder =
    ProductWarehouseStocksCompanion Function({
      required String uuid,
      required String itemCode,
      required String warehouseId,
      Value<double> onHandQty,
      Value<double?> minReorderLevel,
      Value<String?> binLocation,
      required int createdAt,
      required int updatedAt,
      Value<String> syncStatus,
      Value<int> version,
      Value<String?> companyId,
      Value<int?> deletedAt,
      Value<int> rowid,
    });
typedef $$ProductWarehouseStocksTableUpdateCompanionBuilder =
    ProductWarehouseStocksCompanion Function({
      Value<String> uuid,
      Value<String> itemCode,
      Value<String> warehouseId,
      Value<double> onHandQty,
      Value<double?> minReorderLevel,
      Value<String?> binLocation,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<String> syncStatus,
      Value<int> version,
      Value<String?> companyId,
      Value<int?> deletedAt,
      Value<int> rowid,
    });

class $$ProductWarehouseStocksTableFilterComposer
    extends Composer<_$InventoryDatabase, $ProductWarehouseStocksTable> {
  $$ProductWarehouseStocksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemCode => $composableBuilder(
    column: $table.itemCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get warehouseId => $composableBuilder(
    column: $table.warehouseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get onHandQty => $composableBuilder(
    column: $table.onHandQty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minReorderLevel => $composableBuilder(
    column: $table.minReorderLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get binLocation => $composableBuilder(
    column: $table.binLocation,
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

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductWarehouseStocksTableOrderingComposer
    extends Composer<_$InventoryDatabase, $ProductWarehouseStocksTable> {
  $$ProductWarehouseStocksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemCode => $composableBuilder(
    column: $table.itemCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get warehouseId => $composableBuilder(
    column: $table.warehouseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get onHandQty => $composableBuilder(
    column: $table.onHandQty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minReorderLevel => $composableBuilder(
    column: $table.minReorderLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get binLocation => $composableBuilder(
    column: $table.binLocation,
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

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductWarehouseStocksTableAnnotationComposer
    extends Composer<_$InventoryDatabase, $ProductWarehouseStocksTable> {
  $$ProductWarehouseStocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get itemCode =>
      $composableBuilder(column: $table.itemCode, builder: (column) => column);

  GeneratedColumn<String> get warehouseId => $composableBuilder(
    column: $table.warehouseId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get onHandQty =>
      $composableBuilder(column: $table.onHandQty, builder: (column) => column);

  GeneratedColumn<double> get minReorderLevel => $composableBuilder(
    column: $table.minReorderLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get binLocation => $composableBuilder(
    column: $table.binLocation,
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

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$ProductWarehouseStocksTableTableManager
    extends
        RootTableManager<
          _$InventoryDatabase,
          $ProductWarehouseStocksTable,
          ProductWarehouseStockRow,
          $$ProductWarehouseStocksTableFilterComposer,
          $$ProductWarehouseStocksTableOrderingComposer,
          $$ProductWarehouseStocksTableAnnotationComposer,
          $$ProductWarehouseStocksTableCreateCompanionBuilder,
          $$ProductWarehouseStocksTableUpdateCompanionBuilder,
          (
            ProductWarehouseStockRow,
            BaseReferences<
              _$InventoryDatabase,
              $ProductWarehouseStocksTable,
              ProductWarehouseStockRow
            >,
          ),
          ProductWarehouseStockRow,
          PrefetchHooks Function()
        > {
  $$ProductWarehouseStocksTableTableManager(
    _$InventoryDatabase db,
    $ProductWarehouseStocksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductWarehouseStocksTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ProductWarehouseStocksTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ProductWarehouseStocksTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<String> itemCode = const Value.absent(),
                Value<String> warehouseId = const Value.absent(),
                Value<double> onHandQty = const Value.absent(),
                Value<double?> minReorderLevel = const Value.absent(),
                Value<String?> binLocation = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> companyId = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductWarehouseStocksCompanion(
                uuid: uuid,
                itemCode: itemCode,
                warehouseId: warehouseId,
                onHandQty: onHandQty,
                minReorderLevel: minReorderLevel,
                binLocation: binLocation,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                version: version,
                companyId: companyId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uuid,
                required String itemCode,
                required String warehouseId,
                Value<double> onHandQty = const Value.absent(),
                Value<double?> minReorderLevel = const Value.absent(),
                Value<String?> binLocation = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> companyId = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductWarehouseStocksCompanion.insert(
                uuid: uuid,
                itemCode: itemCode,
                warehouseId: warehouseId,
                onHandQty: onHandQty,
                minReorderLevel: minReorderLevel,
                binLocation: binLocation,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                version: version,
                companyId: companyId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductWarehouseStocksTableProcessedTableManager =
    ProcessedTableManager<
      _$InventoryDatabase,
      $ProductWarehouseStocksTable,
      ProductWarehouseStockRow,
      $$ProductWarehouseStocksTableFilterComposer,
      $$ProductWarehouseStocksTableOrderingComposer,
      $$ProductWarehouseStocksTableAnnotationComposer,
      $$ProductWarehouseStocksTableCreateCompanionBuilder,
      $$ProductWarehouseStocksTableUpdateCompanionBuilder,
      (
        ProductWarehouseStockRow,
        BaseReferences<
          _$InventoryDatabase,
          $ProductWarehouseStocksTable,
          ProductWarehouseStockRow
        >,
      ),
      ProductWarehouseStockRow,
      PrefetchHooks Function()
    >;
typedef $$StockTransfersTableCreateCompanionBuilder =
    StockTransfersCompanion Function({
      required String uuid,
      required String transferNumber,
      required String fromWarehouseId,
      required String toWarehouseId,
      required int transferDate,
      Value<String?> notes,
      required int createdAt,
      required int updatedAt,
      Value<String> syncStatus,
      Value<int> version,
      Value<String?> companyId,
      Value<String> status,
      Value<int?> postedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });
typedef $$StockTransfersTableUpdateCompanionBuilder =
    StockTransfersCompanion Function({
      Value<String> uuid,
      Value<String> transferNumber,
      Value<String> fromWarehouseId,
      Value<String> toWarehouseId,
      Value<int> transferDate,
      Value<String?> notes,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<String> syncStatus,
      Value<int> version,
      Value<String?> companyId,
      Value<String> status,
      Value<int?> postedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });

class $$StockTransfersTableFilterComposer
    extends Composer<_$InventoryDatabase, $StockTransfersTable> {
  $$StockTransfersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transferNumber => $composableBuilder(
    column: $table.transferNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromWarehouseId => $composableBuilder(
    column: $table.fromWarehouseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toWarehouseId => $composableBuilder(
    column: $table.toWarehouseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get transferDate => $composableBuilder(
    column: $table.transferDate,
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

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get postedAt => $composableBuilder(
    column: $table.postedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StockTransfersTableOrderingComposer
    extends Composer<_$InventoryDatabase, $StockTransfersTable> {
  $$StockTransfersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transferNumber => $composableBuilder(
    column: $table.transferNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromWarehouseId => $composableBuilder(
    column: $table.fromWarehouseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toWarehouseId => $composableBuilder(
    column: $table.toWarehouseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get transferDate => $composableBuilder(
    column: $table.transferDate,
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

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get postedAt => $composableBuilder(
    column: $table.postedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StockTransfersTableAnnotationComposer
    extends Composer<_$InventoryDatabase, $StockTransfersTable> {
  $$StockTransfersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get transferNumber => $composableBuilder(
    column: $table.transferNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fromWarehouseId => $composableBuilder(
    column: $table.fromWarehouseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toWarehouseId => $composableBuilder(
    column: $table.toWarehouseId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get transferDate => $composableBuilder(
    column: $table.transferDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get postedAt =>
      $composableBuilder(column: $table.postedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$StockTransfersTableTableManager
    extends
        RootTableManager<
          _$InventoryDatabase,
          $StockTransfersTable,
          StockTransferRow,
          $$StockTransfersTableFilterComposer,
          $$StockTransfersTableOrderingComposer,
          $$StockTransfersTableAnnotationComposer,
          $$StockTransfersTableCreateCompanionBuilder,
          $$StockTransfersTableUpdateCompanionBuilder,
          (
            StockTransferRow,
            BaseReferences<
              _$InventoryDatabase,
              $StockTransfersTable,
              StockTransferRow
            >,
          ),
          StockTransferRow,
          PrefetchHooks Function()
        > {
  $$StockTransfersTableTableManager(
    _$InventoryDatabase db,
    $StockTransfersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockTransfersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockTransfersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockTransfersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<String> transferNumber = const Value.absent(),
                Value<String> fromWarehouseId = const Value.absent(),
                Value<String> toWarehouseId = const Value.absent(),
                Value<int> transferDate = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> companyId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> postedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockTransfersCompanion(
                uuid: uuid,
                transferNumber: transferNumber,
                fromWarehouseId: fromWarehouseId,
                toWarehouseId: toWarehouseId,
                transferDate: transferDate,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                version: version,
                companyId: companyId,
                status: status,
                postedAt: postedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uuid,
                required String transferNumber,
                required String fromWarehouseId,
                required String toWarehouseId,
                required int transferDate,
                Value<String?> notes = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> companyId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> postedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockTransfersCompanion.insert(
                uuid: uuid,
                transferNumber: transferNumber,
                fromWarehouseId: fromWarehouseId,
                toWarehouseId: toWarehouseId,
                transferDate: transferDate,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                version: version,
                companyId: companyId,
                status: status,
                postedAt: postedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StockTransfersTableProcessedTableManager =
    ProcessedTableManager<
      _$InventoryDatabase,
      $StockTransfersTable,
      StockTransferRow,
      $$StockTransfersTableFilterComposer,
      $$StockTransfersTableOrderingComposer,
      $$StockTransfersTableAnnotationComposer,
      $$StockTransfersTableCreateCompanionBuilder,
      $$StockTransfersTableUpdateCompanionBuilder,
      (
        StockTransferRow,
        BaseReferences<
          _$InventoryDatabase,
          $StockTransfersTable,
          StockTransferRow
        >,
      ),
      StockTransferRow,
      PrefetchHooks Function()
    >;
typedef $$InventoryAuditTrailTableCreateCompanionBuilder =
    InventoryAuditTrailCompanion Function({
      Value<int> id,
      required String uuid,
      required String documentId,
      required String documentType,
      required String eventType,
      Value<String?> userId,
      Value<String?> notes,
      required int timestamp,
      Value<String?> metadata,
      Value<String?> companyId,
    });
typedef $$InventoryAuditTrailTableUpdateCompanionBuilder =
    InventoryAuditTrailCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String> documentId,
      Value<String> documentType,
      Value<String> eventType,
      Value<String?> userId,
      Value<String?> notes,
      Value<int> timestamp,
      Value<String?> metadata,
      Value<String?> companyId,
    });

class $$InventoryAuditTrailTableFilterComposer
    extends Composer<_$InventoryDatabase, $InventoryAuditTrailTable> {
  $$InventoryAuditTrailTableFilterComposer({
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

  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentType => $composableBuilder(
    column: $table.documentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InventoryAuditTrailTableOrderingComposer
    extends Composer<_$InventoryDatabase, $InventoryAuditTrailTable> {
  $$InventoryAuditTrailTableOrderingComposer({
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

  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentType => $composableBuilder(
    column: $table.documentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InventoryAuditTrailTableAnnotationComposer
    extends Composer<_$InventoryDatabase, $InventoryAuditTrailTable> {
  $$InventoryAuditTrailTableAnnotationComposer({
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

  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get documentType => $composableBuilder(
    column: $table.documentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);
}

class $$InventoryAuditTrailTableTableManager
    extends
        RootTableManager<
          _$InventoryDatabase,
          $InventoryAuditTrailTable,
          InventoryAuditTrailRow,
          $$InventoryAuditTrailTableFilterComposer,
          $$InventoryAuditTrailTableOrderingComposer,
          $$InventoryAuditTrailTableAnnotationComposer,
          $$InventoryAuditTrailTableCreateCompanionBuilder,
          $$InventoryAuditTrailTableUpdateCompanionBuilder,
          (
            InventoryAuditTrailRow,
            BaseReferences<
              _$InventoryDatabase,
              $InventoryAuditTrailTable,
              InventoryAuditTrailRow
            >,
          ),
          InventoryAuditTrailRow,
          PrefetchHooks Function()
        > {
  $$InventoryAuditTrailTableTableManager(
    _$InventoryDatabase db,
    $InventoryAuditTrailTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryAuditTrailTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryAuditTrailTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$InventoryAuditTrailTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> documentId = const Value.absent(),
                Value<String> documentType = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> timestamp = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<String?> companyId = const Value.absent(),
              }) => InventoryAuditTrailCompanion(
                id: id,
                uuid: uuid,
                documentId: documentId,
                documentType: documentType,
                eventType: eventType,
                userId: userId,
                notes: notes,
                timestamp: timestamp,
                metadata: metadata,
                companyId: companyId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required String documentId,
                required String documentType,
                required String eventType,
                Value<String?> userId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required int timestamp,
                Value<String?> metadata = const Value.absent(),
                Value<String?> companyId = const Value.absent(),
              }) => InventoryAuditTrailCompanion.insert(
                id: id,
                uuid: uuid,
                documentId: documentId,
                documentType: documentType,
                eventType: eventType,
                userId: userId,
                notes: notes,
                timestamp: timestamp,
                metadata: metadata,
                companyId: companyId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InventoryAuditTrailTableProcessedTableManager =
    ProcessedTableManager<
      _$InventoryDatabase,
      $InventoryAuditTrailTable,
      InventoryAuditTrailRow,
      $$InventoryAuditTrailTableFilterComposer,
      $$InventoryAuditTrailTableOrderingComposer,
      $$InventoryAuditTrailTableAnnotationComposer,
      $$InventoryAuditTrailTableCreateCompanionBuilder,
      $$InventoryAuditTrailTableUpdateCompanionBuilder,
      (
        InventoryAuditTrailRow,
        BaseReferences<
          _$InventoryDatabase,
          $InventoryAuditTrailTable,
          InventoryAuditTrailRow
        >,
      ),
      InventoryAuditTrailRow,
      PrefetchHooks Function()
    >;

class $InventoryDatabaseManager {
  final _$InventoryDatabase _db;
  $InventoryDatabaseManager(this._db);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$StockReceiptsTableTableManager get stockReceipts =>
      $$StockReceiptsTableTableManager(_db, _db.stockReceipts);
  $$StockIssuesTableTableManager get stockIssues =>
      $$StockIssuesTableTableManager(_db, _db.stockIssues);
  $$StockMovementLinesTableTableManager get stockMovementLines =>
      $$StockMovementLinesTableTableManager(_db, _db.stockMovementLines);
  $$InventoryCostLayersTableTableManager get inventoryCostLayers =>
      $$InventoryCostLayersTableTableManager(_db, _db.inventoryCostLayers);
  $$InventoryCostConsumptionsTableTableManager get inventoryCostConsumptions =>
      $$InventoryCostConsumptionsTableTableManager(
        _db,
        _db.inventoryCostConsumptions,
      );
  $$StockReturnsTableTableManager get stockReturns =>
      $$StockReturnsTableTableManager(_db, _db.stockReturns);
  $$WarehousesTableTableManager get warehouses =>
      $$WarehousesTableTableManager(_db, _db.warehouses);
  $$ProductWarehouseStocksTableTableManager get productWarehouseStocks =>
      $$ProductWarehouseStocksTableTableManager(
        _db,
        _db.productWarehouseStocks,
      );
  $$StockTransfersTableTableManager get stockTransfers =>
      $$StockTransfersTableTableManager(_db, _db.stockTransfers);
  $$InventoryAuditTrailTableTableManager get inventoryAuditTrail =>
      $$InventoryAuditTrailTableTableManager(_db, _db.inventoryAuditTrail);
}
