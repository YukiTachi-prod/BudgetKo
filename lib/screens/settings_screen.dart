import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/ledger_provider.dart';
import 'saved_backgrounds_screen.dart';
import 'package:file_picker/file_picker.dart';
import '../services/platform/platform_file_service.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../widgets/transition_placeholder.dart';
import 'dart:ui' as ui;
import 'package:archive/archive.dart';
import 'dart:typed_data';
import 'dart:io';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: TransitionPlaceholder(
        child: ListView(
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
            const Divider(),
            _buildSectionHeader('Data Management'),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Import Account Packages'),
              subtitle: const Text('Import custom backgrounds from ZIP'),
              onTap: () => _handleImportAccountPackage(context),
            ),
            ListTile(
              leading: const Icon(Icons.wallpaper),
              title: const Text('Saved Backgrounds'),
              subtitle: const Text('Manage your custom account backgrounds'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SavedBackgroundsScreen(),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
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

  Future<void> _handleImportAccountPackage(BuildContext context) async {
    final ledgerProvider = context.read<LedgerProvider>();
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result != null && result.files.single.path != null) {
      final bytes = await File(result.files.single.path!).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      int updatedAccountsCount = 0;
      final fileService = PlatformFileService();

      for (final file in archive) {
        if (file.isFile && file.name.toLowerCase().endsWith('.png')) {
          final baseName = file.name.split('/').last;
          final accountName = baseName.substring(0, baseName.length - 4);

          final account = ledgerProvider.accounts
              .where((a) => a.name == accountName)
              .firstOrNull;

          if (account != null) {
            final Uint8List fileBytes = file.content;
            final codec = await ui.instantiateImageCodec(fileBytes);
            final frame = await codec.getNextFrame();

            if (frame.image.width == 1000 && frame.image.height == 300) {
              final savedPath = await fileService.saveBytesToAppStorage(
                fileBytes,
                'bg_${account.id}_${DateTime.now().millisecondsSinceEpoch}.png',
              );
              ledgerProvider.updateAccount(
                account.id,
                account.name,
                account.currentBalance,
                colorHex: account.colorHex,
                minBalance: account.minBalance,
                backgroundImagePath: savedPath,
                clearBackgroundImage: false,
              );
              updatedAccountsCount++;
            }
          }
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedAccountsCount > 0
                  ? 'Successfully imported $updatedAccountsCount account backgrounds!'
                  : 'No valid matching backgrounds found in the zip.',
            ),
          ),
        );
      }
    }
  }
}
