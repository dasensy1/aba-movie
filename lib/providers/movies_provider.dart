import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// ============================================================================
/// MOVIES PROVIDER (OMDb API + DEMO + РАСШИРЕННЫЕ ФИЛЬТРЫ)
/// ============================================================================
/// Провайдер для управления состоянием фильмов
/// Работает с OMDb API и демо-данными
/// Поддерживает расширенные фильтры поиска
/// ============================================================================

class MoviesProvider with ChangeNotifier {
  final OmdbApiService _apiService = OmdbApiService();
  final DemoDataService _demoService = DemoDataService();

  List<Movie> _trendingMovies = [];
  List<Movie> _searchResults = [];
  List<Movie> _filteredResults = []; // Результаты после фильтрации
  List<Movie> _popularMovies = [];
  List<Movie> _topRatedMovies = [];
  List<Movie> _moviesByGenre = [];
  List<Genre> _genres = [];

  // Расширенные фильтры
  SearchFilters _filters = SearchFilters();
  List<String> _searchHistory = [];

  // Разделённые loading-флаги для каждой операции
  bool _isLoadingTrending = false;
  bool _isLoadingSearch = false;
  bool _isLoadingPopular = false;
  bool _isLoadingTopRated = false;
  bool _isLoadingGenre = false;
  final bool _isLoadingMore = false;
  String? _error;
  String _searchQuery = '';
  int _selectedGenreId = 0;

  // Getters
  List<Movie> get trendingMovies => _trendingMovies;
  List<Movie> get searchResults => _filteredResults.isNotEmpty ? _filteredResults : _searchResults;
  List<Movie> get rawSearchResults => _searchResults; // Без фильтрации
  List<Movie> get popularMovies => _popularMovies;
  List<Movie> get topRatedMovies => _topRatedMovies;
  List<Movie> get moviesByGenre => _moviesByGenre;
  List<Genre> get genres => _genres;
  SearchFilters get filters => _filters;
  List<String> get searchHistory => _searchHistory;
  
  // Общий флаг — true если любая операция грузится
  bool get isLoading => _isLoadingTrending || _isLoadingSearch || _isLoadingPopular || _isLoadingTopRated || _isLoadingGenre;
  bool get isLoadingTrending => _isLoadingTrending;
  bool get isLoadingSearch => _isLoadingSearch;
  bool get isLoadingPopular => _isLoadingPopular;
  bool get isLoadingTopRated => _isLoadingTopRated;
  bool get isLoadingGenre => _isLoadingGenre;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  int get selectedGenreId => _selectedGenreId;

  /// ============================================================================
  /// TRENDING FILMS (Now from OMDb API)
  /// ============================================================================
  Future<void> loadTrendingMovies() async {
    _isLoadingTrending = true;
    _error = null;
    notifyListeners();

    try {
      _trendingMovies = await _apiService.getPopularMovies();
      _isLoadingTrending = false;
      notifyListeners();
    } catch (e) {
      _error = 'Ошибка загрузки трендов: $e';
      _isLoadingTrending = false;
      notifyListeners();
    }
  }

  /// ============================================================================
  /// ПОИСК (OMDb API)
  /// ============================================================================
  Future<void> searchMovies(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _filteredResults = [];
      _searchQuery = '';
      _filters = _filters.reset();
      notifyListeners();
      return;
    }

    _isLoadingSearch = true;
    _error = null;
    _searchQuery = query;
    _filters = _filters.copyWith(searchQuery: query);
    notifyListeners();

    try {
      _searchResults = await _apiService.searchMovies(query);
      
      // Добавляем в историю поиска
      if (!_searchHistory.contains(query)) {
        _searchHistory.insert(0, query);
        if (_searchHistory.length > 10) _searchHistory.removeLast();
      }
      
      // Применяем текущие фильтры
      _applyFilters();
      
      _isLoadingSearch = false;
      notifyListeners();
    } catch (e) {
      _error = 'Ошибка поиска: $e';
      _isLoadingSearch = false;
      notifyListeners();
    }
  }

  /// ============================================================================
  /// РАСШИРЕННЫЕ ФИЛЬТРЫ
  /// ============================================================================

  /// Применить фильтры к результатам поиска
  void applyFilters(SearchFilters newFilters) {
    _filters = newFilters;
    _applyFilters();
    notifyListeners();
  }

  /// Сбросить фильтры
  void resetFilters() {
    _filters = _filters.reset();
    _filteredResults = [];
    notifyListeners();
  }

  /// Внутренний метод для применения фильтров
  void _applyFilters() {
    if (_searchResults.isEmpty) {
      _filteredResults = [];
      return;
    }

    var filtered = _searchResults;

    // Фильтр по жанру (если есть genreIds в Movie)
    if (_filters.selectedGenre.isNotEmpty) {
      filtered = filtered.where((movie) {
        // Для OMDb данных жанр может быть в overview или title
        // Проверяем наличие жанра в доступных полях
        final overview = (movie.overview ?? '').toLowerCase();
        final title = movie.title.toLowerCase();
        return overview.contains(_filters.selectedGenre.toLowerCase()) ||
            title.contains(_filters.selectedGenre.toLowerCase());
      }).toList();
    }

    // Фильтр по рейтингу (minRating)
    if (_filters.minRating > 0) {
      filtered = filtered.where((movie) {
        return movie.voteAverage >= _filters.minRating;
      }).toList();
    }

    // Фильтр по году выпуска
    if (_filters.minYear != null || _filters.maxYear != null) {
      filtered = filtered.where((movie) {
        if (movie.releaseDate == null || movie.releaseDate!.isEmpty) return false;
        
        try {
          final year = int.tryParse(movie.releaseDate!.substring(0, 4));
          if (year == null) return false;
          
          if (_filters.minYear != null && year < _filters.minYear!) return false;
          if (_filters.maxYear != null && year > _filters.maxYear!) return false;
          
          return true;
        } catch (e) {
          return false;
        }
      }).toList();
    }

    // Сортировка
    filtered.sort((a, b) {
      int result = 0;
      
      switch (_filters.sortBy) {
        case 'title':
          result = a.title.compareTo(b.title);
          break;
        case 'year':
          final yearA = _extractYear(a.releaseDate);
          final yearB = _extractYear(b.releaseDate);
          result = yearA.compareTo(yearB);
          break;
        case 'rating':
          result = a.voteAverage.compareTo(b.voteAverage);
          break;
      }
      
      return _filters.sortAscending ? result : -result;
    });

    _filteredResults = filtered;
  }

  /// Извлечь год из даты
  int _extractYear(String? date) {
    if (date == null || date.isEmpty) return 0;
    return int.tryParse(date.substring(0, 4)) ?? 0;
  }

  /// Очистить поиск
  void clearSearch() {
    _searchResults = [];
    _filteredResults = [];
    _searchQuery = '';
    _filters = _filters.reset();
    notifyListeners();
  }

  /// ============================================================================
  /// POPULAR FILMS (Now from OMDb API)
  /// ============================================================================
  Future<void> loadPopularMovies() async {
    _isLoadingPopular = true;
    _error = null;
    notifyListeners();

    try {
      _popularMovies = await _apiService.searchMovies('Marvel');
      _isLoadingPopular = false;
      notifyListeners();
    } catch (e) {
      _error = 'Ошибка загрузки популярных: $e';
      _isLoadingPopular = false;
      notifyListeners();
    }
  }

  /// ============================================================================
  /// TOP RATED FILMS (Now from OMDb API)
  /// ============================================================================
  Future<void> loadTopRatedMovies() async {
    _isLoadingTopRated = true;
    _error = null;
    notifyListeners();

    try {
      _topRatedMovies = await _apiService.searchMovies('Star Wars');
      _isLoadingTopRated = false;
      notifyListeners();
    } catch (e) {
      _error = 'Ошибка загрузки лучших: $e';
      _isLoadingTopRated = false;
      notifyListeners();
    }
  }

  /// ============================================================================
  /// ЖАНРЫ
  /// ============================================================================
  Future<void> loadGenres() async {
    _isLoadingTrending = true;
    _error = null;
    notifyListeners();

    try {
      _genres = _demoService.demoGenres;
      _isLoadingTrending = false;
      notifyListeners();
    } catch (e) {
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
      String query = 'action';
      if (genreId == 1) query = 'action';
      if (genreId == 2) query = 'comedy';
      if (genreId == 3) query = 'drama';

      _moviesByGenre = await _apiService.searchMovies(query);
      _isLoadingGenre = false;
      notifyListeners();
    } catch (e) {
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

  /// Получить детали фильма по IMDB ID (через провайдер, не напрямую API)
  Future<Movie?> getMovieDetails(String imdbId) async {
    try {
      return await _apiService.getMovieDetails(imdbId);
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
