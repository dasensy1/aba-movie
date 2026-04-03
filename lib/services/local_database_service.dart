import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

<<<<<<< HEAD
=======
/// ============================================================================
/// LOCAL DATABASE SERVICE (SQFLITE)
/// ============================================================================
/// Сервис для локального хранения данных (избранные фильмы, настройки, обзоры)
/// ============================================================================

>>>>>>> main-fixed
class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  Database? _database;

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
<<<<<<< HEAD
      version: 4,
=======
      version: 2, // Увеличили версию для новой таблицы
>>>>>>> main-fixed
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

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

<<<<<<< HEAD
    await db.execute('''
      CREATE TABLE watch_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        movie_id INTEGER NOT NULL,
        status TEXT NOT NULL,
        watch_date TEXT NOT NULL
=======
    // Таблица обзоров
    await _createReviewsTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createReviewsTable(db);
    }
  }

  Future<void> _createReviewsTable(Database db) async {
    await db.execute('''
      CREATE TABLE reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        movieId INTEGER NOT NULL,
        userId TEXT NOT NULL,
        userName TEXT NOT NULL,
        userPhotoUrl TEXT,
        rating REAL NOT NULL,
        comment TEXT NOT NULL,
        createdAt TEXT NOT NULL
>>>>>>> main-fixed
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE watchlist ADD COLUMN watch_count INTEGER DEFAULT 0');
    }
    if (oldVersion < 3) {
      await db.execute('CREATE TABLE watch_log (id INTEGER PRIMARY KEY AUTOINCREMENT, movie_id INTEGER NOT NULL, watch_date TEXT NOT NULL)');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE watch_log ADD COLUMN status TEXT DEFAULT "watched"');
    }
  }

  // FAVORITES
  Future<bool> addToFavorites(Movie movie) async {
    final db = await database;
    final existing = await db.query('favorites', where: 'id = ?', whereArgs: [movie.id]);
    if (existing.isNotEmpty) return false;
    await db.insert('favorites', {...movie.toMap(), 'addedAt': DateTime.now().toIso8601String()});
    return true;
  }

  Future<bool> removeFromFavorites(int movieId) async {
    final db = await database;
    final deleted = await db.delete('favorites', where: 'id = ?', whereArgs: [movieId]);
    return deleted > 0;
  }

  Future<bool> isFavorite(int movieId) async {
    final db = await database;
    final result = await db.query('favorites', where: 'id = ?', whereArgs: [movieId]);
    return result.isNotEmpty;
  }

  Future<List<Movie>> getFavorites() async {
    final db = await database;
    final maps = await db.query('favorites', orderBy: 'addedAt DESC');
    return maps.map((map) => Movie.fromMap(map)).toList();
  }

  // WATCHLIST & LOGS
  Future<int> addToWatchlist(WatchlistMovie movie) async {
    final db = await database;
    final id = await db.insert('watchlist', movie.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
    await logActivity(movie.movieId, movie.status.name, movie.addedDate);
    return id;
  }

  Future<void> updateWatchlistStatus(int movieId, WatchStatus status, DateTime? watchedDate, {DateTime? addedDate}) async {
    final db = await database;
    final now = addedDate ?? DateTime.now();
    await db.update('watchlist', {
      'status': status.name,
      'added_date': now.toIso8601String(),
      if (watchedDate != null) 'watched_date': watchedDate.toIso8601String(),
    }, where: 'movie_id = ?', whereArgs: [movieId]);
    await logActivity(movieId, status.name, now);
  }

  Future<void> updateWatchlistRating(int movieId, double rating) async {
    final db = await database;
    await db.update('watchlist', {'user_rating': rating}, where: 'movie_id = ?', whereArgs: [movieId]);
  }

  Future<void> updateWatchlistNotes(int movieId, String notes) async {
    final db = await database;
    await db.update('watchlist', {'notes': notes}, where: 'movie_id = ?', whereArgs: [movieId]);
  }

  Future<void> updateWatchlistWatchCount(int movieId, int count) async {
    final db = await database;
    await db.update('watchlist', {'watch_count': count}, where: 'movie_id = ?', whereArgs: [movieId]);
  }

  Future<void> addWatchLogEntry(int movieId, DateTime date) async {
    await logActivity(movieId, "increment_watch", date);
    final db = await database;
    await db.execute('UPDATE watchlist SET watch_count = watch_count + 1 WHERE movie_id = ?', [movieId]);
  }

  Future<void> logActivity(int movieId, String status, DateTime date) async {
    final db = await database;
    await db.insert('watch_log', {'movie_id': movieId, 'status': status, 'watch_date': date.toIso8601String()});
  }

  Future<bool> removeFromWatchlist(int movieId) async {
    final db = await database;
    await db.delete('watch_log', where: 'movie_id = ?', whereArgs: [movieId]);
    final deleted = await db.delete('watchlist', where: 'movie_id = ?', whereArgs: [movieId]);
    return deleted > 0;
  }

  Future<List<WatchlistMovie>> getWatchlist() async {
    final db = await database;
    final maps = await db.query('watchlist', orderBy: 'added_date DESC');
    return maps.map((map) => WatchlistMovie.fromMap(map)).toList();
  }

<<<<<<< HEAD
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('favorites');
    await db.delete('watchlist');
    await db.delete('watch_log');
    await db.delete('history');
=======
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
  /// REVIEWS (ОБЗОРЫ)
  /// ============================================================================

  /// Добавить обзор
  Future<int> addReview(Review review) async {
    try {
      final db = await database;
      return await db.insert('reviews', review.toMap());
    } catch (e) {
      throw Exception('Ошибка добавления обзора: $e');
    }
  }

  /// Получить обзоры фильма
  Future<List<Review>> getMovieReviews(int movieId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'reviews',
        where: 'movieId = ?',
        whereArgs: [movieId],
        orderBy: 'createdAt DESC',
      );
      return maps.map((map) => Review.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Удалить обзор
  Future<bool> deleteReview(int reviewId) async {
    try {
      final db = await database;
      final deleted = await db.delete(
        'reviews',
        where: 'id = ?',
        whereArgs: [reviewId],
      );
      return deleted > 0;
    } catch (e) {
      return false;
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
      await db.delete('reviews');
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
>>>>>>> main-fixed
  }
}
