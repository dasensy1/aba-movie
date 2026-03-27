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
      version: 2, // Увеличиваем версию для миграции
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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

    // Таблица треккинга фильмов (watchlist)
    await db.execute('''
      CREATE TABLE watchlist (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        movie_id INTEGER NOT NULL,
        imdb_id TEXT,
        title TEXT NOT NULL,
        poster_path TEXT,
        status TEXT NOT NULL,
        user_rating REAL,
        notes TEXT,
        watched_date TEXT,
        added_date TEXT NOT NULL,
        watch_count INTEGER DEFAULT 0,
        UNIQUE(movie_id)
      )
    ''');
  }

  /// Миграция базы данных
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Добавляем колонку watch_count, если её нет
      await db.execute('ALTER TABLE watchlist ADD COLUMN watch_count INTEGER DEFAULT 0');
    }
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
  /// WATCHLIST (ТРЕККИНГ ФИЛЬМОВ)
  /// ============================================================================

  /// Добавить фильм в watchlist
  Future<int> addToWatchlist(WatchlistMovie movie) async {
    try {
      final db = await database;
      return await db.insert(
        'watchlist',
        movie.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (e) {
      throw Exception('Ошибка добавления в треккинг: $e');
    }
  }

  /// Обновить статус фильма в watchlist
  Future<void> updateWatchlistStatus(int movieId, WatchStatus status, DateTime? watchedDate, {DateTime? addedDate}) async {
    try {
      final db = await database;
      final updates = <String, dynamic>{
        'status': status.name,
      };
      
      if (watchedDate != null) {
        updates['watched_date'] = watchedDate.toIso8601String();
      }
      
      if (addedDate != null) {
        updates['added_date'] = addedDate.toIso8601String();
      }

      await db.update(
        'watchlist',
        updates,
        where: 'movie_id = ?',
        whereArgs: [movieId],
      );
    } catch (e) {
      throw Exception('Ошибка обновления статуса: $e');
    }
  }

  /// Обновить количество просмотров
  Future<void> updateWatchlistWatchCount(int movieId, int count) async {
    try {
      final db = await database;
      await db.update(
        'watchlist',
        {'watch_count': count},
        where: 'movie_id = ?',
        whereArgs: [movieId],
      );
    } catch (e) {
      throw Exception('Ошибка обновления счетчика просмотров: $e');
    }
  }

  /// Обновить оценку фильма в watchlist
  Future<void> updateWatchlistRating(int movieId, double rating) async {
    try {
      final db = await database;
      await db.update(
        'watchlist',
        {'user_rating': rating},
        where: 'movie_id = ?',
        whereArgs: [movieId],
      );
    } catch (e) {
      throw Exception('Ошибка обновления оценки: $e');
    }
  }

  /// Обновить заметки фильма в watchlist
  Future<void> updateWatchlistNotes(int movieId, String notes) async {
    try {
      final db = await database;
      await db.update(
        'watchlist',
        {'notes': notes},
        where: 'movie_id = ?',
        whereArgs: [movieId],
      );
    } catch (e) {
      throw Exception('Ошибка обновления заметок: $e');
    }
  }

  /// Удалить фильм из watchlist
  Future<bool> removeFromWatchlist(int movieId) async {
    try {
      final db = await database;
      final deleted = await db.delete(
        'watchlist',
        where: 'movie_id = ?',
        whereArgs: [movieId],
      );
      return deleted > 0;
    } catch (e) {
      throw Exception('Ошибка удаления из треккинга: $e');
    }
  }

  /// Проверить, есть ли фильм в watchlist
  Future<bool> isInWatchlist(int movieId) async {
    try {
      final db = await database;
      final result = await db.query(
        'watchlist',
        where: 'movie_id = ?',
        whereArgs: [movieId],
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Получить весь watchlist
  Future<List<WatchlistMovie>> getWatchlist() async {
    try {
      final db = await database;
      final maps = await db.query('watchlist', orderBy: 'added_date DESC');
      return maps.map((map) => WatchlistMovie.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Получить фильмы по статусу
  Future<List<WatchlistMovie>> getWatchlistByStatus(WatchStatus status) async {
    try {
      final db = await database;
      final maps = await db.query(
        'watchlist',
        where: 'status = ?',
        whereArgs: [status.name],
        orderBy: 'added_date DESC',
      );
      return maps.map((map) => WatchlistMovie.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Получить количество фильмов по статусу
  Future<int> getWatchlistCountByStatus(WatchStatus status) async {
    try {
      final db = await database;
      return Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM watchlist WHERE status = ?',
          [status.name],
        ),
      ) ?? 0;
    } catch (e) {
      return 0;
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
