import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../data/currencies.dart';
import '../models/account.dart';
import '../models/transaction_filter.dart';
import '../utils/formatters.dart';

class TransactionSearchBar extends StatefulWidget {
  final TransactionFilter filter;
  final ValueChanged<TransactionFilter> onChanged;
  final List<MoneyAccount> accounts;
  final bool isExpense;

  const TransactionSearchBar({
    super.key,
    required this.filter,
    required this.onChanged,
    required this.accounts,
    this.isExpense = true,
  });

  @override
  State<TransactionSearchBar> createState() => _TransactionSearchBarState();
}

class _TransactionSearchBarState extends State<TransactionSearchBar> {
  late final TextEditingController _queryCtrl;

  @override
  void initState() {
    super.initState();
    _queryCtrl = TextEditingController(text: widget.filter.query);
  }

  @override
  void didUpdateWidget(covariant TransactionSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filter.query != _queryCtrl.text &&
        widget.filter.query != oldWidget.filter.query) {
      _queryCtrl.text = widget.filter.query;
    }
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    var draft = widget.filter;
    final result = await showModalBottomSheet<TransactionFilter>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final cats =
                widget.isExpense ? expenseCategories : incomeSources;
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                top: 8,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Filters',
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setLocal(() {
                              draft = TransactionFilter(
                                query: draft.query,
                              );
                            });
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isExpense ? 'Category' : 'Source',
                      style: Theme.of(ctx).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('All'),
                          selected: draft.categoryId == null,
                          onSelected: (_) => setLocal(
                            () => draft = draft.copyWith(clearCategory: true),
                          ),
                        ),
                        ...cats.map(
                          (c) => FilterChip(
                            label: Text(c.name),
                            selected: draft.categoryId == c.id,
                            onSelected: (_) => setLocal(
                              () => draft = draft.copyWith(categoryId: c.id),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text('Account', style: Theme.of(ctx).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('All'),
                          selected: draft.accountId == null,
                          onSelected: (_) => setLocal(
                            () => draft = draft.copyWith(clearAccount: true),
                          ),
                        ),
                        ...widget.accounts.map(
                          (a) => FilterChip(
                            label: Text(a.name),
                            selected: draft.accountId == a.id,
                            onSelected: (_) => setLocal(
                              () => draft = draft.copyWith(accountId: a.id),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text('Currency', style: Theme.of(ctx).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('All'),
                          selected: draft.currencyCode == null,
                          onSelected: (_) => setLocal(
                            () => draft = draft.copyWith(clearCurrency: true),
                          ),
                        ),
                        ...supportedCurrencies.map(
                          (c) => FilterChip(
                            label: Text(c.code),
                            selected: draft.currencyCode == c.code,
                            onSelected: (_) => setLocal(
                              () =>
                                  draft = draft.copyWith(currencyCode: c.code),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text('Receipt', style: Theme.of(ctx).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Any'),
                          selected: draft.hasReceipt == null,
                          onSelected: (_) => setLocal(
                            () => draft = draft.copyWith(clearReceipt: true),
                          ),
                        ),
                        FilterChip(
                          label: const Text('With receipt'),
                          selected: draft.hasReceipt == true,
                          onSelected: (_) => setLocal(
                            () => draft = draft.copyWith(hasReceipt: true),
                          ),
                        ),
                        FilterChip(
                          label: const Text('No receipt'),
                          selected: draft.hasReceipt == false,
                          onSelected: (_) => setLocal(
                            () => draft = draft.copyWith(hasReceipt: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Date range',
                      style: Theme.of(ctx).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: ctx,
                                initialDate: draft.from ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (d != null) {
                                setLocal(
                                  () => draft = draft.copyWith(from: d),
                                );
                              }
                            },
                            child: Text(
                              draft.from == null
                                  ? 'From'
                                  : formatDateFull(draft.from!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: ctx,
                                initialDate: draft.to ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (d != null) {
                                setLocal(() => draft = draft.copyWith(to: d));
                              }
                            },
                            child: Text(
                              draft.to == null
                                  ? 'To'
                                  : formatDateFull(draft.to!),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Clear dates',
                          onPressed: () => setLocal(
                            () => draft = draft.copyWith(clearDates: true),
                          ),
                          icon: const Icon(Icons.clear),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, draft),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Apply filters'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (result != null) widget.onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.filter.activeCount -
        (widget.filter.query.trim().isNotEmpty ? 1 : 0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _queryCtrl,
              onChanged: (v) =>
                  widget.onChanged(widget.filter.copyWith(query: v)),
              decoration: InputDecoration(
                hintText: 'Search…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                suffixIcon: _queryCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _queryCtrl.clear();
                          widget.onChanged(widget.filter.copyWith(query: ''));
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Badge(
            isLabelVisible: count > 0,
            label: Text('$count'),
            child: IconButton.filledTonal(
              tooltip: 'Filters',
              onPressed: _openFilters,
              icon: const Icon(Icons.tune_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
