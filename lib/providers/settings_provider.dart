import 'package:flutter/material.dart';
import '../repositories/user_repository.dart';

/// ============================================================================
/// SETTINGS PROVIDER — Версия 2 (user-scoped из БД)
/// ============================================================================
/// Настройки темы и языка хранятся в user_settings таблице БД.
/// Привязаны к конкретному пользователю.
/// ============================================================================

class SettingsProvider with ChangeNotifier {
  final UserRepository _userRepository = UserRepository();

  bool _isDarkTheme = true;
  String _language = 'ru';

  bool get isDarkTheme => _isDarkTheme;
  String get language => _language;
  bool get isLoading => false;

  /// Инициализация настроек
  Future<void> initialize(int? userId) async {
    try {
      if (userId != null) {
        final settings = await _userRepository.getUserSettings(userId);
        if (settings != null) {
          _isDarkTheme = (settings['dark_theme'] ?? 1) == 1;
          _language = settings['language'] ?? 'ru';
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Settings initialization error: $e');
      notifyListeners();
    }
  }

  /// Переключить тему (сохранить в БД для пользователя)
  Future<void> toggleTheme(bool isDark, int? userId) async {
    _isDarkTheme = isDark;
    if (userId != null) {
      await _userRepository.updateUserSettings(userId, darkTheme: isDark);
    }
    notifyListeners();
  }

  /// Установить язык (сохранить в БД для пользователя)
  Future<void> setLanguage(String languageCode, int? userId) async {
    _language = languageCode;
    if (userId != null) {
      await _userRepository.updateUserSettings(userId, language: languageCode);
    }
    notifyListeners();

    // Принудительно обновить UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Получить локализованное название языка
  String getLanguageName(String code) {
    switch (code) {
      case 'ru':
        return 'Русский';
      case 'en':
        return 'English';
      default:
        return 'Русский';
    }
  }

  /// Получить иконку языка
  IconData getLanguageIcon(String code) {
    switch (code) {
      case 'ru':
        return Icons.language;
      case 'en':
        return Icons.translate;
      default:
        return Icons.language;
    }
  }

  /// Получить все поддерживаемые языки
  List<Map<String, String>> get supportedLanguages {
    return [
      {'code': 'ru', 'name': 'Русский'},
      {'code': 'en', 'name': 'English'},
    ];
  }

  /// Сбросить настройки к умолчанию
  Future<void> resetToDefaults(int? userId) async {
    if (userId != null) {
      await _userRepository.updateUserSettings(userId, darkTheme: true, language: 'ru');
    }
    _isDarkTheme = true;
    _language = 'ru';
    notifyListeners();
  }

  /// Очистить кэш
  Future<void> clearCache() async {
    notifyListeners();
  }
}

/// ============================================================================
/// THEME DATA — Современный дизайн с glassmorphism и градиентами
/// ============================================================================

class AppThemes {
  // Современные цветовые палитры
  static const _primaryPurple = Color(0xFF8B5CF6);
  static const _primaryPurpleDark = Color(0xFF7C3AED);
  static const _primaryPurpleLight = Color(0xFFA78BFA);
  static const _accentCyan = Color(0xFF06B6D4);
  static const _accentPink = Color(0xFFEC4899);
  static const _surfaceDark = Color(0xFF1E1B2E);
  static const _surfaceDarkHigher = Color(0xFF262340);
  static const _backgroundDark = Color(0xFF0F0D1A);
  static const _error = Color(0xFFEF4444);

  /// Темная тема (основная) — современный дизайн
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: _primaryPurple,
      primaryColorLight: _primaryPurpleLight,
      primaryColorDark: _primaryPurpleDark,
      scaffoldBackgroundColor: _backgroundDark,
      cardColor: _surfaceDark,

      colorScheme: const ColorScheme.dark(
        primary: _primaryPurple,
        secondary: _accentCyan,
        tertiary: _accentPink,
        surface: _surfaceDark,
        error: _error,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        onError: Colors.black,
      ),

      // AppBar с glassmorphism
      appBarTheme: AppBarTheme(
        backgroundColor: _backgroundDark.withValues(alpha: 0.8),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // Карточки с тенями и скруглениями
      cardTheme: CardThemeData(
        color: _surfaceDark,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),

      // Кнопки с градиентами
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Поля ввода с современным стилем
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primaryPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _error.withValues(alpha: 0.5)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
      ),

      // Нижняя навигация
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _surfaceDark,
        selectedItemColor: _primaryPurple,
        unselectedItemColor: Color(0xFF6B7280),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // FAB с градиентом
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primaryPurple,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _surfaceDarkHigher,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Диалоги
      dialogTheme: DialogThemeData(
        backgroundColor: _surfaceDark,
        elevation: 0,
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
        contentTextStyle: TextStyle(
          fontSize: 15,
          color: Colors.white.withValues(alpha: 0.7),
          height: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),

      // Чипы
      chipTheme: ChipThemeData(
        backgroundColor: _surfaceDarkHigher,
        selectedColor: _primaryPurple.withValues(alpha: 0.2),
        labelStyle: const TextStyle(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Разделители
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.06),
        thickness: 1,
        space: 1,
      ),

      // Иконки
      iconTheme: const IconThemeData(
        color: Colors.white,
        size: 24,
      ),

      // Текст
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.5,
          height: 1.1,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.3,
          height: 1.2,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.white,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.white70,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: Colors.white54,
          height: 1.3,
        ),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
        labelMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white70,
        ),
      ),

      // Списки
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),

      // Переключатели
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryPurple.withValues(alpha: 0.3);
          }
          return Colors.white.withValues(alpha: 0.1);
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryPurple;
          }
          return Colors.white.withValues(alpha: 0.6);
        }),
      ),
    );
  }

  /// Светлая тема — современный дизайн
  static ThemeData get lightTheme {
    const primaryLight = Color(0xFF8B5CF6);
    const surfaceLight = Colors.white;
    const backgroundLight = Color(0xFFF8F7FF);

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryLight,
      scaffoldBackgroundColor: backgroundLight,
      cardColor: surfaceLight,

      colorScheme: const ColorScheme.light(
        primary: primaryLight,
        secondary: Color(0xFF06B6D4),
        tertiary: Color(0xFFEC4899),
        surface: backgroundLight,
        error: Color(0xFFEF4444),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF1F2937),
        onError: Colors.white,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: backgroundLight.withValues(alpha: 0.95),
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F2937),
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),

      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF8B5CF6),
        unselectedItemColor: Color(0xFF9CA3AF),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1F2937),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F2937),
          letterSpacing: 0.3,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 15,
          color: Color(0xFF6B7280),
          height: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF3F4F6),
        selectedColor: primaryLight.withValues(alpha: 0.15),
        labelStyle: const TextStyle(color: Color(0xFF1F2937), fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      dividerTheme: DividerThemeData(
        color: Colors.black.withValues(alpha: 0.06),
        thickness: 1,
        space: 1,
      ),

      iconTheme: const IconThemeData(
        color: Color(0xFF1F2937),
        size: 24,
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1F2937),
          letterSpacing: -0.5,
          height: 1.1,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F2937),
          letterSpacing: -0.3,
          height: 1.2,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F2937),
          letterSpacing: 0.2,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Color(0xFF374151),
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Color(0xFF6B7280),
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: Color(0xFF9CA3AF),
          height: 1.3,
        ),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
          letterSpacing: 0.3,
        ),
        labelMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF6B7280),
        ),
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),

      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryLight.withValues(alpha: 0.3);
          }
          return Colors.black.withValues(alpha: 0.1);
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryLight;
          }
          return Colors.white;
        }),
      ),
    );
  }
}
