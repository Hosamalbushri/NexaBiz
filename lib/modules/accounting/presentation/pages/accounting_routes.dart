import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/voucher_book_type.dart';

/// Route paths owned by the Accounting module.
class AccountingRoutes {
  const AccountingRoutes._();

  static const String root = '/accounting';
  static const String accounts = '/accounting/accounts';
  static const String accountsCreate = '/accounting/accounts/create';
  static const String currencyRates = '/accounting/currency-rates';
  static const String voucherBooks = '/accounting/voucher-books';
  static const String voucherBooksCreate = '/accounting/voucher-books/new';
  static const String reports = '/accounting/reports';
  static const String journals = '/accounting/journals';
  static const String journalsCreate = '/accounting/journals/new';

  static String accountDetails(int id) => '/accounting/accounts/$id';

  static String accountEdit(int id) => '/accounting/accounts/$id/edit';

  static String voucherBookEdit(int id) => '/accounting/voucher-books/$id/edit';

  static String voucherBookSection(VoucherBookType section) =>
      '/accounting/voucher-books/section/${section.section.storageValue}';

  static String journalDetails(String uuid) => '/accounting/journals/$uuid';

  static String journalEdit(String uuid) => '/accounting/journals/$uuid/edit';

  static void goRoot(BuildContext context) => context.go(root);

  static void goAccounts(BuildContext context) => context.go(accounts);

  static void goJournals(BuildContext context) => context.go(journals);

  static void goCurrencyRates(BuildContext context) =>
      context.go(currencyRates);

  static void pushCurrencyRates(BuildContext context) =>
      context.push(currencyRates);

  static void pushVoucherBooks(BuildContext context) =>
      context.push(voucherBooks);

  static void pushReports(BuildContext context) => context.push(reports);

  static void pushJournals(BuildContext context) => context.push(journals);

  static void pushJournalCreate(BuildContext context) =>
      context.push(journalsCreate);

  static void pushJournalDetails(BuildContext context, String uuid) =>
      context.push(journalDetails(uuid));

  static void pushJournalEdit(BuildContext context, String uuid) =>
      context.push(journalEdit(uuid));

  static void pushVoucherBookSection(
    BuildContext context,
    VoucherBookType section,
  ) => context.push(voucherBookSection(section));

  static void pushVoucherBookCreate(
    BuildContext context, {
    String? parentId,
    VoucherBookType? bookType,
  }) {
    final params = <String, String>{};
    if (parentId != null && parentId.isNotEmpty) {
      params['parentId'] = parentId;
    }
    if (bookType != null) {
      params['bookType'] = bookType.storageValue;
    }
    if (params.isEmpty) {
      context.push(voucherBooksCreate);
      return;
    }
    context.push(
      Uri(path: voucherBooksCreate, queryParameters: params).toString(),
    );
  }

  static void pushVoucherBookEdit(BuildContext context, int id) =>
      context.push(voucherBookEdit(id));

  static void pushAccountsCreate(
    BuildContext context, {
    String? parentId,
  }) {
    if (parentId == null || parentId.isEmpty) {
      context.push(accountsCreate);
      return;
    }
    context.push(
      Uri(
        path: accountsCreate,
        queryParameters: {'parentId': parentId},
      ).toString(),
    );
  }

  static void pushAccountDetails(BuildContext context, int id) =>
      context.push(accountDetails(id));

  static void pushAccountEdit(BuildContext context, int id) =>
      context.push(accountEdit(id));
}
