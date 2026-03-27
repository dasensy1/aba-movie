/// ============================================================================
/// WATCHLIST SCREEN
/// ============================================================================
/// Экран трекинга фильмов со статусами: хочу посмотреть, смотрю, просмотрено
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({Key? key}) : super(key: key);

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
    await context.read<WatchlistProvider>().loadWatchlist();
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
                  color: const Color(0xFF7C4DFF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF7C4DFF).withOpacity(0.5)),
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
                  Row(
                    children: [
                      Icon(Icons.history, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        movie.updatedDateDisplay,
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
                          color: const Color(0xFF00E5FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.repeat, size: 12, color: Color(0xFF00E5FF)),
                            const SizedBox(width: 4),
                            Text(
                              'Просмотров: ${movie.watchCount}',
                              style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
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
                  onPressed: () => context.read<WatchlistProvider>().incrementWatchCount(movie.movieId),
                  tooltip: 'Добавить просмотр',
                ),
                PopupMenuButton<WatchStatus>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (status) => context.read<WatchlistProvider>().updateStatus(movie.movieId, status),
                  itemBuilder: (context) => WatchStatus.values.map((s) => PopupMenuItem(
                    value: s,
                    child: Text(s.nameRu),
                  )).toList(),
                ),
              ],
            ),
          ],
        ),
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
