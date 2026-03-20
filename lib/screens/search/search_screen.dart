import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../movie_detail_screen.dart';

/// ============================================================================
/// SEARCH SCREEN
/// ============================================================================
/// Вкладка поиска фильмов с живым вводом
/// ============================================================================

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Поиск с задержкой (debounce)
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (query.trim().isNotEmpty) {
        context.read<MoviesProvider>().searchMovies(query);
      } else {
        context.read<MoviesProvider>().clearSearch();
      }
    });
  }

  /// Очистить поиск
  void _clearSearch() {
    _searchController.clear();
    context.read<MoviesProvider>().clearSearch();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Поле поиска
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Поиск фильмов...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Consumer<MoviesProvider>(
                  builder: (context, movies, _) {
                    if (_searchController.text.isNotEmpty ||
                        movies.searchResults.isNotEmpty) {
                      return IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (query) {
                if (query.trim().isNotEmpty) {
                  context.read<MoviesProvider>().searchMovies(query);
                }
              },
            ),
          ),
          // Результаты
          Expanded(
            child: Consumer<MoviesProvider>(
              builder: (context, moviesProvider, _) {
                // Загрузка
                if (moviesProvider.isLoading) {
                  return const LoadingIndicator(message: 'Поиск...');
                }

                // Ошибка
                if (moviesProvider.error != null) {
                  return CustomErrorWidget(
                    message: moviesProvider.error!,
                    onRetry: () =>
                        moviesProvider.searchMovies(moviesProvider.searchQuery),
                  );
                }

                // Пустой результат
                if (moviesProvider.searchResults.isEmpty) {
                  if (moviesProvider.searchQuery.isEmpty) {
                    return _buildEmptyState();
                  }
                  return EmptyStateWidget(
                    title: 'Ничего не найдено',
                    subtitle: 'Попробуйте другой поисковый запрос',
                    icon: Icons.search_off,
                  );
                }

                // Результаты поиска
                return _buildSearchResults(moviesProvider.searchResults);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Пустое состояние
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          Text(
            'Введите название фильма',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'для поиска',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          // Популярные запросы
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildSearchChip('Начало'),
              _buildSearchChip('Матрица'),
              _buildSearchChip('Бойцовский'),
              _buildSearchChip('Криминальное'),
              _buildSearchChip('Леон'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchChip(String label) {
    return ActionChip(
      label: Text(label),
      backgroundColor: const Color(0xFF1A1A1A),
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
      onPressed: () {
        _searchController.text = label;
        context.read<MoviesProvider>().searchMovies(label);
      },
    );
  }

  /// Результаты поиска
  Widget _buildSearchResults(List<dynamic> movies) {
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
        return Consumer<FavoritesProvider>(
          builder: (context, favorites, _) {
            final isFav = favorites.favorites.any((m) => m.id == movie.id);
            return MovieCardVertical(
              movie: movie,
              isFavorite: isFav,
              onFavoriteTap: () => favorites.toggleFavorite(movie),
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
      },
    );
  }
}
