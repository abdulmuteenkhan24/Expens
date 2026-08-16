/// Unified list item for expenses, incomes, and account transfers.
enum MoneyTxKind { expense, income, transfer }

class MoneyTx {
  final String id;
  final MoneyTxKind kind;
  final double amount;
  final String title;
  final String categoryId;
  final String accountId;
  final String currencyCode;
  final DateTime date;
  final String notes;
  final String receiptPath;
  final String tag;
  final String location;
  final String eventId;
  final bool isRecurring;

  /// Other side of a transfer (to when this is outflow, from when inflow).
  final String relatedAccountId;

  /// For [MoneyTxKind.transfer]: true if money entered [accountId].
  final bool transferIsIn;

  const MoneyTx({
    required this.id,
    required this.kind,
    required this.amount,
    required this.title,
    required this.categoryId,
    required this.accountId,
    required this.currencyCode,
    required this.date,
    this.notes = '',
    this.receiptPath = '',
    this.tag = '',
    this.location = '',
    this.eventId = '',
    this.isRecurring = false,
    this.relatedAccountId = '',
    this.transferIsIn = false,
  });

  bool get isExpense => kind == MoneyTxKind.expense;
  bool get isIncome => kind == MoneyTxKind.income;
  bool get isTransfer => kind == MoneyTxKind.transfer;
  bool get hasReceipt => receiptPath.isNotEmpty;

  /// Money left this account (expense or transfer out).
  bool get isOutflow {
    if (isTransfer) return !transferIsIn;
    return isExpense;
  }
}
