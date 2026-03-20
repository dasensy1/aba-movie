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
  static const String baseUrl = 'http://www.omdbapi.com';

  /// Поиск фильмов по названию
  Future<List<Movie>> searchMovies(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      debugPrint('OMDb Search: $query');
      
      final url = '$baseUrl/?s=${Uri.encodeComponent(query)}&apikey=$apiKey';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['Response'] == 'True' && data['Search'] != null) {
          final results = data['Search'] as List;
          
          List<Movie> movies = [];
          for (var item in results) {
            if (item['imdbID'] != null) {
              // В результатах поиска OMDb нет Plot, поэтому создаем объект
              // Но для главного экрана это нормально. 
              // Полное описание загрузится при переходе на экран деталей.
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
        Uri.parse('$baseUrl/?i=$imdbId&plot=full&apikey=$apiKey'),
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
