import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/modern_ui.dart';
import '../../widgets/widgets.dart';
import '../movie_detail_screen.dart';

/// ============================================================================
/// HOME SCREEN — Чистый, адаптивный, удобный для смартфонов
/// ============================================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isRefreshing = true);
    try {
      final mp = context.read<MoviesProvider>();
      await Future.wait([
        mp.loadTrendingMovies(),
        mp.loadPopularMovies(),
        mp.loadTopRatedMovies(),
      ]);
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 900;
    final horizontalPadding = isWide ? 32.0 : 16.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Consumer<MoviesProvider>(
          builder: (context, mp, _) {
            // Ошибка при пустых данных
            if (mp.error != null && mp.trendingMovies.isEmpty) {
              return _buildErrorState(mp.error!, theme);
            }

            // Загрузка
            if (mp.isLoading && mp.trendingMovies.isEmpty) {
              return _buildLoadingState(theme);
            }

            return RefreshIndicator(
              onRefresh: _loadData,
              color: ModernColors.primaryPurple,
              child: CustomScrollView(
                slivers: [
                  // Шапка
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 0),
                      child: _buildHeader(theme, isWide),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // Hero-баннер
                  if (mp.trendingMovies.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildHeroBanner(mp.trendingMovies.take(5).toList(), isWide, horizontalPadding),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),

                  // Быстрые жанры
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: _buildQuickGenres(mp, horizontalPadding),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),

                  // Секции фильмов
                  _buildMoviesSection(
                    title: 'В тренде',
                    subtitle: 'Свежие подборки этой недели',
                    icon: Icons.trending_up_rounded,
                    movies: mp.trendingMovies,
                    padding: horizontalPadding,
                  ),
                  _buildMoviesSection(
                    title: 'Популярное',
                    subtitle: 'То, что смотрят сейчас',
                    icon: Icons.local_fire_department_rounded,
                    movies: mp.popularMovies,
                    padding: horizontalPadding,
                  ),
                  _buildMoviesSection(
                    title: 'Высокий рейтинг',
                    subtitle: 'Лучшие фильмы всех времён',
                    icon: Icons.workspace_premium_rounded,
                    movies: mp.topRatedMovies,
                    padding: horizontalPadding,
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ========== HEADER ==========
  Widget _buildHeader(ThemeData theme, bool isWide) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Кинозал', style: theme.textTheme.headlineLarge),
              const SizedBox(height: 4),
              Text(
                'Отслеживайте, сохраняйте и открывайте новые фильмы',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          onPressed: _isRefreshing ? null : _loadData,
          icon: _isRefreshing
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.refresh_rounded),
          tooltip: 'Обновить',
        ),
      ],
    );
  }

  // ========== HERO BANNER ==========
  Widget _buildHeroBanner(List<Movie> movies, bool isWide, double padding) {
    if (movies.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: isWide ? 380 : 420,
      child: PageView.builder(
        controller: PageController(viewportFraction: isWide ? 0.85 : 0.92),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _HeroCard(movie: movie, rank: index + 1),
          );
        },
      ),
    );
  }

  // ========== QUICK GENRES ==========
  Widget _buildQuickGenres(MoviesProvider mp, double padding) {
    final genres = mp.genres;
    if (genres.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Жанры', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: genres.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final genre = genres[index];
              return ActionChip(
                label: Text(genre.name),
                onPressed: () {
                  mp.loadMoviesByGenre(genre.id);
                  // Переход на вкладку жанров
                },
                avatar: Icon(Icons.tag_rounded, size: 16),
              );
            },
          ),
        ),
      ],
    );
  }

  // ========== MOVIES SECTION ==========
  Widget _buildMoviesSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Movie> movies,
    required double padding,
  }) {
    if (movies.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: ModernGradients.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: movies.length > 12 ? 12 : movies.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final movie = movies[index];
                  return Consumer<FavoritesProvider>(
                    builder: (context, fav, _) {
                      final auth = context.read<AuthProvider>();
                      final isFav = fav.favorites.any((m) => m.id == movie.id);
                      return MovieCard(
                        movie: movie,
                        isFavorite: isFav,
                        onFavoriteTap: () => fav.toggleFavorite(movie, auth.userId),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  // ========== ERROR STATE ==========
  Widget _buildErrorState(String message, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.red),
              ),
              const SizedBox(height: 16),
              Text('Не удалось загрузить', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isRefreshing ? null : _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== LOADING STATE ==========
  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: ModernGradients.primaryGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.movie_creation_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),
          Text('Загружаем фильмы...', style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

// ============================================================================
// HERO CARD
// ============================================================================

class _HeroCard extends StatelessWidget {
  final Movie movie;
  final int rank;

  const _HeroCard({required this.movie, required this.rank});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)));
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Backdrop
            if (movie.backdropPath != null && movie.backdropPath!.isNotEmpty)
              Image.network(
                'https://image.tmdb.org/t/p/w780${movie.backdropPath}',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallbackGradient(),
              )
            else
              _fallbackGradient(),

            // Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Топ $rank',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFFFC857), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              movie.voteAverage.toStringAsFixed(1),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  if (movie.releaseYear.isNotEmpty)
                    Text(
                      movie.releaseYear,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackGradient() {
    return Container(decoration: const BoxDecoration(gradient: ModernGradients.heroGradient));
  }
}
