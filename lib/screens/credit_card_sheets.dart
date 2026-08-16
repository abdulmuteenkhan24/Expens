import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/account.dart';
import '../providers/app_state.dart';
import '../utils/amount_input.dart';
import '../utils/formatters.dart';
import '../widgets/account_picker.dart';

/// Pay credit card bill from cash/bank/wallet.
Future<void> showPayCreditCardSheet(
  BuildContext context, {
  required String cardId,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _PayCardForm(cardId: cardId),
    ),
  );
}

class _PayCardForm extends StatefulWidget {
  final String cardId;

  const _PayCardForm({required this.cardId});

  @override
  State<_PayCardForm> createState() => _PayCardFormState();
}

class _PayCardFormState extends State<_PayCardForm> {
  final _amountCtrl = TextEditingController();
  String _fromId = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.read<AppState>();
    if (_fromId.isEmpty) {
      final assets = state.assetAccounts;
      _fromId = assets.isNotEmpty ? assets.first.id : state.defaultAccountId;
    }
    if (_amountCtrl.text.isEmpty) {
      final owed = state.creditOwed(widget.cardId);
      if (owed > 0) _amountCtrl.text = formatAmountInput(owed);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = parseAmount(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter amount')),
      );
      return;
    }
    if (_fromId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose account to pay from')),
      );
      return;
    }
    await context.read<AppState>().payCreditCard(
          cardId: widget.cardId,
          fromAccountId: _fromId,
          amount: amount,
        );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Paid ${formatPkr(amount)} toward card')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final card = state.accountById(widget.cardId);
    final owed = state.creditOwed(widget.cardId);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pay credit card',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            card == null
                ? 'Reduce what you owe'
                : '${card.name} · owe ${formatPkr(owed)}',
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
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            decoration: const InputDecoration(
              prefixText: 'Rs  ',
              labelText: 'Payment amount',
            ),
          ),
          const SizedBox(height: 14),
          AccountPicker(
            accounts: state.assetAccounts,
            selectedId: _fromId.isEmpty ? null : _fromId,
            balances: {
              for (final a in state.assetAccounts) a.id: state.balanceFor(a.id),
            },
            onSelected: (id) => setState(() => _fromId = id),
            label: 'Pay from',
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Pay bill'),
          ),
        ],
      ),
    );
  }
}

/// Create installment plan (laptop, phone, etc.).
Future<void> showAddInstallmentSheet(
  BuildContext context, {
  String? creditAccountId,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _InstallmentForm(creditAccountId: creditAccountId ?? ''),
    ),
  );
}

class _InstallmentForm extends StatefulWidget {
  final String creditAccountId;

  const _InstallmentForm({required this.creditAccountId});

  @override
  State<_InstallmentForm> createState() => _InstallmentFormState();
}

class _InstallmentFormState extends State<_InstallmentForm> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _shopCtrl = TextEditingController();
  final _monthsCtrl = TextEditingController(text: '6');
  late String _cardId;
  bool _onCard = true;

  @override
  void initState() {
    super.initState();
    _cardId = widget.creditAccountId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cards = context.read<AppState>().creditCards;
    if (_cardId.isEmpty && cards.isNotEmpty) {
      _cardId = cards.first.id;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _shopCtrl.dispose();
    _monthsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final amount = parseAmount(_amountCtrl.text);
    final months = int.tryParse(_monthsCtrl.text.trim()) ?? 0;
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter item name (e.g. Laptop)')),
      );
      return;
    }
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter total amount')),
      );
      return;
    }
    if (months < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter months (e.g. 6 or 12)')),
      );
      return;
    }

    final state = context.read<AppState>();
    await state.addInstallment(
      InstallmentPlan(
        id: AppState.newId(),
        title: title,
        totalAmount: amount,
        months: months,
        startDate: DateTime.now(),
        personOrShop: _shopCtrl.text.trim(),
        creditAccountId: _onCard ? _cardId : '',
      ),
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Installment plan · ${formatPkr(amount / months)} / month × $months',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cards = state.creditCards;
    final months = int.tryParse(_monthsCtrl.text.trim()) ?? 0;
    final total = parseAmount(_amountCtrl.text) ?? 0;
    final monthly = months > 0 && total > 0 ? total / months : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'New installment',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Laptop, phone, bike — pay over months',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'What did you buy?',
              hintText: 'e.g. Laptop, iPhone, Bike',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [AmountInputFormatter()],
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Total price',
              prefixText: 'Rs  ',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _monthsCtrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Months',
              hintText: '6, 12, 24…',
            ),
          ),
          if (monthly > 0) ...[
            const SizedBox(height: 8),
            Text(
              '≈ ${formatPkr(monthly)} per month',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _shopCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Shop / person (optional)',
              hintText: 'e.g. Daraz, Ali, Outlet',
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Linked to credit card'),
            subtitle: const Text(
              'Monthly pay can reduce card debt when you pay',
            ),
            value: _onCard && cards.isNotEmpty,
            onChanged: cards.isEmpty
                ? null
                : (v) => setState(() => _onCard = v),
          ),
          if (_onCard && cards.isNotEmpty) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _cardId.isEmpty ? cards.first.id : _cardId,
              decoration: const InputDecoration(labelText: 'Credit card'),
              items: cards
                  .map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _cardId = v ?? ''),
            ),
          ],
          if (cards.isEmpty)
            Text(
              'Tip: add a Credit card account to track installments against it.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Save plan'),
          ),
        ],
      ),
    );
  }
}

Future<void> showPayInstallmentSheet(
  BuildContext context,
  InstallmentPlan plan,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _PayInstallmentForm(plan: plan),
    ),
  );
}

class _PayInstallmentForm extends StatefulWidget {
  final InstallmentPlan plan;

  const _PayInstallmentForm({required this.plan});

  @override
  State<_PayInstallmentForm> createState() => _PayInstallmentFormState();
}

class _PayInstallmentFormState extends State<_PayInstallmentForm> {
  late final TextEditingController _amountCtrl;
  String _fromId = '';
  bool _viaCard = true;

  @override
  void initState() {
    super.initState();
    final m = widget.plan.monthlyAmount;
    final pay = m > widget.plan.remaining ? widget.plan.remaining : m;
    _amountCtrl = TextEditingController(text: formatAmountInput(pay));
    _viaCard = widget.plan.creditAccountId.isNotEmpty;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_fromId.isEmpty) {
      _fromId = context.read<AppState>().defaultAccountId;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = parseAmount(_amountCtrl.text);
    if (amount == null || amount <= 0) return;
    await context.read<AppState>().payInstallment(
          planId: widget.plan.id,
          amount: amount,
          fromAccountId: _fromId,
          affectCard: _viaCard && widget.plan.creditAccountId.isNotEmpty,
        );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Installment paid · ${formatPkr(amount)}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final plan = widget.plan;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pay installment',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '${plan.title} · remaining ${formatPkr(plan.remaining)}',
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [AmountInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: 'Rs  ',
            ),
          ),
          const SizedBox(height: 12),
          AccountPicker(
            accounts: state.assetAccounts,
            selectedId: _fromId.isEmpty ? null : _fromId,
            balances: {
              for (final a in state.assetAccounts) a.id: state.balanceFor(a.id),
            },
            onSelected: (id) => setState(() => _fromId = id),
            label: 'Pay from',
          ),
          if (plan.creditAccountId.isNotEmpty)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Apply to credit card debt'),
              subtitle: const Text('Cash → card (reduces card bill)'),
              value: _viaCard,
              onChanged: (v) => setState(() => _viaCard = v),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Pay'),
          ),
        ],
      ),
    );
  }
}
