import 'package:flutter/material.dart';

import '../../utils/modern_ui.dart';

class AuthShell extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget form;
  final Widget footer;
  final Widget? leading;

  const AuthShell({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.form,
    required this.footer,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 960;

    return Scaffold(
      backgroundColor: ModernColors.backgroundDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF141821),
              ModernColors.backgroundDark,
              Color(0xFF0B0D12),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -120,
                left: -80,
                child: _glow(const Color(0xFF3B4252), 280),
              ),
              Positioned(
                bottom: -140,
                right: -60,
                child: _glow(const Color(0xFF2A2F3A), 320),
              ),
              if (leading != null)
                Positioned(
                  top: 12,
                  left: 12,
                  child: leading!,
                ),
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 32 : 16,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: isWide
                        ? Row(
                            children: [
                              Expanded(child: _buildIntroPanel(context)),
                              const SizedBox(width: 28),
                              SizedBox(width: 440, child: _buildCard(context)),
                            ],
                          )
                        : ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 460),
                            child: _buildCard(context),
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

  Widget _buildIntroPanel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Text(
              'Movie Tracker',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Минималистичный трекер для фильмов без лишнего шума.',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Следите за просмотренным, собирайте избранное и быстро переходите к деталям фильма на любом устройстве.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.6,
                ),
          ),
          const SizedBox(height: 28),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FeaturePill(text: 'Трекер просмотров'),
              _FeaturePill(text: 'Избранное'),
              _FeaturePill(text: 'Подборки и жанры'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF11151D).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.68),
                ),
          ),
          const SizedBox(height: 24),
          form,
          const SizedBox(height: 20),
          footer,
        ],
      ),
    );
  }

  Widget _glow(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.22),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final String text;

  const _FeaturePill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
