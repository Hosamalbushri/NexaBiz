import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/settings/company/company_profile_providers.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import '../../data/datasources/account_excel_import_datasource.dart';
import '../../data/datasources/opening_balance_excel_datasource.dart';
import '../../domain/entities/account.dart';
import '../../domain/models/account_exception.dart';
import '../../domain/models/account_import_row.dart';
import '../../domain/models/opening_balance_line.dart';
import '../../domain/services/account_import_opening_journal.dart';
import 'account_providers.dart';
import 'package:stock_count/modules/accounting/journals/presentation/providers/journal_providers.dart';

class AccountOpeningSetupState {
  const AccountOpeningSetupState({
    this.stepIndex = 0,
    this.parent,
    this.importRows = const [],
    this.importFileName,
    this.balanceLines = const [],
    this.balanceFileName,
    this.isBusy = false,
    this.progress = 0,
    this.importResult,
    this.postResult,
    this.errorCode,
    this.errorDetails,
  });

  final int stepIndex;
  final Account? parent;
  final List<AccountImportRow> importRows;
  final String? importFileName;
  final List<OpeningBalanceLine> balanceLines;
  final String? balanceFileName;
  final bool isBusy;
  final double progress;
  final AccountImportResult? importResult;
  final bool? postResult;
  final String? errorCode;
  final String? errorDetails;

  bool get canImportAccounts =>
      parent != null &&
      parent!.isGroup &&
      importRows.any((r) => r.hasName) &&
      !isBusy;

  bool get canPostOpening =>
      balanceLines.any((l) => l.hasAmount) && !isBusy;

  List<OpeningBalanceCurrencySummary> currencySummaries(
    String defaultCurrencyCode,
  ) {
    return AccountImportOpeningJournal.summarize(
      balanceLines,
      defaultCurrencyCode: defaultCurrencyCode,
    );
  }

  AccountOpeningSetupState copyWith({
    int? stepIndex,
    Account? parent,
    bool clearParent = false,
    List<AccountImportRow>? importRows,
    String? importFileName,
    bool clearImportFileName = false,
    List<OpeningBalanceLine>? balanceLines,
    String? balanceFileName,
    bool clearBalanceFileName = false,
    bool? isBusy,
    double? progress,
    AccountImportResult? importResult,
    bool clearImportResult = false,
    bool? postResult,
    bool clearPostResult = false,
    String? errorCode,
    String? errorDetails,
    bool clearError = false,
  }) {
    return AccountOpeningSetupState(
      stepIndex: stepIndex ?? this.stepIndex,
      parent: clearParent ? null : (parent ?? this.parent),
      importRows: importRows ?? this.importRows,
      importFileName: clearImportFileName
          ? null
          : (importFileName ?? this.importFileName),
      balanceLines: balanceLines ?? this.balanceLines,
      balanceFileName: clearBalanceFileName
          ? null
          : (balanceFileName ?? this.balanceFileName),
      isBusy: isBusy ?? this.isBusy,
      progress: progress ?? this.progress,
      importResult:
          clearImportResult ? null : (importResult ?? this.importResult),
      postResult: clearPostResult ? null : (postResult ?? this.postResult),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      errorDetails: clearError ? null : (errorDetails ?? this.errorDetails),
    );
  }
}

class AccountOpeningSetupNotifier
    extends StateNotifier<AccountOpeningSetupState> {
  AccountOpeningSetupNotifier(this._ref)
      : super(const AccountOpeningSetupState());

  final Ref _ref;
  final _accountExcel = const AccountExcelImportDatasource();
  final _balanceExcel = const OpeningBalanceExcelDatasource();

  void setStep(int index) {
    state = state.copyWith(
      stepIndex: index.clamp(0, 2),
      clearError: true,
    );
  }

  void setParent(Account? parent) {
    state = state.copyWith(
      parent: parent,
      clearParent: parent == null,
      clearError: true,
      clearImportResult: true,
    );
  }

  void addImportRow() {
    state = state.copyWith(
      importRows: [
        ...state.importRows,
        AccountImportRow(id: generateUuidV4()),
      ],
      clearError: true,
      clearImportResult: true,
    );
  }

  void updateImportRow(AccountImportRow row) {
    state = state.copyWith(
      importRows: [
        for (final existing in state.importRows)
          if (existing.id == row.id) row else existing,
      ],
      clearError: true,
      clearImportResult: true,
    );
  }

  void removeImportRow(String id) {
    state = state.copyWith(
      importRows: [
        for (final row in state.importRows)
          if (row.id != id) row,
      ],
      clearError: true,
      clearImportResult: true,
    );
  }

  void clearImportRows() {
    state = state.copyWith(
      importRows: const [],
      clearImportFileName: true,
      clearError: true,
      clearImportResult: true,
    );
  }

  void loadImportExcel({required String fileName, required Uint8List bytes}) {
    try {
      final parsed = _accountExcel.parseBytes(bytes);
      state = state.copyWith(
        importFileName: fileName,
        importRows: parsed.rows,
        clearError: true,
        clearImportResult: true,
      );
    } on AccountImportException catch (e) {
      state = state.copyWith(
        errorCode: e.code,
        errorDetails: e.message,
        clearImportResult: true,
      );
    } catch (e) {
      state = state.copyWith(
        errorCode: AccountImportException.decodeFailed,
        errorDetails: e.toString(),
        clearImportResult: true,
      );
    }
  }

  /// Creates accounts under [parent] and seeds empty balance slots for them.
  Future<AccountImportResult?> importAccounts() async {
    if (state.isBusy) {
      return null;
    }

    final parent = state.parent;
    if (parent == null || !parent.isGroup) {
      state = state.copyWith(
        errorCode: parent == null
            ? AccountImportException.parentRequired
            : AccountImportException.parentNotGroup,
        clearImportResult: true,
      );
      return null;
    }

    final candidates = state.importRows.where((r) => r.hasName).toList();
    if (candidates.isEmpty) {
      state = state.copyWith(
        errorCode: AccountImportException.noRows,
        clearImportResult: true,
      );
      return null;
    }

    state = state.copyWith(
      isBusy: true,
      progress: 0.05,
      clearError: true,
      clearImportResult: true,
    );

    try {
      final create = _ref.read(createAccountUseCaseProvider);
      final repo = _ref.read(accountRepositoryProvider);
      final codeGen = _ref.read(accountCodeGeneratorProvider);
      await repo.ensureDefaultChartSeeded();

      final created = <Account>[];
      var inserted = 0;
      var skipped = 0;

      for (var i = 0; i < candidates.length; i++) {
        final row = candidates[i];
        state = state.copyWith(
          progress: 0.05 + (0.9 * (i + 1) / candidates.length),
        );

        var code = row.code.trim();
        if (code.isEmpty) {
          code = await codeGen.generate(
            parentAccountCode: parent.accountCode,
            parentAccountId: parent.uuid,
          );
        }

        final existing = await repo.getByAccountCode(code);
        if (existing != null) {
          skipped++;
          continue;
        }

        try {
          final account = await create(
            AccountDraft(
              parentId: parent.uuid,
              accountCode: code,
              name: row.name.trim(),
              accountType: parent.accountType,
              isGroup: false,
            ),
          );
          inserted++;
          created.add(account);
        } on AccountException catch (e) {
          if (e.code == AccountException.duplicateAccountCode) {
            skipped++;
            continue;
          }
          rethrow;
        }
      }

      final defaultCurrency = _ref
              .read(companyProfileProvider)
              .valueOrNull
              ?.defaultCurrencyCode
              .trim()
              .toUpperCase() ??
          'SAR';

      final seeded = <OpeningBalanceLine>[
        ...state.balanceLines,
        for (final account in created)
          if (!state.balanceLines.any((l) => l.accountId == account.uuid))
            OpeningBalanceLine.forAccount(
              accountId: account.uuid,
              accountCode: account.accountCode,
              accountName: account.name,
              currencyCode: defaultCurrency,
            ),
      ];

      final result = AccountImportResult(
        insertedCount: inserted,
        skippedCount: skipped,
      );
      state = state.copyWith(
        isBusy: false,
        progress: 1,
        importResult: result,
        importRows: inserted > 0 ? const [] : state.importRows,
        clearImportFileName: inserted > 0,
        balanceLines: seeded,
        stepIndex: inserted > 0 ? 1 : state.stepIndex,
      );
      return result;
    } on AccountImportException catch (e) {
      state = state.copyWith(
        isBusy: false,
        errorCode: e.code,
        errorDetails: e.message,
        clearImportResult: true,
      );
      return null;
    } on AccountException catch (e) {
      state = state.copyWith(
        isBusy: false,
        errorCode: e.code,
        errorDetails: e.message,
        clearImportResult: true,
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        errorCode: 'unexpected',
        errorDetails: e.toString(),
        clearImportResult: true,
      );
      return null;
    }
  }

  void addAccountToBalances(
    Account account, {
    required String defaultCurrencyCode,
  }) {
    if (!account.canPost) {
      return;
    }
    final currency = defaultCurrencyCode.trim().toUpperCase();
    final duplicate = state.balanceLines.any(
      (l) =>
          l.accountId == account.uuid &&
          l.currencyCode.trim().toUpperCase() == currency,
    );
    if (duplicate) {
      state = state.copyWith(
        errorCode: AccountImportException.duplicateCurrency,
        errorDetails: account.name,
        clearPostResult: true,
      );
      return;
    }
    state = state.copyWith(
      balanceLines: [
        ...state.balanceLines,
        OpeningBalanceLine.forAccount(
          accountId: account.uuid,
          accountCode: account.accountCode,
          accountName: account.name,
          currencyCode: currency,
        ),
      ],
      clearError: true,
      clearPostResult: true,
    );
  }

  void addBlankBalanceLine({required String defaultCurrencyCode}) {
    state = state.copyWith(
      balanceLines: [
        ...state.balanceLines,
        OpeningBalanceLine.forAccount(
          accountId: '',
          accountCode: '',
          accountName: '',
          currencyCode: defaultCurrencyCode.trim().toUpperCase(),
        ),
      ],
      clearError: true,
      clearPostResult: true,
    );
  }

  void addBalanceLine({
    required String accountId,
    required String accountCode,
    required String accountName,
    String currencyCode = '',
  }) {
    final currency = currencyCode.trim().toUpperCase();
    if (accountId.trim().isEmpty) {
      state = state.copyWith(
        errorCode: AccountImportException.accountRequired,
        clearPostResult: true,
      );
      return;
    }
    final duplicate = state.balanceLines.any(
      (l) =>
          l.accountId == accountId &&
          l.currencyCode.trim().toUpperCase() == currency,
    );
    if (duplicate) {
      state = state.copyWith(
        errorCode: AccountImportException.duplicateCurrency,
        errorDetails: accountName,
        clearPostResult: true,
      );
      return;
    }
    state = state.copyWith(
      balanceLines: [
        ...state.balanceLines,
        OpeningBalanceLine.forAccount(
          accountId: accountId,
          accountCode: accountCode,
          accountName: accountName,
          currencyCode: currency,
        ),
      ],
      clearError: true,
      clearPostResult: true,
    );
  }

  /// Adds the next unused configured currency for an account.
  void addNextCurrencyLine({
    required String accountId,
    required String accountCode,
    required String accountName,
    required List<String> allowedCurrencyCodes,
    required String defaultCurrencyCode,
  }) {
    final fallback = defaultCurrencyCode.trim().toUpperCase();
    final allowed = <String>[
      if (fallback.isNotEmpty) fallback,
      for (final code in allowedCurrencyCodes)
        if (code.trim().toUpperCase() != fallback) code.trim().toUpperCase(),
    ];
    final used = {
      for (final line in state.balanceLines)
        if (line.accountId == accountId)
          line.currencyCode.trim().toUpperCase(),
    };
    String? next;
    for (final code in allowed) {
      if (!used.contains(code)) {
        next = code;
        break;
      }
    }
    if (next == null || next.isEmpty) {
      state = state.copyWith(
        errorCode: AccountImportException.duplicateCurrency,
        errorDetails: accountName,
        clearPostResult: true,
      );
      return;
    }
    addBalanceLine(
      accountId: accountId,
      accountCode: accountCode,
      accountName: accountName,
      currencyCode: next,
    );
  }

  void updateBalanceLine(OpeningBalanceLine line) {
    if (line.hasBothSides) {
      state = state.copyWith(
        errorCode: AccountImportException.bothOpeningSides,
        errorDetails: line.accountName,
        clearPostResult: true,
      );
      return;
    }
    final currency = line.currencyCode.trim().toUpperCase();
    if (line.accountId.trim().isNotEmpty) {
      final duplicate = state.balanceLines.any(
        (l) =>
            l.id != line.id &&
            l.accountId == line.accountId &&
            l.currencyCode.trim().toUpperCase() == currency,
      );
      if (duplicate) {
        state = state.copyWith(
          errorCode: AccountImportException.duplicateCurrency,
          errorDetails: line.accountName,
          clearPostResult: true,
        );
        return;
      }
    }
    state = state.copyWith(
      balanceLines: [
        for (final existing in state.balanceLines)
          if (existing.id == line.id) line else existing,
      ],
      clearError: true,
      clearPostResult: true,
    );
  }

  void removeBalanceLine(String id) {
    state = state.copyWith(
      balanceLines: [
        for (final line in state.balanceLines)
          if (line.id != id) line,
      ],
      clearError: true,
      clearPostResult: true,
    );
  }

  void removeAccountBalances(String accountId) {
    state = state.copyWith(
      balanceLines: [
        for (final line in state.balanceLines)
          if (line.accountId != accountId) line,
      ],
      clearError: true,
      clearPostResult: true,
    );
  }

  Future<void> loadBalanceExcel({
    required String fileName,
    required Uint8List bytes,
    required Set<String> allowedCurrencyCodes,
    required String defaultCurrencyCode,
  }) async {
    try {
      final allowed = {
        for (final code in allowedCurrencyCodes) code.trim().toUpperCase(),
      };
      final fallback = defaultCurrencyCode.trim().toUpperCase();
      if (fallback.isNotEmpty) {
        allowed.add(fallback);
      }

      final parsed = _balanceExcel.parseBytes(bytes);
      final repo = _ref.read(accountRepositoryProvider);
      await repo.ensureDefaultChartSeeded();
      final accounts = await repo.getAll();
      final byCode = <String, ({String id, String code, String name})>{};
      final byId = <String, ({String id, String code, String name})>{};
      for (final account in accounts) {
        if (!account.canPost) {
          continue;
        }
        final entry = (
          id: account.uuid,
          code: account.accountCode,
          name: account.name,
        );
        byCode[account.accountCode] = entry;
        byId[account.uuid] = entry;
      }

      final resolved = _balanceExcel.resolveRows(
        rawRows: parsed.rows,
        byCode: byCode,
        byId: byId,
      );

      final normalized = <OpeningBalanceLine>[];
      for (final line in resolved) {
        if (line.hasBothSides) {
          throw AccountImportException(
            AccountImportException.bothOpeningSides,
            line.accountName,
          );
        }
        final currency = line.currencyCode.trim().toUpperCase().isEmpty
            ? fallback
            : line.currencyCode.trim().toUpperCase();
        if (!allowed.contains(currency)) {
          throw AccountImportException(
            AccountImportException.currencyNotConfigured,
            currency,
          );
        }
        normalized.add(line.copyWith(currencyCode: currency));
      }

      final merged = _mergeBalanceLines(state.balanceLines, normalized);
      state = state.copyWith(
        balanceFileName: fileName,
        balanceLines: merged,
        clearError: true,
        clearPostResult: true,
      );
    } on AccountImportException catch (e) {
      state = state.copyWith(
        errorCode: e.code,
        errorDetails: e.message,
        clearPostResult: true,
      );
    } catch (e) {
      state = state.copyWith(
        errorCode: AccountImportException.decodeFailed,
        errorDetails: e.toString(),
        clearPostResult: true,
      );
    }
  }

  List<OpeningBalanceLine> _mergeBalanceLines(
    List<OpeningBalanceLine> existing,
    List<OpeningBalanceLine> incoming,
  ) {
    final map = <String, OpeningBalanceLine>{
      for (final line in existing)
        '${line.accountId}|${line.currencyCode.trim().toUpperCase()}': line,
    };
    for (final line in incoming) {
      final key =
          '${line.accountId}|${line.currencyCode.trim().toUpperCase()}';
      final prev = map[key];
      if (prev == null) {
        map[key] = line;
      } else {
        map[key] = prev.copyWith(
          debit: line.debit,
          credit: line.credit,
          currencyCode: line.currencyCode,
        );
      }
    }
    return map.values.toList();
  }

  Future<bool> postOpening({
    required String voucherType,
    required String journalDescription,
    required Set<String> allowedCurrencyCodes,
  }) async {
    if (state.isBusy) {
      return false;
    }

    final withAmounts = state.balanceLines.where((l) => l.hasAmount).toList();
    if (withAmounts.isEmpty) {
      state = state.copyWith(
        errorCode: AccountImportException.noBalances,
        clearPostResult: true,
      );
      return false;
    }

    final allowed = {
      for (final code in allowedCurrencyCodes) code.trim().toUpperCase(),
    };
    final fallback = _ref
            .read(companyProfileProvider)
            .valueOrNull
            ?.defaultCurrencyCode
            .trim()
            .toUpperCase() ??
        'SAR';
    allowed.add(fallback);

    for (final line in withAmounts) {
      if (line.accountId.trim().isEmpty) {
        state = state.copyWith(
          errorCode: AccountImportException.accountRequired,
          clearPostResult: true,
        );
        return false;
      }
      if (line.hasBothSides) {
        state = state.copyWith(
          errorCode: AccountImportException.bothOpeningSides,
          errorDetails: line.accountName,
          clearPostResult: true,
        );
        return false;
      }
      final currency = line.currencyCode.trim().toUpperCase().isEmpty
          ? fallback
          : line.currencyCode.trim().toUpperCase();
      if (!allowed.contains(currency)) {
        state = state.copyWith(
          errorCode: AccountImportException.currencyNotConfigured,
          errorDetails: currency,
          clearPostResult: true,
        );
        return false;
      }
    }

    final keys = <String>{};
    final normalizedAmounts = <OpeningBalanceLine>[];
    for (final line in withAmounts) {
      final currency = line.currencyCode.trim().toUpperCase().isEmpty
          ? fallback
          : line.currencyCode.trim().toUpperCase();
      final key = '${line.accountId}|$currency';
      if (!keys.add(key)) {
        state = state.copyWith(
          errorCode: AccountImportException.duplicateCurrency,
          errorDetails: line.accountName,
          clearPostResult: true,
        );
        return false;
      }
      normalizedAmounts.add(line.copyWith(currencyCode: currency));
    }

    state = state.copyWith(
      isBusy: true,
      progress: 0.2,
      clearError: true,
      clearPostResult: true,
    );

    try {
      final repo = _ref.read(accountRepositoryProvider);
      await repo.ensureDefaultChartSeeded();
      final capital = await repo.getByAccountCode(
        AccountImportOpeningJournal.capitalAccountCode,
      );
      if (capital == null || !capital.canPost) {
        throw const AccountImportException(
          AccountImportException.capitalMissing,
        );
      }

      final draft = AccountImportOpeningJournal.buildFromBalanceLines(
        balances: normalizedAmounts,
        capitalAccountUuid: capital.uuid,
        defaultCurrencyCode: fallback,
        entryDate: DateTime.now(),
        voucherNumber: 'OI-${DateTime.now().millisecondsSinceEpoch}',
        voucherType: voucherType,
        description: journalDescription,
      );

      if (draft == null) {
        state = state.copyWith(
          isBusy: false,
          errorCode: AccountImportException.noBalances,
          clearPostResult: true,
        );
        return false;
      }

      state = state.copyWith(progress: 0.7);
      await _ref.read(postJournalEntryUseCaseProvider).call(draft);
      state = state.copyWith(
        isBusy: false,
        progress: 1,
        postResult: true,
        balanceLines: const [],
        clearBalanceFileName: true,
      );
      return true;
    } on AccountImportException catch (e) {
      state = state.copyWith(
        isBusy: false,
        errorCode: e.code,
        errorDetails: e.message,
        postResult: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        errorCode: 'unexpected',
        errorDetails: e.toString(),
        postResult: false,
      );
      return false;
    }
  }

  void resetSession() {
    state = const AccountOpeningSetupState();
  }
}

final accountOpeningSetupProvider = StateNotifierProvider.autoDispose<
    AccountOpeningSetupNotifier, AccountOpeningSetupState>(
  (ref) => AccountOpeningSetupNotifier(ref),
);
