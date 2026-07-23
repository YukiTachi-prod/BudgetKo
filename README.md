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

## Recent Updates

We are continuously improving TASKo to enhance your experience:

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

**CRITICAL RULE FOR ALL AI AGENTS:** Before declaring any task as finished, you MUST run the following commands to ensure code quality and consistency:

1. `dart format .` (to format all code)
2. `flutter analyze` (to check for any linting errors or warnings)

Do not complete your turn until these commands pass successfully or you have explicitly addressed any issues they raise.
