import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/modern_ui.dart';
import '../../widgets/widgets.dart';
import '../movie_collection_screen.dart';
import '../movie_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isRefreshing = false;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureDataLoaded());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _ensureDataLoaded({bool force = false}) async {
    final provider = context.read<MoviesProvider>();
    final tasks = <Future<void>>[];

    if (force || provider.trendingMovies.isEmpty) {
      tasks.add(provider.loadTrendingMovies());
    }
    if (force || provider.popularMovies.isEmpty) {
      tasks.add(provider.loadPopularMovies());
    }
    if (force || provider.topRatedMovies.isEmpty) {
      tasks.add(provider.loadTopRatedMovies());
    }
    if (force || provider.genres.isEmpty) {
      tasks.add(provider.loadGenres());
    }

    if (tasks.isEmpty) return;

    setState(() => _isRefreshing = true);
    try {
      await Future.wait(tasks);
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _openCollectionScreen({
    required String title,
    required String subtitle,
    List<Movie>? movies,
    int? genreId,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MovieCollectionScreen(
          title: title,
          subtitle: subtitle,
          initialMovies: movies,
          genreId: genreId,
          emptyMessage: 'Список пока пуст',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 900;
    final horizontalPadding = isWide ? 32.0 : 16.0;

    return Scaffold(
      backgroundColor: ModernColors.backgroundDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF151922),
              ModernColors.backgroundDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<MoviesProvider>(
            builder: (context, provider, _) {
              if (provider.error != null && provider.trendingMovies.isEmpty) {
                return _buildErrorState(provider.error!);
              }

              if (provider.isLoading && provider.trendingMovies.isEmpty) {
                return _buildLoadingState();
              }

              return RefreshIndicator(
                onRefresh: () => _ensureDataLoaded(force: true),
                color: ModernColors.primaryPurple,
                child: CustomScrollView(
                  slivers: [
                    if (provider.trendingMovies.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                              horizontalPadding, 12, horizontalPadding, 0),
                          child: _buildHeroBanner(
                            provider.trendingMovies.take(5).toList(),
                            isWide,
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                            horizontalPadding, 28, horizontalPadding, 0),
                        child: _buildQuickGenres(provider),
                      ),
                    ),
                    _buildMoviesSection(
                      title: 'В тренде',
                      subtitle: 'Самые обсуждаемые фильмы недели',
                      icon: Icons.trending_up_rounded,
                      movies: provider.trendingMovies,
                      padding: horizontalPadding,
                      isWide: isWide,
                      onOpenAll: () => _openCollectionScreen(
                        title: 'В тренде',
                        subtitle: 'Самые обсуждаемые фильмы недели',
                        movies: provider.trendingMovies,
                      ),
                    ),
                    _buildMoviesSection(
                      title: 'Популярное',
                      subtitle: 'То, что сейчас чаще всего смотрят',
                      icon: Icons.local_fire_department_rounded,
                      movies: provider.popularMovies,
                      padding: horizontalPadding,
                      isWide: isWide,
                      onOpenAll: () => _openCollectionScreen(
                        title: 'Популярное',
                        subtitle: 'То, что сейчас чаще всего смотрят',
                        movies: provider.popularMovies,
                      ),
                    ),
                    _buildMoviesSection(
                      title: 'Высокий рейтинг',
                      subtitle: 'Фильмы с лучшими оценками зрителей',
                      icon: Icons.workspace_premium_rounded,
                      movies: provider.topRatedMovies,
                      padding: horizontalPadding,
                      isWide: isWide,
                      onOpenAll: () => _openCollectionScreen(
                        title: 'Высокий рейтинг',
                        subtitle: 'Фильмы с лучшими оценками зрителей',
                        movies: provider.topRatedMovies,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(List<Movie> movies, bool isWide) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: AspectRatio(
        aspectRatio: isWide ? 21 / 8 : 16 / 11,
        child: PageView.builder(
          controller: _pageController,
          itemCount: movies.length,
          itemBuilder: (context, index) => _HeroCard(movie: movies[index]),
        ),
      ),
    );
  }

  Widget _buildQuickGenres(MoviesProvider provider) {
    if (provider.genres.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Жанры', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: provider.genres.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final genre = provider.genres[index];
              return ActionChip(
                label: Text(genre.name),
                avatar: const Icon(Icons.arrow_outward_rounded, size: 16),
                onPressed: () => _openCollectionScreen(
                  title: genre.name,
                  subtitle: 'Фильмы в жанре ${genre.name}',
                  genreId: genre.id,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMoviesSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Movie> movies,
    required double padding,
    required bool isWide,
    required VoidCallback onOpenAll,
  }) {
    if (movies.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(padding, 28, padding, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Icon(icon, color: Colors.white70, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                TextButton(onPressed: onOpenAll, child: const Text('Открыть')),
              ],
            ),
            const SizedBox(height: 16),
            if (isWide)
              Wrap(
                spacing: 16,
                runSpacing: 20,
                children: movies.take(12).map(_buildMovieCard).toList(),
              )
            else
              SizedBox(
                height: 280,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: movies.length > 12 ? 12 : movies.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) =>
                      _buildMovieCard(movies[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieCard(Movie movie) {
    return Consumer<FavoritesProvider>(
      builder: (context, favorites, _) {
        final auth = context.read<AuthProvider>();
        final isFavorite = favorites.favorites.any((m) => m.id == movie.id);
        return MovieCard(
          movie: movie,
          isFavorite: isFavorite,
          onFavoriteTap: () => favorites.toggleFavorite(movie, auth.userId),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => MovieDetailScreen(movie: movie)),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white54, size: 44),
            const SizedBox(height: 12),
            Text('Не удалось загрузить фильмы',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed:
                  _isRefreshing ? null : () => _ensureDataLoaded(force: true),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: ModernColors.primaryPurple),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final Movie movie;

  const _HeroCard({required this.movie});

  String get _heroImageUrl {
    if (movie.backdropPath != null && movie.backdropPath!.isNotEmpty) {
      return 'https://image.tmdb.org/t/p/w1280${movie.backdropPath}';
    }
    return movie.posterUrl;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_heroImageUrl.isNotEmpty)
          CachedNetworkImage(
            imageUrl: _heroImageUrl,
            fit: BoxFit.cover,
            alignment:
                isMobile ? const Alignment(0.35, 0) : const Alignment(0.25, 0),
            fadeInDuration: const Duration(milliseconds: 120),
            errorWidget: (_, __, ___) => _fallback(),
            placeholder: (_, __) => _fallback(),
          )
        else
          _fallback(),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withValues(alpha: 0.82),
                  Colors.black.withValues(alpha: 0.48),
                  Colors.black.withValues(alpha: 0.18),
                  Colors.black.withValues(alpha: 0.5),
                ],
                stops: const [0.0, 0.32, 0.6, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.76),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(isMobile ? 20 : 24),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: isMobile ? double.infinity : 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.36),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Text(
                      '${movie.releaseYear.isNotEmpty ? '${movie.releaseYear} • ' : ''}${movie.voteAverage.toStringAsFixed(1)}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: isMobile ? 28 : 36,
                          height: 1.05,
                        ),
                  ),
                  if ((movie.overview ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      movie.overview!,
                      maxLines: isMobile ? 3 : 4,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                            height: 1.55,
                          ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => MovieDetailScreen(movie: movie)),
                      );
                    },
                    child: const Text('Подробнее'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF252B36),
            Color(0xFF151922),
          ],
        ),
      ),
    );
  }
}
