class FinanceGroup {
  final String id;
  final String name;
  final List<String> members;
  final DateTime createdAt;

  const FinanceGroup({
    required this.id,
    required this.name,
    required this.members,
    required this.createdAt,
  });

  FinanceGroup copyWith({
    String? id,
    String? name,
    List<String>? members,
    DateTime? createdAt,
  }) {
    return FinanceGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'members': members,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FinanceGroup.fromJson(Map<String, dynamic> json) => FinanceGroup(
        id: json['id'] as String,
        name: json['name'] as String,
        members: (json['members'] as List<dynamic>).cast<String>(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class GroupExpense {
  final String id;
  final String groupId;
  final String title;
  final double amount;
  final String paidBy;
  final List<String> splitAmong;
  final DateTime date;
  final String notes;

  const GroupExpense({
    required this.id,
    required this.groupId,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.splitAmong,
    required this.date,
    this.notes = '',
  });

  double get shareEach =>
      splitAmong.isEmpty ? 0 : amount / splitAmong.length;

  GroupExpense copyWith({
    String? id,
    String? groupId,
    String? title,
    double? amount,
    String? paidBy,
    List<String>? splitAmong,
    DateTime? date,
    String? notes,
  }) {
    return GroupExpense(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      paidBy: paidBy ?? this.paidBy,
      splitAmong: splitAmong ?? this.splitAmong,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'title': title,
        'amount': amount,
        'paidBy': paidBy,
        'splitAmong': splitAmong,
        'date': date.toIso8601String(),
        'notes': notes,
      };

  factory GroupExpense.fromJson(Map<String, dynamic> json) => GroupExpense(
        id: json['id'] as String,
        groupId: json['groupId'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        paidBy: json['paidBy'] as String,
        splitAmong: (json['splitAmong'] as List<dynamic>).cast<String>(),
        date: DateTime.parse(json['date'] as String),
        notes: (json['notes'] as String?) ?? '',
      );
}

/// Net balance for a member in a group (positive = others owe them).
Map<String, double> computeBalances(
  List<String> members,
  List<GroupExpense> expenses,
) {
  final balances = {for (final m in members) m: 0.0};
  for (final e in expenses) {
    if (e.splitAmong.isEmpty) continue;
    final share = e.amount / e.splitAmong.length;
    balances[e.paidBy] = (balances[e.paidBy] ?? 0) + e.amount;
    for (final m in e.splitAmong) {
      balances[m] = (balances[m] ?? 0) - share;
    }
  }
  return balances;
}
