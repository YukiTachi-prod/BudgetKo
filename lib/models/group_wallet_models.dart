import 'dart:math';

/// Locally stored member profile for identification in group wallets.
class GroupProfile {
  final String id;
  final String name;
  final int colorHex;

  const GroupProfile({
    required this.id,
    required this.name,
    required this.colorHex,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'colorHex': colorHex,
  };

  factory GroupProfile.fromJson(Map<String, dynamic> json) => GroupProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    colorHex: (json['colorHex'] as num).toInt(),
  );

  GroupProfile copyWith({String? id, String? name, int? colorHex}) {
    return GroupProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  /// Generates a RFC4122 v4 UUID without external dependencies.
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

/// Represents a shared collective budget / wallet hosted on Supabase.
class GroupWallet {
  final String id;
  final String name;
  final String? description;
  final String currency;
  final String createdByName;
  final String createdById;
  final DateTime createdAt;

  const GroupWallet({
    required this.id,
    required this.name,
    this.description,
    this.currency = '₱',
    required this.createdByName,
    required this.createdById,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    if (description != null) 'description': description,
    'currency': currency,
    'created_by_name': createdByName,
    'created_by_id': createdById,
    'created_at': createdAt.toIso8601String(),
  };

  factory GroupWallet.fromMap(Map<String, dynamic> map) {
    return GroupWallet(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unnamed Group',
      description: map['description']?.toString(),
      currency: map['currency']?.toString() ?? '₱',
      createdByName: map['created_by_name']?.toString() ?? 'Unknown',
      createdById: map['created_by_id']?.toString() ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// A member of a group wallet.
class GroupMember {
  final String id;
  final String walletId;
  final String userId;
  final String name;
  final int colorHex;
  final DateTime joinedAt;

  const GroupMember({
    required this.id,
    required this.walletId,
    required this.userId,
    required this.name,
    required this.colorHex,
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'wallet_id': walletId,
    'user_id': userId,
    'name': name,
    'color_hex': colorHex,
    'joined_at': joinedAt.toIso8601String(),
  };

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      id: map['id']?.toString() ?? '',
      walletId: map['wallet_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Anonymous',
      colorHex: (map['color_hex'] as num?)?.toInt() ?? 0xFF2196F3,
      joinedAt: map['joined_at'] != null
          ? DateTime.tryParse(map['joined_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// A financial transaction recorded in a group wallet.
class GroupTransaction {
  final String id;
  final String walletId;
  final double amount;
  final String transactionType; // 'expense', 'contribution', 'income'
  final String category;
  final String? notes;
  final String paidByName;
  final String paidById;
  final int paidByColorHex;
  final DateTime date;
  final DateTime createdAt;

  const GroupTransaction({
    required this.id,
    required this.walletId,
    required this.amount,
    required this.transactionType,
    required this.category,
    this.notes,
    required this.paidByName,
    required this.paidById,
    required this.paidByColorHex,
    required this.date,
    required this.createdAt,
  });

  bool get isExpense => transactionType.toLowerCase() == 'expense';
  bool get isContribution =>
      transactionType.toLowerCase() == 'contribution' ||
      transactionType.toLowerCase() == 'income';

  Map<String, dynamic> toMap() => {
    'id': id,
    'wallet_id': walletId,
    'amount': amount,
    'transaction_type': transactionType,
    'category': category,
    if (notes != null) 'notes': notes,
    'paid_by_name': paidByName,
    'paid_by_id': paidById,
    'paid_by_color_hex': paidByColorHex,
    'date': date.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };

  factory GroupTransaction.fromMap(Map<String, dynamic> map) {
    return GroupTransaction(
      id: map['id']?.toString() ?? '',
      walletId: map['wallet_id']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      transactionType: map['transaction_type']?.toString() ?? 'expense',
      category: map['category']?.toString() ?? 'General',
      notes: map['notes']?.toString(),
      paidByName: map['paid_by_name']?.toString() ?? 'Unknown',
      paidById: map['paid_by_id']?.toString() ?? '',
      paidByColorHex: (map['paid_by_color_hex'] as num?)?.toInt() ?? 0xFF2196F3,
      date: map['date'] != null
          ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
