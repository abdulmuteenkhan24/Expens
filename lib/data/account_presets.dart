import 'package:flutter/material.dart';

import '../models/account.dart';
import 'bank_logos.dart';

export 'bank_logos.dart' show bankLogoAsset, bankLogoFiles, bankLogosDir;

/// Cash, wallets, and all banks that have logos in `lib/bank-logos/`.
const accountPresets = <AccountPreset>[
  // ── Cash / Person ─────────────────────────────────────────
  AccountPreset(
    id: 'cash',
    name: 'Cash',
    type: AccountType.cash,
    icon: Icons.payments_rounded,
    color: Color(0xFF06D6A0),
  ),
  AccountPreset(
    id: 'person',
    name: 'Person',
    type: AccountType.person,
    icon: Icons.person_rounded,
    color: Color(0xFF8D6E63),
  ),

  // ── Wallets / fintech ─────────────────────────────────────
  AccountPreset(
    id: 'jazzcash',
    name: 'JazzCash',
    type: AccountType.wallet,
    icon: Icons.phone_android_rounded,
    color: Color(0xFF000000),
    smsKeywords: ['jazzcash', 'jazz cash', 'mobilink'],
  ),
  AccountPreset(
    id: 'easypaisa',
    name: 'EasyPaisa',
    type: AccountType.wallet,
    icon: Icons.account_balance_wallet_rounded,
    color: Color(0xFF00A651),
    smsKeywords: ['easypaisa', 'easy paisa', 'telenor bank'],
  ),
  AccountPreset(
    id: 'sadapay',
    name: 'SadaPay',
    type: AccountType.wallet,
    icon: Icons.credit_card_rounded,
    color: Color(0xFF6C5CE7),
    smsKeywords: ['sadapay', 'sada pay'],
  ),
  AccountPreset(
    id: 'nayapay',
    name: 'NayaPay',
    type: AccountType.wallet,
    icon: Icons.wallet_rounded,
    color: Color(0xFFE17055),
    smsKeywords: ['nayapay', 'naya pay'],
  ),
  AccountPreset(
    id: 'zindigi',
    name: 'Zindigi',
    type: AccountType.wallet,
    icon: Icons.phone_iphone_rounded,
    color: Color(0xFF6A1B9A),
    smsKeywords: ['zindigi'],
  ),
  AccountPreset(
    id: 'upaisa',
    name: 'UPaisa',
    type: AccountType.wallet,
    icon: Icons.phone_iphone_rounded,
    color: Color(0xFFE53935),
    smsKeywords: ['upaisa', 'u paisa'],
  ),
  AccountPreset(
    id: 'keenu',
    name: 'Keenu',
    type: AccountType.wallet,
    icon: Icons.qr_code_rounded,
    color: Color(0xFF00897B),
    smsKeywords: ['keenu'],
  ),
  AccountPreset(
    id: 'finja',
    name: 'Finja',
    type: AccountType.wallet,
    icon: Icons.account_balance_wallet_outlined,
    color: Color(0xFF3949AB),
    smsKeywords: ['finja'],
  ),
  AccountPreset(
    id: 'paymax',
    name: 'PayMax',
    type: AccountType.wallet,
    icon: Icons.payment_rounded,
    color: Color(0xFF00838F),
    smsKeywords: ['paymax'],
  ),
  AccountPreset(
    id: 'hbl_konnect',
    name: 'HBL Konnect',
    type: AccountType.wallet,
    icon: Icons.phone_iphone_rounded,
    color: Color(0xFF00A651),
    smsKeywords: ['konnect', 'hbl konnect'],
  ),
  AccountPreset(
    id: 'ubl_omni',
    name: 'UBL Omni',
    type: AccountType.wallet,
    icon: Icons.phone_iphone_rounded,
    color: Color(0xFFC8102E),
    smsKeywords: ['ubl omni', 'omni'],
  ),

  // ── Commercial banks ──────────────────────────────────────
  AccountPreset(
    id: 'hbl',
    name: 'Habib Bank (HBL)',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF00A651),
    smsKeywords: ['hbl', 'habib bank limited', 'habib bank'],
  ),
  AccountPreset(
    id: 'ubl',
    name: 'United Bank (UBL)',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFFC8102E),
    smsKeywords: ['ubl', 'united bank limited', 'united bank'],
  ),
  AccountPreset(
    id: 'mcb',
    name: 'MCB Bank',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF0033A0),
    smsKeywords: ['mcb', 'mcb bank', 'muslim commercial'],
  ),
  AccountPreset(
    id: 'mcb_islamic',
    name: 'MCB Islamic',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF1565C0),
    smsKeywords: ['mcb islamic'],
  ),
  AccountPreset(
    id: 'mcb_arif',
    name: 'MCB Arif Habib',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF0D47A1),
    smsKeywords: ['arif habib', 'mcb arif'],
  ),
  AccountPreset(
    id: 'allied',
    name: 'Allied Bank (ABL)',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF00A3E0),
    smsKeywords: ['allied bank', 'abl', 'allied bank limited'],
  ),
  AccountPreset(
    id: 'nbp',
    name: 'National Bank (NBP)',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF006633),
    smsKeywords: ['nbp', 'national bank of pakistan', 'national bank'],
  ),
  AccountPreset(
    id: 'alfalah',
    name: 'Bank Alfalah',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFFED1C24),
    smsKeywords: ['alfalah', 'bank alfalah'],
  ),
  AccountPreset(
    id: 'bank_al_habib',
    name: 'Bank AL Habib',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF8B4513),
    smsKeywords: ['bank al habib', 'al habib', 'bah'],
  ),
  AccountPreset(
    id: 'habibmetro',
    name: 'Habib Metropolitan Bank',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF1ABC9C),
    smsKeywords: ['habib metro', 'habibmetro', 'habib metropolitan'],
  ),
  AccountPreset(
    id: 'askari',
    name: 'Askari Bank',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF2C3E50),
    smsKeywords: ['askari', 'askari bank'],
  ),
  AccountPreset(
    id: 'jsbank',
    name: 'JS Bank',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF9B59B6),
    smsKeywords: ['js bank', 'jsbank'],
  ),
  AccountPreset(
    id: 'soneri',
    name: 'Soneri Bank',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFFE67E22),
    smsKeywords: ['soneri', 'soneri bank'],
  ),
  AccountPreset(
    id: 'soneri_mustaqeem',
    name: 'Soneri Mustaqeem',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFFD35400),
    smsKeywords: ['mustaqeem'],
  ),
  AccountPreset(
    id: 'bop',
    name: 'Bank of Punjab (BOP)',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF8B0000),
    smsKeywords: ['bank of punjab', 'bop'],
  ),
  AccountPreset(
    id: 'bok',
    name: 'Bank of Khyber (BOK)',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF1A5276),
    smsKeywords: ['bank of khyber', 'bok', 'khayber'],
  ),
  AccountPreset(
    id: 'sindh_bank',
    name: 'Sindh Bank',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF117A65),
    smsKeywords: ['sindh bank'],
  ),
  AccountPreset(
    id: 'first_women',
    name: 'First Women Bank',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFFAD1457),
    smsKeywords: ['first women bank', 'fwbl'],
  ),
  AccountPreset(
    id: 'faysal',
    name: 'Faysal Bank',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF1B4F72),
    smsKeywords: ['faysal', 'faysal bank'],
  ),
  AccountPreset(
    id: 'silk',
    name: 'Silkbank',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF34495E),
    smsKeywords: ['silkbank', 'silk bank'],
  ),
  AccountPreset(
    id: 'samba',
    name: 'Samba Bank',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF2980B9),
    smsKeywords: ['samba'],
  ),
  AccountPreset(
    id: 'summit',
    name: 'Summit Bank',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF8E44AD),
    smsKeywords: ['summit bank'],
  ),
  AccountPreset(
    id: 'ztbl',
    name: 'ZTBL',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF2E7D32),
    smsKeywords: ['ztbl', 'zarai taraqiati'],
  ),
  AccountPreset(
    id: 'bank_of_ajk',
    name: 'Bank of AJK',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF00695C),
    smsKeywords: ['bank of ajk', 'ajk bank'],
  ),
  AccountPreset(
    id: 'idbp',
    name: 'IDBP',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF455A64),
    smsKeywords: ['idbp'],
  ),

  // ── Islamic ───────────────────────────────────────────────
  AccountPreset(
    id: 'meezan',
    name: 'Meezan Bank',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF6B2D5C),
    smsKeywords: ['meezan', 'meezan bank', 'neo islamic', 'neo mastercard'],
  ),
  AccountPreset(
    id: 'bankislami',
    name: 'BankIslami Pakistan',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF27AE60),
    smsKeywords: ['bankislami', 'bank islami'],
  ),
  AccountPreset(
    id: 'dubai_islamic',
    name: 'Dubai Islamic Bank Pakistan',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFFC0392B),
    smsKeywords: ['dubai islamic', 'dib', 'dubai islamic bank'],
  ),
  AccountPreset(
    id: 'albaraka',
    name: 'Al Baraka Bank Pakistan',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF16A085),
    smsKeywords: ['al baraka', 'albaraka'],
  ),

  // ── Foreign / international ───────────────────────────────
  AccountPreset(
    id: 'scb',
    name: 'Standard Chartered Pakistan',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF0072AA),
    smsKeywords: ['standard chartered', 'scb', 'stanchart'],
  ),
  AccountPreset(
    id: 'citi',
    name: 'Citibank Pakistan',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF003B70),
    smsKeywords: ['citibank', 'citi bank', 'citi'],
  ),
  AccountPreset(
    id: 'icbc',
    name: 'ICBC Pakistan',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFFC41E3A),
    smsKeywords: ['icbc', 'industrial and commercial bank of china'],
  ),
  AccountPreset(
    id: 'deutsche',
    name: 'Deutsche Bank AG',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF0018A8),
    smsKeywords: ['deutsche bank'],
  ),
  AccountPreset(
    id: 'mufg',
    name: 'MUFG Bank',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFFE60012),
    smsKeywords: ['mufg'],
  ),

  // ── Microfinance ──────────────────────────────────────────
  AccountPreset(
    id: 'mobilink_bank',
    name: 'Mobilink Bank',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF000000),
    smsKeywords: ['mobilink bank'],
  ),
  AccountPreset(
    id: 'finca',
    name: 'FINCA Microfinance Bank',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF0D47A1),
    smsKeywords: ['finca', 'finca microfinance'],
  ),
  AccountPreset(
    id: 'nrsp',
    name: 'NRSP Microfinance Bank',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF2E7D32),
    smsKeywords: ['nrsp', 'nrsp microfinance'],
  ),
  AccountPreset(
    id: 'khushhali',
    name: 'Khushhali Microfinance Bank',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF6A1B9A),
    smsKeywords: ['khushhali', 'khushali', 'khushhali microfinance'],
  ),
  AccountPreset(
    id: 'apna_mf',
    name: 'Apna Microfinance Bank',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFFE65100),
    smsKeywords: ['apna microfinance', 'apna bank'],
  ),
  AccountPreset(
    id: 'first_mf',
    name: 'First MicroFinance Bank',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF0277BD),
    smsKeywords: ['first microfinance'],
  ),
  AccountPreset(
    id: 'hbl_mf',
    name: 'HBL Microfinance Bank',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF00A651),
    smsKeywords: ['hbl microfinance'],
  ),
  AccountPreset(
    id: 'telenor_mf',
    name: 'Telenor Microfinance Bank',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF00A651),
    smsKeywords: ['telenor microfinance'],
  ),
  AccountPreset(
    id: 'u_mf',
    name: 'U MicroFinance Bank',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFFE53935),
    smsKeywords: ['u microfinance'],
  ),

  // ── Savings accounts (for goals / fixed deposits) ─────────
  AccountPreset(
    id: 'goal_savings',
    name: 'Savings account',
    type: AccountType.savings,
    icon: Icons.account_balance_outlined,
    color: Color(0xFF00C853),
  ),
  AccountPreset(
    id: 'sav_hbl',
    name: 'HBL Savings',
    type: AccountType.savings,
    icon: Icons.account_balance_outlined,
    color: Color(0xFF00A651),
    smsKeywords: ['hbl saving'],
  ),
  AccountPreset(
    id: 'sav_ubl',
    name: 'UBL Savings',
    type: AccountType.savings,
    icon: Icons.account_balance_outlined,
    color: Color(0xFFE31837),
    smsKeywords: ['ubl saving'],
  ),
  AccountPreset(
    id: 'sav_meezan',
    name: 'Meezan Savings',
    type: AccountType.savings,
    icon: Icons.account_balance_outlined,
    color: Color(0xFF6B2D5C),
  ),
  AccountPreset(
    id: 'sav_mcb',
    name: 'MCB Savings',
    type: AccountType.savings,
    icon: Icons.account_balance_outlined,
    color: Color(0xFF0033A0),
  ),
  AccountPreset(
    id: 'sav_alfalah',
    name: 'Bank Alfalah Savings',
    type: AccountType.savings,
    icon: Icons.account_balance_outlined,
    color: Color(0xFFED1C24),
  ),
  AccountPreset(
    id: 'sav_other',
    name: 'Other savings',
    type: AccountType.savings,
    icon: Icons.account_balance_outlined,
    color: Color(0xFF26A69A),
  ),

  // ── Credit cards ──────────────────────────────────────────
  AccountPreset(
    id: 'cc_visa',
    name: 'Visa Credit Card',
    type: AccountType.card,
    icon: Icons.credit_card_rounded,
    color: Color(0xFF1A1F71),
    smsKeywords: ['visa', 'credit card'],
  ),
  AccountPreset(
    id: 'cc_mastercard',
    name: 'Mastercard Credit Card',
    type: AccountType.card,
    icon: Icons.credit_card_rounded,
    color: Color(0xFFEB001B),
    smsKeywords: ['mastercard', 'master card'],
  ),
  AccountPreset(
    id: 'cc_hbl',
    name: 'HBL Credit Card',
    type: AccountType.card,
    icon: Icons.credit_card_rounded,
    color: Color(0xFF00A651),
    smsKeywords: ['hbl credit', 'hbl card'],
  ),
  AccountPreset(
    id: 'cc_ubl',
    name: 'UBL Credit Card',
    type: AccountType.card,
    icon: Icons.credit_card_rounded,
    color: Color(0xFFE31837),
    smsKeywords: ['ubl credit', 'ubl card'],
  ),
  AccountPreset(
    id: 'cc_meezan',
    name: 'Meezan Credit Card',
    type: AccountType.card,
    icon: Icons.credit_card_rounded,
    color: Color(0xFF6B2D5C),
    smsKeywords: ['meezan credit', 'neo mastercard'],
  ),
  AccountPreset(
    id: 'cc_alfalah',
    name: 'Bank Alfalah Credit Card',
    type: AccountType.card,
    icon: Icons.credit_card_rounded,
    color: Color(0xFFED1C24),
    smsKeywords: ['alfalah credit'],
  ),
  AccountPreset(
    id: 'cc_mcb',
    name: 'MCB Credit Card',
    type: AccountType.card,
    icon: Icons.credit_card_rounded,
    color: Color(0xFF0033A0),
    smsKeywords: ['mcb credit'],
  ),
  AccountPreset(
    id: 'cc_other',
    name: 'Other credit card',
    type: AccountType.card,
    icon: Icons.credit_card_rounded,
    color: Color(0xFF5C6BC0),
  ),

  // ── Fallback ──────────────────────────────────────────────
  AccountPreset(
    id: 'other_bank',
    name: 'Other bank',
    type: AccountType.bank,
    icon: Icons.account_balance_rounded,
    color: Color(0xFF636E72),
  ),
  AccountPreset(
    id: 'other_wallet',
    name: 'Other wallet',
    type: AccountType.wallet,
    icon: Icons.account_balance_wallet_outlined,
    color: Color(0xFF636E72),
  ),
];

AccountPreset presetById(String id) {
  return accountPresets.firstWhere(
    (c) => c.id == id,
    orElse: () => accountPresets.first,
  );
}

String typeLabel(AccountType type) => switch (type) {
      AccountType.cash => 'Cash',
      AccountType.bank => 'Bank',
      AccountType.wallet => 'Wallet',
      AccountType.card => 'Credit card',
      AccountType.savings => 'Savings',
      AccountType.person => 'Person',
    };

IconData typeIcon(AccountType type) => switch (type) {
      AccountType.cash => Icons.payments_rounded,
      AccountType.bank => Icons.account_balance_rounded,
      AccountType.wallet => Icons.account_balance_wallet_rounded,
      AccountType.card => Icons.credit_card_rounded,
      AccountType.savings => Icons.account_balance_outlined,
      AccountType.person => Icons.person_rounded,
    };

/// Match SMS body to a preset bank/wallet.
String? matchPresetFromSms(String text) {
  final lower = text.toLowerCase();
  final sorted = [...accountPresets]
    ..sort(
      (a, b) => b.smsKeywords
          .fold(0, (s, k) => s + k.length)
          .compareTo(a.smsKeywords.fold(0, (s, k) => s + k.length)),
    );
  for (final p in sorted) {
    for (final k in p.smsKeywords) {
      if (k.isNotEmpty && lower.contains(k)) return p.id;
    }
  }
  return null;
}

/// Convenience: logo asset for a preset, if any.
String? logoForPreset(String presetId) => bankLogoAsset(presetId);
