import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

/// ============================================================================
/// REVIEWS PROVIDER — Supabase Edition
/// ============================================================================
/// Обзоры привязаны к пользователям через user_id в Supabase.
/// ============================================================================

class ReviewsProvider with ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();

  final Map<int, List<Review>> _movieReviews = {};
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<Review> getReviewsForMovie(int movieId) {
    return _movieReviews[movieId] ?? [];
  }

  Future<void> loadReviews(int movieId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final client = await _supabase.getClient();
      final data = await client
          .from('reviews')
          .select()
          .eq('movie_id', movieId)
          .order('created_at', ascending: false);

      final reviews = data.map((map) => _reviewFromMap(map)).toList();
      _movieReviews[movieId] = reviews;
    } catch (e) {
      debugPrint('Error loading reviews: $e');
      _movieReviews[movieId] = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Review _reviewFromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'] ?? 0,
      movieId: map['movie_id'] ?? 0,
      userId: map['user_id'] ?? 0,
      userName: map['user_name'] ?? 'Аноним',
      userPhotoUrl: map['user_photo_url'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  /// Добавить обзор (требуется userId текущего пользователя)
  Future<void> addReview(Review review, int? userId) async {
    if (userId == null) return;

    try {
      final client = await _supabase.getClient();
      await client.from('reviews').insert({
        'user_id': userId,
        'movie_id': review.movieId,
        'user_name': review.userName,
        'rating': review.rating,
        'comment': review.comment,
        'created_at': DateTime.now().toIso8601String(),
      });

      await loadReviews(review.movieId);
    } catch (e) {
      debugPrint('Error adding review: $e');
    }
  }

  /// Удалить обзор (user-scoped — можно удалить только свой)
  Future<void> deleteReview(int reviewId, int movieId, int? userId) async {
    if (userId == null) return;

    try {
      final client = await _supabase.getClient();
      await client
          .from('reviews')
          .delete()
          .eq('id', reviewId)
          .eq('user_id', userId);

      await loadReviews(movieId);
    } catch (e) {
      debugPrint('Error deleting review: $e');
    }
  }
}
