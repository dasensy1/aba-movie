import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

/// ============================================================================
/// LOCAL DATABASE SERVICE (SQFLITE)
/// ============================================================================
/// Сервис для локального хранения данных (избранные фильмы, настройки)
/// ============================================================================

class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  Database? _database;

  /// ============================================================================
  /// ИНИЦИАЛИЗАЦИЯ БАЗЫ ДАННЫХ
  /// ============================================================================
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'movie_tracker.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// Создание таблиц
  Future<void> _onCreate(Database db, int version) async {
    // Таблица избранных фильмов
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        overview TEXT,
        posterPath TEXT,
        backdropPath TEXT,
        voteAverage REAL,
        voteCount INTEGER,
        releaseDate TEXT,
        genreIds TEXT,
        popularity REAL,
        addedAt TEXT NOT NULL
      )
    ''');

    // Таблица истории просмотров
    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        overview TEXT,
        posterPath TEXT,
        backdropPath TEXT,
        voteAverage REAL,
        voteCount INTEGER,
        releaseDate TEXT,
        genreIds TEXT,
        popularity REAL,
        viewedAt TEXT NOT NULL
      )
    ''');

    // Таблица настроек
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  /// ============================================================================
  /// ИЗБРАННЫЕ ФИЛЬМЫ
  /// ============================================================================

  /// Добавить фильм в избранное
  Future<bool> addToFavorites(Movie movie) async {
    try {
      final db = await database;
      
      // Проверяем, есть ли уже фильм в избранном
      final existing = await db.query(
        'favorites',
        where: 'id = ?',
        whereArgs: [movie.id],
      );

      if (existing.isNotEmpty) {
        return false; // Уже в избранном
      }

      await db.insert('favorites', {
        ...movie.toMap(),
        'addedAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      throw Exception('Ошибка добавления в избранное: $e');
    }
  }

  /// Удалить фильм из избранного
  Future<bool> removeFromFavorites(int movieId) async {
    try {
      final db = await database;
      final deleted = await db.delete(
        'favorites',
        where: 'id = ?',
        whereArgs: [movieId],
      );
      return deleted > 0;
    } catch (e) {
      throw Exception('Ошибка удаления из избранного: $e');
    }
  }

  /// Проверить, есть ли фильм в избранном
  Future<bool> isFavorite(int movieId) async {
    try {
      final db = await database;
      final result = await db.query(
        'favorites',
        where: 'id = ?',
        whereArgs: [movieId],
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Получить все избранные фильмы
  Future<List<Movie>> getFavorites() async {
    try {
      final db = await database;
      final maps = await db.query('favorites', orderBy: 'addedAt DESC');
      return maps.map((map) => Movie.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Получить количество избранных фильмов
  Future<int> getFavoritesCount() async {
    try {
      final db = await database;
      return Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM favorites')
      ) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// ============================================================================
  /// ИСТОРИЯ ПРОСМОТРОВ
  /// ============================================================================

  /// Добавить фильм в историю
  Future<void> addToHistory(Movie movie) async {
    try {
      final db = await database;
      
      // Сначала удаляем если уже есть
      await db.delete(
        'history',
        where: 'id = ?',
        whereArgs: [movie.id],
      );

      await db.insert('history', {
        ...movie.toMap(),
        'viewedAt': DateTime.now().toIso8601String(),
      });

      // Оставляем только последние 50 фильмов
      final oldEntries = await db.rawQuery(
        'SELECT id FROM history ORDER BY viewedAt DESC LIMIT -1 OFFSET 50'
      );
      for (var entry in oldEntries) {
        await db.delete('history', where: 'id = ?', whereArgs: [entry['id']]);
      }
    } catch (e) {
      // Игнорируем ошибки истории
    }
  }

  /// Получить историю просмотров
  Future<List<Movie>> getHistory() async {
    try {
      final db = await database;
      final maps = await db.query('history', orderBy: 'viewedAt DESC', limit: 50);
      return maps.map((map) => Movie.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Очистить историю
  Future<void> clearHistory() async {
    try {
      final db = await database;
      await db.delete('history');
    } catch (e) {
      throw Exception('Ошибка очистки истории: $e');
    }
  }

  /// ============================================================================
  /// НАСТРОЙКИ
  /// ============================================================================

  /// Сохранить настройку
  Future<void> saveSetting(String key, String value) async {
    try {
      final db = await database;
      await db.insert(
        'settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Ошибка сохранения настройки: $e');
    }
  }

  /// Получить настройку
  Future<String?> getSetting(String key) async {
    try {
      final db = await database;
      final result = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: [key],
      );
      if (result.isNotEmpty) {
        return result.first['value'] as String;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Получить все настройки
  Future<Map<String, String>> getAllSettings() async {
    try {
      final db = await database;
      final maps = await db.query('settings');
      return Map.fromEntries(
        maps.map((map) => MapEntry(map['key'] as String, map['value'] as String))
      );
    } catch (e) {
      return {};
    }
  }

  /// ============================================================================
  /// ОЧИСТКА БАЗЫ
  /// ============================================================================
  Future<void> clearAll() async {
    try {
      final db = await database;
      await db.delete('favorites');
      await db.delete('history');
    } catch (e) {
      throw Exception('Ошибка очистки базы: $e');
    }
  }

  /// Закрыть базу данных
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
