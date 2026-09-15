import 'package:drift/drift.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import '../../domain/account/account_currency_policy.dart';
import '../../domain/account/financial_account.dart';
import '../../domain/exchange_rate/exchange_rate_snapshot.dart';
import '../../domain/journal/financial_side.dart';
import '../../domain/journal/journal_entry.dart';
import '../../domain/journal/journal_line.dart';
import '../../domain/journal/journal_status.dart';
import '../../domain/money/decimal_money.dart';
import '../../domain/money/decimal_rate.dart';
import '../../domain/subject/accounting_subject.dart';
import '../../domain/subject/subject_account_bucket.dart';
import '../repositories/exchange_rate_repository.dart';
import '../repositories/financial_account_repository.dart';
import '../repositories/financial_journal_repository.dart';
import '../repositories/financial_subject_repository.dart';
import '../../domain/common/financial_exceptions.dart';
import '../../validation/financial_int64_boundary.dart';

/// Drift implementation of [FinancialAccountRepository].
class DriftFinancialAccountRepository implements FinancialAccountRepository {
  final NexabizDatabase db;

  DriftFinancialAccountRepository(this.db);

  @override
  Future<void> saveAccount(FinancialAccount account) async {
    await db.into(db.financialAccounts).insertOnConflictUpdate(
          FinancialAccountsCompanion.insert(
            id: Value(account.id),
            companyId: account.companyId,
            code: account.code,
            nameAr: Value(account.nameAr),
            nameEn: Value(account.nameEn),
            accountType: account.accountType.toDbValue(),
            currencyPolicy: account.currencyPolicy.toDbValue(),
            fixedCurrencyCode: Value(account.fixedCurrencyCode),
            parentAccountId: Value(account.parentAccountId),
            level: Value(account.level),
            isGroup: Value(account.isGroup),
            isSystemAccount: Value(account.isSystemAccount),
            isActive: Value(account.isActive),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  @override
  Future<FinancialAccount?> findById(String companyId, String id) async {
    final query = db.select(db.financialAccounts)
      ..where((t) => t.companyId.equals(companyId) & t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _mapAccount(row);
  }

  @override
  Future<FinancialAccount?> findByCode(String companyId, String code) async {
    final query = db.select(db.financialAccounts)
      ..where((t) => t.companyId.equals(companyId) & t.code.equals(code));
    final row = await query.getSingleOrNull();
    return row == null ? null : _mapAccount(row);
  }

  @override
  Future<List<FinancialAccount>> findChildren(String companyId, String parentAccountId) async {
    final query = db.select(db.financialAccounts)
      ..where((t) => t.companyId.equals(companyId) & t.parentAccountId.equals(parentAccountId));
    final rows = await query.get();
    return rows.map(_mapAccount).toList();
  }

  @override
  Future<List<FinancialAccount>> getCompanyAccounts(String companyId) async {
    final query = db.select(db.financialAccounts)
      ..where((t) => t.companyId.equals(companyId));
    final rows = await query.get();
    return rows.map(_mapAccount).toList();
  }

  FinancialAccount _mapAccount(FinancialAccountData data) {
    return FinancialAccount(
      id: data.id,
      companyId: data.companyId,
      code: data.code,
      nameAr: data.nameAr,
      nameEn: data.nameEn,
      accountType: FinancialAccountType.fromString(data.accountType),
      currencyPolicy: AccountCurrencyPolicy.fromString(data.currencyPolicy),
      fixedCurrencyCode: data.fixedCurrencyCode,
      parentAccountId: data.parentAccountId,
      level: data.level,
      isGroup: data.isGroup,
      isSystemAccount: data.isSystemAccount,
      isActive: data.isActive,
    );
  }
}

/// Drift implementation of [FinancialSubjectRepository].
class DriftFinancialSubjectRepository implements FinancialSubjectRepository {
  final NexabizDatabase db;

  DriftFinancialSubjectRepository(this.db);

  @override
  Future<void> saveSubject(AccountingSubject subject) async {
    await db.into(db.financialSubjects).insertOnConflictUpdate(
          FinancialSubjectsCompanion.insert(
            id: Value(subject.id),
            companyId: subject.companyId,
            subjectType: subject.subjectType.toDbValue(),
            name: subject.name,
            code: subject.code,
            primaryAccountId: subject.primaryAccountId,
            isActive: Value(subject.isActive),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  @override
  Future<AccountingSubject?> findSubjectById(String companyId, String id) async {
    final query = db.select(db.financialSubjects)
      ..where((t) => t.companyId.equals(companyId) & t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _mapSubject(row);
  }

  @override
  Future<AccountingSubject?> findSubjectByCode(
    String companyId,
    AccountingSubjectType subjectType,
    String code,
  ) async {
    final query = db.select(db.financialSubjects)
      ..where(
        (t) =>
            t.companyId.equals(companyId) &
            t.subjectType.equals(subjectType.toDbValue()) &
            t.code.equals(code),
      );
    final row = await query.getSingleOrNull();
    return row == null ? null : _mapSubject(row);
  }

  @override
  Future<AccountingSubject?> findSubjectByPrimaryAccountId(String companyId, String accountId) async {
    final query = db.select(db.financialSubjects)
      ..where((t) => t.companyId.equals(companyId) & t.primaryAccountId.equals(accountId));
    final row = await query.getSingleOrNull();
    return row == null ? null : _mapSubject(row);
  }

  @override
  Future<SubjectAccountBucket?> getBucket({
    required String companyId,
    required String subjectId,
    required String accountId,
    required String currencyCode,
  }) async {
    final query = db.select(db.financialSubjectAccountBuckets)
      ..where(
        (t) =>
            t.companyId.equals(companyId) &
            t.subjectId.equals(subjectId) &
            t.accountId.equals(accountId) &
            t.currencyCode.equals(currencyCode.toUpperCase()),
      );
    final row = await query.getSingleOrNull();
    return row == null ? null : _mapBucket(row);
  }

  @override
  Future<void> updateBucketBalance(SubjectAccountBucket bucket) async {
    FinancialInt64Boundary.check(bucket.balance.unitsScaled, 'bucket.balanceScaled');
    await db.into(db.financialSubjectAccountBuckets).insertOnConflictUpdate(
          FinancialSubjectAccountBucketsCompanion.insert(
            id: Value(bucket.id),
            companyId: bucket.companyId,
            subjectId: bucket.subjectId,
            accountId: bucket.accountId,
            currencyCode: bucket.currencyCode.toUpperCase(),
            balanceScaled: Value(bucket.balance.unitsScaled),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  AccountingSubject _mapSubject(FinancialSubjectData data) {
    return AccountingSubject(
      id: data.id,
      companyId: data.companyId,
      subjectType: AccountingSubjectType.fromString(data.subjectType),
      name: data.name,
      code: data.code,
      primaryAccountId: data.primaryAccountId,
      isActive: data.isActive,
    );
  }

  SubjectAccountBucket _mapBucket(FinancialSubjectAccountBucketData data) {
    return SubjectAccountBucket(
      id: data.id,
      companyId: data.companyId,
      subjectId: data.subjectId,
      accountId: data.accountId,
      currencyCode: data.currencyCode,
      balance: DecimalMoney.fromScaled(data.balanceScaled, data.currencyCode),
    );
  }
}

/// Drift implementation of [ExchangeRateRepository].
class DriftExchangeRateRepository implements ExchangeRateRepository {
  final NexabizDatabase db;

  DriftExchangeRateRepository(this.db);

  @override
  Future<void> saveRate({
    required String companyId,
    required DecimalRate rate,
    required DateTime effectiveAt,
    String source = 'manual',
    bool isImmutableSnapshot = true,
  }) async {
    FinancialInt64Boundary.check(rate.rateScaled, 'rate.rateScaled');
    await db.into(db.financialExchangeRates).insertOnConflictUpdate(
          FinancialExchangeRatesCompanion.insert(
            companyId: companyId,
            fromCurrencyCode: rate.fromCurrencyCode,
            toCurrencyCode: rate.toCurrencyCode,
            rateScaled: rate.rateScaled,
            effectiveAt: effectiveAt,
            source: Value(source),
            isImmutableSnapshot: Value(isImmutableSnapshot),
          ),
        );
  }

  @override
  Future<ExchangeRateSnapshot?> getLatestRate({
    required String companyId,
    required String fromCurrencyCode,
    required String toCurrencyCode,
  }) async {
    final from = fromCurrencyCode.toUpperCase();
    final to = toCurrencyCode.toUpperCase();

    if (from == to) {
      final identity = DecimalRate.identity(from);
      return ExchangeRateSnapshot(
        id: 'identity_${from}_$to',
        companyId: companyId,
        fromCurrencyCode: from,
        toCurrencyCode: to,
        rate: identity,
        effectiveAt: DateTime.now(),
        source: 'system_identity',
        isImmutableSnapshot: true,
      );
    }

    final query = db.select(db.financialExchangeRates)
      ..where(
        (t) =>
            t.companyId.equals(companyId) &
            t.fromCurrencyCode.equals(from) &
            t.toCurrencyCode.equals(to),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.effectiveAt)])
      ..limit(1);

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final decRate = DecimalRate.fromScaled(
      rateScaled: row.rateScaled,
      fromCurrencyCode: row.fromCurrencyCode,
      toCurrencyCode: row.toCurrencyCode,
    );

    return ExchangeRateSnapshot(
      id: row.id,
      companyId: row.companyId,
      fromCurrencyCode: row.fromCurrencyCode,
      toCurrencyCode: row.toCurrencyCode,
      rate: decRate,
      effectiveAt: row.effectiveAt,
      source: row.source,
      isImmutableSnapshot: row.isImmutableSnapshot,
    );
  }
}

/// Drift implementation of [FinancialJournalRepository].
class DriftFinancialJournalRepository implements FinancialJournalRepository {
  final NexabizDatabase db;

  DriftFinancialJournalRepository(this.db);

  @override
  Future<void> saveEntry(JournalEntry entry) async {
    // Check if entry already exists in persistence layer and is posted
    final existingRow = await (db.select(db.financialJournalEntries)
          ..where((t) => t.companyId.equals(entry.companyId) & t.id.equals(entry.id)))
        .getSingleOrNull();

    if (existingRow != null && existingRow.status == JournalStatus.posted.toDbValue()) {
      throw PostedJournalImmutableException(entry.id);
    }

    // Validate Int64 boundary and transitive tenancy on all line monetary/rate fields
    for (final line in entry.lines) {
      if (line.companyId != entry.companyId) {
        throw FinancialValidationException(
          'Transitive tenancy violation: journal line companyId does not match entry companyId',
          'TENANCY_VIOLATION',
        );
      }
      FinancialInt64Boundary.check(line.transactionAmount.unitsScaled, 'line.transactionAmountScaled');
      FinancialInt64Boundary.check(line.exchangeRate.rateScaled, 'line.exchangeRateScaled');
      FinancialInt64Boundary.check(line.baseAmount.unitsScaled, 'line.baseAmountScaled');
    }

    await db.transaction(() async {
      await db.into(db.financialJournalEntries).insertOnConflictUpdate(
            FinancialJournalEntriesCompanion.insert(
              id: Value(entry.id),
              companyId: entry.companyId,
              entryNumber: entry.entryNumber,
              baseCurrencyCode: entry.baseCurrencyCode,
              postingDate: entry.postingDate,
              status: Value(entry.status.toDbValue()),
              description: Value(entry.description),
              sourceModule: Value(entry.sourceModule),
              sourceDocumentId: Value(entry.sourceDocumentId),
              postedAt: Value(entry.postedAt),
              createdById: Value(entry.createdById),
            ),
          );

      // Save journal lines
      for (final line in entry.lines) {
        await db.into(db.financialJournalLines).insertOnConflictUpdate(
              FinancialJournalLinesCompanion.insert(
                id: Value(line.id),
                companyId: line.companyId,
                journalEntryId: line.journalEntryId,
                lineNumber: line.lineNumber,
                accountId: line.accountId,
                side: line.side.toDbValue(),
                transactionCurrencyCode: line.transactionAmount.currencyCode,
                transactionAmountScaled: line.transactionAmount.unitsScaled,
                exchangeRateScaled: line.exchangeRate.rateScaled,
                baseAmountScaled: line.baseAmount.unitsScaled,
                description: Value(line.description),
                subjectId: Value(line.subjectId),
              ),
            );
      }
    });
  }

  @override
  Future<JournalEntry?> findById(String companyId, String id) async {
    final entryQuery = db.select(db.financialJournalEntries)
      ..where((t) => t.companyId.equals(companyId) & t.id.equals(id));
    final entryRow = await entryQuery.getSingleOrNull();
    if (entryRow == null) return null;

    final linesQuery = db.select(db.financialJournalLines)
      ..where((t) => t.companyId.equals(companyId) & t.journalEntryId.equals(id))
      ..orderBy([(t) => OrderingTerm.asc(t.lineNumber)]);
    final lineRows = await linesQuery.get();

    return _mapJournalEntry(entryRow, lineRows);
  }

  @override
  Future<JournalEntry?> findByNumber(String companyId, String entryNumber) async {
    final entryQuery = db.select(db.financialJournalEntries)
      ..where((t) => t.companyId.equals(companyId) & t.entryNumber.equals(entryNumber));
    final entryRow = await entryQuery.getSingleOrNull();
    if (entryRow == null) return null;

    final linesQuery = db.select(db.financialJournalLines)
      ..where((t) => t.companyId.equals(companyId) & t.journalEntryId.equals(entryRow.id))
      ..orderBy([(t) => OrderingTerm.asc(t.lineNumber)]);
    final lineRows = await linesQuery.get();

    return _mapJournalEntry(entryRow, lineRows);
  }

  @override
  Future<JournalEntry?> findBySourceDocument({
    required String companyId,
    required String sourceModule,
    required String sourceDocumentId,
  }) async {
    final entryQuery = db.select(db.financialJournalEntries)
      ..where(
        (t) =>
            t.companyId.equals(companyId) &
            t.sourceModule.equals(sourceModule) &
            t.sourceDocumentId.equals(sourceDocumentId),
      );
    final entryRow = await entryQuery.getSingleOrNull();
    if (entryRow == null) return null;

    final linesQuery = db.select(db.financialJournalLines)
      ..where((t) => t.companyId.equals(companyId) & t.journalEntryId.equals(entryRow.id))
      ..orderBy([(t) => OrderingTerm.asc(t.lineNumber)]);
    final lineRows = await linesQuery.get();

    return _mapJournalEntry(entryRow, lineRows);
  }

  @override
  Future<List<JournalEntry>> getCompanyEntries(String companyId) async {
    final entryQuery = db.select(db.financialJournalEntries)
      ..where((t) => t.companyId.equals(companyId))
      ..orderBy([(t) => OrderingTerm.desc(t.postingDate)]);
    final entryRows = await entryQuery.get();

    final result = <JournalEntry>[];
    for (final entryRow in entryRows) {
      final linesQuery = db.select(db.financialJournalLines)
        ..where((t) => t.companyId.equals(companyId) & t.journalEntryId.equals(entryRow.id))
        ..orderBy([(t) => OrderingTerm.asc(t.lineNumber)]);
      final lineRows = await linesQuery.get();
      result.add(_mapJournalEntry(entryRow, lineRows));
    }
    return result;
  }

  JournalEntry _mapJournalEntry(
    FinancialJournalEntryData data,
    List<FinancialJournalLineData> lineDatas,
  ) {
    final lines = lineDatas.map((l) {
      final txAmount = DecimalMoney.fromScaled(l.transactionAmountScaled, l.transactionCurrencyCode);
      final rate = DecimalRate.fromScaled(
        rateScaled: l.exchangeRateScaled,
        fromCurrencyCode: l.transactionCurrencyCode,
        toCurrencyCode: data.baseCurrencyCode,
      );
      final baseAmount = DecimalMoney.fromScaled(l.baseAmountScaled, data.baseCurrencyCode);

      return JournalLine(
        id: l.id,
        companyId: l.companyId,
        journalEntryId: l.journalEntryId,
        lineNumber: l.lineNumber,
        accountId: l.accountId,
        side: FinancialSide.fromString(l.side),
        transactionAmount: txAmount,
        exchangeRate: rate,
        baseAmount: baseAmount,
        description: l.description,
        subjectId: l.subjectId,
      );
    }).toList();

    return JournalEntry(
      id: data.id,
      companyId: data.companyId,
      entryNumber: data.entryNumber,
      baseCurrencyCode: data.baseCurrencyCode,
      postingDate: data.postingDate,
      status: JournalStatus.fromString(data.status),
      description: data.description,
      sourceModule: data.sourceModule,
      sourceDocumentId: data.sourceDocumentId,
      postedAt: data.postedAt,
      createdById: data.createdById,
      lines: lines,
    );
  }
}
