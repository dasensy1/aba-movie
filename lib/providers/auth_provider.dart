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

  /// Инициализация при старте приложения
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Читаем session_user_id из SharedPreferences (единственное, что там храним)
      final prefs = await SharedPreferences.getInstance();
      final sessionUserId = prefs.getInt(_sessionUserIdKey);

      if (sessionUserId != null) {
        _localUser = await _userRepository.getUserById(sessionUserId);
        if (_localUser != null) {
          _user = _localUser!.toAppUser();
        } else {
          // Пользователь удалён — очищаем сессию
          await prefs.remove(_sessionUserIdKey);
        }
      }
    } catch (e) {
      debugPrint('Ошибка инициализации auth: $e');
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

      _localUser = await _userRepository.login(email: email, password: password);
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
      // Очищаем сессию
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionUserIdKey);

      _localUser = null;
      _user = null;
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
