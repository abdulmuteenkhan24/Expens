import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/account_presets.dart';
import '../data/categories.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/bank_logo.dart';
import 'accounts_screen.dart';
import 'credit_card_sheets.dart';
import 'transaction_detail_screen.dart';

class AccountDetailScreen extends StatelessWidget {
  final String accountId;

  const AccountDetailScreen({super.key, required this.accountId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final account = state.accountById(accountId);
    if (account == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Account not found')),
      );
    }

    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    final bal = state.balanceFor(accountId);
    final isCard = account.isCreditCard;
    final owed = isCard ? state.creditOwed(accountId) : 0.0;
    final available = isCard ? state.creditAvailable(accountId) : bal;
    final inflow = state.inflowForAccount(accountId, month);
    final outflow = state.outflowForAccount(accountId, month);
    final txs = state.transactionsForAccount(accountId, month: month);
    final plans = state.installmentsForCard(accountId);
    final preset =
        presetById(account.presetId.isEmpty ? 'cash' : account.presetId);

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AccountFormScreen(account: account),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isCard
          ? FloatingActionButton.extended(
              heroTag: 'fab_pay_card',
              onPressed: () => showPayCreditCardSheet(
                context,
                cardId: accountId,
              ),
              icon: const Icon(Icons.payments_rounded),
              label: const Text('Pay bill'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: isCard
                    ? const [Color(0xFF3949AB), Color(0xFF5C6BC0)]
                    : [
                        preset.color.withValues(alpha: 0.9),
                        preset.color.withValues(alpha: 0.65),
                      ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    BankLogo.fromAccount(account, size: 40, radius: 10),
                    const SizedBox(width: 10),
                    Text(
                      typeLabel(account.type),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  isCard ? 'Pending bill (you owe)' : 'Available balance',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                Text(
                  formatPkr(isCard ? owed : bal),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (isCard) ...[
                  const SizedBox(height: 8),
                  Text(
                    account.creditLimit > 0
                        ? 'Limit ${formatPkr(account.creditLimit)} · '
                            'Available ${formatPkr(available)}'
                        : 'Set a credit limit in Edit for available credit',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isCard) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: 'Purchases',
                    value: formatPkr(
                      state.creditPurchases(accountId),
                      compact: true,
                    ),
                    color: AppColors.expense,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Stat(
                    label: 'Payments',
                    value: formatPkr(
                      state.creditPayments(accountId),
                      compact: true,
                    ),
                    color: AppColors.income,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: owed <= 0
                        ? null
                        : () => showPayCreditCardSheet(
                              context,
                              cardId: accountId,
                            ),
                    icon: const Icon(Icons.payments_rounded),
                    label: Text(owed <= 0 ? 'No bill due' : 'Pay bill'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => showAddInstallmentSheet(
                      context,
                      creditAccountId: accountId,
                    ),
                    icon: const Icon(Icons.calendar_view_month_rounded),
                    label: const Text('Installment'),
                  ),
                ),
              ],
            ),
            if (plans.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Installment plans',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              ...plans.map((p) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: p.isSettled
                        ? null
                        : () => showPayInstallmentSheet(context, p),
                    title: Text(
                      p.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      p.isSettled
                          ? 'Settled'
                          : '${formatPkr(p.monthlyAmount, compact: true)}/mo · '
                              '${p.paidMonths}/${p.months} paid · '
                              'left ${formatPkr(p.remaining, compact: true)}',
                    ),
                    trailing: p.isSettled
                        ? const Icon(Icons.check_circle, color: AppColors.income)
                        : const Icon(Icons.chevron_right_rounded),
                  ),
                );
              }),
            ],
          ] else ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: 'Inflow',
                    value: formatPkr(inflow, compact: true),
                    color: AppColors.income,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Stat(
                    label: 'Outflow',
                    value: formatPkr(outflow, compact: true),
                    color: AppColors.expense,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                title: const Text('Opening balance'),
                trailing: Text(
                  formatPkr(account.openingBalance),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            isCard ? 'Card activity this month' : 'This month',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          if (txs.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No transactions this month',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
              ),
            )
          else
            ...txs.map((t) {
              final related =
                  state.accountById(t.relatedAccountId)?.name ?? '';
              late final Color accent;
              late final IconData icon;
              late final String subtitle;
              if (t.isTransfer) {
                accent = AppColors.primary;
                icon = Icons.swap_horiz_rounded;
                subtitle = [
                  t.transferIsIn
                      ? (related.isEmpty ? 'Transfer in' : 'From $related')
                      : (related.isEmpty ? 'Transfer out' : 'To $related'),
                  formatDate(t.date),
                ].join(' · ');
              } else {
                final cat = t.isExpense
                    ? expenseCategoryById(t.categoryId)
                    : incomeSourceById(t.categoryId);
                accent = cat.color;
                icon = cat.icon;
                subtitle = formatDate(t.date);
              }
              final outflow = t.isOutflow;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: t.isTransfer
                      ? (t.relatedAccountId.isEmpty
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AccountDetailScreen(
                                    accountId: t.relatedAccountId,
                                  ),
                                ),
                              ))
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TransactionDetailScreen(
                                id: t.id,
                                isExpense: t.isExpense,
                              ),
                            ),
                          ),
                  leading: CircleAvatar(
                    backgroundColor: accent.withValues(alpha: 0.15),
                    child: Icon(icon, color: accent, size: 18),
                  ),
                  title: Text(
                    t.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(subtitle),
                  trailing: Text(
                    '${outflow ? '-' : '+'}${formatPkr(t.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: outflow ? AppColors.expense : AppColors.income,
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Stat({
    required this.label,
    required this.value,
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
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
