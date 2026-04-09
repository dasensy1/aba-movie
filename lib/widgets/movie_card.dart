import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie.dart';
import '../utils/modern_ui.dart';

/// ============================================================================
/// MOVIE CARD — Современный дизайн с glassmorphism
/// ============================================================================

class MovieCard extends StatefulWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final bool isFavorite;
  final bool showRating;

  const MovieCard({
    super.key,
    required this.movie,
    this.onTap,
    this.onFavoriteTap,
    this.isFavorite = false,
    this.showRating = true,
  });

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: ModernAnimations.fast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: SizedBox(
          width: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Постер
              _buildPoster(),
              const SizedBox(height: ModernSpacing.sm),
              // Информация
              _buildInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPoster() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(ModernRadius.md)),
          child: AspectRatio(
            aspectRatio: 2 / 3,
            child: widget.movie.posterUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: widget.movie.posterUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 300,
                    memCacheHeight: 450,
                    placeholder: (context, url) => _buildPlaceholder(),
                    errorWidget: (context, url, error) => _buildGradientPlaceholder(),
                  )
                : _buildGradientPlaceholder(),
          ),
        ),
        // Кнопка избранного
        if (widget.onFavoriteTap != null)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: widget.onFavoriteTap,
              child: AnimatedContainer(
                duration: ModernAnimations.fast,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: widget.isFavorite
                      ? ModernColors.accentPink.withValues(alpha: 0.9)
                      : Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  boxShadow: widget.isFavorite ? ModernShadows.purpleGlow : [],
                ),
                child: Icon(
                  widget.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        // Рейтинг
        if (widget.showRating && widget.movie.voteAverage > 0)
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(ModernRadius.sm),
                border: Border.all(
                  color: _getRatingColor(widget.movie.voteAverage).withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    color: _getRatingColor(widget.movie.voteAverage),
                    size: 14,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    widget.movie.voteAverage.toStringAsFixed(1),
                    style: TextStyle(
                      color: _getRatingColor(widget.movie.voteAverage),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return const SizedBox.square(
      dimension: 100,
      child: Center(
        child: Icon(
          Icons.movie_creation_outlined,
          color: Colors.white54,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildGradientPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(widget.movie.gradientColors[0]),
            Color(widget.movie.gradientColors[1]),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.movie_creation_rounded,
          color: Colors.white.withValues(alpha: 0.5),
          size: 40,
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.movie.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.3,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (widget.movie.releaseYear.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.movie.releaseYear,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white60,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 7) return ModernColors.success;
    if (rating >= 5) return ModernColors.warning;
    return ModernColors.error;
  }
}

/// ============================================================================
/// MOVIE CARD VERTICAL — Современный дизайн
/// ============================================================================

class MovieCardVertical extends StatefulWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final bool isFavorite;

  const MovieCardVertical({
    super.key,
    required this.movie,
    this.onTap,
    this.onFavoriteTap,
    this.isFavorite = false,
  });

  @override
  State<MovieCardVertical> createState() => _MovieCardVerticalState();
}

class _MovieCardVerticalState extends State<MovieCardVertical> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: ModernAnimations.fast,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: ModernColors.surfaceDark,
          borderRadius: BorderRadius.circular(ModernRadius.md),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(ModernRadius.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Постер
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 2 / 3,
                    child: widget.movie.posterUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.movie.posterUrl,
                            fit: BoxFit.cover,
                            memCacheWidth: 300,
                            memCacheHeight: 450,
                            placeholder: (context, url) => _buildPlaceholder(),
                            errorWidget: (context, url, error) => _buildGradientPlaceholder(),
                          )
                        : _buildGradientPlaceholder(),
                  ),
                  if (widget.onFavoriteTap != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: widget.onFavoriteTap,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: widget.isFavorite
                                ? ModernColors.accentPink.withValues(alpha: 0.9)
                                : Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Информация
              Padding(
                padding: const EdgeInsets.all(ModernSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (widget.movie.voteAverage > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: ModernColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, color: ModernColors.warning, size: 13),
                                const SizedBox(width: 3),
                                Text(
                                  widget.movie.voteAverage.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (widget.movie.releaseYear.isNotEmpty)
                          Text(
                            widget.movie.releaseYear,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white54,
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
    );
  }

  Widget _buildPlaceholder() {
    return const SizedBox.square(
      dimension: 100,
      child: Center(
        child: Icon(
          Icons.movie_creation_outlined,
          color: Colors.white54,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildGradientPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(widget.movie.gradientColors[0]),
            Color(widget.movie.gradientColors[1]),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.movie_creation_rounded,
          color: Colors.white.withValues(alpha: 0.5),
          size: 40,
        ),
      ),
    );
  }
}
