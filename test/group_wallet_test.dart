import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasker/models/group_wallet_models.dart';
import 'package:tasker/providers/group_wallet_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GroupProfile Model & Provider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('GroupProfile serialization and UUID generation', () {
      final id = GroupProfile.generateId();
      expect(id.length, 36); // standard UUID v4 format
      expect(id.contains('-'), isTrue);

      final profile = GroupProfile(id: id, name: 'Alex', colorHex: 0xFF9C27B0);

      final json = profile.toJson();
      final reconstructed = GroupProfile.fromJson(json);

      expect(reconstructed.id, profile.id);
      expect(reconstructed.name, 'Alex');
      expect(reconstructed.colorHex, 0xFF9C27B0);
    });

    test('GroupWalletProvider saves and loads local profile', () async {
      final provider = GroupWalletProvider();
      await provider.preload();
      expect(provider.hasProfile, isFalse);

      await provider.saveProfile('Sam', 0xFF2196F3);
      expect(provider.hasProfile, isTrue);
      expect(provider.profile?.name, 'Sam');
      expect(provider.profile?.colorHex, 0xFF2196F3);

      // Verify persistence across provider instances
      final newProvider = GroupWalletProvider();
      await newProvider.preload();
      expect(newProvider.hasProfile, isTrue);
      expect(newProvider.profile?.name, 'Sam');
      expect(newProvider.profile?.colorHex, 0xFF2196F3);
      expect(newProvider.profile?.password, '');

      // Save with password and verify persistence
      await newProvider.saveProfile('Sam', 0xFF2196F3, password: 'secret123');
      final thirdProvider = GroupWalletProvider();
      await thirdProvider.preload();
      expect(thirdProvider.profile?.password, 'secret123');
    });

    test('MemberClaimResult reclaims existing name with matching password or empty legacy password without duplicates', () {
      final now = DateTime.now();
      final members = [
        GroupMember(
          id: 'm1',
          walletId: 'w1',
          userId: 'orig-alex-id',
          name: 'Alex',
          colorHex: 0xFF111111,
          password: 'pw123',
          joinedAt: now,
        ),
        GroupMember(
          id: 'm2',
          walletId: 'w1',
          userId: 'legacy-sam-id',
          name: 'Sam',
          colorHex: 0xFF222222,
          // Legacy member with empty password
          joinedAt: now,
        ),
      ];

      // Rejoining Alex with a fresh device userId + correct password reclaims orig-alex-id
      final reclaimAlex = MemberClaimResult.resolve(
        existingMembers: members,
        profile: const GroupProfile(
          id: 'new-device-id',
          name: 'alex',
          colorHex: 0xFF333333,
          password: 'pw123',
        ),
      );
      expect(reclaimAlex.status, MemberClaimStatus.reclaimedByName);
      expect(reclaimAlex.matchedMember?.userId, 'orig-alex-id');

      // Rejoining Alex with wrong password is rejected
      final wrongPw = MemberClaimResult.resolve(
        existingMembers: members,
        profile: const GroupProfile(
          id: 'new-device-id',
          name: 'Alex',
          colorHex: 0xFF333333,
          password: 'wrong',
        ),
      );
      expect(wrongPw.status, MemberClaimStatus.wrongPassword);

      // Rejoining legacy Sam with empty password reclaims legacy-sam-id
      final reclaimLegacy = MemberClaimResult.resolve(
        existingMembers: members,
        profile: const GroupProfile(
          id: 'new-device-id',
          name: 'Sam',
          colorHex: 0xFF333333,
          password: '',
        ),
      );
      expect(reclaimLegacy.status, MemberClaimStatus.reclaimedByName);
      expect(reclaimLegacy.matchedMember?.userId, 'legacy-sam-id');

      // Brand new name is allowed as newMember
      final brandNew = MemberClaimResult.resolve(
        existingMembers: members,
        profile: const GroupProfile(
          id: 'new-device-id',
          name: 'Jamie',
          colorHex: 0xFF444444,
          password: 'abc',
        ),
      );
      expect(brandNew.status, MemberClaimStatus.newMember);
    });

    test('WalletDeleteVoteSummary enforces at least 2/3 majority threshold', () {
      expect(WalletDeleteVoteSummary.requiredVotesFor(1), 1);
      expect(WalletDeleteVoteSummary.requiredVotesFor(2), 2);
      expect(WalletDeleteVoteSummary.requiredVotesFor(3), 2);
      expect(WalletDeleteVoteSummary.requiredVotesFor(4), 3);
      expect(WalletDeleteVoteSummary.requiredVotesFor(5), 4);
      expect(WalletDeleteVoteSummary.requiredVotesFor(6), 4);

      final now = DateTime.now();
      final oneVote = WalletDeleteVoteSummary(
        walletId: 'w1',
        walletName: 'Trip',
        totalMembers: 3,
        votes: [
          WalletDeleteVote(
            id: 'v1',
            walletId: 'w1',
            userId: 'u1',
            userName: 'Alex',
            createdAt: now,
          ),
        ],
      );
      expect(oneVote.hasReachedThreshold, isFalse);

      final twoVotes = WalletDeleteVoteSummary(
        walletId: 'w1',
        walletName: 'Trip',
        totalMembers: 3,
        votes: [
          ...oneVote.votes,
          WalletDeleteVote(
            id: 'v2',
            walletId: 'w1',
            userId: 'u2',
            userName: 'Sam',
            createdAt: now,
          ),
        ],
      );
      expect(twoVotes.hasReachedThreshold, isTrue);
    });
  });

  group('Group Models & Collective Math Tests', () {
    test('GroupWallet and GroupTransaction serialization', () {
      final now = DateTime.now();
      final wallet = GroupWallet(
        id: 'wallet-123',
        name: 'Tokyo Trip',
        currency: '¥',
        createdByName: 'Alex',
        createdById: 'user-1',
        createdAt: now,
      );

      final walletMap = wallet.toMap();
      final restoredWallet = GroupWallet.fromMap(walletMap);
      expect(restoredWallet.id, 'wallet-123');
      expect(restoredWallet.name, 'Tokyo Trip');
      expect(restoredWallet.currency, '¥');

      final tx = GroupTransaction(
        id: 'tx-1',
        walletId: 'wallet-123',
        amount: 5000.0,
        transactionType: 'expense',
        category: 'Food',
        notes: 'Sushi dinner',
        paidByName: 'Alex',
        paidById: 'user-1',
        paidByColorHex: 0xFF9C27B0,
        date: now,
        createdAt: now,
      );

      final txMap = tx.toMap();
      final restoredTx = GroupTransaction.fromMap(txMap);
      expect(restoredTx.id, 'tx-1');
      expect(restoredTx.amount, 5000.0);
      expect(restoredTx.isExpense, isTrue);
      expect(restoredTx.isContribution, isFalse);
    });

    test('Collective budget calculations', () {
      final txs = [
        GroupTransaction(
          id: '1',
          walletId: 'w1',
          amount: 10000.0,
          transactionType: 'contribution',
          category: 'Pool',
          paidByName: 'Alex',
          paidById: 'u1',
          paidByColorHex: 0xFF111111,
          date: DateTime.now(),
          createdAt: DateTime.now(),
        ),
        GroupTransaction(
          id: '2',
          walletId: 'w1',
          amount: 5000.0,
          transactionType: 'contribution',
          category: 'Pool',
          paidByName: 'Sam',
          paidById: 'u2',
          paidByColorHex: 0xFF222222,
          date: DateTime.now(),
          createdAt: DateTime.now(),
        ),
        GroupTransaction(
          id: '3',
          walletId: 'w1',
          amount: 3000.0,
          transactionType: 'expense',
          category: 'Groceries',
          paidByName: 'Alex',
          paidById: 'u1',
          paidByColorHex: 0xFF111111,
          date: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      ];

      // Pool balance = (10000 + 5000) - 3000 = 12000
      double pool = 0.0;
      for (var t in txs) {
        if (t.isContribution) {
          pool += t.amount;
        } else {
          pool -= t.amount;
        }
      }
      expect(pool, 12000.0);

      // Alex contributions: 10000; Sam contributions: 5000
      final contribMap = <String, double>{};
      for (var t in txs.where((x) => x.isContribution)) {
        contribMap[t.paidByName] = (contribMap[t.paidByName] ?? 0.0) + t.amount;
      }
      expect(contribMap['Alex'], 10000.0);
      expect(contribMap['Sam'], 5000.0);

      // Alex expense: 3000
      final expenseMap = <String, double>{};
      for (var t in txs.where((x) => x.isExpense)) {
        expenseMap[t.paidByName] = (expenseMap[t.paidByName] ?? 0.0) + t.amount;
      }
      expect(expenseMap['Alex'], 3000.0);
    });
  });
}
