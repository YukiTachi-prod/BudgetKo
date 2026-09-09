import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

class PlatformFileService {
  static final PlatformFileService _instance = PlatformFileService._internal();
  factory PlatformFileService() => _instance;
  PlatformFileService._internal();

  Future<String> copyFileToAppStorage(
    String sourcePath,
    String fileName,
  ) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final destPath = p.join(docsDir.path, fileName);
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  Future<String> saveBytesToAppStorage(Uint8List bytes, String fileName) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final destPath = p.join(docsDir.path, fileName);
    await File(destPath).writeAsBytes(bytes);
    return destPath;
  }

  Future<bool> fileExistsInAppStorage(String fileName) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final destPath = p.join(docsDir.path, fileName);
    return File(destPath).existsSync();
  }

  Future<List<String>> getSavedBackgrounds() async {
    final docsDir = await getApplicationDocumentsDirectory();
    return docsDir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.png'))
        .map((file) => file.path)
        .toList();
  }

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
    await SharePlus.instance.share(
      ShareParams(files: [XFile(filePath)], text: 'Sharing BulsaKo data'),
    );
  }

  Future<void> shareFile(
    Uint8List bytes,
    String filename, {
    String text = 'File from BulsaKo',
  }) async {
    final tempDir = await getTemporaryDirectory();
    final filePath = p.join(tempDir.path, filename);
    await File(filePath).writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(filePath)], text: text),
    );
  }
}
