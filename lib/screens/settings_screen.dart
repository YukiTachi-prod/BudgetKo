import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
