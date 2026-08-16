enum LoanDirection {
  /// You gave money to someone (they owe you)
  lent,

  /// You took money from someone (you owe them)
  borrowed,
}

enum LoanStatus { pending, partial, settled }

/// One installment / payment against a loan.
class LoanPayment {
  final String id;
  final String loanId;
  final double amount;
  final DateTime date;
  final String accountId;
  final String method;
  final String note;

  /// Linked expense (when you repay) or income (when they repay you).
  final String? linkedTxnId;

  const LoanPayment({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.date,
    this.accountId = '',
    this.method = 'cash',
    this.note = '',
    this.linkedTxnId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'loanId': loanId,
        'amount': amount,
        'date': date.toIso8601String(),
        'accountId': accountId,
        'method': method,
        'note': note,
        'linkedTxnId': linkedTxnId,
      };

  factory LoanPayment.fromJson(Map<String, dynamic> json) => LoanPayment(
        id: json['id'] as String,
        loanId: json['loanId'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        accountId: (json['accountId'] as String?) ?? '',
        method: (json['method'] as String?) ?? 'cash',
        note: (json['note'] as String?) ?? '',
        linkedTxnId: json['linkedTxnId'] as String?,
      );
}

class Loan {
  final String id;
  final double amount;
  final double paidAmount;
  final String personName;
  final LoanDirection direction;
  final LoanStatus status;
  final DateTime date;
  final DateTime? dueDate;
  final String purpose;
  final String notes;

  /// Account where money entered (borrowed) or left (lent).
  final String accountId;

  /// Linked income id (borrowed) or expense id (lent) when loan was created.
  final String? linkedOpenTxnId;

  const Loan({
    required this.id,
    required this.amount,
    this.paidAmount = 0,
    required this.personName,
    required this.direction,
    this.status = LoanStatus.pending,
    required this.date,
    this.dueDate,
    this.purpose = '',
    this.notes = '',
    this.accountId = '',
    this.linkedOpenTxnId,
  });

  double get remaining => (amount - paidAmount).clamp(0, amount);

  double get progress => amount <= 0 ? 0 : (paidAmount / amount).clamp(0.0, 1.0);

  bool get isSettled => status == LoanStatus.settled || remaining <= 0;

  bool get isOverdue =>
      !isSettled && dueDate != null && dueDate!.isBefore(DateTime.now());

  Loan copyWith({
    String? id,
    double? amount,
    double? paidAmount,
    String? personName,
    LoanDirection? direction,
    LoanStatus? status,
    DateTime? date,
    DateTime? dueDate,
    String? purpose,
    String? notes,
    String? accountId,
    String? linkedOpenTxnId,
    bool clearDueDate = false,
  }) {
    return Loan(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      personName: personName ?? this.personName,
      direction: direction ?? this.direction,
      status: status ?? this.status,
      date: date ?? this.date,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      purpose: purpose ?? this.purpose,
      notes: notes ?? this.notes,
      accountId: accountId ?? this.accountId,
      linkedOpenTxnId: linkedOpenTxnId ?? this.linkedOpenTxnId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'paidAmount': paidAmount,
        'personName': personName,
        'direction': direction.name,
        'status': status.name,
        'date': date.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'purpose': purpose,
        'notes': notes,
        'accountId': accountId,
        'linkedOpenTxnId': linkedOpenTxnId,
      };

  factory Loan.fromJson(Map<String, dynamic> json) => Loan(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
        personName: json['personName'] as String,
        direction: LoanDirection.values.byName(json['direction'] as String),
        status: LoanStatus.values.byName(
          (json['status'] as String?) ?? 'pending',
        ),
        date: DateTime.parse(json['date'] as String),
        dueDate: json['dueDate'] != null
            ? DateTime.parse(json['dueDate'] as String)
            : null,
        purpose: (json['purpose'] as String?) ?? '',
        notes: (json['notes'] as String?) ?? '',
        accountId: (json['accountId'] as String?) ?? '',
        linkedOpenTxnId: json['linkedOpenTxnId'] as String?,
      );
}

const loanPaymentMethods = <String>[
  'Cash',
  'JazzCash',
  'EasyPaisa',
  'Bank transfer',
  'Other',
];
