# TASKo App Information

## App Description

**TASKo** is a versatile and efficient task management application built with **Flutter**. It is designed to help users organize their daily activities, manage deadlines, and stay productive through a clean and intuitive interface.

### Core Features

- **Task Management**: Create, edit, and delete tasks with ease. Each task can have a title, description, due date, category, and status level.
- **Dynamic Filtering**: Organize your view by filtering tasks based on their current status or category.
- **Local Notifications**: Never miss a deadline with integrated daily reminders for upcoming tasks, powered by `flutter_local_notifications`.
- **Data Persistence**: Your tasks and settings are saved locally using `SharedPreferences`, ensuring your data is available even after closing the app.
- **Import/Export**: Manage your data externally with import and export capabilities, allowing for backups or sharing task lists.
- **PDF Viewer**: Built-in support for viewing PDF documents, likely used for task attachments or detailed reports.
- **Dark Mode Support**: A fully integrated dark theme for comfortable use in low-light environments.

### Technical Architecture

The app follows a modern Flutter architecture using the **Provider** package for state management, ensuring a clean separation between business logic and the user interface.

- **Models**: Defines the data structures (e.g., `Task`) used throughout the application.
- **Providers**: `TaskProvider` and `SettingsProvider` act as the central state containers, handling data manipulation and notifying the UI of changes.
- **Services**: `NotificationService` handles system-level interaction for reminders, and `ImportExportService` manages data portability.
- **Screens**: A variety of screens including a Dashboard, Settings, Task Editing, and a specialized PDF Viewer.

### Recent Updates

- **Crash Prevention**: Fixed a critical bug where the `TaskEditScreen` would fail to load if all categories or statuses were deleted in Settings. The app now handles empty lists gracefully with fallback defaults.
- **Visual Consistency**: Standardized the `SplashScreen` to always display a creamy white background, ensuring a consistent brand experience regardless of the user's theme (Dark/Light mode).
- **Safe Deletions**: Added confirmation dialogs for deleting Categories and Statuses in the `SettingsScreen` to prevent accidental data loss.
- **Status Refactor**: Replaced the 'Priority' system with a more flexible 'Status' system (Not Started, Ongoing, Finished, Dropped).
- **Analytics Dashboard**: Added a new Analytics screen (accessible via Settings) that provides tables and text statistics for task status distribution and category-based workloads.
- **Visual Task Indicators**: Implemented color-coded task tiles based on deadlines:
    - **Dim Red**: Tasks due today or overdue.
    - **Dim Yellow**: Tasks due within 3 days.
    - **Dim Green**: Finished tasks (striking out is removed, replaced by green background and grey text).
- **Notification Logic**: Refined the reminder system to fire at specific intervals (7, 5, 3, and 1 day before the deadline) plus the due date itself, ensuring better battery life and less notification fatigue.

### Coding Standards

- **Variable Naming**: Following standard Dart/Flutter conventions, this project uses **camelCase** for variables, method names, and class members (e.g., `isFinished`, `taskProvider`, `_loadTasks`).
- **Class Naming**: Classes use **PascalCase** (e.g., `TaskEditScreen`).

---

## Project Structure (Tree Output)

```text
.
├── android
│   ├── app
│   │   ├── src
│   │   └── build.gradle.kts
│   ├── gradle
│   │   └── wrapper
│   ├── build.gradle.kts
│   ├── gradle.properties
│   ├── gradlew
│   ├── gradlew.bat
│   ├── local.properties
│   ├── settings.gradle.kts
│   └── tasker_android.iml
├── import_example
│   ├── Machine Problem 1
│   │   ├── image 1.png
│   │   ├── image 2.png
│   │   └── image.png
│   ├── 会話練習
│   │   ├── Calendar of Classes
│   │   ├── Calendar of Classes 31de2f06af5480049a58c166ee985c91_all.csv
│   │   └── Calendar of Classes 31de2f06af5480049a58c166ee985c91.csv
│   ├── Activity 2 Data Analysis Report 31de2f06af548041b40ce0a3dfbd1493.md
│   ├── Activity 3 Data Analysis Presentation 31de2f06af5480869f35ca858d679171.md
│   ├── Assignment 1 Good vs Bad Design 31de2f06af54805282edc48290eb8388.md
│   ├── CS 3211 Blog Post 1 31be2f06af548036bd44e706806359d9.md
│   ├── CS 3211 Blog Post 2 31be2f06af5480d390a9e08fa095278f.md
│   ├── CS 3211 Blog Post 3 31be2f06af5480abb5c7ef7df8d23441.md
│   ├── CS 3211 Blog Post 4 31be2f06af5480ec9185cbfeae228dad.md
│   ├── CS 3211 Blog Post 5 31be2f06af5480dcb46ddf3c3ac4f8a5.md
│   ├── CS 3211 Blog Post 6 31be2f06af5480dea4aceea232208008.md
│   ├── CS 3211 Blog Post 7 31be2f06af548050b9b0f7e8fe752b3e.md
│   ├── CS 3211 Research Tools Orientation 31be2f06af5480f6a581c6c011b6b5cd.md
│   ├── eTRY! Manual 31de2f06af5480b0b4b8f8fa187c3321.md
│   ├── FA1 Create your own network 31be2f06af548075a3d9f2483ddccdf5.md
│   ├── FA1 Network from statnet 31de2f06af54808997dcf91f03b2d762.md
│   ├── FA1 Research Network 31de2f06af5480599d5fd208e5375829.md
│   ├── Introductory Essay Question for Social Network Ana 31be2f06af5480ccadcbefa794e78d61.md
│   ├── Machine Problem 1 31de2f06af548013b039ca6531ad953b.md
│   ├── Quiz 1 31be2f06af5480b99013c42f88031f06.md
│   ├── Quiz 2 31de2f06af548093b02bf05075af8e3a.md
│   ├── Signed Publication Plan 31de2f06af5480d5bfd9d85d68da61c2.md
│   ├── Submission of Article Reviews 31de2f06af548047890acd81f51bb36f.md
│   └── 会話練習 31de2f06af5480ba8785ee345e4fb870.md
├── ios
│   ├── Flutter
│   │   ├── ephemeral
│   │   └── ...
│   ├── Runner
│   │   ├── Assets.xcassets
│   │   └── ...
│   ├── RunnerTests
│   ├── Runner.xcodeproj
│   └── Runner.xcworkspace
├── lib
│   ├── assets
│   │   ├── tasker_logo_bg_removed.png
│   │   ├── tasker_logo.png
│   │   ├── tasko_logo_bg_remove.png
│   │   └── tasko.png
│   ├── models
│   │   └── task.dart
│   ├── providers
│   │   ├── settings_provider.dart
│   │   └── task_provider.dart
│   ├── screens
│   │   ├── dashboard_screen.dart
│   │   ├── pdf_view_screen.dart
│   │   ├── settings_screen.dart
│   │   ├── splash_screen.dart
│   │   └── task_edit_screen.dart
│   ├── services
│   │   ├── import_export_service.dart
│   │   └── notification_service.dart
│   ├── widgets
│   └── main.dart
├── linux
│   ├── flutter
│   ├── runner
│   └── CMakeLists.txt
├── macos
│   ├── Flutter
│   ├── Runner
│   ├── RunnerTests
│   ├── Runner.xcodeproj
│   └── Runner.xcworkspace
├── test
│   └── widget_test.dart
├── web
│   ├── icons
│   ├── favicon.png
│   ├── index.html
│   └── manifest.json
├── windows
│   ├── flutter
│   ├── runner
│   └── CMakeLists.txt
├── analysis_options.yaml
├── pubspec.lock
├── pubspec.yaml
├── README.md
└── tasker.iml
```
