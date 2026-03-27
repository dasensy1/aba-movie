// ============================================================================
// MOVIE TRACKER - MAIN ENTRY POINT
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/providers.dart';
import 'screens/main_screen.dart';
import 'screens/auth/login_screen.dart';
import 'utils/config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MovieTrackerApp());
}

class MovieTrackerApp extends StatelessWidget {
  const MovieTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth Provider
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..initialize(),
        ),
        // Movies Provider
        ChangeNotifierProvider(
          create: (_) => MoviesProvider(),
        ),
        // Favorites Provider (Теперь инициализируем загрузку из БД)
        ChangeNotifierProvider(
          create: (_) => FavoritesProvider()..loadFavorites(),
        ),
        // Watchlist Provider (треккинг фильмов)
        ChangeNotifierProvider(
          create: (_) => WatchlistProvider()..loadWatchlist(),
        ),
        // Settings Provider
        ChangeNotifierProvider(
          create: (_) => SettingsProvider()..initialize(),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: settings.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
            home: const AppStartup(),
          );
        },
      ),
    );
  }
}

class AppStartup extends StatelessWidget {
  const AppStartup({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const SplashScreen();
        }
        if (auth.isSignedIn) {
          return const MainScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _navigateToNextScreen();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
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
            colors: [
              Color(0xFF0D0D0D),
              Color(0xFF1A0B2E),
              Color(0xFF2D1B4E),
              Color(0xFF0D0D0D),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.movie_filter,
                size: 100,
                color: Color(0xFF7C4DFF),
              ),
              const SizedBox(height: 32),
              const Text(
                'Movie Tracker',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7C4DFF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
