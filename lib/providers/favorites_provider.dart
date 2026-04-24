import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

/// ============================================================================
/// FAVORITES PROVIDER — Supabase Edition
/// ============================================================================
/// Провайдер для управления избранными фильмами через Supabase.
/// ============================================================================

class FavoritesProvider with ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();

  List<Movie> _favorites = [];
  Set<int> _favoriteIds = {};
  bool _isLoading = false;
  String? _error;

  List<Movie> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get count => _favorites.length;

  int? _lastLoadedUserId;
  bool _isFirstLoad = true;

  /// Загрузить избранные фильмы текущего пользователя
  Future<void> loadFavorites(int? userId) async {
    if (userId == _lastLoadedUserId && !_isFirstLoad) return;
    _lastLoadedUserId = userId;
    _isFirstLoad = false;

    if (userId == null) {
      _favorites = [];
      _favoriteIds = {};
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final client = await _supabase.getClient();
      final data = await client
          .from('favorites')
          .select()
          .eq('user_id', userId)
          .order('added_at', ascending: false);

      _favorites = data.map((map) => _movieFromMap(map)).toList();
      _favoriteIds = _favorites.map((m) => m.id).toSet();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Movie _movieFromMap(Map<String, dynamic> map) {
    return Movie(
      id: map['movie_id'] ?? map['id'] ?? 0,
      title: map['title'] ?? 'Без названия',
      overview: map['overview'],
      posterPath: map['poster_path'],
      backdropPath: map['backdrop_path'],
      voteAverage: (map['vote_average'] ?? 0).toDouble(),
      voteCount: map['vote_count'] ?? 0,
      releaseDate: map['release_date'],
      genreIds:
          map['genre_ids'] != null && map['genre_ids'].toString().isNotEmpty
              ? (map['genre_ids'] as String).split(',').map(int.parse).toList()
              : [],
      popularity: (map['popularity'] ?? 0).toDouble(),
    );
  }

  /// Проверить, есть ли в избранном (синхронно)
  bool isFavoriteNow(int movieId) {
    return _favoriteIds.contains(movieId);
  }

  /// Добавить/удалить из избранного
  Future<bool> toggleFavorite(Movie movie, int? userId) async {
    if (userId == null) return false;

    try {
      final isCurrentlyFavorite = _favoriteIds.contains(movie.id);
      final client = await _supabase.getClient();

      if (isCurrentlyFavorite) {
        await client
            .from('favorites')
            .delete()
            .eq('movie_id', movie.id)
            .eq('user_id', userId);
        _favorites.removeWhere((m) => m.id == movie.id);
        _favoriteIds.remove(movie.id);
      } else {
        await client.from('favorites').insert({
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
        });
        _favorites.insert(0, movie);
        _favoriteIds.add(movie.id);
      }

      notifyListeners();
      return !isCurrentlyFavorite;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Добавить в избранное
  Future<bool> addToFavorites(Movie movie, int? userId) async {
    if (userId == null) return false;

    try {
      if (_favoriteIds.contains(movie.id)) return false;

      final client = await _supabase.getClient();
      await client.from('favorites').insert({
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
      });

      _favorites.insert(0, movie);
      _favoriteIds.add(movie.id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Удалить из избранного
  Future<bool> removeFromFavorites(int movieId, int? userId) async {
    if (userId == null) return false;

    try {
      final client = await _supabase.getClient();
      await client
          .from('favorites')
          .delete()
          .eq('movie_id', movieId)
          .eq('user_id', userId);

      _favorites.removeWhere((m) => m.id == movieId);
      _favoriteIds.remove(movieId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Очистить ВСЁ избранное (только избранное, не все данные!)
  Future<void> clearAll(int? userId) async {
    if (userId == null) return;

    try {
      final client = await _supabase.getClient();
      await client.from('favorites').delete().eq('user_id', userId);
      _favorites = [];
      _favoriteIds = {};
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  /// Сбросить ошибку
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
