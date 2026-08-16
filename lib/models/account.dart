import 'package:flutter/material.dart';

enum AccountType { cash, bank, wallet, card, savings, person }

class MoneyAccount {
  final String id;
  final String name;
  final AccountType type;

  /// Preset id e.g. hbl, jazzcash — used for icon/color/matching SMS.
  final String presetId;

  /// For assets: money you have. For credit cards: current outstanding debt (what you owe).
  final double openingBalance;

  /// Credit card limit only (0 for non-cards).
  final double creditLimit;

  final String notes;
  final bool archived;

  const MoneyAccount({
    required this.id,
    required this.name,
    required this.type,
    this.presetId = '',
    this.openingBalance = 0,
    this.creditLimit = 0,
    this.notes = '',
    this.archived = false,
  });

  bool get isCreditCard => type == AccountType.card;

  MoneyAccount copyWith({
    String? id,
    String? name,
    AccountType? type,
    String? presetId,
    double? openingBalance,
    double? creditLimit,
    String? notes,
    bool? archived,
  }) {
    return MoneyAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      presetId: presetId ?? this.presetId,
      openingBalance: openingBalance ?? this.openingBalance,
      creditLimit: creditLimit ?? this.creditLimit,
      notes: notes ?? this.notes,
      archived: archived ?? this.archived,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'presetId': presetId,
        'openingBalance': openingBalance,
        'creditLimit': creditLimit,
        'notes': notes,
        'archived': archived,
      };

  factory MoneyAccount.fromJson(Map<String, dynamic> json) => MoneyAccount(
        id: json['id'] as String,
        name: json['name'] as String,
        type: AccountType.values.byName(
          (json['type'] as String?) ?? 'cash',
        ),
        presetId: (json['presetId'] as String?) ?? '',
        openingBalance: (json['openingBalance'] as num?)?.toDouble() ?? 0,
        creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0,
        notes: (json['notes'] as String?) ?? '',
        archived: (json['archived'] as bool?) ?? false,
      );
}

/// Transfer between two accounts (does not change total net worth for assets).
/// Paying a credit card: from cash/bank → to credit card (reduces debt).
class AccountTransfer {
  final String id;
  final String fromAccountId;
  final String toAccountId;
  final double amount;
  final DateTime date;
  final String notes;

  const AccountTransfer({
    required this.id,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.date,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromAccountId': fromAccountId,
        'toAccountId': toAccountId,
        'amount': amount,
        'date': date.toIso8601String(),
        'notes': notes,
      };

  factory AccountTransfer.fromJson(Map<String, dynamic> json) =>
      AccountTransfer(
        id: json['id'] as String,
        fromAccountId: json['fromAccountId'] as String,
        toAccountId: json['toAccountId'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        notes: (json['notes'] as String?) ?? '',
      );
}

/// Buy something on installments (often on a credit card / with a shop).
class InstallmentPlan {
  final String id;
  final String title;
  final double totalAmount;
  final double paidAmount;
  final int months;
  final DateTime startDate;
  final String personOrShop;
  final String creditAccountId;
  final String notes;

  const InstallmentPlan({
    required this.id,
    required this.title,
    required this.totalAmount,
    this.paidAmount = 0,
    required this.months,
    required this.startDate,
    this.personOrShop = '',
    this.creditAccountId = '',
    this.notes = '',
  });

  double get remaining =>
      (totalAmount - paidAmount).clamp(0.0, totalAmount);

  double get monthlyAmount =>
      months <= 0 ? totalAmount : totalAmount / months;

  double get progress =>
      totalAmount <= 0 ? 0 : (paidAmount / totalAmount).clamp(0.0, 1.0);

  bool get isSettled => remaining <= 0.01;

  int get paidMonths {
    if (monthlyAmount <= 0) return months;
    return (paidAmount / monthlyAmount).floor().clamp(0, months);
  }

  InstallmentPlan copyWith({
    String? id,
    String? title,
    double? totalAmount,
    double? paidAmount,
    int? months,
    DateTime? startDate,
    String? personOrShop,
    String? creditAccountId,
    String? notes,
  }) {
    return InstallmentPlan(
      id: id ?? this.id,
      title: title ?? this.title,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      months: months ?? this.months,
      startDate: startDate ?? this.startDate,
      personOrShop: personOrShop ?? this.personOrShop,
      creditAccountId: creditAccountId ?? this.creditAccountId,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'months': months,
        'startDate': startDate.toIso8601String(),
        'personOrShop': personOrShop,
        'creditAccountId': creditAccountId,
        'notes': notes,
      };

  factory InstallmentPlan.fromJson(Map<String, dynamic> json) =>
      InstallmentPlan(
        id: json['id'] as String,
        title: json['title'] as String,
        totalAmount: (json['totalAmount'] as num).toDouble(),
        paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
        months: (json['months'] as num?)?.toInt() ?? 1,
        startDate: DateTime.parse(json['startDate'] as String),
        personOrShop: (json['personOrShop'] as String?) ?? '',
        creditAccountId: (json['creditAccountId'] as String?) ?? '',
        notes: (json['notes'] as String?) ?? '',
      );
}

class AccountPreset {
  final String id;
  final String name;
  final AccountType type;
  final IconData icon;
  final Color color;
  final List<String> smsKeywords;

  const AccountPreset({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.smsKeywords = const [],
  });
}
