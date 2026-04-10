// ============================================================================
// MOVIE DETAIL SCREEN — MODERN UI with Parallax, Glassmorphism
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    if (_currentMovie.overview != null && _currentMovie.overview!.length > 50) return;
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
      body: Stack(
        children: [
          // Backdrop image with parallax
          Positioned(
            top: -_scrollOffset * 0.3,
            left: 0, right: 0,
            height: 500,
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (_, __) => Container(decoration: const BoxDecoration(gradient: ModernGradients.heroGradient)),
                    errorWidget: (_, __, ___) => Container(decoration: const BoxDecoration(gradient: ModernGradients.heroGradient)),
                  )
                : Container(decoration: const BoxDecoration(gradient: ModernGradients.heroGradient)),
          ),
          // Gradient overlays
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.6),
                    ModernColors.backgroundDark,
                    ModernColors.backgroundDark,
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
          ),
          // Content
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildAppBar(movie),
              SliverToBoxAdapter(child: _buildContent(movie)),
            ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ModernSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Title
          Text(
            movie.title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, height: 1.15, letterSpacing: -0.5),
          ),
          const SizedBox(height: 12),
          // Meta info
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (movie.releaseYear.isNotEmpty)
                _buildMetaChip(movie.releaseYear, Icons.calendar_today_rounded, ModernColors.accentCyan),
              if (movie.voteAverage > 0)
                _buildMetaChip(movie.voteAverage.toStringAsFixed(1), Icons.star_rounded, ModernColors.warning),
              if (movie.genreIds.isNotEmpty)
                _buildMetaChip('${movie.genreIds.length} жанров', Icons.movie_outlined, ModernColors.primaryPurpleLight),
            ],
          ),
          const SizedBox(height: 24),
          // Action buttons
          _buildActionRow(),
          if (_isInWatchlist) ...[
            const SizedBox(height: 12),
            _buildQuickAddButton(),
          ],
          const SizedBox(height: 28),
          // Description
          _buildDescriptionSection(movie),
          const SizedBox(height: 28),
          // Watchlist status & rating
          _buildWatchlistSection(movie),
          const SizedBox(height: 32),
          // Reviews
          ReviewsWidget(movieId: movie.id),
          const SizedBox(height: 40),
        ],
      ),
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
            onPressed: _toggleWatchlist,
            icon: Icon(_isInWatchlist ? Icons.check_circle_rounded : Icons.add_circle_rounded, size: 22),
            label: Text(_isInWatchlist ? 'В списке' : 'В список'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isInWatchlist ? ModernColors.success : ModernColors.primaryPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ModernRadius.md)),
              elevation: 0,
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
              child: const Icon(Icons.description_rounded, size: 18, color: Colors.white),
            ),
            const SizedBox(width: ModernSpacing.md),
            const Text('Описание', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          ],
        ),
        const SizedBox(height: ModernSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: Glassmorphism.glassCard(opacity: 0.05, borderRadius: ModernRadius.lg),
          child: Text(
            movie.overview?.isNotEmpty == true ? movie.overview! : 'Описание отсутствует',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 15, height: 1.7),
          ),
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
