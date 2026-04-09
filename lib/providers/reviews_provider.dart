import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/local_database_service.dart';

/// ============================================================================
/// REVIEWS PROVIDER — Версия 2 (user-scoped)
/// ============================================================================
/// Обзоры привязаны к пользователям через user_id в БД.
/// Для UI используется userId из AuthProvider.
/// ============================================================================

class ReviewsProvider with ChangeNotifier {
  final LocalDatabaseService _dbService = LocalDatabaseService();

  Map<int, List<Review>> _movieReviews = {};
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<Review> getReviewsForMovie(int movieId) {
    return _movieReviews[movieId] ?? [];
  }

  Future<void> loadReviews(int movieId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final reviews = await _dbService.getMovieReviews(movieId);
      _movieReviews[movieId] = reviews;
    } catch (e) {
      debugPrint('Error loading reviews: $e');
      _movieReviews[movieId] = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Добавить обзор (требуется userId текущего пользователя)
  Future<void> addReview(Review review, int? userId) async {
    if (userId == null) return;

    try {
      await _dbService.addReview(review, userId);
      // Перезагружаем список после добавления
      await loadReviews(review.movieId);
    } catch (e) {
      debugPrint('Error adding review: $e');
    }
  }

  /// Удалить обзор (user-scoped — можно удалить только свой)
  Future<void> deleteReview(int reviewId, int movieId, int? userId) async {
    if (userId == null) return;

    try {
      await _dbService.deleteReview(reviewId, userId);
      await loadReviews(movieId);
    } catch (e) {
      debugPrint('Error deleting review: $e');
    }
  }
}
