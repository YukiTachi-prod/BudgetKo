import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasker/models/group_wallet_models.dart';
import 'package:tasker/providers/group_wallet_provider.dart';

Map<String, dynamic> wallet(String id) => {
  'id': id,
  'name': id,
  'created_by_id': 'owner',
  'created_by_name': 'Owner',
  'created_at': '2026-10-01T00:00:00Z',
};

void main() {
  late GroupWalletProvider provider;
  late HttpServer server;
  late List<Map<String, dynamic>> wallets;
  late bool unauthorized;
  late bool missingMembers;
  late bool rejectInsert;
  late List<String?> conflictTargets;
  Completer<void>? delayedResponse;
  Completer<void>? requestStarted;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    provider = GroupWalletProvider();
    await provider.preload();
    wallets = [wallet('w1')];
    unauthorized = false;
    missingMembers = false;
    rejectInsert = false;
    conflictTargets = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      await utf8.decoder.bind(request).join();
      Object body = [];
      if (request.uri.path.endsWith('group_transactions') &&
          request.uri.queryParameters['wallet_id'] == 'eq.w1' &&
          delayedResponse != null) {
        requestStarted?.complete();
        await delayedResponse!.future;
        body = [
          {'id': 'stale', 'wallet_id': 'w1', 'amount': 10},
        ];
      }
      if (unauthorized) {
        request.response.statusCode = 401;
        body = {'code': '42501', 'message': 'Invalid API key'};
      } else if (request.uri.path.endsWith('group_wallets')) {
        if (request.method == 'DELETE') {
          final id = request.uri.queryParameters['id']?.replaceFirst('eq.', '');
          wallets.removeWhere((w) => w['id'] == id);
          body = [];
        } else {
          body = request.uri.queryParameters['select'] == 'id' ? [] : wallets;
        }
      } else if (request.uri.path.endsWith('group_members')) {
        if (missingMembers) {
          request.response.statusCode = 404;
          body = {
            'code': 'PGRST205',
            'message': 'group_members does not exist',
          };
        } else if (request.method == 'POST') {
          conflictTargets.add(request.uri.queryParameters['on_conflict']);
        } else {
          body = [
            {
              'id': 'm1',
              'wallet_id': 'w1',
              'user_id': provider.profile?.id,
              'name': 'Alex',
              'color_hex': 0xFF2196F3,
            },
          ];
        }
      } else if (request.uri.path.endsWith('group_transactions') &&
          request.method == 'POST' &&
          rejectInsert) {
        request.response.statusCode = 403;
        body = {'code': '42501', 'message': 'Insert denied'};
      }
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(body));
      await request.response.close();
    });
  });
  tearDown(() async {
    await provider.disconnectSupabase();
    provider.dispose();
    await server.close(force: true);
  });
  Future<bool> connect() =>
      provider.connectSupabase('http://127.0.0.1:${server.port}', 'test-key');

  test('rejected API key reports disconnected', () async {
    unauthorized = true;
    expect(await connect(), isFalse);
    expect(provider.isConnected, isFalse);
    expect(provider.connectionError, isNotNull);
  });

  test('table readiness includes group_members', () async {
    missingMembers = true;
    await connect();
    expect(provider.isTablesReady, isFalse);
  });

  test('profile updates upsert against wallet/user unique key', () async {
    await provider.saveProfile('Alex', 0xFF2196F3);
    await connect();
    await provider.saveProfile('Alex Updated', 0xFF2196F3);
    expect(conflictTargets, contains('wallet_id,user_id'));
  });

  test('refresh after last wallet deletion clears old data', () async {
    await connect();
    provider.transactions.add(
      GroupTransaction.fromMap({
        'id': 'old',
        'wallet_id': 'w1',
        'amount': 10,
        'transaction_type': 'expense',
      }),
    );
    wallets = [];
    await provider.fetchWallets();
    expect(provider.currentWallet, isNull);
    expect(provider.transactions, isEmpty);
    expect(provider.members, isEmpty);
  });

  test(
    'switching wallets discards delayed response from previous wallet',
    () async {
      await connect();
      delayedResponse = Completer<void>();
      requestStarted = Completer<void>();
      final fetch = provider.fetchTransactions();
      await requestStarted!.future;
      await provider.selectWallet(GroupWallet.fromMap(wallet('w2')));
      delayedResponse!.complete();
      await fetch;
      delayedResponse = null;
      requestStarted = null;
      expect(provider.currentWallet?.id, 'w2');
      expect(provider.transactions, isEmpty);
    },
  );

  test('failed insert returns failure and remains retryable', () async {
    await provider.saveProfile('Alex', 0xFF2196F3);
    await connect();
    rejectInsert = true;
    expect(
      await provider.addTransaction(
        amount: 10,
        transactionType: 'expense',
        category: 'Food',
      ),
      isFalse,
    );
    expect(provider.connectionError, contains('Insert denied'));
    expect(provider.isLoading, isFalse);
    rejectInsert = false;
    expect(
      await provider.addTransaction(
        amount: 10,
        transactionType: 'expense',
        category: 'Food',
      ),
      isTrue,
    );
    expect(provider.connectionError, isNull);
  });

  test('invalid amounts and transaction types are rejected', () async {
    await provider.saveProfile('Alex', 0xFF2196F3);
    await connect();
    for (final amount in [0.0, -1.0, double.nan, double.infinity]) {
      expect(
        await provider.addTransaction(
          amount: amount,
          transactionType: 'expense',
          category: 'Food',
        ),
        isFalse,
      );
    }
    expect(
      await provider.addTransaction(
        amount: 1,
        transactionType: 'invalid',
        category: 'Food',
      ),
      isFalse,
    );
  });

  test('legacy profile without ID keeps identity after restart', () async {
    SharedPreferences.setMockInitialValues({'group_profile_name': 'Legacy'});
    final first = GroupWalletProvider();
    await first.preload();
    final second = GroupWalletProvider();
    await second.preload();
    expect(second.profile?.id, first.profile?.id);
    first.dispose();
    second.dispose();
  });

  test('same names and renamed members keep separate totals by ID', () {
    provider.transactions.addAll([
      GroupTransaction.fromMap({
        'paid_by_id': 'u1',
        'paid_by_name': 'Alex',
        'amount': 10,
        'transaction_type': 'expense',
      }),
      GroupTransaction.fromMap({
        'paid_by_id': 'u2',
        'paid_by_name': 'Alex',
        'amount': 20,
        'transaction_type': 'expense',
      }),
      GroupTransaction.fromMap({
        'paid_by_id': 'u1',
        'paid_by_name': 'Renamed',
        'amount': 5,
        'transaction_type': 'expense',
      }),
    ]);
    expect(provider.memberExpenseMap, {'u1': 15, 'u2': 20});
    expect(provider.collectivePoolBalance, -35);
  });

  test('actual provider totals include income and category expenses', () {
    provider.transactions.addAll([
      GroupTransaction.fromMap({
        'paid_by_id': 'u1',
        'amount': 100,
        'transaction_type': 'contribution',
      }),
      GroupTransaction.fromMap({
        'paid_by_id': 'u1',
        'amount': 50,
        'transaction_type': 'income',
      }),
      GroupTransaction.fromMap({
        'paid_by_id': 'u2',
        'amount': 30,
        'transaction_type': 'expense',
        'category': 'Food',
      }),
    ]);
    expect(provider.collectiveTotalIncome, 150);
    expect(provider.collectiveTotalExpenses, 30);
    expect(provider.collectivePoolBalance, 120);
    expect(provider.memberContributionMap, {'u1': 150});
    expect(provider.categoryExpensesMap, {'Food': 30});
  });

  test('deleteWallet removes wallet and clears active state', () async {
    await connect();
    expect(provider.currentWallet?.id, 'w1');
    final ok = await provider.deleteWallet('w1');
    expect(ok, isTrue);
    expect(provider.currentWallet, isNull);
    expect(provider.wallets, isEmpty);
    expect(wallets, isEmpty);
  });
}
