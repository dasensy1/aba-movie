import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';

/// ============================================================================
/// MOVIE DETAIL SCREEN
/// ============================================================================
/// Экран деталей фильма
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
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _currentMovie = widget.movie;
    _checkIfFavorite();
    _loadFullDetails();
  }

  void _checkIfFavorite() {
    final provider = context.read<FavoritesProvider>();
    setState(() {
      _isFavorite = provider.isFavoriteNow(_currentMovie.id);
    });
  }

  /// Загрузка полного описания (Plot) из API
  Future<void> _loadFullDetails() async {
    // Если описание уже есть, не загружаем повторно
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
          content: Text(
            added ? 'Добавлено в избранное' : 'Удалено из избранного',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = _currentMovie;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar с градиентным фоном
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF0D0D0D),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.white,
                  ),
                ),
                onPressed: _toggleFavorite,
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Градиентный фон на основе ID
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(movie.gradientColors[0]),
                          Color(movie.gradientColors[1]),
                          const Color(0xFF0D0D0D),
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                  // Контент заголовка
                  Positioned(
                    bottom: 60,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (movie.voteAverage > 0)
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 20),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Постер и кнопки
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Мини-постер (или иконка если нет URL)
                      Container(
                        width: 100,
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFF1A1A1A),
                          image: movie.posterUrl.isNotEmpty 
                            ? DecorationImage(
                                image: NetworkImage(movie.posterUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                        ),
                        child: movie.posterUrl.isEmpty 
                          ? const Center(child: Icon(Icons.movie, size: 40)) 
                          : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                if (movie.releaseYear.isNotEmpty)
                                  Chip(label: Text(movie.releaseYear)),
                                const SizedBox(width: 8),
                                if (movie.runtime != null)
                                  Chip(label: Text('${movie.runtime} мин')),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _toggleFavorite,
                              icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
                              label: Text(_isFavorite ? 'В избранном' : 'В избранное'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 45),
                                backgroundColor: _isFavorite ? Colors.red.withOpacity(0.8) : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('О фильме', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_isLoadingDetails)
                    const Center(child: CircularProgressIndicator())
                  else
                    Text(
                      movie.overview ?? 'Описание отсутствует для данного фильма.',
                      style: TextStyle(fontSize: 15, color: Colors.grey[400], height: 1.5),
                    ),
                  const SizedBox(height: 24),
                  _buildInfoRow('ID', movie.imdbId ?? movie.id.toString()),
                  _buildInfoRow('Рейтинг', '${movie.voteAverage} (${movie.voteCount} голосов)'),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Text(value),
        ],
      ),
    );
  }
}
