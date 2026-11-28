import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group_wallet_models.dart';

class GroupWalletProvider extends ChangeNotifier {
  static const String _keyProfileId = 'group_profile_id';
  static const String _keyProfileName = 'group_profile_name';
  static const String _keyProfileColor = 'group_profile_color';
  static const String _keyProfilePassword = 'group_profile_password';
  static const String _keySupabaseUrl = 'supabase_url';
  static const String _keySupabaseKey = 'supabase_key';
  static const String _keyActiveWalletId = 'group_active_wallet_id';
  static const String _keyLeftWalletIds = 'group_left_wallet_ids';

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
  Set<String> _leftWalletIds = {};
  Map<String, List<WalletDeleteVote>> _deleteVotesByWallet = {};
  Map<String, int> _memberCountByWallet = {};

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

  WalletDeleteVoteSummary? deleteVoteSummaryFor(String walletId) {
    final votes = _deleteVotesByWallet[walletId];
    if (votes == null || votes.isEmpty) return null;
    final wallet = _wallets.cast<GroupWallet?>().firstWhere(
      (w) => w?.id == walletId,
      orElse: () => null,
    );
    final memberCount = _currentWallet?.id == walletId && _members.isNotEmpty
        ? _members.length
        : (_memberCountByWallet[walletId] ?? 1);
    return WalletDeleteVoteSummary(
      walletId: walletId,
      walletName: wallet?.name ?? 'Group Wallet',
      totalMembers: memberCount,
      votes: List.unmodifiable(votes),
    );
  }

  List<WalletDeleteVoteSummary> get pendingDeleteVotes {
    final summaries = <WalletDeleteVoteSummary>[];
    for (final wallet in _wallets) {
      final summary = deleteVoteSummaryFor(wallet.id);
      if (summary != null) {
        summaries.add(summary);
      }
    }
    return summaries;
  }

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
    final profilePassword = prefs.getString(_keyProfilePassword) ?? '';

    if (profileName != null && profileName.isNotEmpty) {
      _profile = GroupProfile(
        id: profileId ?? GroupProfile.generateId(),
        name: profileName,
        colorHex: profileColor ?? 0xFF7C3AED,
        password: profilePassword,
      );
    }

    if (_profile != null && profileId == null) {
      await prefs.setString(_keyProfileId, _profile!.id);
    }

    _leftWalletIds = (prefs.getStringList(_keyLeftWalletIds) ?? const [])
        .toSet();

    // 2. Load Supabase Config
    _supabaseUrl = prefs.getString(_keySupabaseUrl);
    _supabaseKey = prefs.getString(_keySupabaseKey);

    if (isConfigured) {
      await _initializeClient(silent: true);
    }

    notifyListeners();
  }

  // ── Profile Management ───────────────────────────────────────────────
  Future<void> _persistProfile(GroupProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    _profile = profile;
    await prefs.setString(_keyProfileId, profile.id);
    await prefs.setString(_keyProfileName, profile.name);
    await prefs.setInt(_keyProfileColor, profile.colorHex);
    await prefs.setString(_keyProfilePassword, profile.password);
  }

  Future<void> _upsertMemberWithPasswordFallback(
    Map<String, dynamic> row,
  ) async {
    try {
      await _client!
          .from('group_members')
          .upsert(row, onConflict: 'wallet_id,user_id');
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('password')) {
        try {
          await _client!.rpc(
            'exec_sql',
            params: {
              'query':
                  "ALTER TABLE group_members ADD COLUMN IF NOT EXISTS password TEXT DEFAULT '';",
            },
          );
          await _client!
              .from('group_members')
              .upsert(row, onConflict: 'wallet_id,user_id');
          return;
        } catch (_) {
          final fallback = Map<String, dynamic>.from(row)..remove('password');
          await _client!
              .from('group_members')
              .upsert(fallback, onConflict: 'wallet_id,user_id');
          return;
        }
      }
      rethrow;
    }
  }

  Future<GroupProfile?> _syncProfileWithWallet(
    String walletId, {
    required GroupProfile candidateProfile,
  }) async {
    final res = await _client!
        .from('group_members')
        .select()
        .eq('wallet_id', walletId);

    final remoteMembers = (res as List)
        .map((m) => GroupMember.fromMap(m as Map<String, dynamic>))
        .toList();

    final claim = MemberClaimResult.resolve(
      existingMembers: remoteMembers,
      profile: candidateProfile,
    );

    if (claim.status == MemberClaimStatus.wrongPassword) {
      _connectionError =
          'Incorrect password for "${candidateProfile.name}" in this wallet.';
      notifyListeners();
      return null;
    }

    final resolvedProfile =
        claim.status == MemberClaimStatus.reclaimedByName &&
            claim.matchedMember != null
        ? candidateProfile.copyWith(id: claim.matchedMember!.userId)
        : candidateProfile;

    await _upsertMemberWithPasswordFallback({
      'wallet_id': walletId,
      'user_id': resolvedProfile.id,
      'name': resolvedProfile.name,
      'color_hex': resolvedProfile.colorHex,
      'password': resolvedProfile.password,
    });

    _connectionError = null;
    return resolvedProfile;
  }

  Future<bool> saveProfile(
    String name,
    int colorHex, {
    String? password,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return false;

    final id = _profile?.id ?? GroupProfile.generateId();
    final effectivePassword = password ?? _profile?.password ?? '';
    var candidate = GroupProfile(
      id: id,
      name: cleanName,
      colorHex: colorHex,
      password: effectivePassword,
    );

    // If currently connected to a wallet, verify password / reclaim existing name
    if (_isConnected && _currentWallet != null && _client != null) {
      try {
        final synced = await _syncProfileWithWallet(
          _currentWallet!.id,
          candidateProfile: candidate,
        );
        if (synced == null) {
          return false;
        }
        candidate = synced;
        await _persistProfile(candidate);
        await fetchMembers();
        notifyListeners();
        return true;
      } catch (e) {
        _connectionError = 'Failed to update profile: $e';
        notifyListeners();
        return false;
      }
    }

    await _persistProfile(candidate);
    notifyListeners();
    return true;
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
    password TEXT DEFAULT '',
    joined_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(wallet_id, user_id)
);

ALTER TABLE group_members ADD COLUMN IF NOT EXISTS password TEXT DEFAULT '';

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

CREATE TABLE IF NOT EXISTS group_wallet_delete_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_id UUID NOT NULL REFERENCES group_wallets(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL,
    user_name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(wallet_id, user_id)
);

ALTER TABLE group_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_wallet_delete_votes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public access on group_wallets" ON group_wallets;
CREATE POLICY "Public access on group_wallets" ON group_wallets FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public access on group_members" ON group_members;
CREATE POLICY "Public access on group_members" ON group_members FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public access on group_transactions" ON group_transactions;
CREATE POLICY "Public access on group_transactions" ON group_transactions FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public access on group_wallet_delete_votes" ON group_wallet_delete_votes;
CREATE POLICY "Public access on group_wallet_delete_votes" ON group_wallet_delete_votes FOR ALL USING (true) WITH CHECK (true);
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
          .where((w) => !_leftWalletIds.contains(w.id))
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
      await fetchDeleteVotes();

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
      await _upsertMemberWithPasswordFallback({
        'wallet_id': newWallet.id,
        'user_id': _profile!.id,
        'name': _profile!.name,
        'color_hex': _profile!.colorHex,
        'password': _profile!.password,
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

  Future<bool> joinWalletById(
    String walletId, {
    String? name,
    String? password,
  }) async {
    if (_client == null || _profile == null) return false;

    _isLoading = true;
    _connectionError = null;
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

      final candidate = _profile!.copyWith(
        name: name != null && name.trim().isNotEmpty
            ? name.trim()
            : _profile!.name,
        password: password ?? _profile!.password,
      );

      final synced = await _syncProfileWithWallet(
        wallet.id,
        candidateProfile: candidate,
      );
      if (synced == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _persistProfile(synced);
      if (_leftWalletIds.remove(wallet.id)) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_keyLeftWalletIds, _leftWalletIds.toList());
      }
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

  /// Leaves a group wallet locally without deleting it or removing the member's
  /// remote record, so they can rejoin later using their name and password.
  Future<void> leaveWallet(String walletId) async {
    _leftWalletIds.add(walletId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyLeftWalletIds, _leftWalletIds.toList());

    _wallets = _wallets.where((w) => w.id != walletId).toList();
    _deleteVotesByWallet.remove(walletId);

    if (_currentWallet?.id == walletId) {
      await prefs.remove(_keyActiveWalletId);
      if (_wallets.isNotEmpty) {
        await selectWallet(_wallets.first);
      } else {
        _currentWallet = null;
        _members = [];
        _transactions = [];
      }
    }
    notifyListeners();
  }

  Future<void> _ensureDeleteVotesTable() async {
    if (_client == null) return;
    try {
      await _client!.rpc(
        'exec_sql',
        params: {
          'query': '''
CREATE TABLE IF NOT EXISTS group_wallet_delete_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_id UUID NOT NULL REFERENCES group_wallets(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL,
    user_name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(wallet_id, user_id)
);
ALTER TABLE group_wallet_delete_votes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public access on group_wallet_delete_votes" ON group_wallet_delete_votes;
CREATE POLICY "Public access on group_wallet_delete_votes" ON group_wallet_delete_votes FOR ALL USING (true) WITH CHECK (true);
''',
        },
      );
    } catch (_) {}
  }

  Future<void> fetchDeleteVotes() async {
    if (_client == null || !_isTablesReady || _wallets.isEmpty) {
      _deleteVotesByWallet = {};
      return;
    }

    try {
      final walletIds = _wallets.map((w) => w.id).toList();
      final res = await _client!
          .from('group_wallet_delete_votes')
          .select()
          .inFilter('wallet_id', walletIds)
          .order('created_at', ascending: true);

      final grouped = <String, List<WalletDeleteVote>>{};
      for (final row in (res as List)) {
        final vote = WalletDeleteVote.fromMap(row as Map<String, dynamic>);
        grouped.putIfAbsent(vote.walletId, () => []).add(vote);
      }
      _deleteVotesByWallet = grouped;

      if (grouped.isNotEmpty) {
        final memberRes = await _client!
            .from('group_members')
            .select('wallet_id')
            .inFilter('wallet_id', grouped.keys.toList());
        final counts = <String, int>{};
        for (final row in (memberRes as List)) {
          final wid = (row as Map<String, dynamic>)['wallet_id']?.toString();
          if (wid != null) {
            counts[wid] = (counts[wid] ?? 0) + 1;
          }
        }
        _memberCountByWallet = counts;
      }

      notifyListeners();
    } catch (_) {
      // Table may not exist yet on legacy Supabase projects
    }
  }

  /// Initiates or confirms a 2/3 majority vote to remove [walletId].
  /// Once at least 2/3 of the wallet's members have voted, deletes the wallet.
  Future<VoteDeleteResult> initiateOrConfirmDeleteVote(String walletId) async {
    if (_client == null || _profile == null) return VoteDeleteResult.failed;

    _isLoading = true;
    _connectionError = null;
    notifyListeners();

    try {
      final memberRes = await _client!
          .from('group_members')
          .select('user_id')
          .eq('wallet_id', walletId);
      final totalMembers = (memberRes as List).length;
      final requiredVotes = WalletDeleteVoteSummary.requiredVotesFor(
        totalMembers,
      );

      // Solo wallet (1 member): 2/3 threshold is 1 vote -> delete immediately
      if (requiredVotes <= 1) {
        final deleted = await deleteWallet(walletId);
        return deleted ? VoteDeleteResult.deleted : VoteDeleteResult.failed;
      }

      final voteRow = {
        'wallet_id': walletId,
        'user_id': _profile!.id,
        'user_name': _profile!.name,
      };

      try {
        await _client!
            .from('group_wallet_delete_votes')
            .upsert(voteRow, onConflict: 'wallet_id,user_id');
      } catch (e) {
        if (e.toString().toLowerCase().contains('group_wallet_delete_votes')) {
          await _ensureDeleteVotesTable();
          await _client!
              .from('group_wallet_delete_votes')
              .upsert(voteRow, onConflict: 'wallet_id,user_id');
        } else {
          rethrow;
        }
      }

      await fetchDeleteVotes();
      final summary = deleteVoteSummaryFor(walletId);
      if (summary != null && summary.hasReachedThreshold) {
        final deleted = await deleteWallet(walletId);
        return deleted ? VoteDeleteResult.deleted : VoteDeleteResult.failed;
      }

      _isLoading = false;
      notifyListeners();
      return VoteDeleteResult.voted;
    } catch (e) {
      _connectionError = 'Failed to record removal vote: $e';
      _isLoading = false;
      notifyListeners();
      return VoteDeleteResult.failed;
    }
  }

  Future<bool> withdrawDeleteVote(String walletId) async {
    if (_client == null || _profile == null) return false;
    try {
      await _client!
          .from('group_wallet_delete_votes')
          .delete()
          .eq('wallet_id', walletId)
          .eq('user_id', _profile!.id);
      await fetchDeleteVotes();
      return true;
    } catch (e) {
      _connectionError = 'Failed to withdraw vote: $e';
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

    // Ensure current profile is matched or listed as member without duplicating
    if (_profile != null) {
      final claim = MemberClaimResult.resolve(
        existingMembers: _members,
        profile: _profile!,
      );
      if (claim.status == MemberClaimStatus.reclaimedByName &&
          claim.matchedMember != null) {
        await _persistProfile(
          _profile!.copyWith(id: claim.matchedMember!.userId),
        );
      } else if (claim.status == MemberClaimStatus.wrongPassword) {
        _connectionError =
            'A member named "${_profile!.name}" already exists in this wallet. Edit your profile and enter the password to reclaim it.';
        notifyListeners();
      } else if (claim.status == MemberClaimStatus.newMember) {
        try {
          await _upsertMemberWithPasswordFallback({
            'wallet_id': _currentWallet!.id,
            'user_id': _profile!.id,
            'name': _profile!.name,
            'color_hex': _profile!.colorHex,
            'password': _profile!.password,
          });
          await fetchMembers();
        } catch (_) {}
      }
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
    await prefs.remove(_keyProfilePassword);
    await prefs.remove(_keySupabaseUrl);
    await prefs.remove(_keySupabaseKey);
    await prefs.remove(_keyActiveWalletId);
    await prefs.remove(_keyLeftWalletIds);

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
    _leftWalletIds = {};
    _deleteVotesByWallet = {};
    _memberCountByWallet = {};
    notifyListeners();
  }
}
