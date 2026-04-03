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

  Future<bool> addToWatchlist(dynamic movie, {WatchStatus status = WatchStatus.wantToWatch}) async {
    try {
      if (isInWatchlist(movie.id)) return false;
      final watchlistMovie = WatchlistMovie.fromMovie(movie, status: status);
<<<<<<< HEAD
      final id = await _dbService.addToWatchlist(watchlistMovie);
      _watchlist.insert(0, watchlistMovie.copyWith(id: id));
=======
      
      if (!kIsWeb) {
        await _dbService.addToWatchlist(watchlistMovie);
      }
      
      _watchlist.insert(0, watchlistMovie);
>>>>>>> main-fixed
      _categorizeMovies();
      await loadActivityLog();
      notifyListeners();
      return true;
<<<<<<< HEAD
    } catch (e) { return false; }
=======
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      // Для Веба все равно добавляем в память
      final watchlistMovie = WatchlistMovie.fromMovie(movie, status: status);
      _watchlist.insert(0, watchlistMovie);
      _categorizeMovies();
      notifyListeners();
      return true;
    }
>>>>>>> main-fixed
  }

  Future<bool> updateStatus(int movieId, WatchStatus status) async {
    try {
      final index = _watchlist.indexWhere((m) => m.movieId == movieId);
      if (index == -1) return false;
      final movie = _watchlist[index];
<<<<<<< HEAD
      DateTime now = DateTime.now();
      await _dbService.updateWatchlistStatus(movieId, status, status == WatchStatus.watched ? now : movie.watchedDate, addedDate: now);
      _watchlist[index] = movie.copyWith(status: status, addedDate: now, watchedDate: status == WatchStatus.watched ? now : movie.watchedDate);
=======
      DateTime? watchedDate = movie.watchedDate;
      
      if (status == WatchStatus.watched && watchedDate == null) {
        watchedDate = DateTime.now();
      }

      final updatedMovie = WatchlistMovie(
        id: movie.id,
        movieId: movie.movieId,
        imdbId: movie.imdbId,
        title: movie.title,
        posterPath: movie.posterPath,
        status: status,
        userRating: movie.userRating,
        notes: movie.notes,
        watchedDate: watchedDate,
        addedDate: movie.addedDate,
      );

      if (!kIsWeb) {
        await _dbService.updateWatchlistStatus(movieId, status, watchedDate);
      }
      
      _watchlist[index] = updatedMovie;
>>>>>>> main-fixed
      _categorizeMovies();
      await loadActivityLog();
      notifyListeners();
      return true;
<<<<<<< HEAD
    } catch (e) { return false; }
=======
    } catch (e) {
      debugPrint('Update status error: $e');
      return false;
    }
>>>>>>> main-fixed
  }

  Future<bool> updateRating(int movieId, double rating) async {
    try {
      final index = _watchlist.indexWhere((m) => m.movieId == movieId);
      if (index == -1) return false;
<<<<<<< HEAD
      await _dbService.updateWatchlistRating(movieId, rating);
      _watchlist[index] = _watchlist[index].copyWith(userRating: rating);
      notifyListeners();
      return true;
    } catch (e) { return false; }
=======

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
>>>>>>> main-fixed
  }

  Future<bool> incrementWatchCount(int movieId) async {
    try {
      final index = _watchlist.indexWhere((m) => m.movieId == movieId);
      if (index == -1) return false;
      final movie = _watchlist[index];
<<<<<<< HEAD
      final now = DateTime.now();
      await _dbService.addWatchLogEntry(movieId, now);
      _watchlist[index] = movie.copyWith(watchCount: movie.watchCount + 1, status: WatchStatus.watched, watchedDate: now, addedDate: now);
      _categorizeMovies();
      await loadActivityLog();
      notifyListeners();
      return true;
    } catch (e) { return false; }
=======
      
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
>>>>>>> main-fixed
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
<<<<<<< HEAD
    } catch (e) { return false; }
=======
    } catch (e) {
      return false;
    }
>>>>>>> main-fixed
  }

  Map<String, dynamic> getStatistics() {
    int totalWatches = 0;
    for (var m in _watchlist) totalWatches += m.watchCount;
    final watchedMovies = _watched;
    final totalRatings = watchedMovies.where((m) => m.userRating != null).length;
<<<<<<< HEAD
    final averageRating = totalRatings > 0 ? watchedMovies.where((m) => m.userRating != null).map((m) => m.userRating!).reduce((a, b) => a + b) / totalRatings : 0.0;
=======
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

>>>>>>> main-fixed
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
<<<<<<< HEAD
=======

  void clearError() {
    _error = null;
    notifyListeners();
  }
>>>>>>> main-fixed
}
