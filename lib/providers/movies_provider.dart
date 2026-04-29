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
  List<Movie> get searchResults => _filteredResults;
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
       // Convert genre name to ID
       int? genreId;
       if (_filters.selectedGenre.isNotEmpty) {
         final genre = _genres.firstWhere(
           (g) => g.name.toLowerCase() == _filters.selectedGenre.toLowerCase(),
           orElse: () => Genre(id: 0, name: ''),
         );
         if (genre.id > 0) {
           genreId = genre.id;
         }
       }

        // Fetch from API with all filters applied server-side
        _searchResults = await _apiService.searchMovies(
          query: query,
          genreId: genreId,
          minYear: _filters.minYear,
          maxYear: _filters.maxYear,
          minRating: _filters.minRating > 0 ? _filters.minRating : null,
          sortBy: _filters.sortBy,
          sortAscending: _filters.sortAscending,
        );

        // Add to search history
        if (!_searchHistory.contains(query)) {
          _searchHistory.insert(0, query);
          if (_searchHistory.length > 10) {
            _searchHistory.removeLast();
          }
        }

        // Apply client-side rating filter since TMDb search endpoint doesn't support vote_average.gte
        List<Movie> filteredResults = _searchResults;
        if (_filters.minRating > 0) {
          filteredResults = _searchResults
              .where((movie) => movie.voteAverage >= _filters.minRating)
              .toList();
          debugPrint(
              'Client-side rating filter (minRating=${_filters.minRating}): ${_searchResults.length} -> ${filteredResults.length}');
        }

        _filteredResults = filteredResults;
        _isLoadingSearch = false;
        notifyListeners();
      } catch (e) {
        _error = 'Ошибка поиска: $e';
        _isLoadingSearch = false;
        notifyListeners();
      }
    }

    /// Применить фильтры к результатам поиска
    void applyFilters(SearchFilters newFilters) {
      _filters = newFilters;
      
      // If there's an active search query, re-fetch with new filters
      if (_searchQuery.isNotEmpty) {
        _isLoadingSearch = true;
        notifyListeners();
        
        // Convert genre name to ID
        int? genreId;
        if (_filters.selectedGenre.isNotEmpty) {
          final genre = _genres.firstWhere(
            (g) => g.name.toLowerCase() == _filters.selectedGenre.toLowerCase(),
            orElse: () => Genre(id: 0, name: ''),
          );
          if (genre.id > 0) {
            genreId = genre.id;
          }
        }
        
          _apiService
              .searchMovies(
                query: _searchQuery,
                genreId: genreId,
                minYear: _filters.minYear,
                maxYear: _filters.maxYear,
                minRating: _filters.minRating > 0 ? _filters.minRating : null,
                sortBy: _filters.sortBy,
                sortAscending: _filters.sortAscending,
              )
              .then((results) {
                debugPrint('=== API RESPONSE RECEIVED ===');
                debugPrint('Total results from API: ${results.length}');
                debugPrint('Filter applied: minRating=${_filters.minRating}');
                if (results.isNotEmpty) {
                  debugPrint('Sample ratings: ${results.take(5).map((m) => m.voteAverage).toList()}');
                }

                // Apply client-side rating filter since TMDb search endpoint doesn't support vote_average.gte
                List<Movie> filteredResults = results;
                if (_filters.minRating > 0) {
                  filteredResults = results
                      .where((movie) => movie.voteAverage >= _filters.minRating)
                      .toList();
                  debugPrint('After client-side rating filter: ${filteredResults.length} results');
                }

                // Apply client-side title sort if needed (TMDb doesn't support server-side title sort)
                if (_filters.sortBy == 'title') {
                  filteredResults.sort((a, b) => a.title.compareTo(b.title));
                  if (!_filters.sortAscending) {
                    filteredResults = filteredResults.reversed.toList();
                  }
                }

                _searchResults = results;
                _filteredResults = filteredResults;
                _isLoadingSearch = false;
                notifyListeners();
              })
            .catchError((e) {
              _error = 'Ошибка поиска: $e';
              _isLoadingSearch = false;
              notifyListeners();
            });
      } else {
        // No active search, just update filter state
        notifyListeners();
      }
    }

    /// Сбросить фильтры
    void resetFilters() {
      _filters = _filters.reset();
      _filteredResults = [];
      
      // Re-fetch search results with no filters if there's an active query
      if (_searchQuery.isNotEmpty) {
        _isLoadingSearch = true;
        notifyListeners();
        _apiService
            .searchMovies(
              query: _searchQuery,
            )
            .then((results) {
              _searchResults = results;
              _filteredResults = results;
              _isLoadingSearch = false;
              notifyListeners();
            })
            .catchError((e) {
              _error = 'Ошибка поиска: $e';
              _isLoadingSearch = false;
              notifyListeners();
            });
      } else {
        notifyListeners();
      }
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
