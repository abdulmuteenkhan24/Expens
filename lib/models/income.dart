class Income {
  final String id;
  final double amount;
  final String title;
  final String sourceId;
  final String accountId;
  final String currencyCode;
  final String from;
  final DateTime date;
  final String notes;
  final String receiptPath;
  final String tag;
  final String location;
  final String eventId;
  final bool isRecurring;
  final String recurringRule;

  const Income({
    required this.id,
    required this.amount,
    required this.title,
    required this.sourceId,
    this.accountId = '',
    this.currencyCode = '',
    this.from = '',
    required this.date,
    this.notes = '',
    this.receiptPath = '',
    this.tag = '',
    this.location = '',
    this.eventId = '',
    this.isRecurring = false,
    this.recurringRule = '',
  });

  bool get hasReceipt => receiptPath.isNotEmpty;

  Income copyWith({
    String? id,
    double? amount,
    String? title,
    String? sourceId,
    String? accountId,
    String? currencyCode,
    String? from,
    DateTime? date,
    String? notes,
    String? receiptPath,
    String? tag,
    String? location,
    String? eventId,
    bool? isRecurring,
    String? recurringRule,
    bool clearReceipt = false,
  }) {
    return Income(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      title: title ?? this.title,
      sourceId: sourceId ?? this.sourceId,
      accountId: accountId ?? this.accountId,
      currencyCode: currencyCode ?? this.currencyCode,
      from: from ?? this.from,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      receiptPath: clearReceipt ? '' : (receiptPath ?? this.receiptPath),
      tag: tag ?? this.tag,
      location: location ?? this.location,
      eventId: eventId ?? this.eventId,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringRule: recurringRule ?? this.recurringRule,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'title': title,
        'sourceId': sourceId,
        'accountId': accountId,
        'currencyCode': currencyCode,
        'from': from,
        'date': date.toIso8601String(),
        'notes': notes,
        'receiptPath': receiptPath,
        'tag': tag,
        'location': location,
        'eventId': eventId,
        'isRecurring': isRecurring,
        'recurringRule': recurringRule,
      };

  factory Income.fromJson(Map<String, dynamic> json) => Income(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        title: json['title'] as String,
        sourceId: json['sourceId'] as String,
        accountId: (json['accountId'] as String?) ?? '',
        currencyCode: (json['currencyCode'] as String?) ?? '',
        from: (json['from'] as String?) ?? '',
        date: DateTime.parse(json['date'] as String),
        notes: (json['notes'] as String?) ?? '',
        receiptPath: (json['receiptPath'] as String?) ?? '',
        tag: (json['tag'] as String?) ?? '',
        location: (json['location'] as String?) ?? '',
        eventId: (json['eventId'] as String?) ?? '',
        isRecurring: (json['isRecurring'] as bool?) ?? false,
        recurringRule: (json['recurringRule'] as String?) ?? '',
      );
}
