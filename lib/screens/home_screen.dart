import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/account_presets.dart';
import '../data/categories.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/category_chart.dart';
import '../widgets/transaction_tile.dart';
import 'expense_form_screen.dart';
import 'income_form_screen.dart';
import 'investments_screen.dart';
import 'settings_screen.dart';
import 'sms_import_screen.dart';

/// Home — 360° control: accounts, activity, and reports at a glance.
class HomeScreen extends StatelessWidget {
  final void Function(int tab)? onGoToTab;

  const HomeScreen({super.key, this.onGoToTab});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final recent = state.expenses.take(5).toList();
    final themeIcon = switch (state.themeMode) {
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.dark => Icons.dark_mode_rounded,
      ThemeMode.system => Icons.brightness_auto_rounded,
    };
    final accounts = state.activeAccounts.take(6).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expens',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      Text(
                        'Keep your money under control',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.55),
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Settings',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.settings_outlined),
                ),
                IconButton(
                  tooltip: 'Theme',
                  onPressed: state.cycleTheme,
                  icon: Icon(themeIcon),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Total net control ───────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C853), Color(0xFF00BFA5)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total balance',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatPkr(state.totalAccountsBalance),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Across ${state.activeAccounts.length} accounts · ${state.currencyCode}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          label: 'Income',
                          value: formatPkr(state.monthIncome, compact: true),
                        ),
                      ),
                      Expanded(
                        child: _MiniStat(
                          label: 'Expense',
                          value: formatPkr(state.monthExpense, compact: true),
                        ),
                      ),
                      Expanded(
                        child: _MiniStat(
                          label: 'Month net',
                          value: formatPkr(state.monthBalance, compact: true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── Pillar: Accounts ────────────────────────────
            _SectionHeader(
              title: 'Accounts',
              subtitle: 'Cash, bank & wallets in one place',
              action: 'See all',
              onAction: () => onGoToTab?.call(1),
            ),
            const SizedBox(height: 10),
            if (accounts.isEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.add_card_rounded),
                  title: const Text('Add your first account'),
                  subtitle: const Text('Cash, HBL, JazzCash…'),
                  onTap: () => onGoToTab?.call(1),
                ),
              )
            else
              SizedBox(
                height: 108,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: accounts.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final a = accounts[i];
                    final bal = state.balanceFor(a.id);
                    final preset =
                        presetById(a.presetId.isEmpty ? 'cash' : a.presetId);
                    return Container(
                      width: 148,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: preset.color.withValues(alpha: 0.1),
                        border: Border.all(
                          color: preset.color.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            a.presetId.isNotEmpty
                                ? preset.icon
                                : typeIcon(a.type),
                            color: preset.color,
                            size: 22,
                          ),
                          const Spacer(),
                          Text(
                            a.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            formatPkr(bal, compact: true),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: bal >= 0
                                  ? AppColors.income
                                  : AppColors.expense,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),

            // ── Pillar: Track ───────────────────────────────
            _SectionHeader(
              title: 'Expense tracker',
              subtitle: 'Record, categorize, stay in control',
              action: 'Track',
              onAction: () => onGoToTab?.call(2),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.remove_circle_outline,
                    label: 'Expense',
                    color: AppColors.expense,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ExpenseFormScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.add_circle_outline,
                    label: 'Income',
                    color: AppColors.income,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const IncomeFormScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.sms_outlined,
                    label: 'SMS',
                    color: AppColors.loanLent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SmsImportScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Pillar: Reports ─────────────────────────────
            _SectionHeader(
              title: 'Charts & reports',
              subtitle: 'See where money is going',
              action: 'Reports',
              onAction: () => onGoToTab?.call(3),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spend by category',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    CategoryChart(
                      data: state.spendByCategory(),
                      emptyLabel: 'Add expenses to unlock charts',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // More tools
            Text(
              'More',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _FeatureCard(
                    icon: Icons.handshake_rounded,
                    title: 'Loans',
                    subtitle: formatPkr(
                      state.totalBorrowedPending + state.totalLentPending,
                      compact: true,
                    ),
                    color: AppColors.loanBorrowed,
                    onTap: () => onGoToTab?.call(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FeatureCard(
                    icon: Icons.trending_up_rounded,
                    title: 'Investments',
                    subtitle: formatPkr(state.investmentValue, compact: true),
                    color: AppColors.income,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InvestmentsScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            _SectionHeader(
              title: 'Recent activity',
              subtitle: 'Latest expenses',
              action: 'See all',
              onAction: () => onGoToTab?.call(2),
            ),
            const SizedBox(height: 8),
            if (recent.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No activity yet. Add an expense or income to start.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ...recent.map((e) {
                final cat = expenseCategoryById(e.categoryId);
                final cur = e.currencyCode.isEmpty
                    ? state.currencyCode
                    : e.currencyCode;
                return TransactionTile(
                  key: ValueKey(e.id),
                  title: e.title,
                  subtitle: cat.name,
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
              }),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
              ),
            ],
          ),
        ),
        TextButton(onPressed: onAction, child: Text(action)),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
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
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
      ),
    );
  }
}
