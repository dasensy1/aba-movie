import 'dart:convert';
import 'package:http/http.dart' as http;
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
  static const String baseUrl = 'http://www.omdbapi.com';

  /// Поиск фильмов по названию
  Future<List<Movie>> searchMovies(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/?s=${Uri.encodeComponent(query)}&apikey=$apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['Response'] == 'True' && data['Search'] != null) {
          final results = data['Search'] as List;
          
          // Загружаем детали для каждого фильма
          List<Movie> movies = [];
          for (var item in results) {
            final movie = await getMovieDetails(item['imdbID']);
            if (movie != null) {
              movies.add(movie);
            }
          }
          return movies;
        }
        return [];
      } else {
        throw Exception('Ошибка API: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка поиска: $e');
    }
  }

  /// Получить детали фильма по IMDB ID
  Future<Movie?> getMovieDetails(String imdbId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/?i=$imdbId&plot=full&apikey=$apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['Response'] == 'True') {
          return Movie.fromOmdb(data);
        }
        return null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Получить тренды (популярные фильмы)
  Future<List<Movie>> getPopularMovies() async {
    // OMDb не имеет endpoint для трендов, используем поиск популярных запросов
    final popularQueries = ['marvel', 'batman', 'avatar', 'inception', 'matrix'];
    List<Movie> movies = [];
    
    for (var query in popularQueries) {
      try {
        final results = await searchMovies(query);
        movies.addAll(results.take(2));
      } catch (e) {
        // Игнорируем ошибки
      }
    }
    
    // Удаляем дубликаты по ID
    final uniqueMovies = <int, Movie>{};
    for (var movie in movies) {
      uniqueMovies[movie.id] = movie;
    }
    
    return uniqueMovies.values.take(12).toList();
  }
}
