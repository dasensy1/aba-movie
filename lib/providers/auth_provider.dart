import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../repositories/user_repository.dart';

/// ============================================================================
/// AUTH PROVIDER (ЛОКАЛЬНАЯ АВТОРИЗАЦИЯ) — Версия 2 (БД)
/// ============================================================================
/// Провайдер для управления состоянием аутентификации.
/// Хранит пользователей в SQLite через UserRepository.
/// В SharedPreferences сохраняет только session_user_id для восстановления сессии.
/// ============================================================================

class AuthProvider with ChangeNotifier {
  final UserRepository _userRepository = UserRepository();

  LocalUser? _localUser; // Реальный пользователь из БД
  AppUser? _user; // AppUser для совместимости с UI
  bool _isLoading = false;
  String? _error;

  LocalUser? get localUser => _localUser;
  AppUser? get user => _user;
  int? get userId => _localUser?.id;
  bool get isLoading => _isLoading;
  bool get isSignedIn => _user != null;
  String? get error => _error;

  /// Ключ для хранения ID сессии в SharedPreferences
  static const _sessionUserIdKey = 'session_user_id';

  Future<List<SavedAccount>> getSavedAccounts() async {
    try {
      return await _userRepository.getSavedAccounts();
    } catch (e) {
      debugPrint('Ошибка загрузки сохраненных аккаунтов: $e');
      return [];
    }
  }

  /// Инициализация при старте приложения
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    debugPrint('=== ИНИЦИАЛИЗАЦИЯ AUTH PROVIDER ===');

    try {
      // Читаем session_user_id из SharedPreferences (единственное, что там храним)
      final prefs = await SharedPreferences.getInstance();
      final sessionUserId = prefs.getInt(_sessionUserIdKey);

      debugPrint('session_user_id из SharedPreferences: $sessionUserId');

      if (sessionUserId != null) {
        debugPrint('Попытка восстановления сессии для пользователя ID: $sessionUserId');
        
        // Пробуем восстановить пользователя из БД с увеличенным таймаутом
        try {
          _localUser = await _userRepository.getUserById(sessionUserId)
              .timeout(const Duration(seconds: 15));
          
          if (_localUser != null) {
            debugPrint('Сессия восстановлена успешно: ${_localUser!.email}');
            _user = _localUser!.toAppUser();
          } else {
            // Пользователь удалён — очищаем сессию
            debugPrint('Пользователь ID $sessionUserId не найден в БД, очищаем сессию');
            await prefs.remove(_sessionUserIdKey);
            _localUser = null;
            _user = null;
          }
        } catch (dbError) {
          debugPrint('Ошибка при чтении пользователя из БД: $dbError');
          // Пробуем еще раз без таймаута
          try {
            _localUser = await _userRepository.getUserById(sessionUserId);
            if (_localUser != null) {
              debugPrint('Сессия восстановлена (без таймаута): ${_localUser!.email}');
              _user = _localUser!.toAppUser();
            } else {
              await prefs.remove(_sessionUserIdKey);
            }
          } catch (retryError) {
            debugPrint('Повторная ошибка: $retryError');
            // Если БД недоступна, но сессия была - не теряем пользователя
            // Оставляем _localUser = null, но сохраняем sessionUserId
          }
        }
      } else {
        debugPrint('Сессия не найдена в SharedPreferences');
      }
    } catch (e) {
      debugPrint('Критическая ошибка инициализации auth: $e');
      // Не блокируем приложение — продолжаем без сессии
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Вход (локальный, через БД)
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800)); // Имитация задержки

    try {
      if (email.isEmpty || password.isEmpty) {
        _error = 'Введите email и пароль';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (password.length < 6) {
        _error = 'Пароль должен быть не менее 6 символов';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Сначала проверяем существует ли пользователь
      final existingUser = await _userRepository.getUserByEmail(email);
      if (existingUser == null) {
        _error = 'Аккаунт с таким email не существует. Пожалуйста, зарегистрируйтесь.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Теперь пробуем войти
      _localUser = await _userRepository.login(email: email, password: password);
      _user = _localUser!.toAppUser();

      // Сохраняем сессию
      final prefs = await SharedPreferences.getInstance();
      debugPrint('Сохраняю сессию: user_id=${_localUser!.id}');
      await prefs.setInt(_sessionUserIdKey, _localUser!.id!);
      
      // Проверим что сохранилось
      final savedId = prefs.getInt(_sessionUserIdKey);
      debugPrint('Проверка: session_user_id из SharedPreferences = $savedId');

      debugPrint('Вход выполнен успешно: ${_localUser!.email}');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      
      // Преобразуем технические ошибки в понятные сообщения
      if (errorMsg.contains('Пользователь не найден')) {
        _error = 'Аккаунт с таким email не существует. Пожалуйста, зарегистрируйтесь.';
      } else if (errorMsg.contains('Неверный пароль')) {
        _error = 'Неверный пароль. Проверьте правильность ввода.';
      } else {
        _error = 'Ошибка входа: $errorMsg';
      }
      
      debugPrint('Ошибка входа: $errorMsg');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Регистрация (локальная, через БД)
  Future<bool> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800)); // Имитация задержки

    try {
      if (email.isEmpty || password.isEmpty) {
        _error = 'Введите email и пароль';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (password.length < 6) {
        _error = 'Пароль должен быть не менее 6 символов';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (!email.contains('@')) {
        _error = 'Введите корректный email';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _localUser = await _userRepository.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      _user = _localUser!.toAppUser();

      // Сохраняем сессию
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_sessionUserIdKey, _localUser!.id!);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Выход
  Future<void> logout() async {
    try {
      if (_localUser != null) {
        await _userRepository.saveLogoutAccount(_localUser!);
      }

      // Очищаем сессию
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionUserIdKey);

      _localUser = null;
      _user = null;

      // Сбрасываем флаги загрузки чтобы провайдеры перезагрузили данные при следующем входе
      // Это нужно чтобы при следующем login данные загрузились заново
      notifyListeners();
    } catch (e) {
      _error = 'Ошибка выхода: $e';
      notifyListeners();
    }
  }

  /// Сброс ошибки
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
