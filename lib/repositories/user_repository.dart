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
    final existing = await _db.getUserByEmail(email);
    if (existing != null) {
      throw Exception('Пользователь с таким email уже существует');
    }

    final user = LocalUser(
      email: email,
      passwordHash: LocalUser.hashPassword(password),
      displayName: displayName,
      createdAt: DateTime.now(),
      isAnonymous: false,
    );

    final userId = await _db.createUser(user);
    final created = await _db.getUserById(userId);

    if (created == null) {
      throw Exception('Не удалось создать пользователя');
    }

    // Создаём дефолтные настройки
    await _db.updateUserSettings(userId, darkTheme: true, language: 'ru');

    return created;
  }

  /// Войти (проверить пароль и вернуть пользователя)
  Future<LocalUser> login({
    required String email,
    required String password,
  }) async {
    final user = await _db.getUserByEmail(email);
    if (user == null) {
      throw Exception('Пользователь не найден');
    }

    if (!LocalUser.verifyPassword(password, user.passwordHash)) {
      throw Exception('Неверный пароль');
    }

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
