import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../utils/modern_ui.dart';
import '../../widgets/modern_text_field.dart';
import '../main_screen.dart';

/// ============================================================================
/// REGISTER SCREEN — Современный дизайн
/// ============================================================================

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Необходимо принять условия использования')),
            ],
          ),
          backgroundColor: ModernColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ModernRadius.md),
          ),
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _displayNameController.text.trim().isEmpty
          ? null
          : _displayNameController.text.trim(),
    );

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } else if (mounted && authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(authProvider.error!)),
            ],
          ),
          backgroundColor: ModernColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ModernRadius.md),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 22),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: ModernGradients.heroGradient,
        ),
        child: Stack(
          children: [
            // Декоративные элементы
            Positioned(
              right: -100,
              top: 100,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      ModernColors.accentPink.withValues(alpha: 0.2),
                      ModernColors.accentPink.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            // Контент
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(ModernSpacing.xl),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 24),
                          // Заголовок
                          _buildHeader(),
                          const SizedBox(height: 40),
                          // Форма
                          _buildForm(),
                          const SizedBox(height: 24),
                          // Кнопка регистрации
                          _buildRegisterButton(),
                          const SizedBox(height: 24),
                          // Уже есть аккаунт
                          _buildLoginLink(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: ModernGradients.sunsetGradient,
                boxShadow: ModernShadows.purpleGlow,
              ),
              child: const Icon(
                Icons.person_add_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Создать аккаунт',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Заполните форму для регистрации',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        // Имя
        ModernTextField(
          controller: _displayNameController,
          label: 'Имя',
          icon: Icons.person_outline_rounded,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: ModernSpacing.lg),
        // Email
        ModernTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Введите email';
            if (!value.contains('@')) return 'Введите корректный email';
            return null;
          },
        ),
        const SizedBox(height: ModernSpacing.lg),
        // Пароль
        ModernTextField(
          controller: _passwordController,
          label: 'Пароль',
          icon: Icons.lock_outlined,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Colors.white.withValues(alpha: 0.5),
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Введите пароль';
            if (value.length < 6) return 'Минимум 6 символов';
            return null;
          },
        ),
        const SizedBox(height: ModernSpacing.lg),
        // Подтверждение пароля
        ModernTextField(
          controller: _confirmPasswordController,
          label: 'Подтвердите пароль',
          icon: Icons.lock_outlined,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Colors.white.withValues(alpha: 0.5),
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Подтвердите пароль';
            if (value != _passwordController.text) return 'Пароли не совпадают';
            return null;
          },
          onFieldSubmitted: (_) => _handleRegister(),
        ),
        const SizedBox(height: ModernSpacing.xl),
        // Чекбокс принятия условий
        _buildTermsCheckbox(),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: Checkbox(
            value: _acceptTerms,
            onChanged: (value) {
              setState(() => _acceptTerms = value ?? false);
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
            activeColor: ModernColors.primaryPurple,
            checkColor: Colors.white,
          ),
        ),
        const SizedBox(width: ModernSpacing.md),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _acceptTerms = !_acceptTerms),
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                children: const [
                  TextSpan(text: 'Я принимаю '),
                  TextSpan(
                    text: 'Условия использования',
                    style: TextStyle(
                      color: ModernColors.primaryPurpleLight,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(text: ' и '),
                  TextSpan(
                    text: 'Политику конфиденциальности',
                    style: TextStyle(
                      color: ModernColors.primaryPurpleLight,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return AnimatedContainer(
          duration: ModernAnimations.fast,
          height: 56,
          decoration: BoxDecoration(
            gradient: auth.isLoading ? null : ModernGradients.sunsetGradient,
            color: auth.isLoading ? Colors.white.withValues(alpha: 0.1) : null,
            borderRadius: BorderRadius.circular(ModernRadius.md),
            boxShadow: auth.isLoading ? [] : ModernShadows.purpleGlow,
          ),
          child: ElevatedButton(
            onPressed: auth.isLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ModernRadius.md),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: auth.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Зарегистрироваться',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Уже есть аккаунт? ',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 15,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: const Text(
            'Войти',
            style: TextStyle(
              color: ModernColors.primaryPurpleLight,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
