import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/account_presets.dart';
import '../models/account.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/amount_input.dart';
import '../utils/formatters.dart';
import '../widgets/app_select.dart';
import '../widgets/bank_logo.dart';
import 'account_detail_screen.dart';
import 'transfer_sheet.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  Future<void> _addAccount(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AccountFormScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final list = state.accounts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          IconButton(
            tooltip: 'Transfer',
            onPressed: () => showTransferSheet(context),
            icon: const Icon(Icons.swap_horiz_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Manage cash, bank & wallets — keep overall money under control',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                    ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C853), Color(0xFF00BFA5)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total balance',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatPkr(state.totalAccountsBalance),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${state.activeAccounts.length} accounts · cash, bank, wallet',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              children: [
                ..._section(
                  context,
                  'Cash',
                  list
                      .where(
                        (a) =>
                            a.type == AccountType.cash &&
                            !state.goalSavingsAccounts.any((g) => g.id == a.id),
                      )
                      .toList(),
                  state,
                ),
                ..._section(
                  context,
                  'Wallets',
                  list.where((a) => a.type == AccountType.wallet).toList(),
                  state,
                ),
                ..._section(
                  context,
                  'Banks',
                  list.where((a) => a.type == AccountType.bank).toList(),
                  state,
                ),
                ..._section(
                  context,
                  'Credit cards',
                  list.where((a) => a.type == AccountType.card).toList(),
                  state,
                ),
                ..._section(
                  context,
                  'Savings',
                  list.where((a) => a.type == AccountType.savings).toList(),
                  state,
                ),
                ..._section(
                  context,
                  'Person',
                  list.where((a) => a.type == AccountType.person).toList(),
                  state,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_accounts',
        onPressed: () => _addAccount(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Account'),
      ),
    );
  }

  List<Widget> _section(
    BuildContext context,
    String title,
    List<MoneyAccount> items,
    AppState state,
  ) {
    if (items.isEmpty) return [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
              ),
        ),
      ),
      ...items.map((a) {
        final bal = state.balanceFor(a.id);
        final isCard = a.isCreditCard;
        final color = isCard
            ? AppColors.expense
            : (bal >= 0 ? AppColors.income : AppColors.expense);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AccountDetailScreen(accountId: a.id),
              ),
            ),
            onLongPress: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AccountFormScreen(account: a),
              ),
            ),
            leading: BankLogo.fromAccount(a, size: 44, radius: 12),
            title: Text(
              a.name,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: a.archived
                    ? Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4)
                    : null,
              ),
            ),
            subtitle: Text(
              a.archived
                  ? 'Archived · ${typeLabel(a.type)}'
                  : isCard
                      ? (a.creditLimit > 0
                          ? 'Credit · limit ${formatPkr(a.creditLimit, compact: true)}'
                          : 'Credit card · you owe')
                      : typeLabel(a.type),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatPkr(bal),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                if (isCard)
                  Text(
                    'owed',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.expense.withValues(alpha: 0.8),
                        ),
                  ),
              ],
            ),
          ),
        );
      }),
    ];
  }
}

class AccountFormScreen extends StatefulWidget {
  final MoneyAccount? account;

  const AccountFormScreen({super.key, this.account});

  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  final _nameCtrl = TextEditingController();
  final _openingCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();
  AccountPreset? _preset;
  AccountType _type = AccountType.bank;

  bool get isEdit => widget.account != null;
  bool get isCard => _type == AccountType.card;
  bool get isSavings => _type == AccountType.savings;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    if (a != null) {
      _nameCtrl.text = a.name;
      _openingCtrl.text = formatAmountInput(a.openingBalance);
      _limitCtrl.text =
          a.creditLimit > 0 ? formatAmountInput(a.creditLimit) : '';
      // Savings type removed from UI — treat as bank when editing.
      _type = a.type == AccountType.savings ? AccountType.bank : a.type;
      _preset = a.presetId.isNotEmpty ? presetById(a.presetId) : null;
    } else {
      _preset = presetById('hbl');
      _type = _preset!.type;
      _nameCtrl.text = _preset!.name;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _openingCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  List<AccountPreset> get _presetsForType {
    final list = accountPresets.where((p) => p.type == _type).toList();
    if (list.isEmpty) {
      return accountPresets.where((p) => p.type == AccountType.bank).toList();
    }
    return list;
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter account name')),
      );
      return;
    }
    final opening = parseAmount(_openingCtrl.text) ?? 0.0;
    final limit = isCard ? (parseAmount(_limitCtrl.text) ?? 0.0) : 0.0;
    final state = context.read<AppState>();

    if (isEdit) {
      await state.updateAccount(
        widget.account!.copyWith(
          name: name,
          type: _type,
          presetId: _preset?.id ?? '',
          openingBalance: opening,
          creditLimit: limit,
        ),
      );
    } else {
      await state.addAccount(
        MoneyAccount(
          id: AppState.newId(),
          name: name,
          type: _type,
          presetId: _preset?.id ?? '',
          openingBalance: opening,
          creditLimit: limit,
        ),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final presets = _presetsForType;
    final bankOptions = presets
        .map(
          (p) => AppSelectOption(
            value: p.id,
            label: p.name,
            subtitle: typeLabel(p.type),
            icon: p.icon,
            color: p.color,
            leading: BankLogo.fromPreset(p, size: 40, radius: 10),
          ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit account' : 'Add account'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final state = context.read<AppState>();
                if (state.accounts.length <= 1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Keep at least one account'),
                    ),
                  );
                  return;
                }
                await state.deleteAccount(widget.account!.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          Text(
            'Account type',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          AppSegmentedType<AccountType>(
            selected: _type,
            onChanged: (t) {
              setState(() {
                _type = t;
                final first = accountPresets.where((p) => p.type == t);
                if (first.isNotEmpty) {
                  _preset = first.first;
                  if (!isEdit) _nameCtrl.text = _preset!.name;
                } else if (t == AccountType.card) {
                  _preset = presetById('cc_visa');
                  if (!isEdit) _nameCtrl.text = _preset!.name;
                }
              });
            },
            items: AccountType.values
                .where((t) => t != AccountType.person) // person rarely needed
                .map(
                  (t) => (
                    value: t,
                    label: t == AccountType.card
                        ? 'Credit'
                        : t == AccountType.savings
                            ? 'Savings'
                            : typeLabel(t),
                    icon: typeIcon(t),
                  ),
                )
                .toList(),
          ),
          if (isCard) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF5C6BC0).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Credit card = money you spend now and pay back later. '
                'Purchases increase what you owe. Pay the bill from cash/bank.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.35,
                    ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          AppSelectField<String>(
            label: _type == AccountType.bank
                ? 'Bank'
                : _type == AccountType.wallet
                    ? 'Wallet'
                    : _type == AccountType.cash
                        ? 'Cash type'
                        : _type == AccountType.card
                            ? 'Credit card'
                            : _type == AccountType.savings
                                ? 'Savings bank'
                                : 'Option',
            value: _preset?.id,
            options: bankOptions,
            searchHint: _type == AccountType.bank
                ? 'Search bank (HBL, UBL, Meezan…)'
                : _type == AccountType.card
                    ? 'Search card (Visa, HBL, Meezan…)'
                    : _type == AccountType.savings
                        ? 'Search savings (UBL, HBL…)'
                        : 'Search…',
            hint: 'Select…',
            leading: _preset != null
                ? BankLogo.fromPreset(_preset!, size: 36, radius: 10)
                : null,
            onChanged: (id) {
              final p = presetById(id);
              setState(() {
                _preset = p;
                _type = p.type;
                _nameCtrl.text = p.name;
              });
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Display name',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: isCard
                  ? 'e.g. HBL Visa ****1234'
                  : isSavings
                      ? 'e.g. UBL Savings · Trip fund'
                      : 'e.g. HBL Salary A/C',
            ),
          ),
          if (isCard) ...[
            const SizedBox(height: 16),
            Text(
              'Credit limit',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _limitCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: const [AmountInputFormatter()],
              decoration: const InputDecoration(
                prefixText: 'Rs  ',
                hintText: '0',
                helperText: 'Max you can spend on this card',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Current outstanding (what you owe)',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _openingCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: const [AmountInputFormatter()],
              decoration: const InputDecoration(
                prefixText: 'Rs  ',
                hintText: '0',
                helperText: 'Bill amount still unpaid right now',
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Text(
              'Opening balance',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _openingCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: const [
                AmountInputFormatter(allowNegative: true),
              ],
              decoration: const InputDecoration(
                prefixText: 'Rs  ',
                hintText: '0',
                helperText: 'Current amount already in this account',
              ),
            ),
          ],
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
              isEdit ? 'Save' : 'Add account',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
