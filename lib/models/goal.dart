/// Savings goal (umrah, phone, emergency fund…).
/// Money lives in a dedicated [savingsAccountId] pot — not spent as expense.
class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;

  /// Fallback if pot account missing (legacy). Prefer balance of [savingsAccountId].
  final double savedAmount;

  /// Dedicated AccountType.savings account holding this goal's money.
  final String savingsAccountId;

  final DateTime? deadline;
  final String iconId;
  final String notes;
  final DateTime createdAt;
  final bool archived;

  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.savedAmount = 0,
    this.savingsAccountId = '',
    this.deadline,
    this.iconId = 'flag',
    this.notes = '',
    required this.createdAt,
    this.archived = false,
  });

  double remainingOf(double saved) =>
      (targetAmount - saved).clamp(0.0, targetAmount);

  double progressOf(double saved) => targetAmount <= 0
      ? 0
      : (saved / targetAmount).clamp(0.0, 1.0);

  bool isCompleteWith(double saved) =>
      saved >= targetAmount && targetAmount > 0;

  double get remaining => remainingOf(savedAmount);

  double get progress => progressOf(savedAmount);

  bool get isComplete => isCompleteWith(savedAmount);

  int? get daysLeft {
    if (deadline == null) return null;
    final now = DateTime.now();
    final d = DateTime(deadline!.year, deadline!.month, deadline!.day);
    final t = DateTime(now.year, now.month, now.day);
    return d.difference(t).inDays;
  }

  SavingsGoal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? savedAmount,
    String? savingsAccountId,
    DateTime? deadline,
    String? iconId,
    String? notes,
    DateTime? createdAt,
    bool? archived,
    bool clearDeadline = false,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      savingsAccountId: savingsAccountId ?? this.savingsAccountId,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      iconId: iconId ?? this.iconId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      archived: archived ?? this.archived,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'targetAmount': targetAmount,
        'savedAmount': savedAmount,
        'savingsAccountId': savingsAccountId,
        'deadline': deadline?.toIso8601String(),
        'iconId': iconId,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'archived': archived,
      };

  factory SavingsGoal.fromJson(Map<String, dynamic> json) => SavingsGoal(
        id: json['id'] as String,
        name: json['name'] as String,
        targetAmount: (json['targetAmount'] as num).toDouble(),
        savedAmount: (json['savedAmount'] as num?)?.toDouble() ?? 0,
        savingsAccountId: (json['savingsAccountId'] as String?) ?? '',
        deadline: json['deadline'] != null
            ? DateTime.parse(json['deadline'] as String)
            : null,
        iconId: (json['iconId'] as String?) ?? 'flag',
        notes: (json['notes'] as String?) ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        archived: (json['archived'] as bool?) ?? false,
      );
}

/// Deposit or withdraw history for a goal pot.
class GoalContribution {
  final String id;
  final String goalId;
  final double amount;
  final DateTime date;
  final String note;

  /// Account money came from (deposit) or went to (withdraw).
  final String accountId;

  /// true = into pot, false = out of pot.
  final bool isDeposit;

  const GoalContribution({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.date,
    this.note = '',
    this.accountId = '',
    this.isDeposit = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'goalId': goalId,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
        'accountId': accountId,
        'isDeposit': isDeposit,
      };

  factory GoalContribution.fromJson(Map<String, dynamic> json) =>
      GoalContribution(
        id: json['id'] as String,
        goalId: json['goalId'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        note: (json['note'] as String?) ?? '',
        accountId: (json['accountId'] as String?) ?? '',
        isDeposit: (json['isDeposit'] as bool?) ?? true,
      );
}

const goalIconIds = <String>[
  'flag',
  'home',
  'car',
  'flight',
  'phone',
  'school',
  'emergency',
  'gift',
  'ring',
  'piggy',
];
