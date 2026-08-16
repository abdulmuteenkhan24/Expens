import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/categories.dart';
import '../models/event.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/category_chart.dart';
import 'add_transaction_flow.dart';
import 'transaction_detail_screen.dart';

/// Trip / wedding / birthday detail — full expense history for the event.
class EventDetailScreen extends StatelessWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  Future<void> _editEvent(BuildContext context, FinanceEvent event) async {
    final nameCtrl = TextEditingController(text: event.name);
    final descCtrl = TextEditingController(text: event.description);
    var start = event.startDate;
    DateTime? end = event.endDate;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Edit event',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Description'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Start ${formatDateFull(start)}'),
                    trailing: const Icon(Icons.event),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: start,
                        firstDate: DateTime(2020),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365 * 3)),
                      );
                      if (d != null) setLocal(() => start = d);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      end == null
                          ? 'End date (optional)'
                          : 'End ${formatDateFull(end!)}',
                    ),
                    trailing: const Icon(Icons.event),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: end ?? start,
                        firstDate: start,
                        lastDate:
                            DateTime.now().add(const Duration(days: 365 * 3)),
                      );
                      if (d != null) setLocal(() => end = d);
                    },
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Save'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (ok == true && context.mounted && nameCtrl.text.trim().isNotEmpty) {
      await context.read<AppState>().updateEvent(
            event.copyWith(
              name: nameCtrl.text.trim(),
              description: descCtrl.text.trim(),
              startDate: start,
              endDate: end,
              clearEnd: end == null,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final event = state.eventById(eventId);
    if (event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Event not found')),
      );
    }

    final txs = state.transactionsForEvent(eventId);
    final spend = state.eventSpend(eventId);
    final income = state.eventIncome(eventId);
    final byCat = state.eventSpendByCategory(eventId);
    final expenseCount = txs.where((t) => t.isExpense).length;
    final incomeCount = txs.where((t) => !t.isExpense).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(event.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editEvent(context, event),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete event?'),
                  content: const Text(
                    'Transactions stay in Money, but will no longer be linked to this event.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                await state.deleteEvent(eventId);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // Header summary
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFF9B5DE5), Color(0xFF7B2CBF)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.name,
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                  ],
                ),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    event.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  [
                    formatDateFull(event.startDate),
                    if (event.endDate != null)
                      '→ ${formatDateFull(event.endDate!)}',
                  ].join(' '),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _Mini(
                        label: 'Spent',
                        value: formatPkr(spend, compact: true),
                      ),
                    ),
                    Expanded(
                      child: _Mini(
                        label: 'Income',
                        value: formatPkr(income, compact: true),
                      ),
                    ),
                    Expanded(
                      child: _Mini(
                        label: 'Net',
                        value: formatPkr(income - spend, compact: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CountChip(
                  label: 'Expenses',
                  count: expenseCount,
                  color: AppColors.expense,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CountChip(
                  label: 'Income',
                  count: incomeCount,
                  color: AppColors.income,
                ),
              ),
            ],
          ),
          if (byCat.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Spend by category',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: CategoryChart(
                  data: byCat,
                  emptyLabel: 'No expenses yet',
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                'Expense history',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              Text(
                '${txs.length} total',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (txs.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 40,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No transactions linked yet.\n'
                      'Add an expense and choose this event, or use the button below.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.55),
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...txs.map((t) {
              final cat = t.isExpense
                  ? expenseCategoryById(t.categoryId)
                  : incomeSourceById(t.categoryId);
              final acc = state.accountById(t.accountId)?.name ?? '';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionDetailScreen(
                        id: t.id,
                        isExpense: t.isExpense,
                      ),
                    ),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: cat.color.withValues(alpha: 0.15),
                    child: Icon(cat.icon, color: cat.color, size: 20),
                  ),
                  title: Text(
                    t.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    [
                      cat.name,
                      if (acc.isNotEmpty) acc,
                      formatDate(t.date),
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    '${t.isExpense ? '-' : '+'}${formatPkr(t.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color:
                          t.isExpense ? AppColors.expense : AppColors.income,
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_event_detail',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddTransactionFlow(
              initialType: AddTxType.expense,
              initialEventId: eventId,
            ),
          ),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add expense'),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  final String label;
  final String value;

  const _Mini({required this.label, required this.value});

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
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CountChip({
    required this.label,
    required this.count,
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
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
