import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_effect.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_journal_contracts.dart';
import 'package:stock_count/modules/accounting/domain/lifecycle/accounting_lifecycle_controller_impl.dart';
import 'package:stock_count/modules/accounting/domain/posting/accounting_posting_authority_port.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/repositories/journal_repository.dart';

class FakeJournalRepository implements JournalRepository {
  final Map<String, JournalEntry> _entries = {};

  void addEntry(JournalEntry entry) {
    _entries[entry.id] = entry;
  }

  @override
  Future<JournalEntry?> getByUuid(String uuid) async => _entries[uuid];

  @override
  Future<JournalEntry?> findBySource({
    required String sourceType,
    required String sourceId,
  }) async {
    for (final e in _entries.values) {
      if (e.sourceType == sourceType && e.sourceId == sourceId) {
        return e;
      }
    }
    return null;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePostingAuthority implements AccountingPostingAuthorityPort {
  bool failReversal = false;

  @override
  Future<AccountingPostingResult> postEffect(AccountingEffect effect) async {
    throw UnimplementedError();
  }

  @override
  Future<AccountingPostingResult> reverseJournal({
    required String journalUuid,
    required String reason,
  }) async {
    if (failReversal) {
      return const AccountingPostingResult(
        isSuccess: false,
        journal: null,
        failureReason: 'Reversal posting failed',
      );
    }
    return const AccountingPostingResult(
      isSuccess: true,
      journal: null,
    );
  }
}

void main() {
  late FakeJournalRepository fakeJournalRepo;
  late FakePostingAuthority fakePostingAuthority;
  late AccountingLifecycleController controller;

  final companyId = 'comp-uuid-100';
  final validDate = DateTime.utc(2026, 9, 12);
  final postedUuid = 'jnl-posted-001';
  final unpostedUuid = 'jnl-unposted-001';

  final postedEntry = JournalEntry(
    id: postedUuid,
    entryDate: validDate,
    voucherNumber: 'INV-100',
    voucherType: 'Sale',
    currencyCode: 'USD',
    isPosted: true,
    lines: [],
    createdAt: validDate,
    updatedAt: validDate,
  );

  final unpostedEntry = JournalEntry(
    id: unpostedUuid,
    entryDate: validDate,
    voucherNumber: 'DRAFT-100',
    voucherType: 'Sale Draft',
    currencyCode: 'USD',
    isPosted: false,
    lines: [],
    createdAt: validDate,
    updatedAt: validDate,
  );

  setUp(() {
    fakeJournalRepo = FakeJournalRepository();
    fakePostingAuthority = FakePostingAuthority();
    controller = AccountingLifecycleController(
      postingAuthority: fakePostingAuthority,
      journalRepository: fakeJournalRepo,
    );

    fakeJournalRepo.addEntry(postedEntry);
    fakeJournalRepo.addEntry(unpostedEntry);
  });

  group('AccountingLifecycleController Mandatory Tests', () {
    test('1. Posted journal update rejected by immutability guard', () {
      expect(
        () => controller.assertJournalMutable(isPosted: true, action: 'update'),
        throwsA(isA<AccountingLifecycleException>().having(
          (e) => e.message,
          'message',
          contains('Immutability Violation'),
        )),
      );
    });

    test('2. Posted journal deletion rejected by immutability guard', () {
      expect(
        () => controller.assertJournalMutable(isPosted: true, action: 'delete'),
        throwsA(isA<AccountingLifecycleException>().having(
          (e) => e.message,
          'message',
          contains('Immutability Violation'),
        )),
      );
    });

    test('3. Unposted journal mutation allowed', () {
      expect(
        () => controller.assertJournalMutable(isPosted: false, action: 'update'),
        returnsNormally,
      );
    });

    test('4. Valid Reversal: reverses posted journal entry', () async {
      final result = await controller.reverseJournal(
        journalUuid: postedUuid,
        reason: 'Correction of error',
      );
      expect(result.isSuccess, isTrue);
    });

    test('5. Invalid Reversal: reversing unposted journal rejected', () async {
      expect(
        () async => await controller.reverseJournal(
          journalUuid: unpostedUuid,
          reason: 'Error',
        ),
        throwsA(isA<AccountingLifecycleException>().having(
          (e) => e.message,
          'message',
          contains('Cannot reverse unposted journal entry'),
        )),
      );
    });

    test('6. Reversal of Reversal Policy: second reversal rejected', () async {
      // Simulate existing reversal entry
      final reverseEntry = JournalEntry(
        id: 'jnl-reverse-001',
        entryDate: validDate,
        voucherNumber: 'REV-INV-100',
        voucherType: 'Reversal',
        currencyCode: 'USD',
        isPosted: true,
        lines: [],
        createdAt: validDate,
        updatedAt: validDate,
        sourceType: 'journal_reverse',
        sourceId: postedUuid,
      );
      fakeJournalRepo.addEntry(reverseEntry);

      expect(
        () async => await controller.reverseJournal(
          journalUuid: postedUuid,
          reason: 'Second reversal attempt',
        ),
        throwsA(isA<AccountingLifecycleException>().having(
          (e) => e.message,
          'message',
          contains('has already been reversed'),
        )),
      );
    });

    test('7. Period Status Management: OPEN and CLOSED period behavior', () async {
      final periodId = '2026-09';
      expect(await controller.isPeriodOpen(companyId: companyId, periodId: periodId), isTrue);

      await controller.setPeriodStatus(companyId: companyId, periodId: periodId, isOpen: false);
      expect(await controller.isPeriodOpen(companyId: companyId, periodId: periodId), isFalse);

      await controller.setPeriodStatus(companyId: companyId, periodId: periodId, isOpen: true);
      expect(await controller.isPeriodOpen(companyId: companyId, periodId: periodId), isTrue);
    });
  });
}
