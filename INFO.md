# TASKo App Information

## App Description

**TASKo** is a versatile and efficient task management application built with **Flutter**. It targets **Android**, **Web (Chrome)**, and **Linux desktop**. It is designed to help users organize their daily activities, manage deadlines, and stay productive through a clean and intuitive interface.

### Core Features

- **Dual-Date Task Management**: Create tasks with specific **Start** and **End** date/times for precise scheduling. You can also optionally omit dates entirely for simple to-do items.
- **Routines (Repeating Tasks)**: Dedicated support for recurring activities (Daily, Weekly, Monthly, Hourly) with a specialized viewing tab.
- **Task Locking**: Secure your tasks by locking them; once saved and locked, only the status can be updated, preventing accidental modifications.
- **Bulk Operations**: Long-press to enter multi-selection mode and delete multiple tasks at once.
- **Unique Title Enforcement**: Prevents organization clutter by ensuring no two tasks share the same title.
- **Dynamic Filtering**: Filter tasks by status (chip row), category (popup), or date.
- **Local Notifications & Alarms**: Integrated reminders for upcoming task deadlines (Android/iOS). Pick a custom `.wav` alarm sound in settings. Linux uses libnotify via `flutter_local_notifications` v18 (fire-and-forget only — scheduled reminders not supported on Linux).
- **In-App Notification Center**: A dedicated notification bell and sliding drawer for tracking and managing app alerts seamlessly.
- **Granular Budgeting**: Categories support explicit **Daily and Weekly Budget Limits** to augment existing monthly constraints.
- **Precise Expense Tracking**: The expenses tab displays exact transaction times when recorded, defaulting to just the date for time-less entries.
- **Flexible Time Picking**: Users can choose between a circular dial or a numeric/keyboard input (default) for time selection.
- **Import/Export**: Markdown-based import/export system via ZIP files.
- **Dark/Light Mode**: Fully integrated theme switcher. Light mode uses a soft lavender background with a deep purple sidebar; dark mode uses dark violet tones.
- **Heatmap View**: Visual grid displaying tasks by day/week, accessible via a pinch/squeeze gesture or the header button, with inner-cell sorting options.
- **Custom Status Colors**: Allows users to dynamically select specific display colors for their task statuses from the Settings menu.
- **Wallet Background Management**: Import custom account backgrounds (1000x300 PNG). A dedicated "Saved Backgrounds" screen in settings allows gallery viewing, multi-selection, and batch deletion. Overwrite warnings prevent accidental data loss during imports.
- **Developer Options**: A locked section in Settings (password: `jaceywashere`) for testing immediate and scheduled notifications/alarms and bulk-generating dummy data.

### Technical Architecture

The app follows a modern Flutter architecture using the **Provider** package for state management.

- **Models**: `Task` — all task fields including Start/End dates, locking, routine status.
- **Providers**: `TaskProvider` (task CRUD, filtering, bulk ops) and `SettingsProvider` (categories, statuses, UI prefs).
- **Theme**: `AppTheme` — single source of truth for all ThemeData, colors, and semantic color helpers.
- **Services**: Conditional-export notification and file services for platform compatibility.
- **Screens**: Dashboard, Routines, Settings, Task Edit, Analytics, PDF Viewer.
- **Widgets**: Modular — `TaskTile`, `TaskListView`, `FilterBar`, `StatusPill`, `CategoryTag`, `PlatformPdfViewer`.

---

## Design System

### Theme (`lib/theme/app_theme.dart`)

All theme configuration lives in `AppTheme`. Call `AppTheme.light()` and `AppTheme.dark()` from `main.dart`.

| Token | Light | Dark |
|-------|-------|------|
| Background | `#EEF2FF` (soft lavender) | `#0D0B1A` (dark violet) |
| Surface / Cards | `#FFFFFF` | `#16132B` |
| Primary accent | `#7C3AED` (violet) | `#8B5CF6` |
| Sidebar (NavRail) | `#6D28D9` (deep purple) | `#1A1733` |
| Text | `#1E1B4B` (dark navy) | `#E2E8F0` |
| Subtext | `#6B7280` | `#94A3B8` |
| Border | `#E5E7EB` | `#2E2A4A` |

### Status Colors (`SettingsProvider.statusColors`)

Status colors are now dynamic and user-configurable via the **Settings menu**. The default mapping falls back to grey if unconfigured, but dynamically overrides `AppTheme` when customized.

### Category Colors (`AppTheme.categoryColor(category)`)

Hash-stable 8-color palette (violet, indigo, blue, cyan, emerald, amber, red, pink). No dependency on the category list order.

### Urgency Accent (task tile left bar)

| State | Color |
|-------|-------|
| Overdue / due today | `#EF4444` red |
| Due in ≤ 3 days | `#F59E0B` amber |
| Finished | `#10B981` green |
| Normal | Transparent |

---

## Project Structure

```text
lib/
├── models/
│   └── task.dart
├── providers/
│   ├── settings_provider.dart
│   └── task_provider.dart
├── screens/
│   ├── analytics_screen.dart
│   ├── dashboard_screen.dart       ← StatelessWidget, delegates to TaskListView
│   ├── main_screen.dart            ← Responsive: NavigationRail (≥720px) / BottomNav
│   ├── pdf_view_screen.dart
│   ├── routines_screen.dart        ← StatelessWidget, delegates to TaskListView
│   ├── settings_screen.dart
│   └── task_edit_screen.dart       ← Notion-style property rows, constrained width
├── services/
│   ├── notification_service.dart   ← OLD FILE — to be deleted (see TODO #11)
│   ├── notification/
│   │   ├── notification_service.dart          (conditional export selector)
│   │   ├── mobile_notification_service.dart   (Android + Linux + macOS init paths)
│   │   └── web_notification_service.dart      (no-op stub)
│   └── platform/
│       ├── platform_file_service.dart         (conditional export selector)
│       ├── mobile_file_service.dart           (dart:io + share_plus)
│       └── web_file_service.dart              (dart:html download)
├── theme/
│   └── app_theme.dart              ← Centralized ThemeData (purple/violet palette)
└── widgets/
    ├── category_tag.dart           ← Colored category badge
    ├── filter_bar.dart             ← Status chips + date/category filter pills
    ├── platform_pdf_viewer.dart    (conditional export selector)
    ├── platform_pdf_viewer_mobile.dart  (Syncfusion on mobile, url_launcher on desktop)
    ├── platform_pdf_viewer_web.dart     (placeholder)
    ├── status_pill.dart            ← Colored status badge
    ├── task_list_view.dart         ← Stateful: multi-select + FilterBar + TaskTile list
    └── task_tile.dart              ← Floating card: shadow, urgency bar, StatusPill, CategoryTag
```

---

## Platform Support

| Platform | Build | Notifications | PDF Viewer | File I/O | Share |
|----------|-------|---------------|------------|----------|-------|
| Android | ✅ | ✅ Scheduled | ✅ Syncfusion | ✅ | ✅ |
| Web | ✅ | ✅ no-op | ✅ placeholder | ✅ dart:html | ✅ download |
| Linux | ✅ | ✅ libnotify (no scheduling) | ✅ system viewer (url_launcher) | ✅ dart:io | ✅ xdg-portal |

**Linux system requirement**: `libnotify` must be installed (default on GNOME/KDE distros).

---

## Multi-Platform Strategy

The app uses Dart's **conditional export** pattern to keep platform-specific code out of the wrong build target.

```
services/notification/notification_service.dart
  ├── if (dart.library.html) → web_notification_service.dart   (no-op)
  └── else                  → mobile_notification_service.dart  (Android/iOS/Linux/macOS)

services/platform/platform_file_service.dart
  ├── if (dart.library.html) → web_file_service.dart            (dart:html)
  └── else                  → mobile_file_service.dart          (dart:io)

widgets/platform_pdf_viewer.dart
  ├── if (dart.library.html) → platform_pdf_viewer_web.dart     (placeholder)
  └── else                  → platform_pdf_viewer_mobile.dart   (Syncfusion on mobile,
                                                                  url_launcher on desktop)
```

**Key decisions:**
- Conditional exports (not `kIsWeb`) prevent wrong-platform code from compiling.
- `dart.library.io` is available on ALL native platforms (mobile + desktop), so Linux and Android cannot be separated at compile time via library conditions. Desktop vs mobile is handled at **runtime** inside the native files using `Platform.isAndroid` / `Platform.isLinux`.
- `syncfusion_flutter_pdfviewer` compiles on Linux (uses platform channels) but has no Linux implementation. The `platform_pdf_viewer_mobile.dart` guards against calling it with a `Platform.isAndroid || Platform.isIOS` check.
- `flutter_local_notifications` v18 supports Linux natively via libnotify. Scheduled notifications (`zonedSchedule`) are skipped on Linux — only the initialization path differs.

---

## Remaining TODO — PlatformFileService Wiring

Steps 1 and 6–10 from the original plan are **complete**. The following items remain.
Complete them in order.

### 2. `lib/providers/task_provider.dart`
- Remove `import 'dart:io';`.
- Add `import '../services/platform/platform_file_service.dart';`.
- Change `NotificationService` import to `services/notification/notification_service.dart`.
- Add field: `final PlatformFileService _fileService = PlatformFileService();`
- In `deleteTasks()`, `deleteTask()`, and `clearAllTasks()`: replace every
  `File(path).existsSync()` / `file.deleteSync()` block with
  `_fileService.deletePdfFile(task.pdfPath!)`.

### 3. `lib/screens/pdf_view_screen.dart`
- Remove `import 'dart:io';` and `import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';`.
- Add `import '../widgets/platform_pdf_viewer.dart';`.
- Replace `SfPdfViewer.file(File(path))` with `PlatformPdfViewer(path: path)`.

### 4. `lib/screens/task_edit_screen.dart`
- Remove `import 'dart:io';`, `import 'package:path_provider/path_provider.dart';`,
  `import 'package:path/path.dart' as p;`.
- Add `import 'package:flutter/foundation.dart';` and
  `import '../services/platform/platform_file_service.dart';`.
- Add field: `final PlatformFileService _fileService = PlatformFileService();`
- In `_pickPdf()`: add `withData: kIsWeb` to `FilePicker.pickFiles`; if `kIsWeb` show
  a SnackBar saying "PDF attachment not supported on web" and return early.
- In `_applyPdfChoice()`: replace the `dart:io` copy logic with
  `await _fileService.copyPdfToAppStorage(originalPath)`.
- In `_PdfRow.onTap`: replace `File(path).existsSync()` with
  `_fileService.pdfFileExists(path)`.

### 5. `lib/screens/settings_screen.dart`
- Remove `import 'dart:io';`, `import 'package:path_provider/path_provider.dart';`,
  `import 'package:share_plus/share_plus.dart';`.
- Add `import '../services/platform/platform_file_service.dart';`.
- In `_handleImport()`: add `withData: true` to `FilePicker.pickFiles`; read bytes via
  `result.files.single.bytes` instead of `File(path).readAsBytes()`.
- In `_handleExport()`: replace `dart:io` write logic with
  `await _fileService.saveExportZip(bytes, 'tasks_export.zip')`.
- In `_handleShare()`: replace `dart:io` + `Share.shareXFiles` with
  `await _fileService.shareZip(bytes, 'tasks_share.zip')`.

### 11. Delete `lib/services/notification_service.dart`
The old top-level file is fully replaced by `lib/services/notification/notification_service.dart`.
Delete it after steps 2–5 are complete and the build is verified clean.

---

## Coding Standards

- **Variable Naming**: Standard Dart `camelCase`.
- **Class Naming**: `PascalCase`.
- **Theming**: Always use `AppTheme` static methods and `Theme.of(context)` values. Never hardcode colors in widgets except for semantic constants defined in `AppTheme`.
- **Platform guards**: Use `Platform.isX` runtime checks (from `dart:io`) inside native files. Never use `kIsWeb` for compile-time separation — use conditional exports instead.
- **Widget size**: Use `ConstrainedBox(maxWidth: 600)` for form/detail screens so they don't stretch to full width on desktop.
