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
    // Обновляем данные при переключении таба
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A0B2E),
              const Color(0xFF0D0D0D),
            ],
            stops: const [0.0, 0.5],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Заголовок
              _buildHeader(),
              // Табы
              _buildTabs(),
              // Контент
              Expanded(
                child: Consumer<WatchlistProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF7C4DFF),
                          ),
                        ),
                      );
                    }

                    if (provider.watchlist.isEmpty) {
                      return _buildEmptyState();
                    }

                    return _buildTabContent(provider);
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
                  fontWeight: FontWeight.normal,
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
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C4DFF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF7C4DFF).withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.movie_outlined,
                      color: Color(0xFF7C4DFF),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${provider.totalCount}',
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
          margin: const EdgeInsets.symmetric(horizontal: 16),
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
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            dividerColor: Colors.transparent,
            tabs: [
              _buildTab('Планы', provider.wantToWatchCount, Icons.bookmark_border),
              _buildTab('Смотрю', provider.watchingCount, Icons.play_circle_outline),
              _buildTab('Просмотрено', provider.watchedCount, Icons.check_circle_outline),
              _buildTab('Бросил', provider.droppedCount, Icons.cancel_outlined),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab(String label, int count, IconData icon) {
    return Tab(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 4),
              Text(label),
            ],
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(WatchlistProvider provider) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildMovieList(provider.wantToWatch),
        _buildMovieList(provider.watching),
        _buildMovieList(provider.watched),
        _buildMovieList(provider.dropped),
      ],
    );
  }

  Widget _buildMovieList(List<WatchlistMovie> movies) {
    if (movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_outlined,
              size: 80,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 16),
            Text(
              'Здесь пока пусто',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Добавьте фильмы в эту категорию',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

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
    return Dismissible(
      key: Key(movie.movieId.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text('Удалить фильм?'),
            content: Text(
              'Вы уверены, что хотите удалить "${movie.title}" из треккинга?',
              style: TextStyle(color: Colors.grey[400]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Удалить'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        await context.read<WatchlistProvider>().removeFromWatchlist(movie.movieId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${movie.title} удалён из треккинга'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: InkWell(
          onTap: () {
            // Переход к деталям фильма (нужно создать Movie из WatchlistMovie)
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Постер
                Container(
                  width: 60,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFF2A2A2A),
                    image: movie.posterUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(movie.posterUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: movie.posterUrl.isEmpty
                      ? const Center(
                          child: Icon(Icons.movie, size: 24, color: Colors.grey),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Информация
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Статус
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(movie.status).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  movie.status.icon,
                                  size: 12,
                                  color: _getStatusColor(movie.status),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  movie.status.shortNameRu,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _getStatusColor(movie.status),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Оценка
                          if (movie.userRating != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 12,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    movie.ratingDisplay,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.amber,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const Spacer(),
                          // Дата
                          if (movie.watchedDate != null)
                            Text(
                              movie.watchedDateDisplay,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Кнопка меню статуса
                PopupMenuButton<WatchStatus>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  color: const Color(0xFF1A1A1A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (status) async {
                    await context
                        .read<WatchlistProvider>()
                        .updateStatus(movie.movieId, status);
                  },
                  itemBuilder: (context) => [
                    _buildPopupItem(WatchStatus.wantToWatch),
                    _buildPopupItem(WatchStatus.watching),
                    _buildPopupItem(WatchStatus.watched),
                    _buildPopupItem(WatchStatus.dropped),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<WatchStatus> _buildPopupItem(WatchStatus status) {
    return PopupMenuItem(
      value: status,
      child: Row(
        children: [
          Icon(status.icon, size: 20, color: _getStatusColor(status)),
          const SizedBox(width: 8),
          Text(
            status.nameRu,
            style: const TextStyle(color: Colors.white),
          ),
        ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF7C4DFF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.track_changes,
              size: 80,
              color: Color(0xFF7C4DFF),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Трекинг фильмов пуст',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Добавляйте фильмы в треккинг,\nчтобы отслеживать просмотр',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Переход на главную
            },
            icon: const Icon(Icons.movie_outlined),
            label: const Text('Найти фильмы'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C4DFF),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
