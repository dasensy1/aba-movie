// ============================================================================
// CATEGORIES SCREEN — MODERN UI with genre icons, glassmorphism, animations
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../utils/modern_ui.dart';
import '../../widgets/widgets.dart';
import '../movie_detail_screen.dart';

// Genre icon mapping
const Map<String, IconData> _genreIcons = {
  'Боевик': Icons.local_fire_department_rounded,
  'Комедия': Icons.sentiment_very_satisfied_rounded,
  'Ужасы': Icons.nights_stay_rounded,
  'Фантастика': Icons.rocket_launch_rounded,
  'Драма': Icons.theaters_rounded,
  'Триллер': Icons.shield_moon_rounded,
  'Приключения': Icons.explore_rounded,
  'Фэнтези': Icons.auto_fix_high_rounded,
  'Мелодрама': Icons.favorite_rounded,
  'История': Icons.menu_book_rounded,
  'Детектив': Icons.search_rounded,
  'Военный': Icons.gavel_rounded,
  'Биография': Icons.person_rounded,
  'Музыка': Icons.music_note_rounded,
  'Семейный': Icons.family_restroom_rounded,
  'Анимация': Icons.movie_filter_rounded,
  'Документальный': Icons.camera_alt_rounded,
  'Криминал': Icons.gavel_rounded,
  'Вестерн': Icons.landscape_rounded,
};

IconData _getGenreIcon(String name) {
  for (final entry in _genreIcons.entries) {
    if (name.toLowerCase().contains(entry.key.toLowerCase())) {
      return entry.value;
    }
  }
  return Icons.movie_outlined;
}

// Genre gradient pairs
final List<List<Color>> _genreGradients = [
  [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
  [const Color(0xFF06B6D4), const Color(0xFF0891B2)],
  [const Color(0xFFEC4899), const Color(0xFFDB2777)],
  [const Color(0xFF10B981), const Color(0xFF059669)],
  [const Color(0xFFF59E0B), const Color(0xFFD97706)],
  [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
  [const Color(0xFFEF4444), const Color(0xFFDC2626)],
  [const Color(0xFF8B5CF6), const Color(0xFF06B6D4)],
];

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with TickerProviderStateMixin {
  int? _selectedGenreId;
  late AnimationController _gridAnimationController;
  late Animation<double> _gridAnimation;

  @override
  void initState() {
    super.initState();
    _gridAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _gridAnimation = CurvedAnimation(
      parent: _gridAnimationController,
      curve: Curves.easeOutCubic,
    );
    _gridAnimationController.forward();
    _loadGenres();
  }

  @override
  void dispose() {
    _gridAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadGenres() async {
    final provider = context.read<MoviesProvider>();
    if (provider.genres.isEmpty) {
      provider.loadGenres();
    }
  }

  void _onGenreSelected(int genreId, String genreName) {
    setState(() => _selectedGenreId = genreId);
    context.read<MoviesProvider>().loadMoviesByGenre(genreId);
  }

  void _clearSelection() {
    setState(() => _selectedGenreId = null);
    context.read<MoviesProvider>().clearMoviesByGenre();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: ModernGradients.darkBackgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Consumer<MoviesProvider>(
                  builder: (context, moviesProvider, _) {
                    if (moviesProvider.error != null && moviesProvider.genres.isEmpty) {
                      return _buildErrorSection(moviesProvider.error!);
                    }
                    if (moviesProvider.isLoading && moviesProvider.genres.isEmpty) {
                      return _buildLoadingSection();
                    }
                    if (_selectedGenreId != null) {
                      return _buildMoviesByGenre(moviesProvider);
                    }
                    return _buildGenresGrid(moviesProvider);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
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
              gradient: ModernGradients.sunsetGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.category_rounded, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Text(
            _selectedGenreId != null ? 'Категория' : 'Жанры',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ],
      ),
      actions: [
        if (_selectedGenreId != null)
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.clear_rounded, size: 20),
              onPressed: _clearSelection,
            ),
          ),
      ],
    );
  }

  Widget _buildGenresGrid(MoviesProvider moviesProvider) {
    if (moviesProvider.genres.isEmpty) {
      return const Center(child: Text('Нет категорий', style: TextStyle(color: Colors.white54)));
    }

    final genres = moviesProvider.genres;
    return AnimatedBuilder(
      animation: _gridAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.95 + (_gridAnimation.value * 0.05),
          child: Opacity(opacity: _gridAnimation.value, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(ModernSpacing.lg),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: genres.length,
          itemBuilder: (context, index) {
            final genre = genres[index];
            final gradient = _genreGradients[index % _genreGradients.length];
            return _GenreCard(
              genre: genre,
              gradient: gradient,
              icon: _getGenreIcon(genre.name),
              onTap: () => _onGenreSelected(genre.id, genre.name),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMoviesByGenre(MoviesProvider moviesProvider) {
    if (moviesProvider.isLoading && moviesProvider.moviesByGenre.isEmpty) {
      return _buildLoadingSection();
    }
    if (moviesProvider.error != null && moviesProvider.moviesByGenre.isEmpty) {
      return _buildErrorSection(moviesProvider.error!);
    }
    if (moviesProvider.moviesByGenre.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.movie_outlined, size: 64, color: Colors.white24),
              SizedBox(height: 16),
              Text('Нет фильмов в этой категории', style: TextStyle(color: Colors.white54, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    final selectedGenre = moviesProvider.genres.firstWhere(
      (g) => g.id == _selectedGenreId,
      orElse: () => moviesProvider.genres.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Genre header
        Padding(
          padding: const EdgeInsets.all(ModernSpacing.lg),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: Glassmorphism.glassCard(opacity: 0.06, borderRadius: ModernRadius.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: ModernGradients.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_getGenreIcon(selectedGenre.name), size: 28, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(selectedGenre.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('${moviesProvider.moviesByGenre.length} фильмов', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Movies grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ModernSpacing.lg),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.55,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: moviesProvider.moviesByGenre.length,
            itemBuilder: (context, index) {
              final movie = moviesProvider.moviesByGenre[index];
              return Consumer<FavoritesProvider>(
                builder: (context, favorites, _) {
                  final auth = context.read<AuthProvider>();
                  final isFav = favorites.favorites.any((m) => m.id == movie.id);
                  return MovieCardVertical(
                    movie: movie,
                    isFavorite: isFav,
                    onFavoriteTap: () => favorites.toggleFavorite(movie, auth.userId),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildLoadingSection() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: ModernGradients.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
            ),
            const SizedBox(height: ModernSpacing.xl),
            const Text('Загрузка...', style: TextStyle(color: Colors.white54, fontSize: 14)),
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
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded, size: 48, color: ModernColors.error),
          ),
          const SizedBox(height: ModernSpacing.xl),
          const Text('Ошибка загрузки', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
        ],
      ),
    );
  }
}

class _GenreCard extends StatefulWidget {
  final dynamic genre;
  final List<Color> gradient;
  final IconData icon;
  final VoidCallback onTap;

  const _GenreCard({required this.genre, required this.gradient, required this.icon, required this.onTap});

  @override
  State<_GenreCard> createState() => _GenreCardState();
}

class _GenreCardState extends State<_GenreCard> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: ModernAnimations.fast, vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isPressed
                  ? [widget.gradient[0].withValues(alpha: 0.8), widget.gradient[1].withValues(alpha: 0.6)]
                  : widget.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(ModernRadius.md),
            boxShadow: _isPressed ? [] : [
              BoxShadow(
                color: widget.gradient[0].withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.genre.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
