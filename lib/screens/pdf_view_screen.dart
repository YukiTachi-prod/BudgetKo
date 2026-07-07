import 'package:flutter/material.dart';
import '../widgets/platform_pdf_viewer.dart';

class PdfViewScreen extends StatelessWidget {
  final String path;
  final String title;

  const PdfViewScreen({super.key, required this.path, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PlatformPdfViewer(path: path),
    );
  }
}
