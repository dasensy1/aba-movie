// ============================================================================
// SEARCH FILTERS MODEL
// ============================================================================
// Модель для хранения параметров расширенного поиска
// ============================================================================

class SearchFilters {
  final String searchQuery;
  final String selectedGenre;
  final double minRating;
  final int? minYear;
  final int? maxYear;
  final String sortBy; // 'title', 'year', 'rating'
  final bool sortAscending;

  SearchFilters({
    this.searchQuery = '',
    this.selectedGenre = '',
    this.minRating = 0.0,
    this.minYear,
    this.maxYear,
    this.sortBy = 'title',
    this.sortAscending = true,
  });

  bool get hasActiveFilters {
    return searchQuery.isNotEmpty ||
        selectedGenre.isNotEmpty ||
        minRating > 0 ||
        minYear != null ||
        maxYear != null;
  }

  SearchFilters copyWith({
    String? searchQuery,
    String? selectedGenre,
    double? minRating,
    int? minYear,
    int? maxYear,
    String? sortBy,
    bool? sortAscending,
  }) {
    return SearchFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedGenre: selectedGenre ?? this.selectedGenre,
      minRating: minRating ?? this.minRating,
      minYear: minYear,
      maxYear: maxYear,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  /// Сбросить все фильтры
  SearchFilters reset() {
    return SearchFilters();
  }

  /// Количество активных фильтров (для бейджа)
  int get activeFiltersCount {
    int count = 0;
    if (selectedGenre.isNotEmpty) count++;
    if (minRating > 0) count++;
    if (minYear != null || maxYear != null) count++;
    return count;
  }

  Map<String, dynamic> toMap() {
    return {
      'searchQuery': searchQuery,
      'selectedGenre': selectedGenre,
      'minRating': minRating,
      'minYear': minYear,
      'maxYear': maxYear,
      'sortBy': sortBy,
      'sortAscending': sortAscending,
    };
  }

  factory SearchFilters.fromMap(Map<String, dynamic> map) {
    return SearchFilters(
      searchQuery: map['searchQuery'] ?? '',
      selectedGenre: map['selectedGenre'] ?? '',
      minRating: map['minRating']?.toDouble() ?? 0.0,
      minYear: map['minYear'],
      maxYear: map['maxYear'],
      sortBy: map['sortBy'] ?? 'title',
      sortAscending: map['sortAscending'] ?? true,
    );
  }
}
