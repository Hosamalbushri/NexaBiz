import 'package:flutter/material.dart';

import '../../domain/entities/account_type.dart';

/// Shared Chart of Accounts type colors / icons for presentation widgets.
Color accountTypeColor(ColorScheme scheme, AccountType type) {
  return switch (type) {
    AccountType.asset => scheme.primary,
    AccountType.liability => scheme.tertiary,
    AccountType.equity => scheme.secondary,
    AccountType.revenue => const Color(0xFF2E7D32),
    AccountType.expense => scheme.error,
  };
}

IconData accountTypeIcon(AccountType type) {
  return switch (type) {
    AccountType.asset => Icons.account_balance_wallet_outlined,
    AccountType.liability => Icons.receipt_long_outlined,
    AccountType.equity => Icons.pie_chart_outline_rounded,
    AccountType.revenue => Icons.trending_up_rounded,
    AccountType.expense => Icons.trending_down_rounded,
  };
}
