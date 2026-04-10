import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/models.dart';

/// ============================================================================
/// TMDB API SERVICE — HTTPS, полный доступ к TMDb
/// ============================================================================

class TmdbApiService {
  static final TmdbApiService _instance = TmdbApiService._internal();
  factory TmdbApiService() => _instance;
  TmdbApiService._internal();
// a
  // TMDb API ключ (Bearer token)
  static const String _bearerToken = 'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI1MTBkZmEwMDc4MzIwYjEwZWRkZWE4NDA4N2NiYWQ1NCIsIm5iZiI6MTc3NTgwMDcwMS4wMTcsInN1YiI6IjY5ZDg5MTdkYzc2MmQ3M2NjMWJmZjBjZCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.KwDLhT2Gg4KoC8S1HXMWjapB6xnliLzMbhP5rE0xacA';
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _imageBaseUrl = 'https://image.tmdb.org/t/p';

  String get _authHeader => 'Bearer $_bearerToken';

  /// Поиск фильмов по названию
  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    if (query.trim().isEmpty) return [];

    try {
      debugPrint('TMDb Search: $query (страница $page)');

      final url = '$_baseUrl/search/movie?query=${Uri.encodeComponent(query)}&page=$page&include_adult=false&language=ru-RU';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['results'] != null) {
          final results = data['results'] as List;
          
          final movies = <Movie>[];
          for (var item in results) {
            movies.add(Movie.fromJson(item));
          }
          
          debugPrint('TMDb Search найдено ${movies.length} фильмов');
          return movies;
        }
        return [];
      } else {
        debugPrint('TMDb Search error: ${response.statusCode} - ${response.body}');
        throw Exception('Ошибка API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('TMDb Search error: $e');
      rethrow;
    }
  }

  /// Получить детали фильма по ID
  Future<Movie?> getMovieDetails(int movieId) async {
    try {
      debugPrint('TMDb Getting details for movie ID: $movieId');
      
      final url = '$_baseUrl/movie/$movieId?language=ru-RU&append_to_response=credits,videos';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Movie.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('TMDb Details error: $e');
      return null;
    }
  }

  /// Получить популярные фильмы
  Future<List<Movie>> getPopularMovies({int page = 1}) async {
    try {
      debugPrint('TMDb Getting popular movies (страница $page)');
      
      final url = '$_baseUrl/movie/popular?language=ru-RU&page=$page';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null) {
          final results = data['results'] as List;
          return results.map((item) => Movie.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('TMDb Popular error: $e');
      rethrow;
    }
  }

  /// Получить фильмы в тренде (today/week)
  Future<List<Movie>> getTrendingMovies({String timeWindow = 'week'}) async {
    try {
      debugPrint('TMDb Getting trending movies ($timeWindow)');
      
      final url = '$_baseUrl/trending/movie/$timeWindow?language=ru-RU';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null) {
          final results = data['results'] as List;
          return results.map((item) => Movie.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('TMDb Trending error: $e');
      rethrow;
    }
  }

  /// Получить топ рейтинговые фильмы
  Future<List<Movie>> getTopRatedMovies({int page = 1}) async {
    try {
      debugPrint('TMDb Getting top rated movies (страница $page)');
      
      final url = '$_baseUrl/movie/top_rated?language=ru-RU&page=$page';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null) {
          final results = data['results'] as List;
          return results.map((item) => Movie.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('TMDb Top Rated error: $e');
      rethrow;
    }
  }

  /// Получить фильмы по жанру
  Future<List<Movie>> getMoviesByGenre(int genreId, {int page = 1}) async {
    try {
      debugPrint('TMDb Getting movies by genre: $genreId (страница $page)');
      
      final url = '$_baseUrl/discover/movie?with_genres=$genreId&language=ru-RU&page=$page&sort_by=popularity.desc';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null) {
          final results = data['results'] as List;
          return results.map((item) => Movie.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('TMDb Genre error: $e');
      rethrow;
    }
  }

  /// Получить список всех жанров
  Future<List<Genre>> getGenres() async {
    try {
      debugPrint('=== TMDB GET GENRES ===');
      
      final url = '$_baseUrl/genre/movie/list?language=ru-RU';
      debugPrint('URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Response genres: ${data['genres']}');
        
        if (data['genres'] != null) {
          final genres = data['genres'] as List;
          final genreList = genres.map((item) => Genre.fromJson(item)).toList();
          debugPrint('Распарсено ${genreList.length} жанров');
          return genreList;
        }
      } else {
        debugPrint('Error status: ${response.statusCode}');
      }
      return [];
    } catch (e) {
      debugPrint('TMDb Genres error: $e');
      rethrow;
    }
  }

  /// Получить актеров фильма (cast)
  Future<List<Map<String, dynamic>>> getMovieCast(int movieId) async {
    try {
      debugPrint('TMDb Getting cast for movie ID: $movieId');
      
      final url = '$_baseUrl/movie/$movieId/credits?language=ru-RU';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['cast'] != null) {
          final cast = data['cast'] as List;
          return cast.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      debugPrint('TMDb Cast error: $e');
      return [];
    }
  }

  /// Получить похожие фильмы
  Future<List<Movie>> getSimilarMovies(int movieId, {int page = 1}) async {
    try {
      debugPrint('TMDb Getting similar movies for ID: $movieId');
      
      final url = '$_baseUrl/movie/$movieId/similar?language=ru-RU&page=$page';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null) {
          final results = data['results'] as List;
          return results.map((item) => Movie.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('TMDb Similar error: $e');
      return [];
    }
  }

  /// Получить рекомендации для фильма
  Future<List<Movie>> getRecommendations(int movieId, {int page = 1}) async {
    try {
      debugPrint('TMDb Getting recommendations for ID: $movieId');
      
      final url = '$_baseUrl/movie/$movieId/recommendations?language=ru-RU&page=$page';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null) {
          final results = data['results'] as List;
          return results.map((item) => Movie.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('TMDb Recommendations error: $e');
      return [];
    }
  }

  /// Получить URL для постера
  static String getPosterUrl(String? posterPath, {String size = 'w500'}) {
    if (posterPath == null || posterPath.isEmpty) return '';
    if (posterPath.startsWith('http')) return posterPath;
    return '$_imageBaseUrl/$size$posterPath';
  }

  /// Получить URL для backdrop
  static String getBackdropUrl(String? backdropPath, {String size = 'original'}) {
    if (backdropPath == null || backdropPath.isEmpty) return '';
    return '$_imageBaseUrl/$size$backdropPath';
  }
}
