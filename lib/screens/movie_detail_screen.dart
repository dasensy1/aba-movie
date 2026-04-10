import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/modern_ui.dart';
import 'widgets/status_rating_widget.dart';
import 'widgets/reviews_widget.dart';

/// ============================================================================
/// MOVIE DETAIL SCREEN — Красивый, адаптивный, удобный для смартфонов
/// ============================================================================

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
  bool _loadingDetails = false;

  @override
  void initState() {
    super.initState();
    _currentMovie = widget.movie;
    _checkStatuses();
    _loadFullDetails();
  }

  void _checkStatuses() {
    final fav = context.read<FavoritesProvider>();
    final wl = context.read<WatchlistProvider>();
    setState(() {
      _isFavorite = fav.isFavoriteNow(_currentMovie.id);
      final wm = wl.getWatchlistMovie(_currentMovie.id);
      if (wm != null) {
        _isInWatchlist = true;
        _watchStatus = wm.status;
        _watchCount = wm.watchCount;
      }
    });
  }

  Future<void> _loadFullDetails() async {
    if (_currentMovie.overview != null && _currentMovie.overview!.length > 50) return;
    if (_loadingDetails) return;

    setState(() => _loadingDetails = true);
    try {
      final mp = context.read<MoviesProvider>();
      final full = await mp.getMovieDetails(_currentMovie.id);
      if (full != null && mounted) {
        setState(() => _currentMovie = full);
      }
    } catch (e) {
      debugPrint('Error loading details: $e');
    } finally {
      if (mounted) setState(() => _loadingDetails = false);
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
        final (status, date) = result;
        await provider.addToWatchlist(_currentMovie, auth.userId, status: status, watchedDate: date);
        _checkStatuses();
      }
    }
  }

  Future<void> _incrementCount() async {
    final auth = context.read<AuthProvider>();
    await context.read<WatchlistProvider>().incrementWatchCount(_currentMovie.id, auth.userId);
    _checkStatuses();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Просмотр добавлен! Всего: $_watchCount'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<(WatchStatus, DateTime?)?> _showStatusSelection() async {
    WatchStatus? selectedStatus;
    DateTime? selectedDate;

    return showModalBottomSheet<(WatchStatus, DateTime?)>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Статус просмотра', style: Theme.of(context).textTheme.titleLarge),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...WatchStatus.values.map((status) {
                    final isSelected = selectedStatus == status;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedStatus = status),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _statusColor(status).withValues(alpha: 0.15)
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? _statusColor(status) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(status.icon, color: _statusColor(status)),
                            const SizedBox(width: 12),
                            Text(status.nameRu, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  const Text('Дата просмотра (необязательно)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: DateTime(1900),
                        lastDate: now,
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded),
                          const SizedBox(width: 12),
                          Text(
                            selectedDate != null
                                ? '${selectedDate!.day.toString().padLeft(2, '0')}.${selectedDate!.month.toString().padLeft(2, '0')}.${selectedDate!.year}'
                                : 'Выберите дату',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedStatus != null
                          ? () => Navigator.pop(context, (selectedStatus!, selectedDate))
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Добавить', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _statusColor(WatchStatus s) {
    switch (s) {
      case WatchStatus.wantToWatch: return const Color(0xFF7C5CFC);
      case WatchStatus.watching: return const Color(0xFF06B6D4);
      case WatchStatus.watched: return const Color(0xFF10B981);
      case WatchStatus.dropped: return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = _currentMovie;
    final theme = Theme.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 700;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar с backdrop
          _buildSliverAppBar(movie, theme),

          // Контент
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isWide ? 48 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  if (isWide)
                    _buildWideHeader(movie, theme)
                  else
                    _buildMobileHeader(movie, theme),

                  const SizedBox(height: 24),

                  // Описание
                  _buildDescription(movie, theme),

                  const SizedBox(height: 24),

                  // Кнопки действий
                  _buildActionButtons(movie, theme),

                  const SizedBox(height: 20),

                  // Быстрая кнопка «Посмотрел ещё раз»
                  if (_isInWatchlist) _buildQuickAddButton(theme),

                  const SizedBox(height: 24),

                  // Статус и рейтинг
                  StatusRatingWidget(
                    movieId: movie.id,
                    initialStatus: _watchStatus,
                    isInWatchlist: _isInWatchlist,
                    onStatusChanged: (s) async {
                      final auth = context.read<AuthProvider>();
                      await context.read<WatchlistProvider>().updateStatus(movie.id, s, auth.userId);
                      _checkStatuses();
                    },
                  ),

                  const SizedBox(height: 24),

                  // Обзоры
                  ReviewsWidget(movieId: movie.id),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== SLIVER APP BAR ==========
  Widget _buildSliverAppBar(Movie movie, ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          movie.title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 12, color: Colors.black)],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (movie.backdropPath != null && movie.backdropPath!.isNotEmpty)
              Image.network(
                'https://image.tmdb.org/t/p/w780${movie.backdropPath}',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(gradient: ModernGradients.heroGradient),
                ),
              )
            else
              Container(decoration: const BoxDecoration(gradient: ModernGradients.heroGradient)),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== MOBILE HEADER ==========
  Widget _buildMobileHeader(Movie movie, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Постер
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 120,
            height: 180,
            child: movie.posterPath != null && movie.posterPath!.isNotEmpty
                ? Image.network(
                    'https://image.tmdb.org/t/p/w300${movie.posterPath}',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _posterPlaceholder(),
                  )
                : _posterPlaceholder(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(movie.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              _buildMetaRow(movie, theme),
              const SizedBox(height: 12),
              _buildRatingBadge(movie),
            ],
          ),
        ),
      ],
    );
  }

  // ========== WIDE HEADER ==========
  Widget _buildWideHeader(Movie movie, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: 180,
            height: 270,
            child: movie.posterPath != null && movie.posterPath!.isNotEmpty
                ? Image.network(
                    'https://image.tmdb.org/t/p/w500${movie.posterPath}',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _posterPlaceholder(),
                  )
                : _posterPlaceholder(),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(movie.title, style: theme.textTheme.displaySmall),
              const SizedBox(height: 12),
              _buildMetaRow(movie, theme),
              const SizedBox(height: 16),
              _buildRatingBadge(movie),
            ],
          ),
        ),
      ],
    );
  }

  Widget _posterPlaceholder() {
    return Container(
      decoration: const BoxDecoration(gradient: ModernGradients.primaryGradient),
      child: const Center(child: Icon(Icons.movie_rounded, size: 48, color: Colors.white)),
    );
  }

  Widget _buildMetaRow(Movie movie, ThemeData theme) {
    final parts = <String>[];
    if (movie.releaseYear.isNotEmpty) parts.add(movie.releaseYear);
    if (movie.runtime != null) parts.add('${movie.runtime} мин');
    if (movie.originalLanguage != null) parts.add(movie.originalLanguage!.toUpperCase());

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        ...parts.map((p) => Chip(label: Text(p), visualDensity: VisualDensity.compact)),
      ],
    );
  }

  Widget _buildRatingBadge(Movie movie) {
    if (movie.voteCount == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC857).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFFFC857), size: 20),
          const SizedBox(width: 6),
          Text(
            '${movie.voteAverage.toStringAsFixed(1)} / 10',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(width: 8),
          Text(
            '(${movie.voteCount})',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(Movie movie, ThemeData theme) {
    if (_loadingDetails) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Синопсис', style: theme.textTheme.titleMedium),
              const SizedBox(width: 8),
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_rounded, size: 20),
              const SizedBox(width: 8),
              Text('Синопсис', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            movie.synopsis,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Movie movie, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _toggleWatchlist,
            icon: Icon(_isInWatchlist ? Icons.check_circle_rounded : Icons.bookmark_add_rounded),
            label: Text(_isInWatchlist ? 'В треккинге' : 'В трекер'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isInWatchlist ? const Color(0xFF10B981) : ModernColors.primaryPurple,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          onPressed: _toggleFavorite,
          icon: Icon(_isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded),
          iconSize: 28,
          color: _isFavorite ? const Color(0xFFEF4444) : null,
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAddButton(ThemeData theme) {
    return InkWell(
      onTap: _incrementCount,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: ModernGradients.primaryGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.add_circle_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ПОСМОТРЕЛ ЕЩЁ РАЗ',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                ),
                Text(
                  'Всего просмотров: $_watchCount',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
