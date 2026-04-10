// ============================================================================
// ABOUT SCREEN — MODERN UI with glassmorphism and animations
// ============================================================================

import 'package:flutter/material.dart';
import '../../utils/modern_ui.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: const Interval(0.2, 1.0, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
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
        decoration: const BoxDecoration(gradient: ModernGradients.darkBackgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(ModernSpacing.lg),
                      child: Column(
                        children: [
                          // Logo
                          _buildLogo(),
                          const SizedBox(height: ModernSpacing.xxl),
                          // Info cards
                          _buildInfoCard(
                            icon: Icons.description_rounded,
                            title: 'О приложении',
                            content: 'Movie Tracker — приложение для отслеживания фильмов. Работает локально, все данные на вашем устройстве.',
                            gradient: ModernGradients.primaryGradient,
                          ),
                          const SizedBox(height: ModernSpacing.lg),
                          _buildInfoCard(
                            icon: Icons.flash_on_rounded,
                            title: 'Возможности',
                            content: 'Поиск фильмов, тренды и популярное, категории по жанрам, избранное, трекинг просмотров, обзоры, тёмная тема.',
                            gradient: ModernGradients.oceanGradient,
                          ),
                          const SizedBox(height: ModernSpacing.lg),
                          _buildInfoCard(
                            icon: Icons.code_rounded,
                            title: 'Технологии',
                            content: 'Flutter & Dart, Provider, SQLite, SharedPreferences, CachedNetworkImage.',
                            gradient: ModernGradients.sunsetGradient,
                          ),
                          const SizedBox(height: ModernSpacing.lg),
                          _buildInfoCard(
                            icon: Icons.security_rounded,
                            title: 'Конфиденциальность',
                            content: 'Все данные хранятся локально. Приложение не собирает и не передаёт персональные данные.',
                            gradient: const LinearGradient(colors: [ModernColors.success, Color(0xFF059669)]),
                          ),
                          const SizedBox(height: ModernSpacing.xxl),
                          // Actions
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildActionButton(
                                icon: Icons.star_rounded,
                                label: 'Оценить',
                                gradient: ModernGradients.sunsetGradient,
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Спасибо за оценку!'), behavior: SnackBarBehavior.floating),
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              _buildActionButton(
                                icon: Icons.share_rounded,
                                label: 'Поделиться',
                                gradient: ModernGradients.oceanGradient,
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Ссылка скопирована'), behavior: SnackBarBehavior.floating),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          Text(
                            '2024 Movie Tracker',
                            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: ModernGradients.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_rounded, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Text('О приложении', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                ModernColors.primaryPurple.withValues(alpha: 0.3),
                ModernColors.primaryPurple.withValues(alpha: 0),
              ],
            ),
          ),
        ),
        // Icon
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: ModernGradients.primaryGradient,
            boxShadow: ModernShadows.purpleGlow,
          ),
          child: const Icon(Icons.movie_creation_rounded, size: 56, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: Glassmorphism.glassCard(opacity: 0.05, borderRadius: ModernRadius.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 24, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 8),
                Text(content, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14, height: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(ModernRadius.md),
          boxShadow: ModernShadows.medium,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
