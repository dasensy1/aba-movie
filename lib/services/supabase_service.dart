// ============================================================================
// SUPABASE SERVICE — Direct Database Access (No Supabase Auth)
// ============================================================================
// Прямой доступ к таблицам Supabase без использования Supabase Auth.
// Аутентификация выполняется через таблицу `users` (сравнение password_hash).
// ============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/supabase_config.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? _client;
  bool _initialized = false;

  Future<SupabaseClient> getClient() async {
    if (!_initialized) {
      await _initialize();
    }
    if (_client == null) {
      throw StateError('Supabase client is null');
    }
    return _client!;
  }

  Future<void> _initialize() async {
    if (_initialized) return;

    if (SupabaseConfig.url.isEmpty ||
        SupabaseConfig.anonKey.isEmpty ||
        SupabaseConfig.anonKey.contains('YOUR_ANON')) {
      debugPrint('⚠️ Supabase not configured');
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
      _client = Supabase.instance.client;
      _initialized = true;
      debugPrint('✅ Supabase initialized');
    } catch (e) {
      debugPrint('❌ Supabase init error: $e');
      rethrow;
    }
  }

  bool get isInitialized => _initialized;

  // ==================== USERS ====================

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final client = await getClient();
    final data =
        await client.from('users').select().eq('email', email).maybeSingle();
    return (data != null && data.isNotEmpty) ? data : null;
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final client = await getClient();
    final data = await client.from('users').select().eq('id', id).maybeSingle();
    return (data != null && data.isNotEmpty) ? data : null;
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    final client = await getClient();
    final response = await client.from('users').insert(data).select();
    if (response != null && response.isNotEmpty) {
      return response.first as Map<String, dynamic>;
    }
    throw Exception('Failed to create user');
  }

  Future<void> updateUser(int id, Map<String, dynamic> data) async {
    final client = await getClient();
    await client.from('users').update(data).eq('id', id);
  }

  Future<void> deleteUser(int id) async {
    final client = await getClient();
    await client.from('users').delete().eq('id', id);
  }

  // ==================== USER_SETTINGS ====================

  Future<Map<String, dynamic>?> getUserSettings(int userId) async {
    final client = await getClient();
    return await client
        .from('user_settings')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
  }

  Future<void> upsertUserSettings(
      int userId, Map<String, dynamic> settings) async {
    final client = await getClient();
    await client.from('user_settings').upsert({
      'user_id': userId,
      ...settings,
    }, onConflict: 'user_id');
  }

  // ==================== FAVORITES ====================

  Future<List<Map<String, dynamic>>> getFavorites(int userId) async {
    final client = await getClient();
    return await client
        .from('favorites')
        .select()
        .eq('user_id', userId)
        .order('added_at', ascending: false);
  }

  Future<void> insertFavorite(Map<String, dynamic> data) async {
    final client = await getClient();
    await client.from('favorites').insert(data);
  }

  Future<void> deleteFavorite(int userId, int movieId) async {
    final client = await getClient();
    await client
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('movie_id', movieId);
  }

  // ==================== WATCHLIST ====================

  Future<List<Map<String, dynamic>>> getWatchlist(int userId) async {
    final client = await getClient();
    return await client
        .from('watchlist')
        .select()
        .eq('user_id', userId)
        .order('added_date', ascending: false);
  }

  Future<void> insertWatchlistItem(Map<String, dynamic> data) async {
    final client = await getClient();
    await client.from('watchlist').insert(data);
  }

  Future<void> updateWatchlistItem(
      int userId, int movieId, Map<String, dynamic> data) async {
    final client = await getClient();
    await client
        .from('watchlist')
        .update(data)
        .eq('user_id', userId)
        .eq('movie_id', movieId);
  }

  Future<void> deleteWatchlistItem(int userId, int movieId) async {
    final client = await getClient();
    await client
        .from('watchlist')
        .delete()
        .eq('user_id', userId)
        .eq('movie_id', movieId);
  }

  // ==================== WATCH_LOG ====================

  Future<void> insertWatchLog(Map<String, dynamic> data) async {
    final client = await getClient();
    await client.from('watch_log').insert(data);
  }

  Future<List<Map<String, dynamic>>> getActivityLog(int userId,
      {int limit = 20}) async {
    final client = await getClient();
    return await client
        .from('watch_log')
        .select('movie_id, status, watch_date')
        .eq('user_id', userId)
        .order('watch_date', ascending: false)
        .limit(limit);
  }

  // ==================== REVIEWS ====================

  Future<List<Map<String, dynamic>>> getMovieReviews(int movieId) async {
    final client = await getClient();
    return await client
        .from('reviews')
        .select()
        .eq('movie_id', movieId)
        .order('created_at', ascending: false);
  }

  Future<void> insertReview(Map<String, dynamic> data) async {
    final client = await getClient();
    await client.from('reviews').insert(data);
  }

  Future<void> deleteReview(int reviewId, int userId) async {
    final client = await getClient();
    await client
        .from('reviews')
        .delete()
        .eq('id', reviewId)
        .eq('user_id', userId);
  }

  // ==================== LOGOUT TABLE ====================

  Future<void> insertLogoutAccount(Map<String, dynamic> data) async {
    final client = await getClient();
    await client.from('logout').upsert(data, onConflict: 'user_id');
  }

  Future<List<Map<String, dynamic>>> getLogoutAccounts() async {
    final client = await getClient();
    return await client
        .from('logout')
        .select()
        .order('logged_out_at', ascending: false);
  }
}
