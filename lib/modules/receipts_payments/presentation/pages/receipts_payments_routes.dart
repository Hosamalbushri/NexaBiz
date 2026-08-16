import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/transaction_type.dart';

abstract final class ReceiptsPaymentsRoutes {
  static const root = '/receipts-payments';
  static const receiptsMenu = '/receipts-payments/receipts';
  static const paymentsMenu = '/receipts-payments/payments';
  static const list = '/receipts-payments/list';
  static const createReceipt = '/receipts-payments/receipts/create';
  static const createPayment = '/receipts-payments/payments/create';

  static String details(int id) => '/receipts-payments/$id';
  static String edit(int id) => '/receipts-payments/$id/edit';

  static void goRoot(BuildContext context) => context.go(root);

  static void pushReceiptsMenu(BuildContext context) =>
      context.push(receiptsMenu);

  static void pushPaymentsMenu(BuildContext context) =>
      context.push(paymentsMenu);

  static void goList(BuildContext context, {TransactionType? type}) {
    if (type == null) {
      context.go(list);
    } else {
      context.go('$list?type=${type.storageValue}');
    }
  }

  static void pushList(BuildContext context, {TransactionType? type}) {
    if (type == null) {
      context.push(list);
    } else {
      context.push('$list?type=${type.storageValue}');
    }
  }

  static void pushDetails(BuildContext context, int id) =>
      context.push(details(id));

  static void pushCreateReceipt(BuildContext context) =>
      context.push(createReceipt);

  static void pushCreatePayment(BuildContext context) =>
      context.push(createPayment);

  static void pushEdit(BuildContext context, int id) => context.push(edit(id));

  static void backToList(BuildContext context, {TransactionType? type}) =>
      goList(context, type: type);
}
