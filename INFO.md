# TASKo App Information

## App Description

**TASKo** is a versatile and efficient task management application built with **Flutter**. It is designed to help users organize their daily activities, manage deadlines, and stay productive through a clean and intuitive interface.

### Core Features

- **Dual-Date Task Management**: Create tasks with specific **Start** and **End** date/times for precise scheduling.
- **Routines (Repeating Tasks)**: Dedicated support for recurring activities (Daily, Weekly, Monthly) with a specialized viewing tab.
- **Task Locking**: Secure your tasks by locking them; once saved and locked, only the status can be updated, preventing accidental modifications to titles or dates.
- **Bulk Operations**: Multi-selection mode on the dashboard allows for quick deletion of multiple tasks at once.
- **Unique Title Enforcement**: Prevents organization clutter by ensuring no two tasks share the same title.
- **Dynamic Filtering**: Organize your view by filtering tasks based on their current status, category, or specific dates.
- **Local Notifications**: Integrated reminders for upcoming task deadlines, now synced with the new End Date structure.
- **Flexible Time Picking**: Users can choose between a circular dial or a numeric/keyboard input (default) for time selection.
- **Import/Export**: Robust Markdown-based import/export system via ZIP files, supporting all new task fields (Start/End dates, locking, routine status).
- **Dark Mode Support**: A fully integrated dark theme, including a theme-aware bottom navigation bar.

### Technical Architecture

The app follows a modern Flutter architecture using the **Provider** package for state management, ensuring a clean separation between business logic and the user interface.

- **Models**: Defines the data structures (e.g., `Task`) used throughout the application.
- **Providers**: `TaskProvider` and `SettingsProvider` act as the central state containers.
- **Services**: `NotificationService` handles reminders, and `ImportExportService` manages data portability.
- **Screens**: Includes Dashboard, Routines, Settings, Task Editing, Analytics, and PDF Viewer.

### Recent Updates

- **Navigation Overhaul**: Implemented a **Bottom Navigation Bar** (tabular UI) for seamless switching between Dashboard, Routines, and Settings.
- **Visual Refresh**: Updated the default light mode background to pure white with high-contrast text. The `SplashScreen` has also been updated to a pure white background with a snappier 1-second duration.
- **Status & Locking Logic**: Integrated a "Lock" feature in the `TaskEditScreen`. When enabled, core task details are disabled in the UI to preserve data integrity.
- **Bulk Delete**: Added a long-press gesture on task tiles to enter **Multi-selection Mode**, enabling the "Delete All Selected" functionality.
- **Time Picker Optimization**: Fixed a bug where the time picker ignored the 24-hour format setting. It now correctly displays AM/PM when 24-hour format is disabled.
- **Architecture Maintenance**:
    - Migration: Updated the `Task` model and all related services to handle the transition from a single `date` field to separate `startDate` and `endDate` fields.
    - Code Quality: Resolved all `flutter analyze` issues, including removing unused imports and replacing deprecated `.withOpacity()` calls with `.withValues()`.
    - Dependencies: Added the `uuid` package for robust unique ID generation.

### Coding Standards

- **Variable Naming**: Standard Dart **camelCase**.
- **Class Naming**: **PascalCase**.
- **Theming**: Use `Theme.of(context)` values rather than hardcoded colors where possible to maintain Dark/Light mode compatibility.

---

## Project Structure (Key Files)

```text
lib/
├── models/
│   └── task.dart (Updated with Start/End dates, locking, and routine fields)
├── providers/
│   ├── settings_provider.dart (Includes time picker style and persistence)
│   └── task_provider.dart (Bulk delete, title uniqueness, and routine filters)
├── screens/
│   ├── dashboard_screen.dart (Multi-selection UI)
│   ├── routines_screen.dart (NEW: Tab for repeating tasks)
│   ├── main_screen.dart (Bottom navigation container)
│   ├── task_edit_screen.dart (Locking, routines, and dual-date inputs)
│   └── splash_screen.dart (Standardized white background)
├── services/
│   ├── import_export_service.dart (Markdown parser for new task fields)
│   └── notification_service.dart (Deadline-based reminder logic)
└── main.dart (Global theme and provider initialization)
```
