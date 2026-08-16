import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/categories.dart';
import '../models/expense.dart';
import '../providers/app_state.dart';
import '../services/sms_parser.dart';
import '../utils/amount_input.dart';
import '../utils/formatters.dart';
import '../widgets/account_picker.dart';
import '../widgets/app_select.dart';
import '../widgets/bank_logo.dart';

/// Editable draft built from pasted bank SMS text.
class _SmsDraft {
  double amount;
  String title;
  String categoryId;
  String accountId;
  DateTime date;
  String notes;
  String raw;
  String? location;
  String? cardLast4;

  _SmsDraft({
    required this.amount,
    required this.title,
    required this.categoryId,
    required this.accountId,
    required this.date,
    required this.notes,
    required this.raw,
    this.location,
    this.cardLast4,
  });

  bool get isAtm => categoryId == 'atm';

  factory _SmsDraft.fromParsed(ParsedSmsExpense p, String accountId) {
    final noteParts = <String>['Imported from SMS'];
    if (p.location != null) noteParts.add(p.location!);
    if (p.cardLast4 != null) noteParts.add('Card ****${p.cardLast4}');
    return _SmsDraft(
      amount: p.amount,
      title: p.title,
      categoryId: p.categoryId,
      accountId: accountId,
      date: p.date,
      notes: noteParts.join(' · '),
      raw: p.raw,
      location: p.location,
      cardLast4: p.cardLast4,
    );
  }
}

/// Clipboard-only SMS import — no inbox access, no SMS permission.
class SmsImportScreen extends StatefulWidget {
  const SmsImportScreen({super.key});

  @override
  State<SmsImportScreen> createState() => _SmsImportScreenState();
}

class _SmsImportScreenState extends State<SmsImportScreen> {
  final _pasteCtrl = TextEditingController();
  final List<_SmsDraft> _drafts = [];
  final Set<int> _selected = {};
  bool _loadingClipboard = true;
  String? _status;

  @override
  void initState() {
    super.initState();
    // Auto-read clipboard as soon as screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pasteFromClipboard(silent: true);
    });
  }

  @override
  void dispose() {
    _pasteCtrl.dispose();
    super.dispose();
  }

  List<_SmsDraft> _toDrafts(List<ParsedSmsExpense> parsed) {
    final state = context.read<AppState>();
    return parsed
        .where((p) => p.isDebit)
        .map((p) {
          final accountId = state.accountIdFromSms(p.raw);
          return _SmsDraft.fromParsed(
            p,
            accountId.isEmpty ? state.defaultAccountId : accountId,
          );
        })
        .toList();
  }

  void _setDrafts(List<_SmsDraft> drafts, String status) {
    setState(() {
      _drafts
        ..clear()
        ..addAll(drafts);
      _selected
        ..clear()
        ..addAll(List.generate(_drafts.length, (i) => i));
      _status = status;
      _loadingClipboard = false;
    });
  }

  void _parseText(String text, {bool openEditIfOne = false}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _drafts.clear();
        _selected.clear();
        _status = 'Copy a bank SMS, then open this screen (or paste again).';
        _loadingClipboard = false;
      });
      return;
    }

    _pasteCtrl.text = trimmed;
    final p = SmsParser.parse(trimmed);
    if (p == null) {
      setState(() {
        _drafts.clear();
        _selected.clear();
        _status = 'Could not detect an amount in this text';
        _loadingClipboard = false;
      });
      return;
    }
    if (!p.isDebit) {
      setState(() {
        _drafts.clear();
        _selected.clear();
        _status = 'Looks like a credit/income SMS — not imported as expense';
        _loadingClipboard = false;
      });
      return;
    }

    final drafts = _toDrafts([p]);
    _setDrafts(
      drafts,
      'Detected — tap the card to edit amount, account, category…',
    );

    // One item: open editor so user can fix details before import.
    if (openEditIfOne && drafts.length == 1 && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _editDraft(0);
      });
    }
  }

  Future<void> _pasteFromClipboard({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loadingClipboard = true;
        _status = 'Reading clipboard…';
      });
    }

    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      if (!mounted) return;

      if (text.isEmpty) {
        setState(() {
          _drafts.clear();
          _selected.clear();
          _status =
              'Clipboard is empty. Copy a bank / JazzCash / EasyPaisa SMS first.';
          _loadingClipboard = false;
        });
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Clipboard is empty')),
          );
        }
        return;
      }

      _parseText(text, openEditIfOne: true);
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pasted from clipboard')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingClipboard = false;
        _status = 'Could not read clipboard. Paste the SMS text below.';
      });
    }
  }

  Future<void> _editDraft(int index) async {
    if (index < 0 || index >= _drafts.length) return;
    final draft = _drafts[index];
    final updated = await showModalBottomSheet<_SmsDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => _EditSmsDraftSheet(draft: draft),
    );
    if (updated != null && mounted) {
      setState(() => _drafts[index] = updated);
    }
  }

  Future<void> _importSelected() async {
    if (_selected.isEmpty) return;
    final state = context.read<AppState>();
    var expenses = 0;
    var atms = 0;

    for (final i in _selected.toList()..sort()) {
      final d = _drafts[i];
      final accountId =
          d.accountId.isEmpty ? state.defaultAccountId : d.accountId;

      // ATM / cash withdrawal = bank → Cash transfer (not expense).
      if (d.isAtm) {
        await state.recordAtmWithdrawal(
          amount: d.amount,
          fromAccountId: accountId,
          note: [
            if (d.location != null && d.location!.isNotEmpty) d.location!,
            if (d.cardLast4 != null) '****${d.cardLast4}',
            if (d.notes.isNotEmpty) d.notes,
          ].where((s) => s.isNotEmpty).join(' · '),
          date: d.date,
        );
        atms++;
        continue;
      }

      await state.addExpense(
        Expense(
          id: AppState.newId(),
          amount: d.amount,
          title: d.title.trim().isEmpty ? 'SMS expense' : d.title.trim(),
          categoryId: d.categoryId,
          accountId: accountId,
          currencyCode: state.currencyCode,
          date: d.date,
          notes: d.notes,
          location: d.location ?? '',
        ),
      );
      expenses++;
    }

    if (!mounted) return;
    final parts = <String>[];
    if (expenses > 0) {
      parts.add('$expenses expense${expenses == 1 ? '' : 's'}');
    }
    if (atms > 0) {
      parts.add('$atms ATM → Cash');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imported ${parts.join(' · ')}')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import SMS'),
        actions: [
          IconButton(
            tooltip: 'Paste from clipboard again',
            onPressed: () => _pasteFromClipboard(),
            icon: const Icon(Icons.content_paste_go_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.content_paste_rounded, color: cs.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Copy a bank SMS → open this screen. Text is read from '
                    'clipboard automatically. No SMS permission, no inbox access.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.75),
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadingClipboard ? null : () => _pasteFromClipboard(),
            icon: _loadingClipboard
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.content_paste_rounded),
            label: Text(
              _loadingClipboard ? 'Reading clipboard…' : 'Paste from clipboard',
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _pasteCtrl,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'SMS text',
              hintText: 'Or paste bank SMS text here…',
              alignLabelWithHint: true,
              suffixIcon: IconButton(
                tooltip: 'Paste from clipboard',
                icon: const Icon(Icons.content_paste_rounded),
                onPressed: () => _pasteFromClipboard(),
              ),
            ),
            onChanged: (v) {
              // Live re-detect when user pastes/types manually.
              if (v.trim().length > 20) {
                _parseText(v, openEditIfOne: false);
              }
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: () => _parseText(
                _pasteCtrl.text,
                openEditIfOne: true,
              ),
              child: const Text('Detect & edit'),
            ),
          ),
          if (_status != null) ...[
            const SizedBox(height: 12),
            Text(
              _status!,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
          if (_drafts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Tap card to edit · then Import',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
            ),
          ],
          const SizedBox(height: 12),
          ...List.generate(_drafts.length, (i) {
            final d = _drafts[i];
            final cat = expenseCategoryById(d.categoryId);
            final account = state.accountById(d.accountId);
            final selected = _selected.contains(i);

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _editDraft(i),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: selected,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selected.add(i);
                            } else {
                              _selected.remove(i);
                            }
                          });
                        },
                      ),
                      CircleAvatar(
                        backgroundColor: cat.color.withValues(alpha: 0.15),
                        child: Icon(cat.icon, color: cat.color, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    d.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  formatPkr(d.amount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [
                                cat.name,
                                if (account != null) account.name,
                                formatDate(d.date),
                                if (d.isAtm) 'ATM → Cash',
                              ].join(' · '),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color:
                                        cs.onSurface.withValues(alpha: 0.55),
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to edit details',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: cs.onSurface.withValues(alpha: 0.35),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _selected.isEmpty ? null : _importSelected,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text(
              _selected.isEmpty
                  ? 'Nothing to import'
                  : 'Import ${_selected.length} item${_selected.length == 1 ? '' : 's'}',
            ),
          ),
        ),
      ),
    );
  }
}

/// Edit form for one SMS draft before import.
class _EditSmsDraftSheet extends StatefulWidget {
  final _SmsDraft draft;

  const _EditSmsDraftSheet({required this.draft});

  @override
  State<_EditSmsDraftSheet> createState() => _EditSmsDraftSheetState();
}

class _EditSmsDraftSheetState extends State<_EditSmsDraftSheet> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _notesCtrl;
  late String _categoryId;
  late String _accountId;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    _amountCtrl = TextEditingController(text: formatAmountInput(d.amount));
    _titleCtrl = TextEditingController(text: d.title);
    _notesCtrl = TextEditingController(text: d.notes);
    _categoryId = d.categoryId;
    _accountId = d.accountId;
    _date = d.date;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final amount = parseAmount(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    Navigator.pop(
      context,
      _SmsDraft(
        amount: amount,
        title: _titleCtrl.text.trim().isEmpty
            ? widget.draft.title
            : _titleCtrl.text.trim(),
        categoryId: _categoryId,
        accountId: _accountId,
        date: _date,
        notes: _notesCtrl.text.trim(),
        raw: widget.draft.raw,
        location: widget.draft.location,
        cardLast4: widget.draft.cardLast4,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Edit before import',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Change amount, account, category, or date if needed',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                  ),
            ),
            if (widget.draft.raw.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.draft.raw,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.65),
                      ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: const [AmountInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: 'Rs ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'What was this for?',
              ),
            ),
            const SizedBox(height: 14),
            AccountPicker(
              accounts: state.activeAccounts,
              selectedId: _accountId.isEmpty ? null : _accountId,
              balances: {
                for (final a in state.activeAccounts)
                  a.id: state.balanceFor(a.id),
              },
              onSelected: (id) => setState(() => _accountId = id),
              label: 'From account',
            ),
            const SizedBox(height: 14),
            AppSelectField<String>(
              label: 'Category',
              value: _categoryId,
              hint: 'Select category',
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
            if (_categoryId == 'atm') ...[
              const SizedBox(height: 8),
              Text(
                'ATM is saved as bank → Cash transfer (not an expense).',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
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
                  if (d != null) {
                    setState(() {
                      _date = DateTime(
                        d.year,
                        d.month,
                        d.day,
                        _date.hour,
                        _date.minute,
                      );
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.event_rounded, size: 20),
                  ),
                  child: Text(formatDateFull(_date)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes',
                alignLabelWithHint: true,
              ),
            ),
            if (_accountId.isNotEmpty) ...[
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final acc = state.accountById(_accountId);
                  if (acc == null) return const SizedBox.shrink();
                  return Row(
                    children: [
                      BankLogo.fromAccount(acc, size: 28, radius: 8),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Will deduct from ${acc.name}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.55),
                                  ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}
