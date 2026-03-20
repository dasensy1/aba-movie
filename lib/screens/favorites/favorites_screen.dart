import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../movie_detail_screen.dart';

/// ============================================================================
/// FAVORITES SCREEN
/// ============================================================================
/// Вкладка избранных фильмов
/// ============================================================================

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    await context.read<FavoritesProvider>().loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Избранное'),
        actions: [
          Consumer<FavoritesProvider>(
            builder: (context, favorites, _) {
              if (favorites.favorites.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _showClearConfirm(),
                  tooltip: 'Очистить все',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<FavoritesProvider>(
        builder: (context, favoritesProvider, _) {
          // Загрузка
          if (favoritesProvider.isLoading) {
            return const LoadingIndicator(message: 'Загрузка избранного...');
          }

          // Пусто
          if (favoritesProvider.favorites.isEmpty) {
            return EmptyStateWidget(
              title: 'Нет избранных фильмов',
              subtitle: 'Добавляйте фильмы в избранное,\nчтобы они появились здесь',
              icon: Icons.favorite_border,
              action: ElevatedButton.icon(
                onPressed: () {
                  // Переключаемся на вкладку поиска или главную
                  DefaultTabController.of(context)!.animateTo(0);
                },
                icon: const Icon(Icons.search),
                label: const Text('Найти фильмы'),
              ),
            );
          }

          // Список избранных
          return _buildFavoritesList(favoritesProvider);
        },
      ),
    );
  }

  /// Список избранных фильмов
  Widget _buildFavoritesList(FavoritesProvider provider) {
    return Column(
      children: [
        // Статистика
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.red.withOpacity(0.2),
                Colors.pink.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.red.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${provider.favorites.length}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'фильмов в избранном',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Сетка фильмов
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.55,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: provider.favorites.length,
            itemBuilder: (context, index) {
              final movie = provider.favorites[index];
              return MovieCardVertical(
                movie: movie,
                isFavorite: true,
                onFavoriteTap: () => _toggleFavorite(movie),
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
          ),
        ),
      ],
    );
  }

  /// Переключить избранное
  Future<void> _toggleFavorite(dynamic movie) async {
    final provider = context.read<FavoritesProvider>();
    await provider.toggleFavorite(movie);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${movie.title} удалён из избранного'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Подтверждение очистки
  void _showClearConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить избранное?'),
        content: const Text(
          'Вы уверены, что хотите удалить все фильмы из избранного?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<FavoritesProvider>().clearAll();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Избранное очищено'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }
}
