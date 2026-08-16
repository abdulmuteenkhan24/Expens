class FinanceEvent {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime? endDate;
  final String description;

  const FinanceEvent({
    required this.id,
    required this.name,
    required this.startDate,
    this.endDate,
    this.description = '',
  });

  FinanceEvent copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    bool clearEnd = false,
  }) {
    return FinanceEvent(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: clearEnd ? null : (endDate ?? this.endDate),
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'description': description,
      };

  factory FinanceEvent.fromJson(Map<String, dynamic> json) => FinanceEvent(
        id: json['id'] as String,
        name: json['name'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: json['endDate'] != null
            ? DateTime.parse(json['endDate'] as String)
            : null,
        description: (json['description'] as String?) ?? '',
      );
}
