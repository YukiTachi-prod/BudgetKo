# TASKo - A Versatile Task Management App

**TASKo** is a powerful and intuitive task management application built with Flutter, designed to help you organize your daily activities, manage deadlines, and boost your productivity.

## Features

- **Comprehensive Task Management**: Easily create, edit, and delete tasks. Each task supports a title, description, due date, category, and status.
- **Dynamic Filtering**: Organize your view by filtering tasks based on their current status (e.g., Not Started, Ongoing, Finished, Dropped) or category.
- **Smart Local Notifications**: Stay on top of your deadlines with integrated daily reminders for upcoming tasks.
- **Robust Data Persistence**: Your tasks and settings are securely saved locally using `SharedPreferences`.
- **Import/Export Functionality**: Effortlessly manage your data externally for backups or sharing.
- **Integrated PDF Viewer**: View PDF documents directly within the app (e.g., for task attachments).
- **Dark Mode Support**: Enjoy a comfortable viewing experience in any environment with a fully integrated dark theme.
- **Built-in Budget Calculator**: An integrated wallet and ledger system to manage your personal finances. Track your income, expenses, and inter-account transfers seamlessly alongside your tasks.

## Technical Highlights

Built with a modern Flutter architecture, TASKo leverages the **Provider** package for efficient state management, ensuring a clean separation of concerns.

- **Models**: Clearly defined data structures for `Task` and other entities.
- **Providers**: `TaskProvider`, `SettingsProvider`, and `LedgerProvider` centralize state, handling data manipulation and UI updates.
- **Services**: Dedicated services like `NotificationService` and `ImportExportService` manage system-level interactions and data portability.
- **Screens**: A rich set of screens including Dashboard, Settings, Task Editing, PDF Viewer, Analytics, and Budget.
- **Database**: Drift-powered SQLite database (`BudgetDatabase`) for robust ledger transactions and account tracking.
- **Function Map & Architecture Guide**: Complete symbol directory, architecture data flow, and fast lookup table available in [FUNCTION_MAP.md](FUNCTION_MAP.md).

## Recent Updates

We are continuously improving TASKo to enhance your experience:

- **Group Wallet & Collective Budget (Supabase Sync)**: A dedicated shared wallet window and tab allowing groups to view their collective budget. Members create a locally held profile, connect a Supabase project via API key, auto-verify or generate database tables, and track shared contributions, expenses, and member shares.
- **In-App Notification Center**: A brand-new notification bell and sliding drawer accessible from the top app bar for seamless tracking and management of app alerts.
- **Granular Budgeting**: Categories now support **Daily** and **Weekly Budget Limits** in addition to monthly limits, empowering you with precise control over your spending.
- **Precise Expense Timestamps**: The expenses tab now displays exact transaction times, intelligently falling back to just the date for time-less entries.
- **App Theme Customization & Centered Layouts**: Centered the top app bar titles for the main screens and Wallet view. The back button inside the Wallet screen now displays the Notes/Tasks description icon in the user's chosen primary color. Additionally, a new **Button Color Scheme** picker in Settings allows full app-wide custom button color customization.
- **Fully Customizable Color Pickers**: Installed `flutter_colorpicker`, replacing simple color chips with an interactive color wheel, HSV/RGB sliders, and Hex code editor across Statuses, Wallet Accounts, and Categories.
- **Negative Balance Protection**: The app now prevents any transaction (expense or transfer) from dropping an account balance below zero, warning the user and blocking saving if triggered.
- **Four-Tab Wallet System**: Renamed the "Budget Calculator" to "Wallet" and reorganized it into a 4-tab interface:
    - **Wallet**: View total balance, account chips, category chips, and recent transactions highlighted subtly (opacity `0.08`) in category colors.
    - **Expenses**: A dedicated tab containing the "All Expenses" DataTable with custom-colored account/category tags, driven by independent date range filters.
    - **Loans & Subs**: A dedicated tab to track active Loans/Debts (amounts, remaining balances, due dates, pay-from accounts, notes) and Subscriptions/Bills (cycle, cost, next bill date, active status) using custom-colored account badges.
    - **Analytics**: Displays a combined positive Account Balances Donut Chart, Category Expenses Donut Chart, Monthly limit progress indicators (styled in category colors), and summary statistics for Loans (total borrowed/remaining, payoff progress bar) and Subscriptions (active count, est. monthly cost, upcoming bill alerts).
- **Android Focus**: Streamlined codebase prioritizing Android, removing previous web-specific support to focus on mobile perfection.
- **Enhanced Stability**: Critical bug fixes address `TaskEditScreen` loading failures with empty categories/statuses, now gracefully handling defaults.
- **Wallet Backgrounds Management**: Added a dedicated `Saved Backgrounds` gallery in Settings to view, select, and safely batch-delete custom account backgrounds without leaving orphaned files. Importing background packages now intelligently warns against overwriting existing files.
- **Refined Wallet UI**: Account cards now feature a precise 30%-width right-aligned sub-container for account names and amounts. Amounts use standard font weights for a cleaner look, matching a newly bundled `Format.png` export template.
- **Expenses Zoom Controls**: The "All Expenses" table now features dedicated manual Zoom-In and Zoom-Out floating buttons. These buttons are elegantly styled with the app's primary color and positioned perfectly above the main 'Add Transaction' button, providing full control to scale and horizontally scroll your transaction history smoothly.
- **Safe Deletions**: Confirmation dialogs added for deleting Categories and Statuses in `SettingsScreen` to prevent accidental data loss.
- **Flexible Status System**: Replaced the 'Priority' system with a more versatile 'Status' system (Not Started, Ongoing, Finished, Dropped).
- **Toggleable Task Dates**: Tasks can now optionally omit Start/End dates, creating simple to-do items without scheduling urgency or alarms.
- **Improved UI/UX**: Replaced custom property chips with sleek dropdown menus for task creation, and added deletion confirmation dialogs.
- **Analytics Dashboard**: A new Analytics screen (accessible via Settings) provides valuable insights into task distribution by status and category.
- **Intuitive Visual Indicators**: Task tiles are now color-coded based on deadlines:
    - **Dim Red**: Tasks due today or overdue.
    - **Dim Yellow**: Tasks due within 3 days.
    - **Dim Green**: Finished tasks.
- **Optimized Notifications & Alarms**: Refined reminder system fires at strategic intervals. Restructured alarm triggers, removed redundant Routine options, and introduced custom repeating ring intervals (e.g., Ring every X minutes). Plus, configure custom `.wav` alarm sounds in the settings for high-priority tasks! Background/notification permissions are elegantly requested only when required.
- **Heatmap View**: A GitHub-commit-style task visualization grid showing the intensity of tasks finished across days and weeks, where color opacity scales with productivity. Access it via a two-finger squeeze gesture or the grid icon in the top bar!
- **Customizable Status Colors**: Easily pick unique colors for your task statuses via the Settings screen using our built-in color picker.
- **Task Creation Overhaul**: Form fields and dropdowns are now cleaner and half-width for better use of space. Missing required fields (like Title) intelligently prompt you with warning popups. Background and notification permissions are smartly and gracefully requested only when actually needed.
- **Developer Settings**: Locked behind a developer password (`jaceywashere`), includes advanced notification testing tools and a handy "Insert 50 Test Tasks" utility.


## Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

Ensure you have Flutter installed. If not, follow the instructions on the [Flutter official website](https://flutter.dev/docs/get-started/install).

### Installation

1. Clone the repo:
   ```bash
   git clone https://github.com/your-username/tasker.git # Replace with actual repo URL
   ```
2. Navigate to the project directory:
   ```bash
   cd tasker
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

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
| **Overview Dashboard** | [`lib/screens/main_tab.dart`](lib/screens/main_tab.dart) | `MainTab` (Total Balance, Cash Flow, Accounts Overview, Recent Activity) |
| **All Expenses Table & Zoom** | [`lib/screens/expenses_tab.dart`](lib/screens/expenses_tab.dart) | `ExpensesTab` (`DataTable`, date filter, zoom controls) |
| **Debts & Subscriptions UI** | [`lib/screens/loans_and_subscriptions_tab.dart`](lib/screens/loans_and_subscriptions_tab.dart) | `LoansAndSubscriptionsTab` |
| **Analytics Dashboard & Charts** | [`lib/screens/budget_analytics_screen.dart`](lib/screens/budget_analytics_screen.dart), [`lib/widgets/budget_analytics.dart`](lib/widgets/budget_analytics.dart) | `BudgetAnalyticsTab`, `BudgetAnalytics`, `FullScreenDonutChart` |
| **Transaction Entry & Numpad** | [`lib/screens/transaction_entry_screen.dart`](lib/screens/transaction_entry_screen.dart) | `TransactionEntryScreen` (numpad, negative balance block) |
| **Settings UI** | [`lib/screens/settings_screen.dart`](lib/screens/settings_screen.dart) | `SettingsScreen` |
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


