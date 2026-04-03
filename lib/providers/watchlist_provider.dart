/// ============================================================================
/// WATCHLIST PROVIDER
/// ============================================================================

import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/local_database_service.dart';

class WatchlistProvider with ChangeNotifier {
  final LocalDatabaseService _dbService = LocalDatabaseService();

  List<WatchlistMovie> _watchlist = [];
  List<WatchlistMovie> _wantToWatch = [];
  List<WatchlistMovie> _watching = [];
  List<WatchlistMovie> _watched = [];
  List<WatchlistMovie> _dropped = [];
  List<Map<String, dynamic>> _activityLog = [];

  bool _isLoading = false;
  String? _error;

  List<WatchlistMovie> get watchlist => _watchlist;
  List<WatchlistMovie> get wantToWatch => _wantToWatch;
  List<WatchlistMovie> get watching => _watching;
  List<WatchlistMovie> get watched => _watched;
  List<WatchlistMovie> get dropped => _dropped;
  List<Map<String, dynamic>> get activityLog => _activityLog;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalCount => _watchlist.length;
  int get wantToWatchCount => _wantToWatch.length;
  int get watchingCount => _watching.length;
  int get watchedCount => _watched.length;
  int get droppedCount => _dropped.length;

  Future<void> loadWatchlist() async {
    _isLoading = true;
    notifyListeners();
    try {
      if (!kIsWeb) {
        _watchlist = await _dbService.getWatchlist();
      }
      _categorizeMovies();
      await loadActivityLog();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadActivityLog() async {
    try {
      final db = await _dbService.database;
      final result = await db.rawQuery('''
        SELECT wl.title, wl.poster_path, log.status, log.watch_date
        FROM watch_log log
        JOIN watchlist wl ON log.movie_id = wl.movie_id
        ORDER BY log.watch_date DESC
        LIMIT 20
      ''');
      _activityLog = result;
      notifyListeners();
    } catch (e) {}
  }

  void _categorizeMovies() {
    _wantToWatch = _watchlist.where((m) => m.status == WatchStatus.wantToWatch).toList();
    _watching = _watchlist.where((m) => m.status == WatchStatus.watching).toList();
    _watched = _watchlist.where((m) => m.status == WatchStatus.watched).toList();
    _dropped = _watchlist.where((m) => m.status == WatchStatus.dropped).toList();
  }

  bool isInWatchlist(int movieId) => _watchlist.any((m) => m.movieId == movieId);

  WatchlistMovie? getWatchlistMovie(int movieId) {
    try { return _watchlist.firstWhere((m) => m.movieId == movieId); } catch (e) { return null; }
  }

  /// Добавить фильм в watchlist с опциональной датой просмотра
  Future<bool> addToWatchlist(dynamic movie, {WatchStatus status = WatchStatus.wantToWatch, DateTime? watchedDate}) async {
    try {
      if (isInWatchlist(movie.id)) return false;
      
      // Проверка на будущую дату
      if (watchedDate != null && watchedDate.isAfter(DateTime.now())) {
        _error = 'Нельзя установить будущую дату просмотра';
        return false;
      }

      final watchlistMovie = WatchlistMovie.fromMovie(movie, status: status).copyWith(
        watchedDate: watchedDate,
        watchCount: status == WatchStatus.watched ? 1 : 0,
      );

      if (!kIsWeb) {
        await _dbService.addToWatchlist(watchlistMovie);
      }

      _watchlist.insert(0, watchlistMovie);
      _categorizeMovies();
      await loadActivityLog();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      // Для Веба все равно добавляем в память
      final watchlistMovie = WatchlistMovie.fromMovie(movie, status: status).copyWith(
        watchedDate: watchedDate,
        watchCount: status == WatchStatus.watched ? 1 : 0,
      );
      _watchlist.insert(0, watchlistMovie);
      _categorizeMovies();
      notifyListeners();
      return true;
    }
  }

  /// Обновить статус фильма с опциональной датой просмотра
  Future<bool> updateStatus(int movieId, WatchStatus status, {DateTime? watchedDate}) async {
    try {
      final index = _watchlist.indexWhere((m) => m.movieId == movieId);
      if (index == -1) return false;
      
      final movie = _watchlist[index];
      DateTime? finalWatchedDate = watchedDate ?? movie.watchedDate;

      // Проверка на будущую дату
      if (finalWatchedDate != null && finalWatchedDate.isAfter(DateTime.now())) {
        _error = 'Нельзя установить будущую дату просмотра';
        return false;
      }

      // Если статус "просмотрено" и даты нет, ставим текущую
      if (status == WatchStatus.watched && finalWatchedDate == null) {
        finalWatchedDate = DateTime.now();
      }

      final now = DateTime.now();
      
      if (!kIsWeb) {
        await _dbService.updateWatchlistStatus(movieId, status, finalWatchedDate, addedDate: now);
      }

      _watchlist[index] = movie.copyWith(
        status: status,
        addedDate: now,
        watchedDate: finalWatchedDate,
        watchCount: status == WatchStatus.watched ? (movie.watchCount > 0 ? movie.watchCount : 1) : movie.watchCount,
      );
      
      _categorizeMovies();
      await loadActivityLog();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Update status error: $e');
      return false;
    }
  }

  Future<bool> updateRating(int movieId, double rating) async {
    try {
      final index = _watchlist.indexWhere((m) => m.movieId == movieId);
      if (index == -1) return false;

      final movie = _watchlist[index];

      final updatedMovie = WatchlistMovie(
        id: movie.id,
        movieId: movie.movieId,
        imdbId: movie.imdbId,
        title: movie.title,
        posterPath: movie.posterPath,
        status: movie.status,
        userRating: rating,
        notes: movie.notes,
        watchedDate: movie.watchedDate,
        addedDate: movie.addedDate,
      );

      if (!kIsWeb) {
        await _dbService.updateWatchlistRating(movieId, rating);
      }

      _watchlist[index] = updatedMovie;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateNotes(int movieId, String notes) async {
    try {
      final index = _watchlist.indexWhere((m) => m.movieId == movieId);
      if (index == -1) return false;

      final movie = _watchlist[index];

      final updatedMovie = WatchlistMovie(
        id: movie.id,
        movieId: movie.movieId,
        imdbId: movie.imdbId,
        title: movie.title,
        posterPath: movie.posterPath,
        status: movie.status,
        userRating: movie.userRating,
        notes: notes,
        watchedDate: movie.watchedDate,
        addedDate: movie.addedDate,
      );

      if (!kIsWeb) {
        await _dbService.updateWatchlistNotes(movieId, notes);
      }

      _watchlist[index] = updatedMovie;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> incrementWatchCount(int movieId, {DateTime? watchedDate}) async {
    try {
      final index = _watchlist.indexWhere((m) => m.movieId == movieId);
      if (index == -1) return false;
      
      final movie = _watchlist[index];
      final now = watchedDate ?? DateTime.now();

      // Проверка на будущую дату
      if (watchedDate != null && watchedDate.isAfter(DateTime.now())) {
        _error = 'Нельзя установить будущую дату просмотра';
        return false;
      }

      if (!kIsWeb) {
        await _dbService.addWatchLogEntry(movieId, now);
      }
      
      _watchlist[index] = movie.copyWith(
        watchCount: movie.watchCount + 1,
        status: WatchStatus.watched,
        watchedDate: now,
        addedDate: now,
      );
      
      _categorizeMovies();
      await loadActivityLog();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeFromWatchlist(int movieId) async {
    try {
      if (!kIsWeb) {
        await _dbService.removeFromWatchlist(movieId);
      }
      _watchlist.removeWhere((m) => m.movieId == movieId);
      _categorizeMovies();
      await loadActivityLog();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Map<String, dynamic> getStatistics() {
    int totalWatches = 0;
    for (var m in _watchlist) totalWatches += m.watchCount;
    final watchedMovies = _watched;
    final totalRatings = watchedMovies.where((m) => m.userRating != null).length;
    final averageRating = totalRatings > 0
        ? watchedMovies
            .where((m) => m.userRating != null)
            .map((m) => m.userRating!)
            .reduce((a, b) => a + b) / totalRatings
        : 0.0;

    final byMonth = <String, int>{};
    for (final movie in watchedMovies) {
      if (movie.watchedDate != null) {
        final key = '${movie.watchedDate!.year}-${movie.watchedDate!.month.toString().padLeft(2, '0')}';
        byMonth[key] = (byMonth[key] ?? 0) + 1;
      }
    }

    return {
      'total': totalCount,
      'totalWatches': totalWatches,
      'wantToWatch': wantToWatchCount,
      'watching': watchingCount,
      'watched': watchedCount,
      'dropped': droppedCount,
      'averageRating': averageRating,
    };
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
