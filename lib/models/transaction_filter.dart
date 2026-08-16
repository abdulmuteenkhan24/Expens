class TransactionFilter {
  final String query;
  final String? categoryId;
  final String? accountId;
  final String? currencyCode;
  final String? eventId;
  final String? tag;
  final DateTime? from;
  final DateTime? to;
  final bool? hasReceipt;
  final double? minAmount;
  final double? maxAmount;

  const TransactionFilter({
    this.query = '',
    this.categoryId,
    this.accountId,
    this.currencyCode,
    this.eventId,
    this.tag,
    this.from,
    this.to,
    this.hasReceipt,
    this.minAmount,
    this.maxAmount,
  });

  bool get isActive =>
      query.trim().isNotEmpty ||
      categoryId != null ||
      accountId != null ||
      currencyCode != null ||
      eventId != null ||
      tag != null ||
      from != null ||
      to != null ||
      hasReceipt != null ||
      minAmount != null ||
      maxAmount != null;

  int get activeCount {
    var n = 0;
    if (query.trim().isNotEmpty) n++;
    if (categoryId != null) n++;
    if (accountId != null) n++;
    if (currencyCode != null) n++;
    if (eventId != null) n++;
    if (tag != null) n++;
    if (from != null || to != null) n++;
    if (hasReceipt != null) n++;
    if (minAmount != null || maxAmount != null) n++;
    return n;
  }

  TransactionFilter copyWith({
    String? query,
    String? categoryId,
    String? accountId,
    String? currencyCode,
    String? eventId,
    String? tag,
    DateTime? from,
    DateTime? to,
    bool? hasReceipt,
    double? minAmount,
    double? maxAmount,
    bool clearCategory = false,
    bool clearAccount = false,
    bool clearCurrency = false,
    bool clearEvent = false,
    bool clearTag = false,
    bool clearDates = false,
    bool clearReceipt = false,
    bool clearAmount = false,
  }) {
    return TransactionFilter(
      query: query ?? this.query,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      accountId: clearAccount ? null : (accountId ?? this.accountId),
      currencyCode: clearCurrency ? null : (currencyCode ?? this.currencyCode),
      eventId: clearEvent ? null : (eventId ?? this.eventId),
      tag: clearTag ? null : (tag ?? this.tag),
      from: clearDates ? null : (from ?? this.from),
      to: clearDates ? null : (to ?? this.to),
      hasReceipt: clearReceipt ? null : (hasReceipt ?? this.hasReceipt),
      minAmount: clearAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearAmount ? null : (maxAmount ?? this.maxAmount),
    );
  }

  static const empty = TransactionFilter();
}
