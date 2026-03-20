/// Модель фильма (локальные данные)
class Movie {
  final int id;
  final String title;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final int voteCount;
  final String? releaseDate;
  final List<int> genreIds;
  final double? popularity;

  Movie({
    required this.id,
    required this.title,
    this.overview,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    required this.voteCount,
    this.releaseDate,
    required this.genreIds,
    this.popularity,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] ?? 0,
      title: json['title'] ?? json['name'] ?? 'Без названия',
      overview: json['overview'],
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      voteCount: json['vote_count'] ?? 0,
      releaseDate: json['release_date'] ?? json['first_air_date'],
      genreIds: json['genre_ids'] != null 
          ? List<int>.from(json['genre_ids']) 
          : [],
      popularity: (json['popularity'] ?? 0).toDouble(),
    );
  }

  /// URL постера полного размера
  String get posterUrl {
    if (posterPath == null || posterPath!.isEmpty) return '';
    return 'https://image.tmdb.org/t/p/w500$posterPath';
  }

  /// URL бэкдропа (фона)
  String get backdropUrl {
    if (backdropPath == null || backdropPath!.isEmpty) return '';
    return 'https://image.tmdb.org/t/p/original$backdropPath';
  }

  /// Цвет градиента для постера (на основе ID)
  List<int> get gradientColors {
    final colors = [
      [0xFF7C4DFF, 0xFF00E5FF],
      [0xFF00B8D4, 0xFF0091EA],
      [0xFFD500F9, 0xFFAA00FF],
      [0xFF651FFF, 0xFF311B92],
      [0xFF00E676, 0xFF00C853],
      [0xFFFF9100, 0xFFFF6D00],
      [0xFFFF1744, 0xFFD50000],
      [0xFFE040FB, 0xFF6200EA],
    ];
    final index = id % colors.length;
    return colors[index];
  }

  /// Год релиза
  String get releaseYear {
    if (releaseDate == null || releaseDate!.isEmpty) return '';
    return releaseDate!.substring(0, 4);
  }

  /// Карта для локального хранения
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'overview': overview,
      'posterPath': posterPath,
      'backdropPath': backdropPath,
      'voteAverage': voteAverage,
      'voteCount': voteCount,
      'releaseDate': releaseDate,
      'genreIds': genreIds.join(','),
      'popularity': popularity,
    };
  }

  factory Movie.fromMap(Map<String, dynamic> map) {
    return Movie(
      id: map['id'] ?? 0,
      title: map['title'] ?? 'Без названия',
      overview: map['overview'],
      posterPath: map['posterPath'],
      backdropPath: map['backdropPath'],
      voteAverage: (map['voteAverage'] ?? 0).toDouble(),
      voteCount: map['voteCount'] ?? 0,
      releaseDate: map['releaseDate'],
      genreIds: map['genreIds'] != null 
          ? (map['genreIds'] as String).split(',').map(int.parse).toList()
          : [],
      popularity: (map['popularity'] ?? 0).toDouble(),
    );
  }
}
