import 'package:flutter/material.dart';

import '../data/account_presets.dart';
import '../models/account.dart';

/// Renders bank/wallet logo when available, otherwise a colored icon.
class BankLogo extends StatelessWidget {
  final String? presetId;
  final AccountType? type;
  final double size;
  final double radius;
  final bool showBackground;

  const BankLogo({
    super.key,
    this.presetId,
    this.type,
    this.size = 40,
    this.radius = 12,
    this.showBackground = true,
  });

  factory BankLogo.fromAccount(
    MoneyAccount account, {
    Key? key,
    double size = 40,
    double radius = 12,
  }) {
    return BankLogo(
      key: key,
      presetId: account.presetId,
      type: account.type,
      size: size,
      radius: radius,
    );
  }

  factory BankLogo.fromPreset(
    AccountPreset preset, {
    Key? key,
    double size = 40,
    double radius = 12,
  }) {
    return BankLogo(
      key: key,
      presetId: preset.id,
      type: preset.type,
      size: size,
      radius: radius,
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = presetId ?? '';
    final asset = id.isEmpty ? null : bankLogoAsset(id);
    final preset = id.isEmpty ? null : presetById(id);
    final color = preset?.color ?? Theme.of(context).colorScheme.primary;
    final icon = preset?.icon ??
        (type != null ? typeIcon(type!) : Icons.account_balance_rounded);

    final child = asset == null
        ? Icon(icon, color: color, size: size * 0.5)
        : ClipRRect(
            borderRadius: BorderRadius.circular(radius * 0.6),
            child: Image.asset(
              asset,
              width: size * 0.72,
              height: size * 0.72,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(icon, color: color, size: size * 0.5),
            ),
          );

    if (!showBackground) {
      return SizedBox(width: size, height: size, child: Center(child: child));
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
