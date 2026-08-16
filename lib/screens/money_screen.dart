import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/account_presets.dart';
import '../data/categories.dart';
import '../models/money_tx.dart';
import '../models/transaction_filter.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/bank_logo.dart';
import 'account_detail_screen.dart';
import 'accounts_screen.dart';
import 'add_transaction_flow.dart';
import 'atm_sheet.dart';
import 'events_screen.dart';
import 'transaction_detail_screen.dart';
import 'transfer_sheet.dart';

enum _MoneyPeriod {
  thisMonth,
  lastMonth,
  thisWeek,
  last30,
  all,
  custom,
}

enum _MoneyKindFilter { all, expense, income }

class MoneyScreen extends StatefulWidget {
  const MoneyScreen({super.key});

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> {
  final _searchCtrl = TextEditingController();
  final _listKey = GlobalKey();

  _MoneyPeriod _period = _MoneyPeriod.thisMonth;
  late DateTime _month; // used for month arrow navigation
  DateTime? _customFrom;
  DateTime? _customTo;

  String? _accountId;
  String? _eventId;
  String? _tag;
  String? _categoryId;
  _MoneyKindFilter _kind = _MoneyKindFilter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _month = DateTime(n.year, n.month);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  ({DateTime? from, DateTime? to}) get _range {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_period) {
      case _MoneyPeriod.thisMonth:
        return (
          from: DateTime(_month.year, _month.month, 1),
          to: DateTime(_month.year, _month.month + 1, 0),
        );
      case _MoneyPeriod.lastMonth:
        final start = DateTime(now.year, now.month - 1, 1);
        final end = DateTime(now.year, now.month, 0);
        return (from: start, to: end);
      case _MoneyPeriod.thisWeek:
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return (from: weekStart, to: today);
      case _MoneyPeriod.last30:
        return (from: today.subtract(const Duration(days: 29)), to: today);
      case _MoneyPeriod.all:
        return (from: null, to: null);
      case _MoneyPeriod.custom:
        return (from: _customFrom, to: _customTo ?? today);
    }
  }

  String get _periodLabel {
    final r = _range;
    switch (_period) {
      case _MoneyPeriod.thisMonth:
        return DateFormat('MMM yyyy').format(_month);
      case _MoneyPeriod.lastMonth:
        final d = DateTime(DateTime.now().year, DateTime.now().month - 1, 1);
        return DateFormat('MMM yyyy').format(d);
      case _MoneyPeriod.thisWeek:
        return 'This week';
      case _MoneyPeriod.last30:
        return 'Last 30 days';
      case _MoneyPeriod.all:
        return 'All time';
      case _MoneyPeriod.custom:
        if (r.from == null && r.to == null) return 'Custom';
        final a = r.from != null ? formatDateFull(r.from!) : '…';
        final b = r.to != null ? formatDateFull(r.to!) : '…';
        return '$a → $b';
    }
  }

  TransactionFilter get _filter {
    final r = _range;
    return TransactionFilter(
      query: _query,
      accountId: _accountId,
      eventId: _eventId,
      tag: _tag,
      categoryId: _categoryId,
      from: r.from,
      to: r.to,
    );
  }

  bool get _hasFilters =>
      _query.trim().isNotEmpty ||
      _accountId != null ||
      _eventId != null ||
      _tag != null ||
      _categoryId != null ||
      _kind != _MoneyKindFilter.all ||
      _period != _MoneyPeriod.thisMonth;

  void _clearFilters() {
    setState(() {
      _period = _MoneyPeriod.thisMonth;
      final n = DateTime.now();
      _month = DateTime(n.year, n.month);
      _customFrom = null;
      _customTo = null;
      _accountId = null;
      _eventId = null;
      _tag = null;
      _categoryId = null;
      _kind = _MoneyKindFilter.all;
      _query = '';
      _searchCtrl.clear();
    });
  }

  void _shiftMonth(int delta) {
    setState(() {
      _period = _MoneyPeriod.thisMonth;
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  void _scrollToTransactions() {
    final ctx = _listKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _openFilterSheet() async {
    final state = context.read<AppState>();
    var period = _period;
    var month = _month;
    var accountId = _accountId;
    var eventId = _eventId;
    var tag = _tag;
    var categoryId = _categoryId;
    var kind = _kind;
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

            String periodLabel(_MoneyPeriod p) => switch (p) {
                  _MoneyPeriod.thisMonth => 'This month',
                  _MoneyPeriod.lastMonth => 'Last month',
                  _MoneyPeriod.thisWeek => 'This week',
                  _MoneyPeriod.last30 => 'Last 30 days',
                  _MoneyPeriod.all => 'All time',
                  _MoneyPeriod.custom => 'Custom',
                };

            return Padding(
              padding: EdgeInsets.only(bottom: bottom),
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.88,
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
                            'Filter transactions',
                            style:
                                Theme.of(ctx).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setLocal(() {
                                period = _MoneyPeriod.thisMonth;
                                final n = DateTime.now();
                                month = DateTime(n.year, n.month);
                                accountId = null;
                                eventId = null;
                                tag = null;
                                categoryId = null;
                                kind = _MoneyKindFilter.all;
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
                        'Date, type, account, event, tag, category',
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
                            for (final p in _MoneyPeriod.values)
                              FilterChip(
                                label: Text(periodLabel(p)),
                                selected: period == p,
                                onSelected: (_) => setLocal(() => period = p),
                              ),
                          ],
                        ),
                      ),
                      if (period == _MoneyPeriod.thisMonth)
                        section(
                          'Month',
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => setLocal(
                                  () => month =
                                      DateTime(month.year, month.month - 1),
                                ),
                                icon: const Icon(Icons.chevron_left_rounded),
                              ),
                              Expanded(
                                child: Text(
                                  DateFormat('MMMM yyyy').format(month),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => setLocal(
                                  () => month =
                                      DateTime(month.year, month.month + 1),
                                ),
                                icon: const Icon(Icons.chevron_right_rounded),
                              ),
                            ],
                          ),
                        ),
                      if (period == _MoneyPeriod.custom)
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
                                      initialDate:
                                          customFrom ?? DateTime.now(),
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
                                      firstDate:
                                          customFrom ?? DateTime(2020),
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
                        'Type',
                        Wrap(
                          spacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('All'),
                              selected: kind == _MoneyKindFilter.all,
                              onSelected: (_) => setLocal(
                                () => kind = _MoneyKindFilter.all,
                              ),
                            ),
                            FilterChip(
                              label: const Text('Expense'),
                              selected: kind == _MoneyKindFilter.expense,
                              onSelected: (_) => setLocal(
                                () => kind = _MoneyKindFilter.expense,
                              ),
                            ),
                            FilterChip(
                              label: const Text('Income'),
                              selected: kind == _MoneyKindFilter.income,
                              onSelected: (_) => setLocal(
                                () => kind = _MoneyKindFilter.income,
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
                        'Category',
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
                            // Show expense cats when all/expense; income sources when income
                            ...(kind == _MoneyKindFilter.income
                                    ? incomeSources
                                    : expenseCategories)
                                .map(
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
        _month = month;
        _accountId = accountId;
        _eventId = eventId;
        _tag = tag;
        _categoryId = categoryId;
        _kind = kind;
        _customFrom = customFrom;
        _customTo = customTo;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final filter = _filter;
    final kind = switch (_kind) {
      _MoneyKindFilter.all => null,
      _MoneyKindFilter.expense => MoneyTxKind.expense,
      _MoneyKindFilter.income => MoneyTxKind.income,
    };
    final txs = state.filterMoneyTransactions(filter, kind: kind);
    final accounts = state.mainAccountsByBalance;

    var expenseSum = 0.0;
    var incomeSum = 0.0;
    for (final t in txs) {
      if (t.isTransfer) continue; // transfers move money, not income/expense
      final a = state.amountInPrimary(t.amount, t.currencyCode);
      if (t.isExpense) {
        expenseSum += a;
      } else {
        incomeSum += a;
      }
    }

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Money'),
        actions: [
          if (_hasFilters)
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Reset'),
            ),
          IconButton(
            tooltip: 'Filter transactions',
            onPressed: _openFilterSheet,
            icon: Badge(
              isLabelVisible: _hasFilters,
              smallSize: 8,
              child: const Icon(Icons.tune_rounded),
            ),
          ),
          IconButton(
            tooltip: 'All accounts',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountsScreen()),
            ),
            icon: const Icon(Icons.account_balance_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          // Month / period header
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
            child: Row(
              children: [
                if (_period == _MoneyPeriod.thisMonth)
                  IconButton(
                    onPressed: () => _shiftMonth(-1),
                    icon: const Icon(Icons.chevron_left_rounded),
                  )
                else
                  const SizedBox(width: 48),
                Expanded(
                  child: InkWell(
                    onTap: _openFilterSheet,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          Text(
                            _periodLabel,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Tap to change period & filters',
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: cs.onSurface.withValues(alpha: 0.45),
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_period == _MoneyPeriod.thisMonth)
                  IconButton(
                    onPressed: () => _shiftMonth(1),
                    icon: const Icon(Icons.chevron_right_rounded),
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Search transactions…',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Filters',
                  onPressed: _openFilterSheet,
                  icon: Badge(
                    isLabelVisible: _hasFilters && _query.isEmpty
                        ? true
                        : (_accountId != null ||
                            _eventId != null ||
                            _tag != null ||
                            _categoryId != null ||
                            _kind != _MoneyKindFilter.all),
                    smallSize: 8,
                    child: const Icon(Icons.tune_rounded),
                  ),
                ),
              ],
            ),
          ),
          // Quick period chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final p in [
                  _MoneyPeriod.thisMonth,
                  _MoneyPeriod.lastMonth,
                  _MoneyPeriod.thisWeek,
                  _MoneyPeriod.last30,
                  _MoneyPeriod.all,
                  _MoneyPeriod.custom,
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(switch (p) {
                        _MoneyPeriod.thisMonth => 'Month',
                        _MoneyPeriod.lastMonth => 'Last mo',
                        _MoneyPeriod.thisWeek => 'Week',
                        _MoneyPeriod.last30 => '30 days',
                        _MoneyPeriod.all => 'All',
                        _MoneyPeriod.custom => 'Custom',
                      }),
                      selected: _period == p,
                      onSelected: (_) async {
                        if (p == _MoneyPeriod.custom) {
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
          const SizedBox(height: 4),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total balance',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.55),
                            ),
                      ),
                      Text(
                        formatPkr(state.whatYouHave),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...accounts.map((a) {
                  final bal = state.balanceFor(a.id);
                  final isCard = a.isCreditCard;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AccountDetailScreen(accountId: a.id),
                        ),
                      ),
                      leading: BankLogo.fromAccount(a, size: 44, radius: 12),
                      title: Text(
                        a.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        isCard
                            ? state.creditBalanceLabel(a.id)
                            : typeLabel(a.type),
                      ),
                      trailing: Text(
                        isCard
                            ? (bal > 0
                                ? 'owe ${formatPkr(bal)}'
                                : 'paid up')
                            : formatPkr(bal),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isCard
                              ? (bal > 0
                                  ? AppColors.expense
                                  : AppColors.income)
                              : (bal >= 0
                                  ? AppColors.income
                                  : AppColors.expense),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Text(
                  'Quick actions',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Quick(
                      icon: Icons.history_rounded,
                      label: 'History',
                      onTap: _scrollToTransactions,
                    ),
                    _Quick(
                      icon: Icons.local_atm_rounded,
                      label: 'ATM',
                      onTap: () => showAtmSheet(context),
                    ),
                    _Quick(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Transfer',
                      onTap: () => showTransferSheet(context),
                    ),
                    _Quick(
                      icon: Icons.event_rounded,
                      label: 'Events',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EventsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Filtered period summary
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'In · $_periodLabel',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: cs.onSurface.withValues(alpha: 0.5),
                                    ),
                              ),
                              Text(
                                formatPkr(incomeSum, compact: true),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.income,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Out',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: cs.onSurface.withValues(alpha: 0.5),
                                    ),
                              ),
                              Text(
                                formatPkr(expenseSum, compact: true),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.expense,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Net',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: cs.onSurface.withValues(alpha: 0.5),
                                    ),
                              ),
                              Text(
                                formatPkr(incomeSum - expenseSum, compact: true),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: (incomeSum - expenseSum) >= 0
                                      ? AppColors.income
                                      : AppColors.expense,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                KeyedSubtree(
                  key: _listKey,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Transactions · $_periodLabel',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      Text(
                        '${txs.length}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.45),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
                if (_hasFilters) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (_kind != _MoneyKindFilter.all)
                        InputChip(
                          label: Text(
                            _kind == _MoneyKindFilter.expense
                                ? 'Expense'
                                : 'Income',
                          ),
                          onDeleted: () =>
                              setState(() => _kind = _MoneyKindFilter.all),
                        ),
                      if (_accountId != null)
                        InputChip(
                          label: Text(
                            state.accountById(_accountId!)?.name ?? 'Account',
                          ),
                          onDeleted: () => setState(() => _accountId = null),
                        ),
                      if (_eventId != null)
                        InputChip(
                          label: Text(
                            _eventId!.isEmpty
                                ? 'No event'
                                : (state.eventById(_eventId!)?.name ?? 'Event'),
                          ),
                          onDeleted: () => setState(() => _eventId = null),
                        ),
                      if (_tag != null)
                        InputChip(
                          label: Text(_tag!.isEmpty ? 'No tag' : _tag!),
                          onDeleted: () => setState(() => _tag = null),
                        ),
                      if (_categoryId != null)
                        InputChip(
                          label: Text(
                            (_kind == _MoneyKindFilter.income
                                    ? incomeSourceById(_categoryId!)
                                    : expenseCategoryById(_categoryId!))
                                .name,
                          ),
                          onDeleted: () => setState(() => _categoryId = null),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                if (txs.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 36,
                            color: cs.onSurface.withValues(alpha: 0.35),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _hasFilters
                                ? 'No transactions match filters'
                                : 'No transactions in this period',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.55),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_hasFilters) ...[
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: _clearFilters,
                              child: const Text('Clear filters'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else
                  ...txs.map((t) => _MoneyTxTile(tx: t)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_money',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTransactionFlow()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
      ),
    );
  }
}

class _Quick extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _Quick({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoneyTxTile extends StatelessWidget {
  final MoneyTx tx;

  const _MoneyTxTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final fromName = state.accountById(tx.accountId)?.name ?? '';
    final toName = state.accountById(tx.relatedAccountId)?.name ?? '';
    final cur =
        tx.currencyCode.isEmpty ? state.currencyCode : tx.currencyCode;
    final eventName = tx.eventId.isEmpty
        ? null
        : state.eventById(tx.eventId)?.name;

    late final Color accent;
    late final IconData icon;
    late final String subtitle;
    late final bool outflow;

    if (tx.isTransfer) {
      accent = AppColors.primary;
      icon = Icons.swap_horiz_rounded;
      subtitle = [
        if (fromName.isNotEmpty && toName.isNotEmpty) '$fromName → $toName',
        if (fromName.isNotEmpty && toName.isEmpty) fromName,
        if (tx.tag.isNotEmpty) tx.tag,
        ?eventName,
        formatDate(tx.date),
      ].join(' · ');
      outflow = true;
    } else {
      final cat = tx.isExpense
          ? expenseCategoryById(tx.categoryId)
          : incomeSourceById(tx.categoryId);
      accent = cat.color;
      icon = cat.icon;
      subtitle = [
        cat.name,
        if (fromName.isNotEmpty) fromName,
        if (tx.tag.isNotEmpty) tx.tag,
        ?eventName,
        formatDate(tx.date),
      ].join(' · ');
      outflow = tx.isExpense;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
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
          backgroundColor: accent.withValues(alpha: 0.15),
          child: Icon(icon, color: accent, size: 20),
        ),
        title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '${outflow ? '-' : '+'}${formatPkr(tx.amount, currency: cur)}',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: outflow ? AppColors.expense : AppColors.income,
          ),
        ),
      ),
    );
  }
}
