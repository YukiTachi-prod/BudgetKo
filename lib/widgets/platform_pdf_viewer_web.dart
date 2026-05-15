import 'package:flutter/material.dart';

class PlatformPdfViewer extends StatelessWidget {
  final String path;

  const PlatformPdfViewer({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.picture_as_pdf, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('PDF viewing is not available in the browser.'),
        ],
      ),
    );
  }
}
