import 'package:flutter/services.dart';

/// Parse amount text that may contain commas: `"5,000.50"` → `5000.50`.
double? parseAmount(String text) {
  final cleaned = text.replaceAll(',', '').replaceAll(' ', '').trim();
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}

/// Format a number for an amount field: `5000` → `"5,000"`, `5000.5` → `"5,000.5"`.
String formatAmountInput(num value, {int maxDecimals = 2}) {
  if (value.isNaN || value.isInfinite) return '';
  final negative = value < 0;
  final abs = value.abs();
  final whole = abs.floor();
  final frac = abs - whole;

  final wholeStr = _groupThousands(whole.toString());
  if (frac < 1e-12) {
    return negative ? '-$wholeStr' : wholeStr;
  }

  // Keep up to [maxDecimals] without forced trailing zeros.
  var fracStr = frac
      .toStringAsFixed(maxDecimals)
      .replaceFirst(RegExp(r'^0\.'), '')
      .replaceFirst(RegExp(r'0+$'), '');
  if (fracStr.isEmpty) {
    return negative ? '-$wholeStr' : wholeStr;
  }
  final out = '$wholeStr.$fracStr';
  return negative ? '-$out' : out;
}

String _groupThousands(String digits) {
  if (digits.isEmpty) return '0';
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return buf.toString();
}

/// Auto-formats amount while typing: `5000` → `5,000`, supports decimals.
///
/// Use with [parseAmount] when reading the field value.
class AmountInputFormatter extends TextInputFormatter {
  final int maxDecimals;
  final bool allowNegative;

  const AmountInputFormatter({
    this.maxDecimals = 2,
    this.allowNegative = false,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;

    // Allow empty field.
    if (raw.isEmpty) {
      return newValue;
    }

    // Strip everything except digits, one dot, optional leading minus.
    var text = raw.replaceAll(' ', '');
    var negative = false;
    if (allowNegative && text.startsWith('-')) {
      negative = true;
      text = text.substring(1);
    }
    text = text.replaceAll('-', '');

    // Keep only digits and dots; first dot wins.
    final cleaned = StringBuffer();
    var seenDot = false;
    for (final r in text.runes) {
      final ch = String.fromCharCode(r);
      if (ch == ',') continue;
      if (ch == '.') {
        if (seenDot || maxDecimals <= 0) continue;
        seenDot = true;
        cleaned.write(ch);
      } else if (RegExp(r'\d').hasMatch(ch)) {
        cleaned.write(ch);
      }
    }

    var cleanedStr = cleaned.toString();
    if (cleanedStr.isEmpty) {
      return TextEditingValue(
        text: negative ? '-' : '',
        selection: TextSelection.collapsed(offset: negative ? 1 : 0),
      );
    }

    // Split integer / fraction.
    String intPart;
    String? fracPart;
    final endsWithDot = cleanedStr.endsWith('.');
    if (cleanedStr.contains('.')) {
      final parts = cleanedStr.split('.');
      intPart = parts[0];
      fracPart = parts.length > 1 ? parts[1] : '';
      if (fracPart.length > maxDecimals) {
        fracPart = fracPart.substring(0, maxDecimals);
      }
    } else {
      intPart = cleanedStr;
      fracPart = null;
    }

    // Drop leading zeros from integer (keep single 0).
    intPart = intPart.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (intPart.isEmpty) intPart = '0';

    final grouped = _groupThousands(intPart);
    final buffer = StringBuffer();
    if (negative) buffer.write('-');
    buffer.write(grouped);
    if (fracPart != null || endsWithDot) {
      buffer.write('.');
      if (fracPart != null) buffer.write(fracPart);
    }

    final formatted = buffer.toString();

    // Cursor: count digits (and decimal) left of old cursor in newValue,
    // map to same count in formatted.
    final cursorInNew = newValue.selection.baseOffset.clamp(0, raw.length);
    final left = raw.substring(0, cursorInNew);
    final digitsBefore = _significantCount(left, allowNegative: allowNegative);

    var newCursor = formatted.length;
    var seen = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (_isSignificant(formatted[i], allowNegative: allowNegative)) {
        seen++;
        if (seen >= digitsBefore) {
          newCursor = i + 1;
          break;
        }
      }
    }
    // If user just typed trailing '.', put cursor after it.
    if (endsWithDot && !formatted.endsWith('.')) {
      // shouldn't happen
    } else if (endsWithDot) {
      newCursor = formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: newCursor.clamp(0, formatted.length),
      ),
    );
  }

  static int _significantCount(String s, {required bool allowNegative}) {
    var n = 0;
    for (var i = 0; i < s.length; i++) {
      if (_isSignificant(s[i], allowNegative: allowNegative)) n++;
    }
    return n;
  }

  static bool _isSignificant(String ch, {required bool allowNegative}) {
    if (ch == '.' || RegExp(r'\d').hasMatch(ch)) return true;
    if (allowNegative && ch == '-') return true;
    return false;
  }
}
