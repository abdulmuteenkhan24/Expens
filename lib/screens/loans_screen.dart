import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/loan.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import 'loan_detail_screen.dart';
import 'loan_form_screen.dart';

class LoansScreen extends StatelessWidget {
  const LoansScreen({super.key});

  void _openForm(BuildContext context, {Loan? loan}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LoanFormScreen(loan: loan)),
    );
  }

  void _openDetail(BuildContext context, Loan loan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoanDetailScreen(loanId: loan.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final loans = state.loans;
    final active = loans.where((l) => !l.isSettled).toList();
    final settled = loans.where((l) => l.isSettled).toList();

    // Lift FAB above the floating shell nav (≈78 + safe inset).
    final fabLift = 88.0 + MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans'),
        actions: [
          IconButton(
            tooltip: 'Add loan',
            onPressed: () => _openForm(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Borrow = money into your account (must repay). '
              'Lend = money out (they repay you). Track every installment.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                  ),
            ),
          ),
          if (loans.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _Box(
                      label: 'To receive',
                      amount: state.totalLentPending,
                      color: AppColors.loanLent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Box(
                      label: 'To repay',
                      amount: state.totalBorrowedPending,
                      color: AppColors.loanBorrowed,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: loans.isEmpty
                ? EmptyState(
                    icon: Icons.handshake_rounded,
                    title: 'No loans yet',
                    subtitle:
                        'Borrow 50k → money appears in your account. '
                        'Repay over time with full history.',
                    actionLabel: 'Add loan',
                    onAction: () => _openForm(context),
                  )
                : ListView(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, fabLift + 24),
                    children: [
                      if (active.isNotEmpty) ...[
                        Text(
                          'Active',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.55),
                                  ),
                        ),
                        const SizedBox(height: 8),
                        ...active.map(
                          (loan) => _LoanCard(
                            loan: loan,
                            paymentCount:
                                state.paymentsForLoan(loan.id).length,
                            onTap: () => _openDetail(context, loan),
                          ),
                        ),
                      ],
                      if (settled.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Settled',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.55),
                                  ),
                        ),
                        const SizedBox(height: 8),
                        ...settled.map(
                          (loan) => _LoanCard(
                            loan: loan,
                            paymentCount:
                                state.paymentsForLoan(loan.id).length,
                            onTap: () => _openDetail(context, loan),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        // Sit above the floating bottom nav so it stays tappable.
        padding: EdgeInsets.only(bottom: fabLift - 16, right: 4),
        child: FloatingActionButton.extended(
          heroTag: 'fab_loans',
          onPressed: () => _openForm(context),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add loan'),
        ),
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final Loan loan;
  final int paymentCount;
  final VoidCallback onTap;

  const _LoanCard({
    required this.loan,
    required this.paymentCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLent = loan.direction == LoanDirection.lent;
    final color = isLent ? AppColors.loanLent : AppColors.loanBorrowed;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(
                      isLent
                          ? Icons.north_east_rounded
                          : Icons.south_west_rounded,
                      color: color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loan.personName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          [
                            isLent ? 'Lent' : 'Borrowed',
                            if (loan.purpose.isNotEmpty) loan.purpose,
                            formatDate(loan.date),
                            if (paymentCount > 0) '$paymentCount payments',
                          ].join(' · '),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatPkr(loan.remaining),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color:
                              loan.isSettled ? AppColors.income : color,
                        ),
                      ),
                      Text(
                        loan.isSettled
                            ? 'Settled'
                            : 'of ${formatPkr(loan.amount, compact: true)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.45),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              if (!loan.isSettled) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: loan.progress,
                    minHeight: 6,
                    backgroundColor: color.withValues(alpha: 0.12),
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      loan.isOverdue ? 'Overdue' : 'Tap for history & repay',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: loan.isOverdue
                                ? AppColors.expense
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.45),
                            fontWeight: loan.isOverdue
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      '${(loan.progress * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _Box({
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
