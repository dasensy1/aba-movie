import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/providers.dart';
import '../utils/modern_ui.dart';
import 'categories/categories_screen.dart';
import 'favorites/favorites_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'search/search_screen.dart';
import 'watchlist/watchlist_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
    HomeScreen(
      onNavigateToTab: (index) => setState(() => _currentIndex = index),
    ),
    const SearchScreen(),
    const CategoriesScreen(),
    const WatchlistScreen(),
    FavoritesScreen(
      onNavigateToTab: (index) => setState(() => _currentIndex = index),
    ),
    ProfileScreen(
      onNavigateToTab: (index) => setState(() => _currentIndex = index),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        return Scaffold(
          appBar: isWide ? _buildWebHeader(context) : null,
          body: IndexedStack(index: _currentIndex, children: _pages),
          bottomNavigationBar: isWide
              ? null
              : ConvexAppBar(
                  initialActiveIndex: _currentIndex,
                  backgroundColor: ModernColors.backgroundDark,
                  color: Colors.white.withValues(alpha: 0.4),
                  activeColor: ModernColors.primaryPurpleLight,
                  style: TabStyle.reactCircle,
                  height: 62,
                  items: const [
                    TabItem(icon: Icons.home_outlined, title: 'Главная'),
                    TabItem(icon: Icons.search_rounded, title: 'Поиск'),
                    TabItem(icon: Icons.category_rounded, title: 'Жанры'),
                    TabItem(icon: Icons.track_changes, title: 'Трекинг'),
                    TabItem(
                      icon: Icons.favorite_outline_rounded,
                      title: 'Избранное',
                    ),
                    TabItem(icon: Icons.person_outline, title: 'Профиль'),
                  ],
                  onTap: (index) => setState(() => _currentIndex = index),
                ),
        );
      },
    );
  }

  PreferredSizeWidget _buildWebHeader(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF10131A).withValues(alpha: 0.96),
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(
                  Icons.movie_creation_rounded,
                  color: ModernColors.primaryPurpleLight,
                  size: 30,
                ),
                const SizedBox(width: 10),
                Text(
                  'Aba Movie',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 28),
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
                const Spacer(),
                _WebSearchField(
                  onSearch: (query) {
                    if (query.trim().isEmpty) return;
                    setState(() => _currentIndex = 1);
                    context.read<MoviesProvider>().searchMovies(query.trim());
                  },
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => setState(() => _currentIndex = 5),
                  icon: const Icon(Icons.person_rounded, color: Colors.white70),
                ),
              ],
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
      width: 280,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.36),
                  fontSize: 14,
                ),
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
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? ModernColors.primaryPurple.withValues(alpha: 0.14)
                : _isHovered
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isSelected
                  ? ModernColors.primaryPurple.withValues(alpha: 0.24)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: widget.isSelected
                    ? ModernColors.primaryPurpleLight
                    : Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: TextStyle(
                  color: widget.isSelected ? Colors.white : Colors.white70,
                  fontWeight: widget.isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
