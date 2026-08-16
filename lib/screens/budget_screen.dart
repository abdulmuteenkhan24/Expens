import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/categories.dart';
import '../models/budget.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/amount_input.dart';
import '../utils/formatters.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _month = DateTime(n.year, n.month);
  }

  void _shift(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  Future<void> _editOverall(AppState state, MonthlyBudget? existing) async {
    final ctrl = TextEditingController(
      text: existing != null && existing.overallLimit > 0
          ? formatAmountInput(existing.overallLimit)
          : '',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Monthly budget'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: const [AmountInputFormatter()],
          decoration: const InputDecoration(
            labelText: 'Overall limit',
            prefixText: 'Rs  ',
            helperText: 'Max you want to spend this month (all categories)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final limit = parseAmount(ctrl.text) ?? 0;
    final id = existing?.id ?? AppState.newId();
    await state.saveBudget(
      MonthlyBudget(
        id: id,
        month: _month,
        overallLimit: limit,
        categoryLimits: existing?.categoryLimits ?? {},
        notes: existing?.notes ?? '',
      ),
    );
  }

  Future<void> _editCategory(
    AppState state,
    MonthlyBudget? existing,
    String categoryId,
    String categoryName,
  ) async {
    final current = existing?.categoryLimits[categoryId] ?? 0;
    final ctrl = TextEditingController(
      text: current > 0 ? formatAmountInput(current) : '',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$categoryName budget'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: const [AmountInputFormatter()],
          decoration: InputDecoration(
            labelText: 'Limit for $categoryName',
            prefixText: 'Rs  ',
            helperText: 'Clear and save to remove this limit',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final limit = parseAmount(ctrl.text) ?? 0;
    final map = Map<String, double>.from(existing?.categoryLimits ?? {});
    if (limit <= 0) {
      map.remove(categoryId);
    } else {
      map[categoryId] = limit;
    }
    await state.saveBudget(
      MonthlyBudget(
        id: existing?.id ?? AppState.newId(),
        month: _month,
        overallLimit: existing?.overallLimit ?? 0,
        categoryLimits: map,
        notes: existing?.notes ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final budget = state.budgetForMonth(_month);
    final spent = state.totalSpendInMonth(_month);
    final overallLimit = budget?.overallLimit ?? 0;
    final remaining = overallLimit > 0 ? overallLimit - spent : 0.0;
    final hasOverall = overallLimit > 0;
    final overallPct =
        hasOverall ? (spent / overallLimit).clamp(0.0, 2.0) : 0.0;
    final overBudget = hasOverall && remaining < 0;
    final monthLabel = DateFormat('MMMM yyyy').format(_month);

    // Categories with a limit or with spend this month
    final cats = expenseCategories
        .where((c) => c.id != 'atm')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget'),
        actions: [
          IconButton(
            tooltip: 'Set overall budget',
            onPressed: () => _editOverall(state, budget),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => _shift(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  monthLabel,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              IconButton(
                onPressed: () => _shift(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Overall card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: overBudget
                    ? const [Color(0xFFE53935), Color(0xFFFF7043)]
                    : const [Color(0xFF00C853), Color(0xFF00BFA5)],
              ),
              boxShadow: [
                BoxShadow(
                  color: (overBudget ? AppColors.expense : AppColors.primary)
                      .withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasOverall ? 'This month budget' : 'Spending this month',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatPkr(spent),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (hasOverall) ...[
                  Text(
                    overBudget
                        ? 'Over by ${formatPkr(-remaining)} of ${formatPkr(overallLimit)}'
                        : '${formatPkr(remaining)} left of ${formatPkr(overallLimit)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: overallPct.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      color: Colors.white,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _editOverall(state, budget),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                    ),
                    child: const Text('Set monthly limit'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap a category to set its budget. Track how much you spend vs plan.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'By category',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          ...cats.map((cat) {
            final limit = budget?.categoryLimits[cat.id] ?? 0;
            final catSpent = state.categorySpendInMonth(cat.id, _month);
            if (limit <= 0 && catSpent <= 0) {
              // Still show popular categories with no spend for setup
              if (!_isPopular(cat.id)) return const SizedBox.shrink();
            }
            final pct = limit > 0 ? (catSpent / limit).clamp(0.0, 1.5) : 0.0;
            final over = limit > 0 && catSpent > limit;
            final left = limit > 0 ? limit - catSpent : null;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _editCategory(state, budget, cat.id, cat.name),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: cat.color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(cat.icon, color: cat.color, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              cat.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            formatPkr(catSpent, compact: true),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: over ? AppColors.expense : null,
                            ),
                          ),
                          if (limit > 0)
                            Text(
                              ' / ${formatPkr(limit, compact: true)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.45),
                                  ),
                            ),
                        ],
                      ),
                      if (limit > 0) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct.clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: cat.color.withValues(alpha: 0.12),
                            color: over ? AppColors.expense : cat.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          over
                              ? 'Over by ${formatPkr(-left!)}'
                              : '${formatPkr(left!)} left',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: over
                                        ? AppColors.expense
                                        : cat.color,
                                  ),
                        ),
                      ] else if (catSpent > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'No limit · tap to set budget',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.4),
                                ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Tap to set budget',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.4),
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _editOverall(state, budget),
            icon: const Icon(Icons.edit_outlined),
            label: Text(
              overallLimit > 0
                  ? 'Edit overall limit (${formatPkr(overallLimit, compact: true)})'
                  : 'Set overall monthly limit',
            ),
          ),
        ],
      ),
    );
  }

  bool _isPopular(String id) => const {
        'food',
        'groceries',
        'transport',
        'fuel',
        'bills',
        'shopping',
        'family',
        'home',
        'mobile',
        'entertainment',
        'health',
        'education',
      }.contains(id);
}
