import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../data/account_presets.dart';
import '../data/currencies.dart';
import '../models/account.dart';
import '../models/budget.dart';
import '../models/event.dart';
import '../models/expense.dart';
import '../models/goal.dart';
import '../models/group.dart';
import '../models/income.dart';
import '../models/investment.dart';
import '../models/loan.dart';
import '../models/money_tx.dart';
import '../models/transaction_filter.dart';
import '../utils/formatters.dart';

const _uuid = Uuid();

class AppState extends ChangeNotifier {
  static const _expensesKey = 'expenses_v1';
  static const _incomesKey = 'incomes_v1';
  static const _loansKey = 'loans_v1';
  static const _loanPaymentsKey = 'loan_payments_v1';
  static const _investmentsKey = 'investments_v1';
  static const _groupsKey = 'groups_v1';
  static const _groupExpensesKey = 'group_expenses_v1';
  static const _accountsKey = 'accounts_v1';
  static const _transfersKey = 'transfers_v1';
  static const _eventsKey = 'events_v1';
  static const _tagsKey = 'custom_tags_v1';
  static const _installmentsKey = 'installments_v1';
  static const _goalsKey = 'savings_goals_v1';
  static const _goalContribKey = 'goal_contributions_v1';
  static const _budgetsKey = 'monthly_budgets_v1';
  static const _themeKey = 'theme_mode_v1';
  static const _currencyKey = 'currency_v1';
  static const _ratesKey = 'rates_v1';

  List<Expense> _expenses = [];
  List<Income> _incomes = [];
  List<Loan> _loans = [];
  List<LoanPayment> _loanPayments = [];
  List<Investment> _investments = [];
  List<FinanceGroup> _groups = [];
  List<GroupExpense> _groupExpenses = [];
  List<MoneyAccount> _accounts = [];
  List<AccountTransfer> _transfers = [];
  List<FinanceEvent> _events = [];
  List<InstallmentPlan> _installments = [];
  List<SavingsGoal> _goals = [];
  List<GoalContribution> _goalContributions = [];
  List<MonthlyBudget> _budgets = [];
  /// User-created tags (plus any used on transactions).
  List<String> _customTags = [];
  ThemeMode _themeMode = ThemeMode.system;
  String _currencyCode = 'PKR';
  Map<String, double> _ratesToPrimary = Map.from(defaultRatesToPkr);
  bool _loaded = false;

  bool get isLoaded => _loaded;
  ThemeMode get themeMode => _themeMode;
  String get currencyCode => _currencyCode;
  Map<String, double> get ratesToPrimary => Map.unmodifiable(_ratesToPrimary);
  AppCurrency get currency => currencyByCode(_currencyCode);

  List<Expense> get expenses {
    final list = [..._expenses]..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<Income> get incomes {
    final list = [..._incomes]..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<Loan> get loans {
    final list = [..._loans]..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<LoanPayment> paymentsForLoan(String loanId) {
    final list =
        _loanPayments.where((p) => p.loanId == loanId).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Loan? loanById(String id) {
    for (final l in _loans) {
      if (l.id == id) return l;
    }
    return null;
  }

  List<Investment> get investments {
    final list = [..._investments]..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<FinanceGroup> get groups {
    final list = [..._groups]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<MoneyAccount> get accounts {
    final list = [..._accounts]
      ..sort((a, b) {
        if (a.archived != b.archived) return a.archived ? 1 : -1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return list;
  }

  List<MoneyAccount> get activeAccounts =>
      accounts.where((a) => !a.archived).toList();

  /// Active accounts sorted by balance (highest first).
  /// Credit cards use amount owed (high debt first among cards).
  List<MoneyAccount> get activeAccountsByBalance {
    final list = activeAccounts;
    list.sort((a, b) {
      final ba = a.isCreditCard ? creditOwed(a.id) : balanceFor(a.id);
      final bb = b.isCreditCard ? creditOwed(b.id) : balanceFor(b.id);
      // Assets first (higher cash), then cards by debt
      if (a.isCreditCard != b.isCreditCard) {
        return a.isCreditCard ? 1 : -1;
      }
      return bb.compareTo(ba);
    });
    return list;
  }

  /// Main accounts only (no goal savings pots) — for Home / Money lists.
  List<MoneyAccount> get mainAccountsByBalance {
    final list = activeAccounts
        .where(
          (a) =>
              a.type != AccountType.savings && !_isGoalSavingsAccount(a.id),
        )
        .toList();
    list.sort((a, b) {
      final ba = a.isCreditCard ? creditOwed(a.id) : balanceFor(a.id);
      final bb = b.isCreditCard ? creditOwed(b.id) : balanceFor(b.id);
      if (a.isCreditCard != b.isCreditCard) {
        return a.isCreditCard ? 1 : -1;
      }
      return bb.compareTo(ba);
    });
    return list;
  }

  List<MoneyAccount> get creditCards =>
      activeAccounts.where((a) => a.isCreditCard).toList();

  /// All non-credit accounts (includes goal savings pots).
  List<MoneyAccount> get assetAccounts =>
      activeAccounts.where((a) => !a.isCreditCard).toList();

  /// Cash / bank / wallet only — money you can spend day-to-day.
  List<MoneyAccount> get spendableAccounts => activeAccounts
      .where(
        (a) =>
            !a.isCreditCard &&
            a.type != AccountType.savings &&
            !_isGoalSavingsAccount(a.id),
      )
      .toList();

  /// Dedicated goal savings pots.
  List<MoneyAccount> get goalSavingsAccounts => activeAccounts
      .where(
        (a) =>
            a.type == AccountType.savings || _isGoalSavingsAccount(a.id),
      )
      .toList();

  bool _isGoalSavingsAccount(String accountId) {
    for (final g in _goals) {
      if (g.savingsAccountId == accountId) return true;
    }
    return false;
  }

  SavingsGoal? goalForSavingsAccount(String accountId) {
    for (final g in _goals) {
      if (g.savingsAccountId == accountId) return g;
    }
    return null;
  }

  List<InstallmentPlan> get installments {
    final list = [..._installments]
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    return list;
  }

  List<InstallmentPlan> installmentsForCard(String accountId) =>
      installments.where((p) => p.creditAccountId == accountId).toList();

  List<InstallmentPlan> get activeInstallments =>
      installments.where((p) => !p.isSettled).toList();

  List<SavingsGoal> get goals {
    final list = _goals.where((g) => !g.archived).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<SavingsGoal> get allGoals {
    final list = [..._goals]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  SavingsGoal? goalById(String id) {
    for (final g in _goals) {
      if (g.id == id) return g;
    }
    return null;
  }

  List<GoalContribution> contributionsForGoal(String goalId) {
    final list = _goalContributions.where((c) => c.goalId == goalId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// Money currently sitting in goal savings pots.
  double savedForGoal(SavingsGoal goal) {
    if (goal.savingsAccountId.isNotEmpty) {
      final acc = accountById(goal.savingsAccountId);
      if (acc != null) return balanceFor(goal.savingsAccountId);
    }
    return goal.savedAmount;
  }

  double get totalGoalsSaved =>
      goals.fold(0.0, (s, g) => s + savedForGoal(g));

  double get totalGoalsTarget =>
      goals.fold(0.0, (s, g) => s + g.targetAmount);

  /// Spendable money (excludes credit debt and goal pots).
  double get spendableBalance =>
      spendableAccounts.fold(0.0, (s, a) => s + balanceFor(a.id));

  MonthlyBudget? budgetForMonth(DateTime month) {
    final key = DateTime(month.year, month.month);
    for (final b in _budgets) {
      final m = DateTime(b.month.year, b.month.month);
      if (m == key) return b;
    }
    return null;
  }

  MonthlyBudget? get thisMonthBudget => budgetForMonth(DateTime.now());

  List<AccountTransfer> get transfers {
    final list = [..._transfers]..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<FinanceEvent> get events {
    final list = [..._events]..sort((a, b) => b.startDate.compareTo(a.startDate));
    return list;
  }

  /// All tags: saved custom tags + any already used on expenses/income.
  List<String> get allTags {
    final set = <String>{..._customTags};
    for (final e in _expenses) {
      final t = e.tag.trim();
      if (t.isNotEmpty) set.add(t);
    }
    for (final e in _incomes) {
      final t = e.tag.trim();
      if (t.isNotEmpty) set.add(t);
    }
    final list = set.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  FinanceEvent? eventById(String id) {
    for (final e in _events) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// All money movements newest first (expenses + incomes).
  List<MoneyTx> get allTransactions {
    final list = <MoneyTx>[
      ..._expenses.map(
        (e) => MoneyTx(
          id: e.id,
          kind: MoneyTxKind.expense,
          amount: e.amount,
          title: e.title,
          categoryId: e.categoryId,
          accountId: e.accountId,
          currencyCode: e.currencyCode,
          date: e.date,
          notes: e.notes,
          receiptPath: e.receiptPath,
          tag: e.tag,
          location: e.location,
          eventId: e.eventId,
          isRecurring: e.isRecurring,
        ),
      ),
      ..._incomes.map(
        (e) => MoneyTx(
          id: e.id,
          kind: MoneyTxKind.income,
          amount: e.amount,
          title: e.title,
          categoryId: e.sourceId,
          accountId: e.accountId,
          currencyCode: e.currencyCode,
          date: e.date,
          notes: e.notes,
          receiptPath: e.receiptPath,
          tag: e.tag,
          location: e.location,
          eventId: e.eventId,
          isRecurring: e.isRecurring,
        ),
      ),
      // Goal deposits / account moves — money cut from one account into another.
      ..._transfers.map(
        (t) => MoneyTx(
          id: t.id,
          kind: MoneyTxKind.transfer,
          amount: t.amount,
          title: t.notes.isEmpty ? 'Transfer' : t.notes,
          categoryId: 'transfer',
          accountId: t.fromAccountId,
          relatedAccountId: t.toAccountId,
          currencyCode: _currencyCode,
          date: t.date,
          notes: t.notes,
          transferIsIn: false,
        ),
      ),
    ]..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<MoneyTx> transactionsInMonth(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return allTransactions
        .where((t) => !t.date.isBefore(start) && t.date.isBefore(end))
        .toList();
  }

  /// Filter unified expense+income+transfer list (Money screen).
  /// [kind] null = all, or expense / income / transfer only.
  List<MoneyTx> filterMoneyTransactions(
    TransactionFilter f, {
    MoneyTxKind? kind,
  }) {
    return allTransactions.where((t) {
      if (kind != null && t.kind != kind) return false;
      if (f.query.trim().isNotEmpty) {
        final q = f.query.trim().toLowerCase();
        final hay =
            '${t.title} ${t.notes} ${t.categoryId} ${t.accountId} ${t.relatedAccountId} ${t.tag} ${t.eventId} ${t.location}'
                .toLowerCase();
        if (!hay.contains(q)) return false;
      }
      if (f.categoryId != null && t.categoryId != f.categoryId) return false;
      if (f.accountId != null) {
        if (t.isTransfer) {
          if (t.accountId != f.accountId &&
              t.relatedAccountId != f.accountId) {
            return false;
          }
        } else if (t.accountId != f.accountId) {
          return false;
        }
      }
      if (f.eventId != null) {
        if (f.eventId!.isEmpty) {
          if (t.eventId.isNotEmpty) return false;
        } else if (t.eventId != f.eventId) {
          return false;
        }
      }
      if (f.tag != null) {
        if (f.tag!.isEmpty) {
          if (t.tag.trim().isNotEmpty) return false;
        } else if (t.tag.trim().toLowerCase() != f.tag!.trim().toLowerCase()) {
          return false;
        }
      }
      if (f.currencyCode != null &&
          (t.currencyCode.isEmpty ? _currencyCode : t.currencyCode) !=
              f.currencyCode) {
        return false;
      }
      if (f.hasReceipt != null && t.hasReceipt != f.hasReceipt) return false;
      if (f.from != null && t.date.isBefore(f.from!)) return false;
      if (f.to != null) {
        final end = DateTime(f.to!.year, f.to!.month, f.to!.day, 23, 59, 59);
        if (t.date.isAfter(end)) return false;
      }
      if (f.minAmount != null && t.amount < f.minAmount!) return false;
      if (f.maxAmount != null && t.amount > f.maxAmount!) return false;
      return true;
    }).toList();
  }

  List<MoneyTx> transactionsForAccount(String accountId, {DateTime? month}) {
    bool inMonth(DateTime d) {
      if (month == null) return true;
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 1);
      return !d.isBefore(start) && d.isBefore(end);
    }

    final list = <MoneyTx>[
      // Expense / income on this account only (not transfer stubs).
      ...allTransactions.where(
        (t) =>
            !t.isTransfer && t.accountId == accountId && inMonth(t.date),
      ),
    ];

    // Transfers appear on both sides: cut-from (out) and destination (in).
    for (final t in _transfers) {
      if (!inMonth(t.date)) continue;
      final title = t.notes.isEmpty ? 'Transfer' : t.notes;
      if (t.fromAccountId == accountId) {
        list.add(
          MoneyTx(
            id: '${t.id}_out',
            kind: MoneyTxKind.transfer,
            amount: t.amount,
            title: title,
            categoryId: 'transfer',
            accountId: accountId,
            relatedAccountId: t.toAccountId,
            currencyCode: _currencyCode,
            date: t.date,
            notes: t.notes,
            transferIsIn: false,
          ),
        );
      }
      if (t.toAccountId == accountId) {
        list.add(
          MoneyTx(
            id: '${t.id}_in',
            kind: MoneyTxKind.transfer,
            amount: t.amount,
            title: title,
            categoryId: 'transfer',
            accountId: accountId,
            relatedAccountId: t.fromAccountId,
            currencyCode: _currencyCode,
            date: t.date,
            notes: t.notes,
            transferIsIn: true,
          ),
        );
      }
    }

    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  double inflowForAccount(String accountId, DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    var total = 0.0;
    for (final i in _incomes) {
      if (i.accountId != accountId) continue;
      if (!_inRange(i.date, start, end)) continue;
      total += amountInPrimary(i.amount, i.currencyCode);
    }
    for (final t in _transfers) {
      if (t.toAccountId != accountId) continue;
      if (!_inRange(t.date, start, end)) continue;
      total += t.amount;
    }
    return total;
  }

  double outflowForAccount(String accountId, DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    var total = 0.0;
    for (final e in _expenses) {
      if (e.accountId != accountId) continue;
      if (!_inRange(e.date, start, end)) continue;
      total += amountInPrimary(e.amount, e.currencyCode);
    }
    for (final t in _transfers) {
      if (t.fromAccountId != accountId) continue;
      if (!_inRange(t.date, start, end)) continue;
      total += t.amount;
    }
    return total;
  }

  List<MoneyAccount> get savingsAccounts =>
      activeAccounts.where((a) => a.type == AccountType.savings).toList();

  double get totalSavings =>
      savingsAccounts.fold(0.0, (s, a) => s + balanceFor(a.id));

  /// Day-to-day money (cash/bank/wallet). Goal pots are separate under Goals.
  double get whatYouHave => spendableBalance;

  /// Full assets including goal savings pots (excludes credit debt).
  double get totalIncludingGoals => totalAssetBalance;

  /// Sum of credit card outstanding (what you owe).
  double get totalCreditDebt =>
      creditCards.fold(0.0, (s, a) => s + creditOwed(a.id));

  /// Assets minus credit card debt.
  double get netWorth => whatYouHave - totalCreditDebt;

  double get totalInstallmentsRemaining => activeInstallments.fold(
        0.0,
        (s, p) => s + p.remaining,
      );

  List<GroupExpense> groupExpensesFor(String groupId) {
    final list = _groupExpenses.where((e) => e.groupId == groupId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  MoneyAccount? accountById(String id) {
    for (final a in _accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  String get defaultAccountId {
    if (_accounts.isEmpty) return '';
    // Prefer spendable cash/bank — never a goal pot or credit card.
    final cash = _accounts.where(
      (a) =>
          !a.archived &&
          a.type == AccountType.cash &&
          !_isGoalSavingsAccount(a.id),
    );
    if (cash.isNotEmpty) return cash.first.id;
    final spendable = _accounts.where(
      (a) =>
          !a.archived &&
          !a.isCreditCard &&
          a.type != AccountType.savings &&
          !_isGoalSavingsAccount(a.id),
    );
    if (spendable.isNotEmpty) return spendable.first.id;
    final active = _accounts.where((a) => !a.archived);
    return active.isNotEmpty ? active.first.id : _accounts.first.id;
  }

  /// Sync goal savedAmount from linked savings accounts; migrate old goal expenses.
  void _ensureGoalSavingsAccounts() {
    // Clear broken links (missing account).
    for (var i = 0; i < _goals.length; i++) {
      final g = _goals[i];
      if (g.savingsAccountId.isNotEmpty &&
          accountById(g.savingsAccountId) == null) {
        _goals[i] = g.copyWith(savingsAccountId: '');
      }
    }

    // Convert old "Saved · goal" expenses into transfers into linked savings.
    final toRemove = <String>{};
    for (final e in _expenses) {
      if (e.tag.toLowerCase() != 'goal') continue;
      SavingsGoal? match;
      for (final g in _goals) {
        if (g.savingsAccountId.isEmpty) continue;
        if (e.title == 'Saved · ${g.name}' || e.title.contains(g.name)) {
          match = g;
          break;
        }
      }
      if (match == null) continue;
      final potId = match.savingsAccountId;
      if (e.accountId == potId) continue;
      _transfers.add(
        AccountTransfer(
          id: newId(),
          fromAccountId: e.accountId,
          toAccountId: potId,
          amount: e.amount,
          date: e.date,
          notes: e.notes.isEmpty
              ? 'Migrated goal deposit · ${match.name}'
              : e.notes,
        ),
      );
      toRemove.add(e.id);
    }
    if (toRemove.isNotEmpty) {
      _expenses.removeWhere((e) => toRemove.contains(e.id));
    }

    for (var i = 0; i < _goals.length; i++) {
      final g = _goals[i];
      if (g.savingsAccountId.isEmpty) continue;
      _goals[i] = g.copyWith(savedAmount: balanceFor(g.savingsAccountId));
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString(_themeKey);
    if (theme != null) _themeMode = ThemeMode.values.byName(theme);

    _currencyCode = prefs.getString(_currencyKey) ?? 'PKR';
    final ratesRaw = prefs.getString(_ratesKey);
    if (ratesRaw != null && ratesRaw.isNotEmpty) {
      try {
        final map = jsonDecode(ratesRaw) as Map<String, dynamic>;
        _ratesToPrimary = {
          for (final e in map.entries) e.key: (e.value as num).toDouble(),
        };
      } catch (_) {
        _ratesToPrimary = Map.from(defaultRatesToPkr);
      }
    }
    _applyMoneyFormat();

    _expenses = _decodeList(prefs.getString(_expensesKey), Expense.fromJson);
    _incomes = _decodeList(prefs.getString(_incomesKey), Income.fromJson);
    _loans = _decodeList(prefs.getString(_loansKey), Loan.fromJson);
    _loanPayments =
        _decodeList(prefs.getString(_loanPaymentsKey), LoanPayment.fromJson);
    _investments =
        _decodeList(prefs.getString(_investmentsKey), Investment.fromJson);
    _groups = _decodeList(prefs.getString(_groupsKey), FinanceGroup.fromJson);
    _groupExpenses =
        _decodeList(prefs.getString(_groupExpensesKey), GroupExpense.fromJson);
    _accounts = _decodeList(prefs.getString(_accountsKey), MoneyAccount.fromJson);
    _transfers =
        _decodeList(prefs.getString(_transfersKey), AccountTransfer.fromJson);
    _events = _decodeList(prefs.getString(_eventsKey), FinanceEvent.fromJson);
    _installments =
        _decodeList(prefs.getString(_installmentsKey), InstallmentPlan.fromJson);
    _goals = _decodeList(prefs.getString(_goalsKey), SavingsGoal.fromJson);
    _goalContributions =
        _decodeList(prefs.getString(_goalContribKey), GoalContribution.fromJson);
    _budgets =
        _decodeList(prefs.getString(_budgetsKey), MonthlyBudget.fromJson);
    _customTags = _decodeStringList(prefs.getString(_tagsKey));

    if (_accounts.isEmpty) {
      _accounts = _defaultAccounts();
    }

    // Ensure every goal has a dedicated savings pot account.
    _ensureGoalSavingsAccounts();

    // Migrate old transactions without accountId / currency.
    final def = defaultAccountId;
    _expenses = _expenses.map((e) {
      var x = e;
      if (x.accountId.isEmpty && def.isNotEmpty) {
        x = x.copyWith(accountId: def);
      }
      if (x.currencyCode.isEmpty) {
        x = x.copyWith(currencyCode: _currencyCode);
      }
      return x;
    }).toList();
    _incomes = _incomes.map((e) {
      var x = e;
      if (x.accountId.isEmpty && def.isNotEmpty) {
        x = x.copyWith(accountId: def);
      }
      if (x.currencyCode.isEmpty) {
        x = x.copyWith(currencyCode: _currencyCode);
      }
      return x;
    }).toList();

    _loaded = true;
    notifyListeners();
    await _persist();
  }

  void _applyMoneyFormat() {
    MoneyFormat.configure(
      primaryCode: _currencyCode,
      ratesToPrimary: _ratesToPrimary,
    );
  }

  List<MoneyAccount> _defaultAccounts() => [
        MoneyAccount(
          id: newId(),
          name: 'Cash',
          type: AccountType.cash,
          presetId: 'cash',
        ),
        MoneyAccount(
          id: newId(),
          name: 'JazzCash',
          type: AccountType.wallet,
          presetId: 'jazzcash',
        ),
        MoneyAccount(
          id: newId(),
          name: 'EasyPaisa',
          type: AccountType.wallet,
          presetId: 'easypaisa',
        ),
        MoneyAccount(
          id: newId(),
          name: 'HBL',
          type: AccountType.bank,
          presetId: 'hbl',
        ),
      ];

  List<T> _decodeList<T>(
    String? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<String> _decodeStringList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Remember tag in the list (no persist). Returns true if newly added.
  bool _rememberTag(String tag) {
    final t = tag.trim();
    if (t.isEmpty) return false;
    final exists = _customTags.any((x) => x.toLowerCase() == t.toLowerCase());
    if (exists) return false;
    _customTags.add(t);
    return true;
  }

  /// Register a tag so it appears in the choose/create picker.
  Future<void> ensureTag(String tag) async {
    if (!_rememberTag(tag)) return;
    notifyListeners();
    await _persist();
  }

  Future<void> deleteCustomTag(String tag) async {
    final t = tag.trim().toLowerCase();
    _customTags.removeWhere((x) => x.toLowerCase() == t);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _expensesKey,
      jsonEncode(_expenses.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      _incomesKey,
      jsonEncode(_incomes.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      _loansKey,
      jsonEncode(_loans.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      _loanPaymentsKey,
      jsonEncode(_loanPayments.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      _investmentsKey,
      jsonEncode(_investments.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      _groupsKey,
      jsonEncode(_groups.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      _groupExpensesKey,
      jsonEncode(_groupExpenses.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      _accountsKey,
      jsonEncode(_accounts.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      _transfersKey,
      jsonEncode(_transfers.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      _eventsKey,
      jsonEncode(_events.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      _installmentsKey,
      jsonEncode(_installments.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      _goalsKey,
      jsonEncode(_goals.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      _goalContribKey,
      jsonEncode(_goalContributions.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      _budgetsKey,
      jsonEncode(_budgets.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(_tagsKey, jsonEncode(_customTags));
    await prefs.setString(_currencyKey, _currencyCode);
    await prefs.setString(_ratesKey, jsonEncode(_ratesToPrimary));
    await prefs.setString(_themeKey, _themeMode.name);
  }

  // ── Backup export / import ────────────────────────────────

  static const backupFormat = 'expens_backup';
  static const backupVersion = 1;

  /// Full app data as a JSON map (for file export).
  Map<String, dynamic> exportBackupMap() {
    return {
      'format': backupFormat,
      'version': backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'app': 'Expens',
      'data': {
        'expenses': _expenses.map((e) => e.toJson()).toList(),
        'incomes': _incomes.map((e) => e.toJson()).toList(),
        'loans': _loans.map((e) => e.toJson()).toList(),
        'loanPayments': _loanPayments.map((e) => e.toJson()).toList(),
        'investments': _investments.map((e) => e.toJson()).toList(),
        'groups': _groups.map((e) => e.toJson()).toList(),
        'groupExpenses': _groupExpenses.map((e) => e.toJson()).toList(),
        'accounts': _accounts.map((e) => e.toJson()).toList(),
        'transfers': _transfers.map((e) => e.toJson()).toList(),
        'events': _events.map((e) => e.toJson()).toList(),
        'installments': _installments.map((e) => e.toJson()).toList(),
        'goals': _goals.map((e) => e.toJson()).toList(),
        'goalContributions':
            _goalContributions.map((e) => e.toJson()).toList(),
        'budgets': _budgets.map((e) => e.toJson()).toList(),
        'customTags': _customTags,
        'currencyCode': _currencyCode,
        'ratesToPrimary': _ratesToPrimary,
        'themeMode': _themeMode.name,
      },
    };
  }

  String exportBackupJson() {
    return const JsonEncoder.withIndent('  ').convert(exportBackupMap());
  }

  /// Counts for backup summary.
  Map<String, int> get backupCounts => {
        'accounts': _accounts.length,
        'expenses': _expenses.length,
        'incomes': _incomes.length,
        'loans': _loans.length,
        'events': _events.length,
        'transfers': _transfers.length,
        'investments': _investments.length,
        'tags': _customTags.length,
      };

  /// Restore from a backup JSON string. Replaces all local finance data.
  Future<void> importBackupJson(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw FormatException('Backup is not a valid JSON object');
    }
    await importBackupMap(Map<String, dynamic>.from(decoded));
  }

  Future<void> importBackupMap(Map<String, dynamic> root) async {
    final format = root['format'] as String?;
    if (format != null && format != backupFormat) {
      throw FormatException('Not an Expens backup file');
    }

    final dataRaw = root['data'];
    final Map<String, dynamic> data;
    if (dataRaw is Map) {
      data = Map<String, dynamic>.from(dataRaw);
    } else if (root.containsKey('expenses') || root.containsKey('accounts')) {
      // Allow raw data map without wrapper.
      data = root;
    } else {
      throw FormatException('Backup has no data');
    }

    List<Map<String, dynamic>> asMaps(dynamic v) {
      if (v is! List) return [];
      return v
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    _expenses = asMaps(data['expenses']).map(Expense.fromJson).toList();
    _incomes = asMaps(data['incomes']).map(Income.fromJson).toList();
    _loans = asMaps(data['loans']).map(Loan.fromJson).toList();
    _loanPayments =
        asMaps(data['loanPayments']).map(LoanPayment.fromJson).toList();
    _investments =
        asMaps(data['investments']).map(Investment.fromJson).toList();
    _groups = asMaps(data['groups']).map(FinanceGroup.fromJson).toList();
    _groupExpenses =
        asMaps(data['groupExpenses']).map(GroupExpense.fromJson).toList();
    _accounts = asMaps(data['accounts']).map(MoneyAccount.fromJson).toList();
    _transfers =
        asMaps(data['transfers']).map(AccountTransfer.fromJson).toList();
    _events = asMaps(data['events']).map(FinanceEvent.fromJson).toList();
    _installments =
        asMaps(data['installments']).map(InstallmentPlan.fromJson).toList();
    _goals = asMaps(data['goals']).map(SavingsGoal.fromJson).toList();
    _goalContributions = asMaps(data['goalContributions'])
        .map(GoalContribution.fromJson)
        .toList();
    _budgets = asMaps(data['budgets']).map(MonthlyBudget.fromJson).toList();

    final tags = data['customTags'];
    if (tags is List) {
      _customTags = tags
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else {
      _customTags = [];
    }

    final currency = data['currencyCode'] as String?;
    if (currency != null && currency.isNotEmpty) {
      _currencyCode = currency;
    }

    final rates = data['ratesToPrimary'];
    if (rates is Map) {
      _ratesToPrimary = {
        for (final e in rates.entries) e.key.toString(): (e.value as num).toDouble(),
      };
    }

    final theme = data['themeMode'] as String?;
    if (theme != null) {
      try {
        _themeMode = ThemeMode.values.byName(theme);
      } catch (_) {}
    }

    if (_accounts.isEmpty) {
      _accounts = _defaultAccounts();
    }

    _applyMoneyFormat();
    notifyListeners();
    await _persist();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  void cycleTheme() {
    final next = switch (_themeMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    setThemeMode(next);
  }

  Future<void> setCurrencyCode(String code) async {
    _currencyCode = code;
    _ratesToPrimary[code] = 1;
    _applyMoneyFormat();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, _currencyCode);
    await prefs.setString(_ratesKey, jsonEncode(_ratesToPrimary));
  }

  Future<void> setExchangeRate(String code, double rateToPrimary) async {
    if (code == _currencyCode) {
      _ratesToPrimary[code] = 1;
    } else {
      _ratesToPrimary[code] = rateToPrimary <= 0 ? 1 : rateToPrimary;
    }
    _applyMoneyFormat();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ratesKey, jsonEncode(_ratesToPrimary));
  }

  double amountInPrimary(double amount, String currencyCode) {
    final code = currencyCode.isEmpty ? _currencyCode : currencyCode;
    return MoneyFormat.toPrimary(amount, code);
  }

  // ── Expenses ──────────────────────────────────────────────

  Future<void> addExpense(Expense expense) async {
    _expenses.add(expense);
    _rememberTag(expense.tag);
    notifyListeners();
    await _persist();
  }

  Future<void> updateExpense(Expense expense) async {
    final i = _expenses.indexWhere((e) => e.id == expense.id);
    if (i == -1) return;
    _expenses[i] = expense;
    _rememberTag(expense.tag);
    notifyListeners();
    await _persist();
  }

  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persist();
  }

  // ── Income ────────────────────────────────────────────────

  Future<void> addIncome(Income income) async {
    _incomes.add(income);
    _rememberTag(income.tag);
    notifyListeners();
    await _persist();
  }

  Future<void> updateIncome(Income income) async {
    final i = _incomes.indexWhere((e) => e.id == income.id);
    if (i == -1) return;
    _incomes[i] = income;
    _rememberTag(income.tag);
    notifyListeners();
    await _persist();
  }

  Future<void> deleteIncome(String id) async {
    _incomes.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persist();
  }

  // ── Loans ─────────────────────────────────────────────────

  /// Create loan and move money into / out of an account so you can use it.
  ///
  /// Borrowed → income into [accountId] (you received money).
  /// Lent     → expense from [accountId] (money left your pocket).
  Future<Loan> createLoan({
    required Loan loan,
    required String accountId,
    bool affectBalance = true,
  }) async {
    String? openTxnId;
    final currency = _currencyCode;

    if (affectBalance && accountId.isNotEmpty) {
      if (loan.direction == LoanDirection.borrowed) {
        // Money came in — you can spend it.
        final income = Income(
          id: newId(),
          amount: loan.amount,
          title: 'Loan from ${loan.personName}',
          sourceId: 'loan',
          accountId: accountId,
          currencyCode: currency,
          from: loan.personName,
          date: loan.date,
          notes: loan.purpose.isEmpty
              ? 'Borrowed — must repay'
              : 'Borrowed for ${loan.purpose}',
        );
        _incomes.add(income);
        openTxnId = income.id;
      } else {
        // Money went out — you lent it.
        final expense = Expense(
          id: newId(),
          amount: loan.amount,
          title: 'Loan to ${loan.personName}',
          categoryId: 'loan',
          accountId: accountId,
          currencyCode: currency,
          date: loan.date,
          notes: loan.purpose.isEmpty
              ? 'Lent — expect repayment'
              : 'Lent for ${loan.purpose}',
        );
        _expenses.add(expense);
        openTxnId = expense.id;
      }
    }

    final saved = loan.copyWith(
      accountId: accountId,
      linkedOpenTxnId: openTxnId,
    );
    _loans.add(saved);
    notifyListeners();
    await _persist();
    return saved;
  }

  Future<void> addLoan(Loan loan) async {
    _loans.add(loan);
    notifyListeners();
    await _persist();
  }

  Future<void> updateLoan(Loan loan) async {
    final i = _loans.indexWhere((e) => e.id == loan.id);
    if (i == -1) return;
    _loans[i] = loan;
    notifyListeners();
    await _persist();
  }

  Future<void> deleteLoan(String id) async {
    _loans.removeWhere((e) => e.id == id);
    _loanPayments.removeWhere((p) => p.loanId == id);
    notifyListeners();
    await _persist();
  }

  /// Record a payback installment and move money between people & accounts.
  ///
  /// Borrowed: you pay them → expense from account.
  /// Lent: they pay you → income into account.
  Future<void> recordLoanPayment({
    required String loanId,
    required double amount,
    required String accountId,
    DateTime? date,
    String method = 'Cash',
    String note = '',
  }) async {
    final i = _loans.indexWhere((e) => e.id == loanId);
    if (i == -1 || amount <= 0) return;
    final loan = _loans[i];
    final payAmount = amount.clamp(0.0, loan.remaining);
    if (payAmount <= 0) return;

    final payDate = date ?? DateTime.now();
    String? linkedId;

    if (accountId.isNotEmpty) {
      if (loan.direction == LoanDirection.borrowed) {
        // You repay — money leaves your account.
        final expense = Expense(
          id: newId(),
          amount: payAmount,
          title: 'Repay ${loan.personName}',
          categoryId: 'loan',
          accountId: accountId,
          currencyCode: _currencyCode,
          date: payDate,
          notes: note.isEmpty ? 'Loan repayment' : note,
        );
        _expenses.add(expense);
        linkedId = expense.id;
      } else {
        // They repay you — money enters your account.
        final income = Income(
          id: newId(),
          amount: payAmount,
          title: 'Received from ${loan.personName}',
          sourceId: 'loan',
          accountId: accountId,
          currencyCode: _currencyCode,
          from: loan.personName,
          date: payDate,
          notes: note.isEmpty ? 'Loan repayment received' : note,
        );
        _incomes.add(income);
        linkedId = income.id;
      }
    }

    final payment = LoanPayment(
      id: newId(),
      loanId: loanId,
      amount: payAmount,
      date: payDate,
      accountId: accountId,
      method: method,
      note: note,
      linkedTxnId: linkedId,
    );
    _loanPayments.add(payment);

    final paid = (loan.paidAmount + payAmount).clamp(0.0, loan.amount);
    final status = paid >= loan.amount
        ? LoanStatus.settled
        : paid > 0
            ? LoanStatus.partial
            : LoanStatus.pending;
    _loans[i] = loan.copyWith(paidAmount: paid, status: status);
    notifyListeners();
    await _persist();
  }

  Future<void> deleteLoanPayment(String paymentId) async {
    LoanPayment? p;
    for (final e in _loanPayments) {
      if (e.id == paymentId) {
        p = e;
        break;
      }
    }
    if (p == null) return;
    final payment = p;
    _loanPayments.removeWhere((e) => e.id == paymentId);

    // Soft reverse: remove linked txn if still exists.
    final linkedId = payment.linkedTxnId;
    if (linkedId != null) {
      _expenses.removeWhere((e) => e.id == linkedId);
      _incomes.removeWhere((e) => e.id == linkedId);
    }

    final i = _loans.indexWhere((e) => e.id == payment.loanId);
    if (i != -1) {
      final loan = _loans[i];
      final paid = (loan.paidAmount - payment.amount).clamp(0.0, loan.amount);
      final status = paid >= loan.amount
          ? LoanStatus.settled
          : paid > 0
              ? LoanStatus.partial
              : LoanStatus.pending;
      _loans[i] = loan.copyWith(paidAmount: paid, status: status);
    }
    notifyListeners();
    await _persist();
  }


  // ── Events ────────────────────────────────────────────────

  Future<void> addEvent(FinanceEvent event) async {
    _events.add(event);
    notifyListeners();
    await _persist();
  }

  Future<void> updateEvent(FinanceEvent event) async {
    final i = _events.indexWhere((e) => e.id == event.id);
    if (i == -1) return;
    _events[i] = event;
    notifyListeners();
    await _persist();
  }

  Future<void> deleteEvent(String id) async {
    _events.removeWhere((e) => e.id == id);
    _expenses = _expenses
        .map((e) => e.eventId == id ? e.copyWith(eventId: '') : e)
        .toList();
    _incomes = _incomes
        .map((e) => e.eventId == id ? e.copyWith(eventId: '') : e)
        .toList();
    notifyListeners();
    await _persist();
  }

  double eventSpend(String eventId) {
    return _expenses
        .where((e) => e.eventId == eventId)
        .fold(0.0, (s, e) => s + amountInPrimary(e.amount, e.currencyCode));
  }

  double eventIncome(String eventId) {
    return _incomes
        .where((e) => e.eventId == eventId)
        .fold(0.0, (s, e) => s + amountInPrimary(e.amount, e.currencyCode));
  }

  /// All expenses + incomes linked to an event (newest first).
  List<MoneyTx> transactionsForEvent(String eventId) {
    final list = <MoneyTx>[
      ..._expenses.where((e) => e.eventId == eventId).map(
            (e) => MoneyTx(
              id: e.id,
              kind: MoneyTxKind.expense,
              amount: e.amount,
              title: e.title,
              categoryId: e.categoryId,
              accountId: e.accountId,
              currencyCode: e.currencyCode,
              date: e.date,
              notes: e.notes,
              receiptPath: e.receiptPath,
              tag: e.tag,
              location: e.location,
              eventId: e.eventId,
              isRecurring: e.isRecurring,
            ),
          ),
      ..._incomes.where((e) => e.eventId == eventId).map(
            (e) => MoneyTx(
              id: e.id,
              kind: MoneyTxKind.income,
              amount: e.amount,
              title: e.title,
              categoryId: e.sourceId,
              accountId: e.accountId,
              currencyCode: e.currencyCode,
              date: e.date,
              notes: e.notes,
              receiptPath: e.receiptPath,
              tag: e.tag,
              location: e.location,
              eventId: e.eventId,
              isRecurring: e.isRecurring,
            ),
          ),
    ]..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Map<String, double> eventSpendByCategory(String eventId) {
    final map = <String, double>{};
    for (final e in _expenses) {
      if (e.eventId != eventId) continue;
      map[e.categoryId] =
          (map[e.categoryId] ?? 0) + amountInPrimary(e.amount, e.currencyCode);
    }
    return map;
  }

  // ── Investments ───────────────────────────────────────────

  Future<void> addInvestment(Investment inv) async {
    _investments.add(inv);
    notifyListeners();
    await _persist();
  }

  Future<void> updateInvestment(Investment inv) async {
    final i = _investments.indexWhere((e) => e.id == inv.id);
    if (i == -1) return;
    _investments[i] = inv;
    notifyListeners();
    await _persist();
  }

  Future<void> deleteInvestment(String id) async {
    _investments.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persist();
  }

  double get investedTotal =>
      _investments.fold(0.0, (s, e) => s + e.amount);

  double get investmentValue =>
      _investments.fold(0.0, (s, e) => s + e.currentValue);

  double get investmentGain => investmentValue - investedTotal;

  // ── Groups ────────────────────────────────────────────────

  Future<void> addGroup(FinanceGroup group) async {
    _groups.add(group);
    notifyListeners();
    await _persist();
  }

  Future<void> updateGroup(FinanceGroup group) async {
    final i = _groups.indexWhere((e) => e.id == group.id);
    if (i == -1) return;
    _groups[i] = group;
    notifyListeners();
    await _persist();
  }

  Future<void> deleteGroup(String id) async {
    _groups.removeWhere((e) => e.id == id);
    _groupExpenses.removeWhere((e) => e.groupId == id);
    notifyListeners();
    await _persist();
  }

  Future<void> addGroupExpense(GroupExpense expense) async {
    _groupExpenses.add(expense);
    notifyListeners();
    await _persist();
  }

  Future<void> deleteGroupExpense(String id) async {
    _groupExpenses.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persist();
  }

  // ── Accounts ──────────────────────────────────────────────

  Future<void> addAccount(MoneyAccount account) async {
    _accounts.add(account);
    notifyListeners();
    await _persist();
  }

  Future<void> updateAccount(MoneyAccount account) async {
    final i = _accounts.indexWhere((e) => e.id == account.id);
    if (i == -1) return;
    _accounts[i] = account;
    notifyListeners();
    await _persist();
  }

  Future<void> deleteAccount(String id) async {
    if (_accounts.length <= 1) return;
    final fallback = _accounts.firstWhere((a) => a.id != id).id;
    _accounts.removeWhere((a) => a.id == id);
    _expenses = _expenses
        .map((e) => e.accountId == id ? e.copyWith(accountId: fallback) : e)
        .toList();
    _incomes = _incomes
        .map((e) => e.accountId == id ? e.copyWith(accountId: fallback) : e)
        .toList();
    _transfers.removeWhere(
      (t) => t.fromAccountId == id || t.toAccountId == id,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> addTransfer(AccountTransfer transfer) async {
    _transfers.add(transfer);
    notifyListeners();
    await _persist();
  }

  /// Ensure a Cash account exists; returns its id.
  Future<String> ensureCashAccountId() async {
    for (final a in _accounts) {
      if (!a.archived &&
          (a.type == AccountType.cash || a.presetId == 'cash')) {
        return a.id;
      }
    }
    final cash = MoneyAccount(
      id: newId(),
      name: 'Cash',
      type: AccountType.cash,
      presetId: 'cash',
    );
    _accounts.add(cash);
    notifyListeners();
    await _persist();
    return cash.id;
  }

  /// ATM withdrawal: bank/wallet → Cash (transfer, not expense).
  Future<void> recordAtmWithdrawal({
    required double amount,
    required String fromAccountId,
    String note = '',
    DateTime? date,
  }) async {
    if (amount <= 0 || fromAccountId.isEmpty) return;
    final cashId = await ensureCashAccountId();
    if (fromAccountId == cashId) return;

    await addTransfer(
      AccountTransfer(
        id: newId(),
        fromAccountId: fromAccountId,
        toAccountId: cashId,
        amount: amount,
        date: date ?? DateTime.now(),
        notes: note.isEmpty ? 'ATM cash withdrawal' : 'ATM: $note',
      ),
    );
  }

  Future<void> deleteTransfer(String id) async {
    _transfers.removeWhere((t) => t.id == id);
    notifyListeners();
    await _persist();
  }

  /// For assets: money available. For credit cards: amount you **owe** (positive).
  double balanceFor(String accountId) {
    final acc = accountById(accountId);
    if (acc == null) return 0;
    if (acc.isCreditCard) return creditOwed(accountId);

    var bal = acc.openingBalance;
    for (final e in _expenses) {
      if (e.accountId == accountId) {
        bal -= amountInPrimary(e.amount, e.currencyCode);
      }
    }
    for (final i in _incomes) {
      if (i.accountId == accountId) {
        bal += amountInPrimary(i.amount, i.currencyCode);
      }
    }
    for (final t in _transfers) {
      if (t.fromAccountId == accountId) bal -= t.amount;
      if (t.toAccountId == accountId) bal += t.amount;
    }
    return bal;
  }

  /// Credit card outstanding debt (spend increases, payments decrease).
  double creditOwed(String accountId) {
    final acc = accountById(accountId);
    if (acc == null || !acc.isCreditCard) return 0;
    // openingBalance = outstanding when card was added
    var owed = acc.openingBalance;
    for (final e in _expenses) {
      if (e.accountId == accountId) {
        owed += amountInPrimary(e.amount, e.currencyCode);
      }
    }
    for (final i in _incomes) {
      if (i.accountId == accountId) {
        // Refunds to the card reduce debt.
        owed -= amountInPrimary(i.amount, i.currencyCode);
      }
    }
    for (final t in _transfers) {
      // Paying the card: money from cash/bank → card.
      if (t.toAccountId == accountId) owed -= t.amount;
      // Cash advance / transfer out from card increases debt.
      if (t.fromAccountId == accountId) owed += t.amount;
    }
    // Never negative; overpayment is just "paid in full".
    return owed < 0 ? 0.0 : owed;
  }

  double creditAvailable(String accountId) {
    final acc = accountById(accountId);
    if (acc == null || !acc.isCreditCard) return 0;
    final limit = acc.creditLimit;
    if (limit <= 0) {
      // No limit set — still show "space" as 0 so UI can prompt to set limit.
      return 0;
    }
    final avail = limit - creditOwed(accountId);
    return avail < 0 ? 0.0 : avail;
  }

  /// Short label for pickers: "Owe Rs X · Avail Rs Y" or "Limit Rs Y".
  String creditBalanceLabel(String accountId) {
    final acc = accountById(accountId);
    if (acc == null || !acc.isCreditCard) return formatPkr(0);
    final owed = creditOwed(accountId);
    final limit = acc.creditLimit;
    if (limit > 0) {
      final avail = creditAvailable(accountId);
      if (owed > 0) {
        return 'Owe ${formatPkr(owed, compact: true)} · Avail ${formatPkr(avail, compact: true)}';
      }
      return 'Avail ${formatPkr(avail, compact: true)} / ${formatPkr(limit, compact: true)}';
    }
    if (owed > 0) return 'Owe ${formatPkr(owed, compact: true)}';
    return 'Credit card';
  }

  double get totalAssetBalance =>
      assetAccounts.fold(0.0, (s, a) => s + balanceFor(a.id));

  double get totalAccountsBalance => totalAssetBalance;

  Map<String, double> get allAccountBalances => {
        for (final a in _accounts) a.id: balanceFor(a.id),
      };

  // ── Installments ──────────────────────────────────────────

  /// Create installment plan. If linked to a credit card, charges full
  /// purchase amount to that card so "You owe" increases immediately.
  Future<void> addInstallment(
    InstallmentPlan plan, {
    bool chargeToCard = true,
  }) async {
    _installments.add(plan);

    // Full purchase on credit card → pending bill goes up.
    if (chargeToCard &&
        plan.creditAccountId.isNotEmpty &&
        plan.totalAmount > 0) {
      final card = accountById(plan.creditAccountId);
      if (card != null && card.isCreditCard) {
        _expenses.add(
          Expense(
            id: newId(),
            amount: plan.totalAmount,
            title: plan.title,
            categoryId: 'shopping',
            accountId: plan.creditAccountId,
            currencyCode: _currencyCode,
            date: plan.startDate,
            notes: plan.personOrShop.isEmpty
                ? 'Installment purchase · ${plan.months} months'
                : 'Installment · ${plan.personOrShop} · ${plan.months} mo',
            tag: 'installment',
          ),
        );
      }
    }

    notifyListeners();
    await _persist();
  }

  Future<void> updateInstallment(InstallmentPlan plan) async {
    final i = _installments.indexWhere((e) => e.id == plan.id);
    if (i == -1) return;
    _installments[i] = plan;
    notifyListeners();
    await _persist();
  }

  Future<void> deleteInstallment(String id) async {
    _installments.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persist();
  }

  /// Pay one installment from cash/bank.
  /// If linked to a credit card, pays the card bill (reduces debt).
  Future<void> payInstallment({
    required String planId,
    required double amount,
    String fromAccountId = '',
    bool affectCard = true,
    DateTime? date,
  }) async {
    final i = _installments.indexWhere((e) => e.id == planId);
    if (i == -1) return;
    final plan = _installments[i];
    final pay = amount.clamp(0.0, plan.remaining);
    if (pay <= 0) return;

    final when = date ?? DateTime.now();
    final from = fromAccountId.isEmpty ? defaultAccountId : fromAccountId;

    if (from.isNotEmpty) {
      if (affectCard && plan.creditAccountId.isNotEmpty) {
        final card = accountById(plan.creditAccountId);
        if (card != null && card.isCreditCard) {
          // Only pay down card debt — never below zero.
          final owed = creditOwed(plan.creditAccountId);
          final toCard = pay > owed ? owed : pay;
          if (toCard > 0) {
            _transfers.add(
              AccountTransfer(
                id: newId(),
                fromAccountId: from,
                toAccountId: plan.creditAccountId,
                amount: toCard,
                date: when,
                notes: 'Installment pay · ${plan.title}',
              ),
            );
          }
          // If installment pay > current card debt, rest leaves as normal expense.
          final rest = pay - toCard;
          if (rest > 0.01) {
            _expenses.add(
              Expense(
                id: newId(),
                amount: rest,
                title: 'Installment · ${plan.title}',
                categoryId: 'shopping',
                accountId: from,
                currencyCode: _currencyCode,
                date: when,
                notes: 'Installment (beyond card balance)',
                tag: 'installment',
              ),
            );
          }
        }
      } else {
        // Direct expense from account (shop installment without card).
        _expenses.add(
          Expense(
            id: newId(),
            amount: pay,
            title: 'Installment · ${plan.title}',
            categoryId: 'shopping',
            accountId: from,
            currencyCode: _currencyCode,
            date: when,
            notes: plan.personOrShop.isEmpty
                ? 'Installment payment'
                : 'Installment · ${plan.personOrShop}',
            tag: 'installment',
          ),
        );
      }
    }

    _installments[i] = plan.copyWith(paidAmount: plan.paidAmount + pay);
    notifyListeners();
    await _persist();
  }

  /// Purchases charged to a credit card (expenses only).
  double creditPurchases(String accountId) {
    final acc = accountById(accountId);
    if (acc == null || !acc.isCreditCard) return 0;
    var total = acc.openingBalance;
    for (final e in _expenses) {
      if (e.accountId == accountId) {
        total += amountInPrimary(e.amount, e.currencyCode);
      }
    }
    for (final t in _transfers) {
      if (t.fromAccountId == accountId) total += t.amount; // cash advance
    }
    return total;
  }

  /// Payments made toward a credit card.
  double creditPayments(String accountId) {
    final acc = accountById(accountId);
    if (acc == null || !acc.isCreditCard) return 0;
    var total = 0.0;
    for (final i in _incomes) {
      if (i.accountId == accountId) {
        total += amountInPrimary(i.amount, i.currencyCode);
      }
    }
    for (final t in _transfers) {
      if (t.toAccountId == accountId) total += t.amount;
    }
    return total;
  }

  /// Pay credit card bill from an asset account.
  Future<void> payCreditCard({
    required String cardId,
    required String fromAccountId,
    required double amount,
    String note = '',
    DateTime? date,
  }) async {
    final card = accountById(cardId);
    if (card == null || !card.isCreditCard) return;
    final pay = amount.clamp(0.0, double.infinity);
    if (pay <= 0) return;
    _transfers.add(
      AccountTransfer(
        id: newId(),
        fromAccountId: fromAccountId,
        toAccountId: cardId,
        amount: pay,
        date: date ?? DateTime.now(),
        notes: note.isEmpty ? 'Credit card payment' : note,
      ),
    );
    notifyListeners();
    await _persist();
  }

  // ── Savings goals ─────────────────────────────────────────
  // Money: spendable (cash/bank) → real Savings account (UBL Savings etc.).
  // Goals only track progress; they do not invent balances.

  /// Create goal only (no account). Link a savings account on first deposit.
  Future<void> addGoal(SavingsGoal goal) async {
    _goals.add(
      goal.copyWith(
        savingsAccountId: goal.savingsAccountId,
        savedAmount: goal.savedAmount,
      ),
    );
    notifyListeners();
    await _persist();
  }

  Future<void> updateGoal(SavingsGoal goal) async {
    final i = _goals.indexWhere((g) => g.id == goal.id);
    if (i == -1) return;
    // Preserve linked savings account unless explicitly set.
    final prev = _goals[i];
    final link = goal.savingsAccountId.isNotEmpty
        ? goal.savingsAccountId
        : prev.savingsAccountId;
    _goals[i] = goal.copyWith(savingsAccountId: link);
    notifyListeners();
    await _persist();
  }

  /// Link an existing savings account to this goal.
  Future<void> linkGoalSavingsAccount({
    required String goalId,
    required String savingsAccountId,
  }) async {
    final i = _goals.indexWhere((g) => g.id == goalId);
    if (i == -1) return;
    final acc = accountById(savingsAccountId);
    if (acc == null) return;
    // Prefer savings type; allow any non-credit for flexibility.
    if (acc.isCreditCard) return;
    _goals[i] = _goals[i].copyWith(
      savingsAccountId: savingsAccountId,
      savedAmount: balanceFor(savingsAccountId),
    );
    notifyListeners();
    await _persist();
  }

  /// Create a real savings account and link it to the goal.
  Future<MoneyAccount> createSavingsAccountForGoal({
    required String goalId,
    required String name,
    String presetId = 'goal_savings',
    double openingBalance = 0,
  }) async {
    final i = _goals.indexWhere((g) => g.id == goalId);
    if (i == -1) {
      throw StateError('Goal not found');
    }
    final acc = MoneyAccount(
      id: newId(),
      name: name.trim().isEmpty ? '${_goals[i].name} savings' : name.trim(),
      type: AccountType.savings,
      presetId: presetId.isEmpty ? 'goal_savings' : presetId,
      openingBalance: openingBalance,
      notes: 'Savings for goal: ${_goals[i].name}',
    );
    _accounts.add(acc);
    _goals[i] = _goals[i].copyWith(
      savingsAccountId: acc.id,
      savedAmount: openingBalance,
    );
    notifyListeners();
    await _persist();
    return acc;
  }

  /// Delete goal only (keeps the savings account and its money).
  Future<void> deleteGoal(
    String id, {
    String returnToAccountId = '',
    bool returnMoney = false,
  }) async {
    final g = goalById(id);
    if (g == null) return;
    // Optionally move savings back to cash/bank when deleting goal.
    if (returnMoney && g.savingsAccountId.isNotEmpty) {
      final bal = balanceFor(g.savingsAccountId);
      final to =
          returnToAccountId.isEmpty ? defaultAccountId : returnToAccountId;
      if (bal > 0 && to.isNotEmpty && to != g.savingsAccountId) {
        _transfers.add(
          AccountTransfer(
            id: newId(),
            fromAccountId: g.savingsAccountId,
            toAccountId: to,
            amount: bal,
            date: DateTime.now(),
            notes: 'Closed goal · ${g.name} — money returned',
          ),
        );
      }
    }
    _goals.removeWhere((x) => x.id == id);
    _goalContributions.removeWhere((c) => c.goalId == id);
    notifyListeners();
    await _persist();
  }

  /// Cut money from cash/bank and put into the linked savings account.
  Future<void> contributeToGoal({
    required String goalId,
    required double amount,
    String accountId = '',
    String note = '',
    DateTime? date,
    bool deductFromAccount = true,
  }) async {
    final i = _goals.indexWhere((g) => g.id == goalId);
    if (i == -1) return;
    final pay = amount;
    if (pay <= 0) return;

    final goal = _goals[i];
    final savingsId = goal.savingsAccountId;
    if (savingsId.isEmpty || accountById(savingsId) == null) {
      throw StateError('Link or create a savings account first');
    }

    final from = accountId.isEmpty ? defaultAccountId : accountId;
    final when = date ?? DateTime.now();
    if (from.isEmpty || from == savingsId) return;

    // Like spending: leaves main account → enters savings (transfer).
    _transfers.add(
      AccountTransfer(
        id: newId(),
        fromAccountId: from,
        toAccountId: savingsId,
        amount: pay,
        date: when,
        notes: note.isEmpty
            ? 'Goal deposit · ${goal.name}'
            : 'Goal deposit · ${goal.name}: $note',
      ),
    );

    _goalContributions.add(
      GoalContribution(
        id: newId(),
        goalId: goalId,
        amount: pay,
        date: when,
        note: note,
        accountId: from,
        isDeposit: true,
      ),
    );

    _goals[i] = goal.copyWith(savedAmount: balanceFor(savingsId));
    notifyListeners();
    await _persist();
  }

  /// Move money from savings account back to cash/bank.
  Future<void> withdrawFromGoal({
    required String goalId,
    required double amount,
    String toAccountId = '',
    String note = '',
    DateTime? date,
  }) async {
    final i = _goals.indexWhere((g) => g.id == goalId);
    if (i == -1) return;
    final goal = _goals[i];
    final savingsId = goal.savingsAccountId;
    if (savingsId.isEmpty) return;
    final to = toAccountId.isEmpty ? defaultAccountId : toAccountId;
    final potBal = balanceFor(savingsId);
    final pay = amount.clamp(0.0, potBal);
    if (pay <= 0 || to.isEmpty || to == savingsId) return;
    final when = date ?? DateTime.now();

    _transfers.add(
      AccountTransfer(
        id: newId(),
        fromAccountId: savingsId,
        toAccountId: to,
        amount: pay,
        date: when,
        notes: note.isEmpty
            ? 'Goal withdraw · ${goal.name}'
            : 'Goal withdraw · ${goal.name}: $note',
      ),
    );

    _goalContributions.add(
      GoalContribution(
        id: newId(),
        goalId: goalId,
        amount: pay,
        date: when,
        note: note,
        accountId: to,
        isDeposit: false,
      ),
    );

    _goals[i] = goal.copyWith(savedAmount: balanceFor(savingsId));
    notifyListeners();
    await _persist();
  }

  // ── Budgets ───────────────────────────────────────────────

  Future<void> saveBudget(MonthlyBudget budget) async {
    final key = DateTime(budget.month.year, budget.month.month);
    final i = _budgets.indexWhere((b) {
      final m = DateTime(b.month.year, b.month.month);
      return m == key;
    });
    if (i >= 0) {
      _budgets[i] = budget.copyWith(month: key);
    } else {
      _budgets.add(budget.copyWith(month: key));
    }
    notifyListeners();
    await _persist();
  }

  Future<void> deleteBudget(String id) async {
    _budgets.removeWhere((b) => b.id == id);
    notifyListeners();
    await _persist();
  }

  bool _countsTowardBudget(Expense e) {
    if (e.categoryId == 'atm') return false;
    if (e.tag.toLowerCase() == 'goal') return false;
    return true;
  }

  /// Spend in primary currency for [categoryId] in [month] (whole month).
  double categorySpendInMonth(String categoryId, DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    var total = 0.0;
    for (final e in _expenses) {
      if (e.categoryId != categoryId) continue;
      if (!_countsTowardBudget(e)) continue;
      if (!_inRange(e.date, start, end)) continue;
      total += amountInPrimary(e.amount, e.currencyCode);
    }
    return total;
  }

  double totalSpendInMonth(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    var total = 0.0;
    for (final e in _expenses) {
      if (!_countsTowardBudget(e)) continue;
      if (!_inRange(e.date, start, end)) continue;
      total += amountInPrimary(e.amount, e.currencyCode);
    }
    return total;
  }

  /// Budget remaining for overall (null if no overall limit).
  double? overallBudgetRemaining(DateTime month) {
    final b = budgetForMonth(month);
    if (b == null || b.overallLimit <= 0) return null;
    return b.overallLimit - totalSpendInMonth(month);
  }

  double? categoryBudgetRemaining(String categoryId, DateTime month) {
    final b = budgetForMonth(month);
    final limit = b?.categoryLimits[categoryId];
    if (limit == null || limit <= 0) return null;
    return limit - categorySpendInMonth(categoryId, month);
  }

  /// Resolve account id from SMS text using presets the user owns.
  String accountIdFromSms(String text) {
    final presetId = matchPresetFromSms(text);
    if (presetId != null) {
      for (final a in activeAccounts) {
        if (a.presetId == presetId) return a.id;
      }
    }
    return defaultAccountId;
  }

  // ── Summaries ─────────────────────────────────────────────

  bool _inRange(DateTime d, DateTime start, DateTime end) {
    return !d.isBefore(start) && d.isBefore(end);
  }

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime get _weekStart {
    final t = _today;
    return t.subtract(Duration(days: t.weekday - 1));
  }

  DateTime get _monthStart {
    final n = DateTime.now();
    return DateTime(n.year, n.month, 1);
  }

  double totalExpensesIn(DateTime start, DateTime end) => _expenses
      .where((e) => _inRange(e.date, start, end))
      .fold(
        0.0,
        (s, e) => s + amountInPrimary(e.amount, e.currencyCode),
      );

  double totalIncomeIn(DateTime start, DateTime end) => _incomes
      .where((e) => _inRange(e.date, start, end))
      .fold(
        0.0,
        (s, e) => s + amountInPrimary(e.amount, e.currencyCode),
      );

  List<Expense> filterExpenses(TransactionFilter f) {
    return expenses.where((e) {
      if (f.query.trim().isNotEmpty) {
        final q = f.query.trim().toLowerCase();
        final hay =
            '${e.title} ${e.notes} ${e.categoryId} ${e.accountId} ${e.tag} ${e.eventId} ${e.location}'
                .toLowerCase();
        if (!hay.contains(q)) return false;
      }
      if (f.categoryId != null && e.categoryId != f.categoryId) return false;
      if (f.accountId != null && e.accountId != f.accountId) return false;
      if (f.eventId != null) {
        if (f.eventId!.isEmpty) {
          if (e.eventId.isNotEmpty) return false;
        } else if (e.eventId != f.eventId) {
          return false;
        }
      }
      if (f.tag != null) {
        if (f.tag!.isEmpty) {
          if (e.tag.trim().isNotEmpty) return false;
        } else if (e.tag.trim().toLowerCase() != f.tag!.trim().toLowerCase()) {
          return false;
        }
      }
      if (f.currencyCode != null &&
          (e.currencyCode.isEmpty ? _currencyCode : e.currencyCode) !=
              f.currencyCode) {
        return false;
      }
      if (f.hasReceipt != null && e.hasReceipt != f.hasReceipt) return false;
      if (f.from != null && e.date.isBefore(f.from!)) return false;
      if (f.to != null) {
        final end = DateTime(f.to!.year, f.to!.month, f.to!.day, 23, 59, 59);
        if (e.date.isAfter(end)) return false;
      }
      if (f.minAmount != null && e.amount < f.minAmount!) return false;
      if (f.maxAmount != null && e.amount > f.maxAmount!) return false;
      return true;
    }).toList();
  }

  List<Income> filterIncomes(TransactionFilter f) {
    return incomes.where((e) {
      if (f.query.trim().isNotEmpty) {
        final q = f.query.trim().toLowerCase();
        final hay =
            '${e.title} ${e.from} ${e.notes} ${e.sourceId} ${e.tag} ${e.eventId} ${e.location}'
                .toLowerCase();
        if (!hay.contains(q)) return false;
      }
      if (f.categoryId != null && e.sourceId != f.categoryId) return false;
      if (f.accountId != null && e.accountId != f.accountId) return false;
      if (f.eventId != null) {
        if (f.eventId!.isEmpty) {
          if (e.eventId.isNotEmpty) return false;
        } else if (e.eventId != f.eventId) {
          return false;
        }
      }
      if (f.tag != null) {
        if (f.tag!.isEmpty) {
          if (e.tag.trim().isNotEmpty) return false;
        } else if (e.tag.trim().toLowerCase() != f.tag!.trim().toLowerCase()) {
          return false;
        }
      }
      if (f.currencyCode != null &&
          (e.currencyCode.isEmpty ? _currencyCode : e.currencyCode) !=
              f.currencyCode) {
        return false;
      }
      if (f.hasReceipt != null && e.hasReceipt != f.hasReceipt) return false;
      if (f.from != null && e.date.isBefore(f.from!)) return false;
      if (f.to != null) {
        final end = DateTime(f.to!.year, f.to!.month, f.to!.day, 23, 59, 59);
        if (e.date.isAfter(end)) return false;
      }
      if (f.minAmount != null && e.amount < f.minAmount!) return false;
      if (f.maxAmount != null && e.amount > f.maxAmount!) return false;
      return true;
    }).toList();
  }

  /// Spend by category from an already-filtered expense list.
  Map<String, double> spendByCategoryFrom(List<Expense> list) {
    final map = <String, double>{};
    for (final exp in list) {
      map[exp.categoryId] = (map[exp.categoryId] ?? 0) +
          amountInPrimary(exp.amount, exp.currencyCode);
    }
    return map;
  }

  /// Income by source from an already-filtered income list.
  Map<String, double> incomeBySourceFrom(List<Income> list) {
    final map = <String, double>{};
    for (final inc in list) {
      map[inc.sourceId] = (map[inc.sourceId] ?? 0) +
          amountInPrimary(inc.amount, inc.currencyCode);
    }
    return map;
  }

  double sumExpenses(List<Expense> list) => list.fold(
        0.0,
        (s, e) => s + amountInPrimary(e.amount, e.currencyCode),
      );

  double sumIncomes(List<Income> list) => list.fold(
        0.0,
        (s, e) => s + amountInPrimary(e.amount, e.currencyCode),
      );

  /// Monthly spend for last [months] months, respecting non-date filter fields.
  List<({String label, double amount})> monthlySpendTrendFiltered(
    TransactionFilter base, {
    int months = 6,
  }) {
    final now = DateTime.now();
    final result = <({String label, double amount})>[];
    for (var i = months - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final next = DateTime(month.year, month.month + 1, 1);
      final lastDay = next.subtract(const Duration(days: 1));
      final forced = TransactionFilter(
        query: base.query,
        categoryId: base.categoryId,
        accountId: base.accountId,
        currencyCode: base.currencyCode,
        eventId: base.eventId,
        tag: base.tag,
        from: month,
        to: lastDay,
        hasReceipt: base.hasReceipt,
        minAmount: base.minAmount,
        maxAmount: base.maxAmount,
      );
      final total = sumExpenses(filterExpenses(forced));
      final label = '${month.month}/${month.year % 100}';
      result.add((label: label, amount: total));
    }
    return result;
  }

  double get weekExpense =>
      totalExpensesIn(_weekStart, _today.add(const Duration(days: 1)));

  double get monthExpense =>
      totalExpensesIn(_monthStart, _today.add(const Duration(days: 1)));

  double get weekIncome =>
      totalIncomeIn(_weekStart, _today.add(const Duration(days: 1)));

  double get monthIncome =>
      totalIncomeIn(_monthStart, _today.add(const Duration(days: 1)));

  double get monthBalance => monthIncome - monthExpense;

  double get totalLentPending => _loans
      .where((l) => l.direction == LoanDirection.lent && !l.isSettled)
      .fold(0.0, (s, l) => s + l.remaining);

  double get totalBorrowedPending => _loans
      .where((l) => l.direction == LoanDirection.borrowed && !l.isSettled)
      .fold(0.0, (s, l) => s + l.remaining);

  Map<String, double> spendByCategory({DateTime? start, DateTime? end}) {
    final s = start ?? _monthStart;
    final e = end ?? _today.add(const Duration(days: 1));
    final map = <String, double>{};
    for (final exp in _expenses) {
      if (!_inRange(exp.date, s, e)) continue;
      map[exp.categoryId] = (map[exp.categoryId] ?? 0) +
          amountInPrimary(exp.amount, exp.currencyCode);
    }
    return map;
  }

  Map<String, double> incomeBySource({DateTime? start, DateTime? end}) {
    final s = start ?? _monthStart;
    final e = end ?? _today.add(const Duration(days: 1));
    final map = <String, double>{};
    for (final inc in _incomes) {
      if (!_inRange(inc.date, s, e)) continue;
      map[inc.sourceId] = (map[inc.sourceId] ?? 0) +
          amountInPrimary(inc.amount, inc.currencyCode);
    }
    return map;
  }

  /// Last 6 months expense totals for bar chart.
  List<({String label, double amount})> monthlySpendTrend() {
    final now = DateTime.now();
    final result = <({String label, double amount})>[];
    for (var i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final next = DateTime(month.year, month.month + 1, 1);
      final total = totalExpensesIn(month, next);
      final label = '${month.month}/${month.year % 100}';
      result.add((label: label, amount: total));
    }
    return result;
  }

  static String newId() => _uuid.v4();
}
