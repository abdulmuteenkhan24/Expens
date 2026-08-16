import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/account_presets.dart';
import '../models/account.dart';
import '../providers/app_state.dart';
import '../utils/amount_input.dart';
import '../utils/formatters.dart';
import '../widgets/app_select.dart';
import '../widgets/bank_logo.dart';

/// ATM = take cash from bank → Cash account (not an expense).
Future<void> showAtmSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: const _AtmForm(),
    ),
  );
}

class _AtmForm extends StatefulWidget {
  const _AtmForm();

  @override
  State<_AtmForm> createState() => _AtmFormState();
}

class _AtmFormState extends State<_AtmForm> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _fromId;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
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
    final state = context.read<AppState>();
    final fromId = _fromId;
    if (fromId == null || fromId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select bank / wallet account')),
      );
      return;
    }

    await state.recordAtmWithdrawal(
      amount: amount,
      fromAccountId: fromId,
      note: _noteCtrl.text.trim(),
    );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'ATM: ${formatPkr(amount)} moved to Cash',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    // From: bank/wallet/card (not cash)
    final fromAccounts = state.activeAccounts
        .where((a) => a.type != AccountType.cash)
        .toList();
    if (fromAccounts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add a bank or wallet account first, then use ATM to move money into Cash.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    _fromId ??= fromAccounts.first.id;

    final options = fromAccounts.map((a) {
      final preset = presetById(a.presetId.isEmpty ? 'hbl' : a.presetId);
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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ATM withdrawal',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Cash comes out of your bank/wallet and goes into your Cash account. '
            'Total money stays the same — only the form changes.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 20),
          AppSelectField<String>(
            label: 'From account (bank / wallet)',
            value: _fromId,
            options: options,
            searchHint: 'Search account…',
            onChanged: (v) => setState(() => _fromId = v),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.payments_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'To: Cash account (created if missing)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
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
            decoration: const InputDecoration(
              hintText: 'e.g. MAIN ATM',
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
              'Withdraw to Cash',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
