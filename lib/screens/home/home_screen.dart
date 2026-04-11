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
  final Function(int)? onNavigateToTab;
  
  const HomeScreen({super.key, this.onNavigateToTab});

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
                  // Сразу Hero-баннер без отступов сверху
                  if (mp.trendingMovies.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildHeroBanner(mp.trendingMovies.take(5).toList(), isWide),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),

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
                    isWide: isWide,
                  ),
                  _buildMoviesSection(
                    title: 'Популярное',
                    subtitle: 'То, что смотрят сейчас',
                    icon: Icons.local_fire_department_rounded,
                    movies: mp.popularMovies,
                    padding: horizontalPadding,
                    isWide: isWide,
                  ),
                  _buildMoviesSection(
                    title: 'Высокий рейтинг',
                    subtitle: 'Лучшие фильмы всех времён',
                    icon: Icons.workspace_premium_rounded,
                    movies: mp.topRatedMovies,
                    padding: horizontalPadding,
                    isWide: isWide,
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

  // (Убрали старый Header, так как есть новый Sticky Web-Header)

  // ========== HERO BANNER ==========
  Widget _buildHeroBanner(List<Movie> movies, bool isWide) {
    if (movies.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: isWide ? 640 : 450,
      width: double.infinity,
      child: PageView.builder(
        controller: PageController(viewportFraction: 1.0),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return _HeroCard(movie: movie);
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
                  widget.onNavigateToTab?.call(2); // Переход на вкладку жанров
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
    required bool isWide,
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
            if (isWide)
              Wrap(
                spacing: 16,
                runSpacing: 24,
                children: movies.take(12).map((movie) {
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
                }).toList(),
              )
            else
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

  const _HeroCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 900;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Backdrop (High Quality)
        if (movie.backdropPath != null && movie.backdropPath!.isNotEmpty)
          Image.network(
            'https://image.tmdb.org/t/p/original${movie.backdropPath}',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, __, ___) => _fallbackGradient(),
          )
        else
          _fallbackGradient(),

        // Streaming Style Gradient Overlays
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                ModernColors.backgroundDark,
                ModernColors.backgroundDark.withValues(alpha: 0.7),
                Colors.transparent,
                Colors.transparent,
              ],
              stops: const [0.0, 0.4, 0.8, 1.0],
            ),
          ),
        ),
        
        if (isWide) // Эффект тени слева для десктопа (поверх картинки, под текстом)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    ModernColors.backgroundDark.withValues(alpha: 0.9),
                    ModernColors.backgroundDark.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

        // Content
        Positioned(
          left: isWide ? 64 : 24,
          bottom: isWide ? 80 : 40,
          right: isWide ? size.width * 0.4 : 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Жанры, рейтинг
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: ModernColors.accentCyan.withValues(alpha: 0.15),
                      border: Border.all(color: ModernColors.accentCyan.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: ModernColors.accentCyan, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          movie.voteAverage.toStringAsFixed(1),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (movie.releaseYear.isNotEmpty)
                    Text(
                      movie.releaseYear,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Название фильма
              Text(
                movie.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: Colors.white, 
                  fontWeight: FontWeight.w900,
                  fontSize: isWide ? 64 : 42,
                  height: 1.1,
                  letterSpacing: -1,
                  shadows: [
                    Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              if (movie.overview != null && movie.overview!.isNotEmpty && isWide)
                Text(
                  movie.overview!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                
              const SizedBox(height: 32),
              
              // CTA Кнопки
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)));
                    },
                    icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 28),
                    label: const Text('Смотреть', style: TextStyle(color: Colors.black, fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                    label: const Text('В список', style: TextStyle(color: Colors.white, fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fallbackGradient() {
    return Container(decoration: const BoxDecoration(gradient: ModernGradients.heroGradient));
  }
}
