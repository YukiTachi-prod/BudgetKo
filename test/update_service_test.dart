import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart' as shorebird;
import 'package:tasker/providers/notification_provider.dart';
import 'package:tasker/providers/settings_provider.dart';
import 'package:tasker/screens/settings_screen.dart';
import 'package:tasker/services/update_service.dart';

class _FakeShorebirdUpdater implements shorebird.ShorebirdUpdater {
  @override
  final bool isAvailable;
  final shorebird.UpdateStatus statusToReturn;
  final shorebird.Patch? currentPatch;
  bool updateCalled = false;

  _FakeShorebirdUpdater({
    required this.isAvailable,
    this.statusToReturn = shorebird.UpdateStatus.upToDate,
    this.currentPatch,
  });

  @override
  Future<shorebird.UpdateStatus> checkForUpdate({
    shorebird.UpdateTrack? track,
  }) async => statusToReturn;

  @override
  Future<shorebird.Patch?> readCurrentPatch() async => currentPatch;

  @override
  Future<shorebird.Patch?> readNextPatch() async => currentPatch;

  @override
  Future<void> update({shorebird.UpdateTrack? track}) async {
    updateCalled = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UpdateService.isNewerVersion', () {
    test('detects newer major, minor, patch, and build versions', () {
      expect(UpdateService.isNewerVersion('v2.0.0', '1.1.0+2'), isTrue);
      expect(UpdateService.isNewerVersion('v1.2.0', '1.1.0+2'), isTrue);
      expect(UpdateService.isNewerVersion('1.1.1', '1.1.0+2'), isTrue);
      expect(UpdateService.isNewerVersion('v1.1.0+3', '1.1.0+2'), isTrue);
    });

    test('returns false for equal or older versions', () {
      expect(UpdateService.isNewerVersion('v1.1.0', '1.1.0+2'), isFalse);
      expect(UpdateService.isNewerVersion('v1.1.0+2', '1.1.0+2'), isFalse);
      expect(UpdateService.isNewerVersion('v1.0.9', '1.1.0+2'), isFalse);
      expect(UpdateService.isNewerVersion('v1.1.0+1', '1.1.0+2'), isFalse);
    });
  });

  group('UpdateService.checkForUpdates', () {
    test('returns updateAvailable with direct APK asset URL', () async {
      final service = UpdateService(
        versionReader: () async => '1.1.0+2',
        httpFetcher: (uri) async {
          expect(
            uri.toString(),
            'https://api.github.com/repos/YukiTachi-prod/TASKo/releases/latest',
          );
          return UpdateHttpResponse(
            statusCode: 200,
            body: jsonEncode({
              'tag_name': 'v1.2.0',
              'name': 'BudgetKo v1.2.0',
              'body': '- Added Temporary Group Pool',
              'html_url':
                  'https://github.com/YukiTachi-prod/TASKo/releases/tag/v1.2.0',
              'assets': [
                {
                  'name': 'checksums.txt',
                  'browser_download_url': 'https://example.com/checksums.txt',
                },
                {
                  'name': 'app-release.apk',
                  'browser_download_url':
                      'https://github.com/YukiTachi-prod/TASKo/releases/download/v1.2.0/app-release.apk',
                },
              ],
            }),
          );
        },
      );

      final result = await service.checkForUpdates();
      expect(result.status, UpdateStatus.updateAvailable);
      expect(result.latestVersion, 'v1.2.0');
      expect(result.apkAssetName, 'app-release.apk');
      expect(result.hasDirectApk, isTrue);
      expect(
        result.downloadUrl,
        'https://github.com/YukiTachi-prod/TASKo/releases/download/v1.2.0/app-release.apk',
      );
    });

    test('falls back to html_url when no APK asset is attached', () async {
      final service = UpdateService(
        versionReader: () async => '1.1.0+2',
        httpFetcher: (_) async => UpdateHttpResponse(
          statusCode: 200,
          body: jsonEncode({
            'tag_name': 'v1.2.0',
            'html_url':
                'https://github.com/YukiTachi-prod/TASKo/releases/tag/v1.2.0',
            'assets': [],
          }),
        ),
      );

      final result = await service.checkForUpdates();
      expect(result.status, UpdateStatus.updateAvailable);
      expect(result.hasDirectApk, isFalse);
      expect(
        result.downloadUrl,
        'https://github.com/YukiTachi-prod/TASKo/releases/tag/v1.2.0',
      );
    });

    test('returns upToDate when installed matches latest', () async {
      final service = UpdateService(
        versionReader: () async => '1.1.0+2',
        httpFetcher: (_) async => UpdateHttpResponse(
          statusCode: 200,
          body: jsonEncode({'tag_name': 'v1.1.0', 'assets': []}),
        ),
      );

      final result = await service.checkForUpdates();
      expect(result.status, UpdateStatus.upToDate);
    });

    test('handles 404 when no releases exist yet', () async {
      final service = UpdateService(
        versionReader: () async => '1.1.0+2',
        httpFetcher: (_) async =>
            const UpdateHttpResponse(statusCode: 404, body: '{}'),
      );

      final result = await service.checkForUpdates();
      expect(result.status, UpdateStatus.noReleasesFound);
    });
  });

  group('SettingsScreen Scan for Updates Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('shows Update Available dialog when newer release exists', (
      tester,
    ) async {
      final settings = SettingsProvider();
      await settings.preload();

      final service = UpdateService(
        versionReader: () async => '1.1.0+2',
        httpFetcher: (_) async => UpdateHttpResponse(
          statusCode: 200,
          body: jsonEncode({
            'tag_name': 'v1.3.0',
            'name': 'BudgetKo v1.3.0',
            'body': 'Bug fixes and improvements',
            'html_url':
                'https://github.com/YukiTachi-prod/TASKo/releases/tag/v1.3.0',
            'assets': [
              {
                'name': 'app-release.apk',
                'browser_download_url':
                    'https://github.com/YukiTachi-prod/TASKo/releases/download/v1.3.0/app-release.apk',
              },
            ],
          }),
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settings,
          child: MaterialApp(home: SettingsScreen(updateService: service)),
        ),
      );
      await tester.pumpAndSettle();

      final scanBtn = find.widgetWithText(FilledButton, 'Scan');
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      await tester.ensureVisible(scanBtn);
      await tester.pumpAndSettle();
      await tester.tap(scanBtn);
      await tester.pumpAndSettle();

      expect(find.text('Update Available'), findsOneWidget);
      expect(find.text('BudgetKo v1.3.0'), findsOneWidget);
      expect(find.text('Download APK'), findsOneWidget);
    });

    testWidgets('shows up-to-date snackbar when on latest release', (
      tester,
    ) async {
      final settings = SettingsProvider();
      await settings.preload();

      final service = UpdateService(
        versionReader: () async => '1.1.0+2',
        httpFetcher: (_) async => UpdateHttpResponse(
          statusCode: 200,
          body: jsonEncode({'tag_name': 'v1.1.0', 'assets': []}),
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settings,
          child: MaterialApp(home: SettingsScreen(updateService: service)),
        ),
      );
      await tester.pumpAndSettle();

      final scanBtn = find.widgetWithText(FilledButton, 'Scan');
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      await tester.ensureVisible(scanBtn);
      await tester.pumpAndSettle();
      await tester.tap(scanBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining("You're up to date!"), findsOneWidget);
    });

    testWidgets(
      'detects Shorebird diff patch and downloads it from Quick Patch dialog',
      (tester) async {
        final settings = SettingsProvider();
        await settings.preload();

        final fakeShorebird = _FakeShorebirdUpdater(
          isAvailable: true,
          statusToReturn: shorebird.UpdateStatus.outdated,
          currentPatch: const shorebird.Patch(number: 1),
        );

        final service = UpdateService(
          versionReader: () async => '1.1.1+3',
          shorebirdUpdater: fakeShorebird,
          httpFetcher: (_) async =>
              const UpdateHttpResponse(statusCode: 404, body: '{}'),
        );

        await tester.pumpWidget(
          ChangeNotifierProvider<SettingsProvider>.value(
            value: settings,
            child: MaterialApp(home: SettingsScreen(updateService: service)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Patch #1'), findsOneWidget);

        final scanBtn = find.widgetWithText(FilledButton, 'Scan');
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();
        await tester.ensureVisible(scanBtn);
        await tester.pumpAndSettle();
        await tester.tap(scanBtn);
        await tester.pumpAndSettle();

        expect(find.text('Quick Patch Available'), findsOneWidget);
        await tester.tap(find.text('Download Patch'));
        await tester.pumpAndSettle();

        expect(fakeShorebird.updateCalled, isTrue);
        expect(find.textContaining('Patch downloaded!'), findsOneWidget);
      },
    );
  });

  group('Startup Shorebird patch notification tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'notifies user on startup when a Shorebird patch is available',
      () async {
        final notifications = NotificationProvider();
        await notifications.preload();

        final service = UpdateService(
          versionReader: () async => '1.1.1+3',
          shorebirdUpdater: _FakeShorebirdUpdater(
            isAvailable: true,
            statusToReturn: shorebird.UpdateStatus.outdated,
          ),
        );

        await notifications.checkForPatchUpdate(updateService: service);

        expect(notifications.notifications.length, 1);
        expect(notifications.notifications.first.title, 'App Patch Available');
      },
    );

    test(
      'notifies user on startup when a Shorebird patch needs restart',
      () async {
        final notifications = NotificationProvider();
        await notifications.preload();

        final service = UpdateService(
          versionReader: () async => '1.1.1+3',
          shorebirdUpdater: _FakeShorebirdUpdater(
            isAvailable: true,
            statusToReturn: shorebird.UpdateStatus.restartRequired,
          ),
        );

        await notifications.checkForPatchUpdate(updateService: service);

        expect(notifications.notifications.length, 1);
        expect(notifications.notifications.first.title, 'App Patch Ready');
      },
    );

    test('does not notify when up to date or Shorebird unavailable', () async {
      final notifications = NotificationProvider();
      await notifications.preload();

      final service = UpdateService(
        versionReader: () async => '1.1.1+3',
        shorebirdUpdater: _FakeShorebirdUpdater(
          isAvailable: true,
          statusToReturn: shorebird.UpdateStatus.upToDate,
        ),
      );

      await notifications.checkForPatchUpdate(updateService: service);

      expect(notifications.notifications, isEmpty);
    });
  });
}
