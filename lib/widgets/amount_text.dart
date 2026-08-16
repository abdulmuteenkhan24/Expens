import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class AmountText extends StatelessWidget {
  final double amount;
  final bool isIncome;
  final bool compact;
  final TextStyle? style;
  final bool showSign;
  final String? currencyCode;

  const AmountText({
    super.key,
    required this.amount,
    this.isIncome = false,
    this.compact = false,
    this.style,
    this.showSign = false,
    this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? AppColors.income : AppColors.expense;
    final prefix = showSign ? (isIncome ? '+ ' : '- ') : '';
    return Text(
      '$prefix${formatPkr(amount, compact: compact, currency: currencyCode)}',
      style: (style ?? Theme.of(context).textTheme.titleMedium)?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
