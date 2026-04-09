import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../models/models.dart';
import '../../utils/modern_ui.dart';
import '../movie_detail_screen.dart';

/// ============================================================================
/// HOME SCREEN — Современный дизайн с glassmorphism и градиентами
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
    setState(() {
      _isRefreshing = true;
    });

    try {
      final moviesProvider = context.read<MoviesProvider>();
      await Future.wait([
        moviesProvider.loadTrendingMovies(),
        moviesProvider.loadPopularMovies(),
        moviesProvider.loadTopRatedMovies(),
      ]);
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: ModernGradients.darkBackgroundGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Декоративные фоновые элементы
              ModernDecorations.backgroundCircles,
              // Основной контент
              CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Modern AppBar
                  _buildModernAppBar(),
                  // Контент
                  SliverToBoxAdapter(
                    child: Consumer<MoviesProvider>(
                      builder: (context, moviesProvider, _) {
                        if (moviesProvider.error != null && moviesProvider.trendingMovies.isEmpty) {
                          return _buildErrorSection(moviesProvider.error!);
                        }

                        if (moviesProvider.isLoading && moviesProvider.trendingMovies.isEmpty) {
                          return _buildLoadingSection();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeroBanner(moviesProvider),
                            const SizedBox(height: ModernSpacing.lg),
                            _buildQuickCategories(),
                            const SizedBox(height: ModernSpacing.xl),
                            _buildModernSection(
                              title: 'В тренде',
                              icon: Icons.trending_up,
                              subtitle: 'Популярное сейчас',
                              movies: moviesProvider.trendingMovies,
                            ),
                            const SizedBox(height: ModernSpacing.xxl),
                            _buildModernSection(
                              title: 'Популярное',
                              icon: Icons.local_fire_department,
                              subtitle: 'Выбор зрителей',
                              movies: moviesProvider.popularMovies,
                            ),
                            const SizedBox(height: ModernSpacing.xxl),
                            _buildModernSection(
                              title: 'Лучшее',
                              icon: Icons.workspace_premium,
                              subtitle: 'Высокий рейтинг',
                              movies: moviesProvider.topRatedMovies,
                            ),
                            const SizedBox(height: 100),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Современный AppBar
  Widget _buildModernAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: ModernGradients.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.movie_creation, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Movie Tracker',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh_rounded, size: 22),
            onPressed: _isRefreshing ? null : _loadData,
            tooltip: 'Обновить',
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// Hero баннер с PageView
  Widget _buildHeroBanner(MoviesProvider moviesProvider) {
    if (moviesProvider.trendingMovies.isEmpty) {
      return Container(
        height: 420,
        margin: const EdgeInsets.all(ModernSpacing.lg),
        decoration: BoxDecoration(
          color: ModernColors.surfaceDark,
          borderRadius: BorderRadius.circular(ModernRadius.lg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.movie_creation_outlined, size: 64, color: ModernColors.primaryPurple),
              SizedBox(height: ModernSpacing.lg),
              Text(
                'Загрузка фильмов...',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final movies = moviesProvider.trendingMovies.take(5).toList();

    return SizedBox(
      height: 420,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.88, initialPage: 0),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return AnimatedBuilder(
            animation: PageController(viewportFraction: 0.88),
            builder: (context, child) {
              return AnimatedContainer(
                duration: ModernAnimations.normal,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ModernRadius.lg),
                  boxShadow: ModernShadows.medium,
                ),
                child: child,
              );
            },
            child: _HeroMovieCard(movie: movie, rank: index + 1),
          );
        },
      ),
    );
  }

  /// Быстрые категории
  Widget _buildQuickCategories() {
    final categories = [
      {'icon': Icons.local_fire_department, 'label': 'Боевики'},
      {'icon': Icons.sentiment_very_satisfied, 'label': 'Комедии'},
      {'icon': Icons.rocket_launch, 'label': 'Фантастика'},
      {'icon': Icons.favorite, 'label': 'Драмы'},
      {'icon': Icons.theaters, 'label': 'Триллеры'},
    ];

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: ModernSpacing.lg),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: ModernSpacing.sm),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return _CategoryChip(icon: cat['icon']! as IconData, label: cat['label']! as String);
        },
      ),
    );
  }

  /// Современная секция с фильмами
  Widget _buildModernSection({
    required String title,
    required IconData icon,
    required String subtitle,
    required List<Movie> movies,
  }) {
    if (movies.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ModernSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ModernGradients.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: Colors.white),
              ),
              const SizedBox(width: ModernSpacing.md),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Все',
                  style: TextStyle(
                    color: ModernColors.primaryPurpleLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ModernSpacing.md),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: ModernSpacing.lg),
            itemCount: movies.length > 10 ? 10 : movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return Consumer<FavoritesProvider>(
                builder: (context, favorites, _) {
                  final auth = context.read<AuthProvider>();
                  final isFav = favorites.favorites.any((m) => m.id == movie.id);
                  return MovieCard(
                    movie: movie,
                    isFavorite: isFav,
                    onFavoriteTap: () => favorites.toggleFavorite(movie, auth.userId),
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
      ],
    );
  }

  Widget _buildLoadingSection() {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: ModernGradients.primaryGradient,
                borderRadius: BorderRadius.circular(ModernRadius.full),
              ),
              child: const Icon(Icons.movie_creation_rounded, size: 48, color: Colors.white),
            ),
            const SizedBox(height: ModernSpacing.xl),
            Text(
              'Загружаем фильмы...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSection(String message) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ModernColors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(ModernRadius.full),
            ),
            child: const Icon(Icons.error_outline_rounded, size: 56, color: ModernColors.error),
          ),
          const SizedBox(height: ModernSpacing.xl),
          Text(
            'Ошибка загрузки',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ModernSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: ModernSpacing.xxl),
          ElevatedButton.icon(
            onPressed: _isRefreshing ? null : _loadData,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
            label: const Text('Попробовать снова'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ModernRadius.md)),
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// HERO MOVIE CARD — Современный дизайн
/// ============================================================================

class _HeroMovieCard extends StatelessWidget {
  final Movie movie;
  final int rank;

  const _HeroMovieCard({required this.movie, required this.rank});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ModernRadius.lg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Фон с постером
            _buildBackground(),
            // Градиент
            _buildGradientOverlay(),
            // Контент
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (movie.backdropPath != null) {
      return Image.network(
        'https://image.tmdb.org/t/p/original${movie.backdropPath}',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallbackBackground(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildFallbackBackground();
        },
      );
    }
    return _buildFallbackBackground();
  }

  Widget _buildFallbackBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: ModernGradients.heroGradient,
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.4),
            Colors.black.withValues(alpha: 0.85),
            Colors.black,
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.all(ModernSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: ModernGradients.sunsetGradient,
                    borderRadius: BorderRadius.circular(ModernRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_up_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Тренд #$rank',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (movie.voteAverage > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(ModernRadius.sm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: ModernColors.warning, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          movie.voteAverage.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: ModernSpacing.md),
            // Название
            Text(
              movie.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
                letterSpacing: -0.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: ModernSpacing.sm),
            // Год и жанры
            Row(
              children: [
                if (movie.releaseYear.isNotEmpty)
                  Text(
                    movie.releaseYear,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (movie.genreIds.isNotEmpty) ...[
                  const SizedBox(width: ModernSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${movie.genreIds.length} жанр${movie.genreIds.length == 1 ? '' : movie.genreIds.length < 5 ? 'а' : 'ов'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================================
/// CATEGORY CHIP — Современный чип категории
/// ============================================================================

class _CategoryChip extends StatefulWidget {
  final IconData icon;
  final String label;

  const _CategoryChip({required this.icon, required this.label});

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        // TODO: Переход к категориям
      },
      child: AnimatedContainer(
        duration: ModernAnimations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _isPressed
              ? ModernColors.primaryPurple.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(ModernRadius.full),
          border: Border.all(
            color: _isPressed
                ? ModernColors.primaryPurple.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 16, color: _isPressed ? Colors.white : Colors.white.withValues(alpha: 0.8)),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: TextStyle(
                color: _isPressed ? Colors.white : Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
