import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/providers.dart';
import '../utils/modern_ui.dart';
import 'about/about_screen.dart';
import 'categories/categories_screen.dart';
import 'favorites/favorites_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'search/search_screen.dart';
import 'settings/settings_screen.dart';
import 'watchlist/watchlist_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<_NavDestination> _destinations = [
    const _NavDestination(
      label: 'Home',
      icon: Icons.home_rounded,
      page: HomeScreen(),
    ),
    const _NavDestination(
      label: 'Search',
      icon: Icons.search_rounded,
      page: SearchScreen(),
    ),
    const _NavDestination(
      label: 'Genres',
      icon: Icons.grid_view_rounded,
      page: CategoriesScreen(),
    ),
    const _NavDestination(
      label: 'Watchlist',
      icon: Icons.bookmark_added_rounded,
      page: WatchlistScreen(),
    ),
    const _NavDestination(
      label: 'Favorites',
      icon: Icons.favorite_rounded,
      page: FavoritesScreen(),
    ),
    const _NavDestination(
      label: 'Profile',
      icon: Icons.person_rounded,
      page: ProfileScreen(),
    ),
    const _NavDestination(
      label: 'Settings',
      icon: Icons.tune_rounded,
      page: SettingsScreen(),
    ),
    const _NavDestination(
      label: 'About',
      icon: Icons.info_rounded,
      page: AboutScreen(),
    ),
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

  void _onDestinationSelected(int index) {
    setState(() {
      _currentIndex = index;
    });

    final auth = context.read<AuthProvider>();
    if (index == 3) {
      context.read<WatchlistProvider>().loadWatchlist(auth.userId);
    }
    if (index == 4) {
      context.read<FavoritesProvider>().loadFavorites(auth.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 1100;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: ModernGradients.darkBackgroundGradient,
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (isWide) _buildSidebar(),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: _destinations.map((item) => item.page).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: isWide ? null : _buildBottomBar(),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      margin: const EdgeInsets.all(18),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: ModernGradients.primaryGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: ModernShadows.purpleGlow,
            ),
            child: const Icon(
              Icons.movie_filter_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Movie Tracker',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Browse movies, save picks, and keep your watchlist organized.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: _destinations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _destinations[index];
                final isSelected = index == _currentIndex;

                return AnimatedContainer(
                  duration: ModernAnimations.normal,
                  decoration: BoxDecoration(
                    gradient:
                        isSelected ? ModernGradients.primaryGradient : null,
                    color: isSelected
                        ? null
                        : Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.16)
                          : Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: ListTile(
                    onTap: () => _onDestinationSelected(index),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    leading: Icon(
                      item.icon,
                      color: Colors.white,
                    ),
                    title: Text(
                      item.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ModernColors.surfaceDarkHigher.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: ModernShadows.medium,
      ),
      child: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: Colors.transparent,
        indicatorColor: ModernColors.primaryPurple.withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        onDestinationSelected: _onDestinationSelected,
        destinations: _destinations
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon, color: Colors.white54),
                selectedIcon: Icon(item.icon, color: Colors.white),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NavDestination {
  final String label;
  final IconData icon;
  final Widget page;

  const _NavDestination({
    required this.label,
    required this.icon,
    required this.page,
  });
}
