/// ============================================================================
/// WATCHLIST PROVIDER
/// ============================================================================
/// Провайдер для управления треккингом фильмов
/// Статусы: хочу посмотреть, смотрю, просмотрено, бросил
/// Оценка, заметки, дата просмотра
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
  
  bool _isLoading = false;
  String? _error;

  // Getters
  List<WatchlistMovie> get watchlist => _watchlist;
  List<WatchlistMovie> get wantToWatch => _wantToWatch;
  List<WatchlistMovie> get watching => _watching;
  List<WatchlistMovie> get watched => _watched;
  List<WatchlistMovie> get dropped => _dropped;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  int get totalCount => _watchlist.length;
  int get wantToWatchCount => _wantToWatch.length;
  int get watchingCount => _watching.length;
  int get watchedCount => _watched.length;
  int get droppedCount => _dropped.length;

  /// Загрузить весь watchlist
  Future<void> loadWatchlist() async {
    _isLoading = true;
    notifyListeners();

    try {
      _watchlist = await _dbService.getWatchlist();
      _categorizeMovies();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Категоризировать фильмы по статусам
  void _categorizeMovies() {
    _wantToWatch = _watchlist.where((m) => m.status == WatchStatus.wantToWatch).toList();
    _watching = _watchlist.where((m) => m.status == WatchStatus.watching).toList();
    _watched = _watchlist.where((m) => m.status == WatchStatus.watched).toList();
    _dropped = _watchlist.where((m) => m.status == WatchStatus.dropped).toList();
  }

  /// Проверить, есть ли фильм в watchlist
  bool isInWatchlist(int movieId) {
    return _watchlist.any((m) => m.movieId == movieId);
  }

  /// Получить фильм из watchlist по ID
  WatchlistMovie? getWatchlistMovie(int movieId) {
    try {
      return _watchlist.firstWhere((m) => m.movieId == movieId);
    } catch (e) {
      return null;
    }
  }

  /// Добавить фильм в watchlist
  Future<bool> addToWatchlist(dynamic movie, {WatchStatus status = WatchStatus.wantToWatch}) async {
    try {
      if (isInWatchlist(movie.id)) {
        return false;
      }

      final watchlistMovie = WatchlistMovie.fromMovie(movie, status: status);
      final id = await _dbService.addToWatchlist(watchlistMovie);
      
      // Создаем объект с правильным ID из БД
      final savedMovie = watchlistMovie.copyWith(id: id);
      
      _watchlist.insert(0, savedMovie);
      _categorizeMovies();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Обновить статус фильма
  Future<bool> updateStatus(int movieId, WatchStatus status) async {
    try {
      final index = _watchlist.indexWhere((m) => m.movieId == movieId);
      if (index == -1) return false;

      final movie = _watchlist[index];
      DateTime? watchedDate = movie.watchedDate;
      
      // Если статус "просмотрено" и дата не установлена, ставим текущую
      if (status == WatchStatus.watched && watchedDate == null) {
        watchedDate = DateTime.now();
      }

      final updatedMovie = movie.copyWith(
        status: status,
        watchedDate: watchedDate,
      );

      await _dbService.updateWatchlistStatus(movieId, status, watchedDate);
      _watchlist[index] = updatedMovie;
      _categorizeMovies();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Обновить оценку пользователя
  Future<bool> updateRating(int movieId, double rating) async {
    try {
      final index = _watchlist.indexWhere((m) => m.movieId == movieId);
      if (index == -1) return false;

      final movie = _watchlist[index];
      final updatedMovie = movie.copyWith(userRating: rating);

      await _dbService.updateWatchlistRating(movieId, rating);
      _watchlist[index] = updatedMovie;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Обновить заметки
  Future<bool> updateNotes(int movieId, String notes) async {
    try {
      final index = _watchlist.indexWhere((m) => m.movieId == movieId);
      if (index == -1) return false;

      final movie = _watchlist[index];
      final updatedMovie = movie.copyWith(notes: notes);

      await _dbService.updateWatchlistNotes(movieId, notes);
      _watchlist[index] = updatedMovie;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Удалить из watchlist
  Future<bool> removeFromWatchlist(int movieId) async {
    try {
      await _dbService.removeFromWatchlist(movieId);
      _watchlist.removeWhere((m) => m.movieId == movieId);
      _categorizeMovies();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Переключить статус (циклически)
  Future<void> toggleStatus(int movieId) async {
    final movie = getWatchlistMovie(movieId);
    if (movie == null) return;

    WatchStatus newStatus;
    switch (movie.status) {
      case WatchStatus.wantToWatch:
        newStatus = WatchStatus.watching;
        break;
      case WatchStatus.watching:
        newStatus = WatchStatus.watched;
        break;
      case WatchStatus.watched:
        newStatus = WatchStatus.dropped;
        break;
      case WatchStatus.dropped:
        newStatus = WatchStatus.wantToWatch;
        break;
    }

    await updateStatus(movieId, newStatus);
  }

  /// Получить статистику
  Map<String, dynamic> getStatistics() {
    final watchedMovies = _watched;
    final totalRatings = watchedMovies.where((m) => m.userRating != null).length;
    final averageRating = totalRatings > 0
        ? watchedMovies
            .where((m) => m.userRating != null)
            .map((m) => m.userRating!)
            .reduce((a, b) => a + b) / totalRatings
        : 0.0;

    // Группировка по месяцам
    final byMonth = <String, int>{};
    for (final movie in watchedMovies) {
      if (movie.watchedDate != null) {
        final key = '${movie.watchedDate!.year}-${movie.watchedDate!.month.toString().padLeft(2, '0')}';
        byMonth[key] = (byMonth[key] ?? 0) + 1;
      }
    }

    return {
      'total': totalCount,
      'wantToWatch': wantToWatchCount,
      'watching': watchingCount,
      'watched': watchedCount,
      'dropped': droppedCount,
      'averageRating': averageRating,
      'byMonth': byMonth,
    };
  }

  /// Сбросить ошибку
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
