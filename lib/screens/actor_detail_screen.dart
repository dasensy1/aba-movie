import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/services.dart';
import '../utils/modern_ui.dart';
import 'movie_detail_screen.dart';

class ActorDetailScreen extends StatefulWidget {
  final int actorId;
  final String actorName;

  const ActorDetailScreen({
    super.key,
    required this.actorId,
    required this.actorName,
  });

  @override
  State<ActorDetailScreen> createState() => _ActorDetailScreenState();
}

class _ActorDetailScreenState extends State<ActorDetailScreen> {
  Map<String, dynamic>? _actorDetails;
  List<Movie>? _movieCredits;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActorDetails();
  }

  Future<void> _loadActorDetails() async {
    try {
      final details = await TmdbApiService().getActorDetails(widget.actorId);
      if (mounted && details != null) {
        setState(() {
          _actorDetails = details;
          _movieCredits = _parseMovieCredits(details);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading actor details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Movie> _parseMovieCredits(Map<String, dynamic> details) {
    final credits = details['movie_credits'] as Map<String, dynamic>?;
    if (credits == null) return [];
    final cast = credits['cast'] as List?;
    if (cast == null) return [];
    return cast.map((e) => Movie.fromTmdb(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildActorInfo(),
                  const SizedBox(height: 24),
                  _buildBiography(),
                  const SizedBox(height: 24),
                  _buildFilmography(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    final profilePath = _actorDetails?['profile_path'] as String?;
    final backdropUrl = profilePath != null
        ? 'https://image.tmdb.org/t/p/w1280$profilePath'
        : null;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 300,
      backgroundColor: ModernColors.backgroundDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (backdropUrl != null)
              CachedNetworkImage(
                imageUrl: backdropUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _buildFallback(),
                placeholder: (_, __) => _buildFallback(),
              )
            else
              _buildFallback(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, ModernColors.backgroundDark],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF232834), Color(0xFF11151D)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.person_outlined, color: Colors.white38, size: 80),
      ),
    );
  }

  Widget _buildActorInfo() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final profilePath = _actorDetails?['profile_path'] as String?;
    final name = _actorDetails?['name'] ?? widget.actorName;
    final birthday = _actorDetails?['birthday'];
    final placeOfBirth = _actorDetails?['place_of_birth'];
    final popularity = _actorDetails?['popularity'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 120,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF171C25),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          clipBehavior: Clip.antiAlias,
          child: profilePath != null
              ? CachedNetworkImage(
                  imageUrl: 'https://image.tmdb.org/t/p/w500$profilePath',
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.person_outlined),
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Center(
                  child: Icon(Icons.person_outlined, color: Colors.white38),
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (birthday != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.cake_outlined,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Дата рождения: $birthday',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
              if (placeOfBirth != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        placeOfBirth,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ],
              if (popularity != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.trending_up_outlined,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Популярность: ${popularity.toStringAsFixed(1)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBiography() {
    if (_isLoading) return const SizedBox.shrink();

    final biography = _actorDetails?['biography'] as String?;
    if (biography == null || biography.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Биография',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Биография недоступна.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Биография',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          biography,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.82),
            fontSize: 15,
            height: 1.7,
          ),
        ),
      ],
    );
  }

  Widget _buildFilmography() {
    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Фильмография',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => const SkeletonLoader(
                width: 150,
                height: 220,
                borderRadius: 18,
              ),
            ),
          ),
        ],
      );
    }

    if (_movieCredits == null || _movieCredits!.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Фильмография',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Нет данных о фильмах.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Фильмография (${_movieCredits!.length})',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _movieCredits!.length > 12 ? 12 : _movieCredits!.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final movie = _movieCredits![index];
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.push(
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
                                placeholder: (_, __) => _buildPosterFallback(),
                              )
                            : _buildPosterFallback(),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              movie.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (movie.voteAverage > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                '★ ${movie.voteAverage.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
}
