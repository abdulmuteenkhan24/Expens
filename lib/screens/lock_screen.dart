import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pin = '';
  String? _error;
  bool _busy = false;
  bool _triedBiometric = false;

  static const _pinLength = 4;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    if (_triedBiometric) return;
    _triedBiometric = true;
    final auth = context.read<AuthState>();
    if (!auth.biometricEnabled || !auth.biometricAvailable) return;
    setState(() => _busy = true);
    await auth.unlockWithBiometrics();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _onDigit(String d) async {
    if (_busy || _pin.length >= _pinLength) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length == _pinLength) {
      await _submit();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final ok = await context.read<AuthState>().verifyPin(_pin);
    if (!mounted) return;
    if (!ok) {
      HapticFeedback.heavyImpact();
      setState(() {
        _error = 'Incorrect PIN';
        _pin = '';
        _busy = false;
      });
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            const AppLogo(size: 72, glow: true),
            const SizedBox(height: 20),
            Text(
              'Expens is locked',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter your PIN to continue',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pinLength, (i) {
                final filled = i < _pin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled
                        ? (_error != null ? AppColors.expense : AppColors.primary)
                        : Colors.transparent,
                    border: Border.all(
                      color: _error != null
                          ? AppColors.expense
                          : cs.onSurface.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 22,
              child: _error != null
                  ? Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.expense,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
            ),
            const Spacer(),
            _PinPad(
              onDigit: _onDigit,
              onBackspace: _onBackspace,
              biometricEnabled:
                  auth.biometricEnabled && auth.biometricAvailable,
              onBiometric: _tryBiometric,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PinPad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final bool biometricEnabled;
  final VoidCallback onBiometric;

  const _PinPad({
    required this.onDigit,
    required this.onBackspace,
    required this.biometricEnabled,
    required this.onBiometric,
  });

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      [biometricEnabled ? 'bio' : '', '0', 'del'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        children: keys.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: row.map((k) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _Key(
                      label: k,
                      onTap: () {
                        if (k == 'del') {
                          onBackspace();
                        } else if (k == 'bio') {
                          onBiometric();
                        } else if (k.isNotEmpty) {
                          onDigit(k);
                        }
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _Key({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) {
      return const SizedBox(height: 64);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget child;
    if (label == 'del') {
      child = const Icon(Icons.backspace_outlined, size: 22);
    } else if (label == 'bio') {
      child = const Icon(Icons.fingerprint_rounded, size: 28);
    } else {
      child = Text(
        label,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      );
    }

    return Material(
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 64,
          child: Center(child: child),
        ),
      ),
    );
  }
}
