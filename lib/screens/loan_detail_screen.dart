import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/loan.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/amount_input.dart';
import '../utils/formatters.dart';
import '../widgets/account_picker.dart';
import '../widgets/app_select.dart';
import 'loan_form_screen.dart';

class LoanDetailScreen extends StatelessWidget {
  final String loanId;

  const LoanDetailScreen({super.key, required this.loanId});

  Future<void> _recordPayment(BuildContext context, Loan loan) async {
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
        child: _PaymentSheet(loan: loan),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final loan = state.loanById(loanId);
    if (loan == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Loan not found')),
      );
    }

    final isLent = loan.direction == LoanDirection.lent;
    final color = isLent ? AppColors.loanLent : AppColors.loanBorrowed;
    final payments = state.paymentsForLoan(loan.id);
    final accountName = state.accountById(loan.accountId)?.name;

    return Scaffold(
      appBar: AppBar(
        title: Text(loan.personName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LoanFormScreen(loan: loan),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete loan?'),
                  content: const Text(
                    'Payment history for this loan will be removed. '
                    'Linked income/expense entries stay in Track.',
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
                await state.deleteLoan(loan.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.9),
                  color.withValues(alpha: 0.65),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLent ? 'They owe you' : 'You must repay',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatPkr(loan.remaining),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  loan.isSettled
                      ? 'Fully settled'
                      : 'of ${formatPkr(loan.amount)} total · paid ${formatPkr(loan.paidAmount)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: loan.progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(loan.progress * 100).toStringAsFixed(0)}% paid',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _infoRow(
                    context,
                    'Type',
                    isLent ? 'Lent (they repay you)' : 'Borrowed (you repay)',
                  ),
                  _infoRow(context, 'Person', loan.personName),
                  if (loan.purpose.isNotEmpty)
                    _infoRow(context, 'Purpose', loan.purpose),
                  _infoRow(
                    context,
                    isLent ? 'Date given' : 'Date taken',
                    formatDateFull(loan.date),
                  ),
                  if (loan.dueDate != null)
                    _infoRow(
                      context,
                      'Due date',
                      formatDateFull(loan.dueDate!),
                      valueColor: loan.isOverdue ? AppColors.expense : null,
                    ),
                  if (accountName != null)
                    _infoRow(
                      context,
                      isLent ? 'Paid from' : 'Received in',
                      accountName,
                    ),
                  _infoRow(
                    context,
                    'Status',
                    loan.isSettled
                        ? 'Settled'
                        : loan.paidAmount > 0
                            ? 'Partial'
                            : 'Pending',
                  ),
                ],
              ),
            ),
          ),
          if (!isLent && !loan.isSettled) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.loanBorrowed.withValues(alpha: 0.12),
              ),
              child: Text(
                'Reminder: You borrowed ${formatPkr(loan.amount)} from ${loan.personName}. '
                'Pay back installments until remaining is zero.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
          if (isLent && !loan.isSettled) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.loanLent.withValues(alpha: 0.12),
              ),
              child: Text(
                'You lent ${formatPkr(loan.amount)} to ${loan.personName}. '
                'Record each amount they return.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                'Payment history',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              Text(
                '${payments.length}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.45),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (payments.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  isLent
                      ? 'No payments received yet.'
                      : 'No repayments recorded yet.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
              ),
            )
          else
            ...payments.map((p) {
              final acc = state.accountById(p.accountId)?.name;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(
                      isLent
                          ? Icons.call_received_rounded
                          : Icons.call_made_rounded,
                      color: color,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    formatPkr(p.amount),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    [
                      formatDate(p.date),
                      p.method,
                      ?acc,
                      if (p.note.isNotEmpty) p.note,
                    ].join(' · '),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete payment?'),
                          content: const Text(
                            'This also removes the linked income/expense if present.',
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
                        await state.deleteLoanPayment(p.id);
                      }
                    },
                  ),
                ),
              );
            }),
        ],
      ),
      floatingActionButton: loan.isSettled
          ? null
          : FloatingActionButton.extended(
              heroTag: 'fab_loan_detail',
              onPressed: () => _recordPayment(context, loan),
              icon: const Icon(Icons.payments_rounded),
              label: Text(isLent ? 'Received' : 'Repay'),
            ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                  ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentSheet extends StatefulWidget {
  final Loan loan;

  const _PaymentSheet({required this.loan});

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  late final TextEditingController _amountCtrl;
  final _noteCtrl = TextEditingController();
  late String _accountId;
  String _method = loanPaymentMethods.first;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: formatAmountInput(widget.loan.remaining),
    );
    _accountId = widget.loan.accountId;
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
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = parseAmount(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    final state = context.read<AppState>();
    final accountId =
        _accountId.isEmpty ? state.defaultAccountId : _accountId;
    final isLent = widget.loan.direction == LoanDirection.lent;

    await state.recordLoanPayment(
      loanId: widget.loan.id,
      amount: amount,
      accountId: accountId,
      date: _date,
      method: _method,
      note: _noteCtrl.text.trim(),
    );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isLent
              ? 'Received ${formatPkr(amount)} — added to account'
              : 'Paid ${formatPkr(amount)} — deducted from account',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isLent = widget.loan.direction == LoanDirection.lent;
    final remaining = widget.loan.remaining;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isLent ? 'Record received' : 'Record repayment',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            isLent
                ? '${widget.loan.personName} paid you back. Money goes into your account.'
                : 'You pay ${widget.loan.personName}. Money leaves your account.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Remaining ${formatPkr(remaining)}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isLent ? AppColors.loanLent : AppColors.loanBorrowed,
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
              hintText: '0',
            ),
          ),
          const SizedBox(height: 16),
          AccountPicker(
            accounts: state.activeAccounts,
            selectedId:
                _accountId.isEmpty ? state.defaultAccountId : _accountId,
            balances: state.allAccountBalances,
            onSelected: (id) => setState(() => _accountId = id),
            label: isLent ? 'Receive into' : 'Pay from',
          ),
          const SizedBox(height: 16),
          AppSelectField<String>(
            label: 'Method',
            value: _method,
            searchable: false,
            options: loanPaymentMethods
                .map(
                  (m) => AppSelectOption(
                    value: m,
                    label: m,
                    icon: Icons.payments_outlined,
                  ),
                )
                .toList(),
            onChanged: (m) => setState(() => _method = m),
          ),
          const SizedBox(height: 16),
          Text(
            'Date',
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
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.event_rounded, size: 20),
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
            'Note (optional)',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              hintText: 'e.g. First installment',
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
            child: Text(
              isLent ? 'Save received payment' : 'Save repayment',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
