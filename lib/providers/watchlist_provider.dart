import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

class WatchlistProvider with ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();

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
      final client = await _supabase.getClient();
      final data = await client
          .from('watchlist')
          .select()
          .eq('user_id', userId)
          .order('added_date', ascending: false);

      _watchlist = data.map((map) => WatchlistMovie.fromMap(map)).toList();
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
      final client = await _supabase.getClient();
      final results = await client
          .from('watch_log')
          .select('movie_id, status, watch_date')
          .eq('user_id', userId)
          .order('watch_date', ascending: false)
          .limit(20);

      final log = results.map((row) {
        return {
          'movie_id': row['movie_id'],
          'status': row['status'],
          'watch_date': row['watch_date'],
        };
      }).toList();

      // Enrich with movie titles from watchlist
      final enriched = <Map<String, dynamic>>[];
      for (var entry in log) {
        final movieId = entry['movie_id'] as int;
        final watchlistItem = _watchlist.firstWhere(
          (m) => m.movieId == movieId,
          orElse: () => WatchlistMovie(
            id: 0,
            movieId: movieId,
            imdbId: '',
            title: 'Unknown',
            posterPath: '',
            status: WatchStatus.wantToWatch,
            userRating: null,
            notes: null,
            watchedDate: null,
            addedDate: DateTime.now(),
            watchCount: 0,
          ),
        );
        enriched.add({
          'movie_id': movieId,
          'title': watchlistItem.title,
          'poster_path': watchlistItem.posterPath,
          'status': entry['status'],
          'watch_date': entry['watch_date'],
        });
      }

      _activityLog = enriched;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading activity log: $e');
      _activityLog = [];
    }
  }

  void _categorizeMovies() {
    _wantToWatch =
        _watchlist.where((m) => m.status == WatchStatus.wantToWatch).toList();
    _watching =
        _watchlist.where((m) => m.status == WatchStatus.watching).toList();
    _watched =
        _watchlist.where((m) => m.status == WatchStatus.watched).toList();
    _dropped =
        _watchlist.where((m) => m.status == WatchStatus.dropped).toList();
  }

  bool isInWatchlist(int movieId) =>
      _watchlist.any((m) => m.movieId == movieId);

  WatchlistMovie? getWatchlistMovie(int movieId) {
    try {
      return _watchlist.firstWhere((m) => m.movieId == movieId);
    } catch (e) {
      return null;
    }
  }

  /// Добавить фильм в watchlist
  Future<bool> addToWatchlist(dynamic movie, int? userId,
      {WatchStatus status = WatchStatus.wantToWatch,
      DateTime? watchedDate}) async {
    if (userId == null) return false;

    try {
      if (isInWatchlist(movie.id)) return false;

      if (watchedDate != null && watchedDate.isAfter(DateTime.now())) {
        _error = 'Нельзя установить будущую дату просмотра';
        return false;
      }

      final watchlistMovie =
          WatchlistMovie.fromMovie(movie, status: status).copyWith(
        watchedDate: watchedDate,
        watchCount: status == WatchStatus.watched ? 1 : 0,
      );

      final client = await _supabase.getClient();
      await client.from('watchlist').insert({
        'user_id': userId,
        'movie_id': movie.id,
        'imdb_id': movie.imdbId,
        'title': movie.title,
        'poster_path': movie.posterPath,
        'status': status.name,
        'user_rating': null,
        'notes': null,
        'watched_date': watchedDate?.toIso8601String(),
        'added_date': DateTime.now().toIso8601String(),
        'watch_count': status == WatchStatus.watched ? 1 : 0,
      });

      await _logActivity(userId, movie.id, status.name, DateTime.now());

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

  /// Обновить статус фильма
  Future<bool> updateStatus(int movieId, WatchStatus status, int? userId,
      {DateTime? watchedDate}) async {
    if (userId == null) return false;

    try {
      final index = _watchlist.indexWhere((m) => m.movieId == movieId);
      if (index == -1) return false;

      final movie = _watchlist[index];
      DateTime? finalWatchedDate = watchedDate ?? movie.watchedDate;

      if (finalWatchedDate != null &&
          finalWatchedDate.isAfter(DateTime.now())) {
        _error = 'Нельзя установить будущую дату просмотра';
        return false;
      }

      if (status == WatchStatus.watched && finalWatchedDate == null) {
        finalWatchedDate = DateTime.now();
      }

      final now = DateTime.now();

      final client = await _supabase.getClient();
      await client
          .from('watchlist')
          .update({
            'status': status.name,
            'added_date': now.toIso8601String(),
            if (finalWatchedDate != null)
              'watched_date': finalWatchedDate.toIso8601String(),
            'watch_count': status == WatchStatus.watched
                ? movie.watchCount + 1
                : movie.watchCount,
          })
          .eq('movie_id', movieId)
          .eq('user_id', userId);

      await _logActivity(userId, movieId, status.name, now);

      _watchlist[index] = movie.copyWith(
        status: status,
        addedDate: now,
        watchedDate: finalWatchedDate,
        watchCount: status == WatchStatus.watched
            ? movie.watchCount + 1
            : movie.watchCount,
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
      final updatedMovie = movie.copyWith(userRating: rating);

      final client = await _supabase.getClient();
      await client
          .from('watchlist')
          .update({'user_rating': rating})
          .eq('movie_id', movieId)
          .eq('user_id', userId);

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
      final updatedMovie = movie.copyWith(notes: notes);

      final client = await _supabase.getClient();
      await client
          .from('watchlist')
          .update({'notes': notes})
          .eq('movie_id', movieId)
          .eq('user_id', userId);

      _watchlist[index] = updatedMovie;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> incrementWatchCount(int movieId, int? userId,
      {DateTime? watchedDate}) async {
    if (userId == null) return false;

    try {
      final index = _watchlist.indexWhere((m) => m.movieId == movieId);
      if (index == -1) return false;

      final movie = _watchlist[index];
      final now = watchedDate ?? DateTime.now();

      if (watchedDate != null && watchedDate.isAfter(DateTime.now())) {
        _error = 'Нельзя установить будущую дату просмотра';
        return false;
      }

      final client = await _supabase.getClient();
      await client.from('watch_log').insert({
        'user_id': userId,
        'movie_id': movieId,
        'status': 'watched',
        'watch_date': now.toIso8601String(),
      });

      await client
          .from('watchlist')
          .update({
            'watch_count': movie.watchCount + 1,
            'status': 'watched',
            'watched_date': now.toIso8601String(),
            'added_date': now.toIso8601String(),
          })
          .eq('movie_id', movieId)
          .eq('user_id', userId);

      await _logActivity(userId, movieId, 'watched', now);

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
      final client = await _supabase.getClient();
      await client
          .from('watch_log')
          .delete()
          .eq('movie_id', movieId)
          .eq('user_id', userId);
      await client
          .from('watchlist')
          .delete()
          .eq('movie_id', movieId)
          .eq('user_id', userId);

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
      final client = await _supabase.getClient();
      await client.from('watch_log').delete().eq('user_id', userId);
      await client.from('watchlist').delete().eq('user_id', userId);

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

  Future<void> _logActivity(
      int userId, int movieId, String status, DateTime date) async {
    try {
      final client = await _supabase.getClient();
      await client.from('watch_log').insert({
        'user_id': userId,
        'movie_id': movieId,
        'status': status,
        'watch_date': date.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error logging activity: $e');
    }
  }

  Map<String, dynamic> getStatistics() {
    int totalWatches = 0;
    for (var m in _watchlist) {
      totalWatches += m.watchCount;
    }
    final watchedMovies = _watched;
    final totalRatings =
        watchedMovies.where((m) => m.userRating != null).length;
    final averageRating = totalRatings > 0
        ? watchedMovies
                .where((m) => m.userRating != null)
                .map((m) => m.userRating!)
                .reduce((a, b) => a + b) /
            totalRatings
        : 0.0;

    final byMonth = <String, int>{};
    for (final movie in watchedMovies) {
      if (movie.watchedDate != null) {
        final key =
            '${movie.watchedDate!.year}-${movie.watchedDate!.month.toString().padLeft(2, '0')}';
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
