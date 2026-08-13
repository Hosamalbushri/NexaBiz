import 'package:drift/drift.dart';

import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/voucher_book.dart';
import '../../domain/entities/voucher_book_type.dart';
import '../../domain/models/voucher_book_exception.dart';
import '../../domain/repositories/voucher_book_repository.dart';
import '../../domain/services/default_voucher_books.dart';
import '../../domain/services/voucher_book_validator.dart';
import '../database/accounting_database.dart';

class VoucherBookRepositoryImpl implements VoucherBookRepository {
  VoucherBookRepositoryImpl(this._db, {VoucherBookValidator? validator})
    : _validator = validator ?? const VoucherBookValidator();

  final AccountingDatabase _db;
  final VoucherBookValidator _validator;

  static const Map<VoucherBookType, String> _defaultSectionNamesEn = {
    VoucherBookType.sales: 'Sales',
    VoucherBookType.receipts: 'Receipts',
    VoucherBookType.payments: 'Payments',
    VoucherBookType.purchases: 'Purchases',
    VoucherBookType.journal: 'Journal',
  };

  VoucherBook _map(VoucherBookRow row) {
    return VoucherBook(
      id: row.id,
      uuid: row.uuid,
      parentId: row.parentId,
      name: row.name,
      bookType: VoucherBookType.fromStorage(row.bookType),
      isGroup: row.isGroup,
      currentNumber: row.nextNumber,
      endNumber: row.endNumber,
      isActive: row.isActive,
      notes: row.notes,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAt,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAt,
        isUtc: true,
      ),
    );
  }

  List<VoucherBookSectionNode> _buildTree(List<VoucherBook> all) {
    final groups =
        all
            .where((b) => b.isGroup && b.parentId == null)
            .toList(growable: false)
          ..sort((a, b) {
            final ai = VoucherBookType.sections.indexOf(a.bookType);
            final bi = VoucherBookType.sections.indexOf(b.bookType);
            final aOrder = ai < 0 ? 99 : ai;
            final bOrder = bi < 0 ? 99 : bi;
            if (aOrder != bOrder) {
              return aOrder.compareTo(bOrder);
            }
            return a.name.compareTo(b.name);
          });

    final byParent = <String, List<VoucherBook>>{};
    for (final book in all) {
      if (book.isGroup) {
        continue;
      }
      final parent = book.parentId;
      if (parent == null || parent.isEmpty) {
        continue;
      }
      (byParent[parent] ??= []).add(book);
    }
    for (final list in byParent.values) {
      list.sort((a, b) {
        final typeCmp = a.bookType.name.compareTo(b.bookType.name);
        if (typeCmp != 0) {
          return typeCmp;
        }
        return a.name.compareTo(b.name);
      });
    }

    return [
      for (final group in groups)
        VoucherBookSectionNode(
          group: group,
          children: List.unmodifiable(byParent[group.uuid] ?? const []),
        ),
    ];
  }

  @override
  Future<List<VoucherBook>> getAll() async {
    final rows =
        await (_db.select(_db.voucherBooks)..orderBy([
              (t) => OrderingTerm.asc(t.bookType),
              (t) => OrderingTerm.asc(t.name),
            ]))
            .get();
    return rows.map(_map).toList(growable: false);
  }

  @override
  Stream<List<VoucherBook>> watchAll() {
    final query = _db.select(_db.voucherBooks)
      ..orderBy([
        (t) => OrderingTerm.asc(t.bookType),
        (t) => OrderingTerm.asc(t.name),
      ]);
    return query.watch().map((rows) => rows.map(_map).toList(growable: false));
  }

  @override
  Future<VoucherBook?> getById(int id) async {
    final row = await (_db.select(
      _db.voucherBooks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Future<VoucherBook?> getByUuid(String uuid) async {
    final trimmed = uuid.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final row = await (_db.select(
      _db.voucherBooks,
    )..where((t) => t.uuid.equals(trimmed))).getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Future<List<VoucherBook>> getByType(VoucherBookType type) async {
    final rows =
        await (_db.select(_db.voucherBooks)
              ..where((t) => t.bookType.equals(type.storageValue))
              ..orderBy([(t) => OrderingTerm.asc(t.name)]))
            .get();
    return rows.map(_map).toList(growable: false);
  }

  @override
  Future<List<VoucherBook>> getChildren(String parentUuid) async {
    final rows =
        await (_db.select(_db.voucherBooks)
              ..where((t) => t.parentId.equals(parentUuid))
              ..orderBy([
                (t) => OrderingTerm.asc(t.bookType),
                (t) => OrderingTerm.asc(t.name),
              ]))
            .get();
    return rows.map(_map).toList(growable: false);
  }

  @override
  Future<void> ensureDefaultSections() async {
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    final all = await getAll();
    final groupsByType = <VoucherBookType, VoucherBook>{
      for (final g in all.where((b) => b.isGroup && b.parentId == null))
        g.bookType: g,
    };

    for (final section in VoucherBookType.sections) {
      if (groupsByType.containsKey(section)) {
        continue;
      }
      final uuid = generateUuidV4();
      await _db
          .into(_db.voucherBooks)
          .insert(
            VoucherBooksCompanion.insert(
              uuid: uuid,
              parentId: const Value(null),
              name: _defaultSectionNamesEn[section] ?? section.name,
              bookType: section.storageValue,
              isGroup: const Value(true),
              nextNumber: const Value(1),
              endNumber: const Value(9999),
              isActive: const Value(true),
              createdAt: nowMs,
              updatedAt: nowMs,
            ),
          );
      groupsByType[section] = VoucherBook(
        id: 0,
        uuid: uuid,
        name: _defaultSectionNamesEn[section] ?? section.name,
        bookType: section,
        isGroup: true,
        currentNumber: 1,
        endNumber: 9999,
        isActive: true,
        createdAt: DateTime.fromMillisecondsSinceEpoch(nowMs, isUtc: true),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(nowMs, isUtc: true),
      );
    }

    // Attach legacy flat leaf books to their section group.
    var refreshed = await getAll();
    final groupUuidBySection = <VoucherBookType, String>{
      for (final g in refreshed.where((b) => b.isGroup && b.parentId == null))
        g.bookType: g.uuid,
    };

    for (final book in refreshed) {
      if (book.isGroup) {
        continue;
      }
      if (book.parentId != null && book.parentId!.isNotEmpty) {
        continue;
      }
      final sectionUuid = groupUuidBySection[book.bookType.section];
      if (sectionUuid == null) {
        continue;
      }
      await (_db.update(
        _db.voucherBooks,
      )..where((t) => t.id.equals(book.id))).write(
        VoucherBooksCompanion(
          parentId: Value(sectionUuid),
          updatedAt: Value(nowMs),
        ),
      );
    }

    // Seed one default leaf book per kind when that kind has none yet.
    refreshed = await getAll();
    final leavesBySectionAndType = <String, Set<VoucherBookType>>{};
    for (final book in refreshed) {
      if (book.isGroup) {
        continue;
      }
      final parent = book.parentId;
      if (parent == null || parent.isEmpty) {
        continue;
      }
      (leavesBySectionAndType[parent] ??= {}).add(book.bookType);
    }

    for (final seed in DefaultVoucherBooks.seeds) {
      final sectionUuid = groupUuidBySection[seed.bookType.section];
      if (sectionUuid == null) {
        continue;
      }
      final existingKinds = leavesBySectionAndType[sectionUuid] ?? const {};
      if (existingKinds.contains(seed.bookType)) {
        continue;
      }
      await _db
          .into(_db.voucherBooks)
          .insert(
            VoucherBooksCompanion.insert(
              uuid: generateUuidV4(),
              parentId: Value(sectionUuid),
              name: seed.nameAr,
              bookType: seed.bookType.storageValue,
              isGroup: const Value(false),
              nextNumber: Value(seed.currentNumber),
              endNumber: Value(seed.endNumber),
              isActive: const Value(true),
              notes: Value(seed.nameEn),
              createdAt: nowMs,
              updatedAt: nowMs,
            ),
          );
      (leavesBySectionAndType[sectionUuid] ??= {}).add(seed.bookType);
    }
  }

  @override
  Future<List<VoucherBookSectionNode>> getSectionTree() async {
    await ensureDefaultSections();
    return _buildTree(await getAll());
  }

  @override
  Stream<List<VoucherBookSectionNode>> watchSectionTree() async* {
    await ensureDefaultSections();
    yield* watchAll().map(_buildTree);
  }

  Future<void> _assertParentValid(VoucherBookDraft draft) async {
    if (draft.isGroup) {
      return;
    }
    final parent = await getByUuid(draft.parentId!.trim());
    if (parent == null || !parent.isGroup) {
      throw const VoucherBookException('Parent section not found');
    }
    if (parent.bookType != draft.bookType.section) {
      throw const VoucherBookException(
        'Book type does not match parent section',
      );
    }
  }

  @override
  Future<VoucherBook> create(VoucherBookDraft draft) async {
    _validator.validate(draft);
    await _assertParentValid(draft);
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    final notes = draft.notes?.trim();
    final id = await _db
        .into(_db.voucherBooks)
        .insert(
          VoucherBooksCompanion.insert(
            uuid: generateUuidV4(),
            parentId: Value(draft.isGroup ? null : draft.parentId?.trim()),
            name: draft.name.trim(),
            bookType: draft.bookType.storageValue,
            isGroup: Value(draft.isGroup),
            nextNumber: Value(draft.isGroup ? 1 : draft.currentNumber),
            endNumber: Value(draft.isGroup ? 9999 : draft.endNumber),
            isActive: Value(draft.isActive),
            notes: Value(notes == null || notes.isEmpty ? null : notes),
            createdAt: nowMs,
            updatedAt: nowMs,
          ),
        );
    final created = await getById(id);
    return created!;
  }

  @override
  Future<VoucherBook> update(int id, VoucherBookDraft draft) async {
    _validator.validate(draft);
    final existing = await getById(id);
    if (existing == null) {
      throw const VoucherBookException('Voucher book not found');
    }
    if (existing.isGroup != draft.isGroup) {
      throw const VoucherBookException('Cannot change group/leaf role');
    }
    await _assertParentValid(draft);
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    final notes = draft.notes?.trim();
    await (_db.update(_db.voucherBooks)..where((t) => t.id.equals(id))).write(
      VoucherBooksCompanion(
        parentId: Value(draft.isGroup ? null : draft.parentId?.trim()),
        name: Value(draft.name.trim()),
        bookType: Value(draft.bookType.storageValue),
        nextNumber: Value(
          draft.isGroup ? existing.currentNumber : draft.currentNumber,
        ),
        endNumber: Value(draft.isGroup ? existing.endNumber : draft.endNumber),
        isActive: Value(draft.isActive),
        notes: Value(notes == null || notes.isEmpty ? null : notes),
        updatedAt: Value(nowMs),
      ),
    );
    final updated = await getById(id);
    return updated!;
  }

  @override
  Future<void> delete(int id) async {
    final existing = await getById(id);
    if (existing == null) {
      return;
    }
    if (existing.isGroup) {
      final children = await getChildren(existing.uuid);
      if (children.isNotEmpty) {
        throw const VoucherBookException(
          'Cannot delete a section that still has books',
        );
      }
    }
    await (_db.delete(_db.voucherBooks)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<int> allocateNextNumber(int id) async {
    return _db.transaction(() async {
      final row = await (_db.select(
        _db.voucherBooks,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (row == null) {
        throw const VoucherBookException('Voucher book not found');
      }
      if (row.isGroup) {
        throw const VoucherBookException('Section groups do not issue numbers');
      }
      if (!row.isActive) {
        throw const VoucherBookException('Voucher book is inactive');
      }
      if (row.nextNumber > row.endNumber) {
        throw const VoucherBookException('Voucher book is exhausted');
      }
      final allocated = row.nextNumber;
      final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
      await (_db.update(_db.voucherBooks)..where((t) => t.id.equals(id))).write(
        VoucherBooksCompanion(
          nextNumber: Value(allocated + 1),
          updatedAt: Value(nowMs),
        ),
      );
      return allocated;
    });
  }
}
