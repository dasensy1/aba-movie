// ============================================================================
// MOVIE DETAIL SCREEN — MODERN UI with Parallax, Glassmorphism
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/modern_ui.dart';
import 'widgets/status_rating_widget.dart';
import 'widgets/reviews_widget.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  late Movie _currentMovie;
  List<Movie>? _similarMovies;
  bool _isFavorite = false;
  bool _isInWatchlist = false;
  WatchStatus _watchStatus = WatchStatus.wantToWatch;
  int _watchCount = 0;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _currentMovie = widget.movie;
    _scrollController.addListener(_onScroll);
    _checkStatuses();
    _loadFullDetails();
    _loadSimilarMovies();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkStatuses() {
    final favoritesProvider = context.read<FavoritesProvider>();
    final watchlistProvider = context.read<WatchlistProvider>();

    setState(() {
      _isFavorite = favoritesProvider.isFavoriteNow(_currentMovie.id);
      final watchlistMovie = watchlistProvider.getWatchlistMovie(_currentMovie.id);
      if (watchlistMovie != null) {
        _isInWatchlist = true;
        _watchStatus = watchlistMovie.status;
        _watchCount = watchlistMovie.watchCount;
      } else {
        _isInWatchlist = false;
        _watchCount = 0;
      }
    });
  }

  Future<void> _loadFullDetails() async {
    if (_currentMovie.credits != null && _currentMovie.credits!.isNotEmpty) return;
    try {
      final moviesProvider = context.read<MoviesProvider>();
      final fullMovie = await moviesProvider.getMovieDetails(_currentMovie.id);
      if (fullMovie != null && mounted) {
        setState(() => _currentMovie = fullMovie);
      }
    } catch (e) {
      debugPrint('Error loading movie details: $e');
    }
  }

  Future<void> _loadSimilarMovies() async {
    try {
      final moviesProvider = context.read<MoviesProvider>();
      final similar = await moviesProvider.getSimilarMovies(_currentMovie.id);
      if (mounted) {
        setState(() => _similarMovies = similar);
      }
    } catch (e) {
      debugPrint('Error loading similar movies: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<FavoritesProvider>();
    final added = await provider.toggleFavorite(_currentMovie, auth.userId);
    if (mounted) setState(() => _isFavorite = added);
  }

  Future<void> _toggleWatchlist() async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<WatchlistProvider>();
    if (_isInWatchlist) {
      await provider.removeFromWatchlist(_currentMovie.id, auth.userId);
      setState(() { _isInWatchlist = false; _watchCount = 0; });
    } else {
      final result = await _showStatusSelection();
      if (result != null) {
        final (status, watchedDate) = result;
        await provider.addToWatchlist(_currentMovie, auth.userId, status: status, watchedDate: watchedDate);
        _checkStatuses();
      }
    }
  }

  Future<void> _incrementCount() async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<WatchlistProvider>();
    await provider.incrementWatchCount(_currentMovie.id, auth.userId);
    _checkStatuses();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Просмотр добавлен! Всего: $_watchCount'),
          backgroundColor: ModernColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _launchTrailer() async {
    final movie = _currentMovie;
    if (movie.youtubeTrailerKey != null) {
      final url = Uri.parse('https://www.youtube.com/watch?v=${movie.youtubeTrailerKey}');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } else {
      // Ищем на ютубе, если трейлера нет в базе
      final query = Uri.encodeComponent('${movie.title} ${movie.releaseYear} trailer');
      final url = Uri.parse('https://www.youtube.com/results?search_query=$query');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    }
  }

  Future<(WatchStatus, DateTime?)?> _showStatusSelection() async {
    WatchStatus? selectedStatus;
    DateTime? selectedDate;

    return await showModalBottomSheet<(WatchStatus, DateTime?)>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: Glassmorphism.glassBottomSheet,
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: ModernGradients.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bookmark_add, size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Text('Добавить в список', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 20),
                ...WatchStatus.values.map((status) => GestureDetector(
                  onTap: () => setModalState(() => selectedStatus = status),
                  child: AnimatedContainer(
                    duration: ModernAnimations.fast,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selectedStatus == status
                          ? _getStatusColor(status).withValues(alpha: 0.15)
                          : ModernColors.surfaceDark.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(ModernRadius.md),
                      border: Border.all(
                        color: selectedStatus == status
                            ? _getStatusColor(status).withValues(alpha: 0.6)
                            : Colors.white.withValues(alpha: 0.08),
                        width: selectedStatus == status ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(status.icon, color: _getStatusColor(status), size: 22),
                        const SizedBox(width: 14),
                        Text(status.nameRu, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                )),
                const SizedBox(height: 16),
                ModernDecorations.divider(opacity: 0.08),
                const SizedBox(height: 16),
                const Text('Дата просмотра', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    final now = DateTime.now();
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: now,
                      firstDate: DateTime(1900),
                      lastDate: now,
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(primary: ModernColors.primaryPurple, surface: ModernColors.surfaceDark, onSurface: Colors.white),
                        ),
                        child: child!,
                      ),
                    );
                    if (pickedDate != null && !pickedDate.isAfter(now)) {
                      setModalState(() => selectedDate = pickedDate);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ModernColors.surfaceDark.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(ModernRadius.md),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: ModernColors.primaryPurple, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedDate != null
                                ? '${selectedDate!.day.toString().padLeft(2, '0')}.${selectedDate!.month.toString().padLeft(2, '0')}.${selectedDate!.year}'
                                : 'Выберите дату',
                            style: TextStyle(color: selectedDate != null ? Colors.white : Colors.white.withValues(alpha: 0.4)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedStatus != null
                        ? () => Navigator.pop(context, (selectedStatus!, selectedDate))
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ModernColors.primaryPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ModernRadius.md)),
                    ),
                    child: const Text('Добавить', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Color _getStatusColor(WatchStatus status) {
    switch (status) {
      case WatchStatus.wantToWatch: return ModernColors.primaryPurple;
      case WatchStatus.watching: return ModernColors.accentCyan;
      case WatchStatus.watched: return ModernColors.success;
      case WatchStatus.dropped: return ModernColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = _currentMovie;
    final imageUrl = movie.backdropPath != null
        ? 'https://image.tmdb.org/t/p/original${movie.backdropPath}'
        : (movie.posterUrl.isNotEmpty ? movie.posterUrl : null);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Полноэкранный фон/постер
          Positioned.fill(
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    placeholder: (_, __) => Container(decoration: const BoxDecoration(gradient: ModernGradients.heroGradient)),
                    errorWidget: (_, __, ___) => Container(decoration: const BoxDecoration(gradient: ModernGradients.heroGradient)),
                  )
                : Container(decoration: const BoxDecoration(gradient: ModernGradients.heroGradient)),
          ),
          
          // Затемняющий градиент для читаемости текста поверх
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
                    ModernColors.backgroundDark.withValues(alpha: 0.95),
                    ModernColors.backgroundDark,
                  ],
                  stops: const [0.0, 0.4, 0.65, 1.0],
                ),
              ),
            ),
          ),
          
          // Контент
          Positioned.fill(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                _buildAppBar(movie),
                
                // Пропускаем часть экрана для того, чтобы было видно постер сверху
                SliverToBoxAdapter(
                  child: SizedBox(height: MediaQuery.sizeOf(context).height * 0.15),
                ),
                
                // Компактный блок с информацией
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: ModernColors.backgroundDark.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 40, spreadRadius: -5),
                          ],
                        ),
                        child: _buildContent(movie),
                      ),
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(Movie movie) {
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: AnimatedOpacity(
          opacity: _scrollOffset > 100 ? 1.0 : 0.0,
          duration: ModernAnimations.fast,
          child: Text(
            movie.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(_isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _isFavorite ? ModernColors.accentPink : Colors.white),
            onPressed: _toggleFavorite,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(Movie movie) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Title
        Text(
          movie.title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, height: 1.15, letterSpacing: -0.5),
        ),
        const SizedBox(height: 16),
        // Meta info
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            if (movie.releaseYear.isNotEmpty)
              _buildMetaChip(movie.releaseYear, Icons.calendar_today_rounded, ModernColors.accentCyan),
            if (movie.voteAverage > 0)
              _buildMetaChip(movie.voteAverage.toStringAsFixed(1), Icons.star_rounded, ModernColors.warning),
            if (movie.genreIds.isNotEmpty)
              _buildMetaChip('${movie.genreIds.length} жанров', Icons.movie_outlined, ModernColors.primaryPurpleLight),
          ],
        ),
        const SizedBox(height: 32),
        // Action buttons
        _buildActionRow(),
        if (_isInWatchlist) ...[
          const SizedBox(height: 16),
          _buildQuickAddButton(),
        ],
        const SizedBox(height: 48),
        // Description
        _buildDescriptionSection(movie),
        const SizedBox(height: 40),
        // Watchlist status & rating
        _buildWatchlistSection(movie),
        const SizedBox(height: 40),
        // Actors & Similar Movies
        _buildActorsAndSimilar(),
        const SizedBox(height: 40),
        // Reviews
        ReviewsWidget(movieId: movie.id),
      ],
    );
  }

  Widget _buildActorsAndSimilar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('В главных ролях', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 24),
        SizedBox(
          height: 140,
          child: _currentMovie.credits == null
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 8,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (_, __) => Column(
                    children: [
                      const SkeletonLoader(width: 80, height: 80, borderRadius: 40),
                      const SizedBox(height: 8),
                      const SkeletonLoader(width: 60, height: 12, borderRadius: 4),
                    ],
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _currentMovie.credits!.length > 15 ? 15 : _currentMovie.credits!.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (_, index) {
                    final actor = _currentMovie.credits![index];
                    final profilePath = actor['profile_path'];
                    return Container(
                      width: 90,
                      child: Column(
                        children: [
                          Container(
                            width: 80, 
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ModernColors.surfaceDark,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                              image: profilePath != null ? DecorationImage(
                                image: CachedNetworkImageProvider('https://image.tmdb.org/t/p/w185$profilePath'),
                                fit: BoxFit.cover,
                              ) : null,
                            ),
                            child: profilePath == null ? const Icon(Icons.person, color: Colors.white54) : null,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            actor['name'] ?? '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, height: 1.1),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 48),
        const Text('Похожие фильмы', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 24),
        SizedBox(
          height: 220,
          child: _similarMovies == null
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 6,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (_, __) => const SkeletonLoader(width: 150, height: 220, borderRadius: 16),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _similarMovies!.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final movie = _similarMovies![index];
                    final posterPath = movie.posterPath;
                    return GestureDetector(
                      onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie))),
                      child: Container(
                        width: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: ModernColors.surfaceDark,
                          image: posterPath != null ? DecorationImage(
                            image: CachedNetworkImageProvider('https://image.tmdb.org/t/p/w500$posterPath'),
                            fit: BoxFit.cover,
                          ) : null,
                        ),
                        child: posterPath == null ? const Center(child: Icon(Icons.movie, color: Colors.white54)) : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMetaChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(ModernRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _launchTrailer,
            icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 24),
            label: const Text('Трейлер', style: TextStyle(color: Colors.black, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ModernRadius.md)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _toggleWatchlist,
            icon: Icon(_isInWatchlist ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded, color: Colors.white, size: 22),
            label: Text(_isInWatchlist ? 'В списке' : 'В список', style: const TextStyle(color: Colors.white, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: ModernColors.surfaceDarkHigher,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ModernRadius.md)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAddButton() {
    return GestureDetector(
      onTap: _incrementCount,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: ModernGradients.oceanGradient,
          borderRadius: BorderRadius.circular(ModernRadius.md),
          boxShadow: ModernShadows.medium,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.repeat_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ПОСМОТРЕЛ ЕЩЕ РАЗ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                Text('Всего просмотров: $_watchCount', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection(Movie movie) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: ModernGradients.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.description_rounded, size: 18, color: Colors.white),
            ),
            const SizedBox(width: ModernSpacing.md),
            const Text('Описание', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          ],
        ),
        const SizedBox(height: ModernSpacing.lg),
        Text(
          movie.overview?.isNotEmpty == true ? movie.overview! : 'Описание отсутствует',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildWatchlistSection(Movie movie) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: Glassmorphism.glassCard(opacity: 0.05, borderRadius: ModernRadius.lg),
      child: StatusRatingWidget(
        movieId: movie.id,
        initialStatus: _watchStatus,
        isInWatchlist: _isInWatchlist,
        onStatusChanged: (s) async {
          final auth = context.read<AuthProvider>();
          await context.read<WatchlistProvider>().updateStatus(movie.id, s, auth.userId);
          _checkStatuses();
        },
      ),
    );
  }
}
