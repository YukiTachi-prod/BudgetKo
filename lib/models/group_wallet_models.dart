import 'dart:math';

/// Locally stored member profile for identification in group wallets.
class GroupProfile {
  final String id;
  final String name;
  final int colorHex;
  final String password;

  const GroupProfile({
    required this.id,
    required this.name,
    required this.colorHex,
    this.password = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'colorHex': colorHex,
    if (password.isNotEmpty) 'password': password,
  };

  factory GroupProfile.fromJson(Map<String, dynamic> json) => GroupProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    colorHex: (json['colorHex'] as num).toInt(),
    password: json['password']?.toString() ?? '',
  );

  GroupProfile copyWith({
    String? id,
    String? name,
    int? colorHex,
    String? password,
  }) {
    return GroupProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      password: password ?? this.password,
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
  final String password;
  final DateTime joinedAt;

  const GroupMember({
    required this.id,
    required this.walletId,
    required this.userId,
    required this.name,
    required this.colorHex,
    this.password = '',
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'wallet_id': walletId,
    'user_id': userId,
    'name': name,
    'color_hex': colorHex,
    'password': password,
    'joined_at': joinedAt.toIso8601String(),
  };

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      id: map['id']?.toString() ?? '',
      walletId: map['wallet_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Anonymous',
      colorHex: (map['color_hex'] as num?)?.toInt() ?? 0xFF2196F3,
      password: map['password']?.toString() ?? '',
      joinedAt: map['joined_at'] != null
          ? DateTime.tryParse(map['joined_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

enum MemberClaimStatus {
  matchedById,
  reclaimedByName,
  newMember,
  wrongPassword,
}

class MemberClaimResult {
  final MemberClaimStatus status;
  final GroupMember? matchedMember;

  const MemberClaimResult(this.status, [this.matchedMember]);

  /// Resolves how [profile] maps onto [existingMembers] of a specific wallet.
  ///
  /// - If another member already uses the same name (case-insensitive):
  ///   - Matching password (including empty string for legacy names) reclaims
  ///     that existing member's identity so no duplicate row is created.
  ///   - Non-matching password returns [MemberClaimStatus.wrongPassword].
  /// - Otherwise, if [profile.id] already exists in [existingMembers], returns
  ///   [MemberClaimStatus.matchedById].
  /// - Otherwise returns [MemberClaimStatus.newMember].
  static MemberClaimResult resolve({
    required List<GroupMember> existingMembers,
    required GroupProfile profile,
  }) {
    final normalizedName = profile.name.trim().toLowerCase();

    for (final member in existingMembers) {
      if (member.userId != profile.id &&
          member.name.trim().toLowerCase() == normalizedName) {
        if (member.password == profile.password) {
          return MemberClaimResult(MemberClaimStatus.reclaimedByName, member);
        }
        return MemberClaimResult(MemberClaimStatus.wrongPassword, member);
      }
    }

    for (final member in existingMembers) {
      if (member.userId == profile.id) {
        return MemberClaimResult(MemberClaimStatus.matchedById, member);
      }
    }

    return const MemberClaimResult(MemberClaimStatus.newMember);
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

/// A single member's confirmation vote to remove a group wallet.
class WalletDeleteVote {
  final String id;
  final String walletId;
  final String userId;
  final String userName;
  final DateTime createdAt;

  const WalletDeleteVote({
    required this.id,
    required this.walletId,
    required this.userId,
    required this.userName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'wallet_id': walletId,
    'user_id': userId,
    'user_name': userName,
    'created_at': createdAt.toIso8601String(),
  };

  factory WalletDeleteVote.fromMap(Map<String, dynamic> map) {
    return WalletDeleteVote(
      id: map['id']?.toString() ?? '',
      walletId: map['wallet_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      userName: map['user_name']?.toString() ?? 'A member',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Tracks an active removal vote for a group wallet and evaluates the 2/3 threshold.
class WalletDeleteVoteSummary {
  final String walletId;
  final String walletName;
  final int totalMembers;
  final List<WalletDeleteVote> votes;

  const WalletDeleteVoteSummary({
    required this.walletId,
    required this.walletName,
    required this.totalMembers,
    required this.votes,
  });

  /// Minimum number of votes required (at least 2/3 of members, rounded up).
  static int requiredVotesFor(int memberCount) {
    if (memberCount <= 1) return 1;
    return ((memberCount * 2) / 3).ceil();
  }

  int get requiredVotes => requiredVotesFor(totalMembers);
  int get voteCount => votes.length;
  bool get hasReachedThreshold => voteCount >= requiredVotes;
  bool hasVoted(String userId) => votes.any((v) => v.userId == userId);
  String get initiatorName =>
      votes.isNotEmpty ? votes.first.userName : 'A member';
}

enum VoteDeleteResult { voted, deleted, failed }
