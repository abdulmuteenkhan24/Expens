import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/loan.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/amount_input.dart';
import '../utils/formatters.dart';
import '../widgets/account_picker.dart';
import '../widgets/app_select.dart';

class LoanFormScreen extends StatefulWidget {
  final Loan? loan;

  const LoanFormScreen({super.key, this.loan});

  @override
  State<LoanFormScreen> createState() => _LoanFormScreenState();
}

class _LoanFormScreenState extends State<LoanFormScreen> {
  final _amountCtrl = TextEditingController();
  final _personCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  late LoanDirection _direction;
  late String _accountId;
  DateTime _date = DateTime.now();
  DateTime? _dueDate;
  bool _affectBalance = true;

  bool get isEdit => widget.loan != null;

  @override
  void initState() {
    super.initState();
    final e = widget.loan;
    if (e != null) {
      _amountCtrl.text = formatAmountInput(e.amount);
      _personCtrl.text = e.personName;
      _purposeCtrl.text = e.purpose;
      _direction = e.direction;
      _accountId = e.accountId;
      _date = e.date;
      _dueDate = e.dueDate;
      _affectBalance = false; // already linked when created
    } else {
      _direction = LoanDirection.borrowed;
      _accountId = '';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_accountId.isEmpty) {
      _accountId = context.read<AppState>().defaultAccountId;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _personCtrl.dispose();
    _purposeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = parseAmount(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    if (_personCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a name')),
      );
      return;
    }

    final state = context.read<AppState>();
    final name = _personCtrl.text.trim();
    final purpose = _purposeCtrl.text.trim();
    final accountId =
        _accountId.isEmpty ? state.defaultAccountId : _accountId;

    if (isEdit) {
      final old = widget.loan!;
      final paid = old.paidAmount.clamp(0.0, amount);
      final status = paid >= amount
          ? LoanStatus.settled
          : paid > 0
              ? LoanStatus.partial
              : LoanStatus.pending;
      await state.updateLoan(
        old.copyWith(
          amount: amount,
          paidAmount: paid,
          personName: name,
          direction: _direction,
          status: status,
          date: _date,
          purpose: purpose,
          dueDate: _dueDate,
          clearDueDate: _dueDate == null,
          accountId: accountId,
        ),
      );
    } else {
      await state.createLoan(
        loan: Loan(
          id: AppState.newId(),
          amount: amount,
          personName: name,
          direction: _direction,
          date: _date,
          dueDate: _dueDate,
          purpose: purpose,
          accountId: accountId,
        ),
        accountId: accountId,
        affectBalance: _affectBalance,
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
    final msg = isEdit
        ? 'Loan updated'
        : _direction == LoanDirection.borrowed
            ? 'Borrowed Rs ${amount.toStringAsFixed(0)} — money added to account. Remember to repay.'
            : 'Lent Rs ${amount.toStringAsFixed(0)} — money left your account.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isBorrow = _direction == LoanDirection.borrowed;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit loan' : 'New loan'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          AppSegmentedType<LoanDirection>(
            selected: _direction,
            onChanged: isEdit
                ? (_) {}
                : (d) => setState(() => _direction = d),
            items: const [
              (
                value: LoanDirection.borrowed,
                label: 'I borrowed',
                icon: Icons.south_west_rounded,
              ),
              (
                value: LoanDirection.lent,
                label: 'I lent',
                icon: Icons.north_east_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: (isBorrow ? AppColors.loanBorrowed : AppColors.loanLent)
                  .withValues(alpha: 0.12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isBorrow ? Icons.info_outline : Icons.info_outline,
                  color: isBorrow
                      ? AppColors.loanBorrowed
                      : AppColors.loanLent,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isBorrow
                        ? 'You receive money now (counts as income in the selected account) and must pay it back later.'
                        : 'Money leaves your account now (counts as expense). They owe you and should repay later.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.35,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _amountCtrl,
            autofocus: !isEdit,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [AmountInputFormatter()],
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            decoration: const InputDecoration(
              prefixText: 'Rs  ',
              hintText: '0',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isBorrow ? 'Borrowed from' : 'Lent to',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _personCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Person name',
            ),
          ),
          const SizedBox(height: 16),
          AccountPicker(
            accounts: state.activeAccounts,
            selectedId:
                _accountId.isEmpty ? state.defaultAccountId : _accountId,
            balances: state.allAccountBalances,
            onSelected: (id) => setState(() => _accountId = id),
            label: isBorrow ? 'Money goes into' : 'Money leaves from',
          ),
          if (!isEdit) ...[
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                isBorrow
                    ? 'Add to account balance'
                    : 'Deduct from account balance',
              ),
              subtitle: Text(
                isBorrow
                    ? 'Creates income so you can spend this money'
                    : 'Creates expense when you give them money',
              ),
              value: _affectBalance,
              onChanged: (v) => setState(() => _affectBalance = v),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Purpose (optional)',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _purposeCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'e.g. bike repair, fees, emergency',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isBorrow ? 'Date you took the loan' : 'Date you gave the loan',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            isBorrow
                ? 'When you received this money'
                : 'When you lent them the money',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
          ),
          const SizedBox(height: 8),
          Material(
            color: Theme.of(context).inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2015),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                  helpText: isBorrow ? 'Date taken' : 'Date given',
                );
                if (picked != null) {
                  setState(() {
                    _date = picked;
                    // Keep due date after loan date if both set.
                    if (_dueDate != null && _dueDate!.isBefore(picked)) {
                      _dueDate = null;
                    }
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today_rounded, size: 20),
                  suffixIcon: Icon(Icons.keyboard_arrow_down_rounded),
                ),
                child: Text(
                  formatDateFull(_date),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Due date (optional)',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'When you should finish repaying / collecting',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
          ),
          const SizedBox(height: 8),
          Material(
            color: Theme.of(context).inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ??
                      _date.add(const Duration(days: 30)),
                  firstDate: _date,
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  helpText: 'Due date',
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.event_rounded, size: 20),
                  suffixIcon: _dueDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _dueDate = null),
                        )
                      : const Icon(Icons.keyboard_arrow_down_rounded),
                ),
                child: Text(
                  _dueDate == null
                      ? 'No due date'
                      : formatDateFull(_dueDate!),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _dueDate == null
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
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              isEdit
                  ? 'Save'
                  : isBorrow
                      ? 'Borrow & add money'
                      : 'Lend & deduct money',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
