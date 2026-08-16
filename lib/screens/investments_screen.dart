import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/categories.dart';
import '../models/investment.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/amount_input.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';

class InvestmentsScreen extends StatelessWidget {
  const InvestmentsScreen({super.key});

  void _openForm(BuildContext context, {Investment? inv}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InvestmentFormScreen(investment: inv)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final list = state.investments;
    final gainColor =
        state.investmentGain >= 0 ? AppColors.income : AppColors.expense;

    return Scaffold(
      appBar: AppBar(title: const Text('Investments')),
      body: Column(
        children: [
          if (list.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.income.withValues(alpha: 0.1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Portfolio value',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                    Text(
                      formatPkr(state.investmentValue),
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.income,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Invested ${formatPkr(state.investedTotal)} · Gain ${formatPkr(state.investmentGain)}',
                      style: TextStyle(
                        color: gainColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: list.isEmpty
                ? EmptyState(
                    icon: Icons.trending_up_rounded,
                    title: 'No investments yet',
                    subtitle:
                        'Track stocks, funds, gold, crypto, and savings in one place.',
                    actionLabel: 'Add investment',
                    onAction: () => _openForm(context),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final inv = list[i];
                      final type = investmentTypeById(inv.typeId);
                      final gainColor =
                          inv.gain >= 0 ? AppColors.income : AppColors.expense;
                      return Card(
                        child: ListTile(
                          onTap: () => _openForm(context, inv: inv),
                          leading: CircleAvatar(
                            backgroundColor: type.color.withValues(alpha: 0.15),
                            child: Icon(type.icon, color: type.color, size: 18),
                          ),
                          title: Text(
                            inv.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${type.name} · ${formatDate(inv.date)}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatPkr(inv.currentValue),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${inv.gain >= 0 ? '+' : ''}${formatPkr(inv.gain)}',
                                style: TextStyle(
                                  color: gainColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_investments',
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class InvestmentFormScreen extends StatefulWidget {
  final Investment? investment;

  const InvestmentFormScreen({super.key, this.investment});

  @override
  State<InvestmentFormScreen> createState() => _InvestmentFormScreenState();
}

class _InvestmentFormScreenState extends State<InvestmentFormScreen> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  late String _typeId;

  bool get isEdit => widget.investment != null;

  @override
  void initState() {
    super.initState();
    final e = widget.investment;
    if (e != null) {
      _nameCtrl.text = e.name;
      _amountCtrl.text = formatAmountInput(e.amount);
      _valueCtrl.text = formatAmountInput(e.currentValue);
      _typeId = e.typeId;
    } else {
      _typeId = investmentTypes.first.id;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = parseAmount(_amountCtrl.text);
    final value = parseAmount(_valueCtrl.text);
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a name')),
      );
      return;
    }
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter invested amount')),
      );
      return;
    }

    final state = context.read<AppState>();
    final inv = Investment(
      id: isEdit ? widget.investment!.id : AppState.newId(),
      name: _nameCtrl.text.trim(),
      typeId: _typeId,
      amount: amount,
      currentValue: value ?? amount,
      date: isEdit ? widget.investment!.date : DateTime.now(),
    );

    if (isEdit) {
      await state.updateInvestment(inv);
    } else {
      await state.addInvestment(inv);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit investment' : 'Add investment'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await context
                    .read<AppState>()
                    .deleteInvestment(widget.investment!.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. HBL stock, Meezan fund',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Type',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: investmentTypes.map((t) {
              final selected = _typeId == t.id;
              return ChoiceChip(
                avatar: Icon(t.icon, size: 16, color: t.color),
                label: Text(t.name),
                selected: selected,
                onSelected: (_) => setState(() => _typeId = t.id),
                selectedColor: t.color.withValues(alpha: 0.2),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [AmountInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'Amount invested (Rs)',
              prefixText: 'Rs  ',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _valueCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [AmountInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'Current value (Rs)',
              prefixText: 'Rs  ',
              helperText: 'Leave empty to use invested amount',
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
            child: Text(isEdit ? 'Save' : 'Add'),
          ),
        ),
      ),
    );
  }
}
