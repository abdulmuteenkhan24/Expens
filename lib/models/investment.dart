class Investment {
  final String id;
  final String name;
  final String typeId;
  final double amount;
  final double currentValue;
  final DateTime date;
  final String notes;

  const Investment({
    required this.id,
    required this.name,
    required this.typeId,
    required this.amount,
    double? currentValue,
    required this.date,
    this.notes = '',
  }) : currentValue = currentValue ?? amount;

  double get gain => currentValue - amount;
  double get gainPercent => amount == 0 ? 0 : (gain / amount) * 100;

  Investment copyWith({
    String? id,
    String? name,
    String? typeId,
    double? amount,
    double? currentValue,
    DateTime? date,
    String? notes,
  }) {
    return Investment(
      id: id ?? this.id,
      name: name ?? this.name,
      typeId: typeId ?? this.typeId,
      amount: amount ?? this.amount,
      currentValue: currentValue ?? this.currentValue,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'typeId': typeId,
        'amount': amount,
        'currentValue': currentValue,
        'date': date.toIso8601String(),
        'notes': notes,
      };

  factory Investment.fromJson(Map<String, dynamic> json) => Investment(
        id: json['id'] as String,
        name: json['name'] as String,
        typeId: json['typeId'] as String,
        amount: (json['amount'] as num).toDouble(),
        currentValue: (json['currentValue'] as num?)?.toDouble(),
        date: DateTime.parse(json['date'] as String),
        notes: (json['notes'] as String?) ?? '',
      );
}
