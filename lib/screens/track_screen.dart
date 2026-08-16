import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/categories.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/transaction_filter.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/transaction_search_bar.dart';
import '../widgets/transaction_tile.dart';
import 'expense_form_screen.dart';
import 'income_form_screen.dart';
import 'sms_import_screen.dart';

/// Unified expense + income tracker (bird’s-eye activity list).
class TrackScreen extends StatefulWidget {
  const TrackScreen({super.key});

  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  TransactionFilter _expenseFilter = TransactionFilter.empty;
  TransactionFilter _incomeFilter = TransactionFilter.empty;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _add() {
    if (_tabs.index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ExpenseFormScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const IncomeFormScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final expenses = state.filterExpenses(_expenseFilter);
    final incomes = state.filterIncomes(_incomeFilter);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track'),
        actions: [
          if (_tabs.index == 0)
            IconButton(
              tooltip: 'Import from SMS',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SmsImportScreen()),
              ),
              icon: const Icon(Icons.sms_outlined),
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Income'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryChip(
                    label: 'Spent this month',
                    value: formatPkr(state.monthExpense, compact: true),
                    color: AppColors.expense,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryChip(
                    label: 'Earned this month',
                    value: formatPkr(state.monthIncome, compact: true),
                    color: AppColors.income,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _ExpenseList(
                  filter: _expenseFilter,
                  expenses: expenses,
                  totalAll: state.expenses.length,
                  onFilter: (f) => setState(() => _expenseFilter = f),
                  onAdd: _add,
                ),
                _IncomeList(
                  filter: _incomeFilter,
                  incomes: incomes,
                  totalAll: state.incomes.length,
                  onFilter: (f) => setState(() => _incomeFilter = f),
                  onAdd: _add,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_track',
        onPressed: _add,
        icon: const Icon(Icons.add_rounded),
        label: Text(_tabs.index == 0 ? 'Expense' : 'Income'),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withValues(alpha: 0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseList extends StatelessWidget {
  final TransactionFilter filter;
  final List<Expense> expenses;
  final int totalAll;
  final ValueChanged<TransactionFilter> onFilter;
  final VoidCallback onAdd;

  const _ExpenseList({
    required this.filter,
    required this.expenses,
    required this.totalAll,
    required this.onFilter,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(
      children: [
        TransactionSearchBar(
          filter: filter,
          accounts: state.activeAccounts,
          onChanged: onFilter,
        ),
        Expanded(
          child: totalAll == 0
              ? EmptyState(
                  icon: Icons.receipt_long_rounded,
                  title: 'No expenses yet',
                  subtitle:
                      'Record spending, categorize it, and see where money goes.',
                  actionLabel: 'Add expense',
                  onAction: onAdd,
                )
              : expenses.isEmpty
                  ? EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No matches',
                      subtitle: 'Try a different search or clear filters.',
                      actionLabel: 'Clear filters',
                      onAction: () => onFilter(TransactionFilter.empty),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: expenses.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 2),
                      itemBuilder: (context, i) {
                        final e = expenses[i];
                        final cat = expenseCategoryById(e.categoryId);
                        final acc = state.accountById(e.accountId)?.name;
                        final cur = e.currencyCode.isEmpty
                            ? state.currencyCode
                            : e.currencyCode;
                        final parts = <String>[
                          cat.name,
                          if (acc != null && acc.isNotEmpty) acc,
                          if (cur != state.currencyCode) cur,
                        ];
                        return TransactionTile(
                          key: ValueKey(e.id),
                          title: e.title,
                          subtitle: parts.join(' · '),
                          amount: e.amount,
                          currencyCode: cur,
                          isIncome: false,
                          date: e.date,
                          category: cat,
                          hasReceipt: e.hasReceipt,
                          onEdit: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExpenseFormScreen(expense: e),
                            ),
                          ),
                          onDelete: () => state.deleteExpense(e.id),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _IncomeList extends StatelessWidget {
  final TransactionFilter filter;
  final List<Income> incomes;
  final int totalAll;
  final ValueChanged<TransactionFilter> onFilter;
  final VoidCallback onAdd;

  const _IncomeList({
    required this.filter,
    required this.incomes,
    required this.totalAll,
    required this.onFilter,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(
      children: [
        TransactionSearchBar(
          filter: filter,
          accounts: state.activeAccounts,
          isExpense: false,
          onChanged: onFilter,
        ),
        Expanded(
          child: totalAll == 0
              ? EmptyState(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'No income yet',
                  subtitle:
                      'Log salary, freelance, or other income by source.',
                  actionLabel: 'Add income',
                  onAction: onAdd,
                )
              : incomes.isEmpty
                  ? EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No matches',
                      subtitle: 'Try a different search or clear filters.',
                      actionLabel: 'Clear filters',
                      onAction: () => onFilter(TransactionFilter.empty),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: incomes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 2),
                      itemBuilder: (context, i) {
                        final e = incomes[i];
                        final src = incomeSourceById(e.sourceId);
                        final acc = state.accountById(e.accountId)?.name;
                        final cur = e.currencyCode.isEmpty
                            ? state.currencyCode
                            : e.currencyCode;
                        final parts = <String>[
                          src.name,
                          if (acc != null && acc.isNotEmpty) acc,
                          if (cur != state.currencyCode) cur,
                        ];
                        return TransactionTile(
                          key: ValueKey(e.id),
                          title: e.title,
                          subtitle: parts.join(' · '),
                          amount: e.amount,
                          currencyCode: cur,
                          isIncome: true,
                          date: e.date,
                          category: src,
                          hasReceipt: e.hasReceipt,
                          onEdit: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => IncomeFormScreen(income: e),
                            ),
                          ),
                          onDelete: () => state.deleteIncome(e.id),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
