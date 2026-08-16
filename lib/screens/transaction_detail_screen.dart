import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/categories.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'expense_form_screen.dart';
import 'income_form_screen.dart';

class TransactionDetailScreen extends StatelessWidget {
  final String id;
  final bool isExpense;

  const TransactionDetailScreen({
    super.key,
    required this.id,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (isExpense) {
      final e = state.expenses.where((x) => x.id == id).firstOrNull;
      if (e == null) {
        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('Not found')),
        );
      }
      final cat = expenseCategoryById(e.categoryId);
      final acc = state.accountById(e.accountId);
      final event = e.eventId.isEmpty ? null : state.eventById(e.eventId);
      return _DetailScaffold(
        amount: e.amount,
        currency: e.currencyCode.isEmpty ? state.currencyCode : e.currencyCode,
        isExpense: true,
        title: e.title,
        categoryName: cat.name,
        categoryIcon: cat.icon,
        categoryColor: cat.color,
        accountName: acc?.name ?? '—',
        date: e.date,
        tag: e.tag,
        location: e.location,
        eventName: event?.name,
        isRecurring: e.isRecurring,
        recurringRule: e.recurringRule,
        receiptPath: e.receiptPath,
        notes: e.notes,
        onEdit: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ExpenseFormScreen(expense: e)),
        ),
        onDelete: () async {
          await state.deleteExpense(e.id);
          if (context.mounted) Navigator.pop(context);
        },
      );
    }

    final e = state.incomes.where((x) => x.id == id).firstOrNull;
    if (e == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Not found')),
      );
    }
    final cat = incomeSourceById(e.sourceId);
    final acc = state.accountById(e.accountId);
    final event = e.eventId.isEmpty ? null : state.eventById(e.eventId);
    return _DetailScaffold(
      amount: e.amount,
      currency: e.currencyCode.isEmpty ? state.currencyCode : e.currencyCode,
      isExpense: false,
      title: e.title,
      categoryName: cat.name,
      categoryIcon: cat.icon,
      categoryColor: cat.color,
      accountName: acc?.name ?? '—',
      date: e.date,
      tag: e.tag,
      location: e.location,
      eventName: event?.name,
      isRecurring: e.isRecurring,
      recurringRule: e.recurringRule,
      receiptPath: e.receiptPath,
      notes: e.notes,
      onEdit: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => IncomeFormScreen(income: e)),
      ),
      onDelete: () async {
        await state.deleteIncome(e.id);
        if (context.mounted) Navigator.pop(context);
      },
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}

class _DetailScaffold extends StatelessWidget {
  final double amount;
  final String currency;
  final bool isExpense;
  final String title;
  final String categoryName;
  final IconData categoryIcon;
  final Color categoryColor;
  final String accountName;
  final DateTime date;
  final String tag;
  final String location;
  final String? eventName;
  final bool isRecurring;
  final String recurringRule;
  final String receiptPath;
  final String notes;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DetailScaffold({
    required this.amount,
    required this.currency,
    required this.isExpense,
    required this.title,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.accountName,
    required this.date,
    required this.tag,
    required this.location,
    required this.eventName,
    required this.isRecurring,
    required this.recurringRule,
    required this.receiptPath,
    required this.notes,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = isExpense ? AppColors.expense : AppColors.income;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete?'),
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
              if (ok == true) onDelete();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: color.withValues(alpha: 0.12),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: categoryColor.withValues(alpha: 0.2),
                  child: Icon(categoryIcon, color: categoryColor, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  '${isExpense ? '-' : '+'}${formatPkr(amount, currency: currency)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                _row(context, 'Category', categoryName),
                _row(context, 'Account', accountName),
                _row(context, 'Date', formatDateFull(date)),
                if (tag.isNotEmpty) _row(context, 'Tag', tag),
                if (location.isNotEmpty) _row(context, 'Location', location),
                if (eventName != null) _row(context, 'Event', eventName!),
                if (isRecurring)
                  _row(
                    context,
                    'Recurring',
                    recurringRule.isEmpty ? 'Yes' : recurringRule,
                  ),
                if (notes.isNotEmpty) _row(context, 'Notes', notes),
              ],
            ),
          ),
          if (receiptPath.isNotEmpty && File(receiptPath).existsSync()) ...[
            const SizedBox(height: 16),
            Text(
              'Receipt',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(receiptPath),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String k, String v) {
    return ListTile(
      dense: true,
      title: Text(
        k,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 200),
        child: Text(
          v,
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
