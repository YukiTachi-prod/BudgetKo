import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

class PlatformFileService {
  static final PlatformFileService _instance = PlatformFileService._internal();
  factory PlatformFileService() => _instance;
  PlatformFileService._internal();

  bool get supportsPdfAttachment => false;

  Future<String> copyPdfToAppStorage(String sourcePath) async =>
      throw UnsupportedError('PDF storage is not supported on web.');

  void deletePdfFile(String path) {}

  bool pdfFileExists(String path) => false;

  Future<String> saveExportZip(Uint8List bytes, String filename) async {
    _triggerDownload(bytes, filename, 'application/zip');
    return filename;
  }

  Future<void> shareZip(Uint8List bytes, String filename) async {
    _triggerDownload(bytes, filename, 'application/zip');
  }

  void _triggerDownload(Uint8List bytes, String filename, String mimeType) {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: mimeType),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = filename;
    anchor.click();
    web.URL.revokeObjectURL(url);
  }
}
