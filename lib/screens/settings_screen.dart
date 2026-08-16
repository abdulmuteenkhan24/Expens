import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/currencies.dart';
import '../providers/app_state.dart';
import '../providers/auth_state.dart';
import '../services/backup_service.dart';
import '../theme/app_theme.dart';
import '../utils/amount_input.dart';
import '../utils/formatters.dart';
import 'security_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;

  Future<void> _export(BuildContext context) async {
    final state = context.read<AppState>();
    setState(() => _busy = true);
    try {
      await BackupService.exportShare(state);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup ready — save to Drive, Files, or send to yourself'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import(BuildContext context) async {
    final state = context.read<AppState>();
    final counts = state.backupCounts;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import backup?'),
        content: Text(
          'This replaces all current data on this phone with the backup file.\n\n'
          'Now on this device:\n'
          '• ${counts['accounts']} accounts\n'
          '• ${counts['expenses']} expenses · ${counts['incomes']} incomes\n'
          '• ${counts['loans']} loans · ${counts['events']} events\n\n'
          'Save an export first if you want to keep current data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Choose file'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    setState(() => _busy = true);
    try {
      final json = await BackupService.pickBackupJson();
      if (json == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      await state.importBackupJson(json);
      if (!context.mounted) return;
      final after = state.backupCounts;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported · ${after['accounts']} accounts · '
            '${after['expenses']} expenses · ${after['incomes']} incomes',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final auth = context.watch<AuthState>();
    final counts = state.backupCounts;
    final themeIcon = switch (state.themeMode) {
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.dark => Icons.dark_mode_rounded,
      ThemeMode.system => Icons.brightness_auto_rounded,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Backup & restore',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: _busy
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file_rounded),
                  title: const Text('Export data'),
                  subtitle: Text(
                    'Save full backup · ${counts['accounts']} accounts · '
                    '${counts['expenses']} expenses · ${counts['loans']} loans',
                  ),
                  trailing: const Icon(Icons.ios_share_rounded),
                  onTap: _busy ? null : () => _export(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download_rounded),
                  title: const Text('Import data'),
                  subtitle: const Text(
                    'Restore backup on a new phone (replaces current data)',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _busy ? null : () => _import(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Export a .json file to Google Drive / Files / email. On a new phone, install Expens → Settings → Import and pick that file. Receipt photos are not included.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Currency',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.currency_exchange_rounded),
                  title: const Text('Primary currency'),
                  subtitle: Text(
                    '${state.currency.code} · ${state.currency.name}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _pickPrimaryCurrency(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.swap_vert_rounded),
                  title: const Text('Exchange rates'),
                  subtitle: Text(
                    'Convert other currencies to ${state.currency.code}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ExchangeRatesScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Security',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text('PIN & biometrics'),
              subtitle: Text(
                auth.pinEnabled ? 'App lock is on' : 'App lock is off',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SecurityScreen()),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(themeIcon),
              title: const Text('Theme'),
              subtitle: Text(
                switch (state.themeMode) {
                  ThemeMode.system => 'System',
                  ThemeMode.light => 'Light',
                  ThemeMode.dark => 'Dark',
                },
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: state.cycleTheme,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Amounts are stored in their own currency. Totals convert to '
            '${state.currency.code} using your exchange rates.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _pickPrimaryCurrency(BuildContext context) async {
    final state = context.read<AppState>();
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(
              'Primary currency',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          ...supportedCurrencies.map(
            (c) => ListTile(
              leading: Icon(
                c.code == state.currencyCode
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: c.code == state.currencyCode
                    ? Theme.of(ctx).colorScheme.primary
                    : null,
              ),
              title: Text('${c.code} · ${c.name}'),
              subtitle: Text(c.symbol.trim()),
              onTap: () => Navigator.pop(ctx, c.code),
            ),
          ),
        ],
      ),
    );
    if (selected != null && context.mounted) {
      await context.read<AppState>().setCurrencyCode(selected);
    }
  }
}

class ExchangeRatesScreen extends StatelessWidget {
  const ExchangeRatesScreen({super.key});

  Future<void> _editRate(
    BuildContext context,
    String code,
    double current,
    String primary,
  ) async {
    final ctrl = TextEditingController(text: formatAmountInput(current));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('1 $code = ? $primary'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: const [AmountInputFormatter()],
          decoration: InputDecoration(
            labelText: primary,
            helperText: 'How many $primary equal 1 $code',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final v = parseAmount(ctrl.text);
      if (v != null && v > 0) {
        await context.read<AppState>().setExchangeRate(code, v);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final primary = state.currencyCode;

    return Scaffold(
      appBar: AppBar(title: const Text('Exchange rates')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'Set how many $primary equal 1 unit of each currency. '
                'Used for totals and charts.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.65),
                    ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...supportedCurrencies.map((c) {
            final rate = state.ratesToPrimary[c.code] ??
                defaultRatesToPkr[c.code] ??
                1.0;
            final isPrimary = c.code == primary;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    c.code.substring(0, 1),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                title: Text(
                  c.code,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(c.name),
                trailing: isPrimary
                    ? Text(
                        'Primary',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : Text(
                        '1 ${c.code} = ${formatPkr(rate)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                onTap: isPrimary
                    ? null
                    : () => _editRate(context, c.code, rate, primary),
              ),
            );
          }),
        ],
      ),
    );
  }
}
