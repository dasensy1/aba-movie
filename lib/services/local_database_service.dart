import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

/// ============================================================================
/// LOCAL DATABASE SERVICE (SQFLITE) — Версия 6
/// ============================================================================
/// Переработанная схема БД:
/// - users: таблица локальных пользователей с password_hash
/// - user_settings: настройки привязанные к пользователю
/// - favorites: избранное с user_id
/// - watchlist: список просмотра с user_id
/// - watch_log: лог просмотров с user_id
/// - reviews: обзоры с user_id
/// - settings: общие (не user-scoped) настройки приложения
/// - history: история просмотров (legacy)
///
/// Все user-scoped таблицы имеют:
/// - FOREIGN KEY на users(id)
/// - INDEX по user_id
/// - UNIQUE(user_id, movie_id) где уместно
/// ============================================================================

class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      _database = await _initDatabase().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Database initialization timed out');
          throw TimeoutException('Database initialization timed out');
        },
      );
      return _database!;
    } catch (e) {
      debugPrint('Database error: $e');
      rethrow;
    }
  }

  Future<Database> _initDatabase() async {
    String path;
    
    if (kIsWeb) {
      // Для веба используем специальное имя с версией
      path = 'movie_tracker_v2.db';
      debugPrint('Инициализация БД для WEB, путь: $path');
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, 'movie_tracker_v2.db');
      debugPrint('Инициализация БД для DESKTOP, путь: $path');
    }

    debugPrint('Открываю базу данных...');
    
    return await openDatabase(
      path,
      version: 6, // Новая схема с user-scoped данными
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        debugPrint('База данных успешно открыта!');
        // Проверим что таблицы существуют
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table'",
        );
        debugPrint('Доступные таблицы: ${tables.map((t) => t['name']).join(', ')}');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Включаем поддержку FOREIGN KEY
    await db.execute('PRAGMA foreign_keys = ON');

    // ==================== USERS ====================
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        display_name TEXT,
        photo_url TEXT,
        created_at TEXT NOT NULL,
        is_anonymous INTEGER DEFAULT 0
      )
    ''');

    // ==================== USER SETTINGS ====================
    await db.execute('''
      CREATE TABLE user_settings (
        user_id INTEGER PRIMARY KEY,
        dark_theme INTEGER DEFAULT 1,
        language TEXT DEFAULT 'ru',
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // ==================== FAVORITES ====================
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        movie_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        overview TEXT,
        poster_path TEXT,
        backdrop_path TEXT,
        vote_average REAL,
        vote_count INTEGER,
        release_date TEXT,
        genre_ids TEXT,
        popularity REAL,
        added_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        UNIQUE(user_id, movie_id)
      )
    ''');

    await db.execute('CREATE INDEX idx_favorites_user ON favorites(user_id)');
    await db.execute('CREATE INDEX idx_favorites_movie ON favorites(movie_id)');

    // ==================== WATCHLIST ====================
    await db.execute('''
      CREATE TABLE watchlist (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
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
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        UNIQUE(user_id, movie_id)
      )
    ''');

    await db.execute('CREATE INDEX idx_watchlist_user ON watchlist(user_id)');
    await db.execute('CREATE INDEX idx_watchlist_movie ON watchlist(movie_id)');
    await db.execute('CREATE INDEX idx_watchlist_status ON watchlist(status)');

    // ==================== WATCH LOG ====================
    await db.execute('''
      CREATE TABLE watch_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        movie_id INTEGER NOT NULL,
        status TEXT NOT NULL,
        watch_date TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_watch_log_user ON watch_log(user_id)');
    await db.execute('CREATE INDEX idx_watch_log_date ON watch_log(watch_date DESC)');

    // ==================== REVIEWS ====================
    await db.execute('''
      CREATE TABLE reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        movie_id INTEGER NOT NULL,
        user_name TEXT NOT NULL,
        rating REAL NOT NULL,
        comment TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_reviews_user ON reviews(user_id)');
    await db.execute('CREATE INDEX idx_reviews_movie ON reviews(movie_id)');

    // ==================== SETTINGS (общие) ====================
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // ==================== HISTORY (legacy) ====================
    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        overview TEXT,
        poster_path TEXT,
        backdrop_path TEXT,
        vote_average REAL,
        vote_count INTEGER,
        release_date TEXT,
        genre_ids TEXT,
        popularity REAL,
        viewed_at TEXT NOT NULL
      )
    ''');
  }

  // ==================== MIGRATIONS ====================
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Миграция с v5 на v6 — полная перестройка схемы
    if (oldVersion < 6) {
      await _migrateToV6(db);
    }
  }

  /// Миграция с v5 на v6
  /// Стратегия: создаём новые таблицы, копируем данные, удаляем старые
  Future<void> _migrateToV6(Database db) async {
    await db.execute('PRAGMA foreign_keys = OFF');

    // 1. Создаём users
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        display_name TEXT,
        photo_url TEXT,
        created_at TEXT NOT NULL,
        is_anonymous INTEGER DEFAULT 0
      )
    ''');

    // 2. Создаём user_settings
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_settings (
        user_id INTEGER PRIMARY KEY,
        dark_theme INTEGER DEFAULT 1,
        language TEXT DEFAULT 'ru',
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // 3. Создаём новые favorites с user_id
    await db.execute('''
      CREATE TABLE IF NOT EXISTS favorites_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL DEFAULT 1,
        movie_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        overview TEXT,
        poster_path TEXT,
        backdrop_path TEXT,
        vote_average REAL,
        vote_count INTEGER,
        release_date TEXT,
        genre_ids TEXT,
        popularity REAL,
        added_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        UNIQUE(user_id, movie_id)
      )
    ''');

    // 4. Создаём новый watchlist с user_id
    await db.execute('''
      CREATE TABLE IF NOT EXISTS watchlist_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL DEFAULT 1,
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
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        UNIQUE(user_id, movie_id)
      )
    ''');

    // 5. Создаём новый watch_log с user_id
    await db.execute('''
      CREATE TABLE IF NOT EXISTS watch_log_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL DEFAULT 1,
        movie_id INTEGER NOT NULL,
        status TEXT NOT NULL,
        watch_date TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // 6. Создаём новый reviews с user_id как INTEGER
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reviews_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL DEFAULT 1,
        movie_id INTEGER NOT NULL,
        user_name TEXT NOT NULL,
        rating REAL NOT NULL,
        comment TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Копируем данные из старых таблиц в новые (с user_id = 1 по умолчанию)
    // Для favorites
    try {
      final oldFavorites = await db.query('favorites');
      for (final fav in oldFavorites) {
        final newFav = Map<String, dynamic>.from(fav);
        newFav['user_id'] = 1;
        // Переименовываем колонки если нужно
        if (newFav.containsKey('posterPath')) {
          newFav['poster_path'] = newFav.remove('posterPath');
        }
        if (newFav.containsKey('backdropPath')) {
          newFav['backdrop_path'] = newFav.remove('backdropPath');
        }
        if (newFav.containsKey('voteAverage')) {
          newFav['vote_average'] = newFav.remove('voteAverage');
        }
        if (newFav.containsKey('voteCount')) {
          newFav['vote_count'] = newFav.remove('voteCount');
        }
        if (newFav.containsKey('releaseDate')) {
          newFav['release_date'] = newFav.remove('releaseDate');
        }
        if (newFav.containsKey('genreIds')) {
          newFav['genre_ids'] = newFav.remove('genreIds');
        }
        newFav.remove('id'); // AUTOINCREMENT
        await db.insert('favorites_new', newFav, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    } catch (e) {
      // Старая таблица могла уже не существовать
      debugPrint('Migration v6: error copying favorites: $e');
    }

    // Для watchlist
    try {
      final oldWatchlist = await db.query('watchlist');
      for (final wl in oldWatchlist) {
        final newWl = Map<String, dynamic>.from(wl);
        newWl['user_id'] = 1;
        newWl.remove('id');
        await db.insert('watchlist_new', newWl, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    } catch (e) {
      debugPrint('Migration v6: error copying watchlist: $e');
    }

    // Для watch_log
    try {
      final oldLog = await db.query('watch_log');
      for (final log in oldLog) {
        final newLog = Map<String, dynamic>.from(log);
        newLog['user_id'] = 1;
        newLog.remove('id');
        await db.insert('watch_log_new', newLog, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    } catch (e) {
      debugPrint('Migration v6: error copying watch_log: $e');
    }

    // Для reviews
    try {
      final oldReviews = await db.query('reviews');
      for (final review in oldReviews) {
        final newReview = Map<String, dynamic>.from(review);
        newReview['user_id'] = 1;
        newReview.remove('id');
        await db.insert('reviews_new', newReview, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    } catch (e) {
      debugPrint('Migration v6: error copying reviews: $e');
    }

    // Удаляем старые таблицы
    await db.execute('DROP TABLE IF EXISTS favorites');
    await db.execute('DROP TABLE IF EXISTS watchlist');
    await db.execute('DROP TABLE IF EXISTS watch_log');
    await db.execute('DROP TABLE IF EXISTS reviews');

    // Переименовываем новые
    await db.execute('ALTER TABLE favorites_new RENAME TO favorites');
    await db.execute('ALTER TABLE watchlist_new RENAME TO watchlist');
    await db.execute('ALTER TABLE watch_log_new RENAME TO watch_log');
    await db.execute('ALTER TABLE reviews_new RENAME TO reviews');

    // Создаём индексы
    await db.execute('CREATE INDEX IF NOT EXISTS idx_favorites_user ON favorites(user_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_favorites_movie ON favorites(movie_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_watchlist_user ON watchlist(user_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_watchlist_movie ON watchlist(movie_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_watchlist_status ON watchlist(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_watch_log_user ON watch_log(user_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_watch_log_date ON watch_log(watch_date DESC)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_reviews_user ON reviews(user_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_reviews_movie ON reviews(movie_id)');

    // Переносим настройки из settings в user_settings для дефолтного пользователя
    try {
      final settings = await db.query('settings');
      int darkTheme = 1;
      String language = 'ru';
      for (final s in settings) {
        if (s['key'] == 'dark_theme') {
          darkTheme = int.tryParse(s['value'].toString()) ?? 1;
        }
        if (s['key'] == 'language') {
          language = s['value'].toString();
        }
      }
      await db.insert('user_settings', {
        'user_id': 1,
        'dark_theme': darkTheme,
        'language': language,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    } catch (e) {
      debugPrint('Migration v6: error copying settings to user_settings: $e');
    }

    await db.execute('PRAGMA foreign_keys = ON');
  }

  // ==================== USERS ====================

  /// Создать нового пользователя
  Future<int> createUser(LocalUser user) async {
    final db = await database;
    return await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);
  }

  /// Найти пользователя по email
  Future<LocalUser?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (result.isEmpty) return null;
    return LocalUser.fromMap(result.first);
  }

  /// Найти пользователя по ID
  Future<LocalUser?> getUserById(int id) async {
    final db = await database;
    final result = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return LocalUser.fromMap(result.first);
  }

  /// Получить всех пользователей
  Future<List<LocalUser>> getAllUsers() async {
    final db = await database;
    final maps = await db.query('users', orderBy: 'created_at DESC');
    return maps.map((map) => LocalUser.fromMap(map)).toList();
  }

  /// Удалить пользователя (и все связанные данные — CASCADE)
  Future<bool> deleteUser(int userId) async {
    final db = await database;
    final deleted = await db.delete('users', where: 'id = ?', whereArgs: [userId]);
    return deleted > 0;
  }

  // ==================== USER SETTINGS ====================

  /// Получить настройки пользователя
  Future<Map<String, dynamic>?> getUserSettings(int userId) async {
    final db = await database;
    final result = await db.query('user_settings', where: 'user_id = ?', whereArgs: [userId]);
    if (result.isEmpty) return null;
    return result.first;
  }

  /// Создать/обновить настройки пользователя
  Future<void> updateUserSettings(int userId, {bool? darkTheme, String? language}) async {
    final db = await database;
    final existing = await getUserSettings(userId);

    if (existing == null) {
      await db.insert('user_settings', {
        'user_id': userId,
        'dark_theme': darkTheme != null ? (darkTheme ? 1 : 0) : 1,
        'language': language ?? 'ru',
      });
    } else {
      final updates = <String, dynamic>{};
      if (darkTheme != null) updates['dark_theme'] = darkTheme ? 1 : 0;
      if (language != null) updates['language'] = language;
      if (updates.isNotEmpty) {
        await db.update('user_settings', updates, where: 'user_id = ?', whereArgs: [userId]);
      }
    }
  }

  // ==================== FAVORITES ====================

  /// Добавить в избранное (user-scoped)
  Future<bool> addToFavorites(Movie movie, int userId) async {
    final db = await database;
    final existing = await db.query(
      'favorites',
      where: 'user_id = ? AND movie_id = ?',
      whereArgs: [userId, movie.id],
    );
    if (existing.isNotEmpty) return false;

    final data = {
      'user_id': userId,
      'movie_id': movie.id,
      'title': movie.title,
      'overview': movie.overview,
      'poster_path': movie.posterPath,
      'backdrop_path': movie.backdropPath,
      'vote_average': movie.voteAverage,
      'vote_count': movie.voteCount,
      'release_date': movie.releaseDate,
      'genre_ids': movie.genreIds.join(','),
      'popularity': movie.popularity,
      'added_at': DateTime.now().toIso8601String(),
    };
    await db.insert('favorites', data, conflictAlgorithm: ConflictAlgorithm.ignore);
    return true;
  }

  /// Удалить из избранного (user-scoped)
  Future<bool> removeFromFavorites(int movieId, int userId) async {
    final db = await database;
    final deleted = await db.delete(
      'favorites',
      where: 'user_id = ? AND movie_id = ?',
      whereArgs: [userId, movieId],
    );
    return deleted > 0;
  }

  /// Проверить, есть ли в избранном (user-scoped)
  Future<bool> isFavorite(int movieId, int userId) async {
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'user_id = ? AND movie_id = ?',
      whereArgs: [userId, movieId],
    );
    return result.isNotEmpty;
  }

  /// Получить избранное пользователя
  Future<List<Movie>> getFavorites(int userId) async {
    final db = await database;
    final maps = await db.query(
      'favorites',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'added_at DESC',
    );
    return maps.map((map) => _movieFromFavoriteMap(map)).toList();
  }

  /// Получить count избранного пользователя
  Future<int> getFavoritesCount(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM favorites WHERE user_id = ?',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Удалить всё избранное пользователя
  Future<void> clearFavorites(int userId) async {
    final db = await database;
    await db.delete('favorites', where: 'user_id = ?', whereArgs: [userId]);
  }

  // Преобразование Map из favorites в Movie
  Movie _movieFromFavoriteMap(Map<String, dynamic> map) {
    return Movie(
      id: map['movie_id'] ?? map['id'] ?? 0,
      title: map['title'] ?? 'Без названия',
      overview: map['overview'],
      posterPath: map['poster_path'],
      backdropPath: map['backdrop_path'],
      voteAverage: (map['vote_average'] ?? 0).toDouble(),
      voteCount: map['vote_count'] ?? 0,
      releaseDate: map['release_date'],
      genreIds: map['genre_ids'] != null && map['genre_ids'].toString().isNotEmpty
          ? (map['genre_ids'] as String).split(',').map(int.parse).toList()
          : [],
      popularity: (map['popularity'] ?? 0).toDouble(),
    );
  }

  // ==================== WATCHLIST ====================

  /// Добавить фильм в watchlist (user-scoped)
  Future<int> addToWatchlist(WatchlistMovie movie, int userId) async {
    final db = await database;
    final data = movie.toMap();
    data['user_id'] = userId;
    final id = await db.insert('watchlist', data, conflictAlgorithm: ConflictAlgorithm.ignore);

    if (id > 0) {
      await logActivity(movie.movieId, movie.status.name, movie.addedDate, userId);
    }
    return id;
  }

  /// Обновить статус в watchlist (user-scoped)
  Future<void> updateWatchlistStatus(
    int movieId,
    WatchStatus status,
    int userId, {
    DateTime? watchedDate,
    DateTime? addedDate,
  }) async {
    final db = await database;
    final now = addedDate ?? DateTime.now();
    await db.update(
      'watchlist',
      {
        'status': status.name,
        'added_date': now.toIso8601String(),
        if (watchedDate != null) 'watched_date': watchedDate.toIso8601String(),
      },
      where: 'user_id = ? AND movie_id = ?',
      whereArgs: [userId, movieId],
    );
    await logActivity(movieId, status.name, now, userId);
  }

  /// Обновить рейтинг (user-scoped)
  Future<void> updateWatchlistRating(int movieId, double rating, int userId) async {
    final db = await database;
    await db.update(
      'watchlist',
      {'user_rating': rating},
      where: 'user_id = ? AND movie_id = ?',
      whereArgs: [userId, movieId],
    );
  }

  /// Обновить заметки (user-scoped)
  Future<void> updateWatchlistNotes(int movieId, String notes, int userId) async {
    final db = await database;
    await db.update(
      'watchlist',
      {'notes': notes},
      where: 'user_id = ? AND movie_id = ?',
      whereArgs: [userId, movieId],
    );
  }

  /// Обновить счётчик просмотров (user-scoped)
  Future<void> updateWatchlistWatchCount(int movieId, int count, int userId) async {
    final db = await database;
    await db.update(
      'watchlist',
      {'watch_count': count},
      where: 'user_id = ? AND movie_id = ?',
      whereArgs: [userId, movieId],
    );
  }

  /// Добавить запись в лог просмотров (user-scoped)
  Future<void> addWatchLogEntry(int movieId, DateTime date, int userId) async {
    await logActivity(movieId, 'increment_watch', date, userId);
    final db = await database;
    await db.execute(
      'UPDATE watchlist SET watch_count = watch_count + 1 WHERE user_id = ? AND movie_id = ?',
      [userId, movieId],
    );
  }

  /// Записать активность (user-scoped)
  Future<void> logActivity(int movieId, String status, DateTime date, int userId) async {
    final db = await database;
    await db.insert('watch_log', {
      'user_id': userId,
      'movie_id': movieId,
      'status': status,
      'watch_date': date.toIso8601String(),
    });
  }

  /// Удалить из watchlist (user-scoped)
  Future<bool> removeFromWatchlist(int movieId, int userId) async {
    final db = await database;
    await db.delete(
      'watch_log',
      where: 'user_id = ? AND movie_id = ?',
      whereArgs: [userId, movieId],
    );
    final deleted = await db.delete(
      'watchlist',
      where: 'user_id = ? AND movie_id = ?',
      whereArgs: [userId, movieId],
    );
    return deleted > 0;
  }

  /// Получить watchlist пользователя
  Future<List<WatchlistMovie>> getWatchlist(int userId) async {
    final db = await database;
    final maps = await db.query(
      'watchlist',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'added_date DESC',
    );
    return maps.map((map) => WatchlistMovie.fromMap(map)).toList();
  }

  /// Получить watchlist по статусу (user-scoped)
  Future<List<WatchlistMovie>> getWatchlistByStatus(int userId, WatchStatus status) async {
    final db = await database;
    final maps = await db.query(
      'watchlist',
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, status.name],
      orderBy: 'added_date DESC',
    );
    return maps.map((map) => WatchlistMovie.fromMap(map)).toList();
  }

  /// Получить count по статусу (user-scoped)
  Future<int> getWatchlistCountByStatus(int userId, WatchStatus status) async {
    final db = await database;
    return Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM watchlist WHERE user_id = ? AND status = ?',
        [userId, status.name],
      ),
    ) ?? 0;
  }

  /// Получить лог активности пользователя
  Future<List<Map<String, dynamic>>> getActivityLog(int userId, {int limit = 20}) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT wl.movie_id, wl.title, wl.poster_path, log.status, log.watch_date
      FROM watch_log log
      JOIN watchlist wl ON log.user_id = wl.user_id AND log.movie_id = wl.movie_id
      WHERE log.user_id = ?
      ORDER BY log.watch_date DESC
      LIMIT ?
      ''',
      [userId, limit],
    );
  }

  /// Удалить весь watchlist пользователя
  Future<void> clearWatchlist(int userId) async {
    final db = await database;
    await db.delete('watch_log', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('watchlist', where: 'user_id = ?', whereArgs: [userId]);
  }

  // ==================== REVIEWS ====================

  /// Добавить обзор (user-scoped)
  Future<int> addReview(Review review, int userId) async {
    final db = await database;
    final data = review.toMap();
    data['user_id'] = userId;
    data.remove('userPhotoUrl'); // удаляем старое поле
    return await db.insert('reviews', data);
  }

  /// Получить обзоры фильма (все пользователи)
  Future<List<Review>> getMovieReviews(int movieId) async {
    final db = await database;
    final maps = await db.query(
      'reviews',
      where: 'movie_id = ?',
      whereArgs: [movieId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => _reviewFromMap(map)).toList();
  }

  /// Получить обзоры пользователя
  Future<List<Review>> getUserReviews(int userId) async {
    final db = await database;
    final maps = await db.query(
      'reviews',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => _reviewFromMap(map)).toList();
  }

  /// Удалить обзор (user-scoped)
  Future<bool> deleteReview(int reviewId, int userId) async {
    final db = await database;
    final deleted = await db.delete(
      'reviews',
      where: 'id = ? AND user_id = ?',
      whereArgs: [reviewId, userId],
    );
    return deleted > 0;
  }

  Review _reviewFromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'] ?? 0,
      movieId: map['movie_id'] ?? map['movieId'] ?? 0,
      userId: map['user_id'] ?? 0,
      userName: map['user_name'] ?? 'Аноним',
      userPhotoUrl: '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  // ==================== SETTINGS (общие) ====================

  /// Получить общую настройку
  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (result.isEmpty) return null;
    return result.first['value']?.toString();
  }

  /// Установить общую настройку
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==================== CLEAR / MAINTENANCE ====================

  /// Удалить ВСЕ данные пользователя (CASCADE удалит связанные)
  Future<void> clearUserData(int userId) async {
    final db = await database;
    await db.delete('favorites', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('watchlist', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('watch_log', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('reviews', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('user_settings', where: 'user_id = ?', whereArgs: [userId]);
  }

  /// Удалить ВСЕ данные (полный сброс)
  Future<void> clearAll() async {
    try {
      final db = await database;
      await db.delete('favorites');
      await db.delete('watchlist');
      await db.delete('watch_log');
      await db.delete('history');
      await db.delete('reviews');
      await db.delete('user_settings');
      await db.delete('users');
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
