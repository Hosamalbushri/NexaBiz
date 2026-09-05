import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import 'package:stock_count/modules/system_setup/presentation/providers/system_setup_providers.dart';
import '../../data/repositories/cash_register_repository_impl.dart';
import '../../domain/entities/cash_register.dart';
import '../../domain/repositories/cash_register_repository.dart';
import 'package:stock_count/modules/accounting/journals/presentation/providers/journal_providers.dart';
import '../../domain/services/cash_register_initializer_service.dart';
import '../../domain/services/cash_register_movement_service.dart';
import '../../domain/services/cash_register_posting_resolver_service.dart';
import '../../domain/services/default_cash_register_resolver.dart';

/// Provider for DefaultCashRegisterResolver service.
final defaultCashRegisterResolverProvider = Provider<DefaultCashRegisterResolver>((ref) {
  final cashRepo = ref.watch(cashRegisterRepositoryProvider);
  final accRepo = ref.watch(accountRepositoryProvider);
  return DefaultCashRegisterResolver(
    cashRegisterRepository: cashRepo,
    accountRepository: accRepo,
  );
});

/// Provider for CashRegisterInitializerService.
final cashRegisterInitializerServiceProvider = Provider<CashRegisterInitializerService>((ref) {
  final cashRepo = ref.watch(cashRegisterRepositoryProvider);
  final accRepo = ref.watch(accountRepositoryProvider);
  final resolver = ref.watch(defaultCashRegisterResolverProvider);
  return CashRegisterInitializerService(
    cashRegisterRepository: cashRepo,
    accountRepository: accRepo,
    defaultCashRegisterResolver: resolver,
  );
});

/// Provider for CashRegisterPostingResolverService.
final cashRegisterPostingResolverServiceProvider = Provider<CashRegisterPostingResolverService>((ref) {
  final cashRepo = ref.watch(cashRegisterRepositoryProvider);
  final accRepo = ref.watch(accountRepositoryProvider);
  final resolver = ref.watch(defaultCashRegisterResolverProvider);
  return CashRegisterPostingResolverService(
    cashRegisterRepository: cashRepo,
    accountRepository: accRepo,
    defaultCashRegisterResolver: resolver,
  );
});

/// Provider for CashRegisterMovementService.
final cashRegisterMovementServiceProvider = Provider<CashRegisterMovementService>((ref) {
  final cashRepo = ref.watch(cashRegisterRepositoryProvider);
  final accRepo = ref.watch(accountRepositoryProvider);
  final journalRepo = ref.watch(journalRepositoryProvider);
  final resolver = ref.watch(cashRegisterPostingResolverServiceProvider);
  final journalPosting = ref.watch(journalPostingServiceProvider);
  return CashRegisterMovementService(
    cashRegisterRepository: cashRepo,
    accountRepository: accRepo,
    journalRepository: journalRepo,
    postingResolver: resolver,
    journalPostingService: journalPosting,
  );
});

/// Async provider for the active company's default Cash Register resolution result.
final defaultCashRegisterResultProvider = FutureProvider<DefaultCashRegisterResult>((ref) async {
  final resolver = ref.watch(defaultCashRegisterResolverProvider);
  final initState = await ref.watch(companyInitializationRepositoryProvider).getState();
  final companyId = initState.companyId.isEmpty ? 'default' : initState.companyId;
  return resolver.resolveDefaultCashRegister(companyId);
});

/// Singleton Cash Register Repository provider.
final cashRegisterRepositoryProvider = Provider<CashRegisterRepository>((ref) {
  final accountRepo = ref.watch(accountRepositoryProvider);
  final db = ref.watch(accountingDatabaseProvider);
  return CashRegisterRepositoryImpl(
    accountRepository: accountRepo,
    db: db,
  );
});

/// Async provider for all cash registers belonging to active company.
final cashRegistersProvider = FutureProvider<List<CashRegister>>((ref) async {
  final repo = ref.watch(cashRegisterRepositoryProvider);
  final initState = await ref.watch(companyInitializationRepositoryProvider).getState();
  final companyId = initState.companyId.isEmpty ? 'default' : initState.companyId;
  return repo.getCashRegisters(companyId);
});

/// QUERY-LEVEL GATING: Async provider for ONLY accounting-ready cash registers.
final accountingReadyCashRegistersProvider = FutureProvider<List<CashRegister>>((ref) async {
  final repo = ref.watch(cashRegisterRepositoryProvider);
  final initState = await ref.watch(companyInitializationRepositoryProvider).getState();
  final companyId = initState.companyId.isEmpty ? 'default' : initState.companyId;
  return repo.getAccountingReadyCashRegisters(companyId);
});

/// Readiness summary of the Cash module's accounting configuration.
class CashModuleReadinessSummary {
  const CashModuleReadinessSummary({
    required this.totalRegisters,
    required this.linkedRegisters,
    required this.unlinkedRegisters,
    required this.invalidRegisters,
    required this.statusLabelAr,
    required this.statusLabelEn,
    required this.isReady,
  });

  final int totalRegisters;
  final int linkedRegisters;
  final int unlinkedRegisters;
  final int invalidRegisters;
  final String statusLabelAr;
  final String statusLabelEn;
  final bool isReady;
}

final cashModuleReadinessSummaryProvider = FutureProvider<CashModuleReadinessSummary>((ref) async {
  final registers = await ref.watch(cashRegistersProvider.future);
  final accountRepo = ref.watch(accountRepositoryProvider);
  final initState = await ref.watch(companyInitializationRepositoryProvider).getState();
  final companyId = initState.companyId.isEmpty ? 'default' : initState.companyId;

  if (registers.isEmpty) {
    return const CashModuleReadinessSummary(
      totalRegisters: 0,
      linkedRegisters: 0,
      unlinkedRegisters: 0,
      invalidRegisters: 0,
      statusLabelAr: 'غير مهيأ (لا توجد صناديق)',
      statusLabelEn: 'Not Initialized (No registers)',
      isReady: false,
    );
  }

  int linked = 0;
  int unlinked = 0;
  int invalid = 0;

  for (final reg in registers) {
    if (!reg.isLinked) {
      unlinked++;
      continue;
    }
    final acc = await accountRepo.getByUuid(reg.accountingAccountId!) ??
        await accountRepo.getByAccountCode(reg.accountingAccountId!);
    final status = reg.evaluateStatus(acc, targetCompanyId: companyId);
    if (status == CashRegisterAccountingStatus.ready) {
      linked++;
    } else {
      invalid++;
    }
  }

  final bool ready = unlinked == 0 && invalid == 0 && linked > 0;
  String statusAr;
  String statusEn;

  if (ready) {
    statusAr = 'جاهز ومربوط محاسبياً';
    statusEn = 'Ready';
  } else if (linked > 0) {
    statusAr = 'مكتمل جزئياً ($linked/${registers.length} مربوط)';
    statusEn = 'Partially Configured ($linked/${registers.length} linked)';
  } else if (invalid > 0) {
    statusAr = 'ربط محاسبي غير صالح';
    statusEn = 'Invalid Accounting Link';
  } else {
    statusAr = 'غير مربوط محاسبياً';
    statusEn = 'Not Linked';
  }

  return CashModuleReadinessSummary(
    totalRegisters: registers.length,
    linkedRegisters: linked,
    unlinkedRegisters: unlinked,
    invalidRegisters: invalid,
    statusLabelAr: statusAr,
    statusLabelEn: statusEn,
    isReady: ready,
  );
});
