import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

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
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  void _checkIfFavorite() {
    final provider = context.read<FavoritesProvider>();
    setState(() {
      _isFavorite = provider.isFavoriteNow(widget.movie.id);
    });
  }

  Future<void> _toggleFavorite() async {
    final provider = context.read<FavoritesProvider>();
    final added = await provider.toggleFavorite(widget.movie);

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
    final movie = widget.movie;

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
                  // Градиентный фон
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
                  // Декоративные круги
                  Positioned(
                    right: -50,
                    top: 50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -30,
                    bottom: 50,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  // Контент
                  Positioned(
                    bottom: 60,
                    left: 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (movie.voteAverage > 0) ...[
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Контент
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
                      // Мини-постер
                      Container(
                        width: 100,
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(movie.gradientColors[0]),
                              Color(movie.gradientColors[1]),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.movie,
                            color: Colors.white.withOpacity(0.5),
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Кнопки
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (movie.releaseYear.isNotEmpty)
                                  Chip(
                                    label: Text(movie.releaseYear),
                                    backgroundColor: const Color(0xFF1A1A1A),
                                    labelStyle: const TextStyle(color: Colors.white70),
                                  ),
                                const SizedBox(width: 8),
                                Chip(
                                  label: Text('${movie.voteCount} голосов'),
                                  backgroundColor: const Color(0xFF1A1A1A),
                                  labelStyle: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Трейлер скоро будет доступен'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text('Трейлер'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _toggleFavorite,
                                    icon: Icon(
                                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                                    ),
                                    label: Text(_isFavorite ? 'В избранном' : 'В избранное'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _isFavorite
                                          ? Colors.red
                                          : const Color(0xFF7C4DFF),
                                      side: BorderSide(
                                        color: _isFavorite
                                            ? Colors.red
                                            : const Color(0xFF7C4DFF),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
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
                  const SizedBox(height: 24),
                  // Описание
                  const Text(
                    'О фильме',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    movie.overview ?? 'Описание отсутствует',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[400],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Биография фильма
                  _buildBioSection(movie),
                  const SizedBox(height: 24),
                  // Информация
                  const Text(
                    'Информация',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'ID фильма',
                    '${movie.id}',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Популярность',
                    movie.popularity != null
                        ? movie.popularity!.toStringAsFixed(0)
                        : 'N/A',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Дата релиза',
                    movie.releaseDate ?? 'Неизвестно',
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 120,
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
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  /// Секция биографии фильма
  Widget _buildBioSection(Movie movie) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Биография',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        // Слоган
        if (movie.tagline != null && movie.tagline!.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF7C4DFF).withOpacity(0.2),
                  const Color(0xFF00E5FF).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF7C4DFF).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.format_quote, color: Color(0xFF7C4DFF), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Слоган',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  movie.tagline!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Характеристики
        Row(
          children: [
            _buildBioChip(
              icon: Icons.access_time,
              label: movie.runtime != null ? '${movie.runtime} мин' : 'N/A',
            ),
            const SizedBox(width: 8),
            _buildBioChip(
              icon: Icons.calendar_today,
              label: movie.releaseYear.isNotEmpty ? movie.releaseYear : 'N/A',
            ),
            const SizedBox(width: 8),
            _buildBioChip(
              icon: Icons.language,
              label: _getLanguageName(movie.originalLanguage),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBioChip({required IconData icon, required String label}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF7C4DFF), size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getLanguageName(String? code) {
    if (code == null) return 'N/A';
    switch (code) {
      case 'en':
        return 'Английский';
      case 'ru':
        return 'Русский';
      case 'fr':
        return 'Французский';
      case 'de':
        return 'Немецкий';
      case 'es':
        return 'Испанский';
      case 'ja':
        return 'Японский';
      default:
        return code.toUpperCase();
    }
  }

  Color _getRatingColor(double rating) {
    if (rating >= 7) return Colors.green;
    if (rating >= 5) return Colors.orange;
    return Colors.red;
  }
}
