import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/platform/platform_file_service.dart';
import '../providers/ledger_provider.dart';

class SavedBackgroundsScreen extends StatefulWidget {
  const SavedBackgroundsScreen({super.key});

  @override
  State<SavedBackgroundsScreen> createState() => _SavedBackgroundsScreenState();
}

class _SavedBackgroundsScreenState extends State<SavedBackgroundsScreen> {
  List<String> _backgrounds = [];
  Set<String> _selectedBackgrounds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadBackgrounds();
  }

  Future<void> _loadBackgrounds() async {
    final bgs = await PlatformFileService().getSavedBackgrounds();
    setState(() {
      _backgrounds = bgs;
      _selectedBackgrounds.retainWhere((bg) => _backgrounds.contains(bg));
      if (_backgrounds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedBackgrounds.clear();
    });
  }

  void _toggleSelection(String path) {
    setState(() {
      if (_selectedBackgrounds.contains(path)) {
        _selectedBackgrounds.remove(path);
        if (_selectedBackgrounds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedBackgrounds.add(path);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedBackgrounds.length == _backgrounds.length) {
        _selectedBackgrounds.clear();
        _isSelectionMode = false;
      } else {
        _selectedBackgrounds = _backgrounds.toSet();
      }
    });
  }

  Future<void> _deleteSelectedBackgrounds() async {
    final ledgerProvider = context.read<LedgerProvider>();
    for (var path in _selectedBackgrounds) {
      // Clear from any account using it
      for (var acc in ledgerProvider.accounts) {
        if (acc.backgroundImagePath == path) {
          ledgerProvider.updateAccount(
            acc.id,
            acc.name,
            acc.currentBalance,
            colorHex: acc.colorHex,
            minBalance: acc.minBalance,
            backgroundImagePath: null,
            clearBackgroundImage: true,
          );
        }
      }

      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }

    setState(() {
      _isSelectionMode = false;
      _selectedBackgrounds.clear();
    });
    _loadBackgrounds();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        title: Text(
          _isSelectionMode
              ? '${_selectedBackgrounds.length} Selected'
              : 'Saved Backgrounds',
        ),
        actions: [
          if (_backgrounds.isNotEmpty)
            if (_isSelectionMode) ...[
              TextButton(
                onPressed: _selectAll,
                child: Text(
                  _selectedBackgrounds.length == _backgrounds.length
                      ? 'Deselect All'
                      : 'Select All',
                  style: TextStyle(
                    color: theme.brightness == Brightness.dark
                        ? Colors.blue.shade200
                        : Colors.blue,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: _selectedBackgrounds.isEmpty
                    ? null
                    : () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Selected Backgrounds?'),
                            content: Text(
                              'Are you sure you want to delete ${_selectedBackgrounds.length} background(s)? Any accounts using them will lose their background.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _deleteSelectedBackgrounds();
                                },
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
              ),
            ] else ...[
              TextButton(
                onPressed: _toggleSelectionMode,
                child: Text(
                  'Select',
                  style: TextStyle(
                    color: theme.brightness == Brightness.dark
                        ? Colors.blue.shade200
                        : Colors.blue,
                  ),
                ),
              ),
            ],
        ],
      ),
      body: _backgrounds.isEmpty
          ? const Center(child: Text('No saved backgrounds found.'))
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1000 / 300,
              ),
              itemCount: _backgrounds.length,
              itemBuilder: (context, index) {
                final path = _backgrounds[index];
                final name = path.split('/').last;
                final isSelected = _selectedBackgrounds.contains(path);

                return GestureDetector(
                  onLongPress: () {
                    if (!_isSelectionMode) {
                      setState(() {
                        _isSelectionMode = true;
                        _selectedBackgrounds.add(path);
                      });
                    }
                  },
                  onTap: () {
                    if (_isSelectionMode) {
                      _toggleSelection(path);
                    }
                  },
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: isSelected
                                ? Border.all(color: Colors.blueGrey, width: 2)
                                : null,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              isSelected ? 4 : 6,
                            ),
                            child: isSelected
                                ? ColorFiltered(
                                    colorFilter: ColorFilter.mode(
                                      Colors.black.withValues(alpha: 0.4),
                                      BlendMode.darken,
                                    ),
                                    child: Image.file(
                                      File(path),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Image.file(File(path), fit: BoxFit.cover),
                          ),
                        ),
                      ),
                      if (!_isSelectionMode)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Background?'),
                                    content: Text(
                                      'Are you sure you want to delete "$name"? Any account using it will lose its background.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          _selectedBackgrounds = {path};
                                          _deleteSelectedBackgrounds();
                                        },
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      if (_isSelectionMode)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: isSelected ? Colors.blue : Colors.white70,
                          ),
                        ),
                      Positioned(
                        bottom: 4,
                        left: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          color: Colors.black54,
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
