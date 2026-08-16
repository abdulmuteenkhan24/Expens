import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_state.dart';
import '../theme/app_theme.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  Future<String?> _askPin(
    BuildContext context, {
    required String title,
    String? subtitle,
  }) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle != null) ...[
              Text(subtitle),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: ctrl,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: const InputDecoration(
                labelText: '4-digit PIN',
                counterText: '',
              ),
              onSubmitted: (v) {
                if (v.length == 4) Navigator.pop(ctx, v);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (ctrl.text.length == 4) {
                Navigator.pop(ctx, ctrl.text);
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return result;
  }

  Future<void> _enablePin(BuildContext context) async {
    final pin = await _askPin(
      context,
      title: 'Create PIN',
      subtitle: 'Choose a 4-digit PIN to lock the app.',
    );
    if (pin == null || !context.mounted) return;

    final confirm = await _askPin(
      context,
      title: 'Confirm PIN',
      subtitle: 'Enter the same PIN again.',
    );
    if (confirm == null || !context.mounted) return;

    if (pin != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PINs do not match')),
      );
      return;
    }

    final ok = await context.read<AuthState>().enablePin(pin);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'PIN protection enabled'
              : 'Could not save PIN. Try a full app restart.',
        ),
      ),
    );
  }

  Future<void> _changePin(BuildContext context) async {
    final current = await _askPin(context, title: 'Current PIN');
    if (current == null || !context.mounted) return;

    final next = await _askPin(
      context,
      title: 'New PIN',
      subtitle: 'Choose a new 4-digit PIN.',
    );
    if (next == null || !context.mounted) return;

    final confirm = await _askPin(context, title: 'Confirm new PIN');
    if (confirm == null || !context.mounted) return;

    if (next != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New PINs do not match')),
      );
      return;
    }

    final ok = await context.read<AuthState>().changePin(
          currentPin: current,
          newPin: next,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'PIN updated' : 'Current PIN is incorrect'),
      ),
    );
  }

  Future<void> _disablePin(BuildContext context) async {
    final pin = await _askPin(
      context,
      title: 'Disable PIN',
      subtitle: 'Enter your PIN to turn off lock protection.',
    );
    if (pin == null || !context.mounted) return;

    final ok = await context.read<AuthState>().disablePin(pin);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'PIN protection disabled' : 'Incorrect PIN'),
      ),
    );
  }

  Future<void> _toggleBiometric(BuildContext context, bool value) async {
    final auth = context.read<AuthState>();
    if (value && !auth.pinEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enable PIN first')),
      );
      return;
    }
    if (value && !auth.biometricAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No fingerprint or Face ID available on this device'),
        ),
      );
      return;
    }
    await auth.setBiometricEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.pinEnabled ? 'App lock is on' : 'App lock is off',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          auth.pinEnabled
                              ? 'PIN required when you open the app'
                              : 'Protect expenses with a PIN and fingerprint',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.55),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'PIN protection',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.pin_rounded),
                  title: const Text('Require PIN'),
                  subtitle: const Text('4-digit PIN to unlock'),
                  value: auth.pinEnabled,
                  onChanged: (v) {
                    if (v) {
                      _enablePin(context);
                    } else {
                      _disablePin(context);
                    }
                  },
                ),
                if (auth.pinEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.password_rounded),
                    title: const Text('Change PIN'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _changePin(context),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Biometrics',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.fingerprint_rounded),
              title: const Text('Fingerprint / Face unlock'),
              subtitle: Text(
                !auth.pinEnabled
                    ? 'Enable PIN first'
                    : auth.biometricAvailable
                        ? 'Unlock faster with biometrics'
                        : 'Not available on this device',
              ),
              value: auth.biometricEnabled && auth.pinEnabled,
              onChanged: auth.pinEnabled
                  ? (v) => _toggleBiometric(context, v)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline_rounded),
              title: const Text('Lock now'),
              subtitle: const Text('Immediately lock the app'),
              enabled: auth.pinEnabled,
              onTap: auth.pinEnabled
                  ? () {
                      context.read<AuthState>().lock();
                      Navigator.pop(context);
                    }
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your PIN is stored as a secure hash on this device. It is never uploaded.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.45),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
