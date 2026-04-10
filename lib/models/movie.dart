/// Модель фильма (локальные данные + TMDb)
class Movie {
  final int id;
  final String? imdbId; // Оригинальный ID для OMDb (legacy)
  final String title;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final int voteCount;
  final String? releaseDate;
  final List<int> genreIds;
  final List<Map<String, dynamic>>? genres; // Полный список жанров из TMDb
  final double? popularity;
  final String? tagline;
  final int? runtime;
  final String? status;
  final String? originalLanguage;
  final String? originalTitle;
  final double? budget;
  final double? revenue;
  final List<Map<String, dynamic>>? credits; // Актеры и съемочная группа
  final List<String>? videos; // Трейлеры

  Movie({
    required this.id,
    this.imdbId,
    required this.title,
    this.overview,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    required this.voteCount,
    this.releaseDate,
    required this.genreIds,
    this.genres,
    this.popularity,
    this.tagline,
    this.runtime,
    this.status,
    this.originalLanguage,
    this.originalTitle,
    this.budget,
    this.revenue,
    this.credits,
    this.videos,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    // Обработка genres
    List<int> genreIds = [];
    List<Map<String, dynamic>>? genres;
    
    if (json['genre_ids'] != null) {
      genreIds = List<int>.from(json['genre_ids']);
    }
    
    if (json['genres'] != null) {
      genres = (json['genres'] as List).cast<Map<String, dynamic>>();
      if (genreIds.isEmpty) {
        genreIds = genres.map((g) => g['id'] as int).toList();
      }
    }

    // Обработка credits
    List<Map<String, dynamic>>? credits;
    if (json['credits'] != null && json['credits']['cast'] != null) {
      credits = (json['credits']['cast'] as List)
          .cast<Map<String, dynamic>>();
    }

    // Обработка videos
    List<String>? videos;
    if (json['videos'] != null && json['videos']['results'] != null) {
      videos = (json['videos']['results'] as List)
          .where((v) => v['site'] == 'YouTube' && v['type'] == 'Trailer')
          .map((v) => v['key'].toString())
          .toList();
    }

    return Movie(
      id: json['id'] ?? 0,
      imdbId: json['imdb_id'],
      title: json['title'] ?? json['name'] ?? 'Без названия',
      overview: json['overview'],
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      voteCount: json['vote_count'] ?? 0,
      releaseDate: json['release_date'] ?? json['first_air_date'],
      genreIds: genreIds,
      genres: genres,
      popularity: (json['popularity'] ?? 0).toDouble(),
      tagline: json['tagline'],
      runtime: json['runtime'],
      status: json['status'],
      originalLanguage: json['original_language'],
      originalTitle: json['original_title'],
      budget: json['budget']?.toDouble(),
      revenue: json['revenue']?.toDouble(),
      credits: credits,
      videos: videos,
    );
  }

  /// Создание из TMDB API ответа
  factory Movie.fromTmdb(Map<String, dynamic> json) {
    double voteAverage = 0.0;
    if (json['vote_average'] != null) {
      voteAverage = (json['vote_average'] as num).toDouble();
    }

    int voteCount = 0;
    if (json['vote_count'] != null) {
      voteCount = json['vote_count'] as int;
    }

    int? runtime;
    if (json['runtime'] != null) {
      runtime = json['runtime'] as int;
    }

    List<int> genreIds = [];
    List<Map<String, dynamic>>? genresList;

    if (json['genre_ids'] != null) {
      genreIds = List<int>.from(json['genre_ids']);
    }
    if (json['genres'] != null) {
      genresList = (json['genres'] as List).cast<Map<String, dynamic>>();
      if (genreIds.isEmpty) {
        genreIds = genresList.map((g) => g['id'] as int).toList();
      }
    }

    List<Map<String, dynamic>>? credits;
    if (json['credits'] != null && json['credits']['cast'] != null) {
      credits = (json['credits']['cast'] as List).cast<Map<String, dynamic>>();
    }

    List<String>? videos;
    if (json['videos'] != null && json['videos']['results'] != null) {
      videos = (json['videos']['results'] as List)
          .where((v) => v['site'] == 'YouTube' && v['type'] == 'Trailer')
          .map((v) => v['key'].toString())
          .toList();
    }

    return Movie(
      id: json['id'] ?? 0,
      imdbId: json['imdb_id'],
      title: json['title'] ?? json['name'] ?? 'Без названия',
      overview: json['overview'],
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      voteAverage: voteAverage,
      voteCount: voteCount,
      releaseDate: json['release_date'] ?? json['first_air_date'],
      genreIds: genreIds,
      genres: genresList,
      popularity: json['popularity'] != null
          ? (json['popularity'] as num).toDouble()
          : 0.0,
      tagline: json['tagline'],
      runtime: runtime,
      status: json['status'],
      originalLanguage: json['original_language'],
      credits: credits,
      videos: videos,
    );
  }

  /// Создание из OMDb API (legacy)
  factory Movie.fromOmdb(Map<String, dynamic> json) {
    String? releaseDate;
    if (json['Released'] != null && json['Released'] != 'N/A') {
      try {
        final parts = json['Released'].toString().trim().split(' ');
        if (parts.length >= 3) {
          final year = parts.last;
          final monthStr = parts[parts.length - 2];
          final day = parts[0];

          const months = {
            'Jan': '01', 'Feb': '02', 'Mar': '03', 'Apr': '04',
            'May': '05', 'Jun': '06', 'Jul': '07', 'Aug': '08',
            'Sep': '09', 'Oct': '10', 'Nov': '11', 'Dec': '12',
          };

          final month = months[monthStr] ?? '01';
          releaseDate = '$year-$month-${day.padLeft(2, '0')}';
        }
      } catch (e) {
        releaseDate = null;
      }
    }

    double voteAverage = 0.0;
    if (json['imdbRating'] != null && json['imdbRating'] != 'N/A') {
      try {
        voteAverage = double.parse(json['imdbRating'].toString().split('/').first);
      } catch (e) {
        voteAverage = 0.0;
      }
    }

    int voteCount = 0;
    if (json['imdbVotes'] != null && json['imdbVotes'] != 'N/A') {
      try {
        final votes = json['imdbVotes'].toString().replaceAll(',', '');
        voteCount = int.tryParse(votes) ?? 0;
      } catch (e) {
        voteCount = 0;
      }
    }

    String? posterUrl;
    if (json['Poster'] != null &&
        json['Poster'] != 'N/A' &&
        json['Poster'].toString().trim().isNotEmpty) {
      posterUrl = json['Poster'].toString().trim();
    }

    int? runtime;
    if (json['Runtime'] != null && json['Runtime'] != 'N/A') {
      runtime = int.tryParse(json['Runtime'].toString().replaceAll(' min', ''));
    }

    return Movie(
      id: json['imdbID'] != null ? json['imdbID'].toString().hashCode : 0,
      imdbId: json['imdbID'],
      title: json['Title'] ?? 'Без названия',
      overview: json['Plot'] == 'N/A' ? null : json['Plot'],
      posterPath: posterUrl,
      backdropPath: null,
      voteAverage: voteAverage,
      voteCount: voteCount,
      releaseDate: releaseDate,
      genreIds: [],
      popularity: 0.0,
      tagline: null,
      runtime: runtime,
      status: json['Response'] == 'True' ? 'Вышел' : null,
      originalLanguage: null,
    );
  }

  /// Получить URL постера
  String get posterUrl {
    if (posterPath == null || posterPath!.isEmpty) return '';
    if (posterPath!.startsWith('http')) return posterPath!;
    return 'https://image.tmdb.org/t/p/w500$posterPath';
  }

  /// Получить URL backdrop
  String get backdropUrl {
    if (backdropPath == null || backdropPath!.isEmpty) return '';
    return 'https://image.tmdb.org/t/p/original$backdropPath';
  }

  /// Синопсис фильма (описание)
  String get synopsis {
    if (overview == null || overview!.trim().isEmpty) {
      return 'Синопсис отсутствует.';
    }
    return overview!.trim();
  }

  /// Получить список имен жанров
  List<String> get genreNames {
    if (genres != null && genres!.isNotEmpty) {
      return genres!.map((g) => g['name'] as String).toList();
    }
    return [];
  }

  /// Получить главного актера
  String? get mainActor {
    if (credits != null && credits!.isNotEmpty) {
      return credits![0]['name'].toString();
    }
    return null;
  }

  /// Получить трейлер YouTube
  String? get youtubeTrailerKey {
    if (videos != null && videos!.isNotEmpty) {
      return videos![0];
    }
    return null;
  }

  List<int> get gradientColors {
    final colors = [
      [0xFF7C4DFF, 0xFF00E5FF],
      [0xFF00B8D4, 0xFF0091EA],
      [0xFFD500F9, 0xFFAA00FF],
      [0xFF651FFF, 0xFF311B92],
    ];
    final index = id.abs() % colors.length;
    return colors[index];
  }

  String get releaseYear {
    if (releaseDate == null || releaseDate!.isEmpty) return '';
    return releaseDate!.substring(0, 4);
  }

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
      genreIds: map['genreIds'] != null && map['genreIds'].toString().isNotEmpty
          ? (map['genreIds'] as String).split(',').map(int.parse).toList()
          : [],
      popularity: (map['popularity'] ?? 0).toDouble(),
    );
  }
}
