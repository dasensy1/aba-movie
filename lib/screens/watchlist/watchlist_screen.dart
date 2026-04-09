// ============================================================================
// WATCHLIST SCREEN
// ============================================================================
// Экран трекинга фильмов со статусами: хочу посмотреть, смотрю, просмотрено
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadWatchlist();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    _loadWatchlist();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadWatchlist();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWatchlist() async {
    final auth = context.read<AuthProvider>();
    await context.read<WatchlistProvider>().loadWatchlist(auth.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A0B2E),
              Color(0xFF0D0D0D),
            ],
            stops: [0.0, 0.5],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabs(),
              Expanded(
                child: Consumer<WatchlistProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C4DFF)),
                        ),
                      );
                    }

                    if (provider.watchlist.isEmpty) {
                      return _buildEmptyState();
                    }

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMovieList(provider.wantToWatch),
                        _buildMovieList(provider.watching),
                        _buildMovieList(provider.watched),
                        _buildMovieList(provider.dropped),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Мой треккинг',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
              const Text(
                'Список фильмов',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Spacer(),
          Consumer<WatchlistProvider>(
            builder: (context, provider, _) {
              final stats = provider.getStatistics();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C4DFF).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF7C4DFF).withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF7C4DFF), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${stats['totalWatches']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C4DFF),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Consumer<WatchlistProvider>(
      builder: (context, provider, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF333333)),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: const Color(0xFF7C4DFF),
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: [
              _buildTab('Планы', provider.wantToWatchCount),
              _buildTab('Смотрю', provider.watchingCount),
              _buildTab('Готово', provider.watchedCount),
              _buildTab('Бросил', provider.droppedCount),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab(String label, int count) {
    return Tab(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text('$count', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMovieList(List<WatchlistMovie> movies) {
    if (movies.isEmpty) return _buildEmptyCategory();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        return _buildMovieTile(movie);
      },
    );
  }

  Widget _buildMovieTile(WatchlistMovie movie) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Постер
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                movie.posterUrl,
                width: 60,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 60,
                  height: 90,
                  color: Colors.grey[900],
                  child: const Icon(Icons.movie, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Инфо
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Статус
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(movie.status).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _getStatusColor(movie.status).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(movie.status.icon, size: 12, color: _getStatusColor(movie.status)),
                        const SizedBox(width: 4),
                        Text(
                          movie.status.shortNameRu,
                          style: TextStyle(
                            color: _getStatusColor(movie.status),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Дата просмотра
                  if (movie.watchedDate != null)
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          'Смотрел: ${movie.watchedDateDisplay}',
                          style: TextStyle(color: Colors.grey[500], fontSize: 11),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Счетчик просмотров
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.repeat, size: 12, color: Color(0xFF00E5FF)),
                            const SizedBox(width: 4),
                            Text(
                              '${movie.watchCount}',
                              style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      if (movie.userRating != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star, size: 12, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                movie.ratingDisplay,
                                style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Действия
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFF7C4DFF)),
                  onPressed: () => _showAddWatchDialog(movie),
                  tooltip: 'Добавить просмотр',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (value) => _handleMenuAction(value, movie),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'change_date',
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 20),
                          SizedBox(width: 12),
                          Text('Изменить дату'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'change_status',
                      child: Row(
                        children: [
                          Icon(Icons.swap_horiz, size: 20),
                          SizedBox(width: 12),
                          Text('Изменить статус'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Удалить', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
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

  Future<void> _handleMenuAction(String action, WatchlistMovie movie) async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<WatchlistProvider>();

    switch (action) {
      case 'change_date':
        await _changeWatchDate(movie);
        break;
      case 'change_status':
        final newStatus = await _showStatusChangeDialog(movie);
        if (newStatus != null) {
          await provider.updateStatus(movie.movieId, newStatus, auth.userId);
        }
        break;
      case 'remove':
        await provider.removeFromWatchlist(movie.movieId, auth.userId);
        break;
    }
  }

  Future<void> _changeWatchDate(WatchlistMovie movie) async {
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: movie.watchedDate ?? now,
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
      if (!mounted) return;
      await context.read<WatchlistProvider>().updateStatus(
        movie.movieId,
        movie.status,
        auth.userId,
        watchedDate: pickedDate,
      );
    }
  }

  Future<WatchStatus?> _showStatusChangeDialog(WatchlistMovie movie) async {
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
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            ...WatchStatus.values.map((status) => GestureDetector(
              onTap: () => Navigator.pop(context, status),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: movie.status == status
                      ? _getStatusColor(status).withValues(alpha: 0.2)
                      : const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: movie.status == status
                        ? _getStatusColor(status)
                        : const Color(0xFF333333),
                    width: movie.status == status ? 2 : 1,
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
          ],
        ),
      ),
    );
  }

  Future<void> _showAddWatchDialog(WatchlistMovie movie) async {
    final now = DateTime.now();
    DateTime? selectedDate = now;

    await showModalBottomSheet(
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Добавить просмотр',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Дата просмотра',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? now,
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
                                : 'Выберите дату',
                            style: TextStyle(
                              color: selectedDate != null ? Colors.white : Colors.grey[500],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final auth = context.read<AuthProvider>();
                      context.read<WatchlistProvider>().incrementWatchCount(
                        movie.movieId,
                        auth.userId,
                        watchedDate: selectedDate,
                      );
                      Navigator.pop(context);
                    },
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

  Widget _buildEmptyCategory() {
    return Center(
      child: Text('Пусто', style: TextStyle(color: Colors.grey[600])),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('Ваш треккинг пуст', style: TextStyle(color: Colors.white)),
    );
  }
}
