import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/local_database_service.dart';

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
      if (!kIsWeb) {
        final reviews = await _dbService.getMovieReviews(movieId);
        _movieReviews[movieId] = reviews;
      }
    } catch (e) {
      debugPrint('Error loading reviews: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addReview(Review review) async {
    try {
      if (!kIsWeb) {
        await _dbService.addReview(review);
        // Перезагружаем список после добавления
        await loadReviews(review.movieId);
      } else {
        // Fallback для Web: сохраняем в памяти
        if (!_movieReviews.containsKey(review.movieId)) {
          _movieReviews[review.movieId] = [];
        }
        _movieReviews[review.movieId]!.insert(0, review);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error adding review: $e');
      // Даже если БД упала, добавим в память для вида
      if (!_movieReviews.containsKey(review.movieId)) {
        _movieReviews[review.movieId] = [];
      }
      _movieReviews[review.movieId]!.insert(0, review);
      notifyListeners();
    }
  }

  Future<void> deleteReview(int reviewId, int movieId) async {
    try {
      if (!kIsWeb) {
        await _dbService.deleteReview(reviewId);
        await loadReviews(movieId);
      } else {
        if (_movieReviews.containsKey(movieId)) {
          _movieReviews[movieId]!.removeWhere((r) => r.id == reviewId);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error deleting review: $e');
    }
  }
}
