import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../movie_detail_screen.dart';

/// ============================================================================
/// CATEGORIES SCREEN
/// ============================================================================
/// Вкладка категорий (жанров) фильмов
/// ============================================================================

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  int? _selectedGenreId;

  @override
  void initState() {
    super.initState();
    _loadGenres();
  }

  Future<void> _loadGenres() async {
    final provider = context.read<MoviesProvider>();
    if (provider.genres.isEmpty) {
      provider.loadGenres();
    }
  }

  void _onGenreSelected(int genreId, String genreName) {
    setState(() {
      _selectedGenreId = genreId;
    });
    context.read<MoviesProvider>().loadMoviesByGenre(genreId);
  }

  void _clearSelection() {
    setState(() {
      _selectedGenreId = null;
    });
    context.read<MoviesProvider>().clearMoviesByGenre();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedGenreId != null ? 'Выбрана категория' : 'Категории'),
        actions: [
          if (_selectedGenreId != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearSelection,
              tooltip: 'Сбросить',
            ),
        ],
      ),
      body: Consumer<MoviesProvider>(
        builder: (context, moviesProvider, _) {
          // Ошибка
          if (moviesProvider.error != null && moviesProvider.genres.isEmpty) {
            return CustomErrorWidget(
              message: moviesProvider.error!,
              onRetry: _loadGenres,
            );
          }

          // Загрузка жанров
          if (moviesProvider.isLoading && moviesProvider.genres.isEmpty) {
            return const LoadingIndicator(message: 'Загрузка категорий...');
          }

          // Режим просмотра фильмов жанра
          if (_selectedGenreId != null) {
            return _buildMoviesByGenre(moviesProvider);
          }

          // Список жанров
          return _buildGenresList(moviesProvider);
        },
      ),
    );
  }

  /// Список жанров
  Widget _buildGenresList(MoviesProvider moviesProvider) {
    if (moviesProvider.genres.isEmpty) {
      return const EmptyStateWidget(
        title: 'Нет категорий',
        icon: Icons.category_outlined,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: moviesProvider.genres.length,
      itemBuilder: (context, index) {
        final genre = moviesProvider.genres[index];
        return _buildGenreCard(genre);
      },
    );
  }

  /// Карточка жанра
  Widget _buildGenreCard(dynamic genre) {
    return GestureDetector(
      onTap: () => _onGenreSelected(genre.id, genre.name),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF7C4DFF).withOpacity(0.3),
              const Color(0xFF00E5FF).withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF7C4DFF).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            genre.name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  /// Фильмы по жанру
  Widget _buildMoviesByGenre(MoviesProvider moviesProvider) {
    // Загрузка
    if (moviesProvider.isLoading && moviesProvider.moviesByGenre.isEmpty) {
      return const LoadingIndicator(message: 'Загрузка фильмов...');
    }

    // Ошибка
    if (moviesProvider.error != null && moviesProvider.moviesByGenre.isEmpty) {
      return CustomErrorWidget(
        message: moviesProvider.error!,
        onRetry: () => moviesProvider.loadMoviesByGenre(_selectedGenreId!),
      );
    }

    // Пусто
    if (moviesProvider.moviesByGenre.isEmpty) {
      return const EmptyStateWidget(
        title: 'Нет фильмов',
        subtitle: 'В этой категории пока нет фильмов',
        icon: Icons.movie_outlined,
      );
    }

    return Column(
      children: [
        // Выбранный жанр
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF7C4DFF).withOpacity(0.3),
                const Color(0xFF00E5FF).withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.category, color: Color(0xFF7C4DFF)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Категория',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                    Text(
                      moviesProvider.genres
                              .firstWhere(
                                (g) => g.id == _selectedGenreId,
                                orElse: () => moviesProvider.genres.first,
                              )
                              .name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${moviesProvider.moviesByGenre.length} фильмов',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
        // Сетка фильмов
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.65,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: moviesProvider.moviesByGenre.length,
            itemBuilder: (context, index) {
              final movie = moviesProvider.moviesByGenre[index];
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
          ),
        ),
      ],
    );
  }
}
