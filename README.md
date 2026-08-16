# 💰 Expens  Personal Finance & Expense Tracker

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-brightgreen?style=for-the-badge&logo=android)](https://flutter.dev)
[![Privacy](https://img.shields.io/badge/Privacy-100%25%20Offline%20%26%20Private-success?style=for-the-badge&logo=shield)](https://github.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)

Expens is a modern, privacy-first, offline-first personal finance app built with Flutter. Designed specifically for effortless expense, income, budget, loan, and portfolio management with automated Pakistani Bank & Mobile Wallet SMS import capabilities.

## 🌟 Key Highlights

- **100% Private & Offline**: No cloud servers, no sign-ups, no data tracking. Everything stays on your device.
- **Smart Bank SMS Import**: Copy bank transaction SMS alerts (HBL, Meezan, UBL, JazzCash, EasyPaisa, etc.) and automatically parse the amount, merchant, date, and category.
- **Multi-Account & Debt Tracking**: Keep tabs on bank accounts, cash, credit cards, and track money borrowed or lent.
- **Group Trip & Event Splitter**: Organise shared expenses for trips or events with friends and family.
- **Biometric & PIN Security**: Protect your data using Fingerprint, Face ID, or a custom PIN.

---

## ⚡ Main Features

- **Dashboard**: Net worth overview, monthly expense donut chart, and recent transactions.
- **Money & Accounts**: Track balances and detailed inflow/outflow ledgers per bank/wallet.
- **SMS Parser**: Paste bank SMS text to instantly log transactions without manual entry.
- **Loans & Borrowing**: Record lent/borrowed money with payment history and balance tracking.
- **Budgets & Goals**: Set monthly category limits and target savings goals with progress tracking.
- **Events**: Track trip or event group expenses.
- **Backup & Restore**: Export and import full data backups as JSON.
- **Themes**: Material 3 dark and light modes.

---

## 📱 Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (Dart SDK `^3.10.1`)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Charts**: [fl_chart](https://pub.dev/packages/fl_chart)
- **Security**: `local_auth` & `flutter_secure_storage`
- **UI**: Material 3 & Google Fonts

---

## 🚀 How to Run

### Prerequisites
Make sure you have Flutter installed (`>= 3.10.1`).

### Setup Commands

```bash
# 1. Clone repo
git clone https://github.com/abdulmuteenkhan24/Expens.git
cd Expens

# 2. Install dependencies
flutter pub get

# 3. Launch application
flutter run
```

---

## Supported Banks & Wallets (SMS Auto-Import)

The built-in parser handles SMS transaction alerts from:
- Meezan Bank
- Habib Bank Limited (HBL)
- United Bank Limited (UBL)
- MCB Bank
- Bank Alfalah / Askari Bank / Allied Bank
- JazzCash / EasyPaisa
- SadaPay / NayaPay
- Visa & MasterCard debit/credit card alerts

---

## 📄 License

This project is open-source under the MIT License.
