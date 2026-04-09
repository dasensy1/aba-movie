import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/local_database_service.dart';
import 'auth_provider.dart';

/// ============================================================================
/// FAVORITES PROVIDER — Версия 2 (user-scoped)
/// ============================================================================
/// Провайдер для управления избранными фильмами.
/// Данные привязаны к текущему пользователю через AuthProvider.userId.
/// ============================================================================

class FavoritesProvider with ChangeNotifier {
  final LocalDatabaseService _dbService = LocalDatabaseService();

  List<Movie> _favorites = [];
  Set<int> _favoriteIds = {}; // Для быстрой проверки
  bool _isLoading = false;
  String? _error;

  List<Movie> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get count => _favorites.length;

  /// Загрузить избранные фильмы текущего пользователя
  Future<void> loadFavorites(int? userId) async {
    if (userId == null) {
      _favorites = [];
      _favoriteIds = {};
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _favorites = await _dbService.getFavorites(userId);
      _favoriteIds = _favorites.map((m) => m.id).toSet();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
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

      if (isCurrentlyFavorite) {
        await _dbService.removeFromFavorites(movie.id, userId);
        _favorites.removeWhere((m) => m.id == movie.id);
        _favoriteIds.remove(movie.id);
      } else {
        await _dbService.addToFavorites(movie, userId);
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

      await _dbService.addToFavorites(movie, userId);
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
      final removed = await _dbService.removeFromFavorites(movieId, userId);
      if (removed) {
        _favorites.removeWhere((m) => m.id == movieId);
        _favoriteIds.remove(movieId);
        notifyListeners();
      }
      return removed;
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
      await _dbService.clearFavorites(userId);
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
