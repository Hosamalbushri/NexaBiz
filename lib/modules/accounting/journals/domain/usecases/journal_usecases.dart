import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/modules/accounting/permissions/accounting_permissions.dart';
import '../entities/journal_entry.dart';
import '../repositories/journal_repository.dart';
import '../services/journal_posting_service.dart';

class PostJournalEntry {
  const PostJournalEntry(
    this._posting, [
    this._guard = const AllowAllPermissionGuard(),
  ]);

  final JournalPostingService _posting;
  final PermissionGuard _guard;

  Future<JournalEntry> call(JournalEntryDraft draft) {
    _guard.requireAny(AccountingPermissions.journalsCreate);
    return _posting.post(draft);
  }
}

class GetJournalEntryByUuid {
  const GetJournalEntryByUuid(this._repository);

  final JournalRepository _repository;

  Future<JournalEntry?> call(String uuid) => _repository.getByUuid(uuid);
}

class ListJournalEntryHeaders {
  const ListJournalEntryHeaders(this._repository);

  final JournalRepository _repository;

  Future<List<JournalEntryHeader>> call({
    DateTime? fromDate,
    DateTime? toDate,
    bool? isPosted,
    String? query,
    int? limit,
    int? afterId,
  }) {
    return _repository.listHeaders(
      fromDate: fromDate,
      toDate: toDate,
      isPosted: isPosted,
      query: query,
      limit: limit,
      afterId: afterId,
    );
  }
}

class SoftDeleteJournalEntry {
  const SoftDeleteJournalEntry(
    this._posting, [
    this._guard = const AllowAllPermissionGuard(),
  ]);

  final JournalPostingService _posting;
  final PermissionGuard _guard;

  Future<void> call(String uuid) {
    _guard.requireAny(AccountingPermissions.journalsDelete);
    return _posting.voidByUuid(uuid);
  }
}

/// Voids a journal (reverse if posted, soft-delete if draft).
class VoidJournalEntry {
  const VoidJournalEntry(
    this._posting, [
    this._guard = const AllowAllPermissionGuard(),
  ]);

  final JournalPostingService _posting;
  final PermissionGuard _guard;

  Future<void> call(String uuid) {
    _guard.requireAny(AccountingPermissions.journalsDelete);
    return _posting.voidByUuid(uuid);
  }
}
