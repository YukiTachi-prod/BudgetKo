import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasker/models/group_wallet_models.dart';
import 'package:tasker/providers/group_wallet_provider.dart';
import 'package:tasker/providers/settings_provider.dart';
import 'package:tasker/screens/group_wallet_screen.dart';

class TestGroupWalletProvider extends GroupWalletProvider {
  bool deleteWalletCalled = false;
  bool leaveWalletCalled = false;
  bool initiateVoteCalled = false;
  String? lastDeletedId;
  String? lastLeftId;
  final List<GroupWallet> _testWallets;
  final List<GroupMember> _testMembers;
  final Map<String, List<WalletDeleteVote>> _testVotes = {};

  TestGroupWalletProvider(this._testWallets, {List<GroupMember>? members})
    : _testMembers = members ?? [];

  @override
  bool get hasProfile => true;

  @override
  GroupProfile? get profile =>
      const GroupProfile(id: 'u1', name: 'Test User', colorHex: 0xFF2196F3);

  @override
  bool get isConfigured => true;

  @override
  bool get isConnected => true;

  @override
  bool get isTablesReady => true;

  @override
  List<GroupWallet> get wallets => _testWallets;

  @override
  GroupWallet? get currentWallet =>
      _testWallets.isNotEmpty ? _testWallets.first : null;

  @override
  List<GroupMember> get members => _testMembers;

  @override
  WalletDeleteVoteSummary? deleteVoteSummaryFor(String walletId) {
    final votes = _testVotes[walletId];
    if (votes == null || votes.isEmpty) return null;
    final wallet = _testWallets.cast<GroupWallet?>().firstWhere(
      (w) => w?.id == walletId,
      orElse: () => null,
    );
    return WalletDeleteVoteSummary(
      walletId: walletId,
      walletName: wallet?.name ?? 'Group Wallet',
      totalMembers: _testMembers.isEmpty ? 1 : _testMembers.length,
      votes: votes,
    );
  }

  @override
  List<WalletDeleteVoteSummary> get pendingDeleteVotes => [
    for (final w in _testWallets)
      if (deleteVoteSummaryFor(w.id) != null) deleteVoteSummaryFor(w.id)!,
  ];

  Completer<bool>? addTransactionCompleter;

  @override
  Future<void> leaveWallet(String walletId) async {
    leaveWalletCalled = true;
    lastLeftId = walletId;
    _testWallets.removeWhere((w) => w.id == walletId);
    notifyListeners();
  }

  @override
  Future<VoteDeleteResult> initiateOrConfirmDeleteVote(String walletId) async {
    initiateVoteCalled = true;
    final totalMembers = _testMembers.isEmpty ? 1 : _testMembers.length;
    final requiredVotes = WalletDeleteVoteSummary.requiredVotesFor(
      totalMembers,
    );
    final votes = _testVotes.putIfAbsent(walletId, () => []);
    if (!votes.any((v) => v.userId == profile!.id)) {
      votes.add(
        WalletDeleteVote(
          id: 'v-${votes.length}',
          walletId: walletId,
          userId: profile!.id,
          userName: profile!.name,
          createdAt: DateTime.now(),
        ),
      );
    }
    if (votes.length >= requiredVotes) {
      await deleteWallet(walletId);
      return VoteDeleteResult.deleted;
    }
    notifyListeners();
    return VoteDeleteResult.voted;
  }

  @override
  Future<bool> deleteWallet(String walletId) async {
    deleteWalletCalled = true;
    lastDeletedId = walletId;
    _testWallets.removeWhere((w) => w.id == walletId);
    _testVotes.remove(walletId);
    notifyListeners();
    return true;
  }

  @override
  Future<bool> addTransaction({
    required double amount,
    required String transactionType,
    required String category,
    String? notes,
    DateTime? date,
    String? paidByName,
    String? paidById,
    int? paidByColorHex,
  }) async {
    if (addTransactionCompleter != null) {
      return await addTransactionCompleter!.future;
    }
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestGroupWalletProvider groupProvider;
  late SettingsProvider settingsProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    groupProvider = TestGroupWalletProvider([
      GroupWallet(
        id: 'w1',
        name: 'Test Household',
        currency: '₱',
        createdByName: 'Test User',
        createdById: 'u1',
        createdAt: DateTime.now(),
      ),
    ]);
    settingsProvider = SettingsProvider();
    await settingsProvider.preload();
  });

  Widget createWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GroupWalletProvider>.value(value: groupProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: const MaterialApp(home: GroupWalletScreen()),
    );
  }

  testWidgets(
    'Remove wallet dialog requires typing "Remove group wallet" to confirm',
    (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Verify wallet header card is visible
      expect(find.text('Test Household'), findsOneWidget);

      // Open popup menu on wallet header card
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap 'Remove Wallet'
      expect(find.text('Remove Wallet'), findsOneWidget);
      await tester.tap(find.text('Remove Wallet'));
      await tester.pumpAndSettle();

      // Confirmation dialog should be displayed
      expect(find.text('Remove Group Wallet'), findsOneWidget);
      expect(
        find.textContaining('To confirm, type "Remove group wallet"'),
        findsOneWidget,
      );

      // Find Remove button in dialog
      final removeBtnFinder = find.widgetWithText(FilledButton, 'Remove');
      expect(removeBtnFinder, findsOneWidget);

      // Verify button is disabled initially
      FilledButton removeBtn = tester.widget(removeBtnFinder);
      expect(removeBtn.onPressed, isNull);

      // Enter wrong text
      final inputFinder = find.byType(TextField);
      await tester.enterText(inputFinder, 'random text');
      await tester.pumpAndSettle();

      removeBtn = tester.widget(removeBtnFinder);
      expect(removeBtn.onPressed, isNull);

      // Enter partial text
      await tester.enterText(inputFinder, 'Remove group');
      await tester.pumpAndSettle();

      removeBtn = tester.widget(removeBtnFinder);
      expect(removeBtn.onPressed, isNull);

      // Enter exact confirmation phrase: "Remove group wallet"
      await tester.enterText(inputFinder, 'Remove group wallet');
      await tester.pumpAndSettle();

      removeBtn = tester.widget(removeBtnFinder);
      expect(removeBtn.onPressed, isNotNull);

      // Tap Remove
      await tester.tap(removeBtnFinder);
      await tester.pumpAndSettle();

      // Verify deleteWallet was called with wallet id
      expect(groupProvider.deleteWalletCalled, isTrue);
      expect(groupProvider.lastDeletedId, 'w1');

      // Dialog should be dismissed
      expect(find.text('Remove Group Wallet'), findsNothing);
    },
  );

  testWidgets('Remove wallet can be triggered from wallet picker list', (
    tester,
  ) async {
    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    // Open popup menu -> Switch Wallet
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Switch Wallet'));
    await tester.pumpAndSettle();

    // Verify wallet picker bottom sheet is open
    expect(find.text('Select Group Wallet'), findsOneWidget);

    // Tap delete icon on wallet item
    final deleteIconFinder = find.byTooltip('Remove Group Wallet');
    expect(deleteIconFinder, findsOneWidget);
    await tester.tap(deleteIconFinder);
    await tester.pumpAndSettle();

    // Confirmation dialog is shown
    expect(find.text('Remove Group Wallet'), findsOneWidget);

    // Cancel closes the dialog
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Remove Group Wallet'), findsNothing);
    expect(groupProvider.deleteWalletCalled, isFalse);
  });

  testWidgets(
    'Add to group button displays loading indicator while communicating with supabase',
    (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap Add Transaction button in transactions section
      final addTxBtn = find.widgetWithText(FilledButton, 'Add Transaction');
      expect(addTxBtn, findsOneWidget);
      await tester.tap(addTxBtn);
      await tester.pumpAndSettle();

      // Dialog is shown with 'Add to Group' button
      expect(find.text('Add Group Transaction'), findsOneWidget);
      final addToGroupBtnFinder = find.widgetWithText(
        FilledButton,
        'Add to Group',
      );
      expect(addToGroupBtnFinder, findsOneWidget);

      // Enter amount
      await tester.enterText(find.byType(TextField).first, '120.50');
      await tester.pumpAndSettle();

      // Configure completer to simulate pending network request
      final completer = Completer<bool>();
      groupProvider.addTransactionCompleter = completer;

      // Tap 'Add to Group'
      await tester.tap(addToGroupBtnFinder);
      await tester.pump(); // Pump frame without settling

      // Loading indicator should appear
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Cancel button should be disabled while submitting
      final cancelBtn = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Cancel'),
      );
      expect(cancelBtn.onPressed, isNull);

      // Complete the network call
      completer.complete(true);
      await tester.pumpAndSettle();

      // Dialog should close after completion
      expect(find.text('Add Group Transaction'), findsNothing);
    },
  );

  testWidgets('Leave Wallet option removes wallet locally without deleting it', (
    tester,
  ) async {
    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Leave Wallet'), findsOneWidget);
    await tester.tap(find.text('Leave Wallet'));
    await tester.pumpAndSettle();

    expect(find.text('Leave Group Wallet'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Leave'));
    await tester.pumpAndSettle();

    expect(groupProvider.leaveWalletCalled, isTrue);
    expect(groupProvider.lastLeftId, 'w1');
    expect(groupProvider.deleteWalletCalled, isFalse);
  });

  testWidgets(
    'Remove Wallet starts 2/3 majority vote when multiple members exist',
    (tester) async {
      final now = DateTime.now();
      groupProvider = TestGroupWalletProvider(
        [
          GroupWallet(
            id: 'w1',
            name: 'Team Budget',
            currency: '₱',
            createdByName: 'Test User',
            createdById: 'u1',
            createdAt: now,
          ),
        ],
        members: [
          GroupMember(
            id: 'm1',
            walletId: 'w1',
            userId: 'u1',
            name: 'Test User',
            colorHex: 0xFF111111,
            joinedAt: now,
          ),
          GroupMember(
            id: 'm2',
            walletId: 'w1',
            userId: 'u2',
            name: 'Sam',
            colorHex: 0xFF222222,
            joinedAt: now,
          ),
          GroupMember(
            id: 'm3',
            walletId: 'w1',
            userId: 'u3',
            name: 'Jamie',
            colorHex: 0xFF333333,
            joinedAt: now,
          ),
        ],
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove Wallet'));
      await tester.pumpAndSettle();

      expect(find.textContaining('2 of 3 members (2/3)'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Remove group wallet');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
      await tester.pumpAndSettle();

      // Only 1/2 votes cast -> wallet NOT deleted yet, vote banner shown
      expect(groupProvider.initiateVoteCalled, isTrue);
      expect(groupProvider.deleteWalletCalled, isFalse);
      expect(find.text('Removal vote in progress (1/2)'), findsOneWidget);
    },
  );
}
