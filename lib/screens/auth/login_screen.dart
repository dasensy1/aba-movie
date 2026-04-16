import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/providers.dart';
import '../../utils/modern_ui.dart';
import '../../widgets/modern_text_field.dart';
import '../main_screen.dart';
import 'auth_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
      return;
    }

    if (authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: ModernColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      eyebrow: 'ВХОД',
      title: 'С возвращением',
      subtitle: 'Войдите, чтобы продолжить отслеживать фильмы и списки.',
      form: Form(
        key: _formKey,
        child: Column(
          children: [
            ModernTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите email';
                }
                if (!value.contains('@')) {
                  return 'Введите корректный email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ModernTextField(
              controller: _passwordController,
              label: 'Пароль',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white54,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите пароль';
                }
                if (value.length < 6) {
                  return 'Пароль должен быть не короче 6 символов';
                }
                return null;
              },
              onFieldSubmitted: (_) => _handleLogin(),
            ),
            const SizedBox(height: 20),
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleLogin,
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Войти'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Восстановление пароля пока не реализовано'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Забыли пароль?'),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Нет аккаунта? ',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.56)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: const Text('Регистрация'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
