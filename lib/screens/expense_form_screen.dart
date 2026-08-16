import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/categories.dart';
import '../data/currencies.dart';
import '../models/expense.dart';
import '../providers/app_state.dart';
import '../utils/amount_input.dart';
import '../utils/formatters.dart';
import '../widgets/account_picker.dart';
import '../widgets/app_select.dart';
import '../widgets/receipt_picker.dart';

class ExpenseFormScreen extends StatefulWidget {
  final Expense? expense;

  const ExpenseFormScreen({super.key, this.expense});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _amountCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  late String _categoryId;
  late String _accountId;
  late String _currencyCode;
  late DateTime _date;
  String? _receiptPath;

  bool get isEdit => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    if (e != null) {
      _amountCtrl.text = formatAmountInput(e.amount);
      _titleCtrl.text = e.title;
      _categoryId = e.categoryId;
      _accountId = e.accountId;
      _currencyCode = e.currencyCode;
      _date = e.date;
      _receiptPath = e.receiptPath.isEmpty ? null : e.receiptPath;
    } else {
      _categoryId = expenseCategories.first.id;
      _accountId = '';
      _currencyCode = '';
      _date = DateTime.now();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.read<AppState>();
    if (_accountId.isEmpty) _accountId = state.defaultAccountId;
    if (_currencyCode.isEmpty) _currencyCode = state.currencyCode;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _titleCtrl.dispose();
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

    final state = context.read<AppState>();
    final accountId =
        _accountId.isEmpty ? state.defaultAccountId : _accountId;
    final currency =
        _currencyCode.isEmpty ? state.currencyCode : _currencyCode;
    final cat = expenseCategoryById(_categoryId);
    final title =
        _titleCtrl.text.trim().isEmpty ? cat.name : _titleCtrl.text.trim();
    final receipt = _receiptPath ?? '';

    if (isEdit) {
      await state.updateExpense(
        widget.expense!.copyWith(
          amount: amount,
          title: title,
          categoryId: _categoryId,
          accountId: accountId,
          currencyCode: currency,
          date: _date,
          notes: '',
          receiptPath: receipt,
          clearReceipt: receipt.isEmpty,
        ),
      );
    } else {
      await state.addExpense(
        Expense(
          id: AppState.newId(),
          amount: amount,
          title: title,
          categoryId: _categoryId,
          accountId: accountId,
          currencyCode: currency,
          date: _date,
          receiptPath: receipt,
        ),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final symbol = currencyByCode(_currencyCode).symbol;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit' : 'Add expense'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          TextField(
            controller: _amountCtrl,
            autofocus: !isEdit,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [AmountInputFormatter()],
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            decoration: InputDecoration(
              prefixText: symbol,
              hintText: '0',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
            ),
          ),
          const SizedBox(height: 12),
          AppSelectField<String>(
            label: 'Currency',
            value: _currencyCode,
            searchHint: 'Search currency…',
            options: supportedCurrencies
                .map(
                  (c) => AppSelectOption(
                    value: c.code,
                    label: c.code,
                    subtitle: c.name,
                    icon: Icons.payments_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
                .toList(),
            onChanged: (c) => setState(() => _currencyCode = c),
          ),
          const SizedBox(height: 16),
          AccountPicker(
            accounts: state.activeAccounts,
            selectedId:
                _accountId.isEmpty ? state.defaultAccountId : _accountId,
            balances: state.allAccountBalances,
            onSelected: (id) => setState(() => _accountId = id),
            label: 'Paid from',
          ),
          const SizedBox(height: 16),
          AppSelectField<String>(
            label: 'Category',
            value: _categoryId,
            searchHint: 'Search category…',
            options: expenseCategories
                .map(
                  (c) => AppSelectOption(
                    value: c.id,
                    label: c.name,
                    icon: c.icon,
                    color: c.color,
                  ),
                )
                .toList(),
            onChanged: (id) => setState(() => _categoryId = id),
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
            controller: _titleCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: expenseCategoryById(_categoryId).name,
            ),
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
          ReceiptPicker(
            path: _receiptPath,
            onChanged: (p) => setState(() => _receiptPath = p),
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
              isEdit ? 'Save' : 'Add',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
