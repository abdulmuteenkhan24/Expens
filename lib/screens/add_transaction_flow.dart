import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/categories.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/amount_input.dart';
import '../utils/formatters.dart';
import '../widgets/bank_logo.dart';
import '../widgets/receipt_picker.dart';
import '../widgets/tag_picker.dart';
import 'atm_sheet.dart';
import 'loan_form_screen.dart';
import 'sms_import_screen.dart';
import 'transfer_sheet.dart';

enum AddTxType { expense, income, transfer, people }

/// Multi-step add: Type → Amount → Category → Account → Details → Finish
class AddTransactionFlow extends StatefulWidget {
  final AddTxType initialType;
  final String? initialCategoryId;
  final String? initialEventId;

  const AddTransactionFlow({
    super.key,
    this.initialType = AddTxType.expense,
    this.initialCategoryId,
    this.initialEventId,
  });

  @override
  State<AddTransactionFlow> createState() => _AddTransactionFlowState();
}

class _AddTransactionFlowState extends State<AddTransactionFlow> {
  int _step = 0;
  late AddTxType _type;
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  late String _categoryId;
  late String _accountId;
  DateTime _date = DateTime.now();
  String? _receiptPath;
  String _eventId = '';
  String _tag = '';
  bool _recurring = false;
  String _recurringRule = 'monthly';

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _categoryId = widget.initialCategoryId ?? expenseCategories.first.id;
    _accountId = '';
    _eventId = widget.initialEventId ?? '';
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
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_type == AddTxType.transfer) {
      Navigator.pop(context);
      await showTransferSheet(context);
      return;
    }
    if (_type == AddTxType.people) {
      Navigator.pop(context);
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoanFormScreen()),
      );
      return;
    }

    if (_step == 1) {
      final a = parseAmount(_amountCtrl.text);
      if (a == null || a <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter amount')),
        );
        return;
      }
    }
    if (_step < 4) {
      setState(() => _step++);
    } else {
      await _finish();
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.pop(context);
    } else {
      setState(() => _step--);
    }
  }

  Future<void> _finish() async {
    final amount = parseAmount(_amountCtrl.text);
    if (amount == null || amount <= 0) return;
    final state = context.read<AppState>();
    final accountId =
        _accountId.isEmpty ? state.defaultAccountId : _accountId;
    final title = _descCtrl.text.trim().isEmpty
        ? (_type == AddTxType.expense
            ? expenseCategoryById(_categoryId).name
            : incomeSourceById(_categoryId).name)
        : _descCtrl.text.trim();

    // ATM category = move bank money to Cash (not a spend).
    if (_type == AddTxType.expense && _categoryId == 'atm') {
      await state.recordAtmWithdrawal(
        amount: amount,
        fromAccountId: accountId,
        note: [
          if (_locationCtrl.text.trim().isNotEmpty) _locationCtrl.text.trim(),
          if (_descCtrl.text.trim().isNotEmpty) _descCtrl.text.trim(),
        ].join(' · '),
        date: _date,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ATM: ${formatPkr(amount)} moved to Cash')),
      );
      return;
    }

    if (_type == AddTxType.expense) {
      await state.addExpense(
        Expense(
          id: AppState.newId(),
          amount: amount,
          title: title,
          categoryId: _categoryId,
          accountId: accountId,
          currencyCode: state.currencyCode,
          date: _date,
          notes: '',
          receiptPath: _receiptPath ?? '',
          tag: _tag.trim(),
          location: _locationCtrl.text.trim(),
          eventId: _eventId,
          isRecurring: _recurring,
          recurringRule: _recurring ? _recurringRule : '',
        ),
      );
    } else {
      await state.addIncome(
        Income(
          id: AppState.newId(),
          amount: amount,
          title: title,
          sourceId: _categoryId,
          accountId: accountId,
          currencyCode: state.currencyCode,
          date: _date,
          receiptPath: _receiptPath ?? '',
          tag: _tag.trim(),
          location: _locationCtrl.text.trim(),
          eventId: _eventId,
          isRecurring: _recurring,
          recurringRule: _recurring ? _recurringRule : '',
        ),
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _type == AddTxType.expense ? 'Expense saved' : 'Income saved',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = ['Type', 'Amount', 'Category', 'Account', 'Details'];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _step < steps.length ? steps[_step] : 'Finish',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: (_step + 1) / 5,
            minHeight: 3,
            backgroundColor: Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.12),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(
          key: ValueKey(_step),
          child: _buildStep(),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              if (_step > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _back,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Back'),
                  ),
                ),
              if (_step > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _step == 4
                        ? 'Finish'
                        : _type == AddTxType.transfer ||
                                _type == AddTxType.people
                            ? 'Continue'
                            : 'Next',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      0 => _typeStep(),
      1 => _amountStep(),
      2 => _categoryStep(),
      3 => _accountStep(),
      _ => _detailsStep(),
    };
  }

  Widget _typeStep() {
    final items = [
      (
        AddTxType.expense,
        'Expense',
        Icons.remove_circle_outline,
        AppColors.expense,
      ),
      (
        AddTxType.income,
        'Income',
        Icons.add_circle_outline,
        AppColors.income,
      ),
      (
        AddTxType.transfer,
        'Transfer',
        Icons.swap_horiz_rounded,
        AppColors.loanLent,
      ),
      (
        AddTxType.people,
        'Loans / People',
        Icons.handshake_outlined,
        AppColors.loanBorrowed,
      ),
    ];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'What do you want to add?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Expense · Income · Transfer · Loans · ATM · Import SMS',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
              ),
        ),
        const SizedBox(height: 16),
        Material(
          color: const Color(0xFF5C6BC0).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            leading: const Icon(Icons.local_atm_rounded, color: Color(0xFF5C6BC0)),
            title: const Text(
              'ATM withdrawal',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text('Bank → Cash (balances update)'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () async {
              Navigator.pop(context);
              await showAtmSheet(context);
            },
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: const Color(0xFF7E57C2).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            leading: const Icon(
              Icons.content_paste_rounded,
              color: Color(0xFF7E57C2),
            ),
            title: const Text(
              'Import SMS',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text('Paste bank SMS from clipboard · edit · save'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SmsImportScreen()),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        ...items.map((item) {
          final selected = _type == item.$1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: selected
                  ? item.$4.withValues(alpha: 0.12)
                  : Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() {
                    _type = item.$1;
                    if (_type == AddTxType.income) {
                      _categoryId = incomeSources.first.id;
                    } else if (_type == AddTxType.expense) {
                      _categoryId = widget.initialCategoryId ??
                          expenseCategories.first.id;
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? item.$4
                          : Theme.of(context).dividerColor,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(item.$3, color: item.$4),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item.$2,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: selected ? item.$4 : null,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(Icons.check_circle_rounded, color: item.$4),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _amountStep() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Enter amount (PKR)',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _amountCtrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: const [AmountInputFormatter()],
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
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
      ],
    );
  }

  Widget _categoryStep() {
    final cats =
        _type == AddTxType.income ? incomeSources : expenseCategories;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          _type == AddTxType.income ? 'Income source' : 'Category',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.95,
          children: cats.map((c) {
            final selected = _categoryId == c.id;
            return Material(
              color: selected
                  ? c.color.withValues(alpha: 0.18)
                  : Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _categoryId = c.id),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? c.color : Theme.of(context).dividerColor,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(c.icon, color: c.color, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        c.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? c.color : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _accountStep() {
    final state = context.watch<AppState>();
    // Spendable first (not goal pots), then credit cards.
    final accounts = [
      ...state.spendableAccounts,
      ...state.creditCards,
    ];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Select account',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          _type == AddTxType.expense
              ? 'Cash/bank spends your money. Credit card adds to the bill you pay later.'
              : 'Choose where money goes',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
        ),
        const SizedBox(height: 16),
        ...accounts.map((a) {
          final selected = _accountId == a.id;
          final isCard = a.isCreditCard;
          final subtitle = isCard
              ? state.creditBalanceLabel(a.id)
              : formatPkr(state.balanceFor(a.id));
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: selected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                  : Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(14),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).dividerColor,
                  ),
                ),
                leading: BankLogo.fromAccount(a, size: 40, radius: 10),
                title: Text(
                  a.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  subtitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isCard
                        ? (state.creditOwed(a.id) > 0
                            ? AppColors.expense
                            : Theme.of(context).colorScheme.primary)
                        : null,
                  ),
                ),
                trailing: selected
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () => setState(() => _accountId = a.id),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _detailsStep() {
    final state = context.watch<AppState>();
    final events = state.events;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Additional details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Optional — you can finish anytime',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
        ),
        const SizedBox(height: 16),
        Text(
          'Description',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descCtrl,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'What was this for?'),
        ),
        const SizedBox(height: 14),
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
              final d = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (d != null) setState(() => _date = d);
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.event_rounded, size: 20),
              ),
              child: Text(formatDateFull(_date)),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TagPickerField(
          value: _tag,
          onChanged: (v) => setState(() => _tag = v),
        ),
        const SizedBox(height: 14),
        Text(
          'Location',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _locationCtrl,
          decoration: const InputDecoration(hintText: 'e.g. Islamabad'),
        ),
        const SizedBox(height: 14),
        Text(
          'Link to event (trip, wedding…)',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        if (events.isEmpty)
          Text(
            'No events yet. Create one from Money → Events.',
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
            value: _eventId.isEmpty ? null : _eventId,
            decoration: InputDecoration(
              hintText: 'None',
              prefixIcon: const Icon(Icons.event_rounded, size: 20),
              helperText: _eventId.isNotEmpty
                  ? 'Linked — shows in that event’s history'
                  : null,
            ),
            items: [
              const DropdownMenuItem(value: '', child: Text('None')),
              ...events.map(
                (e) => DropdownMenuItem(value: e.id, child: Text(e.name)),
              ),
            ],
            onChanged: (v) => setState(() => _eventId = v ?? ''),
          ),
        const SizedBox(height: 14),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Recurring transaction'),
          subtitle: const Text('Repeats every month'),
          value: _recurring,
          onChanged: (v) => setState(() => _recurring = v),
        ),
        if (_recurring)
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _recurringRule,
            decoration: const InputDecoration(labelText: 'Repeat'),
            items: const [
              DropdownMenuItem(value: 'daily', child: Text('Daily')),
              DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
              DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _recurringRule = v);
            },
          ),
        const SizedBox(height: 14),
        ReceiptPicker(
          path: _receiptPath,
          onChanged: (p) => setState(() => _receiptPath = p),
        ),
      ],
    );
  }
}
