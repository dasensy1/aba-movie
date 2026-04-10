import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../movie_detail_screen.dart';

/// ============================================================================
/// SEARCH SCREEN — с фильтрами и адаптивным дизайном
/// ============================================================================

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;
  bool _showFilters = false;
  int? _selectedYear;
  String? _selectedGenreId;
  String _selectedSort = 'popularity.desc';

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) {
    final moviesProvider = context.read<MoviesProvider>();
    moviesProvider.searchMovies(
      query,
      year: _selectedYear,
      genre: _selectedGenreId,
      sortBy: _selectedSort,
    );
  }

  void _clearSearch() {
    _searchController.clear();
    _selectedYear = null;
    _selectedGenreId = null;
    _selectedSort = 'popularity.desc';
    context.read<MoviesProvider>().clearSearch();
    _focusNode.unfocus();
  }

  void _applyFilters() {
    final query = _searchController.text.trim();
    _performSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
            },
            tooltip: 'Фильтры',
          ),
        ],
      ),
      body: Column(
        children: [
          // Поле поиска
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Поиск фильмов...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: Consumer<MoviesProvider>(
                  builder: (context, movies, _) {
                    if (_searchController.text.isNotEmpty ||
                        movies.searchResults.isNotEmpty) {
                      return IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: _clearSearch,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: _performSearch,
            ),
          ),

          // Панель фильтров
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildFiltersPanel(),
            crossFadeState: _showFilters ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),

          // Результаты
          Expanded(
            child: Consumer<MoviesProvider>(
              builder: (context, moviesProvider, _) {
                if (moviesProvider.isLoadingSearch) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Ищем фильмы...'),
                      ],
                    ),
                  );
                }

                if (moviesProvider.error != null && moviesProvider.searchResults.isEmpty) {
                  return _buildErrorState(moviesProvider.error!);
                }

                if (moviesProvider.searchResults.isEmpty) {
                  if (moviesProvider.searchQuery.isEmpty && _selectedYear == null && _selectedGenreId == null) {
                    return _buildEmptyState();
                  }
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Ничего не найдено', style: TextStyle(fontSize: 18)),
                        SizedBox(height: 8),
                        Text('Попробуйте изменить запрос или фильтры', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return _buildResults(moviesProvider.searchResults, isWide);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    final moviesProvider = context.read<MoviesProvider>();
    final genres = moviesProvider.genres;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, size: 20),
              const SizedBox(width: 8),
              const Text('Фильтры', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedYear = null;
                    _selectedGenreId = null;
                    _selectedSort = 'popularity.desc';
                  });
                  _applyFilters();
                },
                child: const Text('Сбросить'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Жанры
          if (genres.isNotEmpty) ...[
            const Text('Жанр', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: genres.take(10).map((genre) {
                final isSelected = _selectedGenreId == genre.id.toString();
                return ChoiceChip(
                  label: Text(genre.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedGenreId = selected ? genre.id.toString() : null;
                    });
                    _applyFilters();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Год
          const Text('Год', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildYearChip(null),
              _buildYearChip(DateTime.now().year),
              _buildYearChip(DateTime.now().year - 1),
              _buildYearChip(DateTime.now().year - 2),
              _buildYearChip(DateTime.now().year - 5),
              _buildYearChip(2020),
              _buildYearChip(2015),
              _buildYearChip(2010),
              _buildYearChip(2000),
            ],
          ),
          const SizedBox(height: 12),

          // Сортировка
          const Text('Сортировка', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSortChip('popularity.desc', 'По популярности ↓'),
              _buildSortChip('popularity.asc', 'По популярности ↑'),
              _buildSortChip('vote_average.desc', 'По рейтингу ↓'),
              _buildSortChip('vote_average.asc', 'По рейтингу ↑'),
              _buildSortChip('release_date.desc', 'По дате ↓'),
              _buildSortChip('release_date.asc', 'По дате ↑'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYearChip(int? year) {
    final label = year == null ? 'Все' : year.toString();
    final isSelected = _selectedYear == year;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedYear = year);
        _applyFilters();
      },
    );
  }

  Widget _buildSortChip(String value, String label) {
    final isSelected = _selectedSort == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedSort = value);
        _applyFilters();
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_rounded, size: 56, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Text(
              'Найдите свой фильм',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Введите название или используйте фильтры',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSearchChip('Начало'),
                _buildSearchChip('Интерстеллар'),
                _buildSearchChip('Матрица'),
                _buildSearchChip('Бойцовский клуб'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchChip(String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        _searchController.text = label;
        _performSearch(label);
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Ошибка загрузки', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _performSearch(_searchController.text),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(List<dynamic> movies, bool isWide) {
    if (isWide) {
      return GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.55,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return _buildMovieCard(movie);
        },
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.55,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        return _buildMovieCard(movie);
      },
    );
  }

  Widget _buildMovieCard(dynamic movie) {
    return Consumer<FavoritesProvider>(
      builder: (context, favorites, _) {
        final isFav = favorites.favorites.any((m) => m.id == movie.id);
        return MovieCardVertical(
          movie: movie,
          isFavorite: isFav,
          onFavoriteTap: () {
            final auth = context.read<AuthProvider>();
            favorites.toggleFavorite(movie, auth.userId);
          },
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MovieDetailScreen(movie: movie),
              ),
            );
          },
        );
      },
    );
  }
}
