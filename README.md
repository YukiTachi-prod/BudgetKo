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

- **Android Focus**: Streamlined codebase prioritizing Android, removing previous web-specific support to focus on mobile perfection.
- **Enhanced Stability**: Critical bug fixes address `TaskEditScreen` loading failures with empty categories/statuses, now gracefully handling defaults.
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
- **Wallet & Ledger System**: Introduced a new Budget Screen accessible from the main navigation. Create, edit, and delete accounts and categories. Log income/expenses and transfer funds using a fully integrated Drift-based SQLite database. Swipe between a dynamic interactive Donut Chart and a rigid Line Chart to track expenses over specific Week, Month, and Year periods.
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
