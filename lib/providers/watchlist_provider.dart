// ============================================================================
// WATCHLIST PROVIDER — Версия 2 (user-scoped)
// ============================================================================
// Трекинг фильмов со статусами, оценками, заметками, датами просмотра.
// Данные привязаны к текущему пользователю через AuthProvider.userId.
// ============================================================================

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

  int? _lastLoadedUserId;
  bool _isFirstLoad = true;

  /// Загрузить watchlist текущего пользователя
  Future<void> loadWatchlist(int? userId) async {
    if (userId == _lastLoadedUserId && !_isFirstLoad) return;
    _lastLoadedUserId = userId;
    _isFirstLoad = false;

    if (userId == null) {
      _watchlist = [];
      _wantToWatch = [];
      _watching = [];
      _watched = [];
      _dropped = [];
      _activityLog = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _watchlist = await _dbService.getWatchlist(userId);
      _categorizeMovies();
      await loadActivityLog(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Загрузить лог активности пользователя
  Future<void> loadActivityLog(int? userId) async {
    if (userId == null) {
      _activityLog = [];
      notifyListeners();
      return;
    }

    try {
      _activityLog = await _dbService.getActivityLog(userId, limit: 20);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading activity log: $e');
      _activityLog = [];
    }
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
  Future<bool> addToWatchlist(dynamic movie, int? userId, {WatchStatus status = WatchStatus.wantToWatch, DateTime? watchedDate}) async {
    if (userId == null) return false;

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

      await _dbService.addToWatchlist(watchlistMovie, userId);

      _watchlist.insert(0, watchlistMovie);
      _categorizeMovies();
      await loadActivityLog(userId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Обновить статус фильма с опциональной датой просмотра
  Future<bool> updateStatus(int movieId, WatchStatus status, int? userId, {DateTime? watchedDate}) async {
    if (userId == null) return false;

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

      await _dbService.updateWatchlistStatus(movieId, status, userId, watchedDate: finalWatchedDate, addedDate: now);

      _watchlist[index] = movie.copyWith(
        status: status,
        addedDate: now,
        watchedDate: finalWatchedDate,
        watchCount: status == WatchStatus.watched ? (movie.watchCount > 0 ? movie.watchCount : 1) : movie.watchCount,
      );

      _categorizeMovies();
      await loadActivityLog(userId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Update status error: $e');
      return false;
    }
  }

  Future<bool> updateRating(int movieId, double rating, int? userId) async {
    if (userId == null) return false;

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

      await _dbService.updateWatchlistRating(movieId, rating, userId);

      _watchlist[index] = updatedMovie;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateNotes(int movieId, String notes, int? userId) async {
    if (userId == null) return false;

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

      await _dbService.updateWatchlistNotes(movieId, notes, userId);

      _watchlist[index] = updatedMovie;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> incrementWatchCount(int movieId, int? userId, {DateTime? watchedDate}) async {
    if (userId == null) return false;

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

      await _dbService.addWatchLogEntry(movieId, now, userId);

      _watchlist[index] = movie.copyWith(
        watchCount: movie.watchCount + 1,
        status: WatchStatus.watched,
        watchedDate: now,
        addedDate: now,
      );

      _categorizeMovies();
      await loadActivityLog(userId);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeFromWatchlist(int movieId, int? userId) async {
    if (userId == null) return false;

    try {
      await _dbService.removeFromWatchlist(movieId, userId);
      _watchlist.removeWhere((m) => m.movieId == movieId);
      _categorizeMovies();
      await loadActivityLog(userId);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Удалить весь watchlist пользователя
  Future<void> clearWatchlist(int? userId) async {
    if (userId == null) return;

    try {
      await _dbService.clearWatchlist(userId);
      _watchlist = [];
      _wantToWatch = [];
      _watching = [];
      _watched = [];
      _dropped = [];
      _activityLog = [];
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Map<String, dynamic> getStatistics() {
    int totalWatches = 0;
    for (var m in _watchlist) {
      totalWatches += m.watchCount;
    }
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
