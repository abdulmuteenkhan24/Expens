import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/goal.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/amount_input.dart';
import '../utils/formatters.dart';
import '../widgets/account_picker.dart';
import '../widgets/empty_state.dart';

IconData goalIcon(String id) => switch (id) {
      'home' => Icons.home_rounded,
      'car' => Icons.directions_car_rounded,
      'flight' => Icons.flight_rounded,
      'phone' => Icons.phone_iphone_rounded,
      'school' => Icons.school_rounded,
      'emergency' => Icons.health_and_safety_rounded,
      'gift' => Icons.card_giftcard_rounded,
      'ring' => Icons.diamond_rounded,
      'piggy' => Icons.savings_rounded,
      _ => Icons.flag_rounded,
    };

Color goalColor(String id) => switch (id) {
      'home' => const Color(0xFF8D6E63),
      'car' => const Color(0xFF42A5F5),
      'flight' => const Color(0xFF26A69A),
      'phone' => const Color(0xFF7E57C2),
      'school' => const Color(0xFF66BB6A),
      'emergency' => const Color(0xFFEF5350),
      'gift' => const Color(0xFFFFB74D),
      'ring' => const Color(0xFFEC407A),
      'piggy' => const Color(0xFF00C853),
      _ => const Color(0xFF5C6BC0),
    };

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final list = state.goals;
    final totalSaved = state.totalGoalsSaved;
    final totalTarget = state.totalGoalsTarget;
    final overall = totalTarget > 0 ? totalSaved / totalTarget : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Savings goals')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_goals',
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Goal'),
      ),
      body: list.isEmpty
          ? EmptyState(
              icon: Icons.flag_rounded,
              title: 'No savings goals yet',
              subtitle:
                  'Each goal gets its own savings pot. Move money from cash/bank into the pot — not an expense.',
              actionLabel: 'Create goal',
              onAction: () => _openForm(context),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: AppColors.brandGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'In savings pots',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatPkr(totalSaved),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      Text(
                        'of ${formatPkr(totalTarget)} target · '
                        '${(overall * 100).clamp(0, 999).toStringAsFixed(0)}% · still yours',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: overall.clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...list.map(
                  (g) => _GoalCard(
                    goal: g,
                    saved: state.savedForGoal(g),
                    potName:
                        state.accountById(g.savingsAccountId)?.name ?? '',
                    onTap: () => _openDetail(context, g),
                    onAdd: () => _contribute(context, g),
                  ),
                ),
              ],
            ),
    );
  }

  void _openForm(BuildContext context, {SavingsGoal? goal}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GoalFormScreen(goal: goal)),
    );
  }

  void _openDetail(BuildContext context, SavingsGoal goal) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GoalDetailScreen(goalId: goal.id)),
    );
  }

  Future<void> _contribute(BuildContext context, SavingsGoal goal) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _ContributeSheet(goal: goal),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final double saved;
  final String potName;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _GoalCard({
    required this.goal,
    required this.saved,
    required this.potName,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final color = goalColor(goal.iconId);
    final days = goal.daysLeft;
    final progress = goal.progressOf(saved);
    final remaining = goal.remainingOf(saved);
    final done = goal.isCompleteWith(saved);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(goalIcon(goal.iconId), color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          [
                            if (done) 'Completed 🎉',
                            if (!done)
                              '${formatPkr(saved, compact: true)} of ${formatPkr(goal.targetAmount, compact: true)}',
                            if (days != null && !done)
                              days < 0 ? 'Overdue' : '$days days left',
                          ].join(' · '),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                        ),
                        Text(
                          potName.isEmpty
                              ? 'No savings account yet · deposit to link'
                              : 'Savings: $potName',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'Move to savings pot',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: color.withValues(alpha: 0.12),
                  color: done ? AppColors.income : color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${(progress * 100).toStringAsFixed(0)}% · '
                '${formatPkr(remaining, compact: true)} to go',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GoalFormScreen extends StatefulWidget {
  final SavingsGoal? goal;

  const GoalFormScreen({super.key, this.goal});

  @override
  State<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends State<GoalFormScreen> {
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _iconId = 'flag';
  DateTime? _deadline;

  bool get isEdit => widget.goal != null;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    if (g != null) {
      _nameCtrl.text = g.name;
      _targetCtrl.text = formatAmountInput(g.targetAmount);
      _notesCtrl.text = g.notes;
      _iconId = g.iconId;
      _deadline = g.deadline;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final target = parseAmount(_targetCtrl.text);
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter goal name')),
      );
      return;
    }
    if (target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter target amount')),
      );
      return;
    }
    final state = context.read<AppState>();
    if (isEdit) {
      await state.updateGoal(
        widget.goal!.copyWith(
          name: name,
          targetAmount: target,
          notes: _notesCtrl.text.trim(),
          iconId: _iconId,
          deadline: _deadline,
          clearDeadline: _deadline == null,
        ),
      );
    } else {
      await state.addGoal(
        SavingsGoal(
          id: AppState.newId(),
          name: name,
          targetAmount: target,
          notes: _notesCtrl.text.trim(),
          iconId: _iconId,
          deadline: _deadline,
          createdAt: DateTime.now(),
        ),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit goal' : 'New goal')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Goal name',
              hintText: 'e.g. Umrah, New phone, Emergency',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _targetCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [AmountInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'Target amount',
              prefixText: 'Rs  ',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Icon',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: goalIconIds.map((id) {
              final on = _iconId == id;
              final c = goalColor(id);
              return ChoiceChip(
                selected: on,
                label: Icon(goalIcon(id), size: 20, color: c),
                onSelected: (_) => setState(() => _iconId = id),
                selectedColor: c.withValues(alpha: 0.2),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Deadline (optional)',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Material(
            color: Theme.of(context).inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _deadline ??
                      DateTime.now().add(const Duration(days: 90)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                );
                if (d != null) setState(() => _deadline = d);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.event_rounded, size: 20),
                  suffixIcon: _deadline != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _deadline = null),
                        )
                      : const Icon(Icons.keyboard_arrow_down_rounded),
                ),
                child: Text(
                  _deadline == null
                      ? 'No deadline'
                      : formatDateFull(_deadline!),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _deadline == null
                        ? Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.45)
                        : null,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text(isEdit ? 'Save' : 'Create goal'),
          ),
        ),
      ),
    );
  }
}

class GoalDetailScreen extends StatelessWidget {
  final String goalId;

  const GoalDetailScreen({super.key, required this.goalId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final goal = state.goalById(goalId);
    if (goal == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Goal not found')),
      );
    }
    final color = goalColor(goal.iconId);
    final contribs = state.contributionsForGoal(goalId);
    final saved = state.savedForGoal(goal);
    final pot = state.accountById(goal.savingsAccountId);
    final progress = goal.progressOf(saved);
    final remaining = goal.remainingOf(saved);
    final done = goal.isCompleteWith(saved);

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GoalFormScreen(goal: goal)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete goal?'),
                  content: const Text('Progress history will be removed.'),
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
                await state.deleteGoal(goalId);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_goal_add',
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          builder: (ctx) => Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: _ContributeSheet(goal: goal),
          ),
        ),
        icon: const Icon(Icons.south_west_rounded),
        label: const Text('Move to pot'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: color.withValues(alpha: 0.12),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                Icon(goalIcon(goal.iconId), size: 40, color: color),
                const SizedBox(height: 10),
                Text(
                  formatPkr(saved),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                ),
                Text(
                  'of ${formatPkr(goal.targetAmount)} target',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  pot != null
                      ? 'In: ${pot.name}'
                      : 'Link a savings account on first deposit',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: color.withValues(alpha: 0.15),
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  done
                      ? 'Goal reached!'
                      : '${(progress * 100).toStringAsFixed(0)}% · '
                          '${formatPkr(remaining)} left'
                          '${goal.daysLeft != null ? ' · ${goal.daysLeft} days' : ''}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    showDragHandle: true,
                    builder: (ctx) => Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(ctx).viewInsets.bottom,
                      ),
                      child: _ContributeSheet(goal: goal),
                    ),
                  ),
                  icon: const Icon(Icons.south_west_rounded),
                  label: const Text('Deposit'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: saved <= 0
                      ? null
                      : () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            showDragHandle: true,
                            builder: (ctx) => Padding(
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                              ),
                              child: _WithdrawSheet(goal: goal),
                            ),
                          ),
                  icon: const Icon(Icons.north_east_rounded),
                  label: const Text('Withdraw'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Deposit cuts money from Cash/HBL and puts it in a savings account '
            '(UBL Savings etc.). Main accounts stay separate.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
          ),
          if (goal.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('Notes'),
                subtitle: Text(goal.notes),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'History',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          if (contribs.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No moves yet. Tap Deposit to put money in this pot.',
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
            ...contribs.map(
              (c) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: (c.isDeposit ? color : AppColors.expense)
                        .withValues(alpha: 0.15),
                    child: Icon(
                      c.isDeposit
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      color: c.isDeposit ? color : AppColors.expense,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    '${c.isDeposit ? '+' : '−'}${formatPkr(c.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: c.isDeposit ? color : AppColors.expense,
                    ),
                  ),
                  subtitle: Text(
                    [
                      c.isDeposit ? 'Deposit' : 'Withdraw',
                      formatDate(c.date),
                      if (c.note.isNotEmpty) c.note,
                    ].join(' · '),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContributeSheet extends StatefulWidget {
  final SavingsGoal goal;

  const _ContributeSheet({required this.goal});

  @override
  State<_ContributeSheet> createState() => _ContributeSheetState();
}

class _ContributeSheetState extends State<_ContributeSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _newSavNameCtrl = TextEditingController();
  String _fromId = '';
  String _savingsId = '';
  /// 0 = pick existing, 1 = create new
  int _linkMode = 0;
  /// When true, show link/create UI even if goal already has a savings account.
  bool _editingSavings = false;

  @override
  void initState() {
    super.initState();
    _savingsId = widget.goal.savingsAccountId;
    _newSavNameCtrl.text = '${widget.goal.name} savings';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.read<AppState>();
    if (_fromId.isEmpty) {
      final spendable = state.spendableAccounts;
      _fromId = spendable.isNotEmpty
          ? spendable.first.id
          : state.defaultAccountId;
    }
    if (_savingsId.isEmpty && state.goalSavingsAccounts.isNotEmpty) {
      _savingsId = state.goalSavingsAccounts.first.id;
    }
    if (_savingsId.isEmpty) _linkMode = 1;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _newSavNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _ensureSavingsLinked(AppState state) async {
    final goal = state.goalById(widget.goal.id) ?? widget.goal;
    var savingsId = goal.savingsAccountId;
    final needsLink = _editingSavings ||
        savingsId.isEmpty ||
        state.accountById(savingsId) == null;
    if (!needsLink) return;

    if (_linkMode == 1) {
      final name = _newSavNameCtrl.text.trim();
      if (name.isEmpty) {
        throw StateError('Enter savings account name');
      }
      await state.createSavingsAccountForGoal(
        goalId: widget.goal.id,
        name: name,
        presetId: 'goal_savings',
      );
    } else {
      if (_savingsId.isEmpty) {
        throw StateError('Select a savings account');
      }
      await state.linkGoalSavingsAccount(
        goalId: widget.goal.id,
        savingsAccountId: _savingsId,
      );
    }
  }

  Future<void> _save() async {
    final amount = parseAmount(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter amount to deposit')),
      );
      return;
    }
    final state = context.read<AppState>();
    final fromBal = state.balanceFor(_fromId);
    if (amount > fromBal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not enough balance (has ${formatPkr(fromBal)})'),
        ),
      );
      return;
    }

    try {
      await _ensureSavingsLinked(state);
      final goal = state.goalById(widget.goal.id) ?? widget.goal;
      final savingsId = goal.savingsAccountId;

      await state.contributeToGoal(
        goalId: widget.goal.id,
        amount: amount,
        accountId: _fromId,
        note: _noteCtrl.text.trim(),
      );
      if (!mounted) return;
      final savName = state.accountById(savingsId)?.name ?? 'savings';
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cut ${formatPkr(amount)} from main → $savName',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is StateError ? e.message : 'Could not deposit: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final goal = state.goalById(widget.goal.id) ?? widget.goal;
    final saved = state.savedForGoal(goal);
    final hasLink = goal.savingsAccountId.isNotEmpty &&
        state.accountById(goal.savingsAccountId) != null;
    final linked = hasLink ? state.accountById(goal.savingsAccountId) : null;
    final savingsList = state.goalSavingsAccounts;
    final showLinkedCard = hasLink && linked != null && !_editingSavings;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Deposit · ${goal.name}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Money is cut from cash/bank and moved into a savings account '
            '(like UBL Savings) — not mixed with main accounts.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [AmountInputFormatter()],
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            decoration: const InputDecoration(
              prefixText: 'Rs  ',
              labelText: 'Amount',
            ),
          ),
          const SizedBox(height: 14),
          AccountPicker(
            accounts: state.spendableAccounts,
            selectedId: _fromId.isEmpty ? null : _fromId,
            balances: {
              for (final a in state.spendableAccounts)
                a.id: state.balanceFor(a.id),
            },
            onSelected: (id) => setState(() => _fromId = id),
            label: 'Cut from (cash / bank / wallet)',
          ),
          const SizedBox(height: 16),
          Text(
            'Savings account (destination)',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          if (showLinkedCard)
            Card(
              child: ListTile(
                title: Text(
                  linked.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'In savings ${formatPkr(saved)} · linked to this goal',
                ),
                trailing: TextButton(
                  onPressed: () => setState(() {
                    _editingSavings = true;
                    _savingsId = goal.savingsAccountId;
                    _linkMode = savingsList.length > 1 ? 0 : 1;
                  }),
                  child: const Text('Change'),
                ),
              ),
            )
          else ...[
            if (hasLink)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _editingSavings = false),
                  child: const Text('Cancel'),
                ),
              ),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Link existing')),
                ButtonSegment(value: 1, label: Text('Create new')),
              ],
              selected: {_linkMode},
              onSelectionChanged: (s) => setState(() => _linkMode = s.first),
            ),
            const SizedBox(height: 12),
            if (_linkMode == 0) ...[
              if (savingsList.isEmpty)
                Text(
                  'No savings accounts yet. Create one (e.g. UBL Savings).',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                )
              else
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _savingsId.isEmpty ||
                          !savingsList.any((a) => a.id == _savingsId)
                      ? null
                      : _savingsId,
                  decoration: const InputDecoration(
                    labelText: 'Savings account',
                    prefixIcon: Icon(Icons.account_balance_outlined),
                  ),
                  hint: const Text('Select UBL / HBL savings…'),
                  items: savingsList
                      .map(
                        (a) => DropdownMenuItem(
                          value: a.id,
                          child: Text(
                            '${a.name} · ${formatPkr(state.balanceFor(a.id), compact: true)}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _savingsId = v ?? ''),
                ),
            ] else ...[
              TextField(
                controller: _newSavNameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'New savings account name',
                  hintText: 'e.g. UBL Savings · Trip',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                  helperText: 'Separate from Cash / HBL current accounts',
                ),
              ),
            ],
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Cut from main → savings'),
          ),
        ],
      ),
    );
  }
}

class _WithdrawSheet extends StatefulWidget {
  final SavingsGoal goal;

  const _WithdrawSheet({required this.goal});

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _toId = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_toId.isEmpty) {
      final spendable = context.read<AppState>().spendableAccounts;
      _toId = spendable.isNotEmpty
          ? spendable.first.id
          : context.read<AppState>().defaultAccountId;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = parseAmount(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter amount')),
      );
      return;
    }
    await context.read<AppState>().withdrawFromGoal(
          goalId: widget.goal.id,
          amount: amount,
          toAccountId: _toId,
          note: _noteCtrl.text.trim(),
        );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Moved ${formatPkr(amount)} back to spendable account',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final saved = state.savedForGoal(widget.goal);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Withdraw from ${widget.goal.name}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'In pot: ${formatPkr(saved)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [AmountInputFormatter()],
            decoration: InputDecoration(
              prefixText: 'Rs  ',
              labelText: 'Amount',
              helperText: 'Max ${formatPkr(saved)}',
            ),
          ),
          const SizedBox(height: 14),
          AccountPicker(
            accounts: state.spendableAccounts,
            selectedId: _toId.isEmpty ? null : _toId,
            balances: {
              for (final a in state.spendableAccounts)
                a.id: state.balanceFor(a.id),
            },
            onSelected: (id) => setState(() => _toId = id),
            label: 'To (cash / bank / wallet)',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Withdraw to account'),
          ),
        ],
      ),
    );
  }
}
