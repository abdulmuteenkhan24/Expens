# 💰 Expens — Personal Finance & Expense Tracker

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-brightgreen?style=for-the-badge&logo=android)](https://flutter.dev)
[![Privacy](https://img.shields.io/badge/Privacy-100%25%20Offline%20%26%20Private-success?style=for-the-badge&logo=shield)](https://github.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)

**Expens** is a modern, privacy-first, offline-first personal finance app built with **Flutter**. Designed specifically for effortless expense, income, budget, loan, and portfolio management with automated Pakistani Bank & Mobile Wallet SMS import capabilities.

---

## ✨ Features Overview

### 📊 Dashboard & Financial Insights
- **Net Worth Overview**: Instant visibility into "What You Have" across all cash, bank accounts, and credit cards.
- **Interactive Visualizations**: Powered by `fl_chart` with monthly donut expense breakdowns, category spend distributions, and income vs. expense analytics.
- **Quick Action Bar**: Fast logging for Expenses, Income, Transfers, and SMS Imports.

### 📩  Bank SMS Auto-Import
- **Regex-Based Smart Parser**: Automatically parses transaction SMS messages from major Pakistani banks and mobile wallets.
- **Supported Institutions**: Meezan Bank, HBL, UBL, MCB, Bank Alfalah, Askari Bank, Allied Bank, JazzCash, EasyPaisa, SadaPay, NayaPay, and generic Debit/Credit cards.
- **Data Extracted**: Amount (PKR), vendor/merchant, location/ATM branch, card ending (last 4 digits), transaction date/time, and auto-category assignment.

### 🏦 Multi-Account & Wallet Management
- **Presets & Custom Accounts**: Pre-configured logos and brand colors for local banks and digital wallets.
- **Account Ledger**: Full inflow/outflow transaction history for each bank, wallet, or cash account.

### 🤝 Loans & Debt Management
- **Borrow & Lend Tracker**: Keep track of money lent to friends/family or borrowed loans.
- **Repayment History**: Log partial payments, track remaining balances, and set due dates.

### ✈️ Events & Group Expense Splitter
- **Trip & Event Budgeting**: Group expenses for vacations, weddings, or shared projects.
- **Participant Ledger**: View shared expenses and split costs transparently.

### 🎯 Budgets & Savings Goals
- **Category Monthly Limits**: Set spending caps per category with visual progress bars and over-budget warnings.
- **Target Savings Goals**: Plan savings targets (e.g., Emergency Fund, New Phone, Travel) with deadline countdowns.

### 📈 Investment Portfolio
- **Asset Classes**: Track investments in Stocks, Mutual Funds, Gold, Crypto, and Real Estate.

### 🔒 Security & Privacy First
- **100% Offline & Private**: Your financial data stays entirely on your local device. No external servers or telemetry.
- **Biometric & PIN Protection**: Secure access via Fingerprint / Face ID (`local_auth`) and encrypted PIN authentication (`flutter_secure_storage`).
- **Auto-Lock Security**: Re-locks the application automatically after background inactivity.

### 💾 Backup & Data Portability
- **JSON Export & Import**: Backup your entire financial dataset to a JSON file and restore anytime.
- **Receipt Attachments**: Pick images and attach receipts to transactions.

---

## 🛠️ Tech Stack & Architecture

- **Framework**: [Flutter](https://flutter.dev) (Dart SDK `^3.10.1`)
- **State Management**: [Provider](https://pub.dev/packages/provider) (`ChangeNotifier`, `Consumer2`)
- **Charts & Visualizations**: [fl_chart](https://pub.dev/packages/fl_chart)
- **Security & Storage**:
  - `flutter_secure_storage` (Encrypted Key Vault)
  - `local_auth` (Biometrics / Face ID / Fingerprint)
  - `shared_preferences` & Local JSON Storage
- **UI & Styling**: Material Design 3, `google_fonts`, `cupertino_icons`
- **Utilities**: `intl`, `uuid`, `crypto`, `image_picker`, `file_picker`, `share_plus`

---

## 📂 Project Structure

```text
lib/
├── bank-logos/        # Pre-configured assets and bank logos
├── data/              # Categories, account presets, bank mappings, currencies
├── models/            # Data models (Account, Expense, Income, Loan, Goal, Event, Budget, etc.)
├── providers/         # Global AppState & AuthState (Provider architecture)
├── screens/           # UI Screens (Dashboard, Money, Accounts, Loans, Events, Goals, SMS Import, Security)
├── services/          # Services (SmsParser, AuthService, BackupService, ReceiptService)
├── theme/             # Material 3 light & dark theme definitions
├── utils/             # Formatters, helpers, and extension methods
├── widgets/           # Custom reusable UI components, cards, charts, and pickers
└── main.dart          # App entry point, lifecycle observer & multi-provider bootstrap
```

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed on your machine:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.10.1`)
- [Dart SDK](https://dart.dev/get-dart)
- Android Studio / Xcode (for device emulation and build tools)
- Git

### Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/expens.git
   cd expens
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate App Launcher Icons (Optional)**
   ```bash
   dart run flutter_launcher_icons
   ```

4. **Run the App**
   ```bash
   # Run on connected mobile device or emulator
   flutter run
   ```

5. **Build Release APK (Android)**
   ```bash
   flutter build apk --release
   ```

---

## 📱 App Navigation Map

| Tab / Section | Description |
| :--- | :--- |
| 🏠 **Home** | Net worth overview, monthly expense donut chart, quick actions, recent activity |
| 💵 **Money** | Monthly transaction logs, category filters, ATM withdrawals, transfer sheets |
| ➕ **Add Flow** | Multi-step dialog to quickly add Expense, Income, Transfer, or Loan |
| 🤝 **Loans** | Active borrowed/lent money management and repayment records |
| 📈 **Insights** | Visual analytics, charts, category spending trends, and reports |
| 🎯 **Goals & Budgets** | Set category limits and track target date savings goals |
| 📩 **SMS Import** | Parse clipboard bank SMS notifications into expense records |
| ⚙️ **Settings** | Theme switching (Light/Dark), Security PIN/Biometrics, JSON Data Backup/Restore |

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!
Feel free to check out the [Issues page](../../issues) if you want to contribute.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.
