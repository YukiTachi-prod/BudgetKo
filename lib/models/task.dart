class Task {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String status;
  final String category;
  final bool isFinished;
  final String? pdfPath;
  final bool isPdfCopied;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.status,
    required this.category,
    this.isFinished = false,
    this.pdfPath,
    this.isPdfCopied = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'status': status,
      'category': category,
      'isFinished': isFinished,
      'pdfPath': pdfPath,
      'isPdfCopied': isPdfCopied,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      status: json['status'] ?? json['priority'] ?? 'Not Started',
      category: json['category'],
      isFinished: json['isFinished'] ?? false,
      pdfPath: json['pdfPath'],
      isPdfCopied: json['isPdfCopied'] ?? false,
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? status,
    String? category,
    bool? isFinished,
    String? pdfPath,
    bool? isPdfCopied,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      status: status ?? this.status,
      category: category ?? this.category,
      isFinished: isFinished ?? this.isFinished,
      pdfPath: pdfPath ?? this.pdfPath,
      isPdfCopied: isPdfCopied ?? this.isPdfCopied,
    );
  }
}
