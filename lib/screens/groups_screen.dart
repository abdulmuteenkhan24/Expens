import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/group.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/amount_input.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  Future<void> _createGroup(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final membersCtrl = TextEditingController(text: 'Me');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Group name',
                hintText: 'e.g. Flatmates, Trip',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: membersCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Members (comma separated)',
                hintText: 'Me, Ali, Sara',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    final members = membersCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (members.isEmpty) members.add('Me');

    await context.read<AppState>().addGroup(
          FinanceGroup(
            id: AppState.newId(),
            name: name,
            members: members,
            createdAt: DateTime.now(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final groups = state.groups;

    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),
      body: groups.isEmpty
          ? EmptyState(
              icon: Icons.groups_rounded,
              title: 'No groups yet',
              subtitle:
                  'Split bills with friends or family. Track who paid and who owes what.',
              actionLabel: 'Create group',
              onAction: () => _createGroup(context),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: groups.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final g = groups[i];
                final expenses = state.groupExpensesFor(g.id);
                final total =
                    expenses.fold(0.0, (s, e) => s + e.amount);
                return Card(
                  child: ListTile(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupDetailScreen(groupId: g.id),
                      ),
                    ),
                    leading: CircleAvatar(
                      backgroundColor:
                          const Color(0xFF9B5DE5).withValues(alpha: 0.15),
                      child: const Icon(
                        Icons.groups_rounded,
                        color: Color(0xFF9B5DE5),
                      ),
                    ),
                    title: Text(
                      g.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${g.members.length} members · ${expenses.length} expenses',
                    ),
                    trailing: Text(
                      formatPkr(total, compact: true),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_groups',
        onPressed: () => _createGroup(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class GroupDetailScreen extends StatelessWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  Future<void> _addExpense(BuildContext context, FinanceGroup group) async {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    var paidBy = group.members.first;
    final split = {...group.members};

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add shared expense'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g. Dinner, Groceries',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: const [AmountInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: 'Rs  ',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: paidBy,
                  decoration: const InputDecoration(labelText: 'Paid by'),
                  items: group.members
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setLocal(() => paidBy = v);
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  'Split among',
                  style: Theme.of(ctx).textTheme.labelLarge,
                ),
                ...group.members.map(
                  (m) => CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(m),
                    value: split.contains(m),
                    onChanged: (v) {
                      setLocal(() {
                        if (v == true) {
                          split.add(m);
                        } else {
                          split.remove(m);
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (ok != true || !context.mounted) return;
    final amount = parseAmount(amountCtrl.text);
    final title = titleCtrl.text.trim();
    if (amount == null || amount <= 0 || title.isEmpty || split.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill title, amount, and at least one person')),
      );
      return;
    }

    await context.read<AppState>().addGroupExpense(
          GroupExpense(
            id: AppState.newId(),
            groupId: group.id,
            title: title,
            amount: amount,
            paidBy: paidBy,
            splitAmong: split.toList(),
            date: DateTime.now(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    FinanceGroup? group;
    for (final g in state.groups) {
      if (g.id == groupId) {
        group = g;
        break;
      }
    }
    if (group == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Group not found')),
      );
    }
    final g = group;

    final expenses = state.groupExpensesFor(groupId);
    final balances = computeBalances(g.members, expenses);

    return Scaffold(
      appBar: AppBar(
        title: Text(g.name),
        actions: [
          IconButton(
            tooltip: 'Delete group',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete group?'),
                  content: const Text('All shared expenses will be removed.'),
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
                await state.deleteGroup(groupId);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Text(
            'Balances',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          ...group.members.map((m) {
            final bal = balances[m] ?? 0;
            final color = bal >= 0 ? AppColors.income : AppColors.expense;
            final label = bal.abs() < 0.5
                ? 'Settled'
                : bal > 0
                    ? 'Gets back ${formatPkr(bal)}'
                    : 'Owes ${formatPkr(-bal)}';
            return Card(
              child: ListTile(
                title: Text(m, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          Text(
            'Expenses',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          if (expenses.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No shared expenses yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                  ),
                ),
              ),
            )
          else
            ...expenses.map(
              (e) => Card(
                child: ListTile(
                  title: Text(
                    e.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Paid by ${e.paidBy} · split ${e.splitAmong.length} · ${formatDate(e.date)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatPkr(e.amount),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () => state.deleteGroupExpense(e.id),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_group_detail',
        onPressed: () => _addExpense(context, g),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Expense'),
      ),
    );
  }
}
