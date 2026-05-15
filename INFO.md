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
│   ├── routines_screen.dart (Tab for repeating tasks)
│   ├── main_screen.dart (Bottom navigation container)
│   ├── task_edit_screen.dart (Locking, routines, and dual-date inputs)
│   └── splash_screen.dart (Standardized white background)
├── services/
│   ├── import_export_service.dart (Markdown parser for new task fields)
│   └── notification_service.dart (Deadline-based reminder logic)
└── main.dart (Global theme and provider initialization)
```

---

## In-Progress Refactor: Android + Web (Chrome) Support

A refactor is underway to support both **Android** and **Web (Chrome)** targets. The strategy
uses Dart's **conditional export** pattern so platform-specific code is never compiled on the
wrong target. Three core problems are being solved:

1. `flutter_local_notifications` does not compile on web → abstracted behind a conditional service.
2. `dart:io` (File/Directory) is not available on web → abstracted behind a conditional file service.
3. `SfPdfViewer.file()` requires `dart:io` → wrapped in a conditional widget.

---

### COMPLETED

All new files listed below were **created from scratch** and are ready. No existing files have
been modified yet — the app still builds as before until the wiring step (see TODO below).

#### `lib/services/notification/`

| File | Purpose |
|------|---------|
| `notification_service.dart` | Conditional export selector (`dart.library.html` → web, else mobile) |
| `mobile_notification_service.dart` | Full Android implementation (existing logic, cleaned up) |
| `web_notification_service.dart` | No-op stub — all methods are empty `async {}` |

#### `lib/services/platform/`

| File | Purpose |
|------|---------|
| `platform_file_service.dart` | Conditional export selector |
| `mobile_file_service.dart` | `dart:io` file ops: copy PDF, delete PDF, save/share ZIP via `share_plus` |
| `web_file_service.dart` | Browser download via `dart:html`; `supportsPdfAttachment` returns `false` |

#### `lib/widgets/`

| File | Purpose |
|------|---------|
| `platform_pdf_viewer.dart` | Conditional export selector |
| `platform_pdf_viewer_mobile.dart` | `SfPdfViewer.file(File(path))` |
| `platform_pdf_viewer_web.dart` | "PDF viewing not available in browser" placeholder |

---

### TODO (not started — existing files are unchanged)

Complete the following in order. Each item lists the file to edit and exactly what to change.

#### 1. `lib/main.dart`
- Change import from `../services/notification_service.dart`
  to `services/notification/notification_service.dart`.

#### 2. `lib/providers/task_provider.dart`
- Remove `import 'dart:io';`.
- Add `import '../services/platform/platform_file_service.dart';`.
- Change import of `NotificationService` to point to `services/notification/notification_service.dart`.
- Add field: `final PlatformFileService _fileService = PlatformFileService();`
- In `deleteTasks()`, `deleteTask()`, and `clearAllTasks()`: replace every
  `File(path).existsSync()` / `file.deleteSync()` block with
  `_fileService.deletePdfFile(task.pdfPath!)`.

#### 3. `lib/screens/pdf_view_screen.dart`
- Remove `import 'dart:io';` and `import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';`.
- Add `import '../widgets/platform_pdf_viewer.dart';`.
- Replace `SfPdfViewer.file(File(path))` with `PlatformPdfViewer(path: path)`.

#### 4. `lib/screens/task_edit_screen.dart`
- Remove `import 'dart:io';`, `import 'package:path_provider/path_provider.dart';`,
  `import 'package:path/path.dart' as p;`.
- Add `import 'package:flutter/foundation.dart';` and
  `import '../services/platform/platform_file_service.dart';`.
- Add field: `final PlatformFileService _fileService = PlatformFileService();`
- In `_pickPdf()`: add `withData: kIsWeb` to `FilePicker.pickFiles`; if `kIsWeb` show
  a SnackBar saying "PDF attachment not supported on web" and return early.
- In `_applyPdfChoice()`: replace the `dart:io` copy logic with
  `await _fileService.copyPdfToAppStorage(originalPath)`.
- In the PDF tile `onTap`: replace `File(_pdfPath!).existsSync()` with
  `_fileService.pdfFileExists(_pdfPath!)`.

#### 5. `lib/screens/settings_screen.dart`
- Remove `import 'dart:io';`, `import 'package:path_provider/path_provider.dart';`,
  `import 'package:share_plus/share_plus.dart';`.
- Add `import '../services/platform/platform_file_service.dart';`.
- In `_handleImport()`: add `withData: true` to `FilePicker.pickFiles`; read bytes via
  `result.files.single.bytes` instead of `File(path).readAsBytes()` — this works on
  both mobile and web without `dart:io`.
- In `_handleExport()`: replace `dart:io` write logic with
  `await _fileService.saveExportZip(bytes, 'tasks_export.zip')`.
- In `_handleShare()`: replace `dart:io` + `Share.shareXFiles` with
  `await _fileService.shareZip(bytes, 'tasks_share.zip')`.

#### 6. `lib/widgets/task_tile.dart` — CREATE
Extract the `_buildTaskTile` / `_buildRoutineTile` methods that are duplicated across
`dashboard_screen.dart` and `routines_screen.dart` into a single reusable `TaskTile` widget.

Signature:
```dart
class TaskTile extends StatelessWidget {
  final Task task;
  final bool isMultiSelectionMode;
  final bool isSelected;
  final bool showRepeatBadge;         // true for routines, false for tasks
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onToggleFinished;
  final VoidCallback onDelete;
  ...
}
```

#### 7. `lib/widgets/filter_bar.dart` — CREATE
Extract the identical `_buildFilterBar` method from both screens into a standalone widget.
It reads `TaskProvider` and `SettingsProvider` via `Provider.of` internally.

#### 8. `lib/widgets/task_list_view.dart` — CREATE
Create a stateful widget that owns the multi-selection state and composes `FilterBar` +
`ListView` of `TaskTile`s. This replaces the bodies of both list screens.

Signature:
```dart
class TaskListView extends StatefulWidget {
  final List<Task> tasks;
  final String emptyMessage;
  final bool showRepeatBadge;
  ...
}
```

#### 9. `lib/screens/dashboard_screen.dart` — SIMPLIFY
Replace entire body with:
```dart
class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tasks = Provider.of<TaskProvider>(context).tasks;
    return TaskListView(tasks: tasks, emptyMessage: 'No tasks found');
  }
}
```

#### 10. `lib/screens/routines_screen.dart` — SIMPLIFY
Same pattern as DashboardScreen but uses `taskProvider.routines` and
`showRepeatBadge: true`.

#### 11. Delete `lib/services/notification_service.dart`
The old top-level notification service file is replaced by
`lib/services/notification/notification_service.dart`. Delete the old file once
steps 1 and 2 above are complete.

---

### Key Design Decisions for the Next Agent

- **Conditional exports** (not `kIsWeb` runtime checks) are used for services and widgets
  that use `dart:io` or `dart:html`. This ensures the wrong platform's code is never
  compiled at all, which is required because `flutter_local_notifications` and `dart:io`
  do not compile on web targets.
- **`withData: true`** in `FilePicker.pickFiles` makes file bytes available on all
  platforms without needing `dart:io` to read the file after picking.
- **PDF attachment is disabled on web** (`PlatformFileService.supportsPdfAttachment`
  returns `false` on web). The `task_edit_screen` should check this flag before showing
  the attach button.
- The `ImportExportService` is pure Dart (no `dart:io`) and requires no changes.
