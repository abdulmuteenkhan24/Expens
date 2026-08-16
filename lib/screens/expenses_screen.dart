import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/categories.dart';
import '../models/expense.dart';
import '../models/transaction_filter.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/transaction_search_bar.dart';
import '../widgets/transaction_tile.dart';
import 'expense_form_screen.dart';
import 'sms_import_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  TransactionFilter _filter = TransactionFilter.empty;

  void _openForm({Object? expense}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseFormScreen(
          expense: expense is Expense ? expense : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final expenses = state.filterExpenses(_filter);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            tooltip: 'Import from SMS',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SmsImportScreen()),
            ),
            icon: const Icon(Icons.sms_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: _TotalBox(
                    label: 'This week',
                    amount: state.weekExpense,
                    color: AppColors.expense,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TotalBox(
                    label: 'This month',
                    amount: state.monthExpense,
                    color: const Color(0xFFFF8A65),
                  ),
                ),
              ],
            ),
          ),
          TransactionSearchBar(
            filter: _filter,
            accounts: state.activeAccounts,
            onChanged: (f) => setState(() => _filter = f),
          ),
          if (_filter.isActive)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${expenses.length} result${expenses.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                    ),
              ),
            ),
          Expanded(
            child: state.expenses.isEmpty
                ? EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'No expenses yet',
                    subtitle:
                        'Tap + to add one. Attach receipts and pick currency.',
                    actionLabel: 'Add expense',
                    onAction: () => _openForm(),
                  )
                : expenses.isEmpty
                    ? EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No matches',
                        subtitle: 'Try a different search or clear filters.',
                        actionLabel: 'Clear filters',
                        onAction: () => setState(
                          () => _filter = TransactionFilter.empty,
                        ),
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
                            onEdit: () => _openForm(expense: e),
                            onDelete: () => state.deleteExpense(e.id),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_expenses',
        onPressed: () => _openForm(),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _TotalBox extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _TotalBox({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withValues(alpha: 0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            formatPkr(amount, compact: amount >= 100000),
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
