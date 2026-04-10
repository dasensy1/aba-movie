import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/local_database_service.dart';

/// ============================================================================
/// USER REPOSITORY
/// ============================================================================
/// Репозиторий для работы с пользователями и их данными.
/// Абстрагирует провайдеры от прямого доступа к БД.
/// ============================================================================

class UserRepository {
  final LocalDatabaseService _db = LocalDatabaseService();

  // ==================== AUTH ====================

  /// Зарегистрировать нового пользователя
  Future<LocalUser> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    debugPrint('=== РЕГИСТРАЦИЯ ===');
    debugPrint('Email: $email');
    debugPrint('DisplayName: $displayName');
    
    final existing = await _db.getUserByEmail(email);
    if (existing != null) {
      debugPrint('Пользователь с таким email уже существует!');
      throw Exception('Пользователь с таким email уже существует');
    }

    final user = LocalUser(
      email: email,
      passwordHash: LocalUser.hashPassword(password),
      displayName: displayName,
      createdAt: DateTime.now(),
      isAnonymous: false,
    );

    debugPrint('Создаю пользователя в БД...');
    final userId = await _db.createUser(user);
    debugPrint('Пользователь создан с ID: $userId');
    
    final created = await _db.getUserById(userId);
    if (created == null) {
      debugPrint('ОШИБКА: Не удалось получить пользователя после создания!');
      throw Exception('Не удалось создать пользователя');
    }

    debugPrint('Создаю настройки для пользователя...');
    await _db.updateUserSettings(userId, darkTheme: true, language: 'ru');
    
    debugPrint('Регистрация успешна! User ID: ${created.id}, Email: ${created.email}');
    return created;
  }

  /// Войти (проверить пароль и вернуть пользователя)
  Future<LocalUser> login({
    required String email,
    required String password,
  }) async {
    debugPrint('=== ВХОД ===');
    debugPrint('Email: $email');
    
    final user = await _db.getUserByEmail(email);
    if (user == null) {
      debugPrint('ОШИБКА: Пользователь с email=$email не найден');
      throw Exception('Пользователь не найден');
    }

    debugPrint('Пользователь найден: ID=${user.id}, Email=${user.email}');
    
    final passwordValid = LocalUser.verifyPassword(password, user.passwordHash);
    debugPrint('Проверка пароля: ${passwordValid ? "УСПЕХ" : "НЕУДАЧА"}');
    
    if (!passwordValid) {
      debugPrint('ОШИБКА: Неверный пароль для пользователя ${user.email}');
      throw Exception('Неверный пароль');
    }

    debugPrint('Вход успешен! User ID: ${user.id}');
    return user;
  }

  /// Быстрый вход для уже авторизованного (по ID)
  Future<LocalUser?> getUserById(int id) async {
    return await _db.getUserById(id);
  }

  /// Получить текущего активного пользователя по email (для сессии)
  Future<LocalUser?> getUserByEmail(String email) async {
    return await _db.getUserByEmail(email);
  }

  // ==================== SETTINGS ====================

  Future<Map<String, dynamic>?> getUserSettings(int userId) async {
    return await _db.getUserSettings(userId);
  }

  Future<void> updateUserSettings(
    int userId, {
    bool? darkTheme,
    String? language,
  }) async {
    await _db.updateUserSettings(userId, darkTheme: darkTheme, language: language);
  }

  // ==================== CLEAR ====================

  /// Удалить все данные пользователя (без удаления самого пользователя)
  Future<void> clearUserData(int userId) async {
    await _db.clearUserData(userId);
  }

  /// Полный сброс (удалить всё)
  Future<void> clearAll() async {
    await _db.clearAll();
  }
}
