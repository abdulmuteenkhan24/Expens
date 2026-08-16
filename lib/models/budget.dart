/// Monthly budget: overall cap + per-category limits.
class MonthlyBudget {
  final String id;

  /// First day of the month this budget applies to.
  final DateTime month;

  /// Optional overall spend limit for the month (0 = no overall cap).
  final double overallLimit;

  /// categoryId → limit amount.
  final Map<String, double> categoryLimits;

  final String notes;

  const MonthlyBudget({
    required this.id,
    required this.month,
    this.overallLimit = 0,
    this.categoryLimits = const {},
    this.notes = '',
  });

  DateTime get monthStart => DateTime(month.year, month.month, 1);

  DateTime get monthEndExclusive => DateTime(month.year, month.month + 1, 1);

  MonthlyBudget copyWith({
    String? id,
    DateTime? month,
    double? overallLimit,
    Map<String, double>? categoryLimits,
    String? notes,
  }) {
    return MonthlyBudget(
      id: id ?? this.id,
      month: month ?? this.month,
      overallLimit: overallLimit ?? this.overallLimit,
      categoryLimits: categoryLimits ?? this.categoryLimits,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'month': monthStart.toIso8601String(),
        'overallLimit': overallLimit,
        'categoryLimits': categoryLimits,
        'notes': notes,
      };

  factory MonthlyBudget.fromJson(Map<String, dynamic> json) {
    final raw = json['categoryLimits'];
    final map = <String, double>{};
    if (raw is Map) {
      for (final e in raw.entries) {
        map[e.key.toString()] = (e.value as num).toDouble();
      }
    }
    return MonthlyBudget(
      id: json['id'] as String,
      month: DateTime.parse(json['month'] as String),
      overallLimit: (json['overallLimit'] as num?)?.toDouble() ?? 0,
      categoryLimits: map,
      notes: (json['notes'] as String?) ?? '',
    );
  }
}
