import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/transaction_type.dart';

abstract final class ReceiptsPaymentsRoutes {
  static const root = '/receipts-payments';
  static const receiptsMenu = '/receipts-payments/receipts';
  static const paymentsMenu = '/receipts-payments/payments';
  static const transfersMenu = '/receipts-payments/transfers';
  static const exchangesMenu = '/receipts-payments/exchanges';
  static const postingService = '/receipts-payments/posting';
  static const receiptsList = '/receipts-payments/receipts/list';
  static const paymentsList = '/receipts-payments/payments/list';
  static const transfersList = '/receipts-payments/transfers/list';
  static const exchangesList = '/receipts-payments/exchanges/list';
  static const createReceipt = '/receipts-payments/receipts/create';
  static const createPayment = '/receipts-payments/payments/create';
  static const createTransfer = '/receipts-payments/transfers/create';
  static const createExchange = '/receipts-payments/exchanges/create';

  static String details(int id) => '/receipts-payments/$id';
  static String edit(int id) => '/receipts-payments/$id/edit';
  static String editTransfer(int id) => '/receipts-payments/transfers/$id/edit';
  static String editExchange(int id) => '/receipts-payments/exchanges/$id/edit';

  static String listFor(TransactionType type) => switch (type) {
        TransactionType.receipt => receiptsList,
        TransactionType.payment => paymentsList,
        TransactionType.transfer => transfersList,
        TransactionType.currencyExchange => exchangesList,
      };

  static void goRoot(BuildContext context) => context.go(root);

  static void pushReceiptsMenu(BuildContext context) =>
      context.push(receiptsMenu);

  static void pushPaymentsMenu(BuildContext context) =>
      context.push(paymentsMenu);

  static void pushTransfersMenu(BuildContext context) =>
      context.push(transfersMenu);

  static void pushExchangesMenu(BuildContext context) =>
      context.push(exchangesMenu);

  static void pushPostingService(BuildContext context) =>
      context.push(postingService);

  static void goList(BuildContext context, {required TransactionType type}) =>
      context.go(listFor(type));

  static void pushList(BuildContext context, {required TransactionType type}) =>
      context.push(listFor(type));

  static void pushDetails(BuildContext context, int id) =>
      context.push(details(id));

  static void pushCreateReceipt(BuildContext context) =>
      context.push(createReceipt);

  static void pushCreatePayment(BuildContext context) =>
      context.push(createPayment);

  static void pushCreateTransfer(BuildContext context) =>
      context.push(createTransfer);

  static void pushCreateExchange(BuildContext context) =>
      context.push(createExchange);

  static void pushEdit(BuildContext context, int id) => context.push(edit(id));

  static void pushEditTransfer(BuildContext context, int id) =>
      context.push(editTransfer(id));

  static void pushEditExchange(BuildContext context, int id) =>
      context.push(editExchange(id));

  static void backToList(BuildContext context, {required TransactionType type}) =>
      goList(context, type: type);
}
