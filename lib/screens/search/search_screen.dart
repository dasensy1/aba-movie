import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/modern_ui.dart';
import '../../widgets/widgets.dart';
import '../movie_detail_screen.dart';

/// ============================================================================
/// SEARCH SCREEN - РАСШИРЕННЫЙ ПОИСК С ФИЛЬТРАМИ
/// ============================================================================
/// Современный UI с расширенными фильтрами:
/// - Поиск по названию
/// - Фильтр по жанрам (чипы)
/// - Фильтр по рейтингу (слайдер)
/// - Фильтр по году выпуска
/// - Сортировка результатов
/// - История поиска
/// ============================================================================

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;
  
  // Состояние UI
  bool _showFilters = false;
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;
  
  // Жанры для фильтрации (будут загружены из TMDb)
  List<String> _genres = ['Все'];
  
  // История поиска
  final List<String> _recentSearches = [
    'Начало', 'Матрица', 'Бойцовский клуб', 'Интерстеллар'
  ];

  @override
  void initState() {
    super.initState();
    // Инициализируем контроллер с текстом из стейта, если мы пришли сюда из глобального поиска
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final query = context.read<MoviesProvider>().searchQuery;
        if (query.isNotEmpty && _searchController.text.isEmpty) {
          _searchController.text = query;
        }
      }
    });

    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Загружаем жанры только один раз при первой загрузке
    if (_genres.length <= 1) {
      _loadGenres();
    }
  }

  /// Загрузить жанры из TMDb
  Future<void> _loadGenres() async {
    try {
      final moviesProvider = context.read<MoviesProvider>();
      await moviesProvider.loadGenres();
      
      if (mounted) {
        debugPrint('=== ЗАГРУЖЕНЫ ЖАНРЫ ИЗ TMDB ===');
        debugPrint('Всего жанров: ${moviesProvider.genres.length}');
        moviesProvider.genres.forEach((g) {
          debugPrint('  ID=${g.id}, Name=${g.name}');
        });
        
        setState(() {
          _genres = [
            'Все',
            ...moviesProvider.genres.map((g) => g.name).take(15),
          ];
          debugPrint('Загружено ${_genres.length} жанров для UI: $_genres');
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки жанров: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    _filterAnimationController.dispose();
    super.dispose();
  }

  /// Поиск с задержкой (debounce)
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (query.trim().isNotEmpty) {
        context.read<MoviesProvider>().searchMovies(query);
      } else {
        context.read<MoviesProvider>().clearSearch();
      }
    });
  }

  /// Очистить поиск
  void _clearSearch() {
    _searchController.clear();
    context.read<MoviesProvider>().clearSearch();
    _focusNode.unfocus();
  }

  /// Показать/скрыть фильтры
  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
      if (_showFilters) {
        _filterAnimationController.forward();
      } else {
        _filterAnimationController.reverse();
      }
    });
  }

  /// Применить фильтры
  void _applyFilters({
    String? genre,
    double? minRating,
    int? minYear,
    int? maxYear,
    String? sortBy,
    bool? sortAscending,
  }) {
    final currentFilters = context.read<MoviesProvider>().filters;
    
    // Если выбран "Все", то сбрасываем жанр
    final selectedGenre = (genre == null || genre == 'Все') ? '' : genre;
    
    debugPrint('========================================');
    debugPrint('=== ПРИМЕНЕНИЕ ФИЛЬТРОВ ИЗ UI ===');
    debugPrint('Выбранный жанр (из UI): "$genre"');
    debugPrint('После обработки: "$selectedGenre"');
    debugPrint('Рейтинг: $minRating');
    debugPrint('Год: $minYear - $maxYear');
    debugPrint('Сортировка: $sortBy (${sortAscending == true ? "возр" : "убыв"})');
    debugPrint('Текущий searchQuery: "${currentFilters.searchQuery}"');
    debugPrint('========================================');
    
    final newFilters = currentFilters.copyWith(
      selectedGenre: selectedGenre,
      minRating: minRating ?? 0,
      minYear: minYear,
      maxYear: maxYear,
      sortBy: sortBy ?? currentFilters.sortBy,
      sortAscending: sortAscending ?? currentFilters.sortAscending,
    );

    debugPrint('Применяем фильтры к MoviesProvider...');
    context.read<MoviesProvider>().applyFilters(newFilters);
    debugPrint('Фильтры применены');
    debugPrint('========================================');
  }

  /// Сбросить все фильтры
  void _resetFilters() {
    context.read<MoviesProvider>().resetFilters();
    setState(() {
      _searchController.clear();
    });
  }

  /// Открыть панель фильтров как bottom sheet
  void _openFilterSheet() {
    debugPrint('=== ОТКРЫТИЕ ПАНЕЛИ ФИЛЬТРОВ ===');
    debugPrint('Доступно жанров: ${_genres.length}');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        debugPrint('Создаем _FilterSheet');
        return _FilterSheet(
          genres: _genres,
          onApply: (
            {String? genre,
            double? minRating,
            int? minYear,
            int? maxYear,
            String? sortBy,
            bool? sortAscending}
          ) {
            _applyFilters(
              genre: genre,
              minRating: minRating,
              minYear: minYear,
              maxYear: maxYear,
              sortBy: sortBy,
              sortAscending: sortAscending,
            );
          },
          onReset: _resetFilters,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск фильмов'),
        elevation: 0,
        actions: [
          // Кнопка фильтров с бейджем
          Consumer<MoviesProvider>(
            builder: (context, movies, _) {
              final filterCount = movies.filters.activeFiltersCount;
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      _showFilters 
                          ? Icons.filter_alt_rounded 
                          : Icons.filter_list_rounded,
                    ),
                    onPressed: _openFilterSheet,
                  ),
                  if (filterCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: ModernColors.accentPink,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$filterCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Поле поиска
          _buildSearchBar(),
          
          // Основной контент
          Expanded(
            child: Consumer<MoviesProvider>(
              builder: (context, moviesProvider, _) {
                // Загрузка
                if (moviesProvider.isLoadingSearch) {
                  return const LoadingIndicator(message: 'Поиск фильмов...');
                }

                // Ошибка
                if (moviesProvider.error != null) {
                  return CustomErrorWidget(
                    message: moviesProvider.error!,
                    onRetry: () => moviesProvider.searchMovies(
                      moviesProvider.searchQuery,
                    ),
                  );
                }

                // Пустой результат
                if (moviesProvider.searchResults.isEmpty) {
                  if (moviesProvider.searchQuery.isEmpty) {
                    return _buildEmptyState();
                  }
                  return const EmptyStateWidget(
                    title: 'Ничего не найдено',
                    subtitle: 'Попробуйте изменить параметры поиска',
                    icon: Icons.search_off_rounded,
                  );
                }

                // Результаты поиска
                return _buildSearchResults(moviesProvider.searchResults);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Поле поиска
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Название, актер, режиссер...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: ModernColors.primaryPurpleLight,
            size: 24,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: _clearSearch,
                ),
            ],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        onSubmitted: (query) {
          if (query.trim().isNotEmpty) {
            context.read<MoviesProvider>().searchMovies(query);
          }
        },
      ),
    );
  }

  /// Пустое состояние с историей поиска
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Иконка
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: ModernColors.primaryPurple.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.movie_creation_rounded,
              size: 80,
              color: ModernColors.primaryPurpleLight.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          
          const Text(
            'Найдите свой идеальный фильм',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Введите название, имя актера или режиссера',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          
          // История поиска
          if (_recentSearches.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(Icons.history_rounded, size: 20, color: Colors.white.withValues(alpha: 0.6)),
                  const SizedBox(width: 8),
                  Text(
                    'Недавние запросы',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((query) {
                return _buildSearchChip(query);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// Чип для поиска
  Widget _buildSearchChip(String label) {
    return ActionChip(
      label: Text(label),
      backgroundColor: const Color(0xFF1A1A1A),
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
      avatar: Icon(Icons.search, size: 16, color: Colors.white.withValues(alpha: 0.5)),
      onPressed: () {
        _searchController.text = label;
        context.read<MoviesProvider>().searchMovies(label);
      },
    );
  }

  /// Результаты поиска
  Widget _buildSearchResults(List<Movie> movies) {
    return Column(
      children: [
        // Информация о результатах
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Найдено: ${movies.length}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
              Consumer<MoviesProvider>(
                builder: (context, provider, _) {
                  if (provider.filters.hasActiveFilters) {
                    return Row(
                      children: [
                        Icon(Icons.filter_alt_rounded, size: 16, color: ModernColors.primaryPurpleLight),
                        const SizedBox(width: 4),
                        Text(
                          'Фильтры активны',
                          style: TextStyle(
                            color: ModernColors.primaryPurpleLight,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
        
        // Сетка фильмов
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              // Адаптивное количество колонок: 2-3 на телефонах, 4-6 на десктопах
              final crossAxisCount = width >= 1200 ? 6 : width >= 900 ? 5 : width >= 600 ? 4 : 3;
              
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.65, // Более компактно
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: movies.length,
                itemBuilder: (context, index) {
                  final movie = movies[index];
                  return Consumer<FavoritesProvider>(
                    builder: (context, favorites, _) {
                      final isFav = favorites.favorites.any((m) => m.id == movie.id);
                      return MovieCardVertical(
                        movie: movie,
                        isFavorite: isFav,
                        onFavoriteTap: () {
                          final auth = context.read<AuthProvider>();
                          favorites.toggleFavorite(movie, auth.userId);
                        },
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MovieDetailScreen(movie: movie),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// ============================================================================
/// FILTER SHEET - МОДАЛЬНОЕ ОКНО ФИЛЬТРОВ
/// ============================================================================

class _FilterSheet extends StatefulWidget {
  final List<String> genres;
  final Function({
    String? genre,
    double? minRating,
    int? minYear,
    int? maxYear,
    String? sortBy,
    bool? sortAscending,
  }) onApply;
  final VoidCallback onReset;

  const _FilterSheet({
    required this.genres,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String _selectedGenre = '';
  double _minRating = 0;
  int? _minYear;
  int? _maxYear;
  String _sortBy = 'rating';
  bool _sortAscending = false;

  final List<String> _sortOptions = [
    'rating', 'year', 'title'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Заголовок
          _buildHeader(),
          
          // Контент фильтров
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Жанр
                  _buildGenreSection(),
                  const SizedBox(height: 24),
                  
                  // Рейтинг
                  _buildRatingSection(),
                  const SizedBox(height: 24),
                  
                  // Год выпуска
                  _buildYearSection(),
                  const SizedBox(height: 24),
                  
                  // Сортировка
                  _buildSortSection(),
                ],
              ),
            ),
          ),
          
          // Кнопки действий
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// Заголовок
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Фильтры поиска',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// Секция жанров
  Widget _buildGenreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category_rounded, size: 20, color: ModernColors.primaryPurpleLight),
            const SizedBox(width: 8),
            const Text(
              'Жанр',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.genres.map((genre) {
            final isSelected = genre == 'Все' 
                ? _selectedGenre.isEmpty 
                : _selectedGenre == genre;
            return ChoiceChip(
              label: Text(genre),
              selected: isSelected,
              selectedColor: ModernColors.primaryPurple,
              backgroundColor: const Color(0xFF2A2A2A),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedGenre = genre == 'Все' ? '' : genre;
                  debugPrint('=== ВЫБРАН ЖАНР В UI ===');
                  debugPrint('Выбран: "$genre" -> _selectedGenre="$_selectedGenre"');
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Секция рейтинга
  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star_rounded, size: 20, color: Colors.amber),
            const SizedBox(width: 8),
            const Text(
              'Минимальный рейтинг',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Text(
              _minRating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.star_border_rounded, size: 16, color: Colors.white.withValues(alpha: 0.3)),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: Colors.amber,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                  thumbColor: Colors.amber,
                  overlayColor: Colors.amber.withValues(alpha: 0.2),
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                ),
                child: Slider(
                  value: _minRating,
                  min: 0,
                  max: 10,
                  divisions: 20,
                  label: _minRating.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      _minRating = value;
                    });
                  },
                ),
              ),
            ),
            Icon(Icons.star_rounded, size: 16, color: Colors.amber),
          ],
        ),
      ],
    );
  }

  /// Секция года
  Widget _buildYearSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 20, color: ModernColors.accentCyan),
            const SizedBox(width: 8),
            const Text(
              'Год выпуска',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildYearField(
                label: 'От',
                value: _minYear,
                onChanged: (value) {
                  setState(() {
                    _minYear = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildYearField(
                label: 'До',
                value: _maxYear,
                onChanged: (value) {
                  setState(() {
                    _maxYear = value;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Поле ввода года
  Widget _buildYearField({
    required String label,
    int? value,
    required Function(int?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Год',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (val) {
            final year = int.tryParse(val);
            onChanged(year);
          },
          controller: value != null 
              ? TextEditingController(text: value.toString()) 
              : null,
        ),
      ],
    );
  }

  /// Секция сортировки
  Widget _buildSortSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.sort_rounded, size: 20, color: ModernColors.accentPink),
            const SizedBox(width: 8),
            const Text(
              'Сортировка',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Выбор типа сортировки
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildSortChip('По рейтингу', 'rating'),
            _buildSortChip('По году', 'year'),
            _buildSortChip('По названию', 'title'),
          ],
        ),
        const SizedBox(height: 12),
        
        // Направление сортировки
        Row(
          children: [
            Icon(
              _sortAscending 
                  ? Icons.arrow_upward_rounded 
                  : Icons.arrow_downward_rounded,
              size: 20,
              color: ModernColors.accentPink,
            ),
            const SizedBox(width: 8),
            Text(
              _sortAscending ? 'По возрастанию' : 'По убыванию',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Switch(
              value: _sortAscending,
              onChanged: (value) {
                setState(() {
                  _sortAscending = value;
                });
              },
              activeColor: ModernColors.accentPink,
            ),
          ],
        ),
      ],
    );
  }

  /// Чип сортировки
  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: ModernColors.accentPink,
      backgroundColor: const Color(0xFF2A2A2A),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _sortBy = value;
          });
        }
      },
    );
  }

  /// Кнопки действий
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedGenre = '';
                  _minRating = 0;
                  _minYear = null;
                  _maxYear = null;
                  _sortBy = 'rating';
                  _sortAscending = false;
                });
                widget.onReset();
              },
              icon: const Icon(Icons.restore_rounded),
              label: const Text('Сбросить'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {
                debugPrint('=== НАЖАТА КНОПКА "ПРИМЕНИТЬ" ===');
                debugPrint('_selectedGenre: "$_selectedGenre"');
                debugPrint('_minRating: $_minRating');
                debugPrint('_minYear: $_minYear');
                debugPrint('_maxYear: $_maxYear');
                debugPrint('_sortBy: $_sortBy');
                debugPrint('_sortAscending: $_sortAscending');
                
                widget.onApply(
                  genre: _selectedGenre,
                  minRating: _minRating,
                  minYear: _minYear,
                  maxYear: _maxYear,
                  sortBy: _sortBy,
                  sortAscending: _sortAscending,
                );
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Применить'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ModernColors.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
