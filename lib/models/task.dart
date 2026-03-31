class Task {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String category;
  final bool isFinished;
  final String? pdfPath;
  final bool isPdfCopied;
  final bool isLocked;
  final bool isRoutine;
  final String? repeatInterval; // e.g., 'Daily', 'Weekly', 'Monthly'

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.category,
    this.isFinished = false,
    this.pdfPath,
    this.isPdfCopied = false,
    this.isLocked = false,
    this.isRoutine = false,
    this.repeatInterval,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      'category': category,
      'isFinished': isFinished,
      'pdfPath': pdfPath,
      'isPdfCopied': isPdfCopied,
      'isLocked': isLocked,
      'isRoutine': isRoutine,
      'repeatInterval': repeatInterval,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    // Migration: handle old 'date' field
    DateTime? oldDate;
    if (json['date'] != null) {
      oldDate = DateTime.parse(json['date']);
    }

    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate']) 
          : (oldDate ?? DateTime.now()),
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate']) 
          : (oldDate ?? DateTime.now()),
      status: json['status'] ?? 'Not Started',
      category: json['category'],
      isFinished: json['isFinished'] ?? false,
      pdfPath: json['pdfPath'],
      isPdfCopied: json['isPdfCopied'] ?? false,
      isLocked: json['isLocked'] ?? false,
      isRoutine: json['isRoutine'] ?? false,
      repeatInterval: json['repeatInterval'],
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? category,
    bool? isFinished,
    String? pdfPath,
    bool? isPdfCopied,
    bool? isLocked,
    bool? isRoutine,
    String? repeatInterval,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      category: category ?? this.category,
      isFinished: isFinished ?? this.isFinished,
      pdfPath: pdfPath ?? this.pdfPath,
      isPdfCopied: isPdfCopied ?? this.isPdfCopied,
      isLocked: isLocked ?? this.isLocked,
      isRoutine: isRoutine ?? this.isRoutine,
      repeatInterval: repeatInterval ?? this.repeatInterval,
    );
  }
}
