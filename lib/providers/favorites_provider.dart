import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/local_database_service.dart';

/// ============================================================================
/// FAVORITES PROVIDER
/// ============================================================================
/// Провайдер для управления избранными фильмами
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

  /// Загрузить избранные фильмы
  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();

    try {
      _favorites = await _dbService.getFavorites();
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
  Future<bool> toggleFavorite(Movie movie) async {
    try {
      final isCurrentlyFavorite = _favoriteIds.contains(movie.id);

      if (isCurrentlyFavorite) {
        // Удаляем
        await _dbService.removeFromFavorites(movie.id);
        _favorites.removeWhere((m) => m.id == movie.id);
        _favoriteIds.remove(movie.id);
      } else {
        // Добавляем
        await _dbService.addToFavorites(movie);
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
  Future<bool> addToFavorites(Movie movie) async {
    try {
      if (_favoriteIds.contains(movie.id)) {
        return false; // Уже в избранном
      }

      await _dbService.addToFavorites(movie);
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
  Future<bool> removeFromFavorites(int movieId) async {
    try {
      final removed = await _dbService.removeFromFavorites(movieId);
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

  /// Очистить все избранное
  Future<void> clearAll() async {
    try {
      await _dbService.clearAll();
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
