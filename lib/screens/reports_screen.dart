import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/categories.dart';
import '../models/transaction_filter.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/bank_logo.dart';
import '../widgets/category_chart.dart';
import 'budget_screen.dart';
import 'goals_screen.dart';

enum _ReportPeriod {
  thisMonth,
  lastMonth,
  thisWeek,
  last30,
  thisYear,
  all,
  custom,
}

/// Charts & reports — filter by period, account, event, tag, category.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  _ReportPeriod _period = _ReportPeriod.thisMonth;
  String? _accountId;
  String? _eventId;
  String? _tag;
  String? _categoryId;

  DateTime? _customFrom;
  DateTime? _customTo;

  ({DateTime? from, DateTime? to}) get _range {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_period) {
      case _ReportPeriod.thisMonth:
        return (from: DateTime(now.year, now.month, 1), to: today);
      case _ReportPeriod.lastMonth:
        final start = DateTime(now.year, now.month - 1, 1);
        final end = DateTime(now.year, now.month, 0); // last day prev month
        return (from: start, to: end);
      case _ReportPeriod.thisWeek:
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return (from: weekStart, to: today);
      case _ReportPeriod.last30:
        return (from: today.subtract(const Duration(days: 29)), to: today);
      case _ReportPeriod.thisYear:
        return (from: DateTime(now.year, 1, 1), to: today);
      case _ReportPeriod.all:
        return (from: null, to: null);
      case _ReportPeriod.custom:
        return (from: _customFrom, to: _customTo ?? today);
    }
  }

  String get _periodLabel {
    final r = _range;
    switch (_period) {
      case _ReportPeriod.thisMonth:
        return monthLabel(DateTime.now());
      case _ReportPeriod.lastMonth:
        final d = DateTime(DateTime.now().year, DateTime.now().month - 1, 1);
        return monthLabel(d);
      case _ReportPeriod.thisWeek:
        return 'This week';
      case _ReportPeriod.last30:
        return 'Last 30 days';
      case _ReportPeriod.thisYear:
        return 'Year ${DateTime.now().year}';
      case _ReportPeriod.all:
        return 'All time';
      case _ReportPeriod.custom:
        if (r.from == null && r.to == null) return 'Custom range';
        final a = r.from != null ? formatDateFull(r.from!) : '…';
        final b = r.to != null ? formatDateFull(r.to!) : '…';
        return '$a → $b';
    }
  }

  TransactionFilter get _filter {
    final r = _range;
    return TransactionFilter(
      accountId: _accountId,
      eventId: _eventId,
      tag: _tag,
      categoryId: _categoryId,
      from: r.from,
      to: r.to,
    );
  }

  bool get _hasExtraFilters =>
      _accountId != null ||
      _eventId != null ||
      _tag != null ||
      _categoryId != null ||
      _period != _ReportPeriod.thisMonth;

  void _clearFilters() {
    setState(() {
      _period = _ReportPeriod.thisMonth;
      _accountId = null;
      _eventId = null;
      _tag = null;
      _categoryId = null;
      _customFrom = null;
      _customTo = null;
    });
  }

  Future<void> _openFilterSheet() async {
    final state = context.read<AppState>();
    var period = _period;
    var accountId = _accountId;
    var eventId = _eventId;
    var tag = _tag;
    var categoryId = _categoryId;
    var customFrom = _customFrom;
    var customTo = _customTo;

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final tags = state.allTags;
            final events = state.events;
            final accounts = state.activeAccounts;
            final bottom = MediaQuery.of(ctx).viewInsets.bottom;

            Widget section(String title, Widget child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  child,
                  const SizedBox(height: 16),
                ],
              );
            }

            return Padding(
              padding: EdgeInsets.only(bottom: bottom),
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.85,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                builder: (ctx, scrollCtrl) {
                  return ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      Row(
                        children: [
                          Text(
                            'Report filters',
                            style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setLocal(() {
                                period = _ReportPeriod.thisMonth;
                                accountId = null;
                                eventId = null;
                                tag = null;
                                categoryId = null;
                                customFrom = null;
                                customTo = null;
                              });
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Filter by month, account, event, tag, category',
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: Theme.of(ctx)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.55),
                            ),
                      ),
                      const SizedBox(height: 16),
                      section(
                        'Period',
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final p in _ReportPeriod.values)
                              FilterChip(
                                label: Text(_periodChipLabel(p)),
                                selected: period == p,
                                onSelected: (_) => setLocal(() => period = p),
                              ),
                          ],
                        ),
                      ),
                      if (period == _ReportPeriod.custom)
                        section(
                          'Custom dates',
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.event, size: 18),
                                  onPressed: () async {
                                    final d = await showDatePicker(
                                      context: ctx,
                                      initialDate: customFrom ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (d != null) {
                                      setLocal(() => customFrom = d);
                                    }
                                  },
                                  label: Text(
                                    customFrom == null
                                        ? 'From'
                                        : formatDateFull(customFrom!),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.event, size: 18),
                                  onPressed: () async {
                                    final d = await showDatePicker(
                                      context: ctx,
                                      initialDate: customTo ?? DateTime.now(),
                                      firstDate: customFrom ?? DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (d != null) {
                                      setLocal(() => customTo = d);
                                    }
                                  },
                                  label: Text(
                                    customTo == null
                                        ? 'To'
                                        : formatDateFull(customTo!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      section(
                        'Account',
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('All accounts'),
                              selected: accountId == null,
                              onSelected: (_) =>
                                  setLocal(() => accountId = null),
                            ),
                            ...accounts.map(
                              (a) => FilterChip(
                                avatar: BankLogo.fromAccount(
                                  a,
                                  size: 18,
                                  radius: 4,
                                ),
                                label: Text(a.name),
                                selected: accountId == a.id,
                                onSelected: (_) =>
                                    setLocal(() => accountId = a.id),
                              ),
                            ),
                          ],
                        ),
                      ),
                      section(
                        'Event',
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('All events'),
                              selected: eventId == null,
                              onSelected: (_) =>
                                  setLocal(() => eventId = null),
                            ),
                            FilterChip(
                              label: const Text('No event'),
                              selected: eventId == '',
                              onSelected: (_) =>
                                  setLocal(() => eventId = ''),
                            ),
                            ...events.map(
                              (e) => FilterChip(
                                label: Text(e.name),
                                selected: eventId == e.id,
                                onSelected: (_) =>
                                    setLocal(() => eventId = e.id),
                              ),
                            ),
                          ],
                        ),
                      ),
                      section(
                        'Tag',
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('All tags'),
                              selected: tag == null,
                              onSelected: (_) => setLocal(() => tag = null),
                            ),
                            FilterChip(
                              label: const Text('No tag'),
                              selected: tag == '',
                              onSelected: (_) => setLocal(() => tag = ''),
                            ),
                            ...tags.map(
                              (t) => FilterChip(
                                label: Text(t),
                                selected: tag != null &&
                                    tag!.toLowerCase() == t.toLowerCase(),
                                onSelected: (_) => setLocal(() => tag = t),
                              ),
                            ),
                          ],
                        ),
                      ),
                      section(
                        'Expense category',
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('All'),
                              selected: categoryId == null,
                              onSelected: (_) =>
                                  setLocal(() => categoryId = null),
                            ),
                            ...expenseCategories.map(
                              (c) => FilterChip(
                                avatar: Icon(c.icon, size: 16, color: c.color),
                                label: Text(c.name),
                                selected: categoryId == c.id,
                                onSelected: (_) =>
                                    setLocal(() => categoryId = c.id),
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text('Apply filters'),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );

    if (applied == true && mounted) {
      setState(() {
        _period = period;
        _accountId = accountId;
        _eventId = eventId;
        _tag = tag;
        _categoryId = categoryId;
        _customFrom = customFrom;
        _customTo = customTo;
      });
    }
  }

  String _periodChipLabel(_ReportPeriod p) => switch (p) {
        _ReportPeriod.thisMonth => 'This month',
        _ReportPeriod.lastMonth => 'Last month',
        _ReportPeriod.thisWeek => 'This week',
        _ReportPeriod.last30 => 'Last 30 days',
        _ReportPeriod.thisYear => 'This year',
        _ReportPeriod.all => 'All time',
        _ReportPeriod.custom => 'Custom',
      };

  List<Widget> _activeFilterChips(AppState state) {
    final chips = <Widget>[];
    chips.add(
      InputChip(
        label: Text(_periodLabel),
        avatar: const Icon(Icons.calendar_month_rounded, size: 16),
        onPressed: _openFilterSheet,
      ),
    );
    if (_accountId != null) {
      final a = state.accountById(_accountId!);
      chips.add(
        InputChip(
          label: Text(a?.name ?? 'Account'),
          onDeleted: () => setState(() => _accountId = null),
        ),
      );
    }
    if (_eventId != null) {
      final name = _eventId!.isEmpty
          ? 'No event'
          : (state.eventById(_eventId!)?.name ?? 'Event');
      chips.add(
        InputChip(
          label: Text(name),
          onDeleted: () => setState(() => _eventId = null),
        ),
      );
    }
    if (_tag != null) {
      chips.add(
        InputChip(
          label: Text(_tag!.isEmpty ? 'No tag' : _tag!),
          onDeleted: () => setState(() => _tag = null),
        ),
      );
    }
    if (_categoryId != null) {
      chips.add(
        InputChip(
          label: Text(expenseCategoryById(_categoryId!).name),
          onDeleted: () => setState(() => _categoryId = null),
        ),
      );
    }
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final filter = _filter;
    final expenses = state.filterExpenses(filter);
    final incomes = state.filterIncomes(
      TransactionFilter(
        accountId: filter.accountId,
        eventId: filter.eventId,
        tag: filter.tag,
        // category filter is expense-only
        from: filter.from,
        to: filter.to,
      ),
    );

    final spend = state.spendByCategoryFrom(expenses);
    final incomeMap = state.incomeBySourceFrom(incomes);
    final expenseTotal = state.sumExpenses(expenses);
    final incomeTotal = state.sumIncomes(incomes);
    final net = incomeTotal - expenseTotal;
    final topCategories = spend.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalSpend = spend.values.fold(0.0, (s, v) => s + v);

    // Trend ignores period dates so you still see 6 months, but keeps other filters.
    final trendFilter = TransactionFilter(
      accountId: _accountId,
      eventId: _eventId,
      tag: _tag,
      categoryId: _categoryId,
    );
    final trend = state.monthlySpendTrendFiltered(trendFilter);

    // Account distribution of spend in filtered period (not balance).
    final spendByAccount = <String, double>{};
    for (final e in expenses) {
      final id = e.accountId;
      spendByAccount[id] = (spendByAccount[id] ?? 0) +
          state.amountInPrimary(e.amount, e.currencyCode);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          if (_hasExtraFilters)
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Reset'),
            ),
          IconButton(
            tooltip: 'Filters',
            onPressed: _openFilterSheet,
            icon: Badge(
              isLabelVisible: _hasExtraFilters,
              smallSize: 8,
              child: const Icon(Icons.tune_rounded),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          Text(
            'Filter reports by period, account, event, tag & more',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GoalsScreen()),
                  ),
                  icon: const Icon(Icons.flag_rounded, size: 18),
                  label: const Text('Goals'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BudgetScreen()),
                  ),
                  icon: const Icon(Icons.pie_chart_rounded, size: 18),
                  label: const Text('Budget'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Quick period row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final p in [
                  _ReportPeriod.thisMonth,
                  _ReportPeriod.lastMonth,
                  _ReportPeriod.thisWeek,
                  _ReportPeriod.last30,
                  _ReportPeriod.thisYear,
                  _ReportPeriod.all,
                  _ReportPeriod.custom,
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_periodChipLabel(p)),
                      selected: _period == p,
                      onSelected: (_) async {
                        if (p == _ReportPeriod.custom) {
                          setState(() => _period = p);
                          await _openFilterSheet();
                        } else {
                          setState(() => _period = p);
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ..._activeFilterChips(state),
              ActionChip(
                avatar: const Icon(Icons.tune_rounded, size: 16),
                label: const Text('More filters'),
                onPressed: _openFilterSheet,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Overview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overview',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    _periodLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${expenses.length} expenses · ${incomes.length} incomes',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.45),
                        ),
                  ),
                  const SizedBox(height: 14),
                  _row('Income', formatPkr(incomeTotal), AppColors.income),
                  const SizedBox(height: 8),
                  _row('Expenses', formatPkr(expenseTotal), AppColors.expense),
                  const Divider(height: 22),
                  _row(
                    'Net cash flow',
                    formatPkr(net),
                    net >= 0 ? AppColors.income : AppColors.expense,
                    bold: true,
                  ),
                  const SizedBox(height: 8),
                  _row(
                    'Total across accounts',
                    formatPkr(state.totalAccountsBalance),
                    AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Where money is going',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Spending by category · $_periodLabel',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                  ),
                  const SizedBox(height: 8),
                  CategoryChart(
                    data: spend,
                    emptyLabel: 'No expenses for this filter',
                  ),
                ],
              ),
            ),
          ),
          if (topCategories.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top spending categories',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ...topCategories.take(5).map((e) {
                      final cat = expenseCategoryById(e.key);
                      final pct =
                          totalSpend > 0 ? e.value / totalSpend * 100 : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(cat.icon, size: 18, color: cat.color),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    cat.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  formatPkr(e.value, compact: true),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (pct / 100).clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor:
                                    cat.color.withValues(alpha: 0.12),
                                color: cat.color,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${pct.toStringAsFixed(0)}% of spend',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.45),
                                  ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Income by source',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  CategoryChart(
                    data: incomeMap,
                    isIncome: true,
                    emptyLabel: 'No income for this filter',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '6-month spend trend',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _accountId != null || _eventId != null || _tag != null
                        ? 'Trend uses account / event / tag filters'
                        : 'See how your spending changes over time',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                  ),
                  const SizedBox(height: 16),
                  MonthlyBarChart(data: trend),
                ],
              ),
            ),
          ),
          if (spendByAccount.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spend by account',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Expenses in selected period',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                    ),
                    const SizedBox(height: 12),
                    ...() {
                      final entries = spendByAccount.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value));
                      return entries.map((e) {
                        final acc = state.accountById(e.key);
                        final pct = expenseTotal > 0
                            ? e.value / expenseTotal * 100
                            : 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              if (acc != null)
                                BankLogo.fromAccount(acc, size: 28, radius: 8)
                              else
                                const Icon(Icons.account_balance_wallet,
                                    size: 28),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  acc?.name ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                formatPkr(e.value, compact: true),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.expense,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 40,
                                child: Text(
                                  '${pct.toStringAsFixed(0)}%',
                                  textAlign: TextAlign.end,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.45),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        );
                      });
                    }(),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Money by account balances (always current, not filter-dependent)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Money by account',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Current balances (not affected by date filter)',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (state.activeAccounts.isEmpty)
                    Text(
                      'Add accounts to see balances here',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    ...state.activeAccounts.map((a) {
                      final bal = state.balanceFor(a.id);
                      final total = state.totalAccountsBalance;
                      final pct = total.abs() > 0
                          ? (bal / total.abs() * 100).clamp(-999.0, 999.0)
                          : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            BankLogo.fromAccount(a, size: 28, radius: 8),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                a.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
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
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${pct.abs().toStringAsFixed(0)}%',
                                textAlign: TextAlign.end,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.45),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Loans snapshot',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _row(
                    'To receive (lent)',
                    formatPkr(state.totalLentPending),
                    AppColors.loanLent,
                  ),
                  const SizedBox(height: 8),
                  _row(
                    'To repay (borrowed)',
                    formatPkr(state.totalBorrowedPending),
                    AppColors.loanBorrowed,
                  ),
                  if (state.investments.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _row(
                      'Investments value',
                      formatPkr(state.investmentValue),
                      AppColors.income,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color color, {bool bold = false}) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
