// ============================================================================
// MODERN UI UTILITIES — Градиенты, тени, glassmorphism, декорации
// ============================================================================

import 'package:flutter/material.dart';

/// Современная палитра цветов
class ModernColors {
  static const primaryPurple = Color(0xFF8B5CF6);
  static const primaryPurpleDark = Color(0xFF7C3AED);
  static const primaryPurpleLight = Color(0xFFA78BFA);
  static const accentCyan = Color(0xFF06B6D4);
  static const accentPink = Color(0xFFEC4899);
  static const surfaceDark = Color(0xFF1E1B2E);
  static const surfaceDarkHigher = Color(0xFF262340);
  static const backgroundDark = Color(0xFF0F0D1A);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
}

/// Градиенты для различных элементов
class ModernGradients {
  // Основные градиенты
  static const primaryGradient = LinearGradient(
    colors: [ModernColors.primaryPurple, ModernColors.accentCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroGradient = LinearGradient(
    colors: [
      ModernColors.primaryPurpleDark,
      ModernColors.primaryPurple,
      ModernColors.accentCyan,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  static const sunsetGradient = LinearGradient(
    colors: [ModernColors.accentPink, ModernColors.primaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const oceanGradient = LinearGradient(
    colors: [ModernColors.accentCyan, ModernColors.info],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkBackgroundGradient = RadialGradient(
    center: Alignment.topCenter,
    radius: 1.5,
    colors: [
      ModernColors.surfaceDarkHigher,
      ModernColors.backgroundDark,
    ],
  );

  // Градиент для кнопки
  static const buttonGradient = LinearGradient(
    colors: [ModernColors.primaryPurple, ModernColors.primaryPurpleDark],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Градиент для карточки при наведении
  static const cardHoverGradient = LinearGradient(
    colors: [
      ModernColors.surfaceDarkHigher,
      ModernColors.surfaceDark,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Тени для современного дизайна
class ModernShadows {
  // Мягкая тень для карточек
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  // Средняя тень
  static List<BoxShadow> get medium => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  // Цветная тень (purple glow)
  static List<BoxShadow> get purpleGlow => [
        BoxShadow(
          color: ModernColors.primaryPurple.withValues(alpha: 0.3),
          blurRadius: 24,
          spreadRadius: 2,
          offset: const Offset(0, 8),
        ),
      ];

  // Цветная тень (cyan glow)
  static List<BoxShadow> get cyanGlow => [
        BoxShadow(
          color: ModernColors.accentCyan.withValues(alpha: 0.3),
          blurRadius: 20,
          spreadRadius: 1,
          offset: const Offset(0, 4),
        ),
      ];

  // Тень для FAB
  static List<BoxShadow> get fab => [
        BoxShadow(
          color: ModernColors.primaryPurple.withValues(alpha: 0.4),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
}

/// Glassmorphism эффекты
class Glassmorphism {
  // Базовый glassmorphism контейнер
  static BoxDecoration glassCard({
    double blur = 20,
    double opacity = 0.08,
    Color color = Colors.white,
    double borderRadius = 20,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: color.withValues(alpha: 0.1),
        width: 1,
      ),
    );
  }

  // Glassmorphism для AppBar
  static BoxDecoration get glassAppBar => BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      );

  // Glassmorphism для bottom sheet
  static BoxDecoration get glassBottomSheet => BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      );

  // Glassmorphism для модальных окон
  static BoxDecoration get glassModal => BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      );
}

/// Скругления для разных элементов
class ModernRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double full = 9999;
}

/// Утилиты для декоративных элементов
class ModernDecorations {
  // Декоративный размытый круг (для фона)
  static Widget blurredCircle({
    required double size,
    required Color color,
    Offset? offset,
  }) {
    return Positioned(
      left: offset?.dx ?? 0,
      top: offset?.dy ?? 0,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.3),
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }

  // Фоновые декоративные круги
  static Widget get backgroundCircles => Stack(
        children: [
          blurredCircle(
            size: 300,
            color: ModernColors.primaryPurple,
            offset: const Offset(-100, -50),
          ),
          blurredCircle(
            size: 200,
            color: ModernColors.accentCyan,
            offset: const Offset(200, 100),
          ),
          blurredCircle(
            size: 150,
            color: ModernColors.accentPink,
            offset: const Offset(-50, 300),
          ),
        ],
      );

  // Градиентный разделитель
  static Widget get gradientDivider => Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              ModernColors.primaryPurple.withValues(alpha: 0.3),
              ModernColors.accentCyan.withValues(alpha: 0.3),
              Colors.transparent,
            ],
          ),
        ),
      );

  // Тонкая линия-разделитель
  static Widget divider({double opacity = 0.06}) => Container(
        height: 1,
        color: Colors.white.withValues(alpha: opacity),
      );
}

/// Утилиты для анимаций
class ModernAnimations {
  // Длительности
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  // Кривые
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve bounceOut = Curves.easeOutBack;
  static const Curve elasticOut = Curves.easeOutBack;
}

/// Утилиты для отступов
class ModernSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
}
