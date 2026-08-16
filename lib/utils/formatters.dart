import 'package:intl/intl.dart';

import '../data/currencies.dart';

/// Global money formatting driven by app currency settings.
class MoneyFormat {
  static String primaryCode = 'PKR';

  /// Rate of foreign currency → primary (1 USD = N primary).
  static Map<String, double> ratesToPrimary = Map.from(defaultRatesToPkr);

  static void configure({
    required String primaryCode,
    required Map<String, double> ratesToPrimary,
  }) {
    MoneyFormat.primaryCode = primaryCode;
    MoneyFormat.ratesToPrimary = Map.from(ratesToPrimary);
    // Ensure primary is always 1.
    MoneyFormat.ratesToPrimary[primaryCode] = 1;
  }

  static AppCurrency get primary => currencyByCode(primaryCode);

  /// Convert [amount] in [currencyCode] into primary currency.
  static double toPrimary(double amount, [String? currencyCode]) {
    final code = currencyCode ?? primaryCode;
    if (code == primaryCode) return amount;
    final rate = ratesToPrimary[code] ?? 1;
    return amount * rate;
  }

  static String format(
    double amount, {
    bool compact = false,
    String? currencyCode,
  }) {
    final code = currencyCode ?? primaryCode;
    final meta = currencyByCode(code);
    if (compact && amount.abs() >= 1000) {
      return NumberFormat.compactCurrency(
        locale: meta.locale,
        symbol: meta.symbol,
        decimalDigits: 0,
      ).format(amount);
    }
    return NumberFormat.currency(
      locale: meta.locale,
      symbol: meta.symbol,
      decimalDigits: meta.decimals,
    ).format(amount);
  }
}

/// Formats in the app primary currency (or optional code).
String formatPkr(double amount, {bool compact = false, String? currency}) {
  return MoneyFormat.format(amount, compact: compact, currencyCode: currency);
}

String formatDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(date.year, date.month, date.day);
  final diff = today.difference(d).inDays;

  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return DateFormat('EEEE').format(date);
  if (date.year == now.year) return DateFormat('d MMM').format(date);
  return DateFormat('d MMM yyyy').format(date);
}

String formatDateFull(DateTime date) => DateFormat('d MMM yyyy').format(date);

String monthLabel(DateTime date) => DateFormat('MMMM yyyy').format(date);
