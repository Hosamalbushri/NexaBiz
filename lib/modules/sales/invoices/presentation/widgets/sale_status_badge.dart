import 'package:flutter/material.dart';
import 'package:stock_count/core/widgets/app_amount_field.dart';
import 'package:stock_count/core/widgets/app_status_badge.dart';
import '../../domain/entities/sale_status.dart';

class SaleStatusBadge extends StatelessWidget {
  const SaleStatusBadge({super.key, required this.status, required this.label});

  final SaleStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppStatusBadge(
      label: label,
      tone: switch (status) {
        SaleStatus.unposted => AppStatusTone.neutral,
        SaleStatus.posted => AppStatusTone.success,
      },
    );
  }
}

String formatSaleMoney(BuildContext context, double value) {
  return formatAppAmount(context, value);
}

class SaleMoneyText extends StatelessWidget {
  const SaleMoneyText(this.value, {super.key, this.style, this.textAlign});

  final double value;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return AppAmountText(value, style: style, textAlign: textAlign);
  }
}
