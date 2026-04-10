import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../utils/modern_ui.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';
import 'watchlist/watchlist_screen.dart';
import 'profile/profile_screen.dart';

/// ============================================================================
/// MAIN SCREEN — 3 вкладки
/// ============================================================================

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    WatchlistScreen(),
    ProfileScreen(),
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentIndex == 1 || _currentIndex == 2) {
      final auth = context.read<AuthProvider>();
      context.read<WatchlistProvider>().loadWatchlist(auth.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: ConvexAppBar(
        initialActiveIndex: _currentIndex,
        backgroundColor: ModernColors.backgroundDark,
        color: Colors.white.withValues(alpha: 0.35),
        activeColor: ModernColors.primaryPurple,
        style: TabStyle.reactCircle,
        height: 62,
        items: const [
          TabItem(icon: Icons.home_outlined, title: 'Главная'),
          TabItem(icon: Icons.track_changes, title: 'Трекинг'),
          TabItem(icon: Icons.person_outline, title: 'Профиль'),
        ],
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
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
