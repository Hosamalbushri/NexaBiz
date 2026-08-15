import '../../modules/accounting/domain/repositories/account_repository.dart';
import '../../modules/accounting/domain/repositories/voucher_book_repository.dart';
import '../../modules/system_setup/domain/ports/system_setup_seed_port.dart';

/// App adapter: System Setup → Accounting idempotent seeds.
class AccountingSystemSetupSeedAdapter implements SystemSetupSeedPort {
  AccountingSystemSetupSeedAdapter({
    required AccountRepository accounts,
    required VoucherBookRepository voucherBooks,
  }) : _accounts = accounts,
       _voucherBooks = voucherBooks;

  final AccountRepository _accounts;
  final VoucherBookRepository _voucherBooks;

  @override
  Future<void> ensureLocalDefaults() async {
    await _accounts.ensureDefaultChartSeeded();
    await _voucherBooks.ensureDefaultSections();
  }
}
