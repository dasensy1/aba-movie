import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

/// ============================================================================
/// USER REPOSITORY — Direct DB Access (No Supabase Auth)
/// ============================================================================
/// Работает напрямую с таблицами `users` и `logout` в Supabase.
/// Аутентификация: сравнение email и password_hash из таблицы users.
/// Таблица users имеет колонки: id, created_at, email, name, password_hash
/// ============================================================================

class UserRepository {
  final SupabaseService _supabase = SupabaseService();

  // ==================== AUTH ====================

  /// Зарегистрировать нового пользователя (прямая запись в users)
  Future<LocalUser> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    debugPrint('=== РЕГИСТРАЦИЯ (direct DB) ===');
    debugPrint('Email: $email, Name: $displayName');

    // Проверяем существование
    try {
      final existing = await getUserByEmail(email);
      if (existing != null) {
        debugPrint('Пользователь уже существует');
        throw Exception('Пользователь с таким email уже существует');
      }
    } catch (e) {
      debugPrint('Ошибка проверки: $e');
    }

    // Подготавливаем данные для users
    final now = DateTime.now().toIso8601String();
    final passwordHash = LocalUser.hashPassword(password);

    try {
      final client = await _supabase.getClient();
      final response = await client.from('users').insert({
        'email': email,
        'name': displayName ?? email.split('@')[0],
        'password_hash': passwordHash,
        'created_at': now,
      }).select();

      if (response.isNotEmpty) {
        final userMap = response.first as Map<String, dynamic>;
        final user = _mapLocalUserFromDb(userMap);
        debugPrint('Пользователь создан, ID: ${user.id}');
        return user;
      }
      throw Exception('Не удалось создать пользователя');
    } catch (e) {
      debugPrint('Ошибка регистрации: $e');
      rethrow;
    }
  }

  /// Войти (проверить пароль и вернуть пользователя)
  Future<LocalUser> login({
    required String email,
    required String password,
  }) async {
    debugPrint('=== ВХОД (direct DB) ===');
    debugPrint('Email: $email');

    try {
      final user = await getUserByEmail(email);
      if (user == null) {
        debugPrint('Пользователь не найден');
        throw Exception('Пользователь не найден');
      }

      debugPrint('Найден пользователь ID: ${user.id}');

      // Проверяем пароль
      final passwordValid =
          LocalUser.verifyPassword(password, user.passwordHash);
      debugPrint('Пароль: ${passwordValid ? "верный" : "неверный"}');

      if (!passwordValid) {
        throw Exception('Неверный пароль');
      }

      debugPrint('Вход успешен');
      return user;
    } catch (e) {
      debugPrint('Ошибка входа: $e');
      rethrow;
    }
  }

  /// Получить пользователя по ID
  Future<LocalUser?> getUserById(int id) async {
    try {
      final map = await _supabase.getUserById(id);
      if (map != null) {
        return _mapLocalUserFromDb(map);
      }
    } catch (e) {
      debugPrint('getUserById error: $e');
    }
    return null;
  }

  /// Получить пользователя по email
  Future<LocalUser?> getUserByEmail(String email) async {
    try {
      final map = await _supabase.getUserByEmail(email);
      if (map != null) {
        return _mapLocalUserFromDb(map);
      }
    } catch (e) {
      debugPrint('getUserByEmail error: $e');
    }
    return null;
  }

  /// Сохранить аккаунт после выхода в таблицу logout
  Future<void> saveLogoutAccount(LocalUser user) async {
    try {
      final now = DateTime.now().toIso8601String();
      await _supabase.insertLogoutAccount({
        'user_id': user.id,
        'email': user.email,
        'display_name': user.displayName,
        'photo_url': user.photoUrl,
        'logged_out_at': now,
      });
      debugPrint('Logout account saved');
    } catch (e) {
      debugPrint('saveLogoutAccount error: $e');
    }
  }

  /// Получить список сохраненных аккаунтов из logout
  Future<List<SavedAccount>> getSavedAccounts() async {
    try {
      final rows = await _supabase.getLogoutAccounts();
      return rows.map((map) => SavedAccount.fromMap(map)).toList();
    } catch (e) {
      debugPrint('getSavedAccounts error: $e');
      return [];
    }
  }

  // ==================== SETTINGS ====================

  Future<Map<String, dynamic>?> getUserSettings(int userId) async {
    return await _supabase.getUserSettings(userId);
  }

  Future<void> updateUserSettings(
    int userId, {
    bool? darkTheme,
    String? language,
  }) async {
    await _supabase.upsertUserSettings(userId, {
      if (darkTheme != null) 'dark_theme': darkTheme ? 1 : 0,
      if (language != null) 'language': language,
    });
  }

  // ==================== CLEAR ====================

  Future<void> clearUserData(int userId) async {
    try {
      await _supabase.deleteUser(userId);
      // CASCADE удалит связанные данные (favorites, watchlist, watch_log, reviews, user_settings)
    } catch (e) {
      debugPrint('clearUserData error: $e');
    }
  }

  Future<void> clearAll() async {
    throw UnimplementedError('Полный сброс через клиент Supabase невозможен');
  }

  // ==================== MAPPING ====================

  /// Преобразует Map из Supabase (таблица users) в LocalUser
  LocalUser _mapLocalUserFromDb(Map<String, dynamic> map) {
    return LocalUser(
      id: map['id'] as int,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String,
      displayName: map['name'] as String?, // колонка `name` → displayName
      photoUrl: null, // колонки photo_url нет
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
      isAnonymous: false, // колонки is_anonymous нет
    );
  }
}
