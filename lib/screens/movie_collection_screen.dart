import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/modern_ui.dart';
import '../widgets/widgets.dart';
import 'movie_detail_screen.dart';

class MovieCollectionScreen extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<Movie>? initialMovies;
  final int? genreId;
  final String? emptyMessage;

  const MovieCollectionScreen({
    super.key,
    required this.title,
    this.subtitle,
    this.initialMovies,
    this.genreId,
    this.emptyMessage,
  });

  @override
  State<MovieCollectionScreen> createState() => _MovieCollectionScreenState();
}

class _MovieCollectionScreenState extends State<MovieCollectionScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.genreId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<MoviesProvider>().loadMoviesByGenre(widget.genreId!);
      });
    }
  }

  @override
  void dispose() {
    if (widget.genreId != null) {
      context.read<MoviesProvider>().clearMoviesByGenre();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: ModernColors.backgroundDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF141821),
              ModernColors.backgroundDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<MoviesProvider>(
            builder: (context, provider, _) {
              final movies = widget.genreId != null
                  ? provider.moviesByGenre
                  : (widget.initialMovies ?? const <Movie>[]);
              final isLoading = widget.genreId != null &&
                  provider.isLoadingGenre &&
                  movies.isEmpty;
              final error = widget.genreId != null ? provider.error : null;

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    title: Text(
                      widget.title,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if ((widget.subtitle ?? '').trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                widget.subtitle!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.68),
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Text(
                              '${movies.length} фильмов',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (isLoading)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                            color: ModernColors.primaryPurple),
                      ),
                    )
                  else if (error != null && movies.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            error,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    )
                  else if (movies.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            widget.emptyMessage ?? 'Здесь пока ничего нет',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      sliver: SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.crossAxisExtent;
                          final crossAxisCount = width >= 1200
                              ? 6
                              : width >= 900
                                  ? 5
                                  : width >= 640
                                      ? 4
                                      : 2;

                          return SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: 0.62,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final movie = movies[index];
                                return Consumer<FavoritesProvider>(
                                  builder: (context, favorites, _) {
                                    final auth = context.read<AuthProvider>();
                                    final isFav = favorites.favorites
                                        .any((m) => m.id == movie.id);
                                    return MovieCardVertical(
                                      movie: movie,
                                      isFavorite: isFav,
                                      onFavoriteTap: () => favorites
                                          .toggleFavorite(movie, auth.userId),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                MovieDetailScreen(movie: movie),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                              childCount: movies.length,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
