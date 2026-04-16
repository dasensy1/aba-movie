import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// ============================================================================
/// MOVIES PROVIDER (TMDb API + РАСШИРЕННЫЕ ФИЛЬТРЫ)
/// ============================================================================
/// Провайдер для управления состоянием фильмов
/// Работает с TMDb API
/// Поддерживает расширенные фильтры поиска
/// ============================================================================

class MoviesProvider with ChangeNotifier {
  final TmdbApiService _apiService = TmdbApiService();

  List<Movie> _trendingMovies = [];
  List<Movie> _searchResults = [];
  List<Movie> _filteredResults = []; // Результаты после фильтрации
  List<Movie> _popularMovies = [];
  List<Movie> _topRatedMovies = [];
  List<Movie> _moviesByGenre = [];
  List<Genre> _genres = [];

  // Расширенные фильтры
  SearchFilters _filters = SearchFilters();
  final List<String> _searchHistory = [];

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
  int _genrePage = 1;
  bool _isLoadingMoreGenre = false;

  // Getters
  List<Movie> get trendingMovies => _trendingMovies;
  List<Movie> get searchResults =>
      _filteredResults.isNotEmpty ? _filteredResults : _searchResults;
  List<Movie> get rawSearchResults => _searchResults; // Без фильтрации
  List<Movie> get popularMovies => _popularMovies;
  List<Movie> get topRatedMovies => _topRatedMovies;
  List<Movie> get moviesByGenre => _moviesByGenre;
  List<Genre> get genres => _genres;
  SearchFilters get filters => _filters;
  List<String> get searchHistory => _searchHistory;

  // Общий флаг — true если любая операция грузится
  bool get isLoading =>
      _isLoadingTrending ||
      _isLoadingSearch ||
      _isLoadingPopular ||
      _isLoadingTopRated ||
      _isLoadingGenre;
  bool get isLoadingTrending => _isLoadingTrending;
  bool get isLoadingSearch => _isLoadingSearch;
  bool get isLoadingPopular => _isLoadingPopular;
  bool get isLoadingTopRated => _isLoadingTopRated;
  bool get isLoadingGenre => _isLoadingGenre;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoadingMoreGenre => _isLoadingMoreGenre;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  int get selectedGenreId => _selectedGenreId;

  /// ============================================================================
  /// TRENDING FILMS (TMDb API)
  /// ============================================================================
  Future<void> loadTrendingMovies() async {
    _isLoadingTrending = true;
    _error = null;
    notifyListeners();

    try {
      _trendingMovies = await _apiService.getTrendingMovies();
      _isLoadingTrending = false;
      notifyListeners();
    } catch (e) {
      _error = 'Ошибка загрузки трендов: $e';
      _isLoadingTrending = false;
      notifyListeners();
    }
  }

  /// ============================================================================
  /// ПОИСК (TMDb API)
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
        if (_searchHistory.length > 10) {
          _searchHistory.removeLast();
        }
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
    debugPrint('=== ПРИМЕНЕНИЕ ФИЛЬТРОВ ===');
    debugPrint('Всего результатов поиска: ${_searchResults.length}');
    debugPrint('Фильтр - жанр: "${_filters.selectedGenre}"');
    debugPrint('Фильтр - рейтинг: ${_filters.minRating}');
    debugPrint('Фильтр - год: ${_filters.minYear} - ${_filters.maxYear}');
    debugPrint(
        'Фильтр - сортировка: ${_filters.sortBy} (${_filters.sortAscending ? "возр" : "убыв"})');
    debugPrint('Загружено жанров из TMDb: ${_genres.length}');

    if (_searchResults.isEmpty) {
      _filteredResults = [];
      debugPrint('Результаты пустые - filteredResults очищен');
      return;
    }

    var filtered = _searchResults;
    debugPrint('До фильтрации: ${filtered.length} фильмов');

    // Фильтр по жанру (используем genreIds из Movie)
    if (_filters.selectedGenre.isNotEmpty) {
      // Найдем ID жанра по имени
      final genre = _genres.firstWhere(
        (g) => g.name.toLowerCase() == _filters.selectedGenre.toLowerCase(),
        orElse: () => Genre(id: 0, name: ''),
      );

      debugPrint('Найден жанр "${_filters.selectedGenre}" с ID=${genre.id}');

      if (genre.id > 0) {
        filtered = filtered.where((movie) {
          final hasGenre = movie.genreIds.contains(genre.id);
          if (hasGenre) {
            debugPrint('  ✓ ${movie.title} имеет жанр ID=${genre.id}');
          }
          return hasGenre;
        }).toList();
        debugPrint('После фильтра по жанру: ${filtered.length} фильмов');
      } else {
        debugPrint('Жанр не найден в списке TMDb, используем fallback поиск');
        // Fallback: ищем по названию в overview/title
        filtered = filtered.where((movie) {
          final overview = (movie.overview ?? '').toLowerCase();
          final title = movie.title.toLowerCase();
          return overview.contains(_filters.selectedGenre.toLowerCase()) ||
              title.contains(_filters.selectedGenre.toLowerCase());
        }).toList();
        debugPrint('После fallback фильтра: ${filtered.length} фильмов');
      }
    }

    // Фильтр по рейтингу (minRating)
    if (_filters.minRating > 0) {
      filtered = filtered.where((movie) {
        return movie.voteAverage >= _filters.minRating;
      }).toList();
      debugPrint('После фильтра по рейтингу: ${filtered.length} фильмов');
    }

    // Фильтр по году выпуска
    if (_filters.minYear != null || _filters.maxYear != null) {
      filtered = filtered.where((movie) {
        if (movie.releaseDate == null || movie.releaseDate!.isEmpty) {
          return false;
        }

        try {
          final year = int.tryParse(movie.releaseDate!.substring(0, 4));
          if (year == null) {
            return false;
          }

          if (_filters.minYear != null && year < _filters.minYear!) {
            return false;
          }
          if (_filters.maxYear != null && year > _filters.maxYear!) {
            return false;
          }

          return true;
        } catch (e) {
          return false;
        }
      }).toList();
      debugPrint('После фильтра по году: ${filtered.length} фильмов');
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
    debugPrint(
        '=== ИТОГО после фильтрации: ${_filteredResults.length} фильмов ===');
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
  /// POPULAR FILMS (TMDb API)
  /// ============================================================================
  Future<void> loadPopularMovies() async {
    _isLoadingPopular = true;
    _error = null;
    notifyListeners();

    try {
      _popularMovies = await _apiService.getPopularMovies();
      _isLoadingPopular = false;
      notifyListeners();
    } catch (e) {
      _error = 'Ошибка загрузки популярных: $e';
      _isLoadingPopular = false;
      notifyListeners();
    }
  }

  /// ============================================================================
  /// TOP RATED FILMS (TMDb API)
  /// ============================================================================
  Future<void> loadTopRatedMovies() async {
    _isLoadingTopRated = true;
    _error = null;
    notifyListeners();

    try {
      _topRatedMovies = await _apiService.getTopRatedMovies();
      _isLoadingTopRated = false;
      notifyListeners();
    } catch (e) {
      _error = 'Ошибка загрузки лучших: $e';
      _isLoadingTopRated = false;
      notifyListeners();
    }
  }

  /// ============================================================================
  /// ЖАНРЫ (TMDb API)
  /// ============================================================================
  Future<void> loadGenres() async {
    _isLoadingGenre = true;
    _error = null;
    notifyListeners();

    try {
      _genres = await _apiService.getGenres();
      _isLoadingGenre = false;
      notifyListeners();
    } catch (e) {
      _error = 'Ошибка загрузки жанров: $e';
      _isLoadingGenre = false;
      notifyListeners();
    }
  }

  /// Фильмы по жанру
  Future<void> loadMoviesByGenre(int genreId) async {
    _isLoadingGenre = true;
    _error = null;
    _selectedGenreId = genreId;
    _genrePage = 1;
    notifyListeners();

    try {
      debugPrint('=== ЗАГРУЗКА ФИЛЬМОВ ПО ЖАНРУ ===');
      debugPrint('Genre ID: $genreId');

      _moviesByGenre =
          await _apiService.getMoviesByGenre(genreId, page: _genrePage);
      debugPrint(
          'Загружено ${_moviesByGenre.length} фильмов по жанру ID=$genreId');

      _isLoadingGenre = false;
      notifyListeners();
    } catch (e) {
      _error = 'Ошибка загрузки фильмов: $e';
      _isLoadingGenre = false;
      notifyListeners();
    }
  }

  /// Подгрузка следующей страницы фильмов по жанру
  Future<void> loadMoreMoviesByGenre() async {
    if (_isLoadingMoreGenre || _selectedGenreId <= 0) return;

    _isLoadingMoreGenre = true;
    _genrePage++;
    notifyListeners();

    try {
      final newMovies = await _apiService.getMoviesByGenre(_selectedGenreId,
          page: _genrePage);
      _moviesByGenre.addAll(newMovies);
      _isLoadingMoreGenre = false;
      notifyListeners();
    } catch (e) {
      _error = 'Ошибка подгрузки фильмов: $e';
      _isLoadingMoreGenre = false;
      notifyListeners();
    }
  }

  /// Очистить фильмы по жанру
  void clearMoviesByGenre() {
    _moviesByGenre = [];
    _selectedGenreId = 0;
    _genrePage = 1;
    notifyListeners();
  }

  /// Получить детали фильма по ID (TMDb)
  Future<Movie?> getMovieDetails(int movieId) async {
    try {
      return await _apiService.getMovieDetails(movieId);
    } catch (e) {
      debugPrint('MoviesProvider getMovieDetails error: $e');
      return null;
    }
  }

  /// Получить актеров фильма
  Future<List<Map<String, dynamic>>> getMovieCast(int movieId) async {
    try {
      return await _apiService.getMovieCast(movieId);
    } catch (e) {
      debugPrint('MoviesProvider getMovieCast error: $e');
      return [];
    }
  }

  /// Получить похожие фильмы
  Future<List<Movie>> getSimilarMovies(int movieId) async {
    try {
      return await _apiService.getSimilarMovies(movieId);
    } catch (e) {
      debugPrint('MoviesProvider getSimilarMovies error: $e');
      return [];
    }
  }

  /// Получить рекомендации
  Future<List<Movie>> getRecommendations(int movieId) async {
    try {
      return await _apiService.getRecommendations(movieId);
    } catch (e) {
      debugPrint('MoviesProvider getRecommendations error: $e');
      return [];
    }
  }

  /// Сбросить ошибку
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
