import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/core/tenancy/tenant_context.dart';
import '../../data/repositories/voucher_book_repository_impl.dart';
import '../../domain/entities/voucher_book.dart';
import '../../domain/repositories/voucher_book_repository.dart';
import '../../domain/services/voucher_book_validator.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';

final voucherBookValidatorProvider = Provider<VoucherBookValidator>((ref) {
  return const VoucherBookValidator();
});

final voucherBookRepositoryProvider = Provider<VoucherBookRepository>((ref) {
  return VoucherBookRepositoryImpl(
    ref.watch(accountingDatabaseProvider),
    validator: ref.watch(voucherBookValidatorProvider),
    readCompanyId: () => ref.read(currentCompanyIdProvider),
  );
});

final voucherBooksProvider = StreamProvider<List<VoucherBook>>((ref) {
  return ref.watch(voucherBookRepositoryProvider).watchAll();
});

final voucherBookSectionsProvider =
    StreamProvider<List<VoucherBookSectionNode>>((ref) {
      return ref.watch(voucherBookRepositoryProvider).watchSectionTree();
    });

final voucherBookByIdProvider = FutureProvider.autoDispose
    .family<VoucherBook?, int>((ref, id) {
      return ref.watch(voucherBookRepositoryProvider).getById(id);
    });
