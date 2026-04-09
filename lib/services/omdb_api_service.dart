import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/models.dart';

/// ============================================================================
/// OMDb API SERVICE — HTTPS, fallback API key
/// ============================================================================

class OmdbApiService {
  static final OmdbApiService _instance = OmdbApiService._internal();
  factory OmdbApiService() => _instance;
  OmdbApiService._internal();

  // Fallback ключ, если .env не загружен
  static const String _fallbackKey = '4310ed30';
  static const String _baseUrl = 'https://www.omdbapi.com';

  String get _apiKey => _fallbackKey;

  /// Поиск фильмов по названию
  Future<List<Movie>> searchMovies(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      debugPrint('OMDb Search: $query');

      final url = '$_baseUrl/?s=${Uri.encodeComponent(query)}&apikey=$_apiKey';
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['Response'] == 'True' && data['Search'] != null) {
          final results = data['Search'] as List;

          final movies = <Movie>[];
          for (var item in results) {
            if (item['imdbID'] != null) {
              movies.add(Movie.fromOmdb(item));
            }
          }
          return movies;
        }
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('Ключ API не активирован или недействителен (401)');
      }
      return [];
    } catch (e) {
      debugPrint('OMDb Search error: $e');
      rethrow;
    }
  }

  /// Получить детали фильма по IMDB ID
  Future<Movie?> getMovieDetails(String imdbId) async {
    try {
      debugPrint('OMDb Getting full details for: $imdbId');
      final response = await http.get(
        Uri.parse('$_baseUrl/?i=$imdbId&plot=full&apikey=$_apiKey'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['Response'] == 'True') {
          return Movie.fromOmdb(data);
        }
      }
      return null;
    } catch (e) {
      debugPrint('OMDb Details error: $e');
      return null;
    }
  }

  /// Получить популярные фильмы
  Future<List<Movie>> getPopularMovies() async {
    return searchMovies('2024');
  }
}
