import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';
import 'search/search_screen.dart';
import 'categories/categories_screen.dart';
import 'watchlist/watchlist_screen.dart';
import 'favorites/favorites_screen.dart';
import 'profile/profile_screen.dart';
import 'settings/settings_screen.dart';
import 'about/about_screen.dart';

/// ============================================================================
/// MAIN SCREEN
/// ============================================================================
/// Главный экран с навигацией по 7 вкладкам
/// ============================================================================

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Список страниц
  final List<Widget> _pages = [
    const HomeScreen(),
    const SearchScreen(),
    const CategoriesScreen(),
    const WatchlistScreen(),
    const FavoritesScreen(),
    const ProfileScreen(),
    const SettingsScreen(),
    const AboutScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Загружаем данные при старте
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final moviesProvider = context.read<MoviesProvider>();
    final favoritesProvider = context.read<FavoritesProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final watchlistProvider = context.read<WatchlistProvider>();

    // Инициализация настроек
    await settingsProvider.initialize();

    // Загрузка трендов
    moviesProvider.loadTrendingMovies();
    moviesProvider.loadGenres();

    // Загрузка избранных
    favoritesProvider.loadFavorites();
    
    // Загрузка треккинга
    watchlistProvider.loadWatchlist();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Обновляем треккинг при переключении на вкладку трекинга (индекс 3) или профиля (индекс 5)
    if (_currentIndex == 3 || _currentIndex == 5) {
      context.read<WatchlistProvider>().loadWatchlist();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: ConvexAppBar(
        initialActiveIndex: _currentIndex,
        backgroundColor: const Color(0xFF1A1A1A),
        color: Colors.grey[500],
        activeColor: const Color(0xFF7C4DFF),
        style: TabStyle.reactCircle,
        height: 60,
        items: const [
          TabItem(icon: Icons.home_outlined, title: 'Главная'),
          TabItem(icon: Icons.search, title: 'Поиск'),
          TabItem(icon: Icons.category_outlined, title: 'Категории'),
          TabItem(icon: Icons.track_changes, title: 'Трекинг'),
          TabItem(icon: Icons.favorite_outlined, title: 'Избранное'),
          TabItem(icon: Icons.person_outline, title: 'Профиль'),
          TabItem(icon: Icons.settings_outlined, title: 'Настройки'),
          TabItem(icon: Icons.info_outline, title: 'О приложении'),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

/// ============================================================================
/// SPLASH SCREEN
/// ============================================================================
/// Экран загрузки приложения
/// ============================================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

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

    // Проверяем, авторизован ли пользователь
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
            colors: [
              Color(0xFF0D0D0D),
              Color(0xFF1A0B2E),
              Color(0xFF0D0D0D),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Анимированный логотип
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: const Icon(
                  Icons.movie_filter,
                  size: 100,
                  color: Color(0xFF7C4DFF),
                ),
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
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                  letterSpacing: 1,
                ),
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
