import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/account_presets.dart';
import '../models/account.dart';
import '../providers/app_state.dart';
import '../utils/amount_input.dart';
import '../utils/formatters.dart';
import '../widgets/app_select.dart';
import '../widgets/bank_logo.dart';

/// Polished transfer UI (bottom sheet, not a cramped dialog).
Future<void> showTransferSheet(BuildContext context) async {
  final state = context.read<AppState>();
  final accounts = state.activeAccounts;
  if (accounts.length < 2) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add at least two accounts to transfer')),
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: _TransferForm(accounts: accounts),
    ),
  );
}

class _TransferForm extends StatefulWidget {
  final List<MoneyAccount> accounts;

  const _TransferForm({required this.accounts});

  @override
  State<_TransferForm> createState() => _TransferFormState();
}

class _TransferFormState extends State<_TransferForm> {
  late String _fromId;
  late String _toId;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fromId = widget.accounts.first.id;
    _toId = widget.accounts[1].id;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  List<AppSelectOption<String>> _options() {
    final state = context.read<AppState>();
    return widget.accounts.map((a) {
      final preset = presetById(a.presetId.isEmpty ? 'cash' : a.presetId);
      final bal = state.balanceFor(a.id);
      return AppSelectOption(
        value: a.id,
        label: a.name,
        subtitle: '${typeLabel(a.type)} · ${formatPkr(bal)}',
        icon: a.presetId.isNotEmpty ? preset.icon : typeIcon(a.type),
        color: preset.color,
        leading: BankLogo.fromAccount(a, size: 40, radius: 10),
      );
    }).toList();
  }

  Future<void> _submit() async {
    final amount = parseAmount(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    if (_fromId == _toId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose two different accounts')),
      );
      return;
    }

    await context.read<AppState>().addTransfer(
          AccountTransfer(
            id: AppState.newId(),
            fromAccountId: _fromId,
            toAccountId: _toId,
            amount: amount,
            date: DateTime.now(),
            notes: _noteCtrl.text.trim(),
          ),
        );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transferred ${formatPkr(amount)}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final opts = _options();
    final state = context.watch<AppState>();
    final fromBal = state.balanceFor(_fromId);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Transfer',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Move money between your accounts',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                ),
          ),
          const SizedBox(height: 20),
          AppSelectField<String>(
            label: 'From',
            value: _fromId,
            options: opts,
            searchHint: 'Search account…',
            onChanged: (v) => setState(() {
              _fromId = v;
              if (_toId == _fromId) {
                final other = widget.accounts.firstWhere((a) => a.id != v);
                _toId = other.id;
              }
            }),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Available ${formatPkr(fromBal)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: IconButton.filledTonal(
              tooltip: 'Swap',
              onPressed: () => setState(() {
                final t = _fromId;
                _fromId = _toId;
                _toId = t;
              }),
              icon: const Icon(Icons.swap_vert_rounded),
            ),
          ),
          const SizedBox(height: 8),
          AppSelectField<String>(
            label: 'To',
            value: _toId,
            options: opts,
            searchHint: 'Search account…',
            onChanged: (v) => setState(() => _toId = v),
          ),
          const SizedBox(height: 16),
          Text(
            'Amount',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
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
              hintText: '0',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Note (optional)',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'e.g. Load EasyPaisa',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Transfer',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
