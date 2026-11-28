import 'dart:math';

/// A single participant in a Temporary Group Pool.
class TempPoolParticipant {
  final String id;
  final String name;
  final double amountPaid;
  final double amountToPay;
  final String category;
  final String? owedTo;
  final String? notes;
  final bool isChangeResolved;

  const TempPoolParticipant({
    required this.id,
    required this.name,
    required this.amountPaid,
    required this.amountToPay,
    this.category = TempGroupPool.defaultCashCategory,
    this.owedTo,
    this.notes,
    this.isChangeResolved = false,
  });

  TempPoolParticipant copyWith({
    String? id,
    String? name,
    double? amountPaid,
    double? amountToPay,
    String? category,
    String? owedTo,
    bool clearOwedTo = false,
    String? notes,
    bool clearNotes = false,
    bool? isChangeResolved,
  }) {
    return TempPoolParticipant(
      id: id ?? this.id,
      name: name ?? this.name,
      amountPaid: amountPaid ?? this.amountPaid,
      amountToPay: amountToPay ?? this.amountToPay,
      category: category ?? this.category,
      owedTo: clearOwedTo ? null : (owedTo ?? this.owedTo),
      notes: clearNotes ? null : (notes ?? this.notes),
      isChangeResolved: isChangeResolved ?? this.isChangeResolved,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'amountPaid': amountPaid,
    'amountToPay': amountToPay,
    'category': category,
    if (owedTo != null && owedTo!.isNotEmpty) 'owedTo': owedTo,
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
    if (isChangeResolved) 'isChangeResolved': true,
  };

  factory TempPoolParticipant.fromJson(Map<String, dynamic> json) {
    return TempPoolParticipant(
      id: json['id']?.toString() ?? TempGroupPool.generateId(),
      name: json['name']?.toString() ?? 'Unnamed',
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0.0,
      amountToPay: (json['amountToPay'] as num?)?.toDouble() ?? 0.0,
      category:
          json['category']?.toString() ?? TempGroupPool.defaultCashCategory,
      owedTo: json['owedTo']?.toString(),
      notes: json['notes']?.toString(),
      isChangeResolved: json['isChangeResolved'] == true,
    );
  }
}

/// An isolated temporary group pool wallet for splitting bills / tracking
/// who paid what and how much change each person needs back.
/// Never interacts with the user's personal accounts or ledger.
class TempGroupPool {
  static const String defaultCashCategory = 'Cash';
  static const String defaultECashCategory = 'E-Cash';
  static const List<String> defaultCategories = [
    defaultCashCategory,
    defaultECashCategory,
  ];

  final String id;
  final String name;
  final String currency;
  final bool isEqualShare;
  final double equalShareAmount;
  final List<String> categories;
  final List<TempPoolParticipant> participants;
  final DateTime createdAt;

  const TempGroupPool({
    required this.id,
    required this.name,
    this.currency = '₱',
    this.isEqualShare = false,
    this.equalShareAmount = 0.0,
    this.categories = defaultCategories,
    this.participants = const [],
    required this.createdAt,
  });

  /// Effective amount a participant needs to pay, respecting equal-share mode.
  double effectiveAmountToPay(TempPoolParticipant participant) {
    return isEqualShare ? equalShareAmount : participant.amountToPay;
  }

  /// Positive = change to return to this person.
  /// Negative = amount this person still owes.
  /// Zero = exact payment.
  double changeFor(TempPoolParticipant participant) {
    return participant.amountPaid - effectiveAmountToPay(participant);
  }

  /// Net amount currently held in the pool for a participant (subtracts
  /// returned change once marked resolved).
  double netContributedBy(TempPoolParticipant participant) {
    final change = changeFor(participant);
    if (participant.isChangeResolved && change > 0) {
      return participant.amountPaid - change;
    }
    return participant.amountPaid;
  }

  /// Total money currently collected in the pool (excluding returned change).
  double get totalPooled =>
      participants.fold(0.0, (sum, p) => sum + netContributedBy(p));

  /// Total bill expected across all participants.
  double get totalExpected =>
      participants.fold(0.0, (sum, p) => sum + effectiveAmountToPay(p));

  /// Total change that still needs to be handed back to overpaying participants.
  double get totalChangeBack => participants.fold(0.0, (sum, p) {
    if (p.isChangeResolved) return sum;
    final diff = changeFor(p);
    return diff > 0 ? sum + diff : sum;
  });

  /// Total amount still owed by underpaying participants.
  double get totalStillOwed => participants.fold(0.0, (sum, p) {
    final diff = changeFor(p);
    return diff < 0 ? sum + diff.abs() : sum;
  });

  /// Net surplus or deficit of the pool relative to the expected bill.
  double get netBalance => totalPooled - totalExpected;

  /// Breakdown of pooled money by payment category (e.g. Cash, E-Cash).
  Map<String, double> get categoryTotals {
    final Map<String, double> totals = {for (final cat in categories) cat: 0.0};
    for (final p in participants) {
      totals[p.category] = (totals[p.category] ?? 0.0) + netContributedBy(p);
    }
    return totals;
  }

  TempGroupPool copyWith({
    String? id,
    String? name,
    String? currency,
    bool? isEqualShare,
    double? equalShareAmount,
    List<String>? categories,
    List<TempPoolParticipant>? participants,
    DateTime? createdAt,
  }) {
    return TempGroupPool(
      id: id ?? this.id,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      isEqualShare: isEqualShare ?? this.isEqualShare,
      equalShareAmount: equalShareAmount ?? this.equalShareAmount,
      categories: categories ?? this.categories,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'currency': currency,
    'isEqualShare': isEqualShare,
    'equalShareAmount': equalShareAmount,
    'categories': categories,
    'participants': participants.map((p) => p.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory TempGroupPool.fromJson(Map<String, dynamic> json) {
    final rawCategories = (json['categories'] as List?)
        ?.map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();
    final categories = (rawCategories == null || rawCategories.isEmpty)
        ? List<String>.from(defaultCategories)
        : rawCategories;

    final rawParticipants = (json['participants'] as List?) ?? const [];
    final participants = rawParticipants
        .whereType<Map>()
        .map((m) => TempPoolParticipant.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    return TempGroupPool(
      id: json['id']?.toString() ?? generateId(),
      name: json['name']?.toString() ?? 'Temporary Pool',
      currency: json['currency']?.toString() ?? '₱',
      isEqualShare: json['isEqualShare'] == true,
      equalShareAmount: (json['equalShareAmount'] as num?)?.toDouble() ?? 0.0,
      categories: categories,
      participants: participants,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Generates a unique ID without external dependencies.
  static String generateId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    return [
      bytes
          .sublist(0, 4)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(),
      bytes
          .sublist(4, 6)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(),
      bytes
          .sublist(6, 8)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(),
      bytes
          .sublist(8, 10)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(),
      bytes
          .sublist(10, 16)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(),
    ].join('-');
  }
}
