import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// ============================================================================
/// MOVIES PROVIDER (ЛОКАЛЬНЫЕ ДАННЫЕ)
/// ============================================================================
/// Провайдер для управления состоянием фильмов
/// Работает с демо-данными без внешнего API
/// ============================================================================

class MoviesProvider with ChangeNotifier {
  final DemoDataService _demoService = DemoDataService();
  final LocalDatabaseService _dbService = LocalDatabaseService();

  List<Movie> _trendingMovies = [];
  List<Movie> _searchResults = [];
  List<Movie> _popularMovies = [];
  List<Movie> _topRatedMovies = [];
  List<Movie> _moviesByGenre = [];
  List<Genre> _genres = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String _searchQuery = '';
  int _selectedGenreId = 0;

  // Getters
  List<Movie> get trendingMovies => _trendingMovies;
  List<Movie> get searchResults => _searchResults;
  List<Movie> get popularMovies => _popularMovies;
  List<Movie> get topRatedMovies => _topRatedMovies;
  List<Movie> get moviesByGenre => _moviesByGenre;
  List<Genre> get genres => _genres;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  int get selectedGenreId => _selectedGenreId;

  /// ============================================================================
  /// TRENDING FILMS
  /// ============================================================================
  Future<void> loadTrendingMovies() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500)); // Имитация задержки

    try {
      _trendingMovies = _demoService.getTrendingMovies();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Ошибка загрузки: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ============================================================================
  /// ПОИСК
  /// ============================================================================
  Future<void> searchMovies(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _searchQuery = '';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _searchQuery = query;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300)); // Имитация задержки

    try {
      _searchResults = _demoService.searchMovies(query);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Ошибка поиска: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Очистить поиск
  void clearSearch() {
    _searchResults = [];
    _searchQuery = '';
    notifyListeners();
  }

  /// ============================================================================
  /// POPULAR FILMS
  /// ============================================================================
  Future<void> loadPopularMovies() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    try {
      _popularMovies = _demoService.getPopularMovies();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Ошибка загрузки: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ============================================================================
  /// TOP RATED FILMS
  /// ============================================================================
  Future<void> loadTopRatedMovies() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    try {
      _topRatedMovies = _demoService.getTopRatedMovies();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Ошибка загрузки: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ============================================================================
  /// ЖАНРЫ
  /// ============================================================================
  Future<void> loadGenres() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    try {
      _genres = _demoService.demoGenres;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Ошибка загрузки жанров: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Фильмы по жанру
  Future<void> loadMoviesByGenre(int genreId) async {
    _isLoading = true;
    _error = null;
    _selectedGenreId = genreId;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    try {
      _moviesByGenre = _demoService.getMoviesByGenre(genreId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Ошибка загрузки фильмов: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Очистить фильмы по жанру
  void clearMoviesByGenre() {
    _moviesByGenre = [];
    _selectedGenreId = 0;
    notifyListeners();
  }

  /// Сбросить ошибку
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
