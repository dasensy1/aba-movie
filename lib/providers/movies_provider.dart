import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// ============================================================================
/// MOVIES PROVIDER (OMDb API + DEMO)
/// ============================================================================
/// Провайдер для управления состоянием фильмов
/// Работает с OMDb API и демо-данными
/// ============================================================================

class MoviesProvider with ChangeNotifier {
  final OmdbApiService _apiService = OmdbApiService();
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
  /// TRENDING FILMS (Now from OMDb API)
  /// ============================================================================
  Future<void> loadTrendingMovies() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Загружаем реальные данные из OMDb вместо демо
      _trendingMovies = await _apiService.getPopularMovies();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Ошибка загрузки трендов: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ============================================================================
  /// ПОИСК (OMDb API)
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

    try {
      _searchResults = await _apiService.searchMovies(query);
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
  /// POPULAR FILMS (Now from OMDb API)
  /// ============================================================================
  Future<void> loadPopularMovies() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Используем поисковый запрос для популярных новинок
      _popularMovies = await _apiService.searchMovies('Marvel');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Ошибка загрузки популярных: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ============================================================================
  /// TOP RATED FILMS (Now from OMDb API)
  /// ============================================================================
  Future<void> loadTopRatedMovies() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Используем поисковый запрос для классики
      _topRatedMovies = await _apiService.searchMovies('Star Wars');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Ошибка загрузки лучших: $e';
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

    try {
      // Имитируем жанры через поиск по ключевым словам
      String query = 'action';
      if (genreId == 1) query = 'action';
      if (genreId == 2) query = 'comedy';
      if (genreId == 3) query = 'drama';
      
      _moviesByGenre = await _apiService.searchMovies(query);
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
