import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// ============================================================================
/// AUTH PROVIDER (ЛОКАЛЬНАЯ АВТОРИЗАЦИЯ)
/// ============================================================================
/// Провайдер для управления состоянием аутентификации
/// Работает локально без Firebase
/// ============================================================================

class AuthProvider with ChangeNotifier {
  final SharedPrefsService _prefsService = SharedPrefsService();

  AppUser? _user;
  bool _isLoading = false;
  String? _error;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isSignedIn => _user != null;
  String? get error => _error;

  /// Инициализация при старте приложения
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _prefsService.init();
      
      // Проверяем, есть ли сохранённый пользователь
      final savedEmail = await _prefsService.getString('saved_user_email');
      final savedName = await _prefsService.getString('saved_user_name');
      
      if (savedEmail != null && savedEmail.isNotEmpty) {
        _user = AppUser(
          uid: 'local_user_001',
          email: savedEmail,
          displayName: savedName,
          createdAt: DateTime.now(),
          isAnonymous: false,
        );
      }
    } catch (e) {
      debugPrint('Ошибка инициализации auth: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Вход (локальный)
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800)); // Имитация задержки

    try {
      // Простая валидация
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

      // Создаём локального пользователя
      _user = AppUser(
        uid: 'local_user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        displayName: email.split('@').first,
        createdAt: DateTime.now(),
        isAnonymous: false,
      );

      // Сохраняем данные
      await _prefsService.setString('saved_user_email', email);
      await _prefsService.setString('saved_user_name', _user!.displayName ?? '');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка входа: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Регистрация (локальная)
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

      // Создаём локального пользователя
      _user = AppUser(
        uid: 'local_user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        displayName: displayName ?? email.split('@').first,
        createdAt: DateTime.now(),
        isAnonymous: false,
      );

      // Сохраняем данные
      await _prefsService.setString('saved_user_email', email);
      await _prefsService.setString('saved_user_name', _user!.displayName ?? '');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка регистрации: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Выход
  Future<void> logout() async {
    try {
      await _prefsService.remove('saved_user_email');
      await _prefsService.remove('saved_user_name');
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
