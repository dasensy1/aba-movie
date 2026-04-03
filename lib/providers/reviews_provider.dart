import 'package:flutter/material.dart';
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
      final reviews = await _dbService.getMovieReviews(movieId);
      _movieReviews[movieId] = reviews;
    } catch (e) {
      debugPrint('Error loading reviews: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addReview(Review review) async {
    try {
      await _dbService.addReview(review);
      // Перезагружаем список после добавления
      await loadReviews(review.movieId);
    } catch (e) {
      debugPrint('Error adding review: $e');
      rethrow;
    }
  }

  Future<void> deleteReview(int reviewId, int movieId) async {
    try {
      await _dbService.deleteReview(reviewId);
      await loadReviews(movieId);
    } catch (e) {
      debugPrint('Error deleting review: $e');
    }
  }
}
