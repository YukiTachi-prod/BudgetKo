import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

class PlatformFileService {
  static final PlatformFileService _instance = PlatformFileService._internal();
  factory PlatformFileService() => _instance;
  PlatformFileService._internal();

  bool get supportsPdfAttachment => true;

  Future<String> copyPdfToAppStorage(String sourcePath) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory(p.join(docsDir.path, 'task_pdfs'));
    if (!pdfDir.existsSync()) pdfDir.createSync(recursive: true);

    final fileName = p.basename(sourcePath);
    final destPath = p.join(
      pdfDir.path,
      '${DateTime.now().millisecondsSinceEpoch}_$fileName',
    );
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  void deletePdfFile(String path) {
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
  }

  bool pdfFileExists(String path) => File(path).existsSync();

  Future<String> saveExportZip(Uint8List bytes, String filename) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final filePath = p.join(docsDir.path, filename);
    await File(filePath).writeAsBytes(bytes);
    return filePath;
  }

  Future<void> shareZip(Uint8List bytes, String filename) async {
    final tempDir = await getTemporaryDirectory();
    final filePath = p.join(tempDir.path, filename);
    await File(filePath).writeAsBytes(bytes);
    await Share.shareXFiles([XFile(filePath)], text: 'Sharing TASKo data');
  }
}
