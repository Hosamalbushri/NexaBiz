import 'package:flutter/material.dart';
import 'package:stock_count/core/widgets/app_amount_field.dart';
import 'package:stock_count/core/widgets/app_money_text.dart';
import '../../domain/entities/transaction_status.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

class TransactionStatusBadge extends StatelessWidget {
  const TransactionStatusBadge({
    super.key,
    required this.status,
    required this.label,
  });

  final TransactionStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppStatusBadge(
      label: label,
      tone: switch (status) {
        TransactionStatus.unposted => AppStatusTone.neutral,
        TransactionStatus.posted => AppStatusTone.success,
      },
    );
  }
}

String formatRpMoney(BuildContext context, double value) {
  return formatAppAmount(context, value, decimalPlaces: 0);
}

class RpMoneyText extends StatelessWidget {
  const RpMoneyText(this.value, {super.key, this.style, this.textAlign});

  final double value;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return AppMoneyText(value, decimalDigits: 0, style: style);
  }
}
