import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class ImportExportService {
  static final DateFormat _dateFormat = DateFormat('MM/dd/yyyy');

  Future<List<Task>> importFromZip(Uint8List zipData) async {
    final archive = ZipDecoder().decodeBytes(zipData);
    final List<Task> importedTasks = [];

    for (final file in archive) {
      if (file.isFile && file.name.endsWith('.md')) {
        final content = utf8.decode(file.content as List<int>);
        final task = _parseMarkdown(content, file.name);
        if (task != null) {
          importedTasks.add(task);
        }
      }
    }
    return importedTasks;
  }

  Task? _parseMarkdown(String content, String fileName) {
    try {
      final lines = content.split('\n');
      String title = fileName.replaceAll('.md', '');
      String category = 'Uncategorized';
      String statusStr = 'Not Started';
      bool isFinished = false;
      DateTime dueDate = DateTime.now();
      String description = '';

      // Try to find Title from # header
      final titleMatch = RegExp(
        r'^#\s+(.*)$',
      ).firstMatch(lines.isNotEmpty ? lines[0] : '');
      if (titleMatch != null) {
        title = titleMatch.group(1)!.trim();
      }

      int metadataEndIndex = 0;
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('Course:')) {
          category = line.replaceFirst('Course:', '').trim();
          metadataEndIndex = i;
        } else if (line.startsWith('Status:')) {
          statusStr = line.replaceFirst('Status:', '').trim();
          if (statusStr.toLowerCase() == 'done') {
            statusStr = 'Finished';
          }
          isFinished =
              statusStr.toLowerCase().contains('finished') ||
              statusStr.toLowerCase().contains('done');
          metadataEndIndex = i;
        } else if (line.startsWith('Due date:')) {
          final dateStr = line.replaceFirst('Due date:', '').trim();
          try {
            dueDate = _dateFormat.parse(dateStr);
          } catch (e) {
            // Fallback parsing if format differs
            dueDate = DateTime.tryParse(dateStr) ?? DateTime.now();
          }
          metadataEndIndex = i;
        } else if (line.startsWith('##')) {
          // Description often starts after ## or blank lines
          metadataEndIndex = i - 1;
          break;
        }
      }

      description = lines.skip(metadataEndIndex + 1).join('\n').trim();

      return Task(
        id:
            DateTime.now().millisecondsSinceEpoch.toString() +
            fileName.hashCode.toString(),
        title: title,
        description: description,
        date: dueDate,
        status: statusStr,
        category: category,
        isFinished: isFinished,
      );
    } catch (e) {
      return null;
    }
  }

  Uint8List exportToZip(List<Task> tasks) {
    final archive = Archive();

    for (final task in tasks) {
      final content = _generateMarkdown(task);
      final fileName =
          '${task.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')}.md';
      final fileData = utf8.encode(content);
      archive.addFile(ArchiveFile(fileName, fileData.length, fileData));
    }

    return Uint8List.fromList(ZipEncoder().encode(archive)!);
  }

  String _generateMarkdown(Task task) {
    final dueDateStr = _dateFormat.format(task.date);

    return '''# ${task.title}

Course: ${task.category}
Status: ${task.status}
Assignee: User
Due date: $dueDateStr

## Description

${task.description}
''';
  }
}
