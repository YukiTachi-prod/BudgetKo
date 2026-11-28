import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group_wallet_models.dart';

class GroupWalletProvider extends ChangeNotifier {
  static const String _keyProfileId = 'group_profile_id';
  static const String _keyProfileName = 'group_profile_name';
  static const String _keyProfileColor = 'group_profile_color';
  static const String _keySupabaseUrl = 'supabase_url';
  static const String _keySupabaseKey = 'supabase_key';
  static const String _keyActiveWalletId = 'group_active_wallet_id';

  GroupProfile? _profile;
  String? _supabaseUrl;
  String? _supabaseKey;
  SupabaseClient? _client;

  bool _missingTables = false;
  bool _isConnected = false;
  bool _isTablesReady = false;
  bool _isLoading = false;
  String? _connectionError;

  List<GroupWallet> _wallets = [];
  GroupWallet? _currentWallet;
  List<GroupMember> _members = [];
  List<GroupTransaction> _transactions = [];

  Future<void>? _initFuture;

  GroupWalletProvider() {
    preload();
  }

  // ── Getters ──────────────────────────────────────────────────────────
  GroupProfile? get profile => _profile;
  bool get hasProfile => _profile != null && _profile!.name.trim().isNotEmpty;

  String? get supabaseUrl => _supabaseUrl;
  String? get supabaseKey => _supabaseKey;
  bool get isConfigured =>
      _supabaseUrl != null &&
      _supabaseUrl!.isNotEmpty &&
      _supabaseKey != null &&
      _supabaseKey!.isNotEmpty;
  bool get isConnected => _isConnected;
  bool get isTablesReady => _isTablesReady;
  bool get isLoading => _isLoading;
  String? get connectionError => _connectionError;

  List<GroupWallet> get wallets => _wallets;
  GroupWallet? get currentWallet => _currentWallet;
  List<GroupMember> get members => _members;
  List<GroupTransaction> get transactions => _transactions;

  // ── Preload & Setup ──────────────────────────────────────────────────
  Future<void> preload() {
    return _initFuture ??= _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Load Local Profile
    final profileId = prefs.getString(_keyProfileId);
    final profileName = prefs.getString(_keyProfileName);
    final profileColor = prefs.getInt(_keyProfileColor);

    if (profileName != null && profileName.isNotEmpty) {
      _profile = GroupProfile(
        id: profileId ?? GroupProfile.generateId(),
        name: profileName,
        colorHex: profileColor ?? 0xFF7C3AED,
      );
    }

    if (_profile != null && profileId == null) {
      await prefs.setString(_keyProfileId, _profile!.id);
    }

    // 2. Load Supabase Config
    _supabaseUrl = prefs.getString(_keySupabaseUrl);
    _supabaseKey = prefs.getString(_keySupabaseKey);

    if (isConfigured) {
      await _initializeClient(silent: true);
    }

    notifyListeners();
  }

  // ── Profile Management ───────────────────────────────────────────────
  Future<void> saveProfile(String name, int colorHex) async {
    final prefs = await SharedPreferences.getInstance();
    final id = _profile?.id ?? GroupProfile.generateId();

    _profile = GroupProfile(id: id, name: name.trim(), colorHex: colorHex);

    await prefs.setString(_keyProfileId, id);
    await prefs.setString(_keyProfileName, name.trim());
    await prefs.setInt(_keyProfileColor, colorHex);

    // If currently connected to a wallet, update member record on remote
    if (_isConnected && _currentWallet != null && _client != null) {
      try {
        await _client!.from('group_members').upsert({
          'wallet_id': _currentWallet!.id,
          'user_id': _profile!.id,
          'name': _profile!.name,
          'color_hex': _profile!.colorHex,
        }, onConflict: 'wallet_id,user_id');
        await fetchMembers();
      } catch (_) {}
    }

    notifyListeners();
  }

  // ── Supabase Connection & Table Check ────────────────────────────────
  Future<bool> connectSupabase(String url, String key) async {
    _isLoading = true;
    _connectionError = null;
    notifyListeners();

    final cleanUrl = url.trim();
    final cleanKey = key.trim();

    if (cleanUrl.isEmpty || cleanKey.isEmpty) {
      _connectionError = 'Supabase URL and API Key are required.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySupabaseUrl, cleanUrl);
      await prefs.setString(_keySupabaseKey, cleanKey);
      _supabaseUrl = cleanUrl;
      _supabaseKey = cleanKey;

      final success = await _initializeClient();
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _connectionError = 'Failed to connect: $e';
      _isConnected = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> disconnectSupabase() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySupabaseUrl);
    await prefs.remove(_keySupabaseKey);
    await prefs.remove(_keyActiveWalletId);

    _supabaseUrl = null;
    _supabaseKey = null;
    _client = null;
    _isConnected = false;
    _isTablesReady = false;
    _connectionError = null;
    _wallets = [];
    _currentWallet = null;
    _members = [];
    _transactions = [];

    notifyListeners();
  }

  Future<bool> _initializeClient({bool silent = false}) async {
    if (_supabaseUrl == null || _supabaseKey == null) return false;

    try {
      _client = SupabaseClient(_supabaseUrl!, _supabaseKey!);

      // Check if tables exist
      final tablesExist = await checkDatabaseTables();
      if (!tablesExist && !_missingTables) {
        _isConnected = false;
        return false;
      }
      if (!tablesExist) {
        // Attempt automated table initialization via exec_sql RPC if available
        await attemptAutoInitTables();
      }

      _isConnected = true;
      if (_isTablesReady) _connectionError = null;

      // Fetch group wallets
      if (_isTablesReady) {
        await fetchWallets();
      }

      return true;
    } catch (e) {
      _isConnected = false;
      if (!silent) {
        _connectionError = 'Connection failed: $e';
      }
      return false;
    }
  }

  /// Verifies whether the required tables (`group_wallets`, `group_transactions`) exist.
  Future<bool> checkDatabaseTables() async {
    if (_client == null) return false;

    _isTablesReady = false;
    _missingTables = false;
    try {
      // Test querying group_wallets table
      await _client!.from('group_wallets').select('id').limit(1);
      // Test querying group_transactions table
      await _client!.from('group_transactions').select('id').limit(1);
      await _client!.from('group_members').select('id').limit(1);

      _isTablesReady = true;
      _connectionError = null;
      notifyListeners();
      return true;
    } catch (e) {
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('does not exist') ||
          errorMsg.contains('42p01') ||
          errorMsg.contains('pgrst205') ||
          errorMsg.contains('404')) {
        _missingTables = true;
        _isTablesReady = false;
        _connectionError =
            'Group tables do not exist in your Supabase project yet.';
      } else {
        _connectionError = 'Database check failed: $e';
      }
      notifyListeners();
      return false;
    }
  }

  /// Attempts to run table creation scripts automatically via RPC `exec_sql`.
  Future<bool> attemptAutoInitTables() async {
    if (_client == null) return false;

    const schemaSql = '''
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS group_wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    currency TEXT DEFAULT '₱',
    created_by_name TEXT NOT NULL,
    created_by_id TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS group_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_id UUID NOT NULL REFERENCES group_wallets(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    color_hex BIGINT DEFAULT 4280391411,
    joined_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(wallet_id, user_id)
);

CREATE TABLE IF NOT EXISTS group_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_id UUID NOT NULL REFERENCES group_wallets(id) ON DELETE CASCADE,
    amount NUMERIC NOT NULL,
    transaction_type TEXT NOT NULL,
    category TEXT DEFAULT 'General',
    notes TEXT,
    paid_by_name TEXT NOT NULL,
    paid_by_id TEXT NOT NULL,
    paid_by_color_hex BIGINT DEFAULT 4280391411,
    date TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE group_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public access on group_wallets" ON group_wallets;
CREATE POLICY "Public access on group_wallets" ON group_wallets FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public access on group_members" ON group_members;
CREATE POLICY "Public access on group_members" ON group_members FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public access on group_transactions" ON group_transactions;
CREATE POLICY "Public access on group_transactions" ON group_transactions FOR ALL USING (true) WITH CHECK (true);
''';

    try {
      await _client!.rpc('exec_sql', params: {'query': schemaSql});
      // Re-check
      final ready = await checkDatabaseTables();
      if (ready) {
        await fetchWallets();
      }
      return ready;
    } catch (_) {
      // RPC exec_sql may not be set up on user's Supabase yet; UI will provide copyable SQL script.
      return false;
    }
  }

  // ── Wallets Management ────────────────────────────────────────────────
  Future<void> fetchWallets() async {
    if (_client == null || !_isTablesReady) return;

    try {
      final res = await _client!
          .from('group_wallets')
          .select()
          .order('created_at', ascending: false);

      final list = (res as List)
          .map((m) => GroupWallet.fromMap(m as Map<String, dynamic>))
          .toList();

      _wallets = list;

      final prefs = await SharedPreferences.getInstance();
      final savedWalletId = prefs.getString(_keyActiveWalletId);

      if (savedWalletId != null && _wallets.any((w) => w.id == savedWalletId)) {
        _currentWallet = _wallets.firstWhere((w) => w.id == savedWalletId);
      } else if (_wallets.isNotEmpty) {
        _currentWallet = _wallets.first;
      } else {
        _currentWallet = null;
        _members = [];
        _transactions = [];
      }

      if (_currentWallet != null) {
        await fetchWalletData();
      }

      notifyListeners();
    } catch (e) {
      _connectionError = 'Error fetching wallets: $e';
      notifyListeners();
    }
  }

  Future<void> selectWallet(GroupWallet wallet) async {
    _members = [];
    _transactions = [];
    _currentWallet = wallet;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveWalletId, wallet.id);

    await fetchWalletData();
    notifyListeners();
  }

  Future<GroupWallet?> createWallet(
    String name, {
    String? description,
    String? currency,
  }) async {
    if (_client == null || _profile == null) return null;

    _isLoading = true;
    notifyListeners();

    try {
      final insertData = {
        'name': name.trim(),
        if (description != null && description.isNotEmpty)
          'description': description.trim(),
        'currency': currency ?? '₱',
        'created_by_name': _profile!.name,
        'created_by_id': _profile!.id,
      };

      final res = await _client!
          .from('group_wallets')
          .insert(insertData)
          .select()
          .single();

      final newWallet = GroupWallet.fromMap(res);

      // Register creator as member
      await _client!.from('group_members').insert({
        'wallet_id': newWallet.id,
        'user_id': _profile!.id,
        'name': _profile!.name,
        'color_hex': _profile!.colorHex,
      });

      await fetchWallets();
      await selectWallet(newWallet);

      _isLoading = false;
      notifyListeners();
      return newWallet;
    } catch (e) {
      _connectionError = 'Failed to create wallet: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> joinWalletById(String walletId) async {
    if (_client == null || _profile == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final cleanId = walletId.trim();
      final res = await _client!
          .from('group_wallets')
          .select()
          .eq('id', cleanId)
          .maybeSingle();

      if (res == null) {
        _connectionError = 'No group wallet found with ID: $cleanId';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final wallet = GroupWallet.fromMap(res);

      // Register profile in group_members if not present
      await _client!.from('group_members').upsert({
        'wallet_id': wallet.id,
        'user_id': _profile!.id,
        'name': _profile!.name,
        'color_hex': _profile!.colorHex,
      }, onConflict: 'wallet_id,user_id');

      await fetchWallets();
      await selectWallet(wallet);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _connectionError = 'Failed to join wallet: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteWallet(String walletId) async {
    if (_client == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      if (_currentWallet?.id == walletId) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_keyActiveWalletId);
        _currentWallet = null;
        _members = [];
        _transactions = [];
      }
      await _client!.from('group_wallets').delete().eq('id', walletId);
      await fetchWallets();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _connectionError = 'Failed to delete wallet: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Wallet Data: Members & Transactions ──────────────────────────────
  Future<void> fetchWalletData() async {
    if (_client == null || _currentWallet == null) return;

    final client = _client;
    final walletId = _currentWallet!.id;
    await Future.wait([fetchMembers(), fetchTransactions()]);
    if (_client != client || _currentWallet?.id != walletId) return;

    // Ensure current profile is listed as member
    if (_profile != null && !_members.any((m) => m.userId == _profile!.id)) {
      try {
        await _client!.from('group_members').upsert({
          'wallet_id': _currentWallet!.id,
          'user_id': _profile!.id,
          'name': _profile!.name,
          'color_hex': _profile!.colorHex,
        }, onConflict: 'wallet_id,user_id');
        await fetchMembers();
      } catch (_) {}
    }
  }

  Future<void> fetchMembers() async {
    if (_client == null || _currentWallet == null) return;

    final client = _client!;
    final walletId = _currentWallet!.id;
    try {
      final res = await client
          .from('group_members')
          .select()
          .eq('wallet_id', walletId)
          .order('joined_at', ascending: true);

      if (_client != client || _currentWallet?.id != walletId) return;
      _members = (res as List)
          .map((m) => GroupMember.fromMap(m as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchTransactions() async {
    if (_client == null || _currentWallet == null) return;

    final client = _client!;
    final walletId = _currentWallet!.id;
    try {
      final res = await client
          .from('group_transactions')
          .select()
          .eq('wallet_id', walletId)
          .order('date', ascending: false);

      if (_client != client || _currentWallet?.id != walletId) return;
      _transactions = (res as List)
          .map((m) => GroupTransaction.fromMap(m as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

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
    if (_isLoading ||
        _client == null ||
        _currentWallet == null ||
        _profile == null) {
      return false;
    }
    if (!amount.isFinite ||
        amount <= 0 ||
        !{'expense', 'income', 'contribution'}.contains(transactionType)) {
      _connectionError =
          'Enter a positive amount and a valid transaction type.';
      notifyListeners();
      return false;
    }
    _connectionError = null;

    _isLoading = true;
    notifyListeners();

    try {
      final txData = {
        'wallet_id': _currentWallet!.id,
        'amount': amount,
        'transaction_type': transactionType,
        'category': category.trim().isNotEmpty ? category.trim() : 'General',
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        'paid_by_name': paidByName ?? _profile!.name,
        'paid_by_id': paidById ?? _profile!.id,
        'paid_by_color_hex': paidByColorHex ?? _profile!.colorHex,
        'date': (date ?? DateTime.now()).toIso8601String(),
      };

      await _client!.from('group_transactions').insert(txData);
      await fetchTransactions();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _connectionError = 'Failed to record transaction: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    if (_client == null) return;

    try {
      await _client!
          .from('group_transactions')
          .delete()
          .eq('id', transactionId);
      _transactions.removeWhere((t) => t.id == transactionId);
      notifyListeners();
    } catch (e) {
      _connectionError = 'Failed to delete transaction: $e';
      notifyListeners();
    }
  }

  // ── Collective Budget Computations ────────────────────────────────────
  /// Total Pool Balance: Contributions + Income - Expenses
  double get collectivePoolBalance {
    double total = 0.0;
    for (final tx in _transactions) {
      if (tx.isContribution) {
        total += tx.amount;
      } else {
        total -= tx.amount;
      }
    }
    return total;
  }

  /// Total amount contributed or added as income
  double get collectiveTotalIncome {
    return _transactions
        .where((t) => t.isContribution)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Total group expenses
  double get collectiveTotalExpenses {
    return _transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Member spending map (User ID -> Total Expense Paid)
  Map<String, double> get memberExpenseMap {
    final Map<String, double> map = {};
    for (final tx in _transactions.where((t) => t.isExpense)) {
      map[tx.paidById] = (map[tx.paidById] ?? 0.0) + tx.amount;
    }
    return map;
  }

  /// Member contribution map (User ID -> Total Contributed)
  Map<String, double> get memberContributionMap {
    final Map<String, double> map = {};
    for (final tx in _transactions.where((t) => t.isContribution)) {
      map[tx.paidById] = (map[tx.paidById] ?? 0.0) + tx.amount;
    }
    return map;
  }

  /// Category breakdown for expenses
  Map<String, double> get categoryExpensesMap {
    final Map<String, double> map = {};
    for (final tx in _transactions.where((t) => t.isExpense)) {
      map[tx.category] = (map[tx.category] ?? 0.0) + tx.amount;
    }
    return map;
  }

  /// Clears local Group Wallet profile, credentials, and cached state.
  Future<void> clearLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProfileId);
    await prefs.remove(_keyProfileName);
    await prefs.remove(_keyProfileColor);
    await prefs.remove(_keySupabaseUrl);
    await prefs.remove(_keySupabaseKey);
    await prefs.remove(_keyActiveWalletId);

    _profile = null;
    _supabaseUrl = null;
    _supabaseKey = null;
    _client = null;
    _missingTables = false;
    _isConnected = false;
    _isTablesReady = false;
    _isLoading = false;
    _connectionError = null;
    _wallets = [];
    _currentWallet = null;
    _members = [];
    _transactions = [];
    notifyListeners();
  }
}
