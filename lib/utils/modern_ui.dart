// ============================================================================
// MODERN UI UTILITIES — Градиенты, тени, glassmorphism, декорации
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Современная палитра цветов (Стиль Apple TV / Netflix)
class ModernColors {
  static const primaryPurple = Color(0xFF5A67D8); // Приглушенный индиго/сине-фиолетовый
  static const primaryPurpleDark = Color(0xFF434190);
  static const primaryPurpleLight = Color(0xFF7F9CF5);
  static const accentCyan = Color(0xFF63B3ED); // Мягкий синий
  static const accentPink = Color(0xFFF687B3); // Мягкий розово/персиковый
  static const accentAmber = Color(0xFFF6E05E);
  static const surfaceDark = Color(0xFF1A202C); // Строгий глубокий фон карточек
  static const surfaceDarkHigher = Color(0xFF2D3748);
  static const backgroundDark = Color(0xFF090A0F); // Глубокий почти черный фон
  static const backgroundDarkSoft = Color(0xFF11141F);
  static const borderSoft = Color(0x22FFFFFF);
  static const success = Color(0xFF48BB78);
  static const warning = Color(0xFFD69E2E);
  static const error = Color(0xFFF56565);
  static const info = Color(0xFF4299E1);
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
      Color(0xFF20113A),
      ModernColors.primaryPurpleDark,
      ModernColors.accentCyan,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.55, 1.0],
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
    center: Alignment(-0.15, -0.95),
    radius: 1.7,
    colors: [
      Color(0xFF24203F),
      ModernColors.backgroundDarkSoft,
      ModernColors.backgroundDark,
    ],
    stops: [0.0, 0.45, 1.0],
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
          color: Colors.black.withValues(alpha: 0.22),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
      ];

  // Цветная тень (purple glow)
  static List<BoxShadow> get purpleGlow => [
        BoxShadow(
          color: ModernColors.primaryPurple.withValues(alpha: 0.28),
          blurRadius: 32,
          spreadRadius: 2,
          offset: const Offset(0, 10),
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

  // Тень при наведении (Web Hover)
  static List<BoxShadow> get hoverGlow => [
        BoxShadow(
          color: ModernColors.primaryPurple.withValues(alpha: 0.45),
          blurRadius: 36,
          spreadRadius: 4,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: ModernColors.accentCyan.withValues(alpha: 0.25),
          blurRadius: 24,
          spreadRadius: -2,
          offset: const Offset(0, 8),
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

class AppThemes {
  static final ThemeData lightTheme = _buildTheme(Brightness.light);
  static final ThemeData darkTheme = _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor:
          isDark ? ModernColors.backgroundDark : const Color(0xFFF5F7FB),
      colorScheme: ColorScheme.fromSeed(
        brightness: brightness,
        seedColor: ModernColors.primaryPurple,
        primary: ModernColors.primaryPurple,
        secondary: ModernColors.accentCyan,
        surface: isDark ? ModernColors.surfaceDark : Colors.white,
      ),
    );

    final textTheme = GoogleFonts.spaceGroteskTextTheme(base.textTheme).copyWith(
      headlineLarge: GoogleFonts.spaceGrotesk(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : const Color(0xFF101426),
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : const Color(0xFF101426),
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : const Color(0xFF111827),
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : const Color(0xFF111827),
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white70 : const Color(0xFF374151),
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white60 : const Color(0xFF4B5563),
      ),
      labelLarge: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: isDark ? ModernColors.surfaceDark : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ModernRadius.lg),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF3F4F6),
        hintStyle: textTheme.bodyMedium,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: ModernColors.primaryPurple,
            width: 1.4,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ModernColors.primaryPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white,
        selectedColor: ModernColors.primaryPurple.withValues(alpha: 0.16),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE5E7EB),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        labelStyle: textTheme.bodyMedium,
      ),
    );
  }
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

/// ============================================================================
/// SKELETON LOADING
/// ============================================================================

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _opacity = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: ModernColors.surfaceDarkHigher,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
        );
      },
    );
  }
}

/// Утилиты для Toast уведомлений
class ModernToasts {
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white))),
          ],
        ),
        backgroundColor: ModernColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ModernRadius.md)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
