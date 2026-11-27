# BudgetKo — Personal & Group Finance App

**BudgetKo** is a minimalist personal and group budgeting application built with Flutter. It helps you track accounts, daily/weekly/monthly budgets, expenses, loans, subscriptions, shared group wallets, and quick temporary group pools for splitting bills with friends.

## Features

- **5-Tab Personal Finance Dashboard**:
  - **Main**: Overview hero card with total balance (privacy-masked by default), income vs. expense summary, quick links to Group Wallet & Temporary Group Pool, accounts overview, and recent activity.
  - **Wallet**: Manage multiple accounts (banks, e-wallets, cash) with custom colors, minimum-balance warnings, custom categories with Daily/Weekly/Monthly limits, and recent transactions.
  - **Expenses**: Dedicated sortable/filterable expenses table with date range filters, custom-colored account/category tags, precise timestamps, and zoom controls.
  - **Loans & Subs**: Track active loans/debts (amounts, remaining balances, due dates, pay-from accounts, notes) and recurring subscriptions/bills (billing cycle, cost, next due date, active status).
  - **Analytics**: Account balance and category expense donut charts, budget limit progress indicators, and loan/subscription summaries.
- **Fast Transaction Entry**: Built-in calculator/math-expression numpad (`parseAmount`), custom color pickers, and negative-balance protection to prevent overdrafts.
- **Temporary Group Pool**: Completely isolated temporary wallets for eating out or group purchases where one person pays — featuring a large circular money pool total, unique or equal-split amounts per person, **Cash / E-Cash** (+ custom) payment categories, per-person notes, automatic change-back / still-owed calculation, and Delete + Confirm protection.
- **Group Wallet (Supabase Sync)**: Shared collective wallets backed by Supabase. Create a local profile, connect your Supabase project, auto-verify or copy the SQL schema, and track group contributions, expenses, and member shares.
- **In-App Notification Center & Reminders**: Sliding notification drawer for low-balance warnings, budget alerts, and upcoming loan/subscription due dates.
- **CSV Export**: Export your personal ledger to CSV for backups or spreadsheet analysis.
- **Warm Minimalist Theme**: Light & Dark modes, customizable accent/button color picker, font size scaling, multi-currency selector, and privacy balance masking.

## Technical Highlights

Built with Flutter and **Provider** for clean state management:

- **Database**: Drift-powered SQLite (`BudgetDatabase`) for personal accounts, categories, transactions, loans, and subscriptions.
- **Local Preferences & Isolated Storage**: `SharedPreferences` for app settings, notifications, local group profile, and isolated Temporary Group Pools.
- **Cloud Sync (Optional)**: `supabase_flutter` for collaborative Group Wallets.
- **Function Map & Architecture Guide**: Complete symbol directory, architecture data flow, and fast lookup table available in [FUNCTION_MAP.md](FUNCTION_MAP.md).

## Getting Started

### Prerequisites

Ensure you have Flutter installed. See the [Flutter installation guide](https://flutter.dev/docs/get-started/install).

### Installation

1. Clone the repo:
   ```bash
   git clone https://github.com/YukiTachi-prod/TASKo.git
   ```
2. Navigate to the project directory:
   ```bash
   cd TASKo
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```
5. Build a release APK:
   ```bash
   flutter build apk --release
   ```

## Development Instructions for AI Agents

> [!IMPORTANT]
> **ALWAYS CONSULT THE FUNCTION MAP FIRST**: Do not burn tokens running recursive grep, search commands, or reading files blindly. The entire architecture, file layout, class hierarchy, method signatures, database schemas, and data flow are mapped in **[FUNCTION_MAP.md](FUNCTION_MAP.md)**.

### Quick Lookup for Agents

| To Work On... | Check File | Primary Symbols |
| :--- | :--- | :--- |
| **App Startup & Providers** | [`lib/main.dart`](lib/main.dart) | `main()`, `BudgetKoApp`, `MultiProvider` |
| **Database Tables & Migrations** | [`lib/database/budget_database.dart`](lib/database/budget_database.dart) | `BudgetDatabase`, `Accounts`, `Categories`, `Transactions`, `Loans`, `Subscriptions` |
| **Accounts, Transactions, Loans & Subs** | [`lib/providers/ledger_provider.dart`](lib/providers/ledger_provider.dart) | `LedgerProvider` (`accounts`, `categories`, `transactions`, `loans`, `subscriptions`, CRUD & balance math) |
| **Appearance & Preferences** | [`lib/providers/settings_provider.dart`](lib/providers/settings_provider.dart) | `SettingsProvider` (`isDarkMode`, `currency`, `themeColor`, `hideTotalAmount`, `fontSize`) |
| **In-App Alerts & Warnings** | [`lib/providers/notification_provider.dart`](lib/providers/notification_provider.dart) | `NotificationProvider`, `checkLedgerWarnings()` |
| **OS Notifications & Alarms** | [`lib/services/notification_service.dart`](lib/services/notification_service.dart) | `NotificationService` |
| **CSV Export** | [`lib/services/export_service.dart`](lib/services/export_service.dart) | `DataExportService.exportLedgerToCsv()` |
| **Math Expression Evaluator** | [`lib/utils/math_util.dart`](lib/utils/math_util.dart) | `parseAmount(String input)` |
| **Theme & Design Tokens** | [`lib/theme/app_theme.dart`](lib/theme/app_theme.dart) | `AppTheme.light()`, `AppTheme.dark()`, `AppTheme.categoryColor()` |
| **Main 5-Tab Scaffold** | [`lib/screens/budget_screen.dart`](lib/screens/budget_screen.dart) | `BudgetScreen` (Main, Wallet, Expenses, Loans & Subs, Analytics) |
| **Overview Dashboard** | [`lib/screens/main_tab.dart`](lib/screens/main_tab.dart) | `MainTab` (Total Balance, Cash Flow, Group Wallet & Temp Pool cards, Accounts Overview, Recent Activity) |
| **All Expenses Table & Zoom** | [`lib/screens/expenses_tab.dart`](lib/screens/expenses_tab.dart) | `ExpensesTab` (`DataTable`, date filter, zoom controls) |
| **Debts & Subscriptions UI** | [`lib/screens/loans_and_subscriptions_tab.dart`](lib/screens/loans_and_subscriptions_tab.dart) | `LoansAndSubscriptionsTab` |
| **Analytics Dashboard & Charts** | [`lib/screens/budget_analytics_screen.dart`](lib/screens/budget_analytics_screen.dart), [`lib/widgets/budget_analytics.dart`](lib/widgets/budget_analytics.dart) | `BudgetAnalyticsTab`, `BudgetAnalytics`, `FullScreenDonutChart` |
| **Transaction Entry & Numpad** | [`lib/screens/transaction_entry_screen.dart`](lib/screens/transaction_entry_screen.dart) | `TransactionEntryScreen` (numpad, negative balance block) |
| **Settings UI** | [`lib/screens/settings_screen.dart`](lib/screens/settings_screen.dart) | `SettingsScreen` |
| **Temporary Group Pool** | [`lib/screens/temp_group_pool_screen.dart`](lib/screens/temp_group_pool_screen.dart), [`lib/providers/temp_group_pool_provider.dart`](lib/providers/temp_group_pool_provider.dart), [`lib/models/temp_group_pool_models.dart`](lib/models/temp_group_pool_models.dart) | `TempGroupPoolScreen`, `TempGroupPoolProvider`, `TempGroupPool`, `TempPoolParticipant` |
| **Group Wallet & Collective Budget** | [`lib/screens/group_wallet_screen.dart`](lib/screens/group_wallet_screen.dart), [`lib/providers/group_wallet_provider.dart`](lib/providers/group_wallet_provider.dart) | `GroupWalletScreen`, `GroupWalletTab`, `GroupWalletProvider`, `GroupProfile`, `GroupTransaction` |
| **Supabase Setup Scripts** | [`supabase_schema.sql`](supabase_schema.sql), [`lib/database/supabase_schema.sql`](lib/database/supabase_schema.sql) | DDL schema for `group_wallets`, `group_members`, `group_transactions`, RLS |

> [!NOTE]
> **Active vs. Archived Code**: All active application code lives in `lib/`. The `tasko_pivot/` directory contains archived legacy task management code from before the pivot. Do not modify `tasko_pivot/` unless explicitly instructed to restore legacy task features.

### Quality Assurance Rules

**CRITICAL RULE FOR ALL AI AGENTS:** Before declaring any task as finished, you MUST run the following commands to ensure code quality and consistency:

1. `dart format .` (to format all code)
2. `flutter analyze` (to check for any linting errors or warnings)
3. `flutter test` (to ensure all unit and widget tests pass)

Do not complete your turn until these commands pass successfully or you have explicitly addressed any issues they raise.
