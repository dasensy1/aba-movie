import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================================
/// SHARED PREFERENCES SERVICE
/// ============================================================================
/// Сервис для хранения простых настроек приложения
/// ============================================================================

class SharedPrefsService {
  static final SharedPrefsService _instance = SharedPrefsService._internal();
  factory SharedPrefsService() => _instance;
  SharedPrefsService._internal();

  SharedPreferences? _prefs;

  /// Инициализация
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Получить SharedPreferences экземпляр
  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// ============================================================================
  /// НАСТРОЙКИ ТЕМЫ
  /// ============================================================================
  
  /// Темная тема включена
  Future<bool> isDarkTheme() async {
    final p = await prefs;
    return p.getBool('dark_theme') ?? true;
  }

  /// Установить тему
  Future<void> setDarkTheme(bool value) async {
    final p = await prefs;
    await p.setBool('dark_theme', value);
  }

  /// ============================================================================
  /// ЯЗЫК
  /// ============================================================================
  
  /// Получить выбранный язык
  Future<String> getLanguage() async {
    final p = await prefs;
    return p.getString('language') ?? 'ru';
  }

  /// Установить язык
  Future<void> setLanguage(String value) async {
    final p = await prefs;
    await p.setString('language', value);
  }

  /// ============================================================================
  /// FIRST LAUNCH
  /// ============================================================================
  
  /// Первый запуск приложения
  Future<bool> isFirstLaunch() async {
    final p = await prefs;
    return p.getBool('first_launch') ?? true;
  }

  /// Установить, что приложение уже запускалось
  Future<void> setFirstLaunch(bool value) async {
    final p = await prefs;
    await p.setBool('first_launch', value);
  }

  /// ============================================================================
  /// ИЗБРАННОЕ (дублирование для быстрого доступа)
  /// ============================================================================

  /// Получить список ID избранных фильмов
  Future<List<int>> getFavoriteIds() async {
    final p = await prefs;
    final ids = p.getStringList('favorite_ids')?.map(int.parse).toList() ?? [];
    return ids;
  }

  /// Добавить ID в избранное
  Future<void> addFavoriteId(int id) async {
    final p = await prefs;
    final ids = await getFavoriteIds();
    if (!ids.contains(id)) {
      ids.add(id);
      await p.setStringList('favorite_ids', ids.map((e) => e.toString()).toList());
    }
  }

  /// Удалить ID из избранного
  Future<void> removeFavoriteId(int id) async {
    final p = await prefs;
    final ids = await getFavoriteIds();
    ids.remove(id);
    await p.setStringList('favorite_ids', ids.map((e) => e.toString()).toList());
  }

  /// Проверить, есть ли в избранном
  Future<bool> isFavorite(int id) async {
    final ids = await getFavoriteIds();
    return ids.contains(id);
  }

  /// ============================================================================
  /// ПОСЛЕДНИЙ ПОИСК
  /// ============================================================================
  
  /// Сохранить последний поисковый запрос
  Future<void> saveLastSearch(String query) async {
    final p = await prefs;
    await p.setString('last_search', query);
  }

  /// Получить последний поисковый запрос
  Future<String?> getLastSearch() async {
    final p = await prefs;
    return p.getString('last_search');
  }

  /// ============================================================================
  /// ОБЩИЕ МЕТОДЫ
  /// ============================================================================

  /// Получить строку
  Future<String?> getString(String key) async {
    final p = await prefs;
    return p.getString(key);
  }

  /// Установить строку
  Future<void> setString(String key, String value) async {
    final p = await prefs;
    await p.setString(key, value);
  }

  /// Удалить значение
  Future<void> remove(String key) async {
    final p = await prefs;
    await p.remove(key);
  }

  /// ============================================================================
  /// ОЧИСТКА
  /// ============================================================================

  /// Очистить все данные
  Future<void> clearAll() async {
    final p = await prefs;
    await p.clear();
  }
}
