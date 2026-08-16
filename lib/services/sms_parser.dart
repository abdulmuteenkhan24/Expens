class ParsedSmsExpense {
  final double amount;
  final String title;
  final String categoryId;
  final String raw;
  final DateTime date;
  final bool isDebit;
  final String? location;
  final String? cardLast4;

  const ParsedSmsExpense({
    required this.amount,
    required this.title,
    required this.categoryId,
    required this.raw,
    required this.date,
    this.isDebit = true,
    this.location,
    this.cardLast4,
  });
}

/// Parses common Pakistani bank / wallet / card SMS formats
/// (including ATM cash withdrawals).
class SmsParser {
  static final _amountPatterns = <RegExp>[
    // cash withdrawal of PKR 500.00
    RegExp(
      r'(?:cash\s*withdrawal|withdrawal|withdrawn|debited|purchase|paid|spent|charged|used)\s+(?:of\s+)?(?:PKR|Rs\.?|Rs)\s*([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    ),
    RegExp(r'(?:PKR|Rs\.?|Rs)\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
    RegExp(r'([\d,]+(?:\.\d{1,2})?)\s*(?:PKR|Rs\.?)', caseSensitive: false),
    RegExp(
      r'(?:amount|amt|debited|withdrawn|paid|spent|charged)[:\s]+(?:PKR|Rs\.?)?\s*([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:debited|withdrawn)\s+([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    ),
  ];

  static final _creditHints = RegExp(
    r'credited|received|deposit|cash\s*in|salary|refund',
    caseSensitive: false,
  );

  static final _debitHints = RegExp(
    r'debited|withdrawn|withdrawal|purchase|paid|spent|POS|ATM|transfer\s*to|sent|used for|card ending',
    caseSensitive: false,
  );

  static final _atmHints = RegExp(
    r'cash\s*withdrawal|atm|cash\s*withdraw|withdrawal of|withdrawn at|cash out',
    caseSensitive: false,
  );

  /// Card ending with 2968 / ending 2968 / xx2968
  static final _cardLast4 = RegExp(
    r'(?:ending\s*(?:with)?|card\s*(?:no\.?|number)?\s*[x*]*|xx+|[*]{2,})\s*(\d{4})',
    caseSensitive: false,
  );

   static final _locationAt = RegExp(
    r'\bat\s+([A-Za-z0-9 ,./&\-]{3,60}?)(?:,?\s+on\s+|,?\s+\d{1,2}[-/]|$)',
    caseSensitive: false,
  );

  /// 02-AUG-2026 07:25 PM  |  02-Aug-26  |  02/08/2026
  static final _datePatterns = <RegExp>[
    RegExp(
      r'on\s+(\d{1,2})[-/]([A-Za-z]{3,9})[-/](\d{2,4})(?:\s+(\d{1,2}):(\d{2})\s*(AM|PM)?)?',
      caseSensitive: false,
    ),
    RegExp(
      r'on\s+(\d{1,2})[-/](\d{1,2})[-/](\d{2,4})(?:\s+(\d{1,2}):(\d{2})\s*(AM|PM)?)?',
      caseSensitive: false,
    ),
  ];

  static const _months = <String, int>{
    'jan': 1,
    'january': 1,
    'feb': 2,
    'february': 2,
    'mar': 3,
    'march': 3,
    'apr': 4,
    'april': 4,
    'may': 5,
    'jun': 6,
    'june': 6,
    'jul': 7,
    'july': 7,
    'aug': 8,
    'august': 8,
    'sep': 9,
    'sept': 9,
    'september': 9,
    'oct': 10,
    'october': 10,
    'nov': 11,
    'november': 11,
    'dec': 12,
    'december': 12,
  };

  static ParsedSmsExpense? parse(String text, {DateTime? date}) {
    final cleaned = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) return null;

    double? amount;
    for (final re in _amountPatterns) {
      final m = re.firstMatch(cleaned);
      if (m != null) {
        amount = double.tryParse(m.group(1)!.replaceAll(',', ''));
        if (amount != null && amount > 0) break;
      }
    }
    if (amount == null || amount <= 0) return null;

    final looksDebit =
        _debitHints.hasMatch(cleaned) || _atmHints.hasMatch(cleaned);
    final looksCredit = _creditHints.hasMatch(cleaned) && !looksDebit;
    final isDebit = !looksCredit;

    final isAtm = _atmHints.hasMatch(cleaned);
    final cardLast4 = _cardLast4.firstMatch(cleaned)?.group(1);
    final location = _extractLocation(cleaned, isAtm: isAtm);
    final parsedDate = date ?? _parseDate(cleaned) ?? DateTime.now();

    final title = _guessTitle(
      cleaned,
      isAtm: isAtm,
      location: location,
      cardLast4: cardLast4,
    );
    final categoryId = _guessCategory(cleaned, isAtm: isAtm);

    return ParsedSmsExpense(
      amount: amount,
      title: title,
      categoryId: categoryId,
      raw: cleaned,
      date: parsedDate,
      isDebit: isDebit,
      location: location,
      cardLast4: cardLast4,
    );
  }

  static List<ParsedSmsExpense> parseMany(
    Iterable<({String body, DateTime? date})> messages,
  ) {
    final out = <ParsedSmsExpense>[];
    for (final m in messages) {
      final p = parse(m.body, date: m.date);
      if (p != null && p.isDebit) out.add(p);
    }
    return out;
  }

  static String? _extractLocation(String text, {required bool isAtm}) {
    final m = _locationAt.firstMatch(text);
    if (m == null) return null;
    var loc = m.group(1)!.trim();
    // Drop trailing commas / junk
    loc = loc.replaceAll(RegExp(r'[,\s]+$'), '');
    // Ignore pure time-like leftovers
    if (loc.length < 3) return null;
    // "MAIN BAZAR HARIPUR GRG, HARIPUR" keep first meaningful part
    if (loc.length > 48) loc = '${loc.substring(0, 48).trim()}…';
    return loc;
  }

  static DateTime? _parseDate(String text) {
    for (final re in _datePatterns) {
      final m = re.firstMatch(text);
      if (m == null) continue;
      try {
        final d = int.parse(m.group(1)!);
        final monthRaw = m.group(2)!;
        final yRaw = int.parse(m.group(3)!);
        final year = yRaw < 100 ? 2000 + yRaw : yRaw;

        int month;
        final monthNum = int.tryParse(monthRaw);
        if (monthNum != null) {
          month = monthNum;
        } else {
          month = _months[monthRaw.toLowerCase()] ?? 0;
          if (month == 0) continue;
        }

        var hour = int.tryParse(m.group(4) ?? '') ?? 0;
        final minute = int.tryParse(m.group(5) ?? '') ?? 0;
        final ampm = (m.group(6) ?? '').toUpperCase();
        if (ampm == 'PM' && hour < 12) hour += 12;
        if (ampm == 'AM' && hour == 12) hour = 0;

        return DateTime(year, month, d, hour, minute);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  static String _guessTitle(
    String text, {
    required bool isAtm,
    String? location,
    String? cardLast4,
  }) {
    final lower = text.toLowerCase();

    if (isAtm) {
      if (location != null && location.isNotEmpty) {
        return 'ATM · $location';
      }
      if (cardLast4 != null) return 'ATM withdrawal · ****$cardLast4';
      return 'ATM cash withdrawal';
    }

    if (lower.contains('jazzcash')) return 'JazzCash payment';
    if (lower.contains('easypaisa') || lower.contains('easy paisa')) {
      return 'EasyPaisa payment';
    }
    if (lower.contains('pos') ||
        lower.contains('purchase') ||
        lower.contains('mastercard') ||
        lower.contains('visa') ||
        lower.contains('debit card')) {
      if (location != null && location.isNotEmpty) {
        return 'Card · $location';
      }
      if (cardLast4 != null) return 'Card purchase · ****$cardLast4';
      return 'Card purchase';
    }
    if (lower.contains('uber') ||
        lower.contains('careem') ||
        lower.contains('indrive')) {
      return 'Ride';
    }
    if (lower.contains('daraz')) return 'Daraz order';
    if (lower.contains('fuel') ||
        lower.contains('petrol') ||
        lower.contains('pso') ||
        lower.contains('shell')) {
      return 'Fuel';
    }
    if (lower.contains('load') ||
        lower.contains('recharge') ||
        lower.contains('top-up') ||
        lower.contains('top up')) {
      return 'Mobile top-up';
    }

    if (location != null && location.isNotEmpty) return location;

    final at = RegExp(
      r'(?:at|to|from)\s+([A-Za-z0-9 &.\-]{3,30})',
      caseSensitive: false,
    ).firstMatch(text);
    if (at != null) return at.group(1)!.trim();

    return 'Bank transaction';
  }

  static String _guessCategory(String text, {required bool isAtm}) {
    final lower = text.toLowerCase();

    // ATM / cash first
    if (isAtm) return 'atm';

    if (lower.contains('fuel') ||
        lower.contains('petrol') ||
        lower.contains('pso') ||
        lower.contains('shell') ||
        lower.contains('total parco')) {
      return 'fuel';
    }
    if (lower.contains('uber') ||
        lower.contains('careem') ||
        lower.contains('indrive') ||
        lower.contains('bykea')) {
      return 'transport';
    }
    if (lower.contains('load') ||
        lower.contains('recharge') ||
        lower.contains('top-up') ||
        lower.contains('top up')) {
      return 'mobile';
    }
    // Avoid matching "jazz" inside random words for card SMS
    if (lower.contains('jazzcash') ||
        lower.contains('telenor') ||
        lower.contains('zong') ||
        lower.contains('ufone')) {
      return 'mobile';
    }
    if (lower.contains('daraz') ||
        lower.contains('amazon') ||
        lower.contains('shop')) {
      return 'shopping';
    }
    if (lower.contains('restaurant') ||
        lower.contains('foodpanda') ||
        lower.contains('food') ||
        lower.contains('cafe')) {
      return 'food';
    }
    if (lower.contains('electric') ||
        lower.contains('gas bill') ||
        lower.contains('wapda') ||
        lower.contains('k-electric') ||
        lower.contains('ssgc') ||
        lower.contains('sngpl')) {
      return 'bills';
    }
    if (lower.contains('rent')) return 'rent';
    if (lower.contains('hospital') ||
        lower.contains('pharmacy') ||
        lower.contains('clinic')) {
      return 'health';
    }

    // POS / card spend without clearer merchant → shopping-ish or other
    if (lower.contains('pos') || lower.contains('purchase')) {
      return 'shopping';
    }

    return 'other';
  }

  static const sampleMessages = [
    'Your Neo Islamic MasterCard Debit Card ending with 2968 was used for a cash withdrawal of PKR 500.00 at MAIN ATM  on 02-AUG-2026 07:25 PM.',
    'HBL: Rs 2,450.00 debited from A/C **4521 at DARAZ on 02-Aug-26. Avl Bal Rs 45,200.00',
    'JazzCash: You have sent Rs 500 to 03001234567. Fee Rs 0. Balance Rs 1,250.',
    'Meezan Bank: PKR 3,200 spent at PSO FUEL STATION via debit card. Available: 88,100',
    'EasyPaisa: Rs 1,000 paid for mobile load. Transaction ID 998877.',
    'UBL: ATM Withdrawal of Rs 10,000 from ATM-1234. Available balance Rs 32,000.',
    'Your Visa Debit Card ending with 4412 was used for a purchase of PKR 1,850.00 at AL-FAISAL STORE, ISLAMABAD on 01-AUG-2026 03:10 PM.',
  ];
}
