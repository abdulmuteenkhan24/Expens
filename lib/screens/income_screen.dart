import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/categories.dart';
import '../models/income.dart';
import '../models/transaction_filter.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/transaction_search_bar.dart';
import '../widgets/transaction_tile.dart';
import 'income_form_screen.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  TransactionFilter _filter = TransactionFilter.empty;

  void _openForm({Object? income}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncomeFormScreen(
          income: income is Income ? income : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final incomes = state.filterIncomes(_filter);

    return Scaffold(
      appBar: AppBar(title: const Text('Income')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: AppColors.income.withValues(alpha: 0.1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This month (${state.currencyCode})',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatPkr(state.monthIncome),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.income,
                        ),
                  ),
                ],
              ),
            ),
          ),
          TransactionSearchBar(
            filter: _filter,
            accounts: state.activeAccounts,
            isExpense: false,
            onChanged: (f) => setState(() => _filter = f),
          ),
          Expanded(
            child: state.incomes.isEmpty
                ? EmptyState(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'No income yet',
                    subtitle: 'Add salary, freelance, or other income.',
                    actionLabel: 'Add income',
                    onAction: () => _openForm(),
                  )
                : incomes.isEmpty
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
                            onEdit: () => _openForm(income: e),
                            onDelete: () => state.deleteIncome(e.id),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_income',
        onPressed: () => _openForm(),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
