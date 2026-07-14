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
  final bool isAlarm;
  final bool hasDates;
  final String? repeatInterval; // e.g., 'Daily', 'Weekly', 'Monthly'
  final DateTime? alarmTriggerDate;
  final int? ringIntervalValue;
  final String? ringIntervalUnit;

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
    this.isAlarm = false,
    this.hasDates = true,
    this.repeatInterval,
    this.alarmTriggerDate,
    this.ringIntervalValue,
    this.ringIntervalUnit,
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
      'isAlarm': isAlarm,
      'hasDates': hasDates,
      'repeatInterval': repeatInterval,
      'alarmTriggerDate': alarmTriggerDate?.toIso8601String(),
      'ringIntervalValue': ringIntervalValue,
      'ringIntervalUnit': ringIntervalUnit,
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
      isAlarm: json['isAlarm'] ?? false,
      hasDates: json['hasDates'] ?? true,
      repeatInterval: json['repeatInterval'],
      alarmTriggerDate: json['alarmTriggerDate'] != null
          ? DateTime.parse(json['alarmTriggerDate'])
          : null,
      ringIntervalValue: json['ringIntervalValue'],
      ringIntervalUnit: json['ringIntervalUnit'],
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
    bool? isAlarm,
    bool? hasDates,
    String? repeatInterval,
    DateTime? alarmTriggerDate,
    int? ringIntervalValue,
    String? ringIntervalUnit,
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
      isAlarm: isAlarm ?? this.isAlarm,
      hasDates: hasDates ?? this.hasDates,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      alarmTriggerDate: alarmTriggerDate ?? this.alarmTriggerDate,
      ringIntervalValue: ringIntervalValue ?? this.ringIntervalValue,
      ringIntervalUnit: ringIntervalUnit ?? this.ringIntervalUnit,
    );
  }
}
