import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// ============================================================================
/// MOVIES PROVIDER (TMDB API + DEMO fallback)
/// ============================================================================

class MoviesProvider with ChangeNotifier {
  final TmdbApiService _apiService = TmdbApiService();
  final DemoDataService _demoService = DemoDataService();

  List<Movie> _trendingMovies = [];
  List<Movie> _searchResults = [];
  List<Movie> _popularMovies = [];
  List<Movie> _topRatedMovies = [];
  List<Movie> _moviesByGenre = [];
  List<Genre> _genres = [];

  bool _isLoadingTrending = false;
  bool _isLoadingSearch = false;
  bool _isLoadingPopular = false;
  bool _isLoadingTopRated = false;
  bool _isLoadingGenre = false;
  String? _error;
  String _searchQuery = '';
  int _selectedGenreId = 0;

  // Filters
  int? _filterYear;
  String? _filterGenre;
  String _filterSortBy = 'popularity.desc';

  // Getters
  List<Movie> get trendingMovies => _trendingMovies;
  List<Movie> get searchResults => _searchResults;
  List<Movie> get popularMovies => _popularMovies;
  List<Movie> get topRatedMovies => _topRatedMovies;
  List<Movie> get moviesByGenre => _moviesByGenre;
  List<Genre> get genres => _genres;
  bool get isLoading => _isLoadingTrending || _isLoadingSearch || _isLoadingPopular || _isLoadingTopRated || _isLoadingGenre;
  bool get isLoadingTrending => _isLoadingTrending;
  bool get isLoadingSearch => _isLoadingSearch;
  bool get isLoadingPopular => _isLoadingPopular;
  bool get isLoadingTopRated => _isLoadingTopRated;
  bool get isLoadingGenre => _isLoadingGenre;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  int get selectedGenreId => _selectedGenreId;

  // Filter getters
  int? get filterYear => _filterYear;
  String? get filterGenre => _filterGenre;
  String get filterSortBy => _filterSortBy;

  /// TRENDING FILMS
  Future<void> loadTrendingMovies() async {
    _isLoadingTrending = true;
    _error = null;
    notifyListeners();

    try {
      _trendingMovies = await _apiService.getTrendingMovies();
      if (_trendingMovies.isEmpty) {
        _trendingMovies = _demoService.getTrendingMovies();
      }
      _isLoadingTrending = false;
      notifyListeners();
    } catch (e) {
      _trendingMovies = _demoService.getTrendingMovies();
      _error = 'Ошибка загрузки трендов: $e';
      _isLoadingTrending = false;
      notifyListeners();
    }
  }

  /// ПОИСК с фильтрами
  Future<void> searchMovies(String query, {int? year, String? genre, String? sortBy}) async {
    _filterYear = year ?? _filterYear;
    _filterGenre = genre ?? _filterGenre;
    _filterSortBy = sortBy ?? _filterSortBy;

    if (query.trim().isEmpty && (_filterYear == null && _filterGenre == null)) {
      _searchResults = [];
      _searchQuery = '';
      notifyListeners();
      return;
    }

    _isLoadingSearch = true;
    _error = null;
    _searchQuery = query;
    notifyListeners();

    try {
      _searchResults = await _apiService.searchMovies(
        query,
        year: _filterYear,
        genre: _filterGenre,
        sortBy: _filterSortBy,
      );
      _isLoadingSearch = false;
      notifyListeners();
    } catch (e) {
      // Fallback на демо-данные
      _searchResults = _demoService.searchMovies(query);
      _error = 'Ошибка поиска: $e';
      _isLoadingSearch = false;
      notifyListeners();
    }
  }

  /// Сбросить фильтры
  void resetFilters() {
    _filterYear = null;
    _filterGenre = null;
    _filterSortBy = 'popularity.desc';
    notifyListeners();
  }

  /// Установить фильтр по году
  void setYearFilter(int? year) {
    _filterYear = year;
    notifyListeners();
  }

  /// Установить фильтр по жанру
  void setGenreFilter(String? genreId) {
    _filterGenre = genreId;
    notifyListeners();
  }

  /// Установить сортировку
  void setSortBy(String sortBy) {
    _filterSortBy = sortBy;
    notifyListeners();
  }

  /// Очистить поиск
  void clearSearch() {
    _searchResults = [];
    _searchQuery = '';
    _filterYear = null;
    _filterGenre = null;
    _filterSortBy = 'popularity.desc';
    notifyListeners();
  }

  /// POPULAR FILMS
  Future<void> loadPopularMovies() async {
    _isLoadingPopular = true;
    _error = null;
    notifyListeners();

    try {
      _popularMovies = await _apiService.getPopularMovies();
      if (_popularMovies.isEmpty) {
        _popularMovies = _demoService.getPopularMovies();
      }
      _isLoadingPopular = false;
      notifyListeners();
    } catch (e) {
      _popularMovies = _demoService.getPopularMovies();
      _error = 'Ошибка загрузки популярных: $e';
      _isLoadingPopular = false;
      notifyListeners();
    }
  }

  /// TOP RATED FILMS
  Future<void> loadTopRatedMovies() async {
    _isLoadingTopRated = true;
    _error = null;
    notifyListeners();

    try {
      _topRatedMovies = await _apiService.getTopRatedMovies();
      if (_topRatedMovies.isEmpty) {
        _topRatedMovies = _demoService.getTopRatedMovies();
      }
      _isLoadingTopRated = false;
      notifyListeners();
    } catch (e) {
      _topRatedMovies = _demoService.getTopRatedMovies();
      _error = 'Ошибка загрузки лучших: $e';
      _isLoadingTopRated = false;
      notifyListeners();
    }
  }

  /// ЖАНРЫ из TMDB
  Future<void> loadGenres() async {
    _isLoadingTrending = true;
    _error = null;
    notifyListeners();

    try {
      _genres = await _apiService.getGenres();
      if (_genres.isEmpty) {
        _genres = _demoService.demoGenres;
      }
      _isLoadingTrending = false;
      notifyListeners();
    } catch (e) {
      _genres = _demoService.demoGenres;
      _error = 'Ошибка загрузки жанров: $e';
      _isLoadingTrending = false;
      notifyListeners();
    }
  }

  /// Фильмы по жанру
  Future<void> loadMoviesByGenre(int genreId) async {
    _isLoadingGenre = true;
    _error = null;
    _selectedGenreId = genreId;
    notifyListeners();

    try {
      _moviesByGenre = await _apiService.getMoviesByGenre(genreId);
      _isLoadingGenre = false;
      notifyListeners();
    } catch (e) {
      _moviesByGenre = _demoService.getMoviesByGenre(genreId);
      _error = 'Ошибка загрузки фильмов: $e';
      _isLoadingGenre = false;
      notifyListeners();
    }
  }

  /// Очистить фильмы по жанру
  void clearMoviesByGenre() {
    _moviesByGenre = [];
    _selectedGenreId = 0;
    notifyListeners();
  }

  /// Получить детали фильма
  Future<Movie?> getMovieDetails(int tmdbId) async {
    try {
      return await _apiService.getMovieDetails(tmdbId);
    } catch (e) {
      debugPrint('MoviesProvider getMovieDetails error: $e');
      return null;
    }
  }

  /// Сбросить ошибку
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
