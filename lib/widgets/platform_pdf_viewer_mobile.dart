import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

class PlatformPdfViewer extends StatelessWidget {
  final String path;

  const PlatformPdfViewer({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) {
      return SfPdfViewer.file(File(path));
    }
    return _DesktopPdfOpener(path: path);
  }
}

class _DesktopPdfOpener extends StatelessWidget {
  final String path;

  const _DesktopPdfOpener({required this.path});

  @override
  Widget build(BuildContext context) {
    final filename = path.split(Platform.pathSeparator).last;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.picture_as_pdf_rounded,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(filename, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open with system viewer'),
            onPressed: () =>
                launchUrl(Uri.file(path), mode: LaunchMode.externalApplication),
          ),
        ],
      ),
    );
  }
}
