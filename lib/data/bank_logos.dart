/// Asset paths for logos in `lib/bank-logos/`.
const String bankLogosDir = 'lib/bank-logos';

/// Map presetId → asset file name (inside [bankLogosDir]).
const Map<String, String> bankLogoFiles = {
  // Major banks
  'hbl': 'HBL.png',
  'ubl': 'UBL.png',
  'mcb': 'MCB.png',
  'mcb_islamic': 'MCB - Islamic.png',
  'mcb_arif': 'MCB - Airf Habib.png',
  'allied': 'Allied Bank.png',
  'nbp': 'National Bank.png',
  'nbp_funds': 'NBP Funds.png',
  'alfalah': 'Bank Alfalah.png',
  'bank_al_habib': 'Bank Al Habib.png',
  'habibmetro': 'Habib Metro.png',
  'askari': 'Askari Bank.png',
  'jsbank': 'JS Bank.png',
  'soneri': 'Soneri Bank.png',
  'soneri_mustaqeem': 'Soneri Mustaqeem.png',
  'bop': 'Bank of Punjab.png',
  'bok': 'Bank of Khayber.png',
  'sindh_bank': 'Sindh Bank.png',
  'first_women': 'First Women Bank.png',
  'faysal': 'Faysal Bank.png',
  'meezan': 'Meezan Bank.png',
  'bankislami': 'Bank Islami.png',
  'dubai_islamic': 'Dubai Islamic Bank.png',
  'albaraka': 'ALBarakh.png',
  'scb': 'Standard Chartered.png',
  'citi': 'Citi Bank.png',
  'icbc': 'ICBC.png',
  'samba': 'Samba Bank.png',
  'summit': 'Summit Bank.png',
  'silk': 'SILK Bank.png',
  'ztbl': 'ZTBL.png',
  'bank_of_ajk': 'Bank of AJK.png',
  'idbp': 'IDBP.png',
  'deutsche': 'Deutsche Bank AG.png',
  'mufg': 'MUFG.png',
  // Wallets / fintech
  'jazzcash': 'Jazz Cash.png',
  'easypaisa': 'Easy Paisa.png',
  'sadapay': 'Sada Pay.png',
  'nayapay': 'Naya Pay.png',
  'zindigi': 'Zindigi.png',
  'upaisa': 'U Paisa.png',
  'keenu': 'Keenu.png',
  'finja': 'Finja.png',
  'paymax': 'PayMax.png',
  'aft': 'AFT.png',
  // Microfinance
  'finca': 'Finca Mirofinance.png',
  'nrsp': 'NRSP Microfinance Bank.png',
  'nrsp_alt': 'NRSP.png',
  'khushhali': 'Khushali Micorfinance Bank.png',
  'apna_mf': 'Apna Mirofinance Bank.png',
  'first_mf': 'First MicroFinance Bank Pakistan.png',
  'hbl_mf': 'HBL MF Bank.png',
  'telenor_mf': 'Telenor Microfinance Bank.png',
  'u_mf': 'U MicroFinance Bank.png',
  // Mobile bank / alias
  'mobilink_bank': 'Jazz Cash.png',
  'hbl_konnect': 'HBL.png',
  'ubl_omni': 'UBL.png',
};

String? bankLogoAsset(String presetId) {
  final file = bankLogoFiles[presetId];
  if (file == null) return null;
  return '$bankLogosDir/$file';
}
