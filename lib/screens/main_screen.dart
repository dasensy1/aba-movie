import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../utils/modern_ui.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';
import 'search/search_screen.dart';
import 'categories/categories_screen.dart';
import 'watchlist/watchlist_screen.dart';
import 'favorites/favorites_screen.dart';
import 'profile/profile_screen.dart';

/// ============================================================================
/// MAIN SCREEN — 6 вкладок: Главная, Поиск, Жанры, Трекинг, Избранное, Профиль
/// ============================================================================

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
    HomeScreen(onNavigateToTab: (index) => setState(() => _currentIndex = index)),
    const SearchScreen(),
    const CategoriesScreen(),
    const WatchlistScreen(),
    const FavoritesScreen(),
    ProfileScreen(onNavigateToTab: (index) => setState(() => _currentIndex = index)),
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final auth = context.read<AuthProvider>();
    final moviesProvider = context.read<MoviesProvider>();
    final favoritesProvider = context.read<FavoritesProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final watchlistProvider = context.read<WatchlistProvider>();

    await settingsProvider.initialize(auth.userId);
    moviesProvider.loadTrendingMovies();
    moviesProvider.loadGenres();
    favoritesProvider.loadFavorites(auth.userId);
    watchlistProvider.loadWatchlist(auth.userId);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        
        return Scaffold(
          extendBodyBehindAppBar: isWide,
          appBar: isWide ? _buildWebHeader(context) : null,
          body: IndexedStack(index: _currentIndex, children: _pages),
          bottomNavigationBar: isWide
              ? null
              : ConvexAppBar(
                  initialActiveIndex: _currentIndex,
                  backgroundColor: ModernColors.backgroundDark,
                  color: Colors.white.withValues(alpha: 0.35),
                  activeColor: ModernColors.primaryPurple,
                  style: TabStyle.reactCircle,
                  height: 62,
                  items: const [
                    TabItem(icon: Icons.home_outlined, title: 'Главная'),
                    TabItem(icon: Icons.search_rounded, title: 'Поиск'),
                    TabItem(icon: Icons.category_rounded, title: 'Жанры'),
                    TabItem(icon: Icons.track_changes, title: 'Трекинг'),
                    TabItem(icon: Icons.favorite_outline_rounded, title: 'Избранное'),
                    TabItem(icon: Icons.person_outline, title: 'Профиль'),
                  ],
                  onTap: (index) {
                    setState(() => _currentIndex = index);
                  },
                ),
        );
      },
    );
  }

  PreferredSizeWidget _buildWebHeader(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: ModernColors.backgroundDark.withValues(alpha: 0.75),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  children: [
                    const Icon(
                      Icons.movie_creation_rounded, 
                      color: ModernColors.primaryPurple, 
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Movie Tracker',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(width: 40),
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _WebNavItem(
                            icon: Icons.home_rounded, 
                            title: 'Главная', 
                            isSelected: _currentIndex == 0, 
                            onTap: () => setState(() => _currentIndex = 0),
                          ),
                          _WebNavItem(
                            icon: Icons.category_rounded, 
                            title: 'Жанры', 
                            isSelected: _currentIndex == 2, 
                            onTap: () => setState(() => _currentIndex = 2),
                          ),
                          _WebNavItem(
                            icon: Icons.track_changes_rounded, 
                            title: 'Трекинг', 
                            isSelected: _currentIndex == 3, 
                            onTap: () => setState(() => _currentIndex = 3),
                          ),
                          _WebNavItem(
                            icon: Icons.favorite_rounded, 
                            title: 'Избранное', 
                            isSelected: _currentIndex == 4, 
                            onTap: () => setState(() => _currentIndex = 4),
                          ),
                        ],
                      ),
                    ),
                      _WebSearchField(
                        onSearch: (query) {
                          if (query.isNotEmpty) {
                            setState(() => _currentIndex = 1);
                            context.read<MoviesProvider>().searchMovies(query);
                          }
                        },
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.person_rounded, color: Colors.white70),
                        onPressed: () => setState(() => _currentIndex = 5),
                      ),
                    ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WebSearchField extends StatelessWidget {
  final Function(String) onSearch;
  
  const _WebSearchField({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Colors.white54, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Поиск фильмов...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: onSearch,
            ),
          ),
        ],
      ),
    );
  }
}

class _WebNavItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _WebNavItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_WebNavItem> createState() => _WebNavItemState();
}

class _WebNavItemState extends State<_WebNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: ModernAnimations.fast,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: widget.isSelected 
                ? ModernColors.primaryPurple.withValues(alpha: 0.15) 
                : _isHovered 
                    ? Colors.white.withValues(alpha: 0.05) 
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected 
                  ? ModernColors.primaryPurple.withValues(alpha: 0.3) 
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon, 
                color: widget.isSelected ? ModernColors.accentCyan : (_isHovered ? Colors.white : Colors.white70), 
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: TextStyle(
                  color: widget.isSelected ? Colors.white : (_isHovered ? Colors.white : Colors.white70),
                  fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ============================================================================
/// SPLASH SCREEN
/// ============================================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    if (authProvider.isSignedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D0D0D), Color(0xFF1A0B2E), Color(0xFF0D0D0D)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: const Icon(Icons.movie_filter, size: 100, color: Color(0xFF7C4DFF)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Movie Tracker',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7C4DFF),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ваш персональный киногид',
                style: TextStyle(fontSize: 16, color: Colors.grey[500], letterSpacing: 1),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C4DFF)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
