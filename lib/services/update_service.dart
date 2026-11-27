import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';

enum UpdateStatus { updateAvailable, upToDate, noReleasesFound, error }

class UpdateCheckResult {
  final UpdateStatus status;
  final String currentVersion;
  final String? latestVersion;
  final String? releaseName;
  final String? releaseNotes;
  final String? downloadUrl;
  final String? releasePageUrl;
  final String? apkAssetName;
  final String? errorMessage;

  const UpdateCheckResult({
    required this.status,
    required this.currentVersion,
    this.latestVersion,
    this.releaseName,
    this.releaseNotes,
    this.downloadUrl,
    this.releasePageUrl,
    this.apkAssetName,
    this.errorMessage,
  });

  bool get hasDirectApk => apkAssetName != null && downloadUrl != null;
}

class UpdateHttpResponse {
  final int statusCode;
  final String body;

  const UpdateHttpResponse({required this.statusCode, required this.body});
}

typedef UpdateHttpFetcher = Future<UpdateHttpResponse> Function(Uri uri);
typedef CurrentVersionReader = Future<String> Function();

class UpdateService {
  static const String repoOwner = 'YukiTachi-prod';
  static const String repoName = 'TASKo';

  static Uri get latestReleaseUri => Uri.https(
    'api.github.com',
    '/repos/$repoOwner/$repoName/releases/latest',
  );

  final UpdateHttpFetcher _httpFetcher;
  final CurrentVersionReader _versionReader;

  UpdateService({
    UpdateHttpFetcher? httpFetcher,
    CurrentVersionReader? versionReader,
  }) : _httpFetcher = httpFetcher ?? _defaultHttpFetch,
       _versionReader = versionReader ?? _defaultReadVersion;

  static Future<String> _defaultReadVersion() async {
    final info = await PackageInfo.fromPlatform();
    final build = info.buildNumber.trim();
    return build.isNotEmpty ? '${info.version}+$build' : info.version;
  }

  static Future<UpdateHttpResponse> _defaultHttpFetch(Uri uri) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 12);
    try {
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 12));
      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/vnd.github+json',
      );
      request.headers.set(HttpHeaders.userAgentHeader, 'BudgetKo-App');
      final response = await request.close().timeout(
        const Duration(seconds: 12),
      );
      final body = await response.transform(utf8.decoder).join();
      return UpdateHttpResponse(statusCode: response.statusCode, body: body);
    } finally {
      client.close(force: true);
    }
  }

  Future<String> getCurrentVersion() => _versionReader();

  Future<UpdateCheckResult> checkForUpdates() async {
    String currentVersion = '0.0.0';
    try {
      currentVersion = await _versionReader();
    } catch (_) {}

    try {
      final response = await _httpFetcher(latestReleaseUri);

      if (response.statusCode == 404) {
        return UpdateCheckResult(
          status: UpdateStatus.noReleasesFound,
          currentVersion: currentVersion,
          errorMessage: 'No published releases found on GitHub yet.',
        );
      }

      if (response.statusCode == 403) {
        return UpdateCheckResult(
          status: UpdateStatus.error,
          currentVersion: currentVersion,
          errorMessage:
              'GitHub API rate limit reached. Please try again in a few minutes.',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return UpdateCheckResult(
          status: UpdateStatus.error,
          currentVersion: currentVersion,
          errorMessage:
              'Failed to check for updates (HTTP ${response.statusCode}).',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return UpdateCheckResult(
          status: UpdateStatus.error,
          currentVersion: currentVersion,
          errorMessage: 'Unexpected response from GitHub Releases.',
        );
      }

      final tagName = decoded['tag_name']?.toString().trim() ?? '';
      if (tagName.isEmpty) {
        return UpdateCheckResult(
          status: UpdateStatus.noReleasesFound,
          currentVersion: currentVersion,
          errorMessage: 'Latest GitHub release has no version tag.',
        );
      }

      final releaseName = decoded['name']?.toString().trim();
      final releaseNotes = decoded['body']?.toString().trim();
      final htmlUrl = decoded['html_url']?.toString().trim();
      final assets = (decoded['assets'] as List?) ?? const [];
      final pickedApk = pickApkAsset(assets);

      final downloadUrl = pickedApk['url'] ?? htmlUrl;
      final hasUpdate = isNewerVersion(tagName, currentVersion);

      return UpdateCheckResult(
        status: hasUpdate
            ? UpdateStatus.updateAvailable
            : UpdateStatus.upToDate,
        currentVersion: currentVersion,
        latestVersion: tagName,
        releaseName: (releaseName != null && releaseName.isNotEmpty)
            ? releaseName
            : tagName,
        releaseNotes: (releaseNotes != null && releaseNotes.isNotEmpty)
            ? releaseNotes
            : null,
        downloadUrl: downloadUrl,
        releasePageUrl: htmlUrl,
        apkAssetName: pickedApk['name'],
      );
    } on TimeoutException {
      return UpdateCheckResult(
        status: UpdateStatus.error,
        currentVersion: currentVersion,
        errorMessage: 'Connection timed out while checking GitHub.',
      );
    } on SocketException {
      return UpdateCheckResult(
        status: UpdateStatus.error,
        currentVersion: currentVersion,
        errorMessage: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      return UpdateCheckResult(
        status: UpdateStatus.error,
        currentVersion: currentVersion,
        errorMessage: 'Could not check for updates: $e',
      );
    }
  }

  /// Selects the best APK asset from a GitHub Release's `assets` list.
  /// Prefers `app-release.apk` or a universal APK when multiple APKs exist.
  static Map<String, String?> pickApkAsset(List<dynamic> assets) {
    final apkAssets = <Map<String, String>>[];
    for (final item in assets) {
      if (item is! Map) continue;
      final name = item['name']?.toString().trim() ?? '';
      final url = item['browser_download_url']?.toString().trim() ?? '';
      if (name.toLowerCase().endsWith('.apk') && url.isNotEmpty) {
        apkAssets.add({'name': name, 'url': url});
      }
    }

    if (apkAssets.isEmpty) {
      return {'name': null, 'url': null};
    }

    for (final asset in apkAssets) {
      final lower = asset['name']!.toLowerCase();
      if (lower == 'app-release.apk' || lower.contains('universal')) {
        return asset;
      }
    }

    return apkAssets.first;
  }

  /// Returns true if [latestTag] represents a newer version than [currentVersion].
  /// Supports `v1.2.0`, `1.2.0`, and optional `+build` numbers like `1.2.0+3`.
  static bool isNewerVersion(String latestTag, String currentVersion) {
    final latest = _parseVersion(latestTag);
    final current = _parseVersion(currentVersion);

    for (var i = 0; i < 3; i++) {
      if (latest.parts[i] != current.parts[i]) {
        return latest.parts[i] > current.parts[i];
      }
    }

    if (latest.build != null && current.build != null) {
      return latest.build! > current.build!;
    }
    return false;
  }

  static ({List<int> parts, int? build}) _parseVersion(String raw) {
    var cleaned = raw.trim();
    if (cleaned.startsWith('v') || cleaned.startsWith('V')) {
      cleaned = cleaned.substring(1);
    }

    int? build;
    final plusIdx = cleaned.indexOf('+');
    if (plusIdx != -1) {
      build = int.tryParse(cleaned.substring(plusIdx + 1).trim());
      cleaned = cleaned.substring(0, plusIdx);
    }

    // Strip any pre-release tag (e.g. -beta.1)
    final dashIdx = cleaned.indexOf('-');
    if (dashIdx != -1) {
      cleaned = cleaned.substring(0, dashIdx);
    }

    final rawParts = cleaned.split('.');
    final parts = List<int>.generate(3, (i) {
      if (i >= rawParts.length) return 0;
      return int.tryParse(rawParts[i].trim()) ?? 0;
    });

    return (parts: parts, build: build);
  }
}
