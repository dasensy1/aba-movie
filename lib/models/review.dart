/// Модель обзора на фильм
class Review {
  final int id;
  final int movieId;
  final int userId;
  final String userName;
  final String userPhotoUrl;
  final double rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.movieId,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id == 0 ? null : id,
      'movie_id': movieId,
      'user_id': userId,
      'user_name': userName,
      'user_photo_url': userPhotoUrl,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
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
}
