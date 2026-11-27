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
  String? lastDeletedId;
  final List<GroupWallet> _testWallets;

  TestGroupWalletProvider(this._testWallets);

  @override
  bool get hasProfile => true;

  @override
  GroupProfile? get profile =>
      GroupProfile(id: 'u1', name: 'Test User', colorHex: 0xFF2196F3);

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

  Completer<bool>? addTransactionCompleter;

  @override
  Future<bool> deleteWallet(String walletId) async {
    deleteWalletCalled = true;
    lastDeletedId = walletId;
    _testWallets.removeWhere((w) => w.id == walletId);
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
      final addToGroupBtnFinder = find.widgetWithText(FilledButton, 'Add to Group');
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
      final cancelBtn = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Cancel'));
      expect(cancelBtn.onPressed, isNull);

      // Complete the network call
      completer.complete(true);
      await tester.pumpAndSettle();

      // Dialog should close after completion
      expect(find.text('Add Group Transaction'), findsNothing);
    },
  );
}
