import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// ============================================================================
/// FAVORITES PROVIDER
/// ============================================================================
/// Провайдер для управления избранными фильмами
/// ============================================================================

class FavoritesProvider with ChangeNotifier {
  final LocalDatabaseService _dbService = LocalDatabaseService();

  List<Movie> _favorites = [];
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
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Добавить в избранное
  Future<bool> toggleFavorite(Movie movie) async {
    try {
      final isCurrentlyFavorite = await _dbService.isFavorite(movie.id);

      if (isCurrentlyFavorite) {
        await _dbService.removeFromFavorites(movie.id);
        _favorites.removeWhere((m) => m.id == movie.id);
        notifyListeners();
        return false;
      } else {
        await _dbService.addToFavorites(movie);
        _favorites.insert(0, movie);
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Проверить, есть ли в избранном
  Future<bool> isFavorite(int movieId) async {
    return await _dbService.isFavorite(movieId);
  }

  /// Удалить из избранного
  Future<bool> removeFromFavorites(int movieId) async {
    try {
      final removed = await _dbService.removeFromFavorites(movieId);
      if (removed) {
        _favorites.removeWhere((m) => m.id == movieId);
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
