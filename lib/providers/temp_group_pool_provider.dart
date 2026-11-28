import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/temp_group_pool_models.dart';

/// Manages isolated Temporary Group Pools stored locally in SharedPreferences.
/// Completely independent of personal wallets (`LedgerProvider` / `BudgetDatabase`).
class TempGroupPoolProvider extends ChangeNotifier {
  static const String _keyPools = 'temp_group_pools_v1';
  static const String _keyActivePoolId = 'temp_group_pool_active_id_v1';

  List<TempGroupPool> _pools = [];
  String? _activePoolId;
  Future<void>? _initFuture;

  TempGroupPoolProvider() {
    preload();
  }

  List<TempGroupPool> get pools => List.unmodifiable(_pools);

  TempGroupPool? get activePool {
    if (_pools.isEmpty) return null;
    if (_activePoolId != null) {
      for (final pool in _pools) {
        if (pool.id == _activePoolId) return pool;
      }
    }
    return _pools.first;
  }

  bool get hasActivePool => activePool != null;

  Future<void> preload() {
    return _initFuture ??= _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_keyPools);
    final savedActiveId = prefs.getString(_keyActivePoolId);

    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson);
        if (decoded is List) {
          _pools = decoded
              .whereType<Map>()
              .map((m) => TempGroupPool.fromJson(Map<String, dynamic>.from(m)))
              .toList();
        }
      } catch (_) {
        _pools = [];
      }
    }

    if (savedActiveId != null && _pools.any((p) => p.id == savedActiveId)) {
      _activePoolId = savedActiveId;
    } else if (_pools.isNotEmpty) {
      _activePoolId = _pools.first.id;
    } else {
      _activePoolId = null;
    }

    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_pools.map((p) => p.toJson()).toList());
    await prefs.setString(_keyPools, encoded);
    if (_activePoolId != null) {
      await prefs.setString(_keyActivePoolId, _activePoolId!);
    } else {
      await prefs.remove(_keyActivePoolId);
    }
  }

  Future<TempGroupPool> createPool({
    required String name,
    String currency = '₱',
    bool isEqualShare = false,
    double equalShareAmount = 0.0,
  }) async {
    final trimmed = name.trim();
    final pool = TempGroupPool(
      id: TempGroupPool.generateId(),
      name: trimmed.isNotEmpty ? trimmed : 'Temporary Pool',
      currency: currency,
      isEqualShare: isEqualShare,
      equalShareAmount: equalShareAmount.isFinite && equalShareAmount >= 0
          ? equalShareAmount
          : 0.0,
      categories: List<String>.from(TempGroupPool.defaultCategories),
      participants: const [],
      createdAt: DateTime.now(),
    );

    _pools = [pool, ..._pools];
    _activePoolId = pool.id;
    await _persist();
    notifyListeners();
    return pool;
  }

  Future<void> selectPool(String poolId) async {
    if (!_pools.any((p) => p.id == poolId)) return;
    _activePoolId = poolId;
    await _persist();
    notifyListeners();
  }

  Future<void> updateActivePool({
    String? name,
    bool? isEqualShare,
    double? equalShareAmount,
    String? currency,
  }) async {
    final current = activePool;
    if (current == null) return;

    final updated = current.copyWith(
      name: name != null && name.trim().isNotEmpty ? name.trim() : current.name,
      isEqualShare: isEqualShare ?? current.isEqualShare,
      equalShareAmount:
          equalShareAmount != null &&
              equalShareAmount.isFinite &&
              equalShareAmount >= 0
          ? equalShareAmount
          : current.equalShareAmount,
      currency: currency ?? current.currency,
    );

    _replacePool(updated);
    await _persist();
    notifyListeners();
  }

  /// Splits a given total bill evenly across all current participants.
  Future<void> splitTotalBillEqually(double totalBill) async {
    final current = activePool;
    if (current == null || current.participants.isEmpty) return;
    if (!totalBill.isFinite || totalBill < 0) return;

    final perPerson = totalBill / current.participants.length;
    await updateActivePool(isEqualShare: true, equalShareAmount: perPerson);
  }

  /// Deletes a temporary pool. Intended to be invoked ONLY after user confirmation.
  Future<void> deletePool(String poolId) async {
    _pools = _pools.where((p) => p.id != poolId).toList();
    if (_activePoolId == poolId) {
      _activePoolId = _pools.isNotEmpty ? _pools.first.id : null;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> addCategory(String categoryName) async {
    final current = activePool;
    if (current == null) return;
    final clean = categoryName.trim();
    if (clean.isEmpty) return;
    final exists = current.categories.any(
      (c) => c.toLowerCase() == clean.toLowerCase(),
    );
    if (exists) return;

    final updated = current.copyWith(
      categories: [...current.categories, clean],
    );
    _replacePool(updated);
    await _persist();
    notifyListeners();
  }

  Future<void> removeCategory(String categoryName) async {
    final current = activePool;
    if (current == null) return;
    // Keep the two built-in defaults ('Cash', 'E-Cash') intact
    if (TempGroupPool.defaultCategories.contains(categoryName)) return;

    final nextCategories = current.categories
        .where((c) => c != categoryName)
        .toList();
    // Reassign any participant using the removed category back to Cash
    final nextParticipants = current.participants
        .map(
          (p) => p.category == categoryName
              ? p.copyWith(category: TempGroupPool.defaultCashCategory)
              : p,
        )
        .toList();

    final updated = current.copyWith(
      categories: nextCategories,
      participants: nextParticipants,
    );
    _replacePool(updated);
    await _persist();
    notifyListeners();
  }

  Future<void> addParticipant({
    required String name,
    required double amountPaid,
    required double amountToPay,
    required String category,
    String? owedTo,
    String? notes,
  }) async {
    final current = activePool;
    if (current == null) return;
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    final safePaid = amountPaid.isFinite && amountPaid >= 0 ? amountPaid : 0.0;
    final safeToPay = amountToPay.isFinite && amountToPay >= 0
        ? amountToPay
        : 0.0;
    final cleanCategory = category.trim().isNotEmpty
        ? category.trim()
        : TempGroupPool.defaultCashCategory;
    final cleanOwedTo = owedTo?.trim();
    final cleanNotes = notes?.trim();

    final categories = current.categories.contains(cleanCategory)
        ? current.categories
        : [...current.categories, cleanCategory];

    final participant = TempPoolParticipant(
      id: TempGroupPool.generateId(),
      name: cleanName,
      amountPaid: safePaid,
      amountToPay: safeToPay,
      category: cleanCategory,
      owedTo: cleanOwedTo != null && cleanOwedTo.isNotEmpty
          ? cleanOwedTo
          : null,
      notes: cleanNotes != null && cleanNotes.isNotEmpty ? cleanNotes : null,
    );

    final updated = current.copyWith(
      categories: categories,
      participants: [...current.participants, participant],
    );
    _replacePool(updated);
    await _persist();
    notifyListeners();
  }

  Future<void> updateParticipant(TempPoolParticipant updatedParticipant) async {
    final current = activePool;
    if (current == null) return;

    final nextParticipants = current.participants
        .map((p) => p.id == updatedParticipant.id ? updatedParticipant : p)
        .toList();

    final categories = current.categories.contains(updatedParticipant.category)
        ? current.categories
        : [...current.categories, updatedParticipant.category];

    final updated = current.copyWith(
      categories: categories,
      participants: nextParticipants,
    );
    _replacePool(updated);
    await _persist();
    notifyListeners();
  }

  Future<void> setParticipantChangeResolved(
    String participantId,
    bool resolved,
  ) async {
    final current = activePool;
    if (current == null) return;

    final nextParticipants = current.participants
        .map(
          (p) => p.id == participantId
              ? p.copyWith(isChangeResolved: resolved)
              : p,
        )
        .toList();

    final updated = current.copyWith(participants: nextParticipants);
    _replacePool(updated);
    await _persist();
    notifyListeners();
  }

  Future<void> removeParticipant(String participantId) async {
    final current = activePool;
    if (current == null) return;

    final nextParticipants = current.participants
        .where((p) => p.id != participantId)
        .toList();

    final updated = current.copyWith(participants: nextParticipants);
    _replacePool(updated);
    await _persist();
    notifyListeners();
  }

  Future<void> clearAllData() async {
    _pools = [];
    _activePoolId = null;
    await _persist();
    notifyListeners();
  }

  void _replacePool(TempGroupPool updated) {
    _pools = _pools.map((p) => p.id == updated.id ? updated : p).toList();
  }
}
