import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/modern_ui.dart';
import 'actor_detail_screen.dart';
import 'movie_collection_screen.dart';
import 'widgets/reviews_widget.dart';
import 'widgets/status_rating_widget.dart';

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
    if (!mounted) return;
    setState(() => _scrollOffset = _scrollController.offset);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkStatuses() {
    final favoritesProvider = context.read<FavoritesProvider>();
    final watchlistProvider = context.read<WatchlistProvider>();

    final watchlistMovie = watchlistProvider.getWatchlistMovie(
      _currentMovie.id,
    );
    setState(() {
      _isFavorite = favoritesProvider.isFavoriteNow(_currentMovie.id);
      _isInWatchlist = watchlistMovie != null;
      _watchStatus = watchlistMovie?.status ?? WatchStatus.wantToWatch;
      _watchCount = watchlistMovie?.watchCount ?? 0;
    });
  }

  Future<void> _loadFullDetails() async {
    if (_currentMovie.credits != null &&
        _currentMovie.credits!.isNotEmpty &&
        _currentMovie.genreNames.isNotEmpty) {
      return;
    }

    try {
      final fullMovie = await context.read<MoviesProvider>().getMovieDetails(
        _currentMovie.id,
      );
      if (mounted && fullMovie != null) {
        setState(() => _currentMovie = fullMovie);
      }
    } catch (e) {
      debugPrint('Error loading movie details: $e');
    }
  }

  Future<void> _loadSimilarMovies() async {
    try {
      final movies = await context.read<MoviesProvider>().getSimilarMovies(
        _currentMovie.id,
      );
      if (mounted) {
        setState(() => _similarMovies = movies);
      }
    } catch (e) {
      debugPrint('Error loading similar movies: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    final auth = context.read<AuthProvider>();
    final favorites = context.read<FavoritesProvider>();
    final added = await favorites.toggleFavorite(_currentMovie, auth.userId);
    if (mounted) {
      setState(() => _isFavorite = added);
    }
  }

  Future<void> _toggleWatchlist() async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<WatchlistProvider>();

    if (_isInWatchlist) {
      await provider.removeFromWatchlist(_currentMovie.id, auth.userId);
      _checkStatuses();
      return;
    }

    final result = await _showStatusSelection();
    if (result != null) {
      final (status, watchedDate) = result;
      await provider.addToWatchlist(
        _currentMovie,
        auth.userId,
        status: status,
        watchedDate: watchedDate,
      );
      _checkStatuses();
    }
  }

  Future<void> _incrementCount() async {
    final auth = context.read<AuthProvider>();
    await context.read<WatchlistProvider>().incrementWatchCount(
      _currentMovie.id,
      auth.userId,
    );
    _checkStatuses();
  }

  Future<void> _launchTrailer() async {
    final key = _currentMovie.youtubeTrailerKey;
    final uri = key != null
        ? Uri.parse('https://www.youtube.com/watch?v=$key')
        : Uri.parse(
            'https://www.youtube.com/results?search_query='
            '${Uri.encodeComponent('${_currentMovie.title} ${_currentMovie.releaseYear} trailer')}',
          );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openGenre(int genreId, String genreName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MovieCollectionScreen(
          title: genreName,
          subtitle: 'Фильмы в жанре $genreName',
          genreId: genreId,
        ),
      ),
    );
  }

  Future<(WatchStatus, DateTime?)?> _showStatusSelection() async {
    WatchStatus? selectedStatus;
    DateTime? selectedDate;

    return showModalBottomSheet<(WatchStatus, DateTime?)>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: Glassmorphism.glassBottomSheet,
          padding: const EdgeInsets.all(20),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Добавить в список',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...WatchStatus.values.map((status) {
                    final selected = selectedStatus == status;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedStatus = status),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selected
                              ? _getStatusColor(status).withValues(alpha: 0.16)
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? _getStatusColor(
                                    status,
                                  ).withValues(alpha: 0.45)
                                : Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(status.icon, color: _getStatusColor(status)),
                            const SizedBox(width: 12),
                            Text(
                              status.nameRu,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final now = DateTime.now();
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: DateTime(1900),
                        lastDate: now,
                      );
                      if (pickedDate != null) {
                        setModalState(() => selectedDate = pickedDate);
                      }
                    },
                    icon: const Icon(Icons.calendar_today_rounded),
                    label: Text(
                      selectedDate == null
                          ? 'Указать дату просмотра'
                          : '${selectedDate!.day.toString().padLeft(2, '0')}.'
                                '${selectedDate!.month.toString().padLeft(2, '0')}.'
                                '${selectedDate!.year}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedStatus == null
                          ? null
                          : () => Navigator.pop(context, (
                              selectedStatus!,
                              selectedDate,
                            )),
                      child: const Text('Сохранить'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(WatchStatus status) {
    switch (status) {
      case WatchStatus.wantToWatch:
        return ModernColors.primaryPurple;
      case WatchStatus.watching:
        return ModernColors.accentCyan;
      case WatchStatus.watched:
        return ModernColors.success;
      case WatchStatus.dropped:
        return ModernColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = _currentMovie;
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 900;
    final backdropUrl =
        movie.backdropPath != null && movie.backdropPath!.isNotEmpty
        ? 'https://image.tmdb.org/t/p/w1280${movie.backdropPath}'
        : movie.posterUrl;

    return Scaffold(
      backgroundColor: ModernColors.backgroundDark,
      body: Stack(
        children: [
          Positioned.fill(
            child: backdropUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: backdropUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorWidget: (_, __, ___) => _buildBackdropFallback(),
                    placeholder: (_, __) => _buildBackdropFallback(),
                  )
                : _buildBackdropFallback(),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.18),
                    Colors.black.withValues(alpha: 0.52),
                    ModernColors.backgroundDark.withValues(alpha: 0.92),
                    ModernColors.backgroundDark,
                  ],
                  stops: const [0.0, 0.28, 0.58, 1.0],
                ),
              ),
            ),
          ),
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildAppBar(movie),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isWide ? 32 : 16,
                    110,
                    isWide ? 32 : 16,
                    40,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderSection(movie, isWide),
                          const SizedBox(height: 24),
                          _buildDescriptionSection(movie),
                          const SizedBox(height: 24),
                          _buildWatchlistSection(movie),
                          const SizedBox(height: 24),
                          _buildActorsAndSimilar(),
                          const SizedBox(height: 24),
                          ReviewsWidget(movieId: movie.id),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(Movie movie) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: AnimatedOpacity(
        opacity: _scrollOffset > 120 ? 1 : 0,
        duration: ModernAnimations.fast,
        child: Text(movie.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: _isFavorite ? ModernColors.accentPink : Colors.white,
          ),
          onPressed: _toggleFavorite,
        ),
      ],
    );
  }

  Widget _buildHeaderSection(Movie movie, bool isWide) {
    final genreChips = _buildGenreChips(movie);
    final infoCards = _buildInfoCards(movie);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F131A).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPoster(movie, width: 260),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleArea(movie),
                      const SizedBox(height: 16),
                      Wrap(spacing: 10, runSpacing: 10, children: infoCards),
                      if (genreChips.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Wrap(spacing: 8, runSpacing: 8, children: genreChips),
                      ],
                      const SizedBox(height: 22),
                      _buildActionRow(),
                      if (_isInWatchlist) ...[
                        const SizedBox(height: 12),
                        _buildQuickAddButton(),
                      ],
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPoster(movie, width: 132),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTitleArea(movie)),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(spacing: 10, runSpacing: 10, children: infoCards),
                if (genreChips.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(spacing: 8, runSpacing: 8, children: genreChips),
                ],
                const SizedBox(height: 20),
                _buildActionRow(),
                if (_isInWatchlist) ...[
                  const SizedBox(height: 12),
                  _buildQuickAddButton(),
                ],
              ],
            ),
    );
  }

  Widget _buildPoster(Movie movie, {required double width}) {
    final height = width * 1.5;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFF171C25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: movie.posterUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: movie.posterUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _buildPosterFallback(),
              placeholder: (_, __) => _buildPosterFallback(),
            )
          : _buildPosterFallback(),
    );
  }

  Widget _buildPosterFallback() {
    return Container(
      color: const Color(0xFF171C25),
      child: const Center(
        child: Icon(
          Icons.movie_creation_outlined,
          color: Colors.white38,
          size: 42,
        ),
      ),
    );
  }

  Widget _buildBackdropFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF232834), Color(0xFF11151D)],
        ),
      ),
    );
  }

  Widget _buildTitleArea(Movie movie) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          movie.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        if ((movie.tagline ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            movie.tagline!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildInfoCards(Movie movie) {
    final cards = <Widget>[];

    if (movie.releaseYear.isNotEmpty) {
      cards.add(_buildMetaCard('Год', movie.releaseYear));
    }
    if (movie.runtime != null && movie.runtime! > 0) {
      cards.add(_buildMetaCard('Длительность', '${movie.runtime} мин'));
    }
    if (movie.voteAverage > 0) {
      cards.add(
        _buildMetaCard('Рейтинг', movie.voteAverage.toStringAsFixed(1)),
      );
    }
    if (movie.voteCount > 0) {
      cards.add(_buildMetaCard('Оценок', movie.voteCount.toString()));
    }
    if ((movie.originalLanguage ?? '').isNotEmpty) {
      cards.add(_buildMetaCard('Язык', movie.originalLanguage!.toUpperCase()));
    }

    return cards;
  }

  Widget _buildMetaCard(String label, String value) {
    return Container(
      constraints: const BoxConstraints(minWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.48),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGenreChips(Movie movie) {
    if (movie.genres == null || movie.genres!.isEmpty) {
      return [];
    }

    return movie.genres!
        .map(
          (genre) => InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () =>
                _openGenre(genre['id'] as int, genre['name'] as String),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    genre['name'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_outward_rounded,
                    size: 14,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),
        )
        .toList();
  }

  Widget _buildActionRow() {
    final isCompact = MediaQuery.sizeOf(context).width < 380;

    final trailerButton = ElevatedButton.icon(
      onPressed: _launchTrailer,
      icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
      label: const Text(
        'РўСЂРµР№Р»РµСЂ',
        style: TextStyle(color: Colors.black),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );

    final watchlistButton = ElevatedButton.icon(
      onPressed: _toggleWatchlist,
      icon: Icon(
        _isInWatchlist
            ? Icons.check_circle_rounded
            : Icons.add_circle_outline_rounded,
      ),
      label: Text(_isInWatchlist ? 'Р’ СЃРїРёСЃРєРµ' : 'Р’ СЃРїРёСЃРѕРє'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [trailerButton, const SizedBox(height: 12), watchlistButton],
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _launchTrailer,
            icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
            label: const Text('Трейлер', style: TextStyle(color: Colors.black)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _toggleWatchlist,
            icon: Icon(
              _isInWatchlist
                  ? Icons.check_circle_rounded
                  : Icons.add_circle_outline_rounded,
            ),
            label: Text(_isInWatchlist ? 'В списке' : 'В список'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAddButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _incrementCount,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            const Icon(Icons.repeat_rounded, color: Colors.white70),
            const SizedBox(width: 10),
            Text(
              'Количество просмотров: $_watchCount',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection(Movie movie) {
    return _buildPanel(
      title: 'Описание',
      child: Text(
        movie.synopsis,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.82),
          fontSize: 15,
          height: 1.7,
        ),
      ),
    );
  }

  Widget _buildWatchlistSection(Movie movie) {
    return _buildPanel(
      title: 'Статус и оценка',
      child: StatusRatingWidget(
        movieId: movie.id,
        initialStatus: _watchStatus,
        isInWatchlist: _isInWatchlist,
        onStatusChanged: (status) async {
          final auth = context.read<AuthProvider>();
          await context.read<WatchlistProvider>().updateStatus(
            movie.id,
            status,
            auth.userId,
          );
          _checkStatuses();
        },
      ),
    );
  }

  Widget _buildActorsAndSimilar() {
    return Column(
      children: [
        _buildPanel(
          title: 'Актёры',
          child: SizedBox(
            height: 132,
            child: _currentMovie.credits == null
                ? ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 6,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, __) => const Column(
                      children: [
                        SkeletonLoader(width: 72, height: 72, borderRadius: 36),
                        SizedBox(height: 8),
                        SkeletonLoader(width: 64, height: 12, borderRadius: 6),
                      ],
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _currentMovie.credits!.length > 12
                        ? 12
                        : _currentMovie.credits!.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final actor = _currentMovie.credits![index];
                      final profilePath = actor['profile_path'] as String?;
                      final actorId = actor['id'] as int?;
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: actorId != null
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ActorDetailScreen(
                                      actorId: actorId,
                                      actorName:
                                          actor['name']?.toString() ?? '',
                                    ),
                                  ),
                                );
                              }
                            : null,
                        child: SizedBox(
                          width: 86,
                          child: Column(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.06),
                                  image: profilePath != null
                                      ? DecorationImage(
                                          image: CachedNetworkImageProvider(
                                            'https://image.tmdb.org/t/p/w185$profilePath',
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: profilePath == null
                                    ? const Icon(
                                        Icons.person_outline_rounded,
                                        color: Colors.white54,
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                actor['name']?.toString() ?? '',
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
        const SizedBox(height: 24),
        _buildPanel(
          title: 'Похожие фильмы',
          child: SizedBox(
            height: 240,
            child: _similarMovies == null
                ? ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 4,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, __) => const SkeletonLoader(
                      width: 150,
                      height: 220,
                      borderRadius: 18,
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _similarMovies!.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final movie = _similarMovies![index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MovieDetailScreen(movie: movie),
                            ),
                          );
                        },
                        child: Container(
                          width: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: Colors.white.withValues(alpha: 0.04),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: movie.posterUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: movie.posterUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorWidget: (_, __, ___) =>
                                            _buildPosterFallback(),
                                        placeholder: (_, __) =>
                                            _buildPosterFallback(),
                                      )
                                    : _buildPosterFallback(),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  movie.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPanel({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F131A).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
