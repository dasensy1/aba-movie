import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import 'widgets/status_rating_widget.dart';

/// ============================================================================
/// MOVIE DETAIL SCREEN - УЛУЧШЕННЫЙ UI
/// ============================================================================
/// Экран деталей фильма с функцией треккинга
/// ============================================================================

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;

  const MovieDetailScreen({
    Key? key,
    required this.movie,
  }) : super(key: key);

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  late Movie _currentMovie;
  bool _isFavorite = false;
  bool _isInWatchlist = false;
  WatchStatus _watchStatus = WatchStatus.wantToWatch;
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _currentMovie = widget.movie;
    _checkStatuses();
    _loadFullDetails();
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
      }
    });
  }

  /// Загрузка полного описания из API
  Future<void> _loadFullDetails() async {
    if (_currentMovie.overview != null && _currentMovie.overview!.length > 50) return;
    if (_currentMovie.imdbId == null) return;

    setState(() => _isLoadingDetails = true);

    try {
      final apiService = OmdbApiService();
      final fullMovie = await apiService.getMovieDetails(_currentMovie.imdbId!);

      if (fullMovie != null && mounted) {
        setState(() {
          _currentMovie = fullMovie;
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final provider = context.read<FavoritesProvider>();
    final added = await provider.toggleFavorite(_currentMovie);

    if (mounted) {
      setState(() {
        _isFavorite = added;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(added ? Icons.favorite : Icons.favorite_border, size: 20),
              const SizedBox(width: 8),
              Text(added ? 'Добавлено в избранное' : 'Удалено из избранного'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: added ? const Color(0xFF7C4DFF) : null,
        ),
      );
    }
  }

  Future<void> _toggleWatchlist() async {
    final provider = context.read<WatchlistProvider>();

    if (_isInWatchlist) {
      // Удаляем из треккинга
      await provider.removeFromWatchlist(_currentMovie.id);
      setState(() {
        _isInWatchlist = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Удалено из треккинга'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Показываем выбор статуса перед добавлением
      final selectedStatus = await _showStatusSelection();
      if (selectedStatus != null) {
        await provider.addToWatchlist(_currentMovie, status: selectedStatus);
        setState(() {
          _isInWatchlist = true;
          _watchStatus = selectedStatus;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Добавлено: ${selectedStatus.nameRu}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF00E5FF),
            ),
          );
        }
      }
    }
  }

  /// Показать выбор статуса
  Future<WatchStatus?> _showStatusSelection() async {
    return await showModalBottomSheet<WatchStatus>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Выберите статус',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ...WatchStatus.values.map((status) => _buildStatusOption(status)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(WatchStatus status) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, status),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                status.icon,
                color: _getStatusColor(status),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.nameRu,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    status.shortNameRu,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(WatchStatus status) {
    switch (status) {
      case WatchStatus.wantToWatch:
        return const Color(0xFF7C4DFF);
      case WatchStatus.watching:
        return const Color(0xFF00E5FF);
      case WatchStatus.watched:
        return Colors.green;
      case WatchStatus.dropped:
        return Colors.red;
    }
  }

  Future<void> _updateStatus(WatchStatus status) async {
    if (!_isInWatchlist) {
      await _toggleWatchlist();
    }
    await context.read<WatchlistProvider>().updateStatus(_currentMovie.id, status);
    setState(() {
      _watchStatus = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    final movie = _currentMovie;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(movie.gradientColors[0]),
              Color(movie.gradientColors[1]),
              const Color(0xFF0D0D0D),
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // App Bar
            _buildAppBar(movie),
            // Контент
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Постер и действия
                  _buildPosterAndActions(movie),
                  const SizedBox(height: 24),
                  // Описание
                  _buildDescription(movie),
                  const SizedBox(height: 24),
                  // Информация
                  _buildInfoSection(movie),
                  const SizedBox(height: 24),
                  // Треккинг
                  _buildWatchlistSection(movie),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// App Bar
  Widget _buildAppBar(Movie movie) {
    return SliverAppBar(
      expandedHeight: 350,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // Кнопка треккинга
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isInWatchlist 
                  ? const Color(0xFF00E5FF).withOpacity(0.3)
                  : Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
              border: Border.all(
                color: _isInWatchlist 
                    ? const Color(0xFF00E5FF)
                    : Colors.white.withOpacity(0.2),
              ),
            ),
            child: Icon(
              _isInWatchlist ? Icons.checklist : Icons.add_task,
              color: _isInWatchlist ? const Color(0xFF00E5FF) : Colors.white,
              size: 22,
            ),
          ),
          onPressed: _toggleWatchlist,
          tooltip: _isInWatchlist ? 'В треккинге' : 'Добавить в треккинг',
        ),
        const SizedBox(width: 8),
        // Кнопка избранного
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isFavorite 
                  ? Colors.red.withOpacity(0.3)
                  : Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
              border: Border.all(
                color: _isFavorite ? Colors.red : Colors.white.withOpacity(0.2),
              ),
            ),
            child: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.white,
              size: 22,
            ),
          ),
          onPressed: _toggleFavorite,
          tooltip: _isFavorite ? 'В избранном' : 'В избранное',
        ),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Декоративные элементы
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            // Заголовок
            Positioned(
              bottom: 80,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C4DFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Фильм',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    movie.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (movie.voteAverage > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getRatingColor(movie.voteAverage).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star, color: Colors.white, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                movie.voteAverage.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 12),
                      if (movie.releaseYear.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            movie.releaseYear,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Постер и кнопки действий
  Widget _buildPosterAndActions(Movie movie) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Постер
          Container(
            width: 120,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF1A1A1A),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
              image: movie.posterUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(movie.posterUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: movie.posterUrl.isEmpty
                ? const Center(
                    child: Icon(Icons.movie, size: 50, color: Colors.grey),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          // Информация и действия
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Чипсы с информацией
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (movie.releaseYear.isNotEmpty)
                      _buildInfoChip(Icons.calendar_today, movie.releaseYear),
                    if (movie.runtime != null)
                      _buildInfoChip(Icons.access_time, '${movie.runtime} мин'),
                  ],
                ),
                const SizedBox(height: 16),
                // Кнопки действий
                _buildActionButton(
                  icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                  label: _isFavorite ? 'В избранном' : 'В избранное',
                  color: _isFavorite ? Colors.red : const Color(0xFF7C4DFF),
                  onPressed: _toggleFavorite,
                ),
                const SizedBox(height: 8),
                _buildActionButton(
                  icon: _isInWatchlist ? Icons.checklist : Icons.add_task,
                  label: _isInWatchlist ? 'В треккинге' : 'Добавить в треккинг',
                  color: _isInWatchlist ? const Color(0xFF00E5FF) : const Color(0xFF00E5FF),
                  onPressed: _toggleWatchlist,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Описание
  Widget _buildDescription(Movie movie) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C4DFF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.description, color: Color(0xFF7C4DFF), size: 20),
              ),
              const SizedBox(width: 8),
              const Text(
                'О фильме',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingDetails)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C4DFF)),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF333333)),
              ),
              child: Text(
                movie.overview ?? 'Описание отсутствует для данного фильма.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[400],
                  height: 1.6,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Информация
  Widget _buildInfoSection(Movie movie) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.info_outline, color: Color(0xFF00E5FF), size: 20),
              ),
              const SizedBox(width: 8),
              const Text(
                'Информация',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF333333)),
            ),
            child: Column(
              children: [
                _buildInfoRow('ID', movie.imdbId ?? movie.id.toString()),
                const Divider(height: 1, color: Color(0xFF333333)),
                _buildInfoRow('Рейтинг', '${movie.voteAverage} (${movie.voteCount} голосов)'),
                if (movie.originalLanguage != null) ...[
                  const Divider(height: 1, color: Color(0xFF333333)),
                  _buildInfoRow('Язык', movie.originalLanguage!),
                ],
                if (movie.status != null) ...[
                  const Divider(height: 1, color: Color(0xFF333333)),
                  _buildInfoRow('Статус', movie.status!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Секция треккинга
  Widget _buildWatchlistSection(Movie movie) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.track_changes, color: Color(0xFF00E5FF), size: 20),
              ),
              const SizedBox(width: 8),
              const Text(
                'Трекинг',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF333333)),
            ),
            child: StatusRatingWidget(
              movieId: movie.id,
              initialStatus: _watchStatus,
              isInWatchlist: _isInWatchlist,
              onStatusChanged: _updateStatus,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 7) return Colors.green;
    if (rating >= 5) return Colors.orange;
    return Colors.red;
  }
}
