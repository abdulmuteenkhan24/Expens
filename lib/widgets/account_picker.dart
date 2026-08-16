import 'package:flutter/material.dart';

import '../data/account_presets.dart';
import '../models/account.dart';
import '../utils/formatters.dart';
import 'app_select.dart';
import 'bank_logo.dart';

class AccountPicker extends StatelessWidget {
  final List<MoneyAccount> accounts;
  final String? selectedId;
  final Map<String, double>? balances;
  final ValueChanged<String> onSelected;
  final String label;

  const AccountPicker({
    super.key,
    required this.accounts,
    required this.selectedId,
    required this.onSelected,
    this.balances,
    this.label = 'Account',
  });

  @override
  Widget build(BuildContext context) {
    final active = accounts.where((a) => !a.archived).toList();
    if (active.isEmpty) {
      return Text(
        'No accounts yet. Add one from Accounts.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    final selected = active.where((a) => a.id == selectedId).firstOrNull;
    final options = active.map((a) {
      final preset = presetById(a.presetId.isEmpty ? 'cash' : a.presetId);
      final bal = balances?[a.id];
      return AppSelectOption(
        value: a.id,
        label: a.name,
        subtitle: bal != null
            ? '${typeLabel(a.type)} · ${formatPkr(bal)}'
            : typeLabel(a.type),
        icon: a.presetId.isNotEmpty ? preset.icon : typeIcon(a.type),
        color: preset.color,
      );
    }).toList();

    return AppSelectField<String>(
      label: label,
      value: selectedId,
      options: options,
      searchHint: 'Search account…',
      hint: 'Select account',
      onChanged: onSelected,
      leading: selected != null
          ? BankLogo.fromAccount(selected, size: 36, radius: 10)
          : null,
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
