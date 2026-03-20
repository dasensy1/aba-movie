import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/models.dart';

/// ============================================================================
/// OMDb API SERVICE
/// ============================================================================
/// Сервис для работы с OMDb API
/// API ключ: 4310ed30
/// ============================================================================

class OmdbApiService {
  static final OmdbApiService _instance = OmdbApiService._internal();
  factory OmdbApiService() => _instance;
  OmdbApiService._internal();

  static const String apiKey = '4310ed30';
  static const String baseUrl = 'https://www.omdbapi.com';

  /// Поиск фильмов по названию
  Future<List<Movie>> searchMovies(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      debugPrint('OMDb Search: $query');
      
      final response = await http.get(
        Uri.parse('$baseUrl/?s=${Uri.encodeComponent(query)}&apikey=$apiKey'),
      ).timeout(const Duration(seconds: 10));

      debugPrint('OMDb Response status: ${response.statusCode}');
      debugPrint('OMDb Response body: ${response.body.substring(0, math.min(200, response.body.length))}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['Response'] == 'True' && data['Search'] != null) {
          final results = data['Search'] as List;
          debugPrint('OMDb Found ${results.length} movies');

          // Загружаем детали для каждого фильма
          List<Movie> movies = [];
          for (var item in results) {
            try {
              final movie = await getMovieDetails(item['imdbID']);
              if (movie != null) {
                movies.add(movie);
                debugPrint('OMDb Loaded: ${movie.title} - Poster: ${movie.posterUrl.isNotEmpty}');
              }
            } catch (e) {
              debugPrint('OMDb Error loading details for ${item['imdbID']}: $e');
            }
          }
          return movies;
        } else {
          debugPrint('OMDb No results: ${data['Error']}');
          return [];
        }
      } else {
        throw Exception('Ошибка API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('OMDb Search error: $e');
      throw Exception('Ошибка поиска: $e');
    }
  }

  /// Получить детали фильма по IMDB ID
  Future<Movie?> getMovieDetails(String imdbId) async {
    try {
      debugPrint('OMDb Getting details for: $imdbId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/?i=$imdbId&plot=full&apikey=$apiKey'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['Response'] == 'True') {
          debugPrint('OMDb Details loaded: ${data['Title']}');
          return Movie.fromOmdb(data);
        } else {
          debugPrint('OMDb Details error: ${data['Error']}');
          return null;
        }
      }
      return null;
    } catch (e) {
      debugPrint('OMDb Details error: $e');
      return null;
    }
  }

  /// Получить популярные фильмы (комбинация запросов)
  Future<List<Movie>> getPopularMovies() async {
    final popularQueries = ['avengers', 'batman', 'spider', 'iron man', 'thor'];
    List<Movie> movies = [];

    for (var query in popularQueries) {
      try {
        final results = await searchMovies(query);
        movies.addAll(results.take(2));
        if (movies.length >= 12) break;
      } catch (e) {
        debugPrint('OMDb Popular error for $query: $e');
      }
    }

    // Удаляем дубликаты
    final uniqueMovies = <int, Movie>{};
    for (var movie in movies) {
      if (movie.posterUrl.isNotEmpty) {
        uniqueMovies[movie.id] = movie;
      }
    }

    return uniqueMovies.values.take(12).toList();
  }
}
