import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/settings_provider.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final UpdateService? updateService;

  const SettingsScreen({super.key, this.updateService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final UpdateService _updateService;
  bool _isCheckingUpdates = false;
  String? _currentVersion;
  int? _currentPatchNumber;

  @override
  void initState() {
    super.initState();
    _updateService = widget.updateService ?? UpdateService();
    _loadCurrentVersion();
  }

  Future<void> _loadCurrentVersion() async {
    try {
      final results = await Future.wait([
        _updateService.getCurrentVersion(),
        _updateService.getCurrentPatchNumber(),
      ]);
      if (mounted) {
        setState(() {
          _currentVersion = results[0] as String?;
          _currentPatchNumber = results[1] as int?;
        });
      }
    } catch (_) {}
  }

  Future<void> _scanForUpdates() async {
    if (_isCheckingUpdates) return;
    setState(() => _isCheckingUpdates = true);

    final result = await _updateService.checkForUpdates();

    if (!mounted) return;
    setState(() {
      _isCheckingUpdates = false;
      _currentVersion = result.currentVersion;
      _currentPatchNumber = result.currentPatchNumber;
    });

    switch (result.status) {
      case UpdateStatus.patchAvailable:
        _showPatchAvailableDialog(result);
        break;
      case UpdateStatus.restartRequired:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Update patch downloaded! Restart BudgetKo to apply it.',
            ),
          ),
        );
        break;
      case UpdateStatus.updateAvailable:
        _showUpdateAvailableDialog(result);
        break;
      case UpdateStatus.upToDate:
        final patchSuffix = result.currentPatchNumber != null
            ? ' • Patch #${result.currentPatchNumber}'
            : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You\'re up to date! (v${result.currentVersion}$patchSuffix)',
            ),
          ),
        );
        break;
      case UpdateStatus.noReleasesFound:
      case UpdateStatus.error:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.errorMessage ?? 'Could not check for updates.',
            ),
          ),
        );
        break;
    }
  }

  void _showPatchAvailableDialog(UpdateCheckResult result) {
    bool isDownloading = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Quick Patch Available'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'A lightweight diff patch is available via Shorebird — no full APK download required.',
                  ),
                  if (isDownloading) ...[
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Downloading patch...'),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDownloading ? null : () => Navigator.pop(ctx),
                  child: const Text('Later'),
                ),
                FilledButton.icon(
                  onPressed: isDownloading
                      ? null
                      : () async {
                          setDialogState(() => isDownloading = true);
                          final downloadResult = await _updateService
                              .downloadPatch();
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (!mounted) return;
                          if (downloadResult.status ==
                              UpdateStatus.restartRequired) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Patch downloaded! Restart BudgetKo to apply.',
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  downloadResult.errorMessage ??
                                      'Could not download patch.',
                                ),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.bolt_rounded, size: 18),
                  label: const Text('Download Patch'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open browser for download.')),
      );
    }
  }

  void _showUpdateAvailableDialog(UpdateCheckResult result) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Update Available'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.releaseName ??
                            result.latestVersion ??
                            'New Release',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Installed: v${result.currentVersion}  →  Latest: ${result.latestVersion}',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (result.apkAssetName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'APK: ${result.apkAssetName}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                if (result.releaseNotes != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Release Notes',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(result.releaseNotes!, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later'),
            ),
            if (result.releasePageUrl != null &&
                result.releasePageUrl != result.downloadUrl)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openExternalUrl(result.releasePageUrl!);
                },
                child: const Text('Release Page'),
              ),
            if (result.downloadUrl != null)
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openExternalUrl(result.downloadUrl!);
                },
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text(
                  result.hasDirectApk ? 'Download APK' : 'Open Release',
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        children: [
          _buildSectionHeader('Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Light: Creamy White, Dark: Dark Grey'),
            value: settings.isDarkMode,
            onChanged: (val) => settings.toggleDarkMode(val),
          ),
          ListTile(
            title: const Text('Button Color Scheme'),
            subtitle: const Text(
              'Customize the accent/button color for the app',
            ),
            trailing: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) {
                    Color selectedColor = settings.themeColor != null
                        ? Color(settings.themeColor!)
                        : const Color(0xFFA3A6A8);
                    return AlertDialog(
                      title: const Text('Choose Color Scheme'),
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: selectedColor,
                          onColorChanged: (c) => selectedColor = c,
                          pickerAreaHeightPercent: 0.8,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            settings.setThemeColor(null);
                            Navigator.pop(ctx);
                          },
                          child: const Text('Reset Default'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            settings.setThemeColor(selectedColor.toARGB32());
                            Navigator.pop(ctx);
                          },
                          child: const Text('Select'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Container(
                width: 48,
                height: 32,
                decoration: BoxDecoration(
                  color: settings.themeColor != null
                      ? Color(settings.themeColor!)
                      : const Color(0xFFA3A6A8),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade400),
                ),
              ),
            ),
          ),
          ListTile(
            title: const Text('Font Size'),
            trailing: DropdownButton<String>(
              value: settings.fontSize,
              underline: const SizedBox(),
              items: [
                'Small',
                'Medium',
                'Large',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) {
                if (val != null) settings.setFontSize(val);
              },
            ),
          ),
          const Divider(),
          _buildSectionHeader('Preferences'),
          SwitchListTile(
            title: const Text('Hide Total Amount'),
            subtitle: const Text(
              'Mask balance and amounts on the Main tab by default',
            ),
            value: settings.hideTotalAmount,
            onChanged: (val) => settings.setHideTotalAmount(val),
          ),
          ListTile(
            title: const Text('Currency Symbol'),
            trailing: DropdownButton<String>(
              value: settings.currency,
              underline: const SizedBox(),
              items: [
                '₱',
                '\$',
                '€',
                '£',
                '¥',
                '₹',
                '₩',
              ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) {
                if (val != null) settings.setCurrency(val);
              },
            ),
          ),
          const Divider(),
          _buildSectionHeader('App Updates'),
          ListTile(
            leading: const Icon(Icons.system_update_outlined),
            title: const Text('Scan for Updates'),
            subtitle: Text(
              _currentVersion != null
                  ? 'v$_currentVersion${_currentPatchNumber != null ? ' (Patch #$_currentPatchNumber)' : ''} • Shorebird & GitHub'
                  : 'Check Shorebird patches & GitHub Releases',
            ),
            trailing: _isCheckingUpdates
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : FilledButton(
                    onPressed: _scanForUpdates,
                    child: const Text('Scan'),
                  ),
            onTap: _isCheckingUpdates ? null : _scanForUpdates,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }
}
