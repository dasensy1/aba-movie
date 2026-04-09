import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import 'widgets/status_rating_widget.dart';
import 'widgets/reviews_widget.dart';

/// ============================================================================
/// MOVIE DETAIL SCREEN - УЛУЧШЕННЫЙ UI
/// ============================================================================
/// Экран деталей фильма с функцией треккинга и счетчиком просмотров
/// ============================================================================

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;

  const MovieDetailScreen({
    super.key,
    required this.movie,
  });

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  late Movie _currentMovie;
  bool _isFavorite = false;
  bool _isInWatchlist = false;
  WatchStatus _watchStatus = WatchStatus.wantToWatch;
  int _watchCount = 0;

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
        _watchCount = watchlistMovie.watchCount;
      } else {
        _isInWatchlist = false;
        _watchCount = 0;
      }
    });
  }

  /// Загрузка полного описания из API (через MoviesProvider, не напрямую)
  Future<void> _loadFullDetails() async {
    if (_currentMovie.overview != null && _currentMovie.overview!.length > 50) return;
    if (_currentMovie.imdbId == null) return;

    try {
      final moviesProvider = context.read<MoviesProvider>();
      final fullMovie = await moviesProvider.getMovieDetails(_currentMovie.imdbId!);

      if (fullMovie != null && mounted) {
        setState(() {
          _currentMovie = fullMovie;
        });
      }
    } catch (e) {
      debugPrint('Error loading movie details: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<FavoritesProvider>();
    final added = await provider.toggleFavorite(_currentMovie, auth.userId);

    if (mounted) {
      setState(() {
        _isFavorite = added;
      });
    }
  }

  Future<void> _toggleWatchlist() async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<WatchlistProvider>();

    if (_isInWatchlist) {
      await provider.removeFromWatchlist(_currentMovie.id, auth.userId);
      setState(() {
        _isInWatchlist = false;
        _watchCount = 0;
      });
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
          backgroundColor: Colors.green,
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
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(20),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Выберите статус',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                ...WatchStatus.values.map((status) => GestureDetector(
                  onTap: () {
                    setModalState(() {
                      selectedStatus = status;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selectedStatus == status
                          ? _getStatusColor(status).withValues(alpha: 0.2)
                          : const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedStatus == status
                            ? _getStatusColor(status)
                            : const Color(0xFF333333),
                        width: selectedStatus == status ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(status.icon, color: _getStatusColor(status)),
                        const SizedBox(width: 12),
                        Text(status.nameRu, style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                )),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF333333)),
                const SizedBox(height: 8),
                const Text(
                  'Дата просмотра',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final now = DateTime.now();
                    final messenger = ScaffoldMessenger.of(context);
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: now,
                      firstDate: DateTime(1900),
                      lastDate: now,
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFF7C4DFF),
                              onPrimary: Colors.white,
                              surface: Color(0xFF1A1A1A),
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );

                    if (pickedDate != null) {
                      // Проверка на будущую дату (дополнительная)
                      if (pickedDate.isAfter(now)) {
                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Нельзя выбрать будущую дату!'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      setModalState(() {
                        selectedDate = pickedDate;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF333333)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Color(0xFF7C4DFF)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedDate != null
                                ? '${selectedDate!.day.toString().padLeft(2, '0')}.${selectedDate!.month.toString().padLeft(2, '0')}.${selectedDate!.year}'
                                : 'Выберите дату (необязательно)',
                            style: TextStyle(
                              color: selectedDate != null ? Colors.white : Colors.grey[500],
                            ),
                          ),
                        ),
                        if (selectedDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.red),
                            onPressed: () {
                              setModalState(() {
                                selectedDate = null;
                              });
                            },
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
                      backgroundColor: const Color(0xFF7C4DFF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Добавить',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(WatchStatus status) {
    switch (status) {
      case WatchStatus.wantToWatch: return const Color(0xFF7C4DFF);
      case WatchStatus.watching: return const Color(0xFF00E5FF);
      case WatchStatus.watched: return Colors.green;
      case WatchStatus.dropped: return Colors.red;
    }
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
            colors: [Color(movie.gradientColors[0]), Color(movie.gradientColors[1]), const Color(0xFF0D0D0D)],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(movie),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildPosterAndActions(movie),
                  // НОВАЯ КАЗУАЛЬНАЯ КНОПКА
                  if (_isInWatchlist) _buildQuickAddButton(),
                  _buildDescription(movie),
                  _buildWatchlistSection(movie),
                  const SizedBox(height: 24),
                  // Обзоры
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ReviewsWidget(movieId: movie.id),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFF00E5FF)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFF7C4DFF).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: InkWell(
          onTap: _incrementCount,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_circle, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ПОСМОТРЕЛ ЕЩЕ РАЗ',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  Text(
                    'Всего просмотров: $_watchCount',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(Movie movie) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(movie.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 10)])),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (movie.posterUrl.isNotEmpty) Image.network(movie.posterUrl, fit: BoxFit.cover),
            Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xFF0D0D0D)]))),
          ],
        ),
      ),
    );
  }

  Widget _buildPosterAndActions(Movie movie) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: _toggleWatchlist,
            icon: Icon(_isInWatchlist ? Icons.check : Icons.add),
            label: Text(_isInWatchlist ? 'В треккинге' : 'Добавить'),
            style: ElevatedButton.styleFrom(backgroundColor: _isInWatchlist ? Colors.green : const Color(0xFF7C4DFF)),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(Movie movie) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(movie.overview ?? 'Нет описания', style: const TextStyle(color: Colors.grey, fontSize: 14)),
    );
  }

  Widget _buildWatchlistSection(Movie movie) {
    return Padding(
      padding: const EdgeInsets.all(20),
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
