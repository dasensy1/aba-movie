// ============================================================================
// MOVIE TRACKER - MAIN ENTRY POINT
// ============================================================================

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'providers/providers.dart';
import 'screens/main_screen.dart';
import 'screens/auth/login_screen.dart';
import 'utils/config.dart';
import 'utils/modern_ui.dart' as ui;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация базы данных в зависимости от платформы
  if (kIsWeb) {
    databaseFactory = createDatabaseFactoryFfiWeb(
      options: SqfliteFfiWebOptions(
        indexedDbName: 'movie_tracker_storage',
      ),
    );
  } else {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MovieTrackerApp());
}

class MovieTrackerApp extends StatelessWidget {
  const MovieTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => MoviesProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => FavoritesProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => WatchlistProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ReviewsProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(),
        ),
      ],
      child: const _AppRoot(),
    );
  }
}

/// Единый корневой виджет с единственным Splash/роутингом.
class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  int? _lastUserId;
  bool _providersInitialized = false;

  @override
  void initState() {
    super.initState();
    // Инициализируем провайдеры после первого frame когда AuthProvider готов
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      _lastUserId = auth.userId;
      _initializeProviders(auth.userId);
    });
    // Также слушаем изменения auth
    context.read<AuthProvider>().addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    final auth = context.read<AuthProvider>();
    final userId = auth.userId;

    if (userId != _lastUserId) {
      _lastUserId = userId;
      _initializeProviders(userId);
    }
  }

  Future<void> _initializeProviders(int? userId) async {
    if (_providersInitialized && userId == _lastUserId) return;
    if (userId != null) {
      _providersInitialized = true;
    }

    final settings = context.read<SettingsProvider>();
    final favorites = context.read<FavoritesProvider>();
    final watchlist = context.read<WatchlistProvider>();

    await settings.initialize(userId);
    await favorites.loadFavorites(userId);
    await watchlist.loadWatchlist(userId);
  }

  @override
  void dispose() {
    context.read<AuthProvider>().removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, SettingsProvider>(
      builder: (context, auth, settings, _) {
        if (auth.isLoading) {
          return MaterialApp(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: settings.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
            home: const _ModernSplashScreen(),
          );
        }

        if (auth.isSignedIn) {
          return MaterialApp(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: settings.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
            home: const MainScreen(),
          );
        }

        return MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: settings.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
          home: const LoginScreen(),
        );
      },
    );
  }
}

/// ============================================================================
/// MODERN SPLASH SCREEN
/// ============================================================================

class _ModernSplashScreen extends StatefulWidget {
  const _ModernSplashScreen();

  @override
  State<_ModernSplashScreen> createState() => _ModernSplashScreenState();
}

class _ModernSplashScreenState extends State<_ModernSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: ui.ModernGradients.heroGradient,
        ),
        child: Stack(
          children: [
            Positioned(
              right: -80,
              top: -80,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_controller.value * 0.3),
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            ui.ModernColors.accentCyan.withValues(alpha: 0.3),
                            ui.ModernColors.accentCyan.withValues(alpha: 0.1),
                            ui.ModernColors.accentCyan.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: -100,
              bottom: -100,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_controller.value * 0.4),
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            ui.ModernColors.accentPink.withValues(alpha: 0.25),
                            ui.ModernColors.accentPink.withValues(alpha: 0.08),
                            ui.ModernColors.accentPink.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _controller,
                                builder: (context, child) {
                                  return Container(
                                    width: 140 * (0.5 + _controller.value * 0.5),
                                    height: 140 * (0.5 + _controller.value * 0.5),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          ui.ModernColors.primaryPurple.withValues(alpha: 0.4),
                                          ui.ModernColors.primaryPurple.withValues(alpha: 0),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Container(
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: ui.ModernGradients.primaryGradient,
                                  boxShadow: ui.ModernShadows.purpleGlow,
                                ),
                                child: const Icon(
                                  Icons.movie_creation_rounded,
                                  size: 56,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Movie Tracker',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          FadeTransition(
                            opacity: CurvedAnimation(
                              parent: _controller,
                              curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
                            ),
                            child: Text(
                              'Отслеживай. Смотри. Наслаждайся.',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 48),
                          FadeTransition(
                            opacity: CurvedAnimation(
                              parent: _controller,
                              curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
                            ),
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
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
        ),
      ),
    );
  }
}
