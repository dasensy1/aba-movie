import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/models.dart';

/// ============================================================================
/// TMDB API SERVICE — The Movie Database API v3
/// ============================================================================
/// API ключ — JWT Bearer Token (v4 auth)
/// ============================================================================

class TmdbApiService {
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _imageBase = 'https://image.tmdb.org/t/p/';
  // JWT Bearer Token
  static const String _bearerToken = 'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI1MTBkZmEwMDc4MzIwYjEwZWRkZWE4NDA4N2NiYWQ1NCIsIm5iZiI6MTc3NTgwMDcwMS4wMTcsInN1YiI6IjY5ZDg5MTdkYzc2MmQ3M2NjMWJmZjBjZCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.KwDLhT2Gg4KoC8S1HXMWjapB6xnliLzMbhP5rE0xacA';

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_bearerToken',
    'Content-Type': 'application/json',
    'accept': 'application/json',
  };

  /// Получить тренды (trending movies за неделю)
  Future<List<Movie>> getTrendingMovies() async {
    try {
      debugPrint('TMDB Trending movies');
      final url = '$_baseUrl/trending/movie/week?language=ru-RU';
      final response = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((e) => Movie.fromTmdb(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('TMDB Trending error: $e');
      return [];
    }
  }

  /// Получить популярные фильмы
  Future<List<Movie>> getPopularMovies() async {
    try {
      debugPrint('TMDB Popular movies');
      final url = '$_baseUrl/movie/popular?language=ru-RU';
      final response = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((e) => Movie.fromTmdb(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('TMDB Popular error: $e');
      return [];
    }
  }

  /// Получить фильмы с высоким рейтингом
  Future<List<Movie>> getTopRatedMovies() async {
    try {
      debugPrint('TMDB Top rated movies');
      final url = '$_baseUrl/movie/top_rated?language=ru-RU';
      final response = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((e) => Movie.fromTmdb(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('TMDB Top rated error: $e');
      return [];
    }
  }

  /// Поиск фильмов с поддержкой фильтров
  Future<List<Movie>> searchMovies(String query, {int? year, String? genre, String? sortBy}) async {
    if (query.trim().isEmpty && (year == null && genre == null)) return [];

    try {
      debugPrint('TMDB Search: query="$query" year=$year genre=$genre sort=$sortBy');

      String url;
      if (query.trim().isNotEmpty) {
        url = '$_baseUrl/search/movie?query=${Uri.encodeComponent(query)}&language=ru-RU';
        if (year != null) url += '&year=$year';
        if (genre != null) url += '&with_genres=$genre';
      } else if (genre != null) {
        url = '$_baseUrl/discover/movie?language=ru-RU&with_genres=$genre';
      } else {
        url = '$_baseUrl/discover/movie?language=ru-RU&year=$year';
      }
      if (sortBy != null && sortBy.isNotEmpty) url += '&sort_by=$sortBy';

      final response = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((e) => Movie.fromTmdb(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('TMDB Search error: $e');
      return [];
    }
  }

  /// Фильмы по жанру (discover)
  Future<List<Movie>> getMoviesByGenre(int genreId, {String sortBy = 'popularity.desc'}) async {
    try {
      debugPrint('TMDB Movies by genre: $genreId');
      final url = '$_baseUrl/discover/movie?language=ru-RU&with_genres=$genreId&sort_by=$sortBy';
      final response = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((e) => Movie.fromTmdb(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('TMDB Genre error: $e');
      return [];
    }
  }

  /// Получить детали фильма (с полным синопсисом)
  Future<Movie?> getMovieDetails(int tmdbId) async {
    try {
      debugPrint('TMDB Movie details: $tmdbId');
      // Запрашиваем дополнительные поля: video-ключи, casting-инфо
      final url = '$_baseUrl/movie/$tmdbId?language=ru-RU&append_to_response=videos,credits';
      final response = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Movie.fromTmdb(data);
      }
      return null;
    } catch (e) {
      debugPrint('TMDB Details error: $e');
      return null;
    }
  }

  /// Получить жанры
  Future<List<Genre>> getGenres() async {
    try {
      debugPrint('TMDB Genres');
      final url = '$_baseUrl/genre/movie/list?language=ru-RU';
      final response = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['genres'] as List;
        return results.map((e) => Genre(id: e['id'], name: e['name'])).toList();
      }
      return [];
    } catch (e) {
      debugPrint('TMDB Genres error: $e');
      return [];
    }
  }

  /// URL для постера
  static String getPosterUrl(String? path, {String size = 'w500'}) {
    if (path == null || path.isEmpty) return '';
    return '$_imageBase$path';
  }

  /// URL для backdrop
  static String getBackdropUrl(String? path, {String size = 'original'}) {
    if (path == null || path.isEmpty) return '';
    return '$_imageBase$path';
  }
}
