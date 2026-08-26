// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sales_database.dart';

// ignore_for_file: type=lint
class $SalesTable extends Sales with TableInfo<$SalesTable, SaleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SalesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _saleNumberMeta = const VerificationMeta(
    'saleNumber',
  );
  @override
  late final GeneratedColumn<String> saleNumber = GeneratedColumn<String>(
    'sale_number',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saleDateMeta = const VerificationMeta(
    'saleDate',
  );
  @override
  late final GeneratedColumn<int> saleDate = GeneratedColumn<int>(
    'sale_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _settlementTypeMeta = const VerificationMeta(
    'settlementType',
  );
  @override
  late final GeneratedColumn<String> settlementType = GeneratedColumn<String>(
    'settlement_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('cash'),
  );
  static const VerificationMeta _voucherBookIdMeta = const VerificationMeta(
    'voucherBookId',
  );
  @override
  late final GeneratedColumn<String> voucherBookId = GeneratedColumn<String>(
    'voucher_book_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerCodeMeta = const VerificationMeta(
    'customerCode',
  );
  @override
  late final GeneratedColumn<String> customerCode = GeneratedColumn<String>(
    'customer_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerAccountIdMeta = const VerificationMeta(
    'customerAccountId',
  );
  @override
  late final GeneratedColumn<String> customerAccountId =
      GeneratedColumn<String>(
        'customer_account_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _cashAccountIdMeta = const VerificationMeta(
    'cashAccountId',
  );
  @override
  late final GeneratedColumn<String> cashAccountId = GeneratedColumn<String>(
    'cash_account_id',
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
  static const VerificationMeta _baseCurrencyCodeMeta = const VerificationMeta(
    'baseCurrencyCode',
  );
  @override
  late final GeneratedColumn<String> baseCurrencyCode = GeneratedColumn<String>(
    'base_currency_code',
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
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemDiscountTotalMeta = const VerificationMeta(
    'itemDiscountTotal',
  );
  @override
  late final GeneratedColumn<double> itemDiscountTotal =
      GeneratedColumn<double>(
        'item_discount_total',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _discountTypeMeta = const VerificationMeta(
    'discountType',
  );
  @override
  late final GeneratedColumn<String> discountType = GeneratedColumn<String>(
    'discount_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('fixed'),
  );
  static const VerificationMeta _discountValueMeta = const VerificationMeta(
    'discountValue',
  );
  @override
  late final GeneratedColumn<double> discountValue = GeneratedColumn<double>(
    'discount_value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _discountAmountMeta = const VerificationMeta(
    'discountAmount',
  );
  @override
  late final GeneratedColumn<double> discountAmount = GeneratedColumn<double>(
    'discount_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _taxRateMeta = const VerificationMeta(
    'taxRate',
  );
  @override
  late final GeneratedColumn<double> taxRate = GeneratedColumn<double>(
    'tax_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _taxAmountMeta = const VerificationMeta(
    'taxAmount',
  );
  @override
  late final GeneratedColumn<double> taxAmount = GeneratedColumn<double>(
    'tax_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<double> total = GeneratedColumn<double>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidAmountMeta = const VerificationMeta(
    'paidAmount',
  );
  @override
  late final GeneratedColumn<double> paidAmount = GeneratedColumn<double>(
    'paid_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _remainingAmountMeta = const VerificationMeta(
    'remainingAmount',
  );
  @override
  late final GeneratedColumn<double> remainingAmount = GeneratedColumn<double>(
    'remaining_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _paymentStatusMeta = const VerificationMeta(
    'paymentStatus',
  );
  @override
  late final GeneratedColumn<String> paymentStatus = GeneratedColumn<String>(
    'payment_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unpaid'),
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('cash'),
  );
  static const VerificationMeta _saleStatusMeta = const VerificationMeta(
    'saleStatus',
  );
  @override
  late final GeneratedColumn<String> saleStatus = GeneratedColumn<String>(
    'sale_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
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
  static const VerificationMeta _submittedAtMeta = const VerificationMeta(
    'submittedAt',
  );
  @override
  late final GeneratedColumn<int> submittedAt = GeneratedColumn<int>(
    'submitted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confirmedAtMeta = const VerificationMeta(
    'confirmedAt',
  );
  @override
  late final GeneratedColumn<int> confirmedAt = GeneratedColumn<int>(
    'confirmed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cancelledAtMeta = const VerificationMeta(
    'cancelledAt',
  );
  @override
  late final GeneratedColumn<int> cancelledAt = GeneratedColumn<int>(
    'cancelled_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _externalDocumentNumberMeta =
      const VerificationMeta('externalDocumentNumber');
  @override
  late final GeneratedColumn<String> externalDocumentNumber =
      GeneratedColumn<String>(
        'external_document_number',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _externalStatusMeta = const VerificationMeta(
    'externalStatus',
  );
  @override
  late final GeneratedColumn<String> externalStatus = GeneratedColumn<String>(
    'external_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dataSourceMeta = const VerificationMeta(
    'dataSource',
  );
  @override
  late final GeneratedColumn<String> dataSource = GeneratedColumn<String>(
    'data_source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
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
    saleNumber,
    saleDate,
    settlementType,
    voucherBookId,
    customerId,
    customerCode,
    customerName,
    customerAccountId,
    cashAccountId,
    currencyCode,
    baseCurrencyCode,
    exchangeRate,
    subtotal,
    itemDiscountTotal,
    discountType,
    discountValue,
    discountAmount,
    taxRate,
    taxAmount,
    total,
    paidAmount,
    remainingAmount,
    paymentStatus,
    paymentMethod,
    saleStatus,
    notes,
    createdAt,
    updatedAt,
    submittedAt,
    confirmedAt,
    completedAt,
    cancelledAt,
    externalId,
    externalDocumentNumber,
    externalStatus,
    dataSource,
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
  static const String $name = 'sales';
  @override
  VerificationContext validateIntegrity(
    Insertable<SaleRow> instance, {
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
    if (data.containsKey('sale_number')) {
      context.handle(
        _saleNumberMeta,
        saleNumber.isAcceptableOrUnknown(data['sale_number']!, _saleNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_saleNumberMeta);
    }
    if (data.containsKey('sale_date')) {
      context.handle(
        _saleDateMeta,
        saleDate.isAcceptableOrUnknown(data['sale_date']!, _saleDateMeta),
      );
    }
    if (data.containsKey('settlement_type')) {
      context.handle(
        _settlementTypeMeta,
        settlementType.isAcceptableOrUnknown(
          data['settlement_type']!,
          _settlementTypeMeta,
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
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    }
    if (data.containsKey('customer_code')) {
      context.handle(
        _customerCodeMeta,
        customerCode.isAcceptableOrUnknown(
          data['customer_code']!,
          _customerCodeMeta,
        ),
      );
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    }
    if (data.containsKey('customer_account_id')) {
      context.handle(
        _customerAccountIdMeta,
        customerAccountId.isAcceptableOrUnknown(
          data['customer_account_id']!,
          _customerAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('cash_account_id')) {
      context.handle(
        _cashAccountIdMeta,
        cashAccountId.isAcceptableOrUnknown(
          data['cash_account_id']!,
          _cashAccountIdMeta,
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
    if (data.containsKey('base_currency_code')) {
      context.handle(
        _baseCurrencyCodeMeta,
        baseCurrencyCode.isAcceptableOrUnknown(
          data['base_currency_code']!,
          _baseCurrencyCodeMeta,
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
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    } else if (isInserting) {
      context.missing(_subtotalMeta);
    }
    if (data.containsKey('item_discount_total')) {
      context.handle(
        _itemDiscountTotalMeta,
        itemDiscountTotal.isAcceptableOrUnknown(
          data['item_discount_total']!,
          _itemDiscountTotalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_itemDiscountTotalMeta);
    }
    if (data.containsKey('discount_type')) {
      context.handle(
        _discountTypeMeta,
        discountType.isAcceptableOrUnknown(
          data['discount_type']!,
          _discountTypeMeta,
        ),
      );
    }
    if (data.containsKey('discount_value')) {
      context.handle(
        _discountValueMeta,
        discountValue.isAcceptableOrUnknown(
          data['discount_value']!,
          _discountValueMeta,
        ),
      );
    }
    if (data.containsKey('discount_amount')) {
      context.handle(
        _discountAmountMeta,
        discountAmount.isAcceptableOrUnknown(
          data['discount_amount']!,
          _discountAmountMeta,
        ),
      );
    }
    if (data.containsKey('tax_rate')) {
      context.handle(
        _taxRateMeta,
        taxRate.isAcceptableOrUnknown(data['tax_rate']!, _taxRateMeta),
      );
    }
    if (data.containsKey('tax_amount')) {
      context.handle(
        _taxAmountMeta,
        taxAmount.isAcceptableOrUnknown(data['tax_amount']!, _taxAmountMeta),
      );
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('paid_amount')) {
      context.handle(
        _paidAmountMeta,
        paidAmount.isAcceptableOrUnknown(data['paid_amount']!, _paidAmountMeta),
      );
    }
    if (data.containsKey('remaining_amount')) {
      context.handle(
        _remainingAmountMeta,
        remainingAmount.isAcceptableOrUnknown(
          data['remaining_amount']!,
          _remainingAmountMeta,
        ),
      );
    }
    if (data.containsKey('payment_status')) {
      context.handle(
        _paymentStatusMeta,
        paymentStatus.isAcceptableOrUnknown(
          data['payment_status']!,
          _paymentStatusMeta,
        ),
      );
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('sale_status')) {
      context.handle(
        _saleStatusMeta,
        saleStatus.isAcceptableOrUnknown(data['sale_status']!, _saleStatusMeta),
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
    if (data.containsKey('submitted_at')) {
      context.handle(
        _submittedAtMeta,
        submittedAt.isAcceptableOrUnknown(
          data['submitted_at']!,
          _submittedAtMeta,
        ),
      );
    }
    if (data.containsKey('confirmed_at')) {
      context.handle(
        _confirmedAtMeta,
        confirmedAt.isAcceptableOrUnknown(
          data['confirmed_at']!,
          _confirmedAtMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('cancelled_at')) {
      context.handle(
        _cancelledAtMeta,
        cancelledAt.isAcceptableOrUnknown(
          data['cancelled_at']!,
          _cancelledAtMeta,
        ),
      );
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    }
    if (data.containsKey('external_document_number')) {
      context.handle(
        _externalDocumentNumberMeta,
        externalDocumentNumber.isAcceptableOrUnknown(
          data['external_document_number']!,
          _externalDocumentNumberMeta,
        ),
      );
    }
    if (data.containsKey('external_status')) {
      context.handle(
        _externalStatusMeta,
        externalStatus.isAcceptableOrUnknown(
          data['external_status']!,
          _externalStatusMeta,
        ),
      );
    }
    if (data.containsKey('data_source')) {
      context.handle(
        _dataSourceMeta,
        dataSource.isAcceptableOrUnknown(data['data_source']!, _dataSourceMeta),
      );
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
  SaleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SaleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      saleNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_number'],
      )!,
      saleDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sale_date'],
      )!,
      settlementType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}settlement_type'],
      )!,
      voucherBookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voucher_book_id'],
      ),
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      ),
      customerCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_code'],
      ),
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      ),
      customerAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_account_id'],
      ),
      cashAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cash_account_id'],
      ),
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      baseCurrencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_currency_code'],
      )!,
      exchangeRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}exchange_rate'],
      )!,
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}subtotal'],
      )!,
      itemDiscountTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}item_discount_total'],
      )!,
      discountType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discount_type'],
      )!,
      discountValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}discount_value'],
      )!,
      discountAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}discount_amount'],
      )!,
      taxRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tax_rate'],
      )!,
      taxAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tax_amount'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total'],
      )!,
      paidAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}paid_amount'],
      )!,
      remainingAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}remaining_amount'],
      )!,
      paymentStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_status'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      )!,
      saleStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_status'],
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
      submittedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}submitted_at'],
      ),
      confirmedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}confirmed_at'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      ),
      cancelledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cancelled_at'],
      ),
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      ),
      externalDocumentNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_document_number'],
      ),
      externalStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_status'],
      ),
      dataSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_source'],
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
  $SalesTable createAlias(String alias) {
    return $SalesTable(attachedDatabase, alias);
  }
}

class SaleRow extends DataClass implements Insertable<SaleRow> {
  final int id;
  final String uuid;
  final String saleNumber;

  /// Business date of the invoice (UTC epoch ms, date portion).
  final int saleDate;

  /// [SaleSettlementType.name] — cash | credit
  final String settlementType;

  /// VoucherBook.uuid used for numbering.
  final String? voucherBookId;

  /// Customer.uuid — opaque FK.
  final String? customerId;
  final String? customerCode;
  final String? customerName;

  /// Customer CoA Account.uuid for credit settlement.
  final String? customerAccountId;

  /// Cash/treasury CoA Account.uuid for cash settlement.
  final String? cashAccountId;
  final String currencyCode;
  final String baseCurrencyCode;

  /// rateToBase snapshot at save time.
  final double exchangeRate;
  final double subtotal;
  final double itemDiscountTotal;
  final String discountType;
  final double discountValue;
  final double discountAmount;
  final double taxRate;
  final double taxAmount;
  final double total;
  final double paidAmount;
  final double remainingAmount;
  final String paymentStatus;
  final String paymentMethod;
  final String saleStatus;
  final String? notes;
  final int createdAt;
  final int updatedAt;
  final int? submittedAt;
  final int? confirmedAt;
  final int? completedAt;
  final int? cancelledAt;
  final String? externalId;
  final String? externalDocumentNumber;
  final String? externalStatus;
  final String dataSource;
  final String syncStatus;
  final int? lastSyncedAt;
  final int version;

  /// Company / Tenant owner ID for local multi-tenant data isolation.
  final String? companyId;
  final int? deletedAt;
  const SaleRow({
    required this.id,
    required this.uuid,
    required this.saleNumber,
    required this.saleDate,
    required this.settlementType,
    this.voucherBookId,
    this.customerId,
    this.customerCode,
    this.customerName,
    this.customerAccountId,
    this.cashAccountId,
    required this.currencyCode,
    required this.baseCurrencyCode,
    required this.exchangeRate,
    required this.subtotal,
    required this.itemDiscountTotal,
    required this.discountType,
    required this.discountValue,
    required this.discountAmount,
    required this.taxRate,
    required this.taxAmount,
    required this.total,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.saleStatus,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.submittedAt,
    this.confirmedAt,
    this.completedAt,
    this.cancelledAt,
    this.externalId,
    this.externalDocumentNumber,
    this.externalStatus,
    required this.dataSource,
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
    map['sale_number'] = Variable<String>(saleNumber);
    map['sale_date'] = Variable<int>(saleDate);
    map['settlement_type'] = Variable<String>(settlementType);
    if (!nullToAbsent || voucherBookId != null) {
      map['voucher_book_id'] = Variable<String>(voucherBookId);
    }
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<String>(customerId);
    }
    if (!nullToAbsent || customerCode != null) {
      map['customer_code'] = Variable<String>(customerCode);
    }
    if (!nullToAbsent || customerName != null) {
      map['customer_name'] = Variable<String>(customerName);
    }
    if (!nullToAbsent || customerAccountId != null) {
      map['customer_account_id'] = Variable<String>(customerAccountId);
    }
    if (!nullToAbsent || cashAccountId != null) {
      map['cash_account_id'] = Variable<String>(cashAccountId);
    }
    map['currency_code'] = Variable<String>(currencyCode);
    map['base_currency_code'] = Variable<String>(baseCurrencyCode);
    map['exchange_rate'] = Variable<double>(exchangeRate);
    map['subtotal'] = Variable<double>(subtotal);
    map['item_discount_total'] = Variable<double>(itemDiscountTotal);
    map['discount_type'] = Variable<String>(discountType);
    map['discount_value'] = Variable<double>(discountValue);
    map['discount_amount'] = Variable<double>(discountAmount);
    map['tax_rate'] = Variable<double>(taxRate);
    map['tax_amount'] = Variable<double>(taxAmount);
    map['total'] = Variable<double>(total);
    map['paid_amount'] = Variable<double>(paidAmount);
    map['remaining_amount'] = Variable<double>(remainingAmount);
    map['payment_status'] = Variable<String>(paymentStatus);
    map['payment_method'] = Variable<String>(paymentMethod);
    map['sale_status'] = Variable<String>(saleStatus);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || submittedAt != null) {
      map['submitted_at'] = Variable<int>(submittedAt);
    }
    if (!nullToAbsent || confirmedAt != null) {
      map['confirmed_at'] = Variable<int>(confirmedAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    if (!nullToAbsent || cancelledAt != null) {
      map['cancelled_at'] = Variable<int>(cancelledAt);
    }
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    if (!nullToAbsent || externalDocumentNumber != null) {
      map['external_document_number'] = Variable<String>(
        externalDocumentNumber,
      );
    }
    if (!nullToAbsent || externalStatus != null) {
      map['external_status'] = Variable<String>(externalStatus);
    }
    map['data_source'] = Variable<String>(dataSource);
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

  SalesCompanion toCompanion(bool nullToAbsent) {
    return SalesCompanion(
      id: Value(id),
      uuid: Value(uuid),
      saleNumber: Value(saleNumber),
      saleDate: Value(saleDate),
      settlementType: Value(settlementType),
      voucherBookId: voucherBookId == null && nullToAbsent
          ? const Value.absent()
          : Value(voucherBookId),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      customerCode: customerCode == null && nullToAbsent
          ? const Value.absent()
          : Value(customerCode),
      customerName: customerName == null && nullToAbsent
          ? const Value.absent()
          : Value(customerName),
      customerAccountId: customerAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerAccountId),
      cashAccountId: cashAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(cashAccountId),
      currencyCode: Value(currencyCode),
      baseCurrencyCode: Value(baseCurrencyCode),
      exchangeRate: Value(exchangeRate),
      subtotal: Value(subtotal),
      itemDiscountTotal: Value(itemDiscountTotal),
      discountType: Value(discountType),
      discountValue: Value(discountValue),
      discountAmount: Value(discountAmount),
      taxRate: Value(taxRate),
      taxAmount: Value(taxAmount),
      total: Value(total),
      paidAmount: Value(paidAmount),
      remainingAmount: Value(remainingAmount),
      paymentStatus: Value(paymentStatus),
      paymentMethod: Value(paymentMethod),
      saleStatus: Value(saleStatus),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      submittedAt: submittedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(submittedAt),
      confirmedAt: confirmedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      cancelledAt: cancelledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(cancelledAt),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
      externalDocumentNumber: externalDocumentNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(externalDocumentNumber),
      externalStatus: externalStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(externalStatus),
      dataSource: Value(dataSource),
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

  factory SaleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SaleRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      saleNumber: serializer.fromJson<String>(json['saleNumber']),
      saleDate: serializer.fromJson<int>(json['saleDate']),
      settlementType: serializer.fromJson<String>(json['settlementType']),
      voucherBookId: serializer.fromJson<String?>(json['voucherBookId']),
      customerId: serializer.fromJson<String?>(json['customerId']),
      customerCode: serializer.fromJson<String?>(json['customerCode']),
      customerName: serializer.fromJson<String?>(json['customerName']),
      customerAccountId: serializer.fromJson<String?>(
        json['customerAccountId'],
      ),
      cashAccountId: serializer.fromJson<String?>(json['cashAccountId']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      baseCurrencyCode: serializer.fromJson<String>(json['baseCurrencyCode']),
      exchangeRate: serializer.fromJson<double>(json['exchangeRate']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
      itemDiscountTotal: serializer.fromJson<double>(json['itemDiscountTotal']),
      discountType: serializer.fromJson<String>(json['discountType']),
      discountValue: serializer.fromJson<double>(json['discountValue']),
      discountAmount: serializer.fromJson<double>(json['discountAmount']),
      taxRate: serializer.fromJson<double>(json['taxRate']),
      taxAmount: serializer.fromJson<double>(json['taxAmount']),
      total: serializer.fromJson<double>(json['total']),
      paidAmount: serializer.fromJson<double>(json['paidAmount']),
      remainingAmount: serializer.fromJson<double>(json['remainingAmount']),
      paymentStatus: serializer.fromJson<String>(json['paymentStatus']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      saleStatus: serializer.fromJson<String>(json['saleStatus']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      submittedAt: serializer.fromJson<int?>(json['submittedAt']),
      confirmedAt: serializer.fromJson<int?>(json['confirmedAt']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
      cancelledAt: serializer.fromJson<int?>(json['cancelledAt']),
      externalId: serializer.fromJson<String?>(json['externalId']),
      externalDocumentNumber: serializer.fromJson<String?>(
        json['externalDocumentNumber'],
      ),
      externalStatus: serializer.fromJson<String?>(json['externalStatus']),
      dataSource: serializer.fromJson<String>(json['dataSource']),
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
      'saleNumber': serializer.toJson<String>(saleNumber),
      'saleDate': serializer.toJson<int>(saleDate),
      'settlementType': serializer.toJson<String>(settlementType),
      'voucherBookId': serializer.toJson<String?>(voucherBookId),
      'customerId': serializer.toJson<String?>(customerId),
      'customerCode': serializer.toJson<String?>(customerCode),
      'customerName': serializer.toJson<String?>(customerName),
      'customerAccountId': serializer.toJson<String?>(customerAccountId),
      'cashAccountId': serializer.toJson<String?>(cashAccountId),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'baseCurrencyCode': serializer.toJson<String>(baseCurrencyCode),
      'exchangeRate': serializer.toJson<double>(exchangeRate),
      'subtotal': serializer.toJson<double>(subtotal),
      'itemDiscountTotal': serializer.toJson<double>(itemDiscountTotal),
      'discountType': serializer.toJson<String>(discountType),
      'discountValue': serializer.toJson<double>(discountValue),
      'discountAmount': serializer.toJson<double>(discountAmount),
      'taxRate': serializer.toJson<double>(taxRate),
      'taxAmount': serializer.toJson<double>(taxAmount),
      'total': serializer.toJson<double>(total),
      'paidAmount': serializer.toJson<double>(paidAmount),
      'remainingAmount': serializer.toJson<double>(remainingAmount),
      'paymentStatus': serializer.toJson<String>(paymentStatus),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'saleStatus': serializer.toJson<String>(saleStatus),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'submittedAt': serializer.toJson<int?>(submittedAt),
      'confirmedAt': serializer.toJson<int?>(confirmedAt),
      'completedAt': serializer.toJson<int?>(completedAt),
      'cancelledAt': serializer.toJson<int?>(cancelledAt),
      'externalId': serializer.toJson<String?>(externalId),
      'externalDocumentNumber': serializer.toJson<String?>(
        externalDocumentNumber,
      ),
      'externalStatus': serializer.toJson<String?>(externalStatus),
      'dataSource': serializer.toJson<String>(dataSource),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'lastSyncedAt': serializer.toJson<int?>(lastSyncedAt),
      'version': serializer.toJson<int>(version),
      'companyId': serializer.toJson<String?>(companyId),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  SaleRow copyWith({
    int? id,
    String? uuid,
    String? saleNumber,
    int? saleDate,
    String? settlementType,
    Value<String?> voucherBookId = const Value.absent(),
    Value<String?> customerId = const Value.absent(),
    Value<String?> customerCode = const Value.absent(),
    Value<String?> customerName = const Value.absent(),
    Value<String?> customerAccountId = const Value.absent(),
    Value<String?> cashAccountId = const Value.absent(),
    String? currencyCode,
    String? baseCurrencyCode,
    double? exchangeRate,
    double? subtotal,
    double? itemDiscountTotal,
    String? discountType,
    double? discountValue,
    double? discountAmount,
    double? taxRate,
    double? taxAmount,
    double? total,
    double? paidAmount,
    double? remainingAmount,
    String? paymentStatus,
    String? paymentMethod,
    String? saleStatus,
    Value<String?> notes = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    Value<int?> submittedAt = const Value.absent(),
    Value<int?> confirmedAt = const Value.absent(),
    Value<int?> completedAt = const Value.absent(),
    Value<int?> cancelledAt = const Value.absent(),
    Value<String?> externalId = const Value.absent(),
    Value<String?> externalDocumentNumber = const Value.absent(),
    Value<String?> externalStatus = const Value.absent(),
    String? dataSource,
    String? syncStatus,
    Value<int?> lastSyncedAt = const Value.absent(),
    int? version,
    Value<String?> companyId = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
  }) => SaleRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    saleNumber: saleNumber ?? this.saleNumber,
    saleDate: saleDate ?? this.saleDate,
    settlementType: settlementType ?? this.settlementType,
    voucherBookId: voucherBookId.present
        ? voucherBookId.value
        : this.voucherBookId,
    customerId: customerId.present ? customerId.value : this.customerId,
    customerCode: customerCode.present ? customerCode.value : this.customerCode,
    customerName: customerName.present ? customerName.value : this.customerName,
    customerAccountId: customerAccountId.present
        ? customerAccountId.value
        : this.customerAccountId,
    cashAccountId: cashAccountId.present
        ? cashAccountId.value
        : this.cashAccountId,
    currencyCode: currencyCode ?? this.currencyCode,
    baseCurrencyCode: baseCurrencyCode ?? this.baseCurrencyCode,
    exchangeRate: exchangeRate ?? this.exchangeRate,
    subtotal: subtotal ?? this.subtotal,
    itemDiscountTotal: itemDiscountTotal ?? this.itemDiscountTotal,
    discountType: discountType ?? this.discountType,
    discountValue: discountValue ?? this.discountValue,
    discountAmount: discountAmount ?? this.discountAmount,
    taxRate: taxRate ?? this.taxRate,
    taxAmount: taxAmount ?? this.taxAmount,
    total: total ?? this.total,
    paidAmount: paidAmount ?? this.paidAmount,
    remainingAmount: remainingAmount ?? this.remainingAmount,
    paymentStatus: paymentStatus ?? this.paymentStatus,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    saleStatus: saleStatus ?? this.saleStatus,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    submittedAt: submittedAt.present ? submittedAt.value : this.submittedAt,
    confirmedAt: confirmedAt.present ? confirmedAt.value : this.confirmedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    cancelledAt: cancelledAt.present ? cancelledAt.value : this.cancelledAt,
    externalId: externalId.present ? externalId.value : this.externalId,
    externalDocumentNumber: externalDocumentNumber.present
        ? externalDocumentNumber.value
        : this.externalDocumentNumber,
    externalStatus: externalStatus.present
        ? externalStatus.value
        : this.externalStatus,
    dataSource: dataSource ?? this.dataSource,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    version: version ?? this.version,
    companyId: companyId.present ? companyId.value : this.companyId,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  SaleRow copyWithCompanion(SalesCompanion data) {
    return SaleRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      saleNumber: data.saleNumber.present
          ? data.saleNumber.value
          : this.saleNumber,
      saleDate: data.saleDate.present ? data.saleDate.value : this.saleDate,
      settlementType: data.settlementType.present
          ? data.settlementType.value
          : this.settlementType,
      voucherBookId: data.voucherBookId.present
          ? data.voucherBookId.value
          : this.voucherBookId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      customerCode: data.customerCode.present
          ? data.customerCode.value
          : this.customerCode,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      customerAccountId: data.customerAccountId.present
          ? data.customerAccountId.value
          : this.customerAccountId,
      cashAccountId: data.cashAccountId.present
          ? data.cashAccountId.value
          : this.cashAccountId,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      baseCurrencyCode: data.baseCurrencyCode.present
          ? data.baseCurrencyCode.value
          : this.baseCurrencyCode,
      exchangeRate: data.exchangeRate.present
          ? data.exchangeRate.value
          : this.exchangeRate,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      itemDiscountTotal: data.itemDiscountTotal.present
          ? data.itemDiscountTotal.value
          : this.itemDiscountTotal,
      discountType: data.discountType.present
          ? data.discountType.value
          : this.discountType,
      discountValue: data.discountValue.present
          ? data.discountValue.value
          : this.discountValue,
      discountAmount: data.discountAmount.present
          ? data.discountAmount.value
          : this.discountAmount,
      taxRate: data.taxRate.present ? data.taxRate.value : this.taxRate,
      taxAmount: data.taxAmount.present ? data.taxAmount.value : this.taxAmount,
      total: data.total.present ? data.total.value : this.total,
      paidAmount: data.paidAmount.present
          ? data.paidAmount.value
          : this.paidAmount,
      remainingAmount: data.remainingAmount.present
          ? data.remainingAmount.value
          : this.remainingAmount,
      paymentStatus: data.paymentStatus.present
          ? data.paymentStatus.value
          : this.paymentStatus,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      saleStatus: data.saleStatus.present
          ? data.saleStatus.value
          : this.saleStatus,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      submittedAt: data.submittedAt.present
          ? data.submittedAt.value
          : this.submittedAt,
      confirmedAt: data.confirmedAt.present
          ? data.confirmedAt.value
          : this.confirmedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      cancelledAt: data.cancelledAt.present
          ? data.cancelledAt.value
          : this.cancelledAt,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      externalDocumentNumber: data.externalDocumentNumber.present
          ? data.externalDocumentNumber.value
          : this.externalDocumentNumber,
      externalStatus: data.externalStatus.present
          ? data.externalStatus.value
          : this.externalStatus,
      dataSource: data.dataSource.present
          ? data.dataSource.value
          : this.dataSource,
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
    return (StringBuffer('SaleRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('saleNumber: $saleNumber, ')
          ..write('saleDate: $saleDate, ')
          ..write('settlementType: $settlementType, ')
          ..write('voucherBookId: $voucherBookId, ')
          ..write('customerId: $customerId, ')
          ..write('customerCode: $customerCode, ')
          ..write('customerName: $customerName, ')
          ..write('customerAccountId: $customerAccountId, ')
          ..write('cashAccountId: $cashAccountId, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('baseCurrencyCode: $baseCurrencyCode, ')
          ..write('exchangeRate: $exchangeRate, ')
          ..write('subtotal: $subtotal, ')
          ..write('itemDiscountTotal: $itemDiscountTotal, ')
          ..write('discountType: $discountType, ')
          ..write('discountValue: $discountValue, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('taxRate: $taxRate, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('total: $total, ')
          ..write('paidAmount: $paidAmount, ')
          ..write('remainingAmount: $remainingAmount, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('saleStatus: $saleStatus, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('submittedAt: $submittedAt, ')
          ..write('confirmedAt: $confirmedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('cancelledAt: $cancelledAt, ')
          ..write('externalId: $externalId, ')
          ..write('externalDocumentNumber: $externalDocumentNumber, ')
          ..write('externalStatus: $externalStatus, ')
          ..write('dataSource: $dataSource, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('version: $version, ')
          ..write('companyId: $companyId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    uuid,
    saleNumber,
    saleDate,
    settlementType,
    voucherBookId,
    customerId,
    customerCode,
    customerName,
    customerAccountId,
    cashAccountId,
    currencyCode,
    baseCurrencyCode,
    exchangeRate,
    subtotal,
    itemDiscountTotal,
    discountType,
    discountValue,
    discountAmount,
    taxRate,
    taxAmount,
    total,
    paidAmount,
    remainingAmount,
    paymentStatus,
    paymentMethod,
    saleStatus,
    notes,
    createdAt,
    updatedAt,
    submittedAt,
    confirmedAt,
    completedAt,
    cancelledAt,
    externalId,
    externalDocumentNumber,
    externalStatus,
    dataSource,
    syncStatus,
    lastSyncedAt,
    version,
    companyId,
    deletedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SaleRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.saleNumber == this.saleNumber &&
          other.saleDate == this.saleDate &&
          other.settlementType == this.settlementType &&
          other.voucherBookId == this.voucherBookId &&
          other.customerId == this.customerId &&
          other.customerCode == this.customerCode &&
          other.customerName == this.customerName &&
          other.customerAccountId == this.customerAccountId &&
          other.cashAccountId == this.cashAccountId &&
          other.currencyCode == this.currencyCode &&
          other.baseCurrencyCode == this.baseCurrencyCode &&
          other.exchangeRate == this.exchangeRate &&
          other.subtotal == this.subtotal &&
          other.itemDiscountTotal == this.itemDiscountTotal &&
          other.discountType == this.discountType &&
          other.discountValue == this.discountValue &&
          other.discountAmount == this.discountAmount &&
          other.taxRate == this.taxRate &&
          other.taxAmount == this.taxAmount &&
          other.total == this.total &&
          other.paidAmount == this.paidAmount &&
          other.remainingAmount == this.remainingAmount &&
          other.paymentStatus == this.paymentStatus &&
          other.paymentMethod == this.paymentMethod &&
          other.saleStatus == this.saleStatus &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.submittedAt == this.submittedAt &&
          other.confirmedAt == this.confirmedAt &&
          other.completedAt == this.completedAt &&
          other.cancelledAt == this.cancelledAt &&
          other.externalId == this.externalId &&
          other.externalDocumentNumber == this.externalDocumentNumber &&
          other.externalStatus == this.externalStatus &&
          other.dataSource == this.dataSource &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.version == this.version &&
          other.companyId == this.companyId &&
          other.deletedAt == this.deletedAt);
}

class SalesCompanion extends UpdateCompanion<SaleRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> saleNumber;
  final Value<int> saleDate;
  final Value<String> settlementType;
  final Value<String?> voucherBookId;
  final Value<String?> customerId;
  final Value<String?> customerCode;
  final Value<String?> customerName;
  final Value<String?> customerAccountId;
  final Value<String?> cashAccountId;
  final Value<String> currencyCode;
  final Value<String> baseCurrencyCode;
  final Value<double> exchangeRate;
  final Value<double> subtotal;
  final Value<double> itemDiscountTotal;
  final Value<String> discountType;
  final Value<double> discountValue;
  final Value<double> discountAmount;
  final Value<double> taxRate;
  final Value<double> taxAmount;
  final Value<double> total;
  final Value<double> paidAmount;
  final Value<double> remainingAmount;
  final Value<String> paymentStatus;
  final Value<String> paymentMethod;
  final Value<String> saleStatus;
  final Value<String?> notes;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> submittedAt;
  final Value<int?> confirmedAt;
  final Value<int?> completedAt;
  final Value<int?> cancelledAt;
  final Value<String?> externalId;
  final Value<String?> externalDocumentNumber;
  final Value<String?> externalStatus;
  final Value<String> dataSource;
  final Value<String> syncStatus;
  final Value<int?> lastSyncedAt;
  final Value<int> version;
  final Value<String?> companyId;
  final Value<int?> deletedAt;
  const SalesCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.saleNumber = const Value.absent(),
    this.saleDate = const Value.absent(),
    this.settlementType = const Value.absent(),
    this.voucherBookId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.customerCode = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerAccountId = const Value.absent(),
    this.cashAccountId = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.baseCurrencyCode = const Value.absent(),
    this.exchangeRate = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.itemDiscountTotal = const Value.absent(),
    this.discountType = const Value.absent(),
    this.discountValue = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.taxRate = const Value.absent(),
    this.taxAmount = const Value.absent(),
    this.total = const Value.absent(),
    this.paidAmount = const Value.absent(),
    this.remainingAmount = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.saleStatus = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.submittedAt = const Value.absent(),
    this.confirmedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.cancelledAt = const Value.absent(),
    this.externalId = const Value.absent(),
    this.externalDocumentNumber = const Value.absent(),
    this.externalStatus = const Value.absent(),
    this.dataSource = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.companyId = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  SalesCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String saleNumber,
    this.saleDate = const Value.absent(),
    this.settlementType = const Value.absent(),
    this.voucherBookId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.customerCode = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerAccountId = const Value.absent(),
    this.cashAccountId = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.baseCurrencyCode = const Value.absent(),
    this.exchangeRate = const Value.absent(),
    required double subtotal,
    required double itemDiscountTotal,
    this.discountType = const Value.absent(),
    this.discountValue = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.taxRate = const Value.absent(),
    this.taxAmount = const Value.absent(),
    required double total,
    this.paidAmount = const Value.absent(),
    this.remainingAmount = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.saleStatus = const Value.absent(),
    this.notes = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.submittedAt = const Value.absent(),
    this.confirmedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.cancelledAt = const Value.absent(),
    this.externalId = const Value.absent(),
    this.externalDocumentNumber = const Value.absent(),
    this.externalStatus = const Value.absent(),
    this.dataSource = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.companyId = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : uuid = Value(uuid),
       saleNumber = Value(saleNumber),
       subtotal = Value(subtotal),
       itemDiscountTotal = Value(itemDiscountTotal),
       total = Value(total),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SaleRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? saleNumber,
    Expression<int>? saleDate,
    Expression<String>? settlementType,
    Expression<String>? voucherBookId,
    Expression<String>? customerId,
    Expression<String>? customerCode,
    Expression<String>? customerName,
    Expression<String>? customerAccountId,
    Expression<String>? cashAccountId,
    Expression<String>? currencyCode,
    Expression<String>? baseCurrencyCode,
    Expression<double>? exchangeRate,
    Expression<double>? subtotal,
    Expression<double>? itemDiscountTotal,
    Expression<String>? discountType,
    Expression<double>? discountValue,
    Expression<double>? discountAmount,
    Expression<double>? taxRate,
    Expression<double>? taxAmount,
    Expression<double>? total,
    Expression<double>? paidAmount,
    Expression<double>? remainingAmount,
    Expression<String>? paymentStatus,
    Expression<String>? paymentMethod,
    Expression<String>? saleStatus,
    Expression<String>? notes,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? submittedAt,
    Expression<int>? confirmedAt,
    Expression<int>? completedAt,
    Expression<int>? cancelledAt,
    Expression<String>? externalId,
    Expression<String>? externalDocumentNumber,
    Expression<String>? externalStatus,
    Expression<String>? dataSource,
    Expression<String>? syncStatus,
    Expression<int>? lastSyncedAt,
    Expression<int>? version,
    Expression<String>? companyId,
    Expression<int>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (saleNumber != null) 'sale_number': saleNumber,
      if (saleDate != null) 'sale_date': saleDate,
      if (settlementType != null) 'settlement_type': settlementType,
      if (voucherBookId != null) 'voucher_book_id': voucherBookId,
      if (customerId != null) 'customer_id': customerId,
      if (customerCode != null) 'customer_code': customerCode,
      if (customerName != null) 'customer_name': customerName,
      if (customerAccountId != null) 'customer_account_id': customerAccountId,
      if (cashAccountId != null) 'cash_account_id': cashAccountId,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (baseCurrencyCode != null) 'base_currency_code': baseCurrencyCode,
      if (exchangeRate != null) 'exchange_rate': exchangeRate,
      if (subtotal != null) 'subtotal': subtotal,
      if (itemDiscountTotal != null) 'item_discount_total': itemDiscountTotal,
      if (discountType != null) 'discount_type': discountType,
      if (discountValue != null) 'discount_value': discountValue,
      if (discountAmount != null) 'discount_amount': discountAmount,
      if (taxRate != null) 'tax_rate': taxRate,
      if (taxAmount != null) 'tax_amount': taxAmount,
      if (total != null) 'total': total,
      if (paidAmount != null) 'paid_amount': paidAmount,
      if (remainingAmount != null) 'remaining_amount': remainingAmount,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (saleStatus != null) 'sale_status': saleStatus,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (submittedAt != null) 'submitted_at': submittedAt,
      if (confirmedAt != null) 'confirmed_at': confirmedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (cancelledAt != null) 'cancelled_at': cancelledAt,
      if (externalId != null) 'external_id': externalId,
      if (externalDocumentNumber != null)
        'external_document_number': externalDocumentNumber,
      if (externalStatus != null) 'external_status': externalStatus,
      if (dataSource != null) 'data_source': dataSource,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (version != null) 'version': version,
      if (companyId != null) 'company_id': companyId,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  SalesCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? saleNumber,
    Value<int>? saleDate,
    Value<String>? settlementType,
    Value<String?>? voucherBookId,
    Value<String?>? customerId,
    Value<String?>? customerCode,
    Value<String?>? customerName,
    Value<String?>? customerAccountId,
    Value<String?>? cashAccountId,
    Value<String>? currencyCode,
    Value<String>? baseCurrencyCode,
    Value<double>? exchangeRate,
    Value<double>? subtotal,
    Value<double>? itemDiscountTotal,
    Value<String>? discountType,
    Value<double>? discountValue,
    Value<double>? discountAmount,
    Value<double>? taxRate,
    Value<double>? taxAmount,
    Value<double>? total,
    Value<double>? paidAmount,
    Value<double>? remainingAmount,
    Value<String>? paymentStatus,
    Value<String>? paymentMethod,
    Value<String>? saleStatus,
    Value<String?>? notes,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? submittedAt,
    Value<int?>? confirmedAt,
    Value<int?>? completedAt,
    Value<int?>? cancelledAt,
    Value<String?>? externalId,
    Value<String?>? externalDocumentNumber,
    Value<String?>? externalStatus,
    Value<String>? dataSource,
    Value<String>? syncStatus,
    Value<int?>? lastSyncedAt,
    Value<int>? version,
    Value<String?>? companyId,
    Value<int?>? deletedAt,
  }) {
    return SalesCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      saleNumber: saleNumber ?? this.saleNumber,
      saleDate: saleDate ?? this.saleDate,
      settlementType: settlementType ?? this.settlementType,
      voucherBookId: voucherBookId ?? this.voucherBookId,
      customerId: customerId ?? this.customerId,
      customerCode: customerCode ?? this.customerCode,
      customerName: customerName ?? this.customerName,
      customerAccountId: customerAccountId ?? this.customerAccountId,
      cashAccountId: cashAccountId ?? this.cashAccountId,
      currencyCode: currencyCode ?? this.currencyCode,
      baseCurrencyCode: baseCurrencyCode ?? this.baseCurrencyCode,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      subtotal: subtotal ?? this.subtotal,
      itemDiscountTotal: itemDiscountTotal ?? this.itemDiscountTotal,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      discountAmount: discountAmount ?? this.discountAmount,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      saleStatus: saleStatus ?? this.saleStatus,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      externalId: externalId ?? this.externalId,
      externalDocumentNumber:
          externalDocumentNumber ?? this.externalDocumentNumber,
      externalStatus: externalStatus ?? this.externalStatus,
      dataSource: dataSource ?? this.dataSource,
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
    if (saleNumber.present) {
      map['sale_number'] = Variable<String>(saleNumber.value);
    }
    if (saleDate.present) {
      map['sale_date'] = Variable<int>(saleDate.value);
    }
    if (settlementType.present) {
      map['settlement_type'] = Variable<String>(settlementType.value);
    }
    if (voucherBookId.present) {
      map['voucher_book_id'] = Variable<String>(voucherBookId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (customerCode.present) {
      map['customer_code'] = Variable<String>(customerCode.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (customerAccountId.present) {
      map['customer_account_id'] = Variable<String>(customerAccountId.value);
    }
    if (cashAccountId.present) {
      map['cash_account_id'] = Variable<String>(cashAccountId.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (baseCurrencyCode.present) {
      map['base_currency_code'] = Variable<String>(baseCurrencyCode.value);
    }
    if (exchangeRate.present) {
      map['exchange_rate'] = Variable<double>(exchangeRate.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    if (itemDiscountTotal.present) {
      map['item_discount_total'] = Variable<double>(itemDiscountTotal.value);
    }
    if (discountType.present) {
      map['discount_type'] = Variable<String>(discountType.value);
    }
    if (discountValue.present) {
      map['discount_value'] = Variable<double>(discountValue.value);
    }
    if (discountAmount.present) {
      map['discount_amount'] = Variable<double>(discountAmount.value);
    }
    if (taxRate.present) {
      map['tax_rate'] = Variable<double>(taxRate.value);
    }
    if (taxAmount.present) {
      map['tax_amount'] = Variable<double>(taxAmount.value);
    }
    if (total.present) {
      map['total'] = Variable<double>(total.value);
    }
    if (paidAmount.present) {
      map['paid_amount'] = Variable<double>(paidAmount.value);
    }
    if (remainingAmount.present) {
      map['remaining_amount'] = Variable<double>(remainingAmount.value);
    }
    if (paymentStatus.present) {
      map['payment_status'] = Variable<String>(paymentStatus.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (saleStatus.present) {
      map['sale_status'] = Variable<String>(saleStatus.value);
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
    if (submittedAt.present) {
      map['submitted_at'] = Variable<int>(submittedAt.value);
    }
    if (confirmedAt.present) {
      map['confirmed_at'] = Variable<int>(confirmedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (cancelledAt.present) {
      map['cancelled_at'] = Variable<int>(cancelledAt.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (externalDocumentNumber.present) {
      map['external_document_number'] = Variable<String>(
        externalDocumentNumber.value,
      );
    }
    if (externalStatus.present) {
      map['external_status'] = Variable<String>(externalStatus.value);
    }
    if (dataSource.present) {
      map['data_source'] = Variable<String>(dataSource.value);
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
    return (StringBuffer('SalesCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('saleNumber: $saleNumber, ')
          ..write('saleDate: $saleDate, ')
          ..write('settlementType: $settlementType, ')
          ..write('voucherBookId: $voucherBookId, ')
          ..write('customerId: $customerId, ')
          ..write('customerCode: $customerCode, ')
          ..write('customerName: $customerName, ')
          ..write('customerAccountId: $customerAccountId, ')
          ..write('cashAccountId: $cashAccountId, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('baseCurrencyCode: $baseCurrencyCode, ')
          ..write('exchangeRate: $exchangeRate, ')
          ..write('subtotal: $subtotal, ')
          ..write('itemDiscountTotal: $itemDiscountTotal, ')
          ..write('discountType: $discountType, ')
          ..write('discountValue: $discountValue, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('taxRate: $taxRate, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('total: $total, ')
          ..write('paidAmount: $paidAmount, ')
          ..write('remainingAmount: $remainingAmount, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('saleStatus: $saleStatus, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('submittedAt: $submittedAt, ')
          ..write('confirmedAt: $confirmedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('cancelledAt: $cancelledAt, ')
          ..write('externalId: $externalId, ')
          ..write('externalDocumentNumber: $externalDocumentNumber, ')
          ..write('externalStatus: $externalStatus, ')
          ..write('dataSource: $dataSource, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('version: $version, ')
          ..write('companyId: $companyId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $SaleItemsTable extends SaleItems
    with TableInfo<$SaleItemsTable, SaleItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SaleItemsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _saleUuidMeta = const VerificationMeta(
    'saleUuid',
  );
  @override
  late final GeneratedColumn<String> saleUuid = GeneratedColumn<String>(
    'sale_uuid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 512,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productCodeMeta = const VerificationMeta(
    'productCode',
  );
  @override
  late final GeneratedColumn<String> productCode = GeneratedColumn<String>(
    'product_code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 128,
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
  static const VerificationMeta _packSizeMeta = const VerificationMeta(
    'packSize',
  );
  @override
  late final GeneratedColumn<int> packSize = GeneratedColumn<int>(
    'pack_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseUnitPriceMeta = const VerificationMeta(
    'baseUnitPrice',
  );
  @override
  late final GeneratedColumn<double> baseUnitPrice = GeneratedColumn<double>(
    'base_unit_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _discountTypeMeta = const VerificationMeta(
    'discountType',
  );
  @override
  late final GeneratedColumn<String> discountType = GeneratedColumn<String>(
    'discount_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('fixed'),
  );
  static const VerificationMeta _discountValueMeta = const VerificationMeta(
    'discountValue',
  );
  @override
  late final GeneratedColumn<double> discountValue = GeneratedColumn<double>(
    'discount_value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _discountAmountMeta = const VerificationMeta(
    'discountAmount',
  );
  @override
  late final GeneratedColumn<double> discountAmount = GeneratedColumn<double>(
    'discount_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _taxAmountMeta = const VerificationMeta(
    'taxAmount',
  );
  @override
  late final GeneratedColumn<double> taxAmount = GeneratedColumn<double>(
    'tax_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<double> total = GeneratedColumn<double>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineOrderMeta = const VerificationMeta(
    'lineOrder',
  );
  @override
  late final GeneratedColumn<int> lineOrder = GeneratedColumn<int>(
    'line_order',
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
    saleUuid,
    productId,
    productName,
    productCode,
    barcode,
    quantity,
    mainQuantity,
    subQuantity,
    packSize,
    unitPrice,
    baseUnitPrice,
    discountType,
    discountValue,
    discountAmount,
    taxAmount,
    subtotal,
    total,
    lineOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sale_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SaleItemRow> instance, {
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
    if (data.containsKey('sale_uuid')) {
      context.handle(
        _saleUuidMeta,
        saleUuid.isAcceptableOrUnknown(data['sale_uuid']!, _saleUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_saleUuidMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('product_code')) {
      context.handle(
        _productCodeMeta,
        productCode.isAcceptableOrUnknown(
          data['product_code']!,
          _productCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productCodeMeta);
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
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
    if (data.containsKey('pack_size')) {
      context.handle(
        _packSizeMeta,
        packSize.isAcceptableOrUnknown(data['pack_size']!, _packSizeMeta),
      );
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    if (data.containsKey('base_unit_price')) {
      context.handle(
        _baseUnitPriceMeta,
        baseUnitPrice.isAcceptableOrUnknown(
          data['base_unit_price']!,
          _baseUnitPriceMeta,
        ),
      );
    }
    if (data.containsKey('discount_type')) {
      context.handle(
        _discountTypeMeta,
        discountType.isAcceptableOrUnknown(
          data['discount_type']!,
          _discountTypeMeta,
        ),
      );
    }
    if (data.containsKey('discount_value')) {
      context.handle(
        _discountValueMeta,
        discountValue.isAcceptableOrUnknown(
          data['discount_value']!,
          _discountValueMeta,
        ),
      );
    }
    if (data.containsKey('discount_amount')) {
      context.handle(
        _discountAmountMeta,
        discountAmount.isAcceptableOrUnknown(
          data['discount_amount']!,
          _discountAmountMeta,
        ),
      );
    }
    if (data.containsKey('tax_amount')) {
      context.handle(
        _taxAmountMeta,
        taxAmount.isAcceptableOrUnknown(data['tax_amount']!, _taxAmountMeta),
      );
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    } else if (isInserting) {
      context.missing(_subtotalMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('line_order')) {
      context.handle(
        _lineOrderMeta,
        lineOrder.isAcceptableOrUnknown(data['line_order']!, _lineOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SaleItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SaleItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      saleUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_uuid'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      productCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_code'],
      )!,
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      mainQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}main_quantity'],
      )!,
      subQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sub_quantity'],
      )!,
      packSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pack_size'],
      )!,
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_price'],
      )!,
      baseUnitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}base_unit_price'],
      )!,
      discountType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discount_type'],
      )!,
      discountValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}discount_value'],
      )!,
      discountAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}discount_amount'],
      )!,
      taxAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tax_amount'],
      )!,
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}subtotal'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total'],
      )!,
      lineOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line_order'],
      )!,
    );
  }

  @override
  $SaleItemsTable createAlias(String alias) {
    return $SaleItemsTable(attachedDatabase, alias);
  }
}

class SaleItemRow extends DataClass implements Insertable<SaleItemRow> {
  final int id;
  final String uuid;
  final String saleUuid;

  /// Product.uuid — opaque FK.
  final String productId;
  final String productName;
  final String productCode;
  final String? barcode;

  /// Effective billing quantity (main + sub / packSize).
  final double quantity;
  final double mainQuantity;
  final double subQuantity;
  final int packSize;

  /// Unit price in the sale currency.
  final double unitPrice;

  /// Catalog unit price in company base currency.
  final double baseUnitPrice;
  final String discountType;
  final double discountValue;
  final double discountAmount;
  final double taxAmount;
  final double subtotal;
  final double total;
  final int lineOrder;
  const SaleItemRow({
    required this.id,
    required this.uuid,
    required this.saleUuid,
    required this.productId,
    required this.productName,
    required this.productCode,
    this.barcode,
    required this.quantity,
    required this.mainQuantity,
    required this.subQuantity,
    required this.packSize,
    required this.unitPrice,
    required this.baseUnitPrice,
    required this.discountType,
    required this.discountValue,
    required this.discountAmount,
    required this.taxAmount,
    required this.subtotal,
    required this.total,
    required this.lineOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['sale_uuid'] = Variable<String>(saleUuid);
    map['product_id'] = Variable<String>(productId);
    map['product_name'] = Variable<String>(productName);
    map['product_code'] = Variable<String>(productCode);
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['quantity'] = Variable<double>(quantity);
    map['main_quantity'] = Variable<double>(mainQuantity);
    map['sub_quantity'] = Variable<double>(subQuantity);
    map['pack_size'] = Variable<int>(packSize);
    map['unit_price'] = Variable<double>(unitPrice);
    map['base_unit_price'] = Variable<double>(baseUnitPrice);
    map['discount_type'] = Variable<String>(discountType);
    map['discount_value'] = Variable<double>(discountValue);
    map['discount_amount'] = Variable<double>(discountAmount);
    map['tax_amount'] = Variable<double>(taxAmount);
    map['subtotal'] = Variable<double>(subtotal);
    map['total'] = Variable<double>(total);
    map['line_order'] = Variable<int>(lineOrder);
    return map;
  }

  SaleItemsCompanion toCompanion(bool nullToAbsent) {
    return SaleItemsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      saleUuid: Value(saleUuid),
      productId: Value(productId),
      productName: Value(productName),
      productCode: Value(productCode),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      quantity: Value(quantity),
      mainQuantity: Value(mainQuantity),
      subQuantity: Value(subQuantity),
      packSize: Value(packSize),
      unitPrice: Value(unitPrice),
      baseUnitPrice: Value(baseUnitPrice),
      discountType: Value(discountType),
      discountValue: Value(discountValue),
      discountAmount: Value(discountAmount),
      taxAmount: Value(taxAmount),
      subtotal: Value(subtotal),
      total: Value(total),
      lineOrder: Value(lineOrder),
    );
  }

  factory SaleItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SaleItemRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      saleUuid: serializer.fromJson<String>(json['saleUuid']),
      productId: serializer.fromJson<String>(json['productId']),
      productName: serializer.fromJson<String>(json['productName']),
      productCode: serializer.fromJson<String>(json['productCode']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      quantity: serializer.fromJson<double>(json['quantity']),
      mainQuantity: serializer.fromJson<double>(json['mainQuantity']),
      subQuantity: serializer.fromJson<double>(json['subQuantity']),
      packSize: serializer.fromJson<int>(json['packSize']),
      unitPrice: serializer.fromJson<double>(json['unitPrice']),
      baseUnitPrice: serializer.fromJson<double>(json['baseUnitPrice']),
      discountType: serializer.fromJson<String>(json['discountType']),
      discountValue: serializer.fromJson<double>(json['discountValue']),
      discountAmount: serializer.fromJson<double>(json['discountAmount']),
      taxAmount: serializer.fromJson<double>(json['taxAmount']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
      total: serializer.fromJson<double>(json['total']),
      lineOrder: serializer.fromJson<int>(json['lineOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'saleUuid': serializer.toJson<String>(saleUuid),
      'productId': serializer.toJson<String>(productId),
      'productName': serializer.toJson<String>(productName),
      'productCode': serializer.toJson<String>(productCode),
      'barcode': serializer.toJson<String?>(barcode),
      'quantity': serializer.toJson<double>(quantity),
      'mainQuantity': serializer.toJson<double>(mainQuantity),
      'subQuantity': serializer.toJson<double>(subQuantity),
      'packSize': serializer.toJson<int>(packSize),
      'unitPrice': serializer.toJson<double>(unitPrice),
      'baseUnitPrice': serializer.toJson<double>(baseUnitPrice),
      'discountType': serializer.toJson<String>(discountType),
      'discountValue': serializer.toJson<double>(discountValue),
      'discountAmount': serializer.toJson<double>(discountAmount),
      'taxAmount': serializer.toJson<double>(taxAmount),
      'subtotal': serializer.toJson<double>(subtotal),
      'total': serializer.toJson<double>(total),
      'lineOrder': serializer.toJson<int>(lineOrder),
    };
  }

  SaleItemRow copyWith({
    int? id,
    String? uuid,
    String? saleUuid,
    String? productId,
    String? productName,
    String? productCode,
    Value<String?> barcode = const Value.absent(),
    double? quantity,
    double? mainQuantity,
    double? subQuantity,
    int? packSize,
    double? unitPrice,
    double? baseUnitPrice,
    String? discountType,
    double? discountValue,
    double? discountAmount,
    double? taxAmount,
    double? subtotal,
    double? total,
    int? lineOrder,
  }) => SaleItemRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    saleUuid: saleUuid ?? this.saleUuid,
    productId: productId ?? this.productId,
    productName: productName ?? this.productName,
    productCode: productCode ?? this.productCode,
    barcode: barcode.present ? barcode.value : this.barcode,
    quantity: quantity ?? this.quantity,
    mainQuantity: mainQuantity ?? this.mainQuantity,
    subQuantity: subQuantity ?? this.subQuantity,
    packSize: packSize ?? this.packSize,
    unitPrice: unitPrice ?? this.unitPrice,
    baseUnitPrice: baseUnitPrice ?? this.baseUnitPrice,
    discountType: discountType ?? this.discountType,
    discountValue: discountValue ?? this.discountValue,
    discountAmount: discountAmount ?? this.discountAmount,
    taxAmount: taxAmount ?? this.taxAmount,
    subtotal: subtotal ?? this.subtotal,
    total: total ?? this.total,
    lineOrder: lineOrder ?? this.lineOrder,
  );
  SaleItemRow copyWithCompanion(SaleItemsCompanion data) {
    return SaleItemRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      saleUuid: data.saleUuid.present ? data.saleUuid.value : this.saleUuid,
      productId: data.productId.present ? data.productId.value : this.productId,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      productCode: data.productCode.present
          ? data.productCode.value
          : this.productCode,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      mainQuantity: data.mainQuantity.present
          ? data.mainQuantity.value
          : this.mainQuantity,
      subQuantity: data.subQuantity.present
          ? data.subQuantity.value
          : this.subQuantity,
      packSize: data.packSize.present ? data.packSize.value : this.packSize,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      baseUnitPrice: data.baseUnitPrice.present
          ? data.baseUnitPrice.value
          : this.baseUnitPrice,
      discountType: data.discountType.present
          ? data.discountType.value
          : this.discountType,
      discountValue: data.discountValue.present
          ? data.discountValue.value
          : this.discountValue,
      discountAmount: data.discountAmount.present
          ? data.discountAmount.value
          : this.discountAmount,
      taxAmount: data.taxAmount.present ? data.taxAmount.value : this.taxAmount,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      total: data.total.present ? data.total.value : this.total,
      lineOrder: data.lineOrder.present ? data.lineOrder.value : this.lineOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SaleItemRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('saleUuid: $saleUuid, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('productCode: $productCode, ')
          ..write('barcode: $barcode, ')
          ..write('quantity: $quantity, ')
          ..write('mainQuantity: $mainQuantity, ')
          ..write('subQuantity: $subQuantity, ')
          ..write('packSize: $packSize, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('baseUnitPrice: $baseUnitPrice, ')
          ..write('discountType: $discountType, ')
          ..write('discountValue: $discountValue, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('subtotal: $subtotal, ')
          ..write('total: $total, ')
          ..write('lineOrder: $lineOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    saleUuid,
    productId,
    productName,
    productCode,
    barcode,
    quantity,
    mainQuantity,
    subQuantity,
    packSize,
    unitPrice,
    baseUnitPrice,
    discountType,
    discountValue,
    discountAmount,
    taxAmount,
    subtotal,
    total,
    lineOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SaleItemRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.saleUuid == this.saleUuid &&
          other.productId == this.productId &&
          other.productName == this.productName &&
          other.productCode == this.productCode &&
          other.barcode == this.barcode &&
          other.quantity == this.quantity &&
          other.mainQuantity == this.mainQuantity &&
          other.subQuantity == this.subQuantity &&
          other.packSize == this.packSize &&
          other.unitPrice == this.unitPrice &&
          other.baseUnitPrice == this.baseUnitPrice &&
          other.discountType == this.discountType &&
          other.discountValue == this.discountValue &&
          other.discountAmount == this.discountAmount &&
          other.taxAmount == this.taxAmount &&
          other.subtotal == this.subtotal &&
          other.total == this.total &&
          other.lineOrder == this.lineOrder);
}

class SaleItemsCompanion extends UpdateCompanion<SaleItemRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> saleUuid;
  final Value<String> productId;
  final Value<String> productName;
  final Value<String> productCode;
  final Value<String?> barcode;
  final Value<double> quantity;
  final Value<double> mainQuantity;
  final Value<double> subQuantity;
  final Value<int> packSize;
  final Value<double> unitPrice;
  final Value<double> baseUnitPrice;
  final Value<String> discountType;
  final Value<double> discountValue;
  final Value<double> discountAmount;
  final Value<double> taxAmount;
  final Value<double> subtotal;
  final Value<double> total;
  final Value<int> lineOrder;
  const SaleItemsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.saleUuid = const Value.absent(),
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.productCode = const Value.absent(),
    this.barcode = const Value.absent(),
    this.quantity = const Value.absent(),
    this.mainQuantity = const Value.absent(),
    this.subQuantity = const Value.absent(),
    this.packSize = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.baseUnitPrice = const Value.absent(),
    this.discountType = const Value.absent(),
    this.discountValue = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.taxAmount = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.total = const Value.absent(),
    this.lineOrder = const Value.absent(),
  });
  SaleItemsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String saleUuid,
    required String productId,
    required String productName,
    required String productCode,
    this.barcode = const Value.absent(),
    required double quantity,
    this.mainQuantity = const Value.absent(),
    this.subQuantity = const Value.absent(),
    this.packSize = const Value.absent(),
    required double unitPrice,
    this.baseUnitPrice = const Value.absent(),
    this.discountType = const Value.absent(),
    this.discountValue = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.taxAmount = const Value.absent(),
    required double subtotal,
    required double total,
    this.lineOrder = const Value.absent(),
  }) : uuid = Value(uuid),
       saleUuid = Value(saleUuid),
       productId = Value(productId),
       productName = Value(productName),
       productCode = Value(productCode),
       quantity = Value(quantity),
       unitPrice = Value(unitPrice),
       subtotal = Value(subtotal),
       total = Value(total);
  static Insertable<SaleItemRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? saleUuid,
    Expression<String>? productId,
    Expression<String>? productName,
    Expression<String>? productCode,
    Expression<String>? barcode,
    Expression<double>? quantity,
    Expression<double>? mainQuantity,
    Expression<double>? subQuantity,
    Expression<int>? packSize,
    Expression<double>? unitPrice,
    Expression<double>? baseUnitPrice,
    Expression<String>? discountType,
    Expression<double>? discountValue,
    Expression<double>? discountAmount,
    Expression<double>? taxAmount,
    Expression<double>? subtotal,
    Expression<double>? total,
    Expression<int>? lineOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (saleUuid != null) 'sale_uuid': saleUuid,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (productCode != null) 'product_code': productCode,
      if (barcode != null) 'barcode': barcode,
      if (quantity != null) 'quantity': quantity,
      if (mainQuantity != null) 'main_quantity': mainQuantity,
      if (subQuantity != null) 'sub_quantity': subQuantity,
      if (packSize != null) 'pack_size': packSize,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (baseUnitPrice != null) 'base_unit_price': baseUnitPrice,
      if (discountType != null) 'discount_type': discountType,
      if (discountValue != null) 'discount_value': discountValue,
      if (discountAmount != null) 'discount_amount': discountAmount,
      if (taxAmount != null) 'tax_amount': taxAmount,
      if (subtotal != null) 'subtotal': subtotal,
      if (total != null) 'total': total,
      if (lineOrder != null) 'line_order': lineOrder,
    });
  }

  SaleItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? saleUuid,
    Value<String>? productId,
    Value<String>? productName,
    Value<String>? productCode,
    Value<String?>? barcode,
    Value<double>? quantity,
    Value<double>? mainQuantity,
    Value<double>? subQuantity,
    Value<int>? packSize,
    Value<double>? unitPrice,
    Value<double>? baseUnitPrice,
    Value<String>? discountType,
    Value<double>? discountValue,
    Value<double>? discountAmount,
    Value<double>? taxAmount,
    Value<double>? subtotal,
    Value<double>? total,
    Value<int>? lineOrder,
  }) {
    return SaleItemsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      saleUuid: saleUuid ?? this.saleUuid,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      barcode: barcode ?? this.barcode,
      quantity: quantity ?? this.quantity,
      mainQuantity: mainQuantity ?? this.mainQuantity,
      subQuantity: subQuantity ?? this.subQuantity,
      packSize: packSize ?? this.packSize,
      unitPrice: unitPrice ?? this.unitPrice,
      baseUnitPrice: baseUnitPrice ?? this.baseUnitPrice,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      subtotal: subtotal ?? this.subtotal,
      total: total ?? this.total,
      lineOrder: lineOrder ?? this.lineOrder,
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
    if (saleUuid.present) {
      map['sale_uuid'] = Variable<String>(saleUuid.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (productCode.present) {
      map['product_code'] = Variable<String>(productCode.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (mainQuantity.present) {
      map['main_quantity'] = Variable<double>(mainQuantity.value);
    }
    if (subQuantity.present) {
      map['sub_quantity'] = Variable<double>(subQuantity.value);
    }
    if (packSize.present) {
      map['pack_size'] = Variable<int>(packSize.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    if (baseUnitPrice.present) {
      map['base_unit_price'] = Variable<double>(baseUnitPrice.value);
    }
    if (discountType.present) {
      map['discount_type'] = Variable<String>(discountType.value);
    }
    if (discountValue.present) {
      map['discount_value'] = Variable<double>(discountValue.value);
    }
    if (discountAmount.present) {
      map['discount_amount'] = Variable<double>(discountAmount.value);
    }
    if (taxAmount.present) {
      map['tax_amount'] = Variable<double>(taxAmount.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    if (total.present) {
      map['total'] = Variable<double>(total.value);
    }
    if (lineOrder.present) {
      map['line_order'] = Variable<int>(lineOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SaleItemsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('saleUuid: $saleUuid, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('productCode: $productCode, ')
          ..write('barcode: $barcode, ')
          ..write('quantity: $quantity, ')
          ..write('mainQuantity: $mainQuantity, ')
          ..write('subQuantity: $subQuantity, ')
          ..write('packSize: $packSize, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('baseUnitPrice: $baseUnitPrice, ')
          ..write('discountType: $discountType, ')
          ..write('discountValue: $discountValue, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('subtotal: $subtotal, ')
          ..write('total: $total, ')
          ..write('lineOrder: $lineOrder')
          ..write(')'))
        .toString();
  }
}

class $SalePaymentsTable extends SalePayments
    with TableInfo<$SalePaymentsTable, SalePaymentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SalePaymentsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _saleUuidMeta = const VerificationMeta(
    'saleUuid',
  );
  @override
  late final GeneratedColumn<String> saleUuid = GeneratedColumn<String>(
    'sale_uuid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('cash'),
  );
  static const VerificationMeta _paidAtMeta = const VerificationMeta('paidAt');
  @override
  late final GeneratedColumn<int> paidAt = GeneratedColumn<int>(
    'paid_at',
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
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    saleUuid,
    amount,
    method,
    paidAt,
    createdAt,
    notes,
    externalId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sale_payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<SalePaymentRow> instance, {
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
    if (data.containsKey('sale_uuid')) {
      context.handle(
        _saleUuidMeta,
        saleUuid.isAcceptableOrUnknown(data['sale_uuid']!, _saleUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_saleUuidMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    }
    if (data.containsKey('paid_at')) {
      context.handle(
        _paidAtMeta,
        paidAt.isAcceptableOrUnknown(data['paid_at']!, _paidAtMeta),
      );
    } else if (isInserting) {
      context.missing(_paidAtMeta);
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
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SalePaymentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SalePaymentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      saleUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_uuid'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
      paidAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paid_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      ),
    );
  }

  @override
  $SalePaymentsTable createAlias(String alias) {
    return $SalePaymentsTable(attachedDatabase, alias);
  }
}

class SalePaymentRow extends DataClass implements Insertable<SalePaymentRow> {
  final int id;
  final String uuid;
  final String saleUuid;
  final double amount;
  final String method;
  final int paidAt;
  final int createdAt;
  final String? notes;
  final String? externalId;
  const SalePaymentRow({
    required this.id,
    required this.uuid,
    required this.saleUuid,
    required this.amount,
    required this.method,
    required this.paidAt,
    required this.createdAt,
    this.notes,
    this.externalId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['sale_uuid'] = Variable<String>(saleUuid);
    map['amount'] = Variable<double>(amount);
    map['method'] = Variable<String>(method);
    map['paid_at'] = Variable<int>(paidAt);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    return map;
  }

  SalePaymentsCompanion toCompanion(bool nullToAbsent) {
    return SalePaymentsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      saleUuid: Value(saleUuid),
      amount: Value(amount),
      method: Value(method),
      paidAt: Value(paidAt),
      createdAt: Value(createdAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
    );
  }

  factory SalePaymentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SalePaymentRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      saleUuid: serializer.fromJson<String>(json['saleUuid']),
      amount: serializer.fromJson<double>(json['amount']),
      method: serializer.fromJson<String>(json['method']),
      paidAt: serializer.fromJson<int>(json['paidAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      notes: serializer.fromJson<String?>(json['notes']),
      externalId: serializer.fromJson<String?>(json['externalId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'saleUuid': serializer.toJson<String>(saleUuid),
      'amount': serializer.toJson<double>(amount),
      'method': serializer.toJson<String>(method),
      'paidAt': serializer.toJson<int>(paidAt),
      'createdAt': serializer.toJson<int>(createdAt),
      'notes': serializer.toJson<String?>(notes),
      'externalId': serializer.toJson<String?>(externalId),
    };
  }

  SalePaymentRow copyWith({
    int? id,
    String? uuid,
    String? saleUuid,
    double? amount,
    String? method,
    int? paidAt,
    int? createdAt,
    Value<String?> notes = const Value.absent(),
    Value<String?> externalId = const Value.absent(),
  }) => SalePaymentRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    saleUuid: saleUuid ?? this.saleUuid,
    amount: amount ?? this.amount,
    method: method ?? this.method,
    paidAt: paidAt ?? this.paidAt,
    createdAt: createdAt ?? this.createdAt,
    notes: notes.present ? notes.value : this.notes,
    externalId: externalId.present ? externalId.value : this.externalId,
  );
  SalePaymentRow copyWithCompanion(SalePaymentsCompanion data) {
    return SalePaymentRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      saleUuid: data.saleUuid.present ? data.saleUuid.value : this.saleUuid,
      amount: data.amount.present ? data.amount.value : this.amount,
      method: data.method.present ? data.method.value : this.method,
      paidAt: data.paidAt.present ? data.paidAt.value : this.paidAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SalePaymentRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('saleUuid: $saleUuid, ')
          ..write('amount: $amount, ')
          ..write('method: $method, ')
          ..write('paidAt: $paidAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('notes: $notes, ')
          ..write('externalId: $externalId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    saleUuid,
    amount,
    method,
    paidAt,
    createdAt,
    notes,
    externalId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SalePaymentRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.saleUuid == this.saleUuid &&
          other.amount == this.amount &&
          other.method == this.method &&
          other.paidAt == this.paidAt &&
          other.createdAt == this.createdAt &&
          other.notes == this.notes &&
          other.externalId == this.externalId);
}

class SalePaymentsCompanion extends UpdateCompanion<SalePaymentRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> saleUuid;
  final Value<double> amount;
  final Value<String> method;
  final Value<int> paidAt;
  final Value<int> createdAt;
  final Value<String?> notes;
  final Value<String?> externalId;
  const SalePaymentsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.saleUuid = const Value.absent(),
    this.amount = const Value.absent(),
    this.method = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.externalId = const Value.absent(),
  });
  SalePaymentsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String saleUuid,
    required double amount,
    this.method = const Value.absent(),
    required int paidAt,
    required int createdAt,
    this.notes = const Value.absent(),
    this.externalId = const Value.absent(),
  }) : uuid = Value(uuid),
       saleUuid = Value(saleUuid),
       amount = Value(amount),
       paidAt = Value(paidAt),
       createdAt = Value(createdAt);
  static Insertable<SalePaymentRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? saleUuid,
    Expression<double>? amount,
    Expression<String>? method,
    Expression<int>? paidAt,
    Expression<int>? createdAt,
    Expression<String>? notes,
    Expression<String>? externalId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (saleUuid != null) 'sale_uuid': saleUuid,
      if (amount != null) 'amount': amount,
      if (method != null) 'method': method,
      if (paidAt != null) 'paid_at': paidAt,
      if (createdAt != null) 'created_at': createdAt,
      if (notes != null) 'notes': notes,
      if (externalId != null) 'external_id': externalId,
    });
  }

  SalePaymentsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? saleUuid,
    Value<double>? amount,
    Value<String>? method,
    Value<int>? paidAt,
    Value<int>? createdAt,
    Value<String?>? notes,
    Value<String?>? externalId,
  }) {
    return SalePaymentsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      saleUuid: saleUuid ?? this.saleUuid,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      externalId: externalId ?? this.externalId,
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
    if (saleUuid.present) {
      map['sale_uuid'] = Variable<String>(saleUuid.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (paidAt.present) {
      map['paid_at'] = Variable<int>(paidAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SalePaymentsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('saleUuid: $saleUuid, ')
          ..write('amount: $amount, ')
          ..write('method: $method, ')
          ..write('paidAt: $paidAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('notes: $notes, ')
          ..write('externalId: $externalId')
          ..write(')'))
        .toString();
  }
}

abstract class _$SalesDatabase extends GeneratedDatabase {
  _$SalesDatabase(QueryExecutor e) : super(e);
  $SalesDatabaseManager get managers => $SalesDatabaseManager(this);
  late final $SalesTable sales = $SalesTable(this);
  late final $SaleItemsTable saleItems = $SaleItemsTable(this);
  late final $SalePaymentsTable salePayments = $SalePaymentsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sales,
    saleItems,
    salePayments,
  ];
}

typedef $$SalesTableCreateCompanionBuilder =
    SalesCompanion Function({
      Value<int> id,
      required String uuid,
      required String saleNumber,
      Value<int> saleDate,
      Value<String> settlementType,
      Value<String?> voucherBookId,
      Value<String?> customerId,
      Value<String?> customerCode,
      Value<String?> customerName,
      Value<String?> customerAccountId,
      Value<String?> cashAccountId,
      Value<String> currencyCode,
      Value<String> baseCurrencyCode,
      Value<double> exchangeRate,
      required double subtotal,
      required double itemDiscountTotal,
      Value<String> discountType,
      Value<double> discountValue,
      Value<double> discountAmount,
      Value<double> taxRate,
      Value<double> taxAmount,
      required double total,
      Value<double> paidAmount,
      Value<double> remainingAmount,
      Value<String> paymentStatus,
      Value<String> paymentMethod,
      Value<String> saleStatus,
      Value<String?> notes,
      required int createdAt,
      required int updatedAt,
      Value<int?> submittedAt,
      Value<int?> confirmedAt,
      Value<int?> completedAt,
      Value<int?> cancelledAt,
      Value<String?> externalId,
      Value<String?> externalDocumentNumber,
      Value<String?> externalStatus,
      Value<String> dataSource,
      Value<String> syncStatus,
      Value<int?> lastSyncedAt,
      Value<int> version,
      Value<String?> companyId,
      Value<int?> deletedAt,
    });
typedef $$SalesTableUpdateCompanionBuilder =
    SalesCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String> saleNumber,
      Value<int> saleDate,
      Value<String> settlementType,
      Value<String?> voucherBookId,
      Value<String?> customerId,
      Value<String?> customerCode,
      Value<String?> customerName,
      Value<String?> customerAccountId,
      Value<String?> cashAccountId,
      Value<String> currencyCode,
      Value<String> baseCurrencyCode,
      Value<double> exchangeRate,
      Value<double> subtotal,
      Value<double> itemDiscountTotal,
      Value<String> discountType,
      Value<double> discountValue,
      Value<double> discountAmount,
      Value<double> taxRate,
      Value<double> taxAmount,
      Value<double> total,
      Value<double> paidAmount,
      Value<double> remainingAmount,
      Value<String> paymentStatus,
      Value<String> paymentMethod,
      Value<String> saleStatus,
      Value<String?> notes,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> submittedAt,
      Value<int?> confirmedAt,
      Value<int?> completedAt,
      Value<int?> cancelledAt,
      Value<String?> externalId,
      Value<String?> externalDocumentNumber,
      Value<String?> externalStatus,
      Value<String> dataSource,
      Value<String> syncStatus,
      Value<int?> lastSyncedAt,
      Value<int> version,
      Value<String?> companyId,
      Value<int?> deletedAt,
    });

class $$SalesTableFilterComposer
    extends Composer<_$SalesDatabase, $SalesTable> {
  $$SalesTableFilterComposer({
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

  ColumnFilters<String> get saleNumber => $composableBuilder(
    column: $table.saleNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get saleDate => $composableBuilder(
    column: $table.saleDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settlementType => $composableBuilder(
    column: $table.settlementType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voucherBookId => $composableBuilder(
    column: $table.voucherBookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerCode => $composableBuilder(
    column: $table.customerCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerAccountId => $composableBuilder(
    column: $table.customerAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cashAccountId => $composableBuilder(
    column: $table.cashAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseCurrencyCode => $composableBuilder(
    column: $table.baseCurrencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get itemDiscountTotal => $composableBuilder(
    column: $table.itemDiscountTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get discountType => $composableBuilder(
    column: $table.discountType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get taxRate => $composableBuilder(
    column: $table.taxRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get taxAmount => $composableBuilder(
    column: $table.taxAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get paidAmount => $composableBuilder(
    column: $table.paidAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get remainingAmount => $composableBuilder(
    column: $table.remainingAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get saleStatus => $composableBuilder(
    column: $table.saleStatus,
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

  ColumnFilters<int> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cancelledAt => $composableBuilder(
    column: $table.cancelledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalDocumentNumber => $composableBuilder(
    column: $table.externalDocumentNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalStatus => $composableBuilder(
    column: $table.externalStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataSource => $composableBuilder(
    column: $table.dataSource,
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

class $$SalesTableOrderingComposer
    extends Composer<_$SalesDatabase, $SalesTable> {
  $$SalesTableOrderingComposer({
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

  ColumnOrderings<String> get saleNumber => $composableBuilder(
    column: $table.saleNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get saleDate => $composableBuilder(
    column: $table.saleDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settlementType => $composableBuilder(
    column: $table.settlementType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voucherBookId => $composableBuilder(
    column: $table.voucherBookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerCode => $composableBuilder(
    column: $table.customerCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerAccountId => $composableBuilder(
    column: $table.customerAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cashAccountId => $composableBuilder(
    column: $table.cashAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseCurrencyCode => $composableBuilder(
    column: $table.baseCurrencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get itemDiscountTotal => $composableBuilder(
    column: $table.itemDiscountTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discountType => $composableBuilder(
    column: $table.discountType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get taxRate => $composableBuilder(
    column: $table.taxRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get taxAmount => $composableBuilder(
    column: $table.taxAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get paidAmount => $composableBuilder(
    column: $table.paidAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get remainingAmount => $composableBuilder(
    column: $table.remainingAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get saleStatus => $composableBuilder(
    column: $table.saleStatus,
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

  ColumnOrderings<int> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cancelledAt => $composableBuilder(
    column: $table.cancelledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalDocumentNumber => $composableBuilder(
    column: $table.externalDocumentNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalStatus => $composableBuilder(
    column: $table.externalStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataSource => $composableBuilder(
    column: $table.dataSource,
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

class $$SalesTableAnnotationComposer
    extends Composer<_$SalesDatabase, $SalesTable> {
  $$SalesTableAnnotationComposer({
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

  GeneratedColumn<String> get saleNumber => $composableBuilder(
    column: $table.saleNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get saleDate =>
      $composableBuilder(column: $table.saleDate, builder: (column) => column);

  GeneratedColumn<String> get settlementType => $composableBuilder(
    column: $table.settlementType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get voucherBookId => $composableBuilder(
    column: $table.voucherBookId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerCode => $composableBuilder(
    column: $table.customerCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerAccountId => $composableBuilder(
    column: $table.customerAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cashAccountId => $composableBuilder(
    column: $table.cashAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get baseCurrencyCode => $composableBuilder(
    column: $table.baseCurrencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<double> get itemDiscountTotal => $composableBuilder(
    column: $table.itemDiscountTotal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get discountType => $composableBuilder(
    column: $table.discountType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => column,
  );

  GeneratedColumn<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get taxRate =>
      $composableBuilder(column: $table.taxRate, builder: (column) => column);

  GeneratedColumn<double> get taxAmount =>
      $composableBuilder(column: $table.taxAmount, builder: (column) => column);

  GeneratedColumn<double> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<double> get paidAmount => $composableBuilder(
    column: $table.paidAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get remainingAmount => $composableBuilder(
    column: $table.remainingAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get saleStatus => $composableBuilder(
    column: $table.saleStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cancelledAt => $composableBuilder(
    column: $table.cancelledAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get externalDocumentNumber => $composableBuilder(
    column: $table.externalDocumentNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get externalStatus => $composableBuilder(
    column: $table.externalStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dataSource => $composableBuilder(
    column: $table.dataSource,
    builder: (column) => column,
  );

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

class $$SalesTableTableManager
    extends
        RootTableManager<
          _$SalesDatabase,
          $SalesTable,
          SaleRow,
          $$SalesTableFilterComposer,
          $$SalesTableOrderingComposer,
          $$SalesTableAnnotationComposer,
          $$SalesTableCreateCompanionBuilder,
          $$SalesTableUpdateCompanionBuilder,
          (SaleRow, BaseReferences<_$SalesDatabase, $SalesTable, SaleRow>),
          SaleRow,
          PrefetchHooks Function()
        > {
  $$SalesTableTableManager(_$SalesDatabase db, $SalesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> saleNumber = const Value.absent(),
                Value<int> saleDate = const Value.absent(),
                Value<String> settlementType = const Value.absent(),
                Value<String?> voucherBookId = const Value.absent(),
                Value<String?> customerId = const Value.absent(),
                Value<String?> customerCode = const Value.absent(),
                Value<String?> customerName = const Value.absent(),
                Value<String?> customerAccountId = const Value.absent(),
                Value<String?> cashAccountId = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String> baseCurrencyCode = const Value.absent(),
                Value<double> exchangeRate = const Value.absent(),
                Value<double> subtotal = const Value.absent(),
                Value<double> itemDiscountTotal = const Value.absent(),
                Value<String> discountType = const Value.absent(),
                Value<double> discountValue = const Value.absent(),
                Value<double> discountAmount = const Value.absent(),
                Value<double> taxRate = const Value.absent(),
                Value<double> taxAmount = const Value.absent(),
                Value<double> total = const Value.absent(),
                Value<double> paidAmount = const Value.absent(),
                Value<double> remainingAmount = const Value.absent(),
                Value<String> paymentStatus = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<String> saleStatus = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> submittedAt = const Value.absent(),
                Value<int?> confirmedAt = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<int?> cancelledAt = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<String?> externalDocumentNumber = const Value.absent(),
                Value<String?> externalStatus = const Value.absent(),
                Value<String> dataSource = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> companyId = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => SalesCompanion(
                id: id,
                uuid: uuid,
                saleNumber: saleNumber,
                saleDate: saleDate,
                settlementType: settlementType,
                voucherBookId: voucherBookId,
                customerId: customerId,
                customerCode: customerCode,
                customerName: customerName,
                customerAccountId: customerAccountId,
                cashAccountId: cashAccountId,
                currencyCode: currencyCode,
                baseCurrencyCode: baseCurrencyCode,
                exchangeRate: exchangeRate,
                subtotal: subtotal,
                itemDiscountTotal: itemDiscountTotal,
                discountType: discountType,
                discountValue: discountValue,
                discountAmount: discountAmount,
                taxRate: taxRate,
                taxAmount: taxAmount,
                total: total,
                paidAmount: paidAmount,
                remainingAmount: remainingAmount,
                paymentStatus: paymentStatus,
                paymentMethod: paymentMethod,
                saleStatus: saleStatus,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                submittedAt: submittedAt,
                confirmedAt: confirmedAt,
                completedAt: completedAt,
                cancelledAt: cancelledAt,
                externalId: externalId,
                externalDocumentNumber: externalDocumentNumber,
                externalStatus: externalStatus,
                dataSource: dataSource,
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
                required String saleNumber,
                Value<int> saleDate = const Value.absent(),
                Value<String> settlementType = const Value.absent(),
                Value<String?> voucherBookId = const Value.absent(),
                Value<String?> customerId = const Value.absent(),
                Value<String?> customerCode = const Value.absent(),
                Value<String?> customerName = const Value.absent(),
                Value<String?> customerAccountId = const Value.absent(),
                Value<String?> cashAccountId = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String> baseCurrencyCode = const Value.absent(),
                Value<double> exchangeRate = const Value.absent(),
                required double subtotal,
                required double itemDiscountTotal,
                Value<String> discountType = const Value.absent(),
                Value<double> discountValue = const Value.absent(),
                Value<double> discountAmount = const Value.absent(),
                Value<double> taxRate = const Value.absent(),
                Value<double> taxAmount = const Value.absent(),
                required double total,
                Value<double> paidAmount = const Value.absent(),
                Value<double> remainingAmount = const Value.absent(),
                Value<String> paymentStatus = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<String> saleStatus = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> submittedAt = const Value.absent(),
                Value<int?> confirmedAt = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<int?> cancelledAt = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<String?> externalDocumentNumber = const Value.absent(),
                Value<String?> externalStatus = const Value.absent(),
                Value<String> dataSource = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> companyId = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => SalesCompanion.insert(
                id: id,
                uuid: uuid,
                saleNumber: saleNumber,
                saleDate: saleDate,
                settlementType: settlementType,
                voucherBookId: voucherBookId,
                customerId: customerId,
                customerCode: customerCode,
                customerName: customerName,
                customerAccountId: customerAccountId,
                cashAccountId: cashAccountId,
                currencyCode: currencyCode,
                baseCurrencyCode: baseCurrencyCode,
                exchangeRate: exchangeRate,
                subtotal: subtotal,
                itemDiscountTotal: itemDiscountTotal,
                discountType: discountType,
                discountValue: discountValue,
                discountAmount: discountAmount,
                taxRate: taxRate,
                taxAmount: taxAmount,
                total: total,
                paidAmount: paidAmount,
                remainingAmount: remainingAmount,
                paymentStatus: paymentStatus,
                paymentMethod: paymentMethod,
                saleStatus: saleStatus,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                submittedAt: submittedAt,
                confirmedAt: confirmedAt,
                completedAt: completedAt,
                cancelledAt: cancelledAt,
                externalId: externalId,
                externalDocumentNumber: externalDocumentNumber,
                externalStatus: externalStatus,
                dataSource: dataSource,
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

typedef $$SalesTableProcessedTableManager =
    ProcessedTableManager<
      _$SalesDatabase,
      $SalesTable,
      SaleRow,
      $$SalesTableFilterComposer,
      $$SalesTableOrderingComposer,
      $$SalesTableAnnotationComposer,
      $$SalesTableCreateCompanionBuilder,
      $$SalesTableUpdateCompanionBuilder,
      (SaleRow, BaseReferences<_$SalesDatabase, $SalesTable, SaleRow>),
      SaleRow,
      PrefetchHooks Function()
    >;
typedef $$SaleItemsTableCreateCompanionBuilder =
    SaleItemsCompanion Function({
      Value<int> id,
      required String uuid,
      required String saleUuid,
      required String productId,
      required String productName,
      required String productCode,
      Value<String?> barcode,
      required double quantity,
      Value<double> mainQuantity,
      Value<double> subQuantity,
      Value<int> packSize,
      required double unitPrice,
      Value<double> baseUnitPrice,
      Value<String> discountType,
      Value<double> discountValue,
      Value<double> discountAmount,
      Value<double> taxAmount,
      required double subtotal,
      required double total,
      Value<int> lineOrder,
    });
typedef $$SaleItemsTableUpdateCompanionBuilder =
    SaleItemsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String> saleUuid,
      Value<String> productId,
      Value<String> productName,
      Value<String> productCode,
      Value<String?> barcode,
      Value<double> quantity,
      Value<double> mainQuantity,
      Value<double> subQuantity,
      Value<int> packSize,
      Value<double> unitPrice,
      Value<double> baseUnitPrice,
      Value<String> discountType,
      Value<double> discountValue,
      Value<double> discountAmount,
      Value<double> taxAmount,
      Value<double> subtotal,
      Value<double> total,
      Value<int> lineOrder,
    });

class $$SaleItemsTableFilterComposer
    extends Composer<_$SalesDatabase, $SaleItemsTable> {
  $$SaleItemsTableFilterComposer({
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

  ColumnFilters<String> get saleUuid => $composableBuilder(
    column: $table.saleUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productCode => $composableBuilder(
    column: $table.productCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
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

  ColumnFilters<int> get packSize => $composableBuilder(
    column: $table.packSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get baseUnitPrice => $composableBuilder(
    column: $table.baseUnitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get discountType => $composableBuilder(
    column: $table.discountType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get taxAmount => $composableBuilder(
    column: $table.taxAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lineOrder => $composableBuilder(
    column: $table.lineOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SaleItemsTableOrderingComposer
    extends Composer<_$SalesDatabase, $SaleItemsTable> {
  $$SaleItemsTableOrderingComposer({
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

  ColumnOrderings<String> get saleUuid => $composableBuilder(
    column: $table.saleUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productCode => $composableBuilder(
    column: $table.productCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
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

  ColumnOrderings<int> get packSize => $composableBuilder(
    column: $table.packSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get baseUnitPrice => $composableBuilder(
    column: $table.baseUnitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discountType => $composableBuilder(
    column: $table.discountType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get taxAmount => $composableBuilder(
    column: $table.taxAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lineOrder => $composableBuilder(
    column: $table.lineOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SaleItemsTableAnnotationComposer
    extends Composer<_$SalesDatabase, $SaleItemsTable> {
  $$SaleItemsTableAnnotationComposer({
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

  GeneratedColumn<String> get saleUuid =>
      $composableBuilder(column: $table.saleUuid, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productCode => $composableBuilder(
    column: $table.productCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get mainQuantity => $composableBuilder(
    column: $table.mainQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<double> get subQuantity => $composableBuilder(
    column: $table.subQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<int> get packSize =>
      $composableBuilder(column: $table.packSize, builder: (column) => column);

  GeneratedColumn<double> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<double> get baseUnitPrice => $composableBuilder(
    column: $table.baseUnitPrice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get discountType => $composableBuilder(
    column: $table.discountType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => column,
  );

  GeneratedColumn<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get taxAmount =>
      $composableBuilder(column: $table.taxAmount, builder: (column) => column);

  GeneratedColumn<double> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<double> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<int> get lineOrder =>
      $composableBuilder(column: $table.lineOrder, builder: (column) => column);
}

class $$SaleItemsTableTableManager
    extends
        RootTableManager<
          _$SalesDatabase,
          $SaleItemsTable,
          SaleItemRow,
          $$SaleItemsTableFilterComposer,
          $$SaleItemsTableOrderingComposer,
          $$SaleItemsTableAnnotationComposer,
          $$SaleItemsTableCreateCompanionBuilder,
          $$SaleItemsTableUpdateCompanionBuilder,
          (
            SaleItemRow,
            BaseReferences<_$SalesDatabase, $SaleItemsTable, SaleItemRow>,
          ),
          SaleItemRow,
          PrefetchHooks Function()
        > {
  $$SaleItemsTableTableManager(_$SalesDatabase db, $SaleItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SaleItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SaleItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SaleItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> saleUuid = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<String> productCode = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<double> mainQuantity = const Value.absent(),
                Value<double> subQuantity = const Value.absent(),
                Value<int> packSize = const Value.absent(),
                Value<double> unitPrice = const Value.absent(),
                Value<double> baseUnitPrice = const Value.absent(),
                Value<String> discountType = const Value.absent(),
                Value<double> discountValue = const Value.absent(),
                Value<double> discountAmount = const Value.absent(),
                Value<double> taxAmount = const Value.absent(),
                Value<double> subtotal = const Value.absent(),
                Value<double> total = const Value.absent(),
                Value<int> lineOrder = const Value.absent(),
              }) => SaleItemsCompanion(
                id: id,
                uuid: uuid,
                saleUuid: saleUuid,
                productId: productId,
                productName: productName,
                productCode: productCode,
                barcode: barcode,
                quantity: quantity,
                mainQuantity: mainQuantity,
                subQuantity: subQuantity,
                packSize: packSize,
                unitPrice: unitPrice,
                baseUnitPrice: baseUnitPrice,
                discountType: discountType,
                discountValue: discountValue,
                discountAmount: discountAmount,
                taxAmount: taxAmount,
                subtotal: subtotal,
                total: total,
                lineOrder: lineOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required String saleUuid,
                required String productId,
                required String productName,
                required String productCode,
                Value<String?> barcode = const Value.absent(),
                required double quantity,
                Value<double> mainQuantity = const Value.absent(),
                Value<double> subQuantity = const Value.absent(),
                Value<int> packSize = const Value.absent(),
                required double unitPrice,
                Value<double> baseUnitPrice = const Value.absent(),
                Value<String> discountType = const Value.absent(),
                Value<double> discountValue = const Value.absent(),
                Value<double> discountAmount = const Value.absent(),
                Value<double> taxAmount = const Value.absent(),
                required double subtotal,
                required double total,
                Value<int> lineOrder = const Value.absent(),
              }) => SaleItemsCompanion.insert(
                id: id,
                uuid: uuid,
                saleUuid: saleUuid,
                productId: productId,
                productName: productName,
                productCode: productCode,
                barcode: barcode,
                quantity: quantity,
                mainQuantity: mainQuantity,
                subQuantity: subQuantity,
                packSize: packSize,
                unitPrice: unitPrice,
                baseUnitPrice: baseUnitPrice,
                discountType: discountType,
                discountValue: discountValue,
                discountAmount: discountAmount,
                taxAmount: taxAmount,
                subtotal: subtotal,
                total: total,
                lineOrder: lineOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SaleItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$SalesDatabase,
      $SaleItemsTable,
      SaleItemRow,
      $$SaleItemsTableFilterComposer,
      $$SaleItemsTableOrderingComposer,
      $$SaleItemsTableAnnotationComposer,
      $$SaleItemsTableCreateCompanionBuilder,
      $$SaleItemsTableUpdateCompanionBuilder,
      (
        SaleItemRow,
        BaseReferences<_$SalesDatabase, $SaleItemsTable, SaleItemRow>,
      ),
      SaleItemRow,
      PrefetchHooks Function()
    >;
typedef $$SalePaymentsTableCreateCompanionBuilder =
    SalePaymentsCompanion Function({
      Value<int> id,
      required String uuid,
      required String saleUuid,
      required double amount,
      Value<String> method,
      required int paidAt,
      required int createdAt,
      Value<String?> notes,
      Value<String?> externalId,
    });
typedef $$SalePaymentsTableUpdateCompanionBuilder =
    SalePaymentsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String> saleUuid,
      Value<double> amount,
      Value<String> method,
      Value<int> paidAt,
      Value<int> createdAt,
      Value<String?> notes,
      Value<String?> externalId,
    });

class $$SalePaymentsTableFilterComposer
    extends Composer<_$SalesDatabase, $SalePaymentsTable> {
  $$SalePaymentsTableFilterComposer({
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

  ColumnFilters<String> get saleUuid => $composableBuilder(
    column: $table.saleUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paidAt => $composableBuilder(
    column: $table.paidAt,
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

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SalePaymentsTableOrderingComposer
    extends Composer<_$SalesDatabase, $SalePaymentsTable> {
  $$SalePaymentsTableOrderingComposer({
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

  ColumnOrderings<String> get saleUuid => $composableBuilder(
    column: $table.saleUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paidAt => $composableBuilder(
    column: $table.paidAt,
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

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SalePaymentsTableAnnotationComposer
    extends Composer<_$SalesDatabase, $SalePaymentsTable> {
  $$SalePaymentsTableAnnotationComposer({
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

  GeneratedColumn<String> get saleUuid =>
      $composableBuilder(column: $table.saleUuid, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<int> get paidAt =>
      $composableBuilder(column: $table.paidAt, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );
}

class $$SalePaymentsTableTableManager
    extends
        RootTableManager<
          _$SalesDatabase,
          $SalePaymentsTable,
          SalePaymentRow,
          $$SalePaymentsTableFilterComposer,
          $$SalePaymentsTableOrderingComposer,
          $$SalePaymentsTableAnnotationComposer,
          $$SalePaymentsTableCreateCompanionBuilder,
          $$SalePaymentsTableUpdateCompanionBuilder,
          (
            SalePaymentRow,
            BaseReferences<_$SalesDatabase, $SalePaymentsTable, SalePaymentRow>,
          ),
          SalePaymentRow,
          PrefetchHooks Function()
        > {
  $$SalePaymentsTableTableManager(_$SalesDatabase db, $SalePaymentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SalePaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SalePaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SalePaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> saleUuid = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<int> paidAt = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
              }) => SalePaymentsCompanion(
                id: id,
                uuid: uuid,
                saleUuid: saleUuid,
                amount: amount,
                method: method,
                paidAt: paidAt,
                createdAt: createdAt,
                notes: notes,
                externalId: externalId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required String saleUuid,
                required double amount,
                Value<String> method = const Value.absent(),
                required int paidAt,
                required int createdAt,
                Value<String?> notes = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
              }) => SalePaymentsCompanion.insert(
                id: id,
                uuid: uuid,
                saleUuid: saleUuid,
                amount: amount,
                method: method,
                paidAt: paidAt,
                createdAt: createdAt,
                notes: notes,
                externalId: externalId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SalePaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$SalesDatabase,
      $SalePaymentsTable,
      SalePaymentRow,
      $$SalePaymentsTableFilterComposer,
      $$SalePaymentsTableOrderingComposer,
      $$SalePaymentsTableAnnotationComposer,
      $$SalePaymentsTableCreateCompanionBuilder,
      $$SalePaymentsTableUpdateCompanionBuilder,
      (
        SalePaymentRow,
        BaseReferences<_$SalesDatabase, $SalePaymentsTable, SalePaymentRow>,
      ),
      SalePaymentRow,
      PrefetchHooks Function()
    >;

class $SalesDatabaseManager {
  final _$SalesDatabase _db;
  $SalesDatabaseManager(this._db);
  $$SalesTableTableManager get sales =>
      $$SalesTableTableManager(_db, _db.sales);
  $$SaleItemsTableTableManager get saleItems =>
      $$SaleItemsTableTableManager(_db, _db.saleItems);
  $$SalePaymentsTableTableManager get salePayments =>
      $$SalePaymentsTableTableManager(_db, _db.salePayments);
}
