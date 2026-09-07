import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Canonical money text widget for standard financial amount display.
class AppMoneyText extends StatelessWidget {
  const AppMoneyText(
    this.amount, {
    super.key,
    this.currencyCode,
    this.style,
    this.decimalDigits = 2,
  });

  final double amount;
  final String? currencyCode;
  final TextStyle? style;
  final int decimalDigits;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      symbol: currencyCode != null ? '' : null,
      decimalDigits: decimalDigits,
    );
    final formatted = formatter.format(amount).trim();
    final text = currencyCode != null ? '$formatted $currencyCode' : formatted;

    return Text(text, style: style);
  }
}
