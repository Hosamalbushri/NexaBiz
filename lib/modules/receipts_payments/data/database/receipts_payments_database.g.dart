// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipts_payments_database.dart';

// ignore_for_file: type=lint
class $FinancialTransactionsTable extends FinancialTransactions
    with TableInfo<$FinancialTransactionsTable, FinancialTransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinancialTransactionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _transactionNumberMeta = const VerificationMeta(
    'transactionNumber',
  );
  @override
  late final GeneratedColumn<String> transactionNumber =
      GeneratedColumn<String>(
        'transaction_number',
        aliasedName,
        false,
        additionalChecks: GeneratedColumn.checkTextLength(
          minTextLength: 1,
          maxTextLength: 64,
        ),
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _transactionTypeMeta = const VerificationMeta(
    'transactionType',
  );
  @override
  late final GeneratedColumn<String> transactionType = GeneratedColumn<String>(
    'transaction_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionDateMeta = const VerificationMeta(
    'transactionDate',
  );
  @override
  late final GeneratedColumn<int> transactionDate = GeneratedColumn<int>(
    'transaction_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _counterAmountMeta = const VerificationMeta(
    'counterAmount',
  );
  @override
  late final GeneratedColumn<double> counterAmount = GeneratedColumn<double>(
    'counter_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _counterCurrencyCodeMeta =
      const VerificationMeta('counterCurrencyCode');
  @override
  late final GeneratedColumn<String> counterCurrencyCode =
      GeneratedColumn<String>(
        'counter_currency_code',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('SAR'),
      );
  static const VerificationMeta _counterExchangeRateMeta =
      const VerificationMeta('counterExchangeRate');
  @override
  late final GeneratedColumn<double> counterExchangeRate =
      GeneratedColumn<double>(
        'counter_exchange_rate',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(1.0),
      );
  static const VerificationMeta _linesJsonMeta = const VerificationMeta(
    'linesJson',
  );
  @override
  late final GeneratedColumn<String> linesJson = GeneratedColumn<String>(
    'lines_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _cashAccountIdMeta = const VerificationMeta(
    'cashAccountId',
  );
  @override
  late final GeneratedColumn<String> cashAccountId = GeneratedColumn<String>(
    'cash_account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cashAccountCodeMeta = const VerificationMeta(
    'cashAccountCode',
  );
  @override
  late final GeneratedColumn<String> cashAccountCode = GeneratedColumn<String>(
    'cash_account_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cashAccountNameMeta = const VerificationMeta(
    'cashAccountName',
  );
  @override
  late final GeneratedColumn<String> cashAccountName = GeneratedColumn<String>(
    'cash_account_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _counterAccountIdMeta = const VerificationMeta(
    'counterAccountId',
  );
  @override
  late final GeneratedColumn<String> counterAccountId = GeneratedColumn<String>(
    'counter_account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _counterAccountCodeMeta =
      const VerificationMeta('counterAccountCode');
  @override
  late final GeneratedColumn<String> counterAccountCode =
      GeneratedColumn<String>(
        'counter_account_code',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _counterAccountNameMeta =
      const VerificationMeta('counterAccountName');
  @override
  late final GeneratedColumn<String> counterAccountName =
      GeneratedColumn<String>(
        'counter_account_name',
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
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _documentStatusMeta = const VerificationMeta(
    'documentStatus',
  );
  @override
  late final GeneratedColumn<String> documentStatus = GeneratedColumn<String>(
    'document_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unposted'),
  );
  static const VerificationMeta _relatedDocumentIdMeta = const VerificationMeta(
    'relatedDocumentId',
  );
  @override
  late final GeneratedColumn<String> relatedDocumentId =
      GeneratedColumn<String>(
        'related_document_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _relatedDocumentTypeMeta =
      const VerificationMeta('relatedDocumentType');
  @override
  late final GeneratedColumn<String> relatedDocumentType =
      GeneratedColumn<String>(
        'related_document_type',
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
    transactionNumber,
    transactionType,
    source,
    transactionDate,
    amount,
    currencyCode,
    baseCurrencyCode,
    exchangeRate,
    counterAmount,
    counterCurrencyCode,
    counterExchangeRate,
    linesJson,
    voucherBookId,
    cashAccountId,
    cashAccountCode,
    cashAccountName,
    counterAccountId,
    counterAccountCode,
    counterAccountName,
    customerId,
    customerCode,
    customerName,
    partyName,
    reference,
    description,
    paymentMethod,
    documentStatus,
    relatedDocumentId,
    relatedDocumentType,
    createdAt,
    updatedAt,
    cancelledAt,
    externalId,
    syncStatus,
    lastSyncedAt,
    version,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'financial_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<FinancialTransactionRow> instance, {
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
    if (data.containsKey('transaction_number')) {
      context.handle(
        _transactionNumberMeta,
        transactionNumber.isAcceptableOrUnknown(
          data['transaction_number']!,
          _transactionNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionNumberMeta);
    }
    if (data.containsKey('transaction_type')) {
      context.handle(
        _transactionTypeMeta,
        transactionType.isAcceptableOrUnknown(
          data['transaction_type']!,
          _transactionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionTypeMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('transaction_date')) {
      context.handle(
        _transactionDateMeta,
        transactionDate.isAcceptableOrUnknown(
          data['transaction_date']!,
          _transactionDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionDateMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
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
    if (data.containsKey('counter_amount')) {
      context.handle(
        _counterAmountMeta,
        counterAmount.isAcceptableOrUnknown(
          data['counter_amount']!,
          _counterAmountMeta,
        ),
      );
    }
    if (data.containsKey('counter_currency_code')) {
      context.handle(
        _counterCurrencyCodeMeta,
        counterCurrencyCode.isAcceptableOrUnknown(
          data['counter_currency_code']!,
          _counterCurrencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('counter_exchange_rate')) {
      context.handle(
        _counterExchangeRateMeta,
        counterExchangeRate.isAcceptableOrUnknown(
          data['counter_exchange_rate']!,
          _counterExchangeRateMeta,
        ),
      );
    }
    if (data.containsKey('lines_json')) {
      context.handle(
        _linesJsonMeta,
        linesJson.isAcceptableOrUnknown(data['lines_json']!, _linesJsonMeta),
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
    if (data.containsKey('cash_account_id')) {
      context.handle(
        _cashAccountIdMeta,
        cashAccountId.isAcceptableOrUnknown(
          data['cash_account_id']!,
          _cashAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cashAccountIdMeta);
    }
    if (data.containsKey('cash_account_code')) {
      context.handle(
        _cashAccountCodeMeta,
        cashAccountCode.isAcceptableOrUnknown(
          data['cash_account_code']!,
          _cashAccountCodeMeta,
        ),
      );
    }
    if (data.containsKey('cash_account_name')) {
      context.handle(
        _cashAccountNameMeta,
        cashAccountName.isAcceptableOrUnknown(
          data['cash_account_name']!,
          _cashAccountNameMeta,
        ),
      );
    }
    if (data.containsKey('counter_account_id')) {
      context.handle(
        _counterAccountIdMeta,
        counterAccountId.isAcceptableOrUnknown(
          data['counter_account_id']!,
          _counterAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_counterAccountIdMeta);
    }
    if (data.containsKey('counter_account_code')) {
      context.handle(
        _counterAccountCodeMeta,
        counterAccountCode.isAcceptableOrUnknown(
          data['counter_account_code']!,
          _counterAccountCodeMeta,
        ),
      );
    }
    if (data.containsKey('counter_account_name')) {
      context.handle(
        _counterAccountNameMeta,
        counterAccountName.isAcceptableOrUnknown(
          data['counter_account_name']!,
          _counterAccountNameMeta,
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
    if (data.containsKey('party_name')) {
      context.handle(
        _partyNameMeta,
        partyName.isAcceptableOrUnknown(data['party_name']!, _partyNameMeta),
      );
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
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
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('document_status')) {
      context.handle(
        _documentStatusMeta,
        documentStatus.isAcceptableOrUnknown(
          data['document_status']!,
          _documentStatusMeta,
        ),
      );
    }
    if (data.containsKey('related_document_id')) {
      context.handle(
        _relatedDocumentIdMeta,
        relatedDocumentId.isAcceptableOrUnknown(
          data['related_document_id']!,
          _relatedDocumentIdMeta,
        ),
      );
    }
    if (data.containsKey('related_document_type')) {
      context.handle(
        _relatedDocumentTypeMeta,
        relatedDocumentType.isAcceptableOrUnknown(
          data['related_document_type']!,
          _relatedDocumentTypeMeta,
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
  FinancialTransactionRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FinancialTransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      transactionNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_number'],
      )!,
      transactionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_type'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      transactionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transaction_date'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
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
      counterAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}counter_amount'],
      )!,
      counterCurrencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counter_currency_code'],
      )!,
      counterExchangeRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}counter_exchange_rate'],
      )!,
      linesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lines_json'],
      ),
      voucherBookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voucher_book_id'],
      ),
      cashAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cash_account_id'],
      )!,
      cashAccountCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cash_account_code'],
      ),
      cashAccountName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cash_account_name'],
      ),
      counterAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counter_account_id'],
      )!,
      counterAccountCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counter_account_code'],
      ),
      counterAccountName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counter_account_name'],
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
      partyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}party_name'],
      ),
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      )!,
      documentStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_status'],
      )!,
      relatedDocumentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}related_document_id'],
      ),
      relatedDocumentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}related_document_type'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      cancelledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cancelled_at'],
      ),
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      ),
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
  $FinancialTransactionsTable createAlias(String alias) {
    return $FinancialTransactionsTable(attachedDatabase, alias);
  }
}

class FinancialTransactionRow extends DataClass
    implements Insertable<FinancialTransactionRow> {
  final int id;
  final String uuid;
  final String transactionNumber;

  /// [TransactionType.name] — receipt | payment
  final String transactionType;

  /// [TransactionSource.name]
  final String source;

  /// Business date (UTC epoch ms).
  final int transactionDate;
  final double amount;
  final String currencyCode;
  final String baseCurrencyCode;
  final double exchangeRate;

  /// Counter/party amount (may differ from cash [amount] when currencies differ).
  final double counterAmount;
  final String counterCurrencyCode;
  final double counterExchangeRate;

  /// JSON array of party/CoA allocation lines (multi-account support).
  final String? linesJson;
  final String? voucherBookId;
  final String cashAccountId;
  final String? cashAccountCode;
  final String? cashAccountName;
  final String counterAccountId;
  final String? counterAccountCode;
  final String? counterAccountName;
  final String? customerId;
  final String? customerCode;
  final String? customerName;
  final String? partyName;
  final String? reference;
  final String? description;
  final String paymentMethod;

  /// [TransactionStatus.name]
  final String documentStatus;
  final String? relatedDocumentId;
  final String? relatedDocumentType;
  final int createdAt;
  final int updatedAt;
  final int? cancelledAt;
  final String? externalId;
  final String syncStatus;
  final int? lastSyncedAt;
  final int version;
  final int? deletedAt;
  const FinancialTransactionRow({
    required this.id,
    required this.uuid,
    required this.transactionNumber,
    required this.transactionType,
    required this.source,
    required this.transactionDate,
    required this.amount,
    required this.currencyCode,
    required this.baseCurrencyCode,
    required this.exchangeRate,
    required this.counterAmount,
    required this.counterCurrencyCode,
    required this.counterExchangeRate,
    this.linesJson,
    this.voucherBookId,
    required this.cashAccountId,
    this.cashAccountCode,
    this.cashAccountName,
    required this.counterAccountId,
    this.counterAccountCode,
    this.counterAccountName,
    this.customerId,
    this.customerCode,
    this.customerName,
    this.partyName,
    this.reference,
    this.description,
    required this.paymentMethod,
    required this.documentStatus,
    this.relatedDocumentId,
    this.relatedDocumentType,
    required this.createdAt,
    required this.updatedAt,
    this.cancelledAt,
    this.externalId,
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
    map['transaction_number'] = Variable<String>(transactionNumber);
    map['transaction_type'] = Variable<String>(transactionType);
    map['source'] = Variable<String>(source);
    map['transaction_date'] = Variable<int>(transactionDate);
    map['amount'] = Variable<double>(amount);
    map['currency_code'] = Variable<String>(currencyCode);
    map['base_currency_code'] = Variable<String>(baseCurrencyCode);
    map['exchange_rate'] = Variable<double>(exchangeRate);
    map['counter_amount'] = Variable<double>(counterAmount);
    map['counter_currency_code'] = Variable<String>(counterCurrencyCode);
    map['counter_exchange_rate'] = Variable<double>(counterExchangeRate);
    if (!nullToAbsent || linesJson != null) {
      map['lines_json'] = Variable<String>(linesJson);
    }
    if (!nullToAbsent || voucherBookId != null) {
      map['voucher_book_id'] = Variable<String>(voucherBookId);
    }
    map['cash_account_id'] = Variable<String>(cashAccountId);
    if (!nullToAbsent || cashAccountCode != null) {
      map['cash_account_code'] = Variable<String>(cashAccountCode);
    }
    if (!nullToAbsent || cashAccountName != null) {
      map['cash_account_name'] = Variable<String>(cashAccountName);
    }
    map['counter_account_id'] = Variable<String>(counterAccountId);
    if (!nullToAbsent || counterAccountCode != null) {
      map['counter_account_code'] = Variable<String>(counterAccountCode);
    }
    if (!nullToAbsent || counterAccountName != null) {
      map['counter_account_name'] = Variable<String>(counterAccountName);
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
    if (!nullToAbsent || partyName != null) {
      map['party_name'] = Variable<String>(partyName);
    }
    if (!nullToAbsent || reference != null) {
      map['reference'] = Variable<String>(reference);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['payment_method'] = Variable<String>(paymentMethod);
    map['document_status'] = Variable<String>(documentStatus);
    if (!nullToAbsent || relatedDocumentId != null) {
      map['related_document_id'] = Variable<String>(relatedDocumentId);
    }
    if (!nullToAbsent || relatedDocumentType != null) {
      map['related_document_type'] = Variable<String>(relatedDocumentType);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || cancelledAt != null) {
      map['cancelled_at'] = Variable<int>(cancelledAt);
    }
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
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

  FinancialTransactionsCompanion toCompanion(bool nullToAbsent) {
    return FinancialTransactionsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      transactionNumber: Value(transactionNumber),
      transactionType: Value(transactionType),
      source: Value(source),
      transactionDate: Value(transactionDate),
      amount: Value(amount),
      currencyCode: Value(currencyCode),
      baseCurrencyCode: Value(baseCurrencyCode),
      exchangeRate: Value(exchangeRate),
      counterAmount: Value(counterAmount),
      counterCurrencyCode: Value(counterCurrencyCode),
      counterExchangeRate: Value(counterExchangeRate),
      linesJson: linesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(linesJson),
      voucherBookId: voucherBookId == null && nullToAbsent
          ? const Value.absent()
          : Value(voucherBookId),
      cashAccountId: Value(cashAccountId),
      cashAccountCode: cashAccountCode == null && nullToAbsent
          ? const Value.absent()
          : Value(cashAccountCode),
      cashAccountName: cashAccountName == null && nullToAbsent
          ? const Value.absent()
          : Value(cashAccountName),
      counterAccountId: Value(counterAccountId),
      counterAccountCode: counterAccountCode == null && nullToAbsent
          ? const Value.absent()
          : Value(counterAccountCode),
      counterAccountName: counterAccountName == null && nullToAbsent
          ? const Value.absent()
          : Value(counterAccountName),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      customerCode: customerCode == null && nullToAbsent
          ? const Value.absent()
          : Value(customerCode),
      customerName: customerName == null && nullToAbsent
          ? const Value.absent()
          : Value(customerName),
      partyName: partyName == null && nullToAbsent
          ? const Value.absent()
          : Value(partyName),
      reference: reference == null && nullToAbsent
          ? const Value.absent()
          : Value(reference),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      paymentMethod: Value(paymentMethod),
      documentStatus: Value(documentStatus),
      relatedDocumentId: relatedDocumentId == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedDocumentId),
      relatedDocumentType: relatedDocumentType == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedDocumentType),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      cancelledAt: cancelledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(cancelledAt),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
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

  factory FinancialTransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FinancialTransactionRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      transactionNumber: serializer.fromJson<String>(json['transactionNumber']),
      transactionType: serializer.fromJson<String>(json['transactionType']),
      source: serializer.fromJson<String>(json['source']),
      transactionDate: serializer.fromJson<int>(json['transactionDate']),
      amount: serializer.fromJson<double>(json['amount']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      baseCurrencyCode: serializer.fromJson<String>(json['baseCurrencyCode']),
      exchangeRate: serializer.fromJson<double>(json['exchangeRate']),
      counterAmount: serializer.fromJson<double>(json['counterAmount']),
      counterCurrencyCode: serializer.fromJson<String>(
        json['counterCurrencyCode'],
      ),
      counterExchangeRate: serializer.fromJson<double>(
        json['counterExchangeRate'],
      ),
      linesJson: serializer.fromJson<String?>(json['linesJson']),
      voucherBookId: serializer.fromJson<String?>(json['voucherBookId']),
      cashAccountId: serializer.fromJson<String>(json['cashAccountId']),
      cashAccountCode: serializer.fromJson<String?>(json['cashAccountCode']),
      cashAccountName: serializer.fromJson<String?>(json['cashAccountName']),
      counterAccountId: serializer.fromJson<String>(json['counterAccountId']),
      counterAccountCode: serializer.fromJson<String?>(
        json['counterAccountCode'],
      ),
      counterAccountName: serializer.fromJson<String?>(
        json['counterAccountName'],
      ),
      customerId: serializer.fromJson<String?>(json['customerId']),
      customerCode: serializer.fromJson<String?>(json['customerCode']),
      customerName: serializer.fromJson<String?>(json['customerName']),
      partyName: serializer.fromJson<String?>(json['partyName']),
      reference: serializer.fromJson<String?>(json['reference']),
      description: serializer.fromJson<String?>(json['description']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      documentStatus: serializer.fromJson<String>(json['documentStatus']),
      relatedDocumentId: serializer.fromJson<String?>(
        json['relatedDocumentId'],
      ),
      relatedDocumentType: serializer.fromJson<String?>(
        json['relatedDocumentType'],
      ),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      cancelledAt: serializer.fromJson<int?>(json['cancelledAt']),
      externalId: serializer.fromJson<String?>(json['externalId']),
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
      'transactionNumber': serializer.toJson<String>(transactionNumber),
      'transactionType': serializer.toJson<String>(transactionType),
      'source': serializer.toJson<String>(source),
      'transactionDate': serializer.toJson<int>(transactionDate),
      'amount': serializer.toJson<double>(amount),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'baseCurrencyCode': serializer.toJson<String>(baseCurrencyCode),
      'exchangeRate': serializer.toJson<double>(exchangeRate),
      'counterAmount': serializer.toJson<double>(counterAmount),
      'counterCurrencyCode': serializer.toJson<String>(counterCurrencyCode),
      'counterExchangeRate': serializer.toJson<double>(counterExchangeRate),
      'linesJson': serializer.toJson<String?>(linesJson),
      'voucherBookId': serializer.toJson<String?>(voucherBookId),
      'cashAccountId': serializer.toJson<String>(cashAccountId),
      'cashAccountCode': serializer.toJson<String?>(cashAccountCode),
      'cashAccountName': serializer.toJson<String?>(cashAccountName),
      'counterAccountId': serializer.toJson<String>(counterAccountId),
      'counterAccountCode': serializer.toJson<String?>(counterAccountCode),
      'counterAccountName': serializer.toJson<String?>(counterAccountName),
      'customerId': serializer.toJson<String?>(customerId),
      'customerCode': serializer.toJson<String?>(customerCode),
      'customerName': serializer.toJson<String?>(customerName),
      'partyName': serializer.toJson<String?>(partyName),
      'reference': serializer.toJson<String?>(reference),
      'description': serializer.toJson<String?>(description),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'documentStatus': serializer.toJson<String>(documentStatus),
      'relatedDocumentId': serializer.toJson<String?>(relatedDocumentId),
      'relatedDocumentType': serializer.toJson<String?>(relatedDocumentType),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'cancelledAt': serializer.toJson<int?>(cancelledAt),
      'externalId': serializer.toJson<String?>(externalId),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'lastSyncedAt': serializer.toJson<int?>(lastSyncedAt),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  FinancialTransactionRow copyWith({
    int? id,
    String? uuid,
    String? transactionNumber,
    String? transactionType,
    String? source,
    int? transactionDate,
    double? amount,
    String? currencyCode,
    String? baseCurrencyCode,
    double? exchangeRate,
    double? counterAmount,
    String? counterCurrencyCode,
    double? counterExchangeRate,
    Value<String?> linesJson = const Value.absent(),
    Value<String?> voucherBookId = const Value.absent(),
    String? cashAccountId,
    Value<String?> cashAccountCode = const Value.absent(),
    Value<String?> cashAccountName = const Value.absent(),
    String? counterAccountId,
    Value<String?> counterAccountCode = const Value.absent(),
    Value<String?> counterAccountName = const Value.absent(),
    Value<String?> customerId = const Value.absent(),
    Value<String?> customerCode = const Value.absent(),
    Value<String?> customerName = const Value.absent(),
    Value<String?> partyName = const Value.absent(),
    Value<String?> reference = const Value.absent(),
    Value<String?> description = const Value.absent(),
    String? paymentMethod,
    String? documentStatus,
    Value<String?> relatedDocumentId = const Value.absent(),
    Value<String?> relatedDocumentType = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    Value<int?> cancelledAt = const Value.absent(),
    Value<String?> externalId = const Value.absent(),
    String? syncStatus,
    Value<int?> lastSyncedAt = const Value.absent(),
    int? version,
    Value<int?> deletedAt = const Value.absent(),
  }) => FinancialTransactionRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    transactionNumber: transactionNumber ?? this.transactionNumber,
    transactionType: transactionType ?? this.transactionType,
    source: source ?? this.source,
    transactionDate: transactionDate ?? this.transactionDate,
    amount: amount ?? this.amount,
    currencyCode: currencyCode ?? this.currencyCode,
    baseCurrencyCode: baseCurrencyCode ?? this.baseCurrencyCode,
    exchangeRate: exchangeRate ?? this.exchangeRate,
    counterAmount: counterAmount ?? this.counterAmount,
    counterCurrencyCode: counterCurrencyCode ?? this.counterCurrencyCode,
    counterExchangeRate: counterExchangeRate ?? this.counterExchangeRate,
    linesJson: linesJson.present ? linesJson.value : this.linesJson,
    voucherBookId: voucherBookId.present
        ? voucherBookId.value
        : this.voucherBookId,
    cashAccountId: cashAccountId ?? this.cashAccountId,
    cashAccountCode: cashAccountCode.present
        ? cashAccountCode.value
        : this.cashAccountCode,
    cashAccountName: cashAccountName.present
        ? cashAccountName.value
        : this.cashAccountName,
    counterAccountId: counterAccountId ?? this.counterAccountId,
    counterAccountCode: counterAccountCode.present
        ? counterAccountCode.value
        : this.counterAccountCode,
    counterAccountName: counterAccountName.present
        ? counterAccountName.value
        : this.counterAccountName,
    customerId: customerId.present ? customerId.value : this.customerId,
    customerCode: customerCode.present ? customerCode.value : this.customerCode,
    customerName: customerName.present ? customerName.value : this.customerName,
    partyName: partyName.present ? partyName.value : this.partyName,
    reference: reference.present ? reference.value : this.reference,
    description: description.present ? description.value : this.description,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    documentStatus: documentStatus ?? this.documentStatus,
    relatedDocumentId: relatedDocumentId.present
        ? relatedDocumentId.value
        : this.relatedDocumentId,
    relatedDocumentType: relatedDocumentType.present
        ? relatedDocumentType.value
        : this.relatedDocumentType,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    cancelledAt: cancelledAt.present ? cancelledAt.value : this.cancelledAt,
    externalId: externalId.present ? externalId.value : this.externalId,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  FinancialTransactionRow copyWithCompanion(
    FinancialTransactionsCompanion data,
  ) {
    return FinancialTransactionRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      transactionNumber: data.transactionNumber.present
          ? data.transactionNumber.value
          : this.transactionNumber,
      transactionType: data.transactionType.present
          ? data.transactionType.value
          : this.transactionType,
      source: data.source.present ? data.source.value : this.source,
      transactionDate: data.transactionDate.present
          ? data.transactionDate.value
          : this.transactionDate,
      amount: data.amount.present ? data.amount.value : this.amount,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      baseCurrencyCode: data.baseCurrencyCode.present
          ? data.baseCurrencyCode.value
          : this.baseCurrencyCode,
      exchangeRate: data.exchangeRate.present
          ? data.exchangeRate.value
          : this.exchangeRate,
      counterAmount: data.counterAmount.present
          ? data.counterAmount.value
          : this.counterAmount,
      counterCurrencyCode: data.counterCurrencyCode.present
          ? data.counterCurrencyCode.value
          : this.counterCurrencyCode,
      counterExchangeRate: data.counterExchangeRate.present
          ? data.counterExchangeRate.value
          : this.counterExchangeRate,
      linesJson: data.linesJson.present ? data.linesJson.value : this.linesJson,
      voucherBookId: data.voucherBookId.present
          ? data.voucherBookId.value
          : this.voucherBookId,
      cashAccountId: data.cashAccountId.present
          ? data.cashAccountId.value
          : this.cashAccountId,
      cashAccountCode: data.cashAccountCode.present
          ? data.cashAccountCode.value
          : this.cashAccountCode,
      cashAccountName: data.cashAccountName.present
          ? data.cashAccountName.value
          : this.cashAccountName,
      counterAccountId: data.counterAccountId.present
          ? data.counterAccountId.value
          : this.counterAccountId,
      counterAccountCode: data.counterAccountCode.present
          ? data.counterAccountCode.value
          : this.counterAccountCode,
      counterAccountName: data.counterAccountName.present
          ? data.counterAccountName.value
          : this.counterAccountName,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      customerCode: data.customerCode.present
          ? data.customerCode.value
          : this.customerCode,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      partyName: data.partyName.present ? data.partyName.value : this.partyName,
      reference: data.reference.present ? data.reference.value : this.reference,
      description: data.description.present
          ? data.description.value
          : this.description,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      documentStatus: data.documentStatus.present
          ? data.documentStatus.value
          : this.documentStatus,
      relatedDocumentId: data.relatedDocumentId.present
          ? data.relatedDocumentId.value
          : this.relatedDocumentId,
      relatedDocumentType: data.relatedDocumentType.present
          ? data.relatedDocumentType.value
          : this.relatedDocumentType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      cancelledAt: data.cancelledAt.present
          ? data.cancelledAt.value
          : this.cancelledAt,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
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
    return (StringBuffer('FinancialTransactionRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('transactionNumber: $transactionNumber, ')
          ..write('transactionType: $transactionType, ')
          ..write('source: $source, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('amount: $amount, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('baseCurrencyCode: $baseCurrencyCode, ')
          ..write('exchangeRate: $exchangeRate, ')
          ..write('counterAmount: $counterAmount, ')
          ..write('counterCurrencyCode: $counterCurrencyCode, ')
          ..write('counterExchangeRate: $counterExchangeRate, ')
          ..write('linesJson: $linesJson, ')
          ..write('voucherBookId: $voucherBookId, ')
          ..write('cashAccountId: $cashAccountId, ')
          ..write('cashAccountCode: $cashAccountCode, ')
          ..write('cashAccountName: $cashAccountName, ')
          ..write('counterAccountId: $counterAccountId, ')
          ..write('counterAccountCode: $counterAccountCode, ')
          ..write('counterAccountName: $counterAccountName, ')
          ..write('customerId: $customerId, ')
          ..write('customerCode: $customerCode, ')
          ..write('customerName: $customerName, ')
          ..write('partyName: $partyName, ')
          ..write('reference: $reference, ')
          ..write('description: $description, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('documentStatus: $documentStatus, ')
          ..write('relatedDocumentId: $relatedDocumentId, ')
          ..write('relatedDocumentType: $relatedDocumentType, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cancelledAt: $cancelledAt, ')
          ..write('externalId: $externalId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    uuid,
    transactionNumber,
    transactionType,
    source,
    transactionDate,
    amount,
    currencyCode,
    baseCurrencyCode,
    exchangeRate,
    counterAmount,
    counterCurrencyCode,
    counterExchangeRate,
    linesJson,
    voucherBookId,
    cashAccountId,
    cashAccountCode,
    cashAccountName,
    counterAccountId,
    counterAccountCode,
    counterAccountName,
    customerId,
    customerCode,
    customerName,
    partyName,
    reference,
    description,
    paymentMethod,
    documentStatus,
    relatedDocumentId,
    relatedDocumentType,
    createdAt,
    updatedAt,
    cancelledAt,
    externalId,
    syncStatus,
    lastSyncedAt,
    version,
    deletedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinancialTransactionRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.transactionNumber == this.transactionNumber &&
          other.transactionType == this.transactionType &&
          other.source == this.source &&
          other.transactionDate == this.transactionDate &&
          other.amount == this.amount &&
          other.currencyCode == this.currencyCode &&
          other.baseCurrencyCode == this.baseCurrencyCode &&
          other.exchangeRate == this.exchangeRate &&
          other.counterAmount == this.counterAmount &&
          other.counterCurrencyCode == this.counterCurrencyCode &&
          other.counterExchangeRate == this.counterExchangeRate &&
          other.linesJson == this.linesJson &&
          other.voucherBookId == this.voucherBookId &&
          other.cashAccountId == this.cashAccountId &&
          other.cashAccountCode == this.cashAccountCode &&
          other.cashAccountName == this.cashAccountName &&
          other.counterAccountId == this.counterAccountId &&
          other.counterAccountCode == this.counterAccountCode &&
          other.counterAccountName == this.counterAccountName &&
          other.customerId == this.customerId &&
          other.customerCode == this.customerCode &&
          other.customerName == this.customerName &&
          other.partyName == this.partyName &&
          other.reference == this.reference &&
          other.description == this.description &&
          other.paymentMethod == this.paymentMethod &&
          other.documentStatus == this.documentStatus &&
          other.relatedDocumentId == this.relatedDocumentId &&
          other.relatedDocumentType == this.relatedDocumentType &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.cancelledAt == this.cancelledAt &&
          other.externalId == this.externalId &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt);
}

class FinancialTransactionsCompanion
    extends UpdateCompanion<FinancialTransactionRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> transactionNumber;
  final Value<String> transactionType;
  final Value<String> source;
  final Value<int> transactionDate;
  final Value<double> amount;
  final Value<String> currencyCode;
  final Value<String> baseCurrencyCode;
  final Value<double> exchangeRate;
  final Value<double> counterAmount;
  final Value<String> counterCurrencyCode;
  final Value<double> counterExchangeRate;
  final Value<String?> linesJson;
  final Value<String?> voucherBookId;
  final Value<String> cashAccountId;
  final Value<String?> cashAccountCode;
  final Value<String?> cashAccountName;
  final Value<String> counterAccountId;
  final Value<String?> counterAccountCode;
  final Value<String?> counterAccountName;
  final Value<String?> customerId;
  final Value<String?> customerCode;
  final Value<String?> customerName;
  final Value<String?> partyName;
  final Value<String?> reference;
  final Value<String?> description;
  final Value<String> paymentMethod;
  final Value<String> documentStatus;
  final Value<String?> relatedDocumentId;
  final Value<String?> relatedDocumentType;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> cancelledAt;
  final Value<String?> externalId;
  final Value<String> syncStatus;
  final Value<int?> lastSyncedAt;
  final Value<int> version;
  final Value<int?> deletedAt;
  const FinancialTransactionsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.transactionNumber = const Value.absent(),
    this.transactionType = const Value.absent(),
    this.source = const Value.absent(),
    this.transactionDate = const Value.absent(),
    this.amount = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.baseCurrencyCode = const Value.absent(),
    this.exchangeRate = const Value.absent(),
    this.counterAmount = const Value.absent(),
    this.counterCurrencyCode = const Value.absent(),
    this.counterExchangeRate = const Value.absent(),
    this.linesJson = const Value.absent(),
    this.voucherBookId = const Value.absent(),
    this.cashAccountId = const Value.absent(),
    this.cashAccountCode = const Value.absent(),
    this.cashAccountName = const Value.absent(),
    this.counterAccountId = const Value.absent(),
    this.counterAccountCode = const Value.absent(),
    this.counterAccountName = const Value.absent(),
    this.customerId = const Value.absent(),
    this.customerCode = const Value.absent(),
    this.customerName = const Value.absent(),
    this.partyName = const Value.absent(),
    this.reference = const Value.absent(),
    this.description = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.documentStatus = const Value.absent(),
    this.relatedDocumentId = const Value.absent(),
    this.relatedDocumentType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.cancelledAt = const Value.absent(),
    this.externalId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  FinancialTransactionsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String transactionNumber,
    required String transactionType,
    required String source,
    required int transactionDate,
    required double amount,
    this.currencyCode = const Value.absent(),
    this.baseCurrencyCode = const Value.absent(),
    this.exchangeRate = const Value.absent(),
    this.counterAmount = const Value.absent(),
    this.counterCurrencyCode = const Value.absent(),
    this.counterExchangeRate = const Value.absent(),
    this.linesJson = const Value.absent(),
    this.voucherBookId = const Value.absent(),
    required String cashAccountId,
    this.cashAccountCode = const Value.absent(),
    this.cashAccountName = const Value.absent(),
    required String counterAccountId,
    this.counterAccountCode = const Value.absent(),
    this.counterAccountName = const Value.absent(),
    this.customerId = const Value.absent(),
    this.customerCode = const Value.absent(),
    this.customerName = const Value.absent(),
    this.partyName = const Value.absent(),
    this.reference = const Value.absent(),
    this.description = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.documentStatus = const Value.absent(),
    this.relatedDocumentId = const Value.absent(),
    this.relatedDocumentType = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.cancelledAt = const Value.absent(),
    this.externalId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : uuid = Value(uuid),
       transactionNumber = Value(transactionNumber),
       transactionType = Value(transactionType),
       source = Value(source),
       transactionDate = Value(transactionDate),
       amount = Value(amount),
       cashAccountId = Value(cashAccountId),
       counterAccountId = Value(counterAccountId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<FinancialTransactionRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? transactionNumber,
    Expression<String>? transactionType,
    Expression<String>? source,
    Expression<int>? transactionDate,
    Expression<double>? amount,
    Expression<String>? currencyCode,
    Expression<String>? baseCurrencyCode,
    Expression<double>? exchangeRate,
    Expression<double>? counterAmount,
    Expression<String>? counterCurrencyCode,
    Expression<double>? counterExchangeRate,
    Expression<String>? linesJson,
    Expression<String>? voucherBookId,
    Expression<String>? cashAccountId,
    Expression<String>? cashAccountCode,
    Expression<String>? cashAccountName,
    Expression<String>? counterAccountId,
    Expression<String>? counterAccountCode,
    Expression<String>? counterAccountName,
    Expression<String>? customerId,
    Expression<String>? customerCode,
    Expression<String>? customerName,
    Expression<String>? partyName,
    Expression<String>? reference,
    Expression<String>? description,
    Expression<String>? paymentMethod,
    Expression<String>? documentStatus,
    Expression<String>? relatedDocumentId,
    Expression<String>? relatedDocumentType,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? cancelledAt,
    Expression<String>? externalId,
    Expression<String>? syncStatus,
    Expression<int>? lastSyncedAt,
    Expression<int>? version,
    Expression<int>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (transactionNumber != null) 'transaction_number': transactionNumber,
      if (transactionType != null) 'transaction_type': transactionType,
      if (source != null) 'source': source,
      if (transactionDate != null) 'transaction_date': transactionDate,
      if (amount != null) 'amount': amount,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (baseCurrencyCode != null) 'base_currency_code': baseCurrencyCode,
      if (exchangeRate != null) 'exchange_rate': exchangeRate,
      if (counterAmount != null) 'counter_amount': counterAmount,
      if (counterCurrencyCode != null)
        'counter_currency_code': counterCurrencyCode,
      if (counterExchangeRate != null)
        'counter_exchange_rate': counterExchangeRate,
      if (linesJson != null) 'lines_json': linesJson,
      if (voucherBookId != null) 'voucher_book_id': voucherBookId,
      if (cashAccountId != null) 'cash_account_id': cashAccountId,
      if (cashAccountCode != null) 'cash_account_code': cashAccountCode,
      if (cashAccountName != null) 'cash_account_name': cashAccountName,
      if (counterAccountId != null) 'counter_account_id': counterAccountId,
      if (counterAccountCode != null)
        'counter_account_code': counterAccountCode,
      if (counterAccountName != null)
        'counter_account_name': counterAccountName,
      if (customerId != null) 'customer_id': customerId,
      if (customerCode != null) 'customer_code': customerCode,
      if (customerName != null) 'customer_name': customerName,
      if (partyName != null) 'party_name': partyName,
      if (reference != null) 'reference': reference,
      if (description != null) 'description': description,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (documentStatus != null) 'document_status': documentStatus,
      if (relatedDocumentId != null) 'related_document_id': relatedDocumentId,
      if (relatedDocumentType != null)
        'related_document_type': relatedDocumentType,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (cancelledAt != null) 'cancelled_at': cancelledAt,
      if (externalId != null) 'external_id': externalId,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  FinancialTransactionsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? transactionNumber,
    Value<String>? transactionType,
    Value<String>? source,
    Value<int>? transactionDate,
    Value<double>? amount,
    Value<String>? currencyCode,
    Value<String>? baseCurrencyCode,
    Value<double>? exchangeRate,
    Value<double>? counterAmount,
    Value<String>? counterCurrencyCode,
    Value<double>? counterExchangeRate,
    Value<String?>? linesJson,
    Value<String?>? voucherBookId,
    Value<String>? cashAccountId,
    Value<String?>? cashAccountCode,
    Value<String?>? cashAccountName,
    Value<String>? counterAccountId,
    Value<String?>? counterAccountCode,
    Value<String?>? counterAccountName,
    Value<String?>? customerId,
    Value<String?>? customerCode,
    Value<String?>? customerName,
    Value<String?>? partyName,
    Value<String?>? reference,
    Value<String?>? description,
    Value<String>? paymentMethod,
    Value<String>? documentStatus,
    Value<String?>? relatedDocumentId,
    Value<String?>? relatedDocumentType,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? cancelledAt,
    Value<String?>? externalId,
    Value<String>? syncStatus,
    Value<int?>? lastSyncedAt,
    Value<int>? version,
    Value<int?>? deletedAt,
  }) {
    return FinancialTransactionsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      transactionNumber: transactionNumber ?? this.transactionNumber,
      transactionType: transactionType ?? this.transactionType,
      source: source ?? this.source,
      transactionDate: transactionDate ?? this.transactionDate,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      baseCurrencyCode: baseCurrencyCode ?? this.baseCurrencyCode,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      counterAmount: counterAmount ?? this.counterAmount,
      counterCurrencyCode: counterCurrencyCode ?? this.counterCurrencyCode,
      counterExchangeRate: counterExchangeRate ?? this.counterExchangeRate,
      linesJson: linesJson ?? this.linesJson,
      voucherBookId: voucherBookId ?? this.voucherBookId,
      cashAccountId: cashAccountId ?? this.cashAccountId,
      cashAccountCode: cashAccountCode ?? this.cashAccountCode,
      cashAccountName: cashAccountName ?? this.cashAccountName,
      counterAccountId: counterAccountId ?? this.counterAccountId,
      counterAccountCode: counterAccountCode ?? this.counterAccountCode,
      counterAccountName: counterAccountName ?? this.counterAccountName,
      customerId: customerId ?? this.customerId,
      customerCode: customerCode ?? this.customerCode,
      customerName: customerName ?? this.customerName,
      partyName: partyName ?? this.partyName,
      reference: reference ?? this.reference,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      documentStatus: documentStatus ?? this.documentStatus,
      relatedDocumentId: relatedDocumentId ?? this.relatedDocumentId,
      relatedDocumentType: relatedDocumentType ?? this.relatedDocumentType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      externalId: externalId ?? this.externalId,
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
    if (transactionNumber.present) {
      map['transaction_number'] = Variable<String>(transactionNumber.value);
    }
    if (transactionType.present) {
      map['transaction_type'] = Variable<String>(transactionType.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (transactionDate.present) {
      map['transaction_date'] = Variable<int>(transactionDate.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
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
    if (counterAmount.present) {
      map['counter_amount'] = Variable<double>(counterAmount.value);
    }
    if (counterCurrencyCode.present) {
      map['counter_currency_code'] = Variable<String>(
        counterCurrencyCode.value,
      );
    }
    if (counterExchangeRate.present) {
      map['counter_exchange_rate'] = Variable<double>(
        counterExchangeRate.value,
      );
    }
    if (linesJson.present) {
      map['lines_json'] = Variable<String>(linesJson.value);
    }
    if (voucherBookId.present) {
      map['voucher_book_id'] = Variable<String>(voucherBookId.value);
    }
    if (cashAccountId.present) {
      map['cash_account_id'] = Variable<String>(cashAccountId.value);
    }
    if (cashAccountCode.present) {
      map['cash_account_code'] = Variable<String>(cashAccountCode.value);
    }
    if (cashAccountName.present) {
      map['cash_account_name'] = Variable<String>(cashAccountName.value);
    }
    if (counterAccountId.present) {
      map['counter_account_id'] = Variable<String>(counterAccountId.value);
    }
    if (counterAccountCode.present) {
      map['counter_account_code'] = Variable<String>(counterAccountCode.value);
    }
    if (counterAccountName.present) {
      map['counter_account_name'] = Variable<String>(counterAccountName.value);
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
    if (partyName.present) {
      map['party_name'] = Variable<String>(partyName.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (documentStatus.present) {
      map['document_status'] = Variable<String>(documentStatus.value);
    }
    if (relatedDocumentId.present) {
      map['related_document_id'] = Variable<String>(relatedDocumentId.value);
    }
    if (relatedDocumentType.present) {
      map['related_document_type'] = Variable<String>(
        relatedDocumentType.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (cancelledAt.present) {
      map['cancelled_at'] = Variable<int>(cancelledAt.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
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
    return (StringBuffer('FinancialTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('transactionNumber: $transactionNumber, ')
          ..write('transactionType: $transactionType, ')
          ..write('source: $source, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('amount: $amount, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('baseCurrencyCode: $baseCurrencyCode, ')
          ..write('exchangeRate: $exchangeRate, ')
          ..write('counterAmount: $counterAmount, ')
          ..write('counterCurrencyCode: $counterCurrencyCode, ')
          ..write('counterExchangeRate: $counterExchangeRate, ')
          ..write('linesJson: $linesJson, ')
          ..write('voucherBookId: $voucherBookId, ')
          ..write('cashAccountId: $cashAccountId, ')
          ..write('cashAccountCode: $cashAccountCode, ')
          ..write('cashAccountName: $cashAccountName, ')
          ..write('counterAccountId: $counterAccountId, ')
          ..write('counterAccountCode: $counterAccountCode, ')
          ..write('counterAccountName: $counterAccountName, ')
          ..write('customerId: $customerId, ')
          ..write('customerCode: $customerCode, ')
          ..write('customerName: $customerName, ')
          ..write('partyName: $partyName, ')
          ..write('reference: $reference, ')
          ..write('description: $description, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('documentStatus: $documentStatus, ')
          ..write('relatedDocumentId: $relatedDocumentId, ')
          ..write('relatedDocumentType: $relatedDocumentType, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cancelledAt: $cancelledAt, ')
          ..write('externalId: $externalId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$ReceiptsPaymentsDatabase extends GeneratedDatabase {
  _$ReceiptsPaymentsDatabase(QueryExecutor e) : super(e);
  $ReceiptsPaymentsDatabaseManager get managers =>
      $ReceiptsPaymentsDatabaseManager(this);
  late final $FinancialTransactionsTable financialTransactions =
      $FinancialTransactionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [financialTransactions];
}

typedef $$FinancialTransactionsTableCreateCompanionBuilder =
    FinancialTransactionsCompanion Function({
      Value<int> id,
      required String uuid,
      required String transactionNumber,
      required String transactionType,
      required String source,
      required int transactionDate,
      required double amount,
      Value<String> currencyCode,
      Value<String> baseCurrencyCode,
      Value<double> exchangeRate,
      Value<double> counterAmount,
      Value<String> counterCurrencyCode,
      Value<double> counterExchangeRate,
      Value<String?> linesJson,
      Value<String?> voucherBookId,
      required String cashAccountId,
      Value<String?> cashAccountCode,
      Value<String?> cashAccountName,
      required String counterAccountId,
      Value<String?> counterAccountCode,
      Value<String?> counterAccountName,
      Value<String?> customerId,
      Value<String?> customerCode,
      Value<String?> customerName,
      Value<String?> partyName,
      Value<String?> reference,
      Value<String?> description,
      Value<String> paymentMethod,
      Value<String> documentStatus,
      Value<String?> relatedDocumentId,
      Value<String?> relatedDocumentType,
      required int createdAt,
      required int updatedAt,
      Value<int?> cancelledAt,
      Value<String?> externalId,
      Value<String> syncStatus,
      Value<int?> lastSyncedAt,
      Value<int> version,
      Value<int?> deletedAt,
    });
typedef $$FinancialTransactionsTableUpdateCompanionBuilder =
    FinancialTransactionsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String> transactionNumber,
      Value<String> transactionType,
      Value<String> source,
      Value<int> transactionDate,
      Value<double> amount,
      Value<String> currencyCode,
      Value<String> baseCurrencyCode,
      Value<double> exchangeRate,
      Value<double> counterAmount,
      Value<String> counterCurrencyCode,
      Value<double> counterExchangeRate,
      Value<String?> linesJson,
      Value<String?> voucherBookId,
      Value<String> cashAccountId,
      Value<String?> cashAccountCode,
      Value<String?> cashAccountName,
      Value<String> counterAccountId,
      Value<String?> counterAccountCode,
      Value<String?> counterAccountName,
      Value<String?> customerId,
      Value<String?> customerCode,
      Value<String?> customerName,
      Value<String?> partyName,
      Value<String?> reference,
      Value<String?> description,
      Value<String> paymentMethod,
      Value<String> documentStatus,
      Value<String?> relatedDocumentId,
      Value<String?> relatedDocumentType,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> cancelledAt,
      Value<String?> externalId,
      Value<String> syncStatus,
      Value<int?> lastSyncedAt,
      Value<int> version,
      Value<int?> deletedAt,
    });

class $$FinancialTransactionsTableFilterComposer
    extends Composer<_$ReceiptsPaymentsDatabase, $FinancialTransactionsTable> {
  $$FinancialTransactionsTableFilterComposer({
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

  ColumnFilters<String> get transactionNumber => $composableBuilder(
    column: $table.transactionNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
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

  ColumnFilters<double> get counterAmount => $composableBuilder(
    column: $table.counterAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get counterCurrencyCode => $composableBuilder(
    column: $table.counterCurrencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get counterExchangeRate => $composableBuilder(
    column: $table.counterExchangeRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linesJson => $composableBuilder(
    column: $table.linesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voucherBookId => $composableBuilder(
    column: $table.voucherBookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cashAccountId => $composableBuilder(
    column: $table.cashAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cashAccountCode => $composableBuilder(
    column: $table.cashAccountCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cashAccountName => $composableBuilder(
    column: $table.cashAccountName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get counterAccountId => $composableBuilder(
    column: $table.counterAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get counterAccountCode => $composableBuilder(
    column: $table.counterAccountCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get counterAccountName => $composableBuilder(
    column: $table.counterAccountName,
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

  ColumnFilters<String> get partyName => $composableBuilder(
    column: $table.partyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentStatus => $composableBuilder(
    column: $table.documentStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relatedDocumentId => $composableBuilder(
    column: $table.relatedDocumentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relatedDocumentType => $composableBuilder(
    column: $table.relatedDocumentType,
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

  ColumnFilters<int> get cancelledAt => $composableBuilder(
    column: $table.cancelledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
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

class $$FinancialTransactionsTableOrderingComposer
    extends Composer<_$ReceiptsPaymentsDatabase, $FinancialTransactionsTable> {
  $$FinancialTransactionsTableOrderingComposer({
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

  ColumnOrderings<String> get transactionNumber => $composableBuilder(
    column: $table.transactionNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
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

  ColumnOrderings<double> get counterAmount => $composableBuilder(
    column: $table.counterAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get counterCurrencyCode => $composableBuilder(
    column: $table.counterCurrencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get counterExchangeRate => $composableBuilder(
    column: $table.counterExchangeRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linesJson => $composableBuilder(
    column: $table.linesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voucherBookId => $composableBuilder(
    column: $table.voucherBookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cashAccountId => $composableBuilder(
    column: $table.cashAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cashAccountCode => $composableBuilder(
    column: $table.cashAccountCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cashAccountName => $composableBuilder(
    column: $table.cashAccountName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get counterAccountId => $composableBuilder(
    column: $table.counterAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get counterAccountCode => $composableBuilder(
    column: $table.counterAccountCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get counterAccountName => $composableBuilder(
    column: $table.counterAccountName,
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

  ColumnOrderings<String> get partyName => $composableBuilder(
    column: $table.partyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentStatus => $composableBuilder(
    column: $table.documentStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relatedDocumentId => $composableBuilder(
    column: $table.relatedDocumentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relatedDocumentType => $composableBuilder(
    column: $table.relatedDocumentType,
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

  ColumnOrderings<int> get cancelledAt => $composableBuilder(
    column: $table.cancelledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
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

class $$FinancialTransactionsTableAnnotationComposer
    extends Composer<_$ReceiptsPaymentsDatabase, $FinancialTransactionsTable> {
  $$FinancialTransactionsTableAnnotationComposer({
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

  GeneratedColumn<String> get transactionNumber => $composableBuilder(
    column: $table.transactionNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

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

  GeneratedColumn<double> get counterAmount => $composableBuilder(
    column: $table.counterAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get counterCurrencyCode => $composableBuilder(
    column: $table.counterCurrencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<double> get counterExchangeRate => $composableBuilder(
    column: $table.counterExchangeRate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get linesJson =>
      $composableBuilder(column: $table.linesJson, builder: (column) => column);

  GeneratedColumn<String> get voucherBookId => $composableBuilder(
    column: $table.voucherBookId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cashAccountId => $composableBuilder(
    column: $table.cashAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cashAccountCode => $composableBuilder(
    column: $table.cashAccountCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cashAccountName => $composableBuilder(
    column: $table.cashAccountName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get counterAccountId => $composableBuilder(
    column: $table.counterAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get counterAccountCode => $composableBuilder(
    column: $table.counterAccountCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get counterAccountName => $composableBuilder(
    column: $table.counterAccountName,
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

  GeneratedColumn<String> get partyName =>
      $composableBuilder(column: $table.partyName, builder: (column) => column);

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get documentStatus => $composableBuilder(
    column: $table.documentStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relatedDocumentId => $composableBuilder(
    column: $table.relatedDocumentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relatedDocumentType => $composableBuilder(
    column: $table.relatedDocumentType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get cancelledAt => $composableBuilder(
    column: $table.cancelledAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
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

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$FinancialTransactionsTableTableManager
    extends
        RootTableManager<
          _$ReceiptsPaymentsDatabase,
          $FinancialTransactionsTable,
          FinancialTransactionRow,
          $$FinancialTransactionsTableFilterComposer,
          $$FinancialTransactionsTableOrderingComposer,
          $$FinancialTransactionsTableAnnotationComposer,
          $$FinancialTransactionsTableCreateCompanionBuilder,
          $$FinancialTransactionsTableUpdateCompanionBuilder,
          (
            FinancialTransactionRow,
            BaseReferences<
              _$ReceiptsPaymentsDatabase,
              $FinancialTransactionsTable,
              FinancialTransactionRow
            >,
          ),
          FinancialTransactionRow,
          PrefetchHooks Function()
        > {
  $$FinancialTransactionsTableTableManager(
    _$ReceiptsPaymentsDatabase db,
    $FinancialTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FinancialTransactionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$FinancialTransactionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$FinancialTransactionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> transactionNumber = const Value.absent(),
                Value<String> transactionType = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> transactionDate = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String> baseCurrencyCode = const Value.absent(),
                Value<double> exchangeRate = const Value.absent(),
                Value<double> counterAmount = const Value.absent(),
                Value<String> counterCurrencyCode = const Value.absent(),
                Value<double> counterExchangeRate = const Value.absent(),
                Value<String?> linesJson = const Value.absent(),
                Value<String?> voucherBookId = const Value.absent(),
                Value<String> cashAccountId = const Value.absent(),
                Value<String?> cashAccountCode = const Value.absent(),
                Value<String?> cashAccountName = const Value.absent(),
                Value<String> counterAccountId = const Value.absent(),
                Value<String?> counterAccountCode = const Value.absent(),
                Value<String?> counterAccountName = const Value.absent(),
                Value<String?> customerId = const Value.absent(),
                Value<String?> customerCode = const Value.absent(),
                Value<String?> customerName = const Value.absent(),
                Value<String?> partyName = const Value.absent(),
                Value<String?> reference = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<String> documentStatus = const Value.absent(),
                Value<String?> relatedDocumentId = const Value.absent(),
                Value<String?> relatedDocumentType = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> cancelledAt = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => FinancialTransactionsCompanion(
                id: id,
                uuid: uuid,
                transactionNumber: transactionNumber,
                transactionType: transactionType,
                source: source,
                transactionDate: transactionDate,
                amount: amount,
                currencyCode: currencyCode,
                baseCurrencyCode: baseCurrencyCode,
                exchangeRate: exchangeRate,
                counterAmount: counterAmount,
                counterCurrencyCode: counterCurrencyCode,
                counterExchangeRate: counterExchangeRate,
                linesJson: linesJson,
                voucherBookId: voucherBookId,
                cashAccountId: cashAccountId,
                cashAccountCode: cashAccountCode,
                cashAccountName: cashAccountName,
                counterAccountId: counterAccountId,
                counterAccountCode: counterAccountCode,
                counterAccountName: counterAccountName,
                customerId: customerId,
                customerCode: customerCode,
                customerName: customerName,
                partyName: partyName,
                reference: reference,
                description: description,
                paymentMethod: paymentMethod,
                documentStatus: documentStatus,
                relatedDocumentId: relatedDocumentId,
                relatedDocumentType: relatedDocumentType,
                createdAt: createdAt,
                updatedAt: updatedAt,
                cancelledAt: cancelledAt,
                externalId: externalId,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                version: version,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required String transactionNumber,
                required String transactionType,
                required String source,
                required int transactionDate,
                required double amount,
                Value<String> currencyCode = const Value.absent(),
                Value<String> baseCurrencyCode = const Value.absent(),
                Value<double> exchangeRate = const Value.absent(),
                Value<double> counterAmount = const Value.absent(),
                Value<String> counterCurrencyCode = const Value.absent(),
                Value<double> counterExchangeRate = const Value.absent(),
                Value<String?> linesJson = const Value.absent(),
                Value<String?> voucherBookId = const Value.absent(),
                required String cashAccountId,
                Value<String?> cashAccountCode = const Value.absent(),
                Value<String?> cashAccountName = const Value.absent(),
                required String counterAccountId,
                Value<String?> counterAccountCode = const Value.absent(),
                Value<String?> counterAccountName = const Value.absent(),
                Value<String?> customerId = const Value.absent(),
                Value<String?> customerCode = const Value.absent(),
                Value<String?> customerName = const Value.absent(),
                Value<String?> partyName = const Value.absent(),
                Value<String?> reference = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<String> documentStatus = const Value.absent(),
                Value<String?> relatedDocumentId = const Value.absent(),
                Value<String?> relatedDocumentType = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> cancelledAt = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => FinancialTransactionsCompanion.insert(
                id: id,
                uuid: uuid,
                transactionNumber: transactionNumber,
                transactionType: transactionType,
                source: source,
                transactionDate: transactionDate,
                amount: amount,
                currencyCode: currencyCode,
                baseCurrencyCode: baseCurrencyCode,
                exchangeRate: exchangeRate,
                counterAmount: counterAmount,
                counterCurrencyCode: counterCurrencyCode,
                counterExchangeRate: counterExchangeRate,
                linesJson: linesJson,
                voucherBookId: voucherBookId,
                cashAccountId: cashAccountId,
                cashAccountCode: cashAccountCode,
                cashAccountName: cashAccountName,
                counterAccountId: counterAccountId,
                counterAccountCode: counterAccountCode,
                counterAccountName: counterAccountName,
                customerId: customerId,
                customerCode: customerCode,
                customerName: customerName,
                partyName: partyName,
                reference: reference,
                description: description,
                paymentMethod: paymentMethod,
                documentStatus: documentStatus,
                relatedDocumentId: relatedDocumentId,
                relatedDocumentType: relatedDocumentType,
                createdAt: createdAt,
                updatedAt: updatedAt,
                cancelledAt: cancelledAt,
                externalId: externalId,
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

typedef $$FinancialTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$ReceiptsPaymentsDatabase,
      $FinancialTransactionsTable,
      FinancialTransactionRow,
      $$FinancialTransactionsTableFilterComposer,
      $$FinancialTransactionsTableOrderingComposer,
      $$FinancialTransactionsTableAnnotationComposer,
      $$FinancialTransactionsTableCreateCompanionBuilder,
      $$FinancialTransactionsTableUpdateCompanionBuilder,
      (
        FinancialTransactionRow,
        BaseReferences<
          _$ReceiptsPaymentsDatabase,
          $FinancialTransactionsTable,
          FinancialTransactionRow
        >,
      ),
      FinancialTransactionRow,
      PrefetchHooks Function()
    >;

class $ReceiptsPaymentsDatabaseManager {
  final _$ReceiptsPaymentsDatabase _db;
  $ReceiptsPaymentsDatabaseManager(this._db);
  $$FinancialTransactionsTableTableManager get financialTransactions =>
      $$FinancialTransactionsTableTableManager(_db, _db.financialTransactions);
}
