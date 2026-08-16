import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/categories.dart';
import '../models/money_tx.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_logo.dart';
import '../widgets/bank_logo.dart';
import '../widgets/category_chart.dart';
import 'account_detail_screen.dart';
import 'accounts_screen.dart';
import 'add_transaction_flow.dart';
import 'atm_sheet.dart';
import 'budget_screen.dart';
import 'events_screen.dart';
import 'goals_screen.dart';
import 'groups_screen.dart';
import 'investments_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'sms_import_screen.dart';
import 'transaction_detail_screen.dart';
import 'transfer_sheet.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  void _openMoreTools(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => const _MoreToolsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Main accounts only — goal pots stay under Goals, not here.
    final accounts = state.mainAccountsByBalance;
    final recent = state.allTransactions.take(6).toList();
    final showAccounts = accounts.take(4).toList();
    final extraAccounts = accounts.length - showAccounts.length;
    final creditDebt = state.totalCreditDebt;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            // ── Header ──────────────────────────────────────
            Row(
              children: [
                const AppLogo(size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expens',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                      ),
                      Text(
                        'Your money at a glance',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Settings',
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                  ),
                  icon: const Icon(Icons.settings_outlined, size: 22),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── What You Have + Accounts (compact card) ─────
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF00C853), Color(0xFF00BFA5)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C853).withValues(alpha: 0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'What You Have',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatPkr(state.whatYouHave),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                    height: 1.15,
                                  ),
                            ),
                            Text(
                              'Cash · bank · wallets (spendable)',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          state.currencyCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'In ${formatPkr(state.monthIncome, compact: true)}'
                    '  ·  Out ${formatPkr(state.monthExpense, compact: true)}'
                    '  ·  Net ${formatPkr(state.monthBalance, compact: true)}'
                    '${state.totalGoalsSaved > 0 ? '  ·  In goals ${formatPkr(state.totalGoalsSaved, compact: true)}' : ''}'
                    '${creditDebt > 0 ? '  ·  Cards ${formatPkr(creditDebt, compact: true)} owed' : ''}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (accounts.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'Accounts',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AccountsScreen(),
                            ),
                          ),
                          child: Text(
                            'See all (${accounts.length})',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...List.generate(showAccounts.length, (i) {
                      final a = showAccounts[i];
                      final bal = state.balanceFor(a.id);
                      return InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AccountDetailScreen(accountId: a.id),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              BankLogo.fromAccount(a, size: 26, radius: 7),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  a.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                a.isCreditCard
                                    ? (bal > 0
                                        ? 'owe ${formatPkr(bal, compact: true)}'
                                        : 'avail ${formatPkr(state.creditAvailable(a.id), compact: true)}')
                                    : formatPkr(bal, compact: true),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (extraAccounts > 0)
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AccountsScreen(),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '+$extraAccounts more',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                  ] else ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AccountsScreen(),
                        ),
                      ),
                      child: Text(
                        '+ Add cash, bank or wallet',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Quick actions (core only; rest under More) ──
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Quick actions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () => _openMoreTools(context),
                  child: const Text('More'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                child: Row(
                  children: [
                    _QuickAction(
                      icon: Icons.remove_circle_outline_rounded,
                      label: 'Expense',
                      color: AppColors.expense,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddTransactionFlow(
                            initialType: AddTxType.expense,
                          ),
                        ),
                      ),
                    ),
                    _QuickAction(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'Income',
                      color: AppColors.income,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddTransactionFlow(
                            initialType: AddTxType.income,
                          ),
                        ),
                      ),
                    ),
                    _QuickAction(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Transfer',
                      color: AppColors.loanLent,
                      onTap: () => showTransferSheet(context),
                    ),
                    _QuickAction(
                      icon: Icons.local_atm_rounded,
                      label: 'ATM',
                      color: const Color(0xFF5C6BC0),
                      onTap: () => showAtmSheet(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── This month ──────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    'This month',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Text(
                  monthLabel(DateTime.now()),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spending by category',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    CategoryChart(
                      data: state.spendByCategory(),
                      emptyLabel: 'No expenses this month yet',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // ── Recent ──────────────────────────────────────
            Text(
              'Recent',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            if (recent.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 28,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 32,
                        color: cs.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No transactions yet',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Use Quick actions or tap + to add one',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < recent.length; i++) ...[
                      _TxTile(tx: recent[i]),
                      if (i < recent.length - 1)
                        Divider(
                          height: 1,
                          indent: 68,
                          color: cs.outlineVariant.withValues(alpha: 0.4),
                        ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Secondary tools — opened from Home "More" so main stays uncluttered.
class _MoreToolsSheet extends StatelessWidget {
  const _MoreToolsSheet();

  void _open(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final goalsSub = state.goals.isEmpty
        ? 'Save for something'
        : '${state.goals.length} · ${formatPkr(state.totalGoalsSaved, compact: true)}';
    final budgetSub = (state.thisMonthBudget?.overallLimit ?? 0) > 0
        ? 'Left ${formatPkr(state.overallBudgetRemaining(DateTime.now()) ?? 0, compact: true)}'
        : 'Plan monthly spend';

    final items = <({
      IconData icon,
      String title,
      String subtitle,
      Color color,
      VoidCallback onTap,
    })>[
      (
        icon: Icons.flag_rounded,
        title: 'Goals',
        subtitle: goalsSub,
        color: const Color(0xFF00C853),
        onTap: () => _open(context, const GoalsScreen()),
      ),
      (
        icon: Icons.pie_chart_rounded,
        title: 'Budget',
        subtitle: budgetSub,
        color: const Color(0xFF5C6BC0),
        onTap: () => _open(context, const BudgetScreen()),
      ),
      (
        icon: Icons.account_balance_wallet_outlined,
        title: 'Accounts',
        subtitle: '${state.activeAccounts.length} accounts',
        color: const Color(0xFF00897B),
        onTap: () => _open(context, const AccountsScreen()),
      ),
      (
        icon: Icons.event_rounded,
        title: 'Events',
        subtitle: state.events.isEmpty
            ? 'Trips, weddings, projects'
            : '${state.events.length} events',
        color: const Color(0xFFFF7043),
        onTap: () => _open(context, const EventsScreen()),
      ),
      (
        icon: Icons.sms_rounded,
        title: 'SMS import',
        subtitle: 'Paste bank SMS to log txs',
        color: const Color(0xFF7E57C2),
        onTap: () => _open(context, const SmsImportScreen()),
      ),
      (
        icon: Icons.show_chart_rounded,
        title: 'Investments',
        subtitle: 'Track holdings',
        color: const Color(0xFF26A69A),
        onTap: () => _open(context, const InvestmentsScreen()),
      ),
      (
        icon: Icons.groups_rounded,
        title: 'Groups',
        subtitle: 'Shared expenses',
        color: const Color(0xFF42A5F5),
        onTap: () => _open(context, const GroupsScreen()),
      ),
      (
        icon: Icons.insights_rounded,
        title: 'Reports',
        subtitle: 'Charts & breakdowns',
        color: const Color(0xFF5C6BC0),
        onTap: () => _open(context, const ReportsScreen()),
      ),
      (
        icon: Icons.settings_outlined,
        title: 'Settings',
        subtitle: 'Backup, currency, security',
        color: const Color(0xFF78909C),
        onTap: () => _open(context, const SettingsScreen()),
      ),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'More tools',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Kept off the home screen so it stays simple',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.62,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final item = items[i];
                  return Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      onTap: item.onTap,
                      leading: CircleAvatar(
                        backgroundColor: item.color.withValues(alpha: 0.14),
                        child: Icon(item.icon, color: item.color, size: 20),
                      ),
                      title: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(item.subtitle),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  final MoneyTx tx;

  const _TxTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final fromName = state.accountById(tx.accountId)?.name ?? '';
    final toName = state.accountById(tx.relatedAccountId)?.name ?? '';
    final cur =
        tx.currencyCode.isEmpty ? state.currencyCode : tx.currencyCode;

    late final Color accent;
    late final IconData icon;
    late final String subtitle;
    late final String amountPrefix;
    late final Color amountColor;

    if (tx.isTransfer) {
      accent = AppColors.primary;
      icon = Icons.swap_horiz_rounded;
      subtitle = [
        if (fromName.isNotEmpty && toName.isNotEmpty) '$fromName → $toName',
        if (fromName.isNotEmpty && toName.isEmpty) 'From $fromName',
        formatDate(tx.date),
      ].join(' · ');
      // Goal deposit / transfer: money left the source account.
      amountPrefix = '-';
      amountColor = AppColors.expense;
    } else {
      final cat = tx.isExpense
          ? expenseCategoryById(tx.categoryId)
          : incomeSourceById(tx.categoryId);
      accent = cat.color;
      icon = cat.icon;
      subtitle =
          [cat.name, if (fromName.isNotEmpty) fromName, formatDate(tx.date)]
              .join(' · ');
      amountPrefix = tx.isExpense ? '-' : '+';
      amountColor = tx.isExpense ? AppColors.expense : AppColors.income;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      onTap: () {
        if (tx.isTransfer) {
          final openId = tx.relatedAccountId.isNotEmpty
              ? tx.relatedAccountId
              : tx.accountId;
          if (openId.isEmpty) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AccountDetailScreen(accountId: openId),
            ),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionDetailScreen(
              id: tx.id,
              isExpense: tx.isExpense,
            ),
          ),
        );
      },
      leading: CircleAvatar(
        backgroundColor: accent.withValues(alpha: 0.14),
        child: Icon(icon, color: accent, size: 20),
      ),
      title: Text(
        tx.title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      trailing: Text(
        '$amountPrefix${formatPkr(tx.amount, currency: cur)}',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: amountColor,
        ),
      ),
    );
  }
}
